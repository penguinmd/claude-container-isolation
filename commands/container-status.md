---
description: Check the status of the container isolation environment
---

Check the status of the container isolation environment for this project.

Look for the container management script at `./scripts/container` and run the status command.

If the script exists, run: `./scripts/container status`

If the script doesn't exist, inform the user that the container isolation environment hasn't been set up yet and suggest running `/isolated-setup` first.

Display the output clearly, including:
- Whether the container is running
- Container name and ID (if running)
- Resource usage (if available)
- Network status
- Volume/mount information
