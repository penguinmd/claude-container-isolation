#!/usr/bin/env bash
set -euo pipefail

# MCP setup script for container initialization
# This script configures the Model Context Protocol in the container

CLAUDE_DIR="/root/.claude"
MCP_CONFIG="${CLAUDE_DIR}/mcp_config.json"
WORKSPACE="/workspace"

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
if [ ! -f /.dockerenv ]; then
    log_warn "Not running in a Docker container - this script is meant for container initialization"
fi

log_info "Setting up MCP configuration..."

# Create .claude directory if it doesn't exist (shouldn't be needed due to volume mount)
if [ ! -d "$CLAUDE_DIR" ]; then
    log_warn "Claude directory not found at $CLAUDE_DIR, creating..."
    mkdir -p "$CLAUDE_DIR"
fi

# Check if mcp_config.json exists
if [ ! -f "$MCP_CONFIG" ]; then
    log_warn "MCP config not found at $MCP_CONFIG"
    log_info "Creating default MCP configuration..."

    cat > "$MCP_CONFIG" << 'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/workspace"
      ]
    }
  }
}
EOF
    log_info "Default MCP configuration created"
else
    log_info "MCP configuration already exists"
fi

# Validate JSON
if command -v jq &> /dev/null; then
    if jq empty "$MCP_CONFIG" 2>/dev/null; then
        log_info "MCP configuration is valid JSON"
    else
        log_error "MCP configuration is not valid JSON"
        exit 1
    fi
else
    log_warn "jq not available, skipping JSON validation"
fi

# Check if Node.js is available for MCP servers
if command -v node &> /dev/null; then
    log_info "Node.js version: $(node --version)"
else
    log_warn "Node.js not found - MCP servers may not work"
fi

if command -v npx &> /dev/null; then
    log_info "npx is available"
else
    log_warn "npx not found - MCP servers may not work"
fi

log_info "MCP setup complete"

# Display configuration summary
echo ""
echo "MCP Configuration Summary:"
echo "  Config file: $MCP_CONFIG"
echo "  Workspace: $WORKSPACE"
echo ""

if [ -f "$MCP_CONFIG" ]; then
    echo "Configured MCP servers:"
    if command -v jq &> /dev/null; then
        jq -r '.mcpServers | keys[]' "$MCP_CONFIG" 2>/dev/null || echo "  (unable to parse)"
    else
        echo "  (jq not available for parsing)"
    fi
fi
