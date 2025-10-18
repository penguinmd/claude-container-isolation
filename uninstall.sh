#!/usr/bin/env bash
# Uninstallation script for Container Isolation plugin
# https://github.com/penguinmd/claude-container-isolation

set -e

PLUGIN_NAME="container-isolation"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Container Isolation - Uninstallation                      ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo ""

# Warn about containers
echo -e "${YELLOW}⚠ WARNING: This will uninstall the plugin but NOT remove your containers${NC}"
echo -e "${YELLOW}  To remove containers from your projects, run:${NC}"
echo -e "${YELLOW}    cd /path/to/project${NC}"
echo -e "${YELLOW}    ./scripts/container destroy${NC}"
echo ""
read -p "Continue with uninstall? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi
echo ""

# Uninstall plugin
echo -e "${BLUE}[1/2]${NC} Uninstalling ${PLUGIN_NAME} plugin..."

PLUGIN_DIR="$HOME/.claude/plugins/cache/${PLUGIN_NAME}"
if [ -d "$PLUGIN_DIR" ]; then
    # Try to uninstall via CLI first
    if command -v claude &> /dev/null; then
        claude plugin uninstall "$PLUGIN_NAME" 2>/dev/null || true
    fi

    # Remove directory if still exists
    if [ -d "$PLUGIN_DIR" ]; then
        rm -rf "$PLUGIN_DIR"
    fi

    echo -e "${GREEN}✓ Plugin uninstalled${NC}"
else
    echo -e "${YELLOW}  (Plugin not found)${NC}"
fi
echo ""

# Verify removal
echo -e "${BLUE}[2/2]${NC} Verifying removal..."

if [ -d "$PLUGIN_DIR" ]; then
    echo -e "${RED}✗ Plugin directory still exists${NC}"
    echo -e "${YELLOW}⚠ Some components could not be removed${NC}"
else
    echo -e "${GREEN}✓ Uninstallation complete${NC}"
fi
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║             Uninstallation Complete!                       ║${NC}"
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo ""
echo -e "${BLUE}What was removed:${NC}"
echo -e "  ✓ ~/.claude/plugins/cache/${PLUGIN_NAME}/ (plugin files)"
echo ""
echo -e "${YELLOW}What was NOT removed:${NC}"
echo -e "  • Container environments in your projects"
echo -e "  • Project .claude-container/ directories"
echo -e "  • Project scripts/container files"
echo ""
echo -e "${BLUE}To remove containers from projects:${NC}"
echo -e "  1. cd /path/to/project"
echo -e "  2. ./scripts/container destroy"
echo -e "  3. rm -rf .claude-container/ scripts/"
echo ""
echo -e "${BLUE}To reinstall:${NC}"
echo -e "  curl -sSL https://raw.githubusercontent.com/penguinmd/claude-container-isolation/main/install.sh | bash"
echo ""
