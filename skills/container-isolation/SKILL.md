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

If Apple Container is not installed, guide the user through installation (see Implementation section).

---

## Implementation Instructions

**When invoked, follow these steps exactly:**

### Step 1: Check Prerequisites

1. **Verify working directory:**
   ```bash
   PROJECT_DIR=$(pwd)
   ```
   Announce the detected project directory to user.

2. **Check Apple Container installation:**
   ```bash
   which container
   ```

   **If not found:**
   - Inform user Apple Container is required
   - Provide installation instructions:
     ```
     Install Apple Container:

     Option 1 (Recommended):
       brew install --cask container

     Option 2 (Manual):
       curl -LO https://github.com/apple/container/releases/download/0.1.0/container-0.1.0-installer-signed.pkg
       sudo installer -pkg container-0.1.0-installer-signed.pkg -target /

     After installation, run:
       container system start

     Then re-run this skill.
     ```
   - **STOP here** and wait for user to install

3. **Check system requirements:**
   ```bash
   sw_vers  # Check macOS version
   uname -m # Check architecture
   ```

   **If macOS < 26 or not arm64:**
   - Warn user: "This skill requires macOS 26+ and Apple Silicon (M1/M2/M3/M4)"
   - Ask if they want to continue anyway (might not work)

### Step 2: Choose Mode

Use **AskUserQuestion** tool with these options:

```
Question: "Choose container isolation mode:"
Header: "Setup Mode"
MultiSelect: false

Options:
1. Label: "Playground (Recommended)"
   Description: "Maximum security. Isolated storage, API-only network. Perfect for testing untrusted code."

2. Label: "Development"
   Description: "Convenient access. Syncs with host filesystem, full internet. Only for code you trust."

3. Label: "Custom"
   Description: "Full control. Configure all options manually (10-12 questions)."
```

Store result in variable: `MODE`

### Step 3: Mode-Specific Configuration

#### If MODE == "Playground":

Use **AskUserQuestion** for:
```
Question: "Sync your Claude skills to the container?"
Header: "Skills"
MultiSelect: false
Options:
  1. "Yes (Recommended)" - "Container will have access to all your skills"
  2. "No" - "Skip skills synchronization"
```

**Auto-configure:**
- Base OS: Ubuntu 24.04
- Storage: Named volume
- Network: Locked (API only)
- MCP: Install in container
- Auth: Separate API key
- Execution: Safe mode

#### If MODE == "Development":

Show warning first:
```
⚠️  DEVELOPMENT MODE WARNING

This mode provides minimal isolation:
  • Container can access your host filesystem
  • Container shares your API credentials
  • Full network access enabled

Only use with code you fully trust.

Continue?
```

If user confirms, ask:
```
Question: "Sync Claude skills to container?"
(Same as Playground)
```

**Auto-configure:**
- Base OS: Ubuntu 24.04
- Storage: Bind mount (host directory)
- Network: Full
- MCP: Install in container
- Auth: Shared API key
- Execution: Dangerous mode (optional, ask user)

#### If MODE == "Custom":

Ask ALL configuration questions using **AskUserQuestion**:

1. **Base OS:**
   ```
   Options: Ubuntu 24.04 / Alpine 3.19 / Debian 12
   ```

2. **Storage:**
   ```
   Options: Named volume (fastest) / Bind mount (syncs with host)
   ```

3. **Network:**
   ```
   Options: Locked (API only) / Development (packages+API) / Full internet
   ```

4. **MCP Servers:**
   ```
   Question: "Install MCP servers?"
   If yes → Which servers? (Filesystem, Brave Search, GitHub, PostgreSQL)
   ```

5. **Skills Sync:**
   ```
   Options: Yes / No
   ```

6. **Git Configuration:**
   ```
   Question: "Configure git credentials?"
   If yes → Collect: Name, Email, Auth method (PAT/SSH/None)
   ```

7. **Environment Variables:**
   ```
   Question: "Import environment variables?"
   Options: From .env file / Manual entry / Skip
   ```

8. **Authentication:**
   ```
   Options: Share host API key / Separate API key
   ```

9. **Execution Mode:**
   ```
   Options: Safe mode (prompts) / Dangerous mode (no prompts)
   ```

10. **Resource Limits:**
    ```
    CPU cores: (default: 2)
    Memory: (default: 4GB)
    ```

### Step 4: Create Directory Structure

Create the container infrastructure:

```bash
mkdir -p .claude-container/scripts
mkdir -p scripts
```

### Step 5: Generate Configuration Files

#### 5.1 Create config.json

