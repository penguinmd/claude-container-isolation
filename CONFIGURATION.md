# Configuration Guide

> **Note:** This skill uses **Apple Container** (macOS 26+, Apple Silicon). All commands use the `container` CLI (e.g., `container run`, `container exec`, `container build`). Apple Container is OCI-compatible and supports standard container image formats.

This guide covers the configuration file schema, customization options, and advanced settings for the Container Isolation skill.

## Table of Contents

- [Configuration File Schema](#configuration-file-schema)
- [Field Descriptions](#field-descriptions)
- [Customization After Creation](#customization-after-creation)
- [Environment Variables](#environment-variables)
- [Network Configuration Options](#network-configuration-options)
- [Storage Options](#storage-options)
- [MCP Server Configuration](#mcp-server-configuration)

## Configuration File Schema

The container configuration is stored in `.claude-container/config.json`. Here's the complete schema:

```json
{
  "container": {
    "name": "claude-workspace-<project>",
    "image": "node:20-bookworm",
    "workdir": "/workspace",
    "autoStart": false,
    "removeOnExit": false
  },
  "environment": {
    "NODE_ENV": "development",
    "TERM": "xterm-256color"
  },
  "volumes": {
    "/workspace": {
      "type": "bind",
      "source": "${PROJECT_ROOT}",
      "readonly": false
    },
    "/workspace/node_modules": {
      "type": "volume",
      "name": "claude-workspace-<project>-node_modules"
    }
  },
  "network": {
    "mode": "bridge",
    "ports": {
      "3000": "3000",
      "8080": "8080"
    },
    "dns": ["8.8.8.8", "8.8.4.4"]
  },
  "resources": {
    "cpus": "2.0",
    "memory": "2g",
    "memorySwap": "2g"
  },
  "security": {
    "readonlyRootfs": false,
    "noNewPrivileges": true,
    "seccompProfile": "default",
    "apparmorProfile": "container-default"
  },
  "mcp": {
    "enabled": true,
    "server": "stdio",
    "transport": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
    }
  },
  "metadata": {
    "created": "2025-01-15T10:30:00Z",
    "version": "1.0.0",
    "description": "Node.js development environment"
  }
}
```

## Field Descriptions

### Container Settings

#### `container.name`
- **Type:** `string`
- **Required:** Yes
- **Description:** Unique identifier for the container. Must be unique across all containers on the system.
- **Pattern:** `claude-workspace-<project-name>`
- **Example:** `"claude-workspace-myapp"`

#### `container.image`
- **Type:** `string`
- **Required:** Yes
- **Description:** Container image to use as the base. Can be any image from container registry or a custom image.
- **Common Values:**
  - `node:20-bookworm` - Node.js 20 on Debian
  - `python:3.11-slim` - Python 3.11 minimal
  - `ubuntu:22.04` - Ubuntu 22.04 LTS
  - `rust:1.75-bookworm` - Rust 1.75
- **Example:** `"node:20-bookworm"`

#### `container.workdir`
- **Type:** `string`
- **Required:** Yes
- **Description:** Working directory inside the container where commands execute by default.
- **Default:** `"/workspace"`
- **Example:** `"/workspace"`

#### `container.autoStart`
- **Type:** `boolean`
- **Required:** No
- **Default:** `false`
- **Description:** Whether to automatically start the container when the skill is activated.
- **Example:** `true`

#### `container.removeOnExit`
- **Type:** `boolean`
- **Required:** No
- **Default:** `false`
- **Description:** Whether to automatically remove the container when it stops.
- **Warning:** Setting to `true` will delete all container state on exit.
- **Example:** `false`

### Environment Variables

#### `environment`
- **Type:** `object`
- **Required:** No
- **Description:** Key-value pairs of environment variables to set in the container.
- **Example:**
  ```json
  {
    "NODE_ENV": "development",
    "API_URL": "https://api.example.com",
    "DEBUG": "app:*",
    "PATH": "/usr/local/bin:/usr/bin:/bin"
  }
  ```

**Common Environment Variables:**

| Variable | Purpose | Example |
|----------|---------|---------|
| `NODE_ENV` | Node.js environment | `"development"` |
| `PYTHON_ENV` | Python environment | `"development"` |
| `DEBUG` | Debug logging | `"*"` or `"app:*"` |
| `TERM` | Terminal type | `"xterm-256color"` |
| `LANG` | Locale setting | `"en_US.UTF-8"` |
| `TZ` | Timezone | `"America/New_York"` |

### Volume Configuration

#### `volumes.<path>`
- **Type:** `object`
- **Required:** At least one volume recommended
- **Description:** Mount points for data persistence and file sharing.

**Volume Types:**

##### Bind Mount
Mounts a host directory into the container:
```json
"/workspace": {
  "type": "bind",
  "source": "/Users/username/projects/myapp",
  "readonly": false
}
```

**Fields:**
- `type`: Must be `"bind"`
- `source`: Absolute path on host system
- `readonly`: Whether the mount is read-only (default: `false`)

**Special Variables:**
- `${PROJECT_ROOT}`: Automatically replaced with current project directory
- `${HOME}`: Replaced with user's home directory

##### Named Volume
Creates a container-managed volume:
```json
"/workspace/node_modules": {
  "type": "volume",
  "name": "claude-workspace-myapp-node_modules"
}
```

**Fields:**
- `type`: Must be `"volume"`
- `name`: Unique name for the volume

**Use Cases:**
- `node_modules` - Faster npm installs, avoid platform conflicts
- Cache directories - Better performance than bind mounts
- Database data - Persistent storage independent of host

##### Tmpfs Mount
Creates an in-memory filesystem:
```json
"/tmp": {
  "type": "tmpfs",
  "size": "100m"
}
```

**Fields:**
- `type`: Must be `"tmpfs"`
- `size`: Maximum size (e.g., `"100m"`, `"1g"`)

**Use Cases:**
- Temporary files that don't need persistence
- High-performance scratch space
- Sensitive data that shouldn't be written to disk

### Network Configuration

#### `network.mode`
- **Type:** `string`
- **Required:** No
- **Default:** `"bridge"`
- **Options:**
  - `bridge` - Standard container network with port mapping
  - `host` - Share host's network namespace (no isolation)
  - `none` - No network access
  - Custom network name - Connect to existing container network
- **Example:** `"bridge"`

#### `network.ports`
- **Type:** `object`
- **Required:** No
- **Description:** Port mappings from container to host.
- **Format:** `"<container-port>": "<host-port>"`
- **Example:**
  ```json
  {
    "3000": "3000",
    "8080": "8080",
    "5432": "54321"
  }
  ```

**Port Mapping Strategies:**

| Strategy | Configuration | Use Case |
|----------|---------------|----------|
| Same port | `"3000": "3000"` | Simple, single instance |
| Different port | `"3000": "3001"` | Avoid conflicts, multiple instances |
| Range | Multiple entries | Multiple services |
| Dynamic | Empty object `{}` | No exposed ports |

#### `network.dns`
- **Type:** `array of strings`
- **Required:** No
- **Description:** Custom DNS servers for name resolution.
- **Example:** `["8.8.8.8", "8.8.4.4"]`

**Common DNS Servers:**
- `8.8.8.8`, `8.8.4.4` - Google Public DNS
- `1.1.1.1`, `1.0.0.1` - Cloudflare DNS
- `208.67.222.222`, `208.67.220.220` - OpenDNS

### Resource Limits

#### `resources.cpus`
- **Type:** `string`
- **Required:** No
- **Description:** CPU quota (number of CPUs).
- **Format:** Decimal string (e.g., `"2.0"`, `"0.5"`)
- **Example:** `"2.0"` (2 CPU cores)

#### `resources.memory`
- **Type:** `string`
- **Required:** No
- **Description:** Memory limit.
- **Format:** Number with unit (`b`, `k`, `m`, `g`)
- **Example:** `"2g"` (2 gigabytes)

#### `resources.memorySwap`
- **Type:** `string`
- **Required:** No
- **Description:** Total memory limit (memory + swap).
- **Recommendation:** Set equal to `memory` to disable swap.
- **Example:** `"2g"`

### Security Settings

#### `security.readonlyRootfs`
- **Type:** `boolean`
- **Default:** `false`
- **Description:** Mount the container's root filesystem as read-only.
- **Impact:** Prevents any writes to the container filesystem (except mounted volumes).
- **Example:** `true`

#### `security.noNewPrivileges`
- **Type:** `boolean`
- **Default:** `true`
- **Description:** Prevent processes from gaining additional privileges.
- **Recommendation:** Keep enabled unless you have a specific need.
- **Example:** `true`

#### `security.seccompProfile`
- **Type:** `string`
- **Default:** `"default"`
- **Description:** Seccomp (secure computing mode) profile.
- **Options:** `"default"`, `"unconfined"`, or path to custom profile
- **Example:** `"default"`

#### `security.apparmorProfile`
- **Type:** `string`
- **Default:** `"container-default"`
- **Description:** AppArmor security profile (Linux only).
- **Options:** `"container-default"`, `"unconfined"`, or custom profile name
- **Example:** `"container-default"`

### MCP Server Configuration

#### `mcp.enabled`
- **Type:** `boolean`
- **Default:** `true`
- **Description:** Enable Model Context Protocol server for Claude integration.
- **Example:** `true`

#### `mcp.server`
- **Type:** `string`
- **Default:** `"stdio"`
- **Description:** MCP server communication method.
- **Options:** `"stdio"`, `"http"`, `"websocket"`
- **Example:** `"stdio"`

#### `mcp.transport`
- **Type:** `object`
- **Description:** Configuration for MCP server transport.
- **Example:**
  ```json
  {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
  }
  ```

**Common MCP Servers:**

##### Filesystem Server
```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
}
```

##### Git Server
```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-git", "/workspace"]
}
```

##### Database Server
```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-postgres", "postgresql://localhost/mydb"]
}
```

## Customization After Creation

### Modifying Configuration

1. **Edit the configuration file:**
   ```bash
   # Open in your editor
   vim .claude-container/config.json
   ```

2. **Validate the configuration:**
   ```bash
   # The skill will validate on next use
   /container-isolation status
   ```

3. **Apply changes:**
   ```bash
   # Stop the container
   /container-isolation stop

   # Start with new configuration
   /container-isolation start
   ```

### Adding Environment Variables

Add to the `environment` section:

```json
{
  "environment": {
    "EXISTING_VAR": "value",
    "NEW_VAR": "new-value"
  }
}
```

### Adding Port Mappings

Add to the `network.ports` section:

```json
{
  "network": {
    "ports": {
      "3000": "3000",
      "9229": "9229"  // Add Node.js debugger port
    }
  }
}
```

### Adding Volumes

Add a new entry to the `volumes` section:

```json
{
  "volumes": {
    "/workspace": {
      "type": "bind",
      "source": "${PROJECT_ROOT}"
    },
    "/workspace/.cache": {
      "type": "volume",
      "name": "claude-workspace-myapp-cache"
    }
  }
}
```

### Changing Resource Limits

Update the `resources` section:

```json
{
  "resources": {
    "cpus": "4.0",      // Increase from 2.0
    "memory": "4g",     // Increase from 2g
    "memorySwap": "4g"
  }
}
```

## Environment Variables

### Predefined Variables

The skill supports these special variables in configuration:

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `${PROJECT_ROOT}` | Current project directory | `/Users/username/projects/myapp` |
| `${HOME}` | User's home directory | `/Users/username` |
| `${USER}` | Current username | `username` |
| `${CONTAINER_NAME}` | Name of the container | `claude-workspace-myapp` |

### Usage in Configuration

```json
{
  "volumes": {
    "/workspace": {
      "type": "bind",
      "source": "${PROJECT_ROOT}"
    },
    "/home/user/.ssh": {
      "type": "bind",
      "source": "${HOME}/.ssh",
      "readonly": true
    }
  },
  "environment": {
    "USER": "${USER}",
    "HOME": "/home/${USER}"
  }
}
```

### Runtime Environment Variables

These are set automatically in the container:

- `CONTAINER_NAME` - Name of the container
- `CLAUDE_SKILL` - Set to `"container-isolation"`
- `CLAUDE_VERSION` - Skill version
- `WORKSPACE_ROOT` - Path to workspace directory

### Passing Host Environment Variables

To pass environment variables from the host:

```json
{
  "environment": {
    "API_KEY": "${API_KEY}",
    "DATABASE_URL": "${DATABASE_URL}"
  }
}
```

The `${VAR_NAME}` syntax pulls values from the host environment.

## Network Configuration Options

### Bridge Network (Default)

Isolated network with port mapping:

```json
{
  "network": {
    "mode": "bridge",
    "ports": {
      "3000": "3000"
    }
  }
}
```

**Pros:**
- Network isolation
- Port mapping support
- Multiple containers can coexist

**Cons:**
- Slight performance overhead
- Requires explicit port mapping

### Host Network

Share the host's network stack:

```json
{
  "network": {
    "mode": "host"
  }
}
```

**Pros:**
- Best network performance
- Access to all host ports
- No port mapping needed

**Cons:**
- No network isolation
- Port conflicts possible
- Not available on Apple Container for Mac/Windows

### No Network

Completely isolated (no network access):

```json
{
  "network": {
    "mode": "none"
  }
}
```

**Use Cases:**
- Security-sensitive processing
- Batch jobs that don't need network
- Testing offline behavior

### Custom Network

Connect to an existing container network:

```json
{
  "network": {
    "mode": "my-custom-network"
  }
}
```

**Setup:**
```bash
# Create network
container network create my-custom-network

# Configure container to use it
```

**Use Cases:**
- Multi-container applications
- Shared services (databases, caches)
- Microservices architectures

## Storage Options

### Bind Mounts

Mount host directories for live development:

```json
{
  "/workspace": {
    "type": "bind",
    "source": "/Users/username/projects/myapp",
    "readonly": false
  }
}
```

**Best For:**
- Source code
- Configuration files
- Development assets

**Performance:**
- Good on Linux
- Slower on macOS/Windows (use volumes for performance-critical paths)

### Named Volumes

container-managed persistent storage:

```json
{
  "/workspace/node_modules": {
    "type": "volume",
    "name": "myapp-node_modules"
  }
}
```

**Best For:**
- Dependencies (node_modules, vendor)
- Cache directories
- Database data
- Performance-critical paths on macOS/Windows

**Advantages:**
- Fast on all platforms
- Easy backup/restore
- Portable between containers

### Tmpfs Mounts

In-memory temporary storage:

```json
{
  "/tmp": {
    "type": "tmpfs",
    "size": "100m"
  }
}
```

**Best For:**
- Temporary files
- Build artifacts
- Session data
- High-performance scratch space

**Limitations:**
- Lost on container restart
- Uses system RAM
- Size-limited

### Volume Combinations

Typical setup for web applications:

```json
{
  "volumes": {
    "/workspace": {
      "type": "bind",
      "source": "${PROJECT_ROOT}"
    },
    "/workspace/node_modules": {
      "type": "volume",
      "name": "myapp-node_modules"
    },
    "/workspace/.next": {
      "type": "volume",
      "name": "myapp-next-cache"
    },
    "/tmp": {
      "type": "tmpfs",
      "size": "500m"
    }
  }
}
```

This configuration:
- Mounts source code from host (live editing)
- Uses volume for node_modules (performance)
- Uses volume for build cache (persistence + performance)
- Uses tmpfs for temporary files (speed)

## MCP Server Configuration

### Filesystem Server

Provides file access to Claude:

```json
{
  "mcp": {
    "enabled": true,
    "server": "stdio",
    "transport": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
    }
  }
}
```

**Capabilities:**
- Read/write files
- List directories
- Search file contents

### Git Server

Provides Git operations to Claude:

```json
{
  "mcp": {
    "enabled": true,
    "server": "stdio",
    "transport": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git", "/workspace"]
    }
  }
}
```

**Capabilities:**
- Git status, log, diff
- Commit changes
- Branch management

### Database Server

Provides database access to Claude:

```json
{
  "mcp": {
    "enabled": true,
    "server": "stdio",
    "transport": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "postgresql://user:pass@localhost:5432/mydb"
      ]
    }
  }
}
```

**Capabilities:**
- Query execution
- Schema inspection
- Data analysis

### Custom MCP Server

Run your own MCP server:

```json
{
  "mcp": {
    "enabled": true,
    "server": "stdio",
    "transport": {
      "command": "node",
      "args": ["/workspace/mcp-server.js"]
    },
    "environment": {
      "CONFIG_PATH": "/workspace/config.json"
    }
  }
}
```

### Disabling MCP

To disable MCP integration:

```json
{
  "mcp": {
    "enabled": false
  }
}
```

### Multiple MCP Servers

Currently, the skill supports one MCP server per container. To use multiple MCP servers:

1. **Create separate containers** for each MCP server
2. **Use a proxy MCP server** that combines multiple backends
3. **Switch configurations** as needed

## Configuration Templates

### Node.js Development

```json
{
  "container": {
    "name": "claude-workspace-nodejs",
    "image": "node:20-bookworm",
    "workdir": "/workspace"
  },
  "environment": {
    "NODE_ENV": "development",
    "NPM_CONFIG_UPDATE_NOTIFIER": "false"
  },
  "volumes": {
    "/workspace": {
      "type": "bind",
      "source": "${PROJECT_ROOT}"
    },
    "/workspace/node_modules": {
      "type": "volume",
      "name": "nodejs-node_modules"
    }
  },
  "network": {
    "mode": "bridge",
    "ports": {
      "3000": "3000",
      "9229": "9229"
    }
  },
  "resources": {
    "cpus": "2.0",
    "memory": "2g"
  }
}
```

### Python Development

```json
{
  "container": {
    "name": "claude-workspace-python",
    "image": "python:3.11-slim",
    "workdir": "/workspace"
  },
  "environment": {
    "PYTHONUNBUFFERED": "1",
    "PYTHONDONTWRITEBYTECODE": "1"
  },
  "volumes": {
    "/workspace": {
      "type": "bind",
      "source": "${PROJECT_ROOT}"
    },
    "/workspace/.venv": {
      "type": "volume",
      "name": "python-venv"
    }
  },
  "network": {
    "mode": "bridge",
    "ports": {
      "8000": "8000"
    }
  }
}
```

### Rust Development

```json
{
  "container": {
    "name": "claude-workspace-rust",
    "image": "rust:1.75-bookworm",
    "workdir": "/workspace"
  },
  "volumes": {
    "/workspace": {
      "type": "bind",
      "source": "${PROJECT_ROOT}"
    },
    "/usr/local/cargo/registry": {
      "type": "volume",
      "name": "rust-cargo-registry"
    },
    "/workspace/target": {
      "type": "volume",
      "name": "rust-target"
    }
  },
  "resources": {
    "cpus": "4.0",
    "memory": "4g"
  }
}
```

## Troubleshooting Configuration

### Common Issues

**Problem: Container fails to start**
- Check image name is correct and available
- Verify port conflicts: `container ps`
- Check volume paths exist on host
- Review container logs: `container logs <container-name>`

**Problem: Port mapping not working**
- Verify port is not in use: `lsof -i :<port>`
- Check firewall settings
- Try different host port

**Problem: Volume mount empty**
- Verify source path is absolute
- Check permissions on host directory
- Ensure path exists on host

**Problem: Environment variables not set**
- Check JSON syntax (quotes, commas)
- Verify variable names don't conflict
- Test with `container exec <container> env`

### Validation

Validate your configuration:

```bash
# Test configuration syntax
cat .claude-container/config.json | jq .

# Dry-run container creation
container create --name test-config \
  --rm \
  -v "$(pwd)":/workspace \
  node:20-bookworm \
  tail -f /dev/null

# Test and remove
container rm test-config
```

### Getting Help

If you encounter issues:

1. Check the main README.md for common solutions
2. Review ADVANCED.md for complex scenarios
3. Examine container logs: `container logs <container-name>`
4. Validate configuration with `jq`
5. Test with minimal configuration first
