# Quick Start - Testing Your Plugin Before Publishing

This guide helps you test the container-isolation plugin locally before publishing to GitHub.

---

## Prerequisites Check

Before testing, verify you have:

```bash
# Check macOS version (need 26+)
sw_vers

# Check architecture (need arm64)
uname -m

# Check Apple Container installed
which container
container --version

# Check Claude Code installed
which claude
claude --version
```

---

## Local Testing Steps

### Step 1: Validate Plugin Structure

```bash
cd /Users/mdr/SynologyDrive/projects/skills/container-isolation

# Check all JSON files are valid
python3 -m json.tool .claude-plugin/plugin.json >/dev/null && echo "✓ plugin.json valid"
python3 -m json.tool hooks/hooks.json >/dev/null && echo "✓ hooks.json valid"

# Check file structure
ls -la .claude-plugin/plugin.json
ls -la commands/container.md
ls -la hooks/hooks.json
ls -la hooks/session-start.sh
ls -la SKILL.md
ls -la install.sh
ls -la uninstall.sh

# Check scripts are executable
ls -la install.sh uninstall.sh
```

### Step 2: Test Installation Script (Syntax)

```bash
# Test syntax without running
bash -n install.sh && echo "✓ install.sh syntax OK"
bash -n uninstall.sh && echo "✓ uninstall.sh syntax OK"
```

### Step 3: Simulate Plugin Installation Locally

Since the plugin isn't published yet, you can test it locally:

```bash
# Create a local test installation
mkdir -p ~/.claude/plugins/test
cp -r /Users/mdr/SynologyDrive/projects/skills/container-isolation ~/.claude/plugins/test/

# Create the command alias manually
mkdir -p ~/.claude/commands
cat > ~/.claude/commands/container-test.md <<'EOF'
---
description: Test container isolation (local version)
---

# Container Isolation Management (TEST)

Use the AskUserQuestion tool to present the following menu:

Question: "What would you like to do with container isolation?"
Header: "Container"
MultiSelect: false

Options:
1. Label: "Set up new environment"
   Description: "Create and configure a new isolated container (choose from Playground/Development/Custom modes)"

2. Label: "Check status"
   Description: "View current container status, resource usage, and configuration"

3. Label: "Open shell"
   Description: "Open an interactive terminal session (auto-starts container if stopped)"

4. Label: "Manage container"
   Description: "Stop, restart, or permanently destroy the container environment"

## Based on User Selection:

### If "Set up new environment":
Read and execute the Container Isolation skill to set up a new environment.

Use the SKILL.md file located at: ~/.claude/plugins/test/container-isolation/SKILL.md

Follow the skill's instructions exactly, starting with:
1. Check prerequisites
2. Ask user to choose mode (Playground/Development/Custom)
3. Complete all setup steps

### If "Check status":
Run: ./scripts/container status

### If "Open shell":
Run: ./scripts/container shell

### If "Manage container":
Present management sub-menu (stop/restart/destroy/back)
EOF

echo "✓ Local test installation created"
```

### Step 4: Test the Command

```bash
# Start Claude Code
claude

# In Claude Code, test the command
/container-test

# You should see the interactive menu
# Try selecting "Set up new environment" to test the full flow
```

### Step 5: Test in a Real Project

```bash
# Navigate to a test project (or create one)
mkdir -p ~/test-container-project
cd ~/test-container-project

# Start Claude Code and run the setup
claude
/container-test

# Select: Set up new environment
# Choose: Playground Mode (safest for testing)
# Complete the setup

# Verify files were created
ls -la .claude-container/
ls -la scripts/container

# Test container commands
./scripts/container status
./scripts/container start
./scripts/container shell
# (inside container) exit
./scripts/container stop
```

### Step 6: Test Session-Start Hook

```bash
# Make the hook executable
chmod +x ~/.claude/plugins/test/container-isolation/hooks/session-start.sh

# Test the hook directly
~/.claude/plugins/test/container-isolation/hooks/session-start.sh

# Should output JSON with session notification
```

### Step 7: Clean Up Test Installation

```bash
# Remove test files
rm ~/.claude/commands/container-test.md
rm -rf ~/.claude/plugins/test/container-isolation

# Remove test project (if you want)
rm -rf ~/test-container-project

echo "✓ Test cleanup complete"
```

---

## Publishing Checklist

Once local testing is complete:

### 1. Push to GitHub

```bash
# Main plugin repository
cd /Users/mdr/SynologyDrive/projects/skills/container-isolation
git add .
git commit -m "Initial release - container isolation plugin

- Automated install/uninstall scripts
- Interactive /container command
- Playground/Development/Custom modes
- Auto-updates via session-start hook
- Comprehensive documentation"

git remote add origin https://github.com/penguinmd/claude-container-isolation.git
git push -u origin main

# Tag the release
git tag v1.0.0
git push --tags
```

