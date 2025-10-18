Enter an interactive shell session in the container isolation environment.

Look for the container management script at `./scripts/container` and run the shell command.

If the script exists:
1. Check if the container is running first with `./scripts/container status`
2. If not running, start it with `./scripts/container start`
3. Then run: `./scripts/container shell`

If the script doesn't exist, inform the user that the container isolation environment hasn't been set up yet and suggest running `/isolated-setup` first.

Note: This will open an interactive shell session. The user will be inside the container and can run commands there. They should type `exit` when done to return to the host system.
