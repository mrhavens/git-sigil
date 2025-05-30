#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

GIT_REMOTE_NAME="github"
REPO_NAME=$(basename "$(pwd)")

# ────────────────
# Logging Helpers
# ────────────────
info()  { echo -e "\e[1;34m[INFO]\e[0m $*"; }
warn()  { echo -e "\e[1;33m[WARN]\e[0m $*"; }
error() { echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; exit 1; }

# ────────────────
# Check/install git
# ────────────────
if ! command -v git &>/dev/null; then
  info "Installing git..."
  sudo apt update && sudo apt install git -y || error "Failed to install git"
else
  info "Git already installed: $(git --version)"
fi

# ────────────────
# Check/install GitHub CLI
# ────────────────
if ! command -v gh &>/dev/null; then
  info "Installing GitHub CLI..."
  type -p curl >/dev/null || sudo apt install curl -y
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update && sudo apt install gh -y || error "Failed to install GitHub CLI"
else
  info "GitHub CLI already installed: $(gh --version | head -n 1)"
fi

# ────────────────
# Authenticate GitHub CLI
# ────────────────
if ! gh auth status &>/dev/null; then
  info "Authenticating GitHub CLI..."
  gh auth login || error "GitHub authentication failed"
else
  info "GitHub CLI authenticated as: $(gh auth status | grep 'Logged in as' | cut -d ':' -f2 | xargs)"
fi

# ────────────────
# Initialize Git Repo
# ────────────────
if [ ! -d ".git" ]; then
  info "Initializing local Git repo..."
  git init || error "Git init failed"
  git add . || warn "No files to add"
  git commit -m "Initial commit" || warn "Nothing to commit"
else
  info "Git repo already initialized."
fi

# ────────────────
# Create GitHub remote if missing
# ────────────────
if ! git remote get-url "$GIT_REMOTE_NAME" &>/dev/null; then
  info "Creating GitHub repo '$REPO_NAME' via CLI..."
  gh repo create "$REPO_NAME" --public --source=. --remote="$GIT_REMOTE_NAME" --push || error "GitHub repo creation failed"
else
  info "Remote '$GIT_REMOTE_NAME' already set to: $(git remote get-url $GIT_REMOTE_NAME)"
fi

# ────────────────
# Commit changes if needed
# ────────────────
if ! git diff --quiet || ! git diff --cached --quiet; then
  info "Changes detected — committing..."
  git add . || warn "Nothing staged"
  git commit -m "Update: $(date '+%Y-%m-%d %H:%M:%S')" || warn "Nothing to commit"
else
  info "No uncommitted changes."
fi

# ────────────────
# Push if branch is ahead
# ────────────────
if git status | grep -q "Your branch is ahead"; then
  info "Pushing changes to GitHub..."
  git push "$GIT_REMOTE_NAME" "$(git rev-parse --abbrev-ref HEAD)" || error "Push failed"
else
  info "No push needed. Local and remote are synced."
fi
