#!/bin/bash

# rad-info.sh: Retrieve repository information for Radicle or centralized Git hosting.
# Complies with RIGOR principles: Reproducible, Interoperable, Generalizable, Open, Robust.
# Dependencies: git, rad (Radicle CLI). Optional: curl, jq (for centralized Git or JSON output).
# Version: 2.1.0
# License: GPLv3

# Default settings
REMOTE_NAME=""
OUTPUT_FORMAT="text"
DETAILED_MODE=false
ALL_REM=false
INTERACTIVE=false
FORCE_INIT=false
LOG_LEVEL="error" # error, warning, debug
LOG_DEST="stderr" # stderr, stdout, file:/path
CONFIG_FILE="${HOME}/.rad-info.rc"
PLUGIN_DIR="${HOME}/.rad-info/plugins"
TEMP_DIR=$(mktemp -d "/tmp/rad-info.XXXXXX")
RAD_TIMEOUT_SECONDS=10
RAD_RETRY_COUNT=3
GIT_CACHE=""
OUTPUT_GENERATED=false

# Centralized logging function
log_message() {
  local level=$1 message=$2
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S%z")
  case $LOG_LEVEL in
    error) [[ "$level" == "error" ]] || return 0 ;;
    warning) [[ "$level" == "error" || "$level" == "warning" ]] || return 0 ;;
    debug) ;;
    *) return 1 ;;
  esac
  case $LOG_DEST in
    file:*) echo "[$timestamp] $level: $message" >> "${LOG_DEST#file:}" ;;
    stdout) echo "[$timestamp] $level: $message" ;;
    *) echo "[$level] $message" >&2 >&3 ;;
  esac
}

# Function to check for tools
check_tools() {
  local tools=("$@")
  for cmd in "${tools[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log_message "error" "$cmd is required but not installed"
      return 1
    fi
  done
  return 0
}

# Function to execute commands with timeout and retries
exec_command() {
  local cmd=$1 retries=$2 stdout_file=$3 stderr_file=$4
  local attempt=1 exit_code
  while ((attempt <= retries)); do
    if timeout $RAD_TIMEOUT_SECONDS $cmd 2>"$stderr_file" >"$stdout_file"; then
      log_message "debug" "Command '$cmd' succeeded on attempt $attempt"
      return 0
    fi
    exit_code=$?
    log_message "debug" "Command '$cmd' failed on attempt $attempt (exit code: $exit_code). Retrying..."
    ((attempt++))
    sleep 1
  done
  log_message "error" "Command '$cmd' failed after $retries attempts"
  return 1
}

# Function to find Radicle remote
find_radicle_remote() {
  if [ -z "$GIT_CACHE" ]; then
    GIT_CACHE=$(git remote -v 2>/dev/null || echo "")
  fi
  local remote
  remote=$(echo "$GIT_CACHE" | grep 'rad://' | awk '{print $1}' | sort -u | head -n1 || echo "")
  log_message "debug" "Found Radicle remote: $remote"
  echo "$remote"
}