Based on user choices, create `.claude-container/config.json`:

```json
{
  "mode": "[MODE]",
  "created_date": "[CURRENT_DATE]",
  "container_name": "[PROJECT_NAME]-[MODE]",
  "image_name": "[PROJECT_NAME]-image:latest",
  "base_image": "[ubuntu:24.04 | alpine:3.19 | debian:12]",
  "storage": {
    "type": "[bind | volume]",
    "source": "[PROJECT_DIR | volume-name]",
    "destination": "/workspace"
  },
  "network": {
    "mode": "[locked | development | full]"
  },
  "mcp": {
    "enabled": [true | false],
    "servers": ["filesystem", "brave-search", ...]
  },
  "skills": {
    "sync": [true | false],
    "source": "[~/.claude/skills]"
  },
  "git": {
    "configured": [true | false],
    "name": "[user input]",
    "email": "[user input]"
  },
  "resources": {
    "cpus": [2],
    "memory": "[4g]"
  },
  "execution_mode": "[safe | dangerous]"
}
```

Use **Write** tool to create this file.

#### 5.2 Create manifest.json

Track what was created:

```json
{
  "skill_version": "1.0.0",
  "created": "[TIMESTAMP]",
  "files_created": [
    ".claude-container/config.json",
    ".claude-container/Containerfile",
    ".claude-container/CONTAINER-SPEC.md",
    "scripts/container",
    ".gitignore (modified)"
  ]
}
```

#### 5.3 Copy Containerfile Template

Based on chosen OS, copy the appropriate template:

```bash
# Use Read tool to read the template from the skill directory
# The skill will be located at either:
# ~/.claude/skills/container-isolation/templates/Containerfile.[ubuntu|alpine|debian]
# or .claude/skills/container-isolation/templates/Containerfile.[ubuntu|alpine|debian]

# Use Write tool to create .claude-container/Containerfile
```

#### 5.4 Copy Helper Scripts

Copy scripts from skill templates:

```bash
# Read each script template from the skill directory
# The skill will be located at either:
# ~/.claude/skills/container-isolation/scripts/[script-name]
# or .claude/skills/container-isolation/scripts/[script-name]

Read: [skill-path]/scripts/container
Read: [skill-path]/scripts/setup-mcp.sh
Read: [skill-path]/scripts/sync-skills.sh

# Write to project with variable substitution
# Replace {{CONTAINER_NAME}}, {{IMAGE_NAME}}, {{PROJECT_ROOT}}
```

Use **Write** tool to create `scripts/container`, `scripts/setup-mcp.sh`, `scripts/sync-skills.sh`

Then make executable:
```bash
chmod +x scripts/container scripts/setup-mcp.sh scripts/sync-skills.sh
```

#### 5.5 Generate CONTAINER-SPEC.md

Read the template:
```bash
# Read from the skill directory
# Located at either:
# ~/.claude/skills/container-isolation/templates/container-spec.md.template
# or .claude/skills/container-isolation/templates/container-spec.md.template

Read: [skill-path]/templates/container-spec.md.template
```

Fill in all `{{PLACEHOLDERS}}` with actual values from config.

Write to `.claude-container/CONTAINER-SPEC.md`

#### 5.6 Update .gitignore

Check if `.gitignore` exists, if not create it.

Append (or create with):
```
# Claude Container isolation
.claude-container/
scripts/container
scripts/setup-mcp.sh
scripts/sync-skills.sh
*.log
```

### Step 6: Summary and Next Steps

Display success message:

```
✅ Container isolation environment configured!

Mode: [MODE]
Container: [CONTAINER_NAME]
Base Image: [BASE_IMAGE]
Storage: [TYPE]
Network: [MODE]

Files created:
  ✓ .claude-container/config.json
  ✓ .claude-container/Containerfile
  ✓ .claude-container/CONTAINER-SPEC.md
  ✓ scripts/container
  ✓ scripts/setup-mcp.sh
  ✓ scripts/sync-skills.sh

Next steps:

1. Build and start container:
   ./scripts/container start

2. Enter container shell:
   ./scripts/container shell

3. Inside container, run Claude:
   claude

4. When done, stop container:
   ./scripts/container stop

Full documentation: .claude-container/CONTAINER-SPEC.md
```

---

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
- Container has same capabilities as host Claude
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
- **GitHub README:** https://github.com/penguinmd/claude-container-isolation
- **Apple Container:** https://github.com/apple/container
- **Configuration reference:** See repository CONFIGURATION.md
- **Advanced usage:** See repository ADVANCED.md
