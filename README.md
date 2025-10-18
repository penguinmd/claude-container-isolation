# Container Isolation for Claude Code

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-26%2B-blue.svg)](https://www.apple.com/macos/)
[![Apple Silicon](https://img.shields.io/badge/Apple-Silicon-black.svg)](https://www.apple.com/mac/)

Create secure, isolated development environments using Apple Container technology for safe Claude Code execution.

## Overview

This Claude Code skill creates isolated containerized environments using Apple's Container technology (macOS 26+). Each container runs in its own lightweight VM with hypervisor-level isolation, allowing you to:

- Test AI-generated code you don't fully trust
- Experiment with unfamiliar libraries or frameworks
- Learn new technologies in a safe sandbox
- Create reproducible development environments
- Run potentially risky operations in isolation

## Prerequisites

### Required

| Component | Version | Check Command |
|-----------|---------|---------------|
| macOS | 26.0+ | `sw_vers` |
| Architecture | Apple Silicon (arm64) | `uname -m` |
| Apple Container | Latest | `which container` |
| Claude Code CLI | Latest | `which claude` |

### Installing Apple Container

**Option 1: Homebrew (Recommended)**
```bash
brew install --cask container
```

**Option 2: Manual Installation**
```bash
# Download the signed installer package
curl -LO https://github.com/apple/container/releases/download/0.1.0/container-0.1.0-installer-signed.pkg

# Install (requires sudo)
sudo installer -pkg container-0.1.0-installer-signed.pkg -target /

# Verify installation
container --version
```

**Option 3: Build from Source**
```bash
git clone https://github.com/apple/container.git
cd container
make install
```

### Verifying Prerequisites

Run this command to check all prerequisites:
```bash
# Check macOS version
sw_vers

# Check architecture
uname -m

# Check Container CLI
which container
container --version

# Check Claude CLI
which claude
claude --version
```

## Installation

### One-Line Installation (Recommended)

The easiest way to install is with our automated installation script:

```bash
curl -sSL https://raw.githubusercontent.com/penguinmd/claude-container-isolation/main/install.sh | bash
```

This will:
- Add the plugin marketplace
- Install the container-isolation plugin
- Verify installation
- Display next steps

**That's it!** The plugin is now available in all your projects.

### Manual Installation

If you prefer to install manually:

```bash
# Start Claude Code
claude

# Add the marketplace
/plugin marketplace add penguinmd/claude-container-isolation-marketplace

# Install the plugin
/plugin install container-isolation@container-isolation-marketplace
```

### Verifying Installation

After installation, verify everything is working:

```bash
# Check plugin is installed
ls -la ~/.claude/plugins/cache/container-isolation/

# Start Claude Code
claude

# Try the command (should show an interactive menu)
/container-isolation:container

# Check plugin list
/plugin list
```

### Updating

The plugin automatically checks for updates on each Claude Code session start. To manually update:

```bash
# In Claude Code
/plugin update container-isolation

# Or reinstall
curl -sSL https://raw.githubusercontent.com/penguinmd/claude-container-isolation/main/install.sh | bash
```

### Uninstalling

To completely remove the plugin:

```bash
curl -sSL https://raw.githubusercontent.com/penguinmd/claude-container-isolation/main/uninstall.sh | bash
```

Or manually:

```bash
# In Claude Code
/plugin uninstall container-isolation
```

**Note:** This will NOT remove containers from your projects. To remove containers, run `./scripts/container destroy` in each project first.

## Quick Start

### 1. Navigate to Your Project

```bash
cd /path/to/your/project
```

### 2. Run the Container Command

```bash
claude
> /container-isolation:container
```

### 3. Select Your Action

The command will present an interactive menu with these options:

- **Set up new environment** - Create a new isolated container (choose Playground/Development/Custom mode)
- **Check status** - View current container status
- **Open shell** - Enter an interactive shell session
- **Stop container** - Stop the running container

If setting up a new environment, you'll be asked to select one of three modes:

- **Playground Mode** (Maximum Security) - For untrusted code
- **Development Mode** (Minimal Restrictions) - For trusted projects
- **Custom Mode** (Configurable) - For specific requirements

### 4. Start Using Your Container

```bash
# Start the container
./scripts/container start

# Enter the container shell
./scripts/container shell

# Inside the container, use Claude as normal
root@container:/workspace# claude
```

## Three Operating Modes

### Playground Mode (Maximum Security)

**Use for:** Testing untrusted AI-generated code, experimenting with unknown libraries

**Security Level:** ★★★★★

**Features:**
- Network: API access only (Claude, Anthropic endpoints)
- Storage: Isolated container volume (no host access)
- API Keys: Separate container credentials
- Questions: 2 (mode + skill sync)

**Example Setup:**
```
Project Directory: /Users/you/test-project
┌─────────────────────────────────────┐
│  HOST SYSTEM (Protected)            │
│  - No container network access      │
│  - No filesystem access             │
│  - Separate API credentials         │
└─────────────────────────────────────┘
         ↕ (API calls only)
┌─────────────────────────────────────┐
│  CONTAINER (Isolated)                │
│  /workspace/ (isolated volume)       │
│  - Full internet blocked             │
│  - Code runs safely                  │
└─────────────────────────────────────┘
```

### Development Mode (Minimal Restrictions)

**Use for:** Working on trusted projects with full productivity

**Security Level:** ★☆☆☆☆

**Features:**
- Network: Full internet access
- Storage: Bind mount to host project directory (live sync)
- API Keys: Shared with host
- Questions: 2 (mode + skill sync)

**Example Setup:**
```
Project Directory: /Users/you/my-app
┌─────────────────────────────────────┐
│  HOST SYSTEM                         │
│  /Users/you/my-app/                  │
│  - Files instantly sync              │
│  - Shared API credentials            │
└─────────────────────────────────────┘
         ↕ (bind mount sync)
┌─────────────────────────────────────┐
│  CONTAINER                           │
│  /workspace/ → /Users/you/my-app/    │
│  - Full network access               │
│  - Edit with host tools              │
└─────────────────────────────────────┘
```

### Custom Mode (Configurable)

**Use for:** Specific security/workflow requirements

**Security Level:** Configurable (1-5 stars)

**Features:**
- Network: User choice (isolated/development/full)
- Storage: User choice (isolated/bind mount/mixed)
- API Keys: User choice (separate/shared)
- MCP Servers: User choice (container/host/both)
- Git: User choice (configure credentials)
- Questions: 10-12 (detailed configuration)

**Configuration Options:**
1. Network policy (isolated/development/full)
2. Storage strategy (isolated volume/bind mount/hybrid)
3. API credential sharing (yes/no)
4. Skill synchronization (yes/no)
5. MCP server installation (container/host/both)
6. MCP server selection (filesystem/brave/github/postgres)
7. Git credential configuration (yes/no)
8. Git credential type (PAT/SSH)
9. Additional environment variables
10. Custom container settings

## What Gets Created

When you run the skill, it creates the following structure in your project:

```
your-project/
├── .claude-container/
│   ├── config.json              # Machine-readable configuration
│   ├── manifest.json            # Tracks created files and settings
│   ├── CONTAINER-SPEC.md        # Human-readable documentation
│   ├── Containerfile           # Container image definition
│   └── mcp-config.json         # MCP server configuration
│
├── scripts/
│   ├── container               # Main management script (5 commands)
│   ├── setup-mcp.sh           # MCP server installation helper
│   └── sync-skills.sh         # Skills synchronization helper
│
└── .gitignore                  # Updated to exclude container artifacts
```

### Generated Files Explained

**`.claude-container/config.json`**
- Machine-readable configuration
- Used by scripts for automation
- Contains all container settings

**`.claude-container/manifest.json`**
- Tracks what the skill created
- Records timestamps and versions
- Used for cleanup and updates

**`.claude-container/CONTAINER-SPEC.md`**
- Human-readable documentation
- Explains your specific setup
- Security considerations
- Usage instructions

**`.claude-container/Containerfile`**
- Defines the container image
- Base image + dependencies
- Environment configuration
- Startup commands

**`.claude-container/mcp-config.json`**
- MCP server configurations
- Server endpoints and settings
- Credentials (if applicable)

**`scripts/container`**
- Main management script
- 5 core commands: start, stop, shell, status, destroy
- Handles container lifecycle

**`scripts/setup-mcp.sh`**
- Installs MCP servers inside container
- Configures server settings
- Verifies installation

**`scripts/sync-skills.sh`**
- Copies skills from host to container
- Maintains read-only host skills
- Updates on demand

## Common Commands

### Container Management

```bash
# Start the container (creates if needed)
./scripts/container start

# Enter interactive shell
./scripts/container shell

# Check container status
./scripts/container status

# Stop the container (preserves data)
./scripts/container stop

# Complete removal (prompts for confirmation)
./scripts/container destroy
```

### Working Inside the Container

```bash
# Enter container
./scripts/container shell

# Inside container - use Claude
root@container:/workspace# claude

# Run commands
root@container:/workspace# npm install
root@container:/workspace# python script.py

# Exit container
root@container:/workspace# exit
```

### Skills Synchronization

```bash
# Sync skills from host to container (if enabled)
./scripts/sync-skills.sh

# Inside container - verify skills
root@container:~# claude
> /help
```

### MCP Server Management

```bash
# Setup MCP servers (run inside container)
root@container:/workspace# /workspace/scripts/setup-mcp.sh

# Verify MCP configuration
root@container:/workspace# cat ~/.config/claude/mcp-config.json
```

## How It Works

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        HOST SYSTEM                          │
│                                                             │
│  ┌─────────────────┐         ┌──────────────────┐          │
│  │  Claude Code    │         │  Your Project    │          │
│  │  CLI (host)     │         │  /path/to/proj   │          │
│  └─────────────────┘         └──────────────────┘          │
│                                       │                     │
│                                       ↓                     │
│                      ┌────────────────────────────┐         │
│                      │   Skill Execution          │         │
│                      │   /container               │         │
│                      └────────────────────────────┘         │
│                                       │                     │
│                                       ↓                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Apple Container Runtime                      │  │
│  │  (VM with hypervisor-level isolation)                │  │
│  │                                                       │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │  CONTAINER ENVIRONMENT                         │  │  │
│  │  │                                                 │  │  │
│  │  │  /workspace/  ← Your code                      │  │  │
│  │  │  /root/.claude/  ← Skills (synced)             │  │  │
│  │  │  /root/.config/claude/  ← MCP config           │  │  │
│  │  │                                                 │  │  │
│  │  │  Claude CLI (container instance)               │  │  │
│  │  │  - Isolated or shared API credentials          │  │  │
│  │  │  - Restricted or full network access           │  │  │
│  │  │  - Safe code execution environment             │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Security Isolation Levels

```
PLAYGROUND MODE (Maximum Security)
════════════════════════════════════
Host System          Container
    │                    │
    │  API calls only    │
    ├───────────────────→│
    │                    │
    │  No filesystem     │
    │     access         │
    │                    │

DEVELOPMENT MODE (Minimal Restrictions)
════════════════════════════════════
Host System          Container
    │                    │
    │  Bind mount sync   │
    │←──────────────────→│
    │                    │
    │  Full network      │
    │  Shared creds      │
    │                    │

CUSTOM MODE (User Configured)
════════════════════════════════════
Host System          Container
    │                    │
    │  ┌─ Network: ?     │
    │  ├─ Storage: ?     │
    │  ├─ API: ?         │
    │  └─ MCP: ?         │
    │                    │
```

## Troubleshooting

### Container CLI Not Found

**Symptom:** `container: command not found`

**Solution:**
```bash
# Install via Homebrew
brew install --cask container

# Verify installation
which container
container --version
```

### Permission Denied

**Symptom:** `Permission denied` when running container commands

**Solution:**
```bash
# Verify you have admin access
sudo -v

# Reinstall Apple Container
brew reinstall --cask container

# Check permissions on scripts
chmod +x ./scripts/container
chmod +x ./scripts/setup-mcp.sh
chmod +x ./scripts/sync-skills.sh
```

### Container Won't Start

**Symptom:** Container fails to start or crashes

**Solution:**
```bash
# Check container status
./scripts/container status

# View container logs
container logs <container-name>

# Destroy and recreate
./scripts/container destroy
./scripts/container start
```

### Skills Not Available in Container

**Symptom:** Skills don't work inside container

**Solution:**
```bash
# Verify skills were synced
./scripts/container shell
root@container:/workspace# ls -la /root/.claude/

# Re-sync skills from host
exit
./scripts/sync-skills.sh

# Verify sync
./scripts/container shell
root@container:/workspace# claude
> /help
```

### MCP Servers Not Working

**Symptom:** MCP servers not accessible in container

**Solution:**
```bash
# Enter container
./scripts/container shell

# Run MCP setup script
root@container:/workspace# /workspace/scripts/setup-mcp.sh

# Verify configuration
root@container:/workspace# cat ~/.config/claude/mcp-config.json

# Restart Claude
root@container:/workspace# exit
./scripts/container stop
./scripts/container start
```

### Network Connectivity Issues

**Symptom:** Can't access internet or APIs from container

**Solution:**
```bash
# Check network mode in config
cat .claude-container/config.json | grep network

# Test connectivity from inside container
./scripts/container shell
root@container:/workspace# ping -c 3 8.8.8.8
root@container:/workspace# curl -I https://api.anthropic.com

# If in Playground mode, only API access is allowed
# Switch to Development or Custom mode if you need full access
```

### File Sync Problems (Development Mode)

**Symptom:** Changes not appearing in host/container

**Solution:**
```bash
# Verify bind mount configuration
cat .claude-container/config.json | grep storage

# Check if container is running
./scripts/container status

# Restart container to refresh mount
./scripts/container stop
./scripts/container start

# Verify mount inside container
./scripts/container shell
root@container:/workspace# ls -la
root@container:/workspace# pwd
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/penguinmd/claude-container-isolation.git
cd claude-container-isolation

# Test the skill
cd /path/to/test/project
claude
> /container
```

### Testing

```bash
# Run tests (coming soon)
./tests/run-tests.sh
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## See Also

- [Apple Container Documentation](https://github.com/apple/container)
- [Claude Code CLI Documentation](https://claude.com/claude-code)
- [MCP Server Documentation](https://modelcontextprotocol.io)
- [CONFIGURATION.md](CONFIGURATION.md) - Detailed configuration reference
- [ADVANCED.md](ADVANCED.md) - Advanced usage patterns

## Support

- Open an issue on GitHub
- Check existing issues for solutions
- Review the generated `CONTAINER-SPEC.md` in your project
- Consult Apple Container documentation

---

Made with Claude Code | Secure Development Made Easy
