# Installation Guide for Container Isolation Plugin

## For End Users

### Quick Install (Recommended)

Run this single command to install everything:

```bash
curl -sSL https://raw.githubusercontent.com/penguinmd/claude-container-isolation/main/install.sh | bash
```

This will:
1. Add the plugin marketplace
2. Install the container-isolation plugin
3. Create the `/container` command alias
4. Verify installation

### What Gets Installed

After installation, you'll have:

#### 1. Plugin Files (Auto-managed)
Location: `~/.claude/plugins/cache/container-isolation/`

```
~/.claude/plugins/cache/container-isolation/
├── .claude-plugin/
│   └── plugin.json              # Plugin metadata
├── commands/
│   └── container.md             # Plugin's namespaced command
├── hooks/
│   ├── hooks.json              # Hook configuration
│   └── session-start.sh        # Session notification hook
├── scripts/                     # Helper scripts for generation
├── templates/                   # Container setup templates
├── SKILL.md                    # Main skill implementation
├── README.md                   # Documentation
├── CONFIGURATION.md            # Config reference
└── ADVANCED.md                 # Advanced usage
```

**Auto-updates:** Plugin files automatically update on each session start (via git pull).

#### 2. Command Alias (User-created)
Location: `~/.claude/commands/container.md`

This is a simple alias that calls the plugin's skill, but with a shorter name:
- `/container` → reads plugin's SKILL.md
- `/container-isolation:container` → plugin's original namespaced command

Both work, but `/container` is cleaner.

### Available Commands After Install

```bash
# Start Claude Code
claude

# Use the simple command
/container

# Or use the full plugin command
/container-isolation:container

# Both do the same thing - present an interactive menu
```

### Verifying Installation

```bash
# Check plugin is installed
ls -la ~/.claude/plugins/cache/container-isolation/SKILL.md

# Check command alias exists
ls -la ~/.claude/commands/container.md

# Test in Claude Code
claude
/container
# Should show interactive menu
```

### Updating

The plugin auto-updates on each Claude Code session start. To force an update:

```bash
# Reinstall with latest version
curl -sSL https://raw.githubusercontent.com/penguinmd/claude-container-isolation/main/install.sh | bash
```

### Uninstalling

```bash
curl -sSL https://raw.githubusercontent.com/penguinmd/claude-container-isolation/main/uninstall.sh | bash
```

This removes:
- The plugin files
- The `/container` command

This does NOT remove:
- Container environments in your projects
- Project-specific `.claude-container/` directories

To fully clean up a project:
```bash
cd /path/to/project
./scripts/container destroy  # Stop and remove container
rm -rf .claude-container/ scripts/  # Remove generated files
```

---

## For Plugin Developers

### How This Plugin Works

This plugin uses a hybrid approach to provide the best user experience:

1. **Plugin System** (for distribution & updates)
   - Plugin installed via marketplace
   - Files stored in `~/.claude/plugins/cache/container-isolation/`
   - Auto-updates via session-start hook
   - Provides `/container-isolation:container` command (namespaced)

2. **Command Alias** (for UX)
   - User command at `~/.claude/commands/container.md`
   - Provides clean `/container` name
   - Simply references the plugin's SKILL.md

### Plugin Structure

```
container-isolation/                    # Plugin repository root
│
├── .claude-plugin/
│   └── plugin.json                    # REQUIRED - Plugin metadata
│
├── commands/                          # Plugin commands (namespaced)
│   └── container.md                   # Becomes /container-isolation:container
│
├── hooks/                             # Event handlers
│   ├── hooks.json                     # Hook configuration
│   └── session-start.sh               # Session notification
│
├── scripts/                           # Helper scripts (for SKILL)
│   ├── sync-skills.sh
│   └── setup-mcp.sh
│
├── templates/                         # Templates (for SKILL)
│   └── ...
│
├── SKILL.md                          # Main skill implementation
├── README.md                         # User documentation
├── CONFIGURATION.md                  # Config reference
├── ADVANCED.md                       # Advanced usage
│
├── install.sh                        # Automated installer
└── uninstall.sh                      # Automated uninstaller
```

### Key Files Explained

#### `.claude-plugin/plugin.json`
Plugin metadata - required for Claude Code to recognize this as a plugin.

```json
{
  "name": "container-isolation",
  "description": "Create secure, isolated development environments",
  "version": "1.0.0",
  "author": { "name": "penguinmd", "email": "..." },
  "homepage": "https://github.com/penguinmd/claude-container-isolation",
  "repository": "https://github.com/penguinmd/claude-container-isolation",
  "license": "MIT",
  "keywords": ["container", "isolation", "security"]
}
```

