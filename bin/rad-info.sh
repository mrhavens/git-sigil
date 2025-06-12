#!/bin/bash

# rad-info.sh: Retrieve repository information for Radicle or centralized Git hosting.
# Complies with RIGOR principles: Reproducible, Interoperable, Generalizable, Open, Robust.
# Dependencies: git, rad (Radicle CLI). Optional: curl, jq (for centralized Git or JSON output).
# Version: 1.6.0
# License: MIT

# Default settings
REMOTE_NAME=""
OUTPUT_FORMAT="text"
DETAILED_MODE=false
ALL_REMOTES=false
VERBOSE=false
CONFIG_FILE="$HOME/.rad-info.rc"
PLUGIN_DIR="$HOME/.rad-info/plugins"

# Function to check for tools
check_tools() {
  local tools=("$@")
  for cmd in "${tools[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Error: $cmd is required but not installed" >&2
      return 1
    fi
  done
}

# Function to log verbose output
log_verbose() {
  [ "$VERBOSE" = true ] && echo "[DEBUG] $*" >&2
}

# Function to find Radicle remote
find_radicle_remote() {
  local remote
  remote=$(git remote -v | grep 'rad://' | awk '{print $1}' | sort -u | head -n1 2>/dev/null || echo "")
  log_verbose "Found Radicle remote: $remote (exit code: $?)"
  echo "$remote"
}

# Function to check Radicle version
check_rad_version() {
  if ! check_tools rad; then
    echo "Error: Radicle CLI (rad) is not installed" >&2
    return 1
  fi
  local version
  version=$(rad --version | awk '{print $2}' 2>/dev/null || echo "unknown")
  log_verbose "Radicle CLI version: $version (exit code: $?)"
  if [[ "$version" == "unknown" || ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Warning: Could not determine Radicle CLI version. Some features may not work." >&2
  fi
  echo "$version"
}

# Parse command-line options
while getopts "r:jdav" opt; do
  case $opt in
    r) REMOTE_NAME="$OPTARG" ;;
    j) OUTPUT_FORMAT="json" ;;
    d) DETAILED_MODE=true ;;
    a) ALL_REMOTES=true ;;
    v) VERBOSE=true ;;
    *) echo "Usage: $0 [-r remote] [-j] [-d] [-a] [-v]"
       echo "  -r: Specify remote name (default: auto-detect)"
       echo "  -j: Output in JSON format"
       echo "  -d: Include detailed Radicle info (peers, issues, patches, identity revisions)"
       echo "  -a: Summarize all remotes"
       echo "  -v: Enable verbose logging"
       exit 0 ;;
  esac
done

# Load config file if exists
if [ -f "$CONFIG_FILE" ]; then
  log_verbose "Loading config from $CONFIG_FILE"
  source "$CONFIG_FILE"
fi

