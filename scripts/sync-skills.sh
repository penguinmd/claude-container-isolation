#!/usr/bin/env bash
set -euo pipefail

# Skills sync script for container
# This script syncs skills from the host to the container's .claude directory

WORKSPACE="/workspace"
SKILLS_SOURCE="${WORKSPACE}/.claude/skills"
CLAUDE_DIR="/root/.claude"
SKILLS_TARGET="${CLAUDE_DIR}/skills"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running in container
if [ ! -f /.containerenv ]; then
    log_warn "Not running in a container - this script is meant for container operations"
fi

log_info "Syncing skills to container..."

# Check if source skills directory exists
if [ ! -d "$SKILLS_SOURCE" ]; then
    log_warn "Skills source directory not found: $SKILLS_SOURCE"
    log_info "Creating empty skills directory..."
    mkdir -p "$SKILLS_SOURCE"
fi

# Create Claude directory if it doesn't exist
if [ ! -d "$CLAUDE_DIR" ]; then
    log_info "Creating Claude directory: $CLAUDE_DIR"
    mkdir -p "$CLAUDE_DIR"
fi

# Remove existing target directory if it exists
if [ -d "$SKILLS_TARGET" ] || [ -L "$SKILLS_TARGET" ]; then
    log_info "Removing existing skills directory: $SKILLS_TARGET"
    rm -rf "$SKILLS_TARGET"
fi

# Create symbolic link
log_info "Creating symbolic link from $SKILLS_SOURCE to $SKILLS_TARGET"
ln -s "$SKILLS_SOURCE" "$SKILLS_TARGET"

# Verify the link
if [ -L "$SKILLS_TARGET" ]; then
    log_info "Symbolic link created successfully"
    log_info "Link target: $(readlink "$SKILLS_TARGET")"
else
    log_error "Failed to create symbolic link"
    exit 1
fi

# Count skills
skill_count=0
if [ -d "$SKILLS_SOURCE" ]; then
    skill_count=$(find "$SKILLS_SOURCE" -mindepth 1 -maxdepth 1 -type d | wc -l)
fi

log_info "Skills sync complete"
echo ""
echo "Skills Summary:"
echo "  Source: $SKILLS_SOURCE"
echo "  Target: $SKILLS_TARGET"
echo "  Skills available: $skill_count"
echo ""

# List available skills
if [ "$skill_count" -gt 0 ]; then
    echo "Available skills:"
    find "$SKILLS_SOURCE" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | sed 's/^/  - /'
else
    echo "No skills found in $SKILLS_SOURCE"
fi
