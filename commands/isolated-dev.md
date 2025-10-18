---
description: Set up a Development mode container with minimal restrictions
---

Read and execute the Container Isolation skill to set up a Development mode environment for this project.

Use the SKILL.md file located at: ${CLAUDE_PLUGIN_ROOT}/SKILL.md

IMPORTANT: Skip the mode selection step and proceed directly with Development mode configuration:
- Mode: Development (Minimal Restrictions)
- Base OS: Ubuntu 24.04
- Storage: Bind mount (syncs with host directory)
- Network: Full internet access
- MCP: Install in container
- Auth: Shared API key with host
- Execution: Ask user (safe vs dangerous mode)

Show the development mode warning, then ask about skills synchronization and execution mode, then proceed with all other setup steps automatically.
