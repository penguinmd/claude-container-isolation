---
name: Container Isolation for Claude Code
description: Create secure, isolated development environments using Apple Container for running Claude Code safely
when_to_use: when you need to test untrusted or AI-generated code safely, experiment with new libraries without risking your system, or create reproducible development environments
version: 1.0.0
languages: all
dependencies: Apple Container (macOS 26+), Apple Silicon Mac
---

# Container Isolation for Claude Code

## Overview

This skill creates isolated containerized environments using Apple's Container technology (macOS 26+) for safe Claude Code execution. Each container runs in its own lightweight VM with hypervisor-level isolation, allowing you to test untrusted code, experiment with new libraries, and create reproducible development environments without risking your host system.

## When to Use

- Testing AI-generated code you don't fully trust
- Experimenting with unfamiliar libraries or frameworks
- Learning new technologies in a safe sandbox
- Creating reproducible development environments
- Running potentially risky operations in isolation

## Prerequisites

| Requirement | Check Command | Expected Result |
|-------------|---------------|-----------------|
| macOS 26+ | `sw_vers` | ProductVersion: 26.x.x |
| Apple Silicon | `uname -m` | arm64 |
| Apple Container | `which container` | /usr/local/bin/container |

If Apple Container is not installed, the skill will guide you through installation.

## Quick Start

```bash
# 1. Run skill in your project directory
cd /path/to/your/project
claude
> /isolated-dev-setup

# 2. Choose mode (Playground/Development/Custom)
# Skill defaults to current directory

# 3. Enter container
./scripts/container shell

# Inside container
root@container:/workspace# claude
```

## Three Modes

| Mode | Security | Use Case | Questions | Network | Storage |
|------|----------|----------|-----------|---------|---------|
| **Playground** | ★★★★★ Maximum | Untrusted code testing | 2 | API only | Isolated volume |
| **Development** | ★☆☆☆☆ Minimal | Trusted project work | 2 | Full internet | Host sync (bind mount) |
| **Custom** | Configurable | Specific requirements | 10-12 | User choice | User choice |

## What Gets Created

In your project directory:
```
.claude-container/
├── config.json              # Machine-readable configuration
├── manifest.json            # Tracks what was created
├── CONTAINER-SPEC.md        # Human-readable specifications
├── Containerfile           # Container image definition
└── mcp-config.json         # MCP server configuration

scripts/
├── container               # Main helper script (5 commands)
├── setup-mcp.sh           # MCP server installer
└── sync-skills.sh         # Skills synchronization

.gitignore                  # Updated to exclude container files
```

## Common Commands

```bash
./scripts/container start    # Start container
./scripts/container shell    # Enter interactive shell
./scripts/container status   # Check if running
./scripts/container stop     # Stop container (preserves data)
./scripts/container destroy  # Complete removal with confirmation
```

## Troubleshooting

**Container CLI not found:**
```bash
# Install via Homebrew
brew install --cask container

# Or download from GitHub
curl -LO https://github.com/apple/container/releases/download/0.1.0/container-0.1.0-installer-signed.pkg
sudo installer -pkg container-0.1.0-installer-signed.pkg -target /
```

**Permission denied:**
- Installation requires admin/sudo access
- Check: `sudo -v`

**Skill not working:**
- Ensure you're in a project directory
- Skill defaults to current working directory (`pwd`)

## Features

### Security Isolation
- VM-per-container (hypervisor-level isolation)
- Network restrictions (API-only, development, or full)
- Isolated or shared filesystem
- Separate or shared API credentials

### Skills Sync
- Option to copy your Claude skills into container (default: Yes)
- Container has same superpowers as host Claude
- Keeps host skills read-only

### MCP Integration
- Install MCP servers inside container (isolated)
- Or connect to host MCP servers (Custom mode only, with warnings)
- Supports: Filesystem, Brave Search, GitHub, PostgreSQL

### Git Integration
- Configure git credentials in container
- Support for Personal Access Tokens or SSH keys
- Environment variable management

## See Also

- **Full documentation:** Generated `CONTAINER-SPEC.md` in your project
- **GitHub README:** https://github.com/USER/claude-container-isolation
- **Apple Container:** https://github.com/apple/container
- **Configuration reference:** `CONFIGURATION.md`
- **Advanced usage:** `ADVANCED.md`
