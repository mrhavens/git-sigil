#!/bin/bash

# Exit on error
set -e

# Check if we're in a Git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: Not inside a Git repository"
  exit 1
fi

# Check for required tools
for cmd in git rad jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: $cmd is required but not installed"
    exit 1
  fi
done

# Ensure rad is initialized for the repository
if ! rad inspect >/dev/null 2>&1; then
  echo "Error: This repository is not initialized with Radicle. Run 'rad init' first."
  exit 1
fi

# Get repository details using rad commands
REPO_RID=$(rad inspect --rid 2>/dev/null | grep -o 'rad:[a-zA-Z0-9]\+' || echo "N/A")
if [ "$REPO_RID" == "N/A" ]; then
  echo "Error: Could not retrieve Repository ID (RID)"
  exit 1
fi

# Get repository name and visibility
REPO_INFO=$(rad inspect --json 2>/dev/null | jq -r '.name, .visibility.type' || echo "N/A N/A")
read REPO_NAME VISIBILITY <<< "$REPO_INFO"
if [ "$REPO_NAME" == "N/A" ]; then
  echo "Error: Could not retrieve repository name"
  exit 1
fi

# Get user identity (DID and NID)
USER_INFO=$(rad self --json 2>/dev/null | jq -r '.did, .nid' || echo "N/A N/A")
read DID NID <<< "$USER_INFO"
if [ "$DID" == "N/A" ]; then
  echo "Error: Could not retrieve user identity (DID)"
  exit 1
fi

# Get preferred seed nodes from config
PREFERRED_SEEDS=$(rad config --json 2>/dev/null | jq -r '.preferredSeeds[]' | tr '\n' ',' | sed 's/,$//')
if [ -z "$PREFERRED_SEEDS" ]; then
  PREFERRED_SEEDS="None configured"
fi

# Get local repository details
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "N/A")
CURRENT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "N/A")
REPO_STATUS=$(git status --porcelain 2>/dev/null | wc -l | xargs)
if [ "$REPO_STATUS" -eq 0 ]; then
  REPO_STATUS="Clean"
else
  REPO_STATUS="Dirty ($REPO_STATUS uncommitted changes)"
fi

# Get sync status (peers seeding the repo)
SYNC_STATUS=$(rad sync status --json 2>/dev/null | jq -r '.peers[]?.node' | tr '\n' ',' | sed 's/,$//' || echo "No peers found")
if [ -z "$SYNC_STATUS" ]; then
  SYNC_STATUS="No peers found"
fi

# Get web view URL (if public)
if [ "$VISIBILITY" == "public" ]; then
  PUBLIC_EXPLORER=$(rad config --json | jq -r '.publicExplorer' | sed "s@\\\$host@seed.radicle.garden@g;s@\\\$rid@$REPO_RID@g;s@\\\$path@@g")
else
  PUBLIC_EXPLORER="N/A (Private repository)"
fi

# Output repository information
cat <<EOF
Radicle Repository Information:
------------------------------
Repository Name: $REPO_NAME
Repository ID (RID): $REPO_RID
Visibility: $VISIBILITY
User DID: $DID
Node ID (NID): $NID
Preferred Seed Nodes: $PREFERRED_SEEDS
Web View URL: $PUBLIC_EXPLORER
Default Branch: $DEFAULT_BRANCH
Current Branch: $CURRENT_BRANCH
Current Commit: $CURRENT_COMMIT
Repository Status: $REPO_STATUS
Seeding Peers: $SYNC_STATUS
------------------------------
Clone Command: rad clone $REPO_RID
Sync Command: rad sync $REPO_RID
Initialize Command (if not cloned): rad init --name $REPO_NAME --default-branch $DEFAULT_BRANCH --visibility $VISIBILITY
------------------------------
Notes:
- To clone, ensure Radicle is installed (see https://radicle.xyz).
- For private repositories, ensure you have the necessary cryptographic keys.
- Syncing requires at least one seeding peer to be online.
EOF
