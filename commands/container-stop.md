---
description: Stop the running container isolation environment
---

Stop the running container isolation environment for this project.

Look for the container management script at `./scripts/container` and run the stop command.

If the script exists:
1. Check current status with `./scripts/container status`
2. If running, stop it with `./scripts/container stop`
3. Confirm the container has stopped

If the script doesn't exist, inform the user that the container isolation environment hasn't been set up yet.

Note: Stopping the container preserves all data in volumes. The container can be restarted later with `./scripts/container start` or `/container-shell`.

If the user wants to completely remove the container and all its data, they should use `./scripts/container destroy` instead (but warn them this is destructive).