```bash
# Marketplace repository
cd /Users/mdr/SynologyDrive/projects/skills/container-isolation-marketplace
git add .
git commit -m "Initial marketplace for container-isolation plugin"

git remote add origin https://github.com/penguinmd/claude-container-isolation-marketplace.git
git push -u origin main

git tag v1.0.0
git push --tags
```

### 2. Test Real Installation

On a different machine or after uninstalling local test:

```bash
# Test the one-line installer
curl -sSL https://raw.githubusercontent.com/penguinmd/claude-container-isolation/main/install.sh | bash

# Verify installation
ls -la ~/.claude/plugins/cache/container-isolation/
ls -la ~/.claude/commands/container.md

# Test the command
claude
/container
```

### 3. Update GitHub Repository Settings

On https://github.com/penguinmd/claude-container-isolation:

- Add description: "Secure, isolated development environments using Apple Container for Claude Code"
- Add topics: `claude-code`, `apple-container`, `containerization`, `security`, `development-environment`
- Add website: Link to README or docs
- Enable Issues
- Add LICENSE file (MIT)
- Add .gitignore if not present

### 4. Create GitHub Release

1. Go to Releases → Draft a new release
2. Tag: `v1.0.0`
3. Title: `Container Isolation v1.0.0 - Initial Release`
4. Description:
   ```markdown
   ## Container Isolation for Claude Code

   Create secure, isolated development environments using Apple Container technology.

   ### Features
   - 🔒 Playground mode - Maximum security for untrusted code
   - 🚀 Development mode - Full productivity for trusted projects
   - ⚙️ Custom mode - Flexible configuration for specific needs
   - 🔄 Auto-updates via session-start hook
   - 📦 One-line installation

   ### Installation

   \`\`\`bash
   curl -sSL https://raw.githubusercontent.com/penguinmd/claude-container-isolation/main/install.sh | bash
   \`\`\`

   ### Documentation
   - [README](README.md)
   - [Installation Guide](INSTALLATION-GUIDE.md)
   - [Configuration Reference](CONFIGURATION.md)
   - [Advanced Usage](ADVANCED.md)

   ### Requirements
   - macOS 26.0+
   - Apple Silicon (arm64)
   - Apple Container CLI
   - Claude Code CLI
   ```

---

## Troubleshooting Local Tests

### Issue: `/container-test` command not found

**Fix:**
```bash
# Verify command file exists
ls -la ~/.claude/commands/container-test.md

# Restart Claude Code to reload commands
```

### Issue: "SKILL.md not found"

**Fix:**
```bash
# Check path in command file matches actual location
cat ~/.claude/commands/container-test.md | grep SKILL.md
ls -la ~/.claude/plugins/test/container-isolation/SKILL.md
```

### Issue: Session-start hook not working

**Fix:**
```bash
# Make executable
chmod +x ~/.claude/plugins/test/container-isolation/hooks/session-start.sh

# Test directly
~/.claude/plugins/test/container-isolation/hooks/session-start.sh
```

### Issue: Container setup fails

**Fix:**
```bash
# Check Apple Container is installed
which container
container --version

# Try manually
cd ~/test-container-project
# Follow SKILL.md steps manually
```

---

## Final Verification Before Publishing

Run through this checklist:

- [ ] All JSON files validate
- [ ] install.sh runs without errors
- [ ] uninstall.sh cleans up correctly
- [ ] /container-test command shows menu
- [ ] Can complete Playground mode setup
- [ ] Generated scripts work (start/stop/shell/status)
- [ ] Session-start hook displays notification
- [ ] Documentation is complete and accurate
- [ ] LICENSE file is present (MIT)
- [ ] .gitignore excludes sensitive files
- [ ] Git repositories are ready to push

---

## Post-Publishing

After publishing to GitHub:

1. **Test real installation:**
   ```bash
   curl -sSL https://raw.githubusercontent.com/penguinmd/claude-container-isolation/main/install.sh | bash
   ```

2. **Verify auto-updates:**
   - Make a small change to SKILL.md
   - Push to GitHub
   - Start new Claude Code session
   - Check hook shows "updated to latest version"

3. **Monitor GitHub:**
   - Watch for issues
   - Respond to questions
   - Merge pull requests

4. **Share:**
   - Post to Claude Code community
   - Share on social media
   - Add to Claude Code plugin lists

---

**Ready to publish!** 🚀

If all tests pass, you're ready to push to GitHub and share with the community.
