---
description: Manage container isolation environments for safe Claude Code execution
---

# Container Isolation Management

Use the AskUserQuestion tool to present the following menu:

```
Question: "What would you like to do with container isolation?"
Header: "Container"
MultiSelect: false

Options:
1. Label: "Set up new environment"
   Description: "Create a new isolated container environment (Playground/Development/Custom mode)"

2. Label: "Check status"
   Description: "View current container status and configuration"

3. Label: "Open shell"
   Description: "Enter an interactive shell session in the running container"

4. Label: "Stop container"
   Description: "Stop the running container (preserves data)"
```

## Based on User Selection:

### If "Set up new environment":
Read and execute the Container Isolation skill to set up a new environment.

Use the SKILL.md file located at: ${CLAUDE_PLUGIN_ROOT}/SKILL.md

Follow the skill's instructions exactly, starting with:
1. Check prerequisites
2. Ask user to choose mode (Playground/Development/Custom)
3. Complete all setup steps

### If "Check status":
Check the status of the container isolation environment for this project.

Look for the container management script at `./scripts/container` and run the status command.

If the script exists, run: `./scripts/container status`

If the script doesn't exist, inform the user that the container isolation environment hasn't been set up yet and suggest selecting "Set up new environment" from the menu.

Display the output clearly, including:
- Whether the container is running
- Container name and ID (if running)
- Resource usage (if available)
- Network status
- Volume/mount information

### If "Open shell":
Enter an interactive shell session in the container isolation environment.

Look for the container management script at `./scripts/container` and run the shell command.

If the script exists:
1. Check if the container is running first with `./scripts/container status`
2. If not running, start it with `./scripts/container start`
3. Then run: `./scripts/container shell`

If the script doesn't exist, inform the user that the container isolation environment hasn't been set up yet and suggest selecting "Set up new environment" from the menu.

Note: This will open an interactive shell session. The user will be inside the container and can run commands there. They should type `exit` when done to return to the host system.

### If "Stop container":
Stop the running container isolation environment for this project.

Look for the container management script at `./scripts/container` and run the stop command.

If the script exists:
1. Check current status with `./scripts/container status`
2. If running, stop it with `./scripts/container stop`
3. Confirm the container has stopped

If the script doesn't exist, inform the user that the container isolation environment hasn't been set up yet.

Note: Stopping the container preserves all data in volumes. The container can be restarted later with `./scripts/container start` or by selecting "Open shell" from the menu.

If the user wants to completely remove the container and all its data, they should use `./scripts/container destroy` instead (but warn them this is destructive).