# Load plugins if directory exists
if [ -d "$PLUGIN_DIR" ]; then
  for plugin in "$PLUGIN_DIR"/*.sh; do
    if [ -f "$plugin" ]; then
      log_verbose "Loading plugin: $plugin"
      source "$plugin"
    fi
  done
fi

# Check if in a Git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: Not inside a Git repository" >&2
  exit 1
fi

# Check core tools
check_tools git || exit 1

# Initialize variables
RID=""
NODE_ID=""
FULL_NAME=""
DEFAULT_BRANCH=""
CURRENT_BRANCH=""
CURRENT_COMMIT=""
REPO_STATUS=""
HOST=""
SEED_NODES=""
VISIBILITY=""
PEERS=""
ISSUES=""
PATCHES=""
IDENTITY_REVISIONS=""
REMOTES=()

# Function to get local Git details
get_local_git_details() {
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "N/A")
  CURRENT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "N/A")
  local status_count
  status_count=$(git status --porcelain 2>/dev/null | wc -l | xargs)
  REPO_STATUS=$([ "$status_count" -eq 0 ] && echo "Clean" || echo "Dirty ($status_count uncommitted changes)")
  DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
  log_verbose "Local Git details: branch=$CURRENT_BRANCH, commit=$CURRENT_COMMIT, status=$REPO_STATUS, default=$DEFAULT_BRANCH (exit code: $?)"
}

# Function to handle Radicle repositories
handle_radicle() {
  check_rad_version >/dev/null || return 1

  # Check Radicle node status and connectivity
  local node_status node_stderr
  node_status=$(rad node status 2>/tmp/rad_node_stderr) || {
    node_stderr=$(cat /tmp/rad_node_stderr)
    log_verbose "rad node status failed: $node_stderr (exit code: $?)"
    echo "Error: Radicle node is not running. Start it with 'rad node start'" >&2
    return 1
  }
  log_verbose "Node status: $node_status (exit code: $?)"
  local peer_count
  peer_count=$(echo "$node_status" | grep -c 'connected' || echo "0")
  if [ "$peer_count" -eq 0 ]; then
    echo "Warning: Radicle node is running but not connected to peers. Check seed node configuration." >&2
  fi
  log_verbose "Connected peers: $peer_count"

  # Check repository initialization
  local payload_output payload_stderr
  payload_output=$(rad inspect --payload 2>/tmp/rad_payload_stderr) || {
    payload_stderr=$(cat /tmp/rad_payload_stderr)
    log_verbose "rad inspect --payload failed: $payload_stderr (exit code: $?)"
    echo "Warning: Repository not fully initialized with Radicle. Run 'rad init' to set metadata." >&2
  }
  log_verbose "rad inspect --payload output: $payload_output (exit code: $?)"

  # Get RID
  local inspect_output inspect_stderr
  inspect_output=$(rad inspect 2>/tmp/rad_inspect_stderr) || {
    inspect_stderr=$(cat /tmp/rad_inspect_stderr)
    log_verbose "rad inspect failed: $inspect_stderr (exit code: $?)"
    echo "Warning: Not a Radicle repository. Falling back to Git details." >&2
    return 1
  }
  RID=$(echo "$inspect_output" | grep -o 'rad:[^ ]*' || echo "")
  [ -z "$RID" ] && { echo "Error: Could not retrieve Radicle Repository ID (RID)" >&2; return 1; }
  log_verbose "RID: $RID (exit code: $?)"

  # Get Node ID
  local self_output self_stderr
  self_output=$(rad self 2>/tmp/rad_self_stderr || echo "")
  self_stderr=$(cat /tmp/rad_self_stderr)
  NODE_ID=$(echo "$self_output" | grep 'Node ID (NID)' | awk '{print $NF}' || echo "N/A")
  log_verbose "Node ID: $NODE_ID, stderr: $self_stderr (exit code: $?)"

  # Get repository metadata from payload
  if [ -n "$payload_output" ] && check_tools jq; then
    FULL_NAME=$(echo "$payload_output" | jq -r '.["xyz.radicle.project"].name // "N/A"' 2>/dev/null || echo "N/A")
    VISIBILITY=$(echo "$payload_output" | jq -r '.visibility // "unknown"' 2>/dev/null || echo "unknown")
    DEFAULT_BRANCH=$(echo "$payload_output" | jq -r '.["xyz.radicle.project"].default_branch // "main"' 2>/dev/null || echo "main")
  else
    FULL_NAME=$(git config rad.name 2>/dev/null || basename "$(git rev-parse --show-toplevel)" 2>/dev/null || echo "N/A")
    VISIBILITY="unknown"
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/rad/HEAD 2>/dev/null | sed 's@^refs/remotes/rad/@@' || echo "main")
    echo "Warning: Repository metadata not found or jq not installed. Using directory name: $FULL_NAME. Run 'rad id update --payload xyz.radicle.project name \"<name>\"' to set a name." >&2
  fi
  if [ "$FULL_NAME" = "N/A" ]; then
    FULL_NAME=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null || echo "N/A")
    echo "Warning: Repository name not found. Using directory name: $FULL_NAME. Run 'rad id update --payload xyz.radicle.project name \"<name>\"' to set a name." >&2
  fi
  log_verbose "Full Name: $FULL_NAME, Visibility: $VISIBILITY, Default Branch: $DEFAULT_BRANCH"

  # Get seed nodes
  local config_output config_stderr
  config_output=$(rad config 2>/tmp/rad_config_stderr || echo "")
  config_stderr=$(cat /tmp/rad_config_stderr)
  log_verbose "rad config output: $config_output, stderr: $config_stderr (exit code: $?)"
  if [ -n "$config_output" ] && echo "$config_output" | grep -q '{'; then
    if check_tools jq; then
      SEED_NODES=$(echo "$config_output" | jq -r '.preferredSeeds[]' 2>/dev/null | paste -sd, - || echo "N/A")
    else
      SEED_NODES=$(echo "$config_output" | grep -oE '[^ ]+@[^ ]+:8776' | paste -sd, - || echo "N/A")
      echo "Warning: jq not installed; using fallback for seed nodes parsing" >&2
    fi
  else
    SEED_NODES="N/A"
    echo "Warning: Failed to parse rad config for seed nodes" >&2
  fi
  log_verbose "Seed Nodes: $SEED_NODES"

  # Detailed mode: peers, issues, patches, identity revisions
  if [ "$DETAILED_MODE" = true ]; then
    PEERS=$(rad peer ls 2>/dev/null | wc -l | xargs || echo "N/A")
    ISSUES=$(rad issue ls 2>/dev/null | wc -l | xargs || echo "N/A")
    PATCHES=$(rad patch ls 2>/dev/null | wc -l | xargs || echo "N/A")
    IDENTITY_REVISIONS=$(rad id list 2>/dev/null | grep -c 'accepted' || echo "N/A")
    log_verbose "Peers: $PEERS, Issues: $ISSUES, Patches: $PATCHES, Identity Revisions: $IDENTITY_REVISIONS (exit code: $?)"
  fi

  HOST="radicle"
  get_local_git_details
}

# Function to handle centralized Git
handle_centralized() {
  local remote_url=$1
  if [[ "$remote_url" =~ ^rad:// ]]; then
    echo "Error: Radicle URL ($remote_url) cannot be processed as centralized Git. Ensure repository is initialized with 'rad init'." >&2
    return 1
  fi
  local parsed_url="$remote_url"
  if [[ "$remote_url" =~ ^git@ ]]; then
    parsed_url=$(echo "$remote_url" | sed -E 's/git@([^:]+):(.+)\.git$/https:\/\/\1\/\2/')
  fi

  if [[ "$parsed_url" =~ https?://([^/]+)/([^/]+)/([^/]+) ]]; then
    HOST="${BASH_REMATCH[1]}"
    FULL_NAME="${BASH_REMATCH[2]}/${BASH_REMATCH[3]%.git}"
  else
    echo "Error: Could not parse remote URL: $remote_url" >&2
    return 1
  fi
  log_verbose "Centralized Git: Host=$HOST, Full Name=$FULL_NAME (exit code: $?)"

  # Optional API-based metadata with retry
  if check_tools curl jq; then
    local api_url=""
    local curl_opts=(--silent --fail)
    if [ -n "$GITHUB_TOKEN" ] && [ "$HOST" = "github.com" ]; then
      curl_opts+=(--header "Authorization: token $GITHUB_TOKEN")
    fi
    case "$HOST" in
      github.com)
        api_url="https://api.github.com/repos/$FULL_NAME"
        ;;
      gitlab.com)
        api_url="https://gitlab.com/api/v4/projects/$(echo -n "$FULL_NAME" | xxd -p | tr -d '\n')"
        ;;
      bitbucket.org)
        api_url="https://api.bitbucket.org/2.0/repositories/$FULL_NAME"
        ;;
    esac
    if [ -n "$api_url" ]; then
      local repo_details=""
      for attempt in 1 2 3; do
        repo_details=$(curl "${curl_opts[@]}" "$api_url" 2>/dev/null || echo "")
        log_verbose "API attempt $attempt response: $repo_details (exit code: $?)"
        [ -n "$repo_details" ] && break
        sleep 1
      done
      if [ -n "$repo_details" ]; then
        FULL_NAME=$(echo "$repo_details" | jq -r '.full_name // .path_with_namespace // ""' || echo "$FULL_NAME")
        DEFAULT_BRANCH=$(echo "$repo_details" | jq -r '.default_branch // .mainbranch.name // "main"' || echo "main")
      else
        echo "Warning: Failed to fetch API metadata for $HOST after retries" >&2
      fi
    fi
  else
    echo "Warning: curl or jq not installed; skipping API metadata for $HOST" >&2
  fi

  get_local_git_details
}

# Function to summarize all remotes
summarize_all_remotes() {
  local remotes
  mapfile -t remotes < <(git remote)
  REMOTES=()
  for remote in "${remotes[@]}"; do
    local url
    url=$(git remote get-url "$remote" 2>/dev/null || echo "N/A")
    local type="centralized"
    [[ "$url" =~ ^rad:// ]] && type="radicle"
    REMOTES+=("$remote: $type ($url)")
    log_verbose "Remote: $remote, Type: $type, URL: $url (exit code: $?)"
  done
}

# Main logic
if [ "$ALL_REMOTES" = true ]; then
  summarize_all_remotes
elif [ -z "$REMOTE_NAME" ]; then
  REMOTE_NAME=$(find_radicle_remote)
  if [ -z "$REMOTE_NAME" ] && rad inspect >/dev/null 2>&1; then
    REMOTE_NAME="rad"
  fi
fi

if [ -n "$REMOTE_NAME" ]; then
  REMOTE_URL=$(git remote get-url "$REMOTE_NAME" 2>/dev/null || echo "")
  log_verbose "Processing remote: $REMOTE_NAME ($REMOTE_URL) (exit code: $?)"
  if [[ "$REMOTE_URL" =~ ^rad:// ]] || rad inspect >/dev/null 2>&1; then
    handle_radicle || {
      echo "Warning: Failed to process Radicle repository. Ensure 'rad init' has been run and metadata is set with 'rad id update'." >&2
      return 1
    }
  else
    handle_centralized "$REMOTE_URL" || {
      echo "Warning: Failed to process centralized Git repository." >&2
      return 1
    }
  fi
else
  echo "Warning: No Radicle remote found. Processing as centralized Git or use -r to specify." >&2
  REMOTE_NAME="origin"
  REMOTE_URL=$(git remote get-url "$REMOTE_NAME" 2>/dev/null || echo "")
  [ -z "$REMOTE_URL" ] && { echo "Error: No remote URL found" >&2; exit 1; }
  handle_centralized "$REMOTE_URL" || {
    echo "Warning: Failed to process centralized Git repository." >&2
    return 1
  }
fi

# Output repository information
if [ "$OUTPUT_FORMAT" = "json" ]; then
  if ! check_tools jq; then
    echo "Error: jq is required for JSON output. Falling back to text output." >&2
    OUTPUT_FORMAT="text"
  else
    jq -n --arg host "$HOST" \
      --arg full_name "$FULL_NAME" \
      --arg rid "$RID" \
      --arg node_id "$NODE_ID" \
      --arg default_branch "$DEFAULT_BRANCH" \
      --arg current_branch "$CURRENT_BRANCH" \
      --arg current_commit "$CURRENT_COMMIT" \
      --arg repo_status "$REPO_STATUS" \
      --arg seed_nodes "$SEED_NODES" \
      --arg visibility "$VISIBILITY" \
      --arg peers "$PEERS" \
      --arg issues "$ISSUES" \
      --arg patches "$PATCHES" \
      --arg identity_revisions "$IDENTITY_REVISIONS" \
      --argjson remotes "$(printf '%s\n' "${REMOTES[@]}" | jq -R . | jq -s .)" \
      '{
        hosting_service: $host,
        full_name: $full_name,
        repo_id: $rid,
        node_id: $node_id,
        default_branch: $default_branch,
        current_branch: $current_branch,
        current_commit: $current_commit,
        repo_status: $repo_status,
        seed_nodes: $seed_nodes,
        visibility: $visibility,
        peers: $peers,
        issues: $issues,
        patches: $patches,
        identity_revisions: $identity_revisions,
        remotes: $remotes
      }'
  fi
fi

if [ "$OUTPUT_FORMAT" = "text" ]; then
  echo
  echo "Repository Information:"
  echo "----------------------"
  echo "Hosting Service: $HOST"
  echo "Full Name: ${FULL_NAME:-N/A}"
  echo "Repository ID: ${RID:-N/A}"
  echo "Node ID: ${NODE_ID:-N/A}"
  echo "Default Branch: $DEFAULT_BRANCH"
  echo "Current Branch: $CURRENT_BRANCH"
  echo "Current Commit: $CURRENT_COMMIT"
  echo "Repository Status: $REPO_STATUS"
  [ -n "$SEED_NODES" ] && echo "Seed Nodes: $SEED_NODES"
  [ -n "$VISIBILITY" ] && echo "Visibility: $VISIBILITY"
  [ "$DETAILED_MODE" = true ] && [ -n "$PEERS" ] && echo "Peers: $PEERS"
  [ "$DETAILED_MODE" = true ] && [ -n "$ISSUES" ] && echo "Issues: $ISSUES"
  [ "$DETAILED_MODE" = true ] && [ -n "$PATCHES" ] && echo "Patches: $PATCHES"
  [ "$DETAILED_MODE" = true ] && [ -n "$IDENTITY_REVISIONS" ] && echo "Accepted Identity Revisions: $IDENTITY_REVISIONS"
  if [ "$ALL_REMOTES" = true ]; then
    echo "Remotes:"
    for remote in "${REMOTES[@]}"; do
      echo "  $remote"
    done
  fi
  echo "----------------------"
  if [ "$HOST" = "radicle" ]; then
    echo "Clone Command: rad clone $RID"
    echo "Sync Command: rad sync"
    echo "Note: Ensure Radicle node is running ('rad node start') and configured with seed nodes."
    echo "See 'rad help' for more commands and https://radicle.xyz for documentation."
  else
    echo "Clone Command: git clone $REMOTE_URL"
    echo "Sync Command: git fetch $REMOTE_NAME && git pull $REMOTE_NAME $DEFAULT_BRANCH"
  fi
fi

# Clean up temporary files
rm -f /tmp/rad_*_stderr
