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
   Description: "Create and configure a new isolated container (choose from Playground/Development/Custom modes)"

2. Label: "Check status"
   Description: "View current container status, resource usage, and configuration"

3. Label: "Open shell"
   Description: "Open an interactive terminal session (auto-starts container if stopped)"

4. Label: "Manage container"
   Description: "Stop, restart, or permanently destroy the container environment"
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

### If "Manage container":
Present a sub-menu for container lifecycle management operations.

Use the AskUserQuestion tool to present the following sub-menu:

```
Question: "What container management operation would you like to perform?"
Header: "Manage"
MultiSelect: false

Options:
1. Label: "Stop container"
   Description: "Stop the running container to free resources (all data is preserved)"

2. Label: "Restart container"
   Description: "Restart the container to apply configuration changes or recover from errors"

3. Label: "Destroy environment"
   Description: "Permanently remove the container and all its data (cannot be undone)"

4. Label: "Go back"
   Description: "Return to the main container menu"
```

#### If user selects "Stop container":
Look for the container management script at `./scripts/container` and run the stop command.

If the script exists:
1. Check current status with `./scripts/container status`
2. If running, stop it with `./scripts/container stop`
3. Confirm the container has stopped

If the script doesn't exist, inform the user that the container isolation environment hasn't been set up yet.

Note: Stopping the container preserves all data in volumes. The container can be restarted later with `./scripts/container start` or by selecting "Open shell" from the menu.

#### If user selects "Restart container":
Look for the container management script at `./scripts/container` and restart the container.

If the script exists:
1. Check current status with `./scripts/container status`
2. Run `./scripts/container restart` (or stop then start if restart command doesn't exist)
3. Confirm the container has restarted successfully

If the script doesn't exist, inform the user that the container isolation environment hasn't been set up yet.

#### If user selects "Destroy environment":
IMPORTANT: This is a destructive operation that cannot be undone. Always confirm with the user before proceeding.

Look for the container management script at `./scripts/container` and run the destroy command.

If the script exists:
1. Warn the user: "⚠️  WARNING: This will permanently delete the container and ALL its data. This cannot be undone."
2. Ask for explicit confirmation before proceeding
3. If confirmed, run: `./scripts/container destroy`
4. Confirm the container has been destroyed

If the script doesn't exist, inform the user that no container environment is set up.

Note: After destroying the environment, users can create a new one by selecting "Set up new environment" from the main menu.

#### If user selects "Go back":
Return to the main container menu by presenting it again.