#### `commands/container.md`
Plugin command - automatically registered as `/container-isolation:container`.

Uses `${CLAUDE_PLUGIN_ROOT}` environment variable to reference plugin files.

#### `hooks/hooks.json`
Hook configuration - defines which scripts run on which events.

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "startup|resume|clear|compact",
      "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh" }]
    }]
  }
}
```

#### `hooks/session-start.sh`
Runs on every Claude Code session start. This script:
1. Checks for updates (git pull)
2. Displays notification about the skill
3. Shows update status if new version pulled

#### `install.sh`
End-user installer that:
1. Validates prerequisites
2. Adds marketplace
3. Installs plugin
4. Creates `~/.claude/commands/container.md` alias
5. Verifies installation

### Environment Variables Available

When plugin is installed, these are available:

- `${CLAUDE_PLUGIN_ROOT}` - Plugin directory path
  - Example: `/Users/username/.claude/plugins/cache/container-isolation`
  - Use this in commands and hooks to reference plugin files

### Testing Locally

To test your plugin before publishing:

```bash
# 1. Create a test installation directory
mkdir -p ~/.claude/plugins/cache/container-isolation-test

# 2. Copy your plugin files
cp -r /path/to/your/plugin/* ~/.claude/plugins/cache/container-isolation-test/

# 3. Create a test command
cat > ~/.claude/commands/container-test.md <<'EOF'
---
description: Test container isolation
---
Read and execute: ~/.claude/plugins/cache/container-isolation-test/SKILL.md
EOF

# 4. Test in Claude Code
claude
/container-test
```

### Publishing to Marketplace

1. **Create the plugin repository:**
   ```bash
   # Push to GitHub
   git remote add origin https://github.com/yourusername/your-plugin.git
   git push -u origin main
   ```

2. **Create the marketplace repository:**
   - Create separate repo for marketplace
   - Add `.claude-plugin/marketplace.json`:
   ```json
   {
     "name": "your-marketplace-name",
     "owner": { "name": "username", "email": "email@example.com" },
     "metadata": { "description": "...", "version": "1.0.0" },
     "plugins": [{
       "name": "your-plugin",
       "source": { "source": "url", "url": "https://github.com/you/your-plugin.git" },
       "description": "...",
       "version": "1.0.0",
       "keywords": [...],
       "strict": true
     }]
   }
   ```

3. **Users install via:**
   ```bash
   /plugin marketplace add yourusername/your-marketplace
   /plugin install your-plugin@your-marketplace
   ```

### Best Practices

1. **Always use `${CLAUDE_PLUGIN_ROOT}`** in plugin commands/hooks
2. **Version your plugin** in plugin.json
3. **Auto-update via session-start hook** (git pull)
4. **Provide install.sh** for one-line setup
5. **Document the /namespaced:command** and explain alias approach
6. **Test locally** before publishing
7. **Keep SKILL.md focused** - main implementation logic
8. **Use scripts/** for helper utilities
9. **Use templates/** for generated content

---

## Troubleshooting

### Plugin not found after installation

**Check:**
```bash
ls -la ~/.claude/plugins/cache/container-isolation/
```

**Fix:**
```bash
/plugin install container-isolation@container-isolation-marketplace
```

### `/container` command not working

**Check:**
```bash
ls -la ~/.claude/commands/container.md
```

**Fix:**
```bash
# Recreate the alias
mkdir -p ~/.claude/commands
cat > ~/.claude/commands/container.md <<'EOF'
---
description: Manage container isolation environments
---
Read and execute: ~/.claude/plugins/cache/container-isolation/SKILL.md
EOF
```

### Session-start hook not running

**Check:**
```bash
ls -la ~/.claude/plugins/cache/container-isolation/hooks/session-start.sh
chmod +x ~/.claude/plugins/cache/container-isolation/hooks/session-start.sh
```

### Auto-updates not working

The session-start hook runs `git pull`. Check:
```bash
cd ~/.claude/plugins/cache/container-isolation/
git status
git pull origin main
```

---

## Support

- **Issues:** https://github.com/penguinmd/claude-container-isolation/issues
- **Docs:** https://github.com/penguinmd/claude-container-isolation/blob/main/README.md
- **Source:** https://github.com/penguinmd/claude-container-isolation
