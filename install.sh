#!/usr/bin/env bash
# Installation script for Container Isolation plugin
# https://github.com/penguinmd/claude-container-isolation

set -e

PLUGIN_NAME="container-isolation"
MARKETPLACE_REPO="penguinmd/claude-container-isolation-marketplace"
PLUGIN_SOURCE="container-isolation@container-isolation-marketplace"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Container Isolation for Claude Code - Installation       ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo ""

# Check prerequisites
echo -e "${BLUE}[1/3]${NC} Checking prerequisites..."

# Check if claude CLI exists
if ! command -v claude &> /dev/null; then
    echo -e "${RED}✗ Claude Code CLI not found${NC}"
    echo "Please install Claude Code CLI first: https://claude.com/claude-code"
    exit 1
fi

# Check macOS version
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${YELLOW}⚠ Warning: This plugin is designed for macOS 26+ with Apple Container${NC}"
fi

# Check architecture
ARCH=$(uname -m)
if [[ "$ARCH" != "arm64" ]]; then
    echo -e "${YELLOW}⚠ Warning: This plugin requires Apple Silicon (arm64), found: $ARCH${NC}"
fi

# Check if Apple Container is installed
if ! command -v container &> /dev/null; then
    echo -e "${YELLOW}⚠ Warning: Apple Container CLI not found${NC}"
    echo "  Install with: brew install --cask container"
    echo "  Or visit: https://github.com/apple/container"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}✓ Prerequisites checked${NC}"
echo ""

# Add marketplace if not already added
echo -e "${BLUE}[2/3]${NC} Adding plugin marketplace..."

# Check if marketplace is already added (this will fail silently if already added)
if claude --help &> /dev/null; then
    # Try to add marketplace - will error if already exists, but we'll ignore it
    claude plugin marketplace add "$MARKETPLACE_REPO" 2>/dev/null || echo -e "${YELLOW}  (Marketplace already added)${NC}"
fi

echo -e "${GREEN}✓ Marketplace configured${NC}"
echo ""

# Install plugin
echo -e "${BLUE}[3/3]${NC} Installing ${PLUGIN_NAME} plugin..."

# Check if plugin is already installed
PLUGIN_DIR="$HOME/.claude/plugins/cache/${PLUGIN_NAME}"
if [ -d "$PLUGIN_DIR" ]; then
    echo -e "${YELLOW}  Plugin already installed, updating...${NC}"
    cd "$PLUGIN_DIR"
    git pull origin main 2>/dev/null || echo -e "${YELLOW}  (Could not update - using existing version)${NC}"
else
    # Install the plugin
    if ! claude plugin install "$PLUGIN_SOURCE" 2>/dev/null; then
        echo -e "${RED}✗ Plugin installation failed${NC}"
        echo "Please try manually: /plugin install $PLUGIN_SOURCE"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Plugin installed${NC}"
echo ""

echo -e "${GREEN}✓ Installation complete!${NC}"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                 Installation Successful!                   ║${NC}"
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo ""
echo -e "${BLUE}Quick Start:${NC}"
echo -e "  1. Navigate to your project: ${YELLOW}cd /path/to/your/project${NC}"
echo -e "  2. Start Claude Code: ${YELLOW}claude${NC}"
echo -e "  3. Run: ${YELLOW}/container-isolation:container${NC}"
echo ""
echo -e "${BLUE}Available Command:${NC}"
echo -e "  ${YELLOW}/container-isolation:container${NC} - Interactive menu for container management"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo -e "  README: ~/.claude/plugins/cache/${PLUGIN_NAME}/README.md"
echo -e "  Skill:  ~/.claude/plugins/cache/${PLUGIN_NAME}/SKILL.md"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Ensure Apple Container is installed: ${YELLOW}brew install --cask container${NC}"
echo -e "  2. Navigate to a project directory"
echo -e "  3. Run ${YELLOW}/container-isolation:container${NC} and select 'Set up new environment'"
echo ""
echo -e "For support: https://github.com/penguinmd/claude-container-isolation/issues"
echo ""