# Function to check Radicle version
check_version() {
  if ! check_tools rad; then
    return 1
  fi
  local version
  version=$(rad --version 2>/dev/null | awk '{print $2}' || echo "unknown")
  log_message "debug" "Radicle CLI version: $version"
  if [[ "$version" == "unknown" || ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_message "warning" "Could not determine Radicle CLI version. Some features may not work."
  fi
  echo "$version"
}

# Function to prompt for initialization
prompt_init() {
  if [ "$INTERACTIVE" != "true" ] && [ "$FORCE_INIT" != "true" ]; then
    log_message "warning" "Run with -i for interactive initialization or -f to force"
    return 1
  fi
  local repo_name default_branch="main" visibility="public"
  repo_name=$(basename "$PWD")
  if [ "$INTERACTIVE" = "true" ]; then
    read -p "Initialize Radicle repository? (y/n) [n]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then return 1; fi
    read -p "Repository name [$repo_name]: " name
    repo_name=${name:-$repo_name}
    read -p "Default branch [$default_branch]: " branch
    default_branch=${branch:-$default_branch}
    read -p "Visibility (public/private) [public]: " vis
    visibility=${vis:-public}
  fi
  log_message "info" "Initializing Radicle repository: $repo_name"
  if rad init --name "$repo_name" --default-branch "$default_branch" 2>"$TEMP_DIR/init_stderr"; then
    if rad id update --payload xyz.radicle.project name "\"$repo_name\"" --visibility "$visibility" 2>"$TEMP_DIR/id_update_stderr"; then
      log_message "info" "Updated repository metadata: $repo_name ($visibility)"
      return 0
    else
      log_message "warning" "Failed to update repository metadata: $(cat "$TEMP_DIR/id_update_stderr")"
      return 1
    fi
  else
    log_message "error" "Failed to initialize Radicle repository: $(cat "$TEMP_DIR/init_stderr")"
    return 1
  fi
}

# Function to start Radicle node
start_node() {
  if [ "$INTERACTIVE" != "true" ] && [ "$FORCE_INIT" != "true" ]; then
    log_message "warning" "Radicle node not running. Run with -i or -f to start"
    return 1
  fi
  if [ "$INTERACTIVE" = "true" ]; then
    read -p "Start Radicle node? (y/n) [n]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then return 1; fi
  fi
  log_message "info" "Starting Radicle node"
  if rad node start 2>"$TEMP_DIR/node_start_stderr"; then
    log_message "info" "Radicle node started"
    return 0
  else
    log_message "error" "Failed to start Radicle node: $(cat "$TEMP_DIR/node_start_stderr")"
    return 1
  fi
}

# Function to display help
show_help() {
  cat << EOF
rad-info.sh: Retrieve repository information for Radicle or centralized Git hosting.
Version: 2.1.0
License: GPLv3

Usage: $0 [options]

Options:
  -h, --help        Show this help message and exit
  -r <remote>       Specify remote name (default: auto-detect)
  -j                Output in JSON format
  -d                Detailed Radicle info (peers, issues, patches, etc.)
  -i                Interactive mode for initialization
  -f                Force initialization and node start
  -a                Summarize all remotes
  -l <level>        Log level or file (error, warning, debug, file:/path)
  -v                Verbose logging (debug level)

Configuration:
  Config file: $CONFIG_FILE
  Plugin directory: $PLUGIN_DIR
  Log file (if -l file:/path): Specified path

Examples:
  $0                Display repository info (text format)
  $0 -j             Output repository info in JSON
  $0 -d             Include detailed Radicle metadata
  $0 -i             Interactively initialize uninitialized Radicle repo
  $0 -f             Force Radicle initialization and node start
  $0 -a             List all remotes
  $0 -l debug       Enable debug logging
  $0 -l file:/var/log/rad-info.log  Log to file

Notes:
  - Requires git and rad (Radicle CLI). Optional: curl, jq.
  - Run 'rad node start' before using Radicle features.
  - See https://radicle.xyz for Radicle documentation.
EOF
  OUTPUT_GENERATED=true
}

# Parse command-line options
while getopts "r:jdihafl:v-:" opt; do
  case "$opt" in
    r) REMOTE_NAME="$OPTARG" ;;
    j) OUTPUT_FORMAT="json" ;;
    d) DETAILED_MODE="true" ;;
    i) INTERACTIVE="true" ;;
    f) FORCE_INIT="true" ;;
    a) ALL_REM="true" ;;
    l) LOG_LEVEL="$OPTARG" ;;
    v) LOG_LEVEL="debug" ;;
    h) show_help; exit 0 ;;
    -) case "$OPTARG" in
         help) show_help; exit 0 ;;
         *) log_message "error" "Unknown option --$OPTARG"; show_help; exit 1 ;;
       esac ;;
    *) show_help; exit 1 ;;
  esac
done

# Validate log level
if [[ "$LOG_LEVEL" != "error" && "$LOG_LEVEL" != "warning" && "$LOG_LEVEL" != "debug" && ! "$LOG_LEVEL" =~ ^file: ]]; then
  log_message "error" "Invalid log level: $LOG_LEVEL. Use error, warning, debug, or file:/path"
  show_help
  exit 1
fi

# Redirect stderr to /dev/null for clean output, keep fd 3 for logging
exec 3>&2 2>/dev/null

# Load config file
if [ -f "$CONFIG_FILE" ]; then
  log_message "debug" "Loading config from $CONFIG_FILE"
  source "$CONFIG_FILE" || log_message "error" "Failed to load config file: $CONFIG_FILE"
fi

# Load plugins
if [ -d "$PLUGIN_DIR" ]; then
  for plugin in "$PLUGIN_DIR"/*.sh; do
    if [ -f "$plugin" ]; then
      log_message "debug" "Loading plugin: $plugin"
      if ! (source "$plugin" 2>"$TEMP_DIR/plugin_stderr"); then
        log_message "warning" "Failed to load plugin $plugin: $(cat "$TEMP_DIR/plugin_stderr")"
      fi
    fi
  done
fi

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
OPEN_PATCHES=""
IDENTITY_REVISIONS=""
DELEGATES=""
SEED_STATUS=""
CONFIG_CACHE=""

# Function to get local Git details
get_local_git_details() {
  if [ -z "$GIT_CACHE" ]; then
    GIT_CACHE=$(git remote -v 2>/dev/null || echo "")
  fi
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "N/A")
  CURRENT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "N/A")
  local status_count
  status_count=$(git status --porcelain 2>/dev/null | wc -l | xargs)
  REPO_STATUS=$([ "$status_count" -eq 0 ] && echo "Clean" || echo "Dirty ($status_count uncommitted changes)")
  DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
  log_message "debug" "Local Git details: branch=$CURRENT_BRANCH, commit=$CURRENT_COMMIT, status=$REPO_STATUS, default=$DEFAULT_BRANCH"
}

# Function to handle Radicle repositories
handle_radicle() {
  if ! check_version >/dev/null; then
    log_message "error" "Radicle CLI not available"
    return 1
  fi

  # Check Radicle node status
  local stdout_file="$TEMP_DIR/node_stdout" stderr_file="$TEMP_DIR/node_stderr"
  if ! exec_command "rad node status" $RAD_RETRY_COUNT "$stdout_file" "$stderr_file"; then
    log_message "error" "Radicle node is not running"
    start_node && exec_command "rad node status" $RAD_RETRY_COUNT "$stdout_file" "$stderr_file"
    if [ $? -ne 0 ]; then return 1; fi
  fi
  local node_status
  node_status=$(cat "$stdout_file" 2>/dev/null || echo "")
  log_message "debug" "Node status: $node_status"
  local peer_count
  peer_count=$(echo "$node_status" | grep -c 'connected' | xargs || echo "0")
  if [ "$peer_count" -eq 0 ]; then
    log_message "warning" "Radicle node is running but not connected to peers. Check seed node configuration."
  fi
  log_message "debug" "Connected peers: $peer_count"

  # Get RID
  stdout_file="$TEMP_DIR/inspect_stdout" stderr_file="$TEMP_DIR/inspect_stderr"
  if ! exec_command "rad inspect" $RAD_RETRY_COUNT "$stdout_file" "$stderr_file"; then
    log_message "warning" "Not a Radicle repository"
    prompt_init && return handle_radicle
    return 1
  fi
  RID=$(cat "$stdout_file" 2>/dev/null | grep -o 'rad:[^ ]*' || echo "")
  if [ -z "$RID" ]; then
    log_message "error" "Could not retrieve Radicle Repository ID (RID)"
    prompt_init && return handle_radicle
    return 1
  fi
  log_message "debug" "RID: $RID"

  # Get Node ID
  stdout_file="$TEMP_DIR/self_stdout" stderr_file="$TEMP_DIR/self_stderr"
  exec_command "rad self" $RAD_RETRY_COUNT "$stdout_file" "$stderr_file" || true
  NODE_ID=$(cat "$stdout_file" 2>/dev/null | grep 'Node ID (NID)' | awk '{print $NF}' || echo "N/A")
  log_message "debug" "Node ID: $NODE_ID"

  # Get repository metadata
  stdout_file="$TEMP_DIR/payload_stdout" stderr_file="$TEMP_DIR/payload_stderr"
  local payload_output
  if exec_command "rad inspect --payload" $RAD_RETRY_COUNT "$stdout_file" "$stderr_file"; then
    payload_output=$(cat "$stdout_file" 2>/dev/null || echo "")
    log_message "debug" "rad inspect --payload output: $payload_output"
    if check_tools jq; then
      FULL_NAME=$(echo "$payload_output" | jq -r '.["xyz.radicle.project"].name // "N/A"' 2>/dev/null || echo "N/A")
      VISIBILITY=$(echo "$payload_output" | jq -r '.visibility // "public"' 2>/dev/null || echo "public")
      DEFAULT_BRANCH=$(echo "$payload_output" | jq -r '.["xyz.radicle.project"].defaultBranch // "'"$CURRENT_BRANCH"'"' 2>/dev/null || echo "$CURRENT_BRANCH")
      DELEGATES=$(echo "$payload_output" | jq -r '.delegates | length' 2>/dev/null || echo "N/A")
    else
      log_message "warning" "jq not installed; falling back to directory name for metadata"
      FULL_NAME=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null || echo "N/A")
      VISIBILITY="public"
      DEFAULT_BRANCH="$CURRENT_BRANCH"
      DELEGATES="N/A"
    fi
  else
    log_message "warning" "Repository not fully initialized"
    prompt_init && return handle_radicle
    FULL_NAME=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null || echo "N/A")
    VISIBILITY="public"
    DEFAULT_BRANCH="$CURRENT_BRANCH"
    DELEGATES="N/A"
  fi
  [ "$FULL_NAME" = "N/A" ] && FULL_NAME=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null || echo "N/A")
  log_message "debug" "Full Name: $FULL_NAME, Visibility: $VISIBILITY, Default Branch: $DEFAULT_BRANCH, Delegates: $DELEGATES"

  # Get seed nodes
  stdout_file="$TEMP_DIR/config_stdout" stderr_file="$TEMP_DIR/config_stderr"
  if [ -z "$CONFIG_CACHE" ]; then
    if exec_command "rad config" $RAD_RETRY_COUNT "$stdout_file" "$stderr_file"; then
      CONFIG_CACHE=$(cat "$stdout_file" 2>/dev/null || echo "")
      log_message "debug" "rad config output: $CONFIG_CACHE"
    else
      CONFIG_CACHE=""
      log_message "warning" "Failed to parse rad config for seed nodes"
    fi
  fi
  if [ -n "$CONFIG_CACHE" ] && echo "$CONFIG_CACHE" | grep -q '{'; then
    if check_tools jq; then
      SEED_NODES=$(echo "$CONFIG_CACHE" | jq -r '.preferredSeeds[]' 2>/dev/null | paste -sd, - || echo "N/A")
      SEED_STATUS=$(echo "$node_status" | grep -oE '[^ ]+@[^ ]+:8776.*connected' | sed 's/.*\(@.*connected\)/\1/' | paste -sd, - || echo "N/A")
    else
      SEED_NODES=$(echo "$CONFIG_CACHE" | grep -oE '[^ ]+@[^ ]+:8776' | paste -sd, - || echo "N/A")
      SEED_STATUS="N/A"
      log_message "warning" "jq not installed; using fallback for seed nodes"
    fi
  else
    SEED_NODES=""
    SEED_STATUS=""
  fi
  log_message "info" "Seed Nodes: $SEED_NODES, Status: $SEED_STATUS"

  # Detailed mode
  if [ "$DETAILED_MODE" = "true" ]; then
    PEERS=$(rad peer ls 2>/dev/null | wc -l | xargs || echo "N/A")
    ISSUES=$(rad issue ls 2>/dev/null | wc -l | xargs || echo "N/A")
    PATCHES=$(rad patch ls --all 2>/dev/null | wc -l | xargs || echo "N/A")
    OPEN_PATCHES=$(rad patch ls --open 2>/dev/null | wc -l | xargs || echo "N/A")
    IDENTITY_REVISIONS=$(rad id list 2>/dev/null | grep -c 'accepted' || echo "N/A")
    log_message "debug" "Peers: $PEERS, Issues: $ISSUES, Patches: $PATCHES, Open Patches: $OPEN_PATCHES, Identity Revisions: $IDENTITY_REVISIONS"
  fi

  HOST="radicle"
  get_local_git_details
  return 0
}

# Function to handle centralized Git
handle_centralized() {
  local remote_url=$1
  if [[ "$remote_url" =~ ^rad:// ]]; then
    log_message "error" "Radicle URL ($remote_url) cannot be processed as centralized Git"
    return 1
  fi
  local parsed_url="$remote_url"
  if [[ "$remote_url" =~ ^git@ ]]; then
    parsed_url=$(echo "$remote_url" | sed -E 's/git@([^:]+):(.+)\.git/https:\/\/\1\/\2/')
  fi

  if [[ "$parsed_url" =~ https?://([^/]+)/(.*) ]]; then
    HOST="${BASH_REMATCH[1]}"
    FULL_NAME=$(echo "${BASH_REMATCH[2]}" | sed 's/\.git$//')
  else
    log_message "error" "Invalid remote URL: $remote_url. Expected format: https://host/path"
    return 1
  fi
  log_message "Centralized Git: Host=$HOST, Age=$FULL_NAME"

  # API-based metadata
  if check_tools curl jq; then
    local api_url=""
    local curl_opts=(--silent --fail)
    [ -n "$GITHUB_TOKEN" ] && [ "$HOST" = "github.com" ] && curl_opts+=(--header "Authorization: token $GITHUB_TOKEN")
    case "$HOST in
      github.com) api_url="https://api.github.com/repos/$FULL_NAME" ;;
      gitlab.com) api_url="https://gitlab.com/api/v4/projects/$(echo -n "$FULL_NAME" | xxd -p | tr -d '\n')" ;;
      bitbucket.org) api_url="https://api.bitbucket.org/2.0/repositories/$FULL_NAME" ;;
      *) log_message "debug" "No API support for host: $HOST" ;;
    esac
    if [ -n "$api_url" ]; then
      local stdout_file="$TEMP_DIR/api_stdout" stderr_file="$TEMP_DIR/api_stderr"
      if exec_command "curl ${curl_opts[*]}" '$api_url'" $RAD_TIMEOUT_COUNT "$stdout_file" "$stderr_file"; then
        local repo_details
        repo_details=$(cat "$stdout_file" 2>/dev/null || echo "")
        log_message "debug" "API response: $repo_details"
        FULL_NAME=$(echo "$repo_details" | jq -r '.full_name // .path_with_namespace // "$FULL_NAME"' 2>/dev/null || echo "$FULL_NAME")
        DEFAULT_BRANCH=$(echo "$repo_details" | jq -r '.default_branch // .mainbranch.name // "main"' 2>/dev/null || echo "main")
      else
        log_message "warning" "Failed to fetch API metadata for $HOST"
      fi
    fi
  else
    log_message "warning" "curl or jq not installed; skipping API metadata"
  fi
fi

  get_local_git_details()
  return 0
}

# Function to summarize all remotes
summarize_all() {
  if [ -z "$GIT_CACHE" ]; then
    GIT_CACHE=$(git remote -v 2>/dev/null || echo "")
  fi
  local remotes
  mapfile -t remotes < <(echo "$GIT_CACHE" | awk '{print $1}' | sort -u || echo "")
  REMOTES=()
  for remote in "${remotes[@]}"; do
    local url=$(echo "$GIT_CACHE" | grep "^$remote\s" | awk '{print $2}' | head -n1 || echo "")
    local type="centralized"
    [[ "$url" =~ ^rad:// ]] && type="radicle"
    REMOTES+=("$remote: $type ($url)")
    log_message "debug" "Remote: $remote, Type: $type, URL: $url"
  done
}

# Function to output repository information
output_info() {
  if [ "$OUTPUT_FORMAT" = "json" ]; then
    if ! check_tools jq; then
      log_message "error" "jq is required for JSON output. Falling back to text."
      OUTPUT_FORMAT="text"
    else
      jq -n --arg host "$HOST" \
        --arg full_name "$FULL_NAME" \
        --arg rid "$RID" \
        --arg node_id node_id "$NODE_ID" \
        --arg default_branch "$DEFAULT_BRANCH" \
        --arg current_branch "$CURRENT_BRANCH" \
        --arg current_commit "$CURRENT_COMMIT" \
        --arg repo_status "$REPO_STATUS" \
        --arg seed_nodes "$SEED_NODES" \
        --arg seed_status "$SEED_STATUS" \
        --arg visibility "$VISIBILITY" \
        --arg peers "$PEERS" \
        --arg issues "$ISSUES" \
        --arg patches "$PATCHES" \
        --arg open_patches "$OPEN_PATCHES" \
        --arg identity_revisions "$IDENTITY_REVISIONS" \
        --arg delegates "$DELEGATES" \
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
          seed_status: $seed_status,
          visibility: $visibility,
          peers: $peers,
          issues: $issues,
          patches: $patches,
          open_patches: $open_patches,
          identity_revisions: $identity_revisions,
          delegates: $delegates,
          remotes: $remotes
        }'
      OUTPUT_GENERATED=true
      return 0
    fi
  fi

  if [ "$OUTPUT_FORMAT" = "text" ]; then
    echo
    echo "Repository Information:"
    echo "----------------------"
    echo "Hosting Service: ${HOST:-N/A}"
    echo "Full Name: ${FULL_NAME:-N/A}"
    echo "Repository ID: ${RID:-N/A}"
    echo "Node ID: ${NODE_ID:-N/A}"
    echo "Default Branch: ${DEFAULT_BRANCH:-N/A}"
    echo "Current Branch: ${CURRENT_BRANCH:-N/A}"
    echo "Current Commit: ${CURRENT_COMMIT:-N/A}"
    echo "Repository Status: ${REPO_STATUS:-N/A}"
    [ -n "$SEED_NODES" ] && [ "$SEED_NODES" != "N/A" ] && echo "Seed Nodes: $SEED_NODES"
    [ -n "$SEED_STATUS" ] && [ "$SEED_STATUS" != "N/A" ] && echo "Seed Status: $SEED_STATUS"
    [ -n "$VISIBILITY" ] && [ "$VISIBILITY" != "N/A" ] && echo "Visibility: $VISIBILITY"
    if [ "$DETAILED_MODE" = "true" ]; then
      [ -n "$PEERS" ] && [ "$PEERS" != "N/A" ] && echo "Peers: $PEERS"
      [ -n "$ISSUES" ] && [ "$ISSUES" != "N/A" ] && echo "Issues: $ISSUES"
      [ -n "$PATCHES" ] && [ "$PATCHES" != "N/A" ] && echo "Total Patches: $PATCHES"
      [ -n "$OPEN_PATCHES" ] && [ "$OPEN_PATCHES" != "N/A" ] && echo "Open Patches: $OPEN_PATCHES"
      [ -n "$IDENTITY_REVISIONS" ] && [ "$IDENTITY_REVISIONS" != "N/A" ] && echo "Accepted Identity Revisions: $IDENTITY_REVISIONS"
      [ -n "$DELEGATES" ] && [ "$DELEGATES" != "N/A" ] && echo "Delegates: $DELEGATES"
    fi
    if [ "$ALL_REM" = "true" ]; then
      echo "Remotes:"
      for remote in "${REMOTES[@]}"; do
        echo "  $remote"
      done
    fi
    echo "----------------------"
    if [ "$HOST" = "radicle" ]; then
      echo "Clone Command: rad clone ${RID:-<repository-id>}"
      echo "Sync Command: rad sync"
      echo "Note: Ensure Radicle node is running ('rad node start') and configured with seed nodes."
      echo "See 'rad help' for more commands and https://radicle.xyz for documentation."
    else
      echo "Clone Command: git clone ${REMOTE_URL:-<remote-url>}"
      echo "Sync Command: git fetch ${REMOTE_NAME:-origin} && git pull ${REMOTE_NAME:-origin} ${DEFAULT_BRANCH:-main}"
    fi
    OUTPUT_GENERATED=true
    return 0
  fi
}

# Main logic
if ! git rev-parse --is-inside-work-tree >/dev/null; then
  log_message "error" "Not inside a Git repository"
  show_help
  rm -rf "$TEMP_DIR"
  exit 1
fi

if ! check_tools git; then
  show_help
  rm -rf "$TEMP_DIR"
  exit 1
fi

if [ "$ALL_REM" = "true" ]; then
  summarize_all
elif [ -z "$REMOTE_NAME" ]; then
  REMOTE_NAME=$(find_radicle_remote)
  if [ -z "$REMOTE_NAME" ] && rad inspect >/dev/null 2>&1; then
    REMOTE_NAME="rad"
  fi
fi

if [ -n "$REMOTE_NAME" ]; then
  REMOTE_URL=$(git remote get-url "$REMOTE_NAME" 2>/dev/null || echo "")
  log_message "debug" "Processing remote: $REMOTE_NAME ($REMOTE_URL)"
  if [[ "$REMOTE_URL" =~ ^rad:// ]] || rad inspect >/dev/null 2>&1; then
    handle_radicle || {
      log_message "warning" "Failed to process Radicle repository. Falling back to Git details."
      get_local_git_details
      FULL_NAME=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null || echo "N/A")
      VISIBILITY="public"
      HOST="radicle"
      DEFAULT_BRANCH="$CURRENT_BRANCH"
    }
  else
    handle_centralized "$REMOTE_URL" || {
      log_message "warning" "Failed to process centralized Git repository."
      get_local_git_details
      FULL_NAME=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null || echo "N/A")
      HOST="unknown"
    }
  fi
else
  log_message "warning" "No Radicle remote found. Processing as centralized Git."
  REMOTE_NAME="origin"
  REMOTE_URL=$(git remote get-url "$REMOTE_NAME" 2>/dev/null || echo "")
  if [ -z "$REMOTE_URL" ]; then
    log_message "error" "No remote URL found"
    get_local_git_details
    FULL_NAME=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null || echo "N/A")
    HOST="unknown"
  else
    handle_centralized "$REMOTE_URL" || {
      log_message "warning" "Failed to process centralized Git repository."
      get_local_git_details
      FULL_NAME=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null || echo "N/A")
      HOST="unknown"
    }
  fi
fi

# Ensure output
output_info || {
  log_message "error" "Failed to generate output"
  show_help
}

if [ "$OUTPUT_GENERATED" = "false" ]; then
  log_message "error" "No output generated"
  show_help
fi

# Clean up
rm -rf "$TEMP_DIR"
exit 0
