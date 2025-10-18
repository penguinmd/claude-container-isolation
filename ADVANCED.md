# Advanced Usage Guide

> **Important:** This skill uses **Apple Container** (macOS 26+, Apple Silicon). All command examples use the `container` CLI (e.g., `container run`, `container exec`, `container build`). Apple Container is OCI-compatible and supports standard container image formats and command syntax.

This guide covers advanced usage patterns, optimization techniques, and complex scenarios for the Container Isolation skill.

## Table of Contents

- [Multi-Container Workflows](#multi-container-workflows)
- [Custom Base Images](#custom-base-images)
- [Network Isolation Patterns](#network-isolation-patterns)
- [Volume Management](#volume-management)
- [Sharing Containers](#sharing-containers)
- [Performance Tuning](#performance-tuning)
- [Security Hardening](#security-hardening)
- [CI/CD Integration](#cicd-integration)
- [Debugging Techniques](#debugging-techniques)
- [Troubleshooting](#troubleshooting)

## Multi-Container Workflows

### Overview

Complex applications often require multiple containers working together. This section covers strategies for orchestrating multiple isolated environments.

### Approach 1: Shared Container Network

Create containers that can communicate with each other:

#### Step 1: Create a Custom Network

```bash
container network create claude-network
```

#### Step 2: Configure Containers

**Frontend Container** (`.claude-container/config.json`):
```json
{
  "container": {
    "name": "claude-frontend",
    "image": "node:20-bookworm",
    "workdir": "/workspace"
  },
  "network": {
    "mode": "claude-network",
    "ports": {
      "3000": "3000"
    }
  },
  "environment": {
    "API_URL": "http://claude-backend:8000"
  }
}
```

**Backend Container** (separate project):
```json
{
  "container": {
    "name": "claude-backend",
    "image": "python:3.11-slim",
    "workdir": "/workspace"
  },
  "network": {
    "mode": "claude-network",
    "ports": {
      "8000": "8000"
    }
  }
}
```

**Key Points:**
- Containers reference each other by container name
- Both use the same network
- Only necessary ports are exposed to host
- Internal communication uses container names as hostnames

### Approach 2: Container Compose Integration

For complex multi-container setups, create a `container-compose.yml`:

```yaml
version: '3.8'

services:
  frontend:
    image: node:20-bookworm
    container_name: claude-frontend
    working_dir: /workspace
    volumes:
      - ./frontend:/workspace
      - frontend-node-modules:/workspace/node_modules
    ports:
      - "3000:3000"
    environment:
      - API_URL=http://backend:8000
    depends_on:
      - backend
    networks:
      - claude-network

  backend:
    image: python:3.11-slim
    container_name: claude-backend
    working_dir: /workspace
    volumes:
      - ./backend:/workspace
      - backend-venv:/workspace/.venv
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://db:5432/myapp
    depends_on:
      - db
    networks:
      - claude-network

  db:
    image: postgres:15-alpine
    container_name: claude-db
    environment:
      - POSTGRES_PASSWORD=development
      - POSTGRES_DB=myapp
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - claude-network

volumes:
  frontend-node-modules:
  backend-venv:
  db-data:

networks:
  claude-network:
    driver: bridge
```

**Usage:**
```bash
# Start all services
container-compose up -d

# Access specific container with skill
/container-isolation attach claude-frontend

# Stop all services
container-compose down
```

### Approach 3: Service Discovery

For dynamic environments, use service discovery:

```json
{
  "environment": {
    "CONSUL_URL": "http://consul:8500",
    "SERVICE_NAME": "my-service"
  },
  "network": {
    "mode": "claude-network"
  }
}
```

**Setup Consul:**
```bash
container run -d \
  --name consul \
  --network claude-network \
  -p 8500:8500 \
  consul:latest
```

## Custom Base Images

### Creating Custom Images

Build specialized images for your development needs:

#### Basic Containerfile

```containerfile
FROM node:20-bookworm

# Install additional tools
RUN apt-get update && apt-get install -y \
    git \
    vim \
    curl \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install global npm packages
RUN npm install -g \
    typescript \
    ts-node \
    nodemon \
    prettier \
    eslint

# Set up non-root user
RUN useradd -m -s /bin/bash developer
USER developer

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
```

**Build and Use:**
```bash
# Build image
container build -t claude-node-dev:latest .

# Update config.json
{
  "container": {
    "image": "claude-node-dev:latest"
  }
}
```

#### Multi-Language Containerfile

Support multiple languages in one image:

```containerfile
FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install base tools
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    vim \
    wget \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install Python
RUN add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y python3.11 python3.11-venv python3-pip

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Go
RUN wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz \
    && rm go1.21.0.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

WORKDIR /workspace
CMD ["/bin/bash"]
```

#### Development Tools Image

Include common development tools:

```containerfile
FROM node:20-bookworm

# Install development tools
RUN apt-get update && apt-get install -y \
    # Version control
    git git-lfs \
    # Editors
    vim neovim emacs-nox \
    # Network tools
    curl wget netcat-openbsd \
    # Process tools
    htop tmux \
    # Build tools
    build-essential \
    # Database clients
    postgresql-client mysql-client redis-tools \
    # Cloud CLIs
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh

# Configure Git
RUN git config --global init.defaultBranch main \
    && git config --global pull.rebase false

WORKDIR /workspace
CMD ["/bin/bash"]
```

### Image Optimization

#### Multi-Stage Builds

Reduce image size:

```containerfile
# Build stage
FROM node:20-bookworm AS builder

WORKDIR /build
COPY package*.json ./
RUN npm ci --only=production

# Runtime stage
FROM node:20-bookworm-slim

WORKDIR /workspace
COPY --from=builder /build/node_modules ./node_modules

CMD ["/bin/bash"]
```

#### Layer Caching

Optimize build speed:

```containerfile
FROM node:20-bookworm

# Install system packages (changes rarely)
RUN apt-get update && apt-get install -y git vim \
    && rm -rf /var/lib/apt/lists/*

# Install global npm packages (changes occasionally)
RUN npm install -g typescript nodemon

# Copy package files (changes more often)
WORKDIR /workspace
COPY package*.json ./

# Install dependencies (changes frequently)
RUN npm install

# Application code (changes most often) - handled by volume mount
CMD ["/bin/bash"]
```

## Network Isolation Patterns

### Pattern 1: Complete Isolation

No network access for maximum security:

```json
{
  "network": {
    "mode": "none"
  }
}
```

**Use Cases:**
- Processing sensitive data
- Offline development
- Security testing
- Batch processing without external dependencies

**Testing:**
```bash
# Inside container - should fail
curl https://google.com  # Should fail: no network

# File processing still works
cat /workspace/data.json | jq .
```

### Pattern 2: Controlled Egress

Allow outbound connections but no inbound:

```json
{
  "network": {
    "mode": "bridge",
    "ports": {}  // No exposed ports
  }
}
```

**Use Cases:**
- API clients
- Data fetching
- Package installation
- Services that don't need to be accessed

**Testing:**
```bash
# Can make outbound requests
curl https://api.github.com

# But no external access to container services
# Port 3000 running inside container is not accessible from host
```

### Pattern 3: Service Mesh

Multiple containers with service-to-service communication:

#### Setup

```bash
# Create isolated network
container network create --driver bridge \
  --subnet 172.25.0.0/16 \
  --gateway 172.25.0.1 \
  claude-mesh
```

#### Service A Configuration

```json
{
  "container": {
    "name": "service-a"
  },
  "network": {
    "mode": "claude-mesh",
    "ports": {
      "3000": "3000"  // Exposed to host
    }
  },
  "environment": {
    "SERVICE_B_URL": "http://service-b:8000",
    "SERVICE_C_URL": "http://service-c:9000"
  }
}
```

#### Service B Configuration

```json
{
  "container": {
    "name": "service-b"
  },
  "network": {
    "mode": "claude-mesh",
    "ports": {}  // Not exposed to host
  }
}
```

**Benefits:**
- Internal communication without host exposure
- Network-level isolation
- Service discovery by container name

### Pattern 4: VPN Access

Connect container to corporate VPN:

```containerfile
FROM node:20-bookworm

# Install OpenVPN
RUN apt-get update && apt-get install -y openvpn \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
CMD ["/bin/bash"]
```

```json
{
  "volumes": {
    "/workspace": {
      "type": "bind",
      "source": "${PROJECT_ROOT}"
    },
    "/etc/openvpn": {
      "type": "bind",
      "source": "${HOME}/.vpn",
      "readonly": true
    }
  },
  "security": {
    "capabilities": ["NET_ADMIN"]
  }
}
```

**Usage:**
```bash
# Inside container
openvpn --config /etc/openvpn/company.ovpn
```

## Volume Management

### Backup and Restore

#### Backing Up Volumes

**Named Volume Backup:**
```bash
# Backup a named volume
container run --rm \
  -v myapp-data:/source:ro \
  -v $(pwd):/backup \
  alpine \
  tar czf /backup/myapp-data-$(date +%Y%m%d).tar.gz -C /source .
```

**Automated Backup Script:**
```bash
#!/bin/bash
# backup-volumes.sh

VOLUMES=("myapp-node-modules" "myapp-cache" "myapp-data")
BACKUP_DIR="${HOME}/container-backups/$(date +%Y%m%d)"

mkdir -p "$BACKUP_DIR"

for volume in "${VOLUMES[@]}"; do
    echo "Backing up $volume..."
    container run --rm \
        -v "$volume:/source:ro" \
        -v "$BACKUP_DIR:/backup" \
        alpine \
        tar czf "/backup/${volume}.tar.gz" -C /source .
done

echo "Backups completed in $BACKUP_DIR"
```

#### Restoring Volumes

**Restore from Backup:**
```bash
# Create new volume
container volume create myapp-data-restored

# Restore data
container run --rm \
  -v myapp-data-restored:/target \
  -v $(pwd):/backup \
  alpine \
  tar xzf /backup/myapp-data-20250115.tar.gz -C /target
```

**Automated Restore Script:**
```bash
#!/bin/bash
# restore-volumes.sh

BACKUP_FILE=$1
VOLUME_NAME=$2

if [ -z "$BACKUP_FILE" ] || [ -z "$VOLUME_NAME" ]; then
    echo "Usage: $0 <backup-file> <volume-name>"
    exit 1
fi

# Create volume if it doesn't exist
container volume create "$VOLUME_NAME"

# Restore
container run --rm \
    -v "$VOLUME_NAME:/target" \
    -v "$(dirname $BACKUP_FILE):/backup" \
    alpine \
    tar xzf "/backup/$(basename $BACKUP_FILE)" -C /target

echo "Restored $BACKUP_FILE to $VOLUME_NAME"
```

### Volume Migration

#### Between Hosts

**Export on Host A:**
```bash
# Export volume
container run --rm \
  -v myapp-data:/source:ro \
  alpine \
  tar c -C /source . | gzip > myapp-data.tar.gz

# Transfer to Host B
scp myapp-data.tar.gz user@hostb:~/
```

**Import on Host B:**
```bash
# Create volume
container volume create myapp-data

# Import data
gunzip < myapp-data.tar.gz | \
  container run --rm -i \
    -v myapp-data:/target \
    alpine \
    tar x -C /target
```

#### Between Containers

**Copy volume to new volume:**
```bash
# Create new volume
container volume create myapp-data-v2

# Copy data
container run --rm \
  -v myapp-data:/source:ro \
  -v myapp-data-v2:/target \
  alpine \
  cp -av /source/. /target/
```

### Volume Cleanup

#### Remove Unused Volumes

```bash
# List all volumes
container volume ls

# Remove specific volume
container volume rm myapp-old-data

# Remove all unused volumes
container volume prune

# Force remove (even if in use)
container volume rm -f myapp-data
```

#### Automated Cleanup Script

```bash
#!/bin/bash
# cleanup-old-volumes.sh

# Find volumes older than 30 days
CUTOFF_DATE=$(date -d '30 days ago' +%s)

container volume ls -q | while read volume; do
    CREATED=$(container volume inspect -f '{{.CreatedAt}}' "$volume")
    CREATED_TS=$(date -d "$CREATED" +%s)

    if [ "$CREATED_TS" -lt "$CUTOFF_DATE" ]; then
        echo "Removing old volume: $volume (created $CREATED)"
        container volume rm "$volume" 2>/dev/null || echo "  (in use, skipped)"
    fi
done
```

## Sharing Containers

### Export and Import

#### Export Container as Image

**Export running container:**
```bash
# Commit container to image
container commit claude-workspace-myapp myapp-dev:latest

# Save image to file
container save myapp-dev:latest | gzip > myapp-dev.tar.gz
```

**Import on another machine:**
```bash
# Load image
gunzip < myapp-dev.tar.gz | container load

# Use in configuration
{
  "container": {
    "image": "myapp-dev:latest"
  }
}
```

#### Export Complete Environment

**Export script:**
```bash
#!/bin/bash
# export-environment.sh

CONTAINER_NAME=$1
OUTPUT_DIR=${2:-./export}

mkdir -p "$OUTPUT_DIR"

# Export container as image
container commit "$CONTAINER_NAME" "${CONTAINER_NAME}-export:latest"
container save "${CONTAINER_NAME}-export:latest" | gzip > "$OUTPUT_DIR/image.tar.gz"

# Export configuration
cp .claude-container/config.json "$OUTPUT_DIR/"

# Export volumes
VOLUMES=$(container inspect -f '{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}} {{end}}{{end}}' "$CONTAINER_NAME")

for vol in $VOLUMES; do
    container run --rm \
        -v "$vol:/source:ro" \
        -v "$OUTPUT_DIR:/backup" \
        alpine \
        tar czf "/backup/volume-${vol}.tar.gz" -C /source .
done

echo "Environment exported to $OUTPUT_DIR"
```

**Import script:**
```bash
#!/bin/bash
# import-environment.sh

IMPORT_DIR=$1

if [ -z "$IMPORT_DIR" ]; then
    echo "Usage: $0 <import-directory>"
    exit 1
fi

# Load image
gunzip < "$IMPORT_DIR/image.tar.gz" | container load

# Copy configuration
mkdir -p .claude-container
cp "$IMPORT_DIR/config.json" .claude-container/

# Restore volumes
for vol_file in "$IMPORT_DIR"/volume-*.tar.gz; do
    VOL_NAME=$(basename "$vol_file" | sed 's/^volume-//' | sed 's/.tar.gz$//')
    container volume create "$VOL_NAME"

    gunzip < "$vol_file" | \
        container run --rm -i \
            -v "$VOL_NAME:/target" \
            alpine \
            tar x -C /target
done

echo "Environment imported. Start with: /container-isolation start"
```

### Sharing via Registry

#### Push to container registry

```bash
# Tag image
container tag myapp-dev:latest username/myapp-dev:latest

# Login to container registry
container login

# Push
container push username/myapp-dev:latest
```

#### Use in configuration

```json
{
  "container": {
    "image": "username/myapp-dev:latest"
  }
}
```

**Team members can now:**
```bash
# Pull image automatically on first start
/container-isolation start
```

### Private Registry

#### Setup Private Registry

```bash
# Run registry
container run -d \
  -p 5000:5000 \
  --restart=always \
  --name registry \
  -v registry-data:/var/lib/registry \
  registry:2
```

#### Push to Private Registry

```bash
# Tag for private registry
container tag myapp-dev:latest localhost:5000/myapp-dev:latest

# Push
container push localhost:5000/myapp-dev:latest
```

#### Use in Configuration

```json
{
  "container": {
    "image": "registry.company.com:5000/myapp-dev:latest"
  }
}
```

## Performance Tuning

### Volume Performance

#### macOS/Windows Optimization

Use `:cached` or `:delegated` mount modes:

```bash
# Manual container run example
container run -v "$(pwd):/workspace:cached" myimage
```

**For configuration** (requires manual container CLI usage or container-compose):

In `container-compose.yml`:
```yaml
volumes:
  - ./src:/workspace/src:cached  # Better read performance
  - ./build:/workspace/build:delegated  # Better write performance
```

#### Use Volumes for Dependencies

```json
{
  "volumes": {
    "/workspace": {
      "type": "bind",
      "source": "${PROJECT_ROOT}"
    },
    "/workspace/node_modules": {
      "type": "volume",
      "name": "myapp-node-modules"
    },
    "/workspace/.git": {
      "type": "volume",
      "name": "myapp-git"
    }
  }
}
```

**Performance improvement:**
- 5-10x faster npm operations
- 2-3x faster git operations
- Eliminates platform-specific binary issues

### Resource Optimization

#### Right-Sizing Resources

**Development (single developer):**
```json
{
  "resources": {
    "cpus": "2.0",
    "memory": "2g",
    "memorySwap": "2g"
  }
}
```

**Build/Test (CI/CD):**
```json
{
  "resources": {
    "cpus": "4.0",
    "memory": "4g",
    "memorySwap": "4g"
  }
}
```

**Production-like (local testing):**
```json
{
  "resources": {
    "cpus": "1.0",
    "memory": "512m",
    "memorySwap": "512m"
  }
}
```

#### Memory Swappiness

```bash
# Inside container
sysctl vm.swappiness=10  # Reduce swap usage
```

### Build Performance

#### Layer Caching Strategy

```containerfile
# Optimal layer ordering (least to most frequently changed)
FROM node:20-bookworm

# 1. System packages (rarely change)
RUN apt-get update && apt-get install -y git

# 2. Global tools (occasionally change)
RUN npm install -g typescript

# 3. Dependencies (change with package.json)
COPY package*.json ./
RUN npm install

# 4. Application code (frequently changes)
COPY . .
```

#### BuildKit

Enable BuildKit for faster builds:

```bash
# Enable BuildKit
export CONTAINER_BUILDKIT=1

# Build with BuildKit
container build -t myimage .
```

**Features:**
- Parallel build stages
- Better caching
- Faster dependency resolution

### Network Performance

#### DNS Caching

```json
{
  "network": {
    "dns": ["8.8.8.8", "1.1.1.1"],
    "dnsOptions": ["ndots:1", "timeout:1", "attempts:2"]
  }
}
```

#### Connection Pooling

In application code:

```javascript
// Use connection pooling
const pool = new Pool({
  host: 'db',
  max: 20,  // Max connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

## Security Hardening

### Principle of Least Privilege

#### Read-Only Root Filesystem

```json
{
  "security": {
    "readonlyRootfs": true
  },
  "volumes": {
    "/workspace": {
      "type": "bind",
      "source": "${PROJECT_ROOT}"
    },
    "/tmp": {
      "type": "tmpfs",
      "size": "100m"
    }
  }
}
```

**Benefits:**
- Prevents unauthorized file modifications
- Mitigates container escape vulnerabilities
- Enforces immutable infrastructure

#### Drop Capabilities

```bash
# Via container run
container run --cap-drop=ALL --cap-add=NET_BIND_SERVICE myimage
```

**Common capabilities to drop:**
- `CHOWN` - Change file ownership
- `DAC_OVERRIDE` - Bypass file permission checks
- `FSETID` - Don't clear SUID/SGID bits
- `KILL` - Bypass permission checks for sending signals
- `NET_RAW` - Use RAW and PACKET sockets

#### Non-Root User

```containerfile
FROM node:20-bookworm

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set ownership
RUN chown -R appuser:appuser /workspace

# Switch to non-root user
USER appuser

WORKDIR /workspace
```

### Secret Management

#### Never Commit Secrets

```json
{
  "environment": {
    "API_KEY": "${API_KEY}",  // From host environment
    "DB_PASSWORD": "${DB_PASSWORD}"
  }
}
```

**In `.gitignore`:**
```
.env
.env.local
.claude-container/secrets/
```

#### Use Container Secrets

For sensitive data:

```bash
# Create secret
echo "my-secret-value" | container secret create api_key -

# Use in container (swarm mode)
container service create \
  --secret api_key \
  myimage
```

#### Mount Secrets as Files

```json
{
  "volumes": {
    "/run/secrets": {
      "type": "bind",
      "source": "${HOME}/.secrets",
      "readonly": true
    }
  }
}
```

**Access in container:**
```bash
cat /run/secrets/api_key
```

### Network Security

#### Firewall Rules

```bash
# Allow only specific outbound destinations
iptables -A CONTAINER-USER -d 192.168.1.0/24 -j ACCEPT
iptables -A CONTAINER-USER -j DROP
```

#### TLS for Inter-Container Communication

```yaml
# container-compose.yml
services:
  app:
    environment:
      - DATABASE_URL=postgresql://db:5432/myapp?sslmode=require
    depends_on:
      - db

  db:
    command: postgres -c ssl=on -c ssl_cert_file=/certs/server.crt
    volumes:
      - ./certs:/certs:ro
```

### Scanning and Auditing

#### Scan Images for Vulnerabilities

```bash
# Using Container Image Scanning
container image scan cves myimage:latest

# Using Trivy
trivy image myimage:latest

# Using Snyk
snyk container test myimage:latest
```

#### Audit Configuration

```bash
# Container Security Audit
git clone # Security audit tools for containers
# Use container security scanning tools
# Run security audit
```

## CI/CD Integration

### GitHub Actions

#### Workflow Example

```yaml
# .github/workflows/container-test.yml
name: Container Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Container Build
        uses: # Container build setup@v2

      - name: Build container image
        run: |
          container build -t myapp-test:latest .

      - name: Create container
        run: |
          container create \
            --name test-container \
            -v "$PWD:/workspace" \
            -v myapp-node-modules:/workspace/node_modules \
            myapp-test:latest \
            tail -f /dev/null

      - name: Start container
        run: container start test-container

      - name: Install dependencies
        run: |
          container exec test-container npm install

      - name: Run tests
        run: |
          container exec test-container npm test

      - name: Run linter
        run: |
          container exec test-container npm run lint

      - name: Build application
        run: |
          container exec test-container npm run build

      - name: Cleanup
        if: always()
        run: |
          container stop test-container
          container rm test-container
```

### GitLab CI

```yaml
# .gitlab-ci.yml
image: container:latest

services:
  - container:dind

variables:
  CONTAINER_DRIVER: overlay2
  CONTAINER_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG

stages:
  - build
  - test
  - deploy

build:
  stage: build
  script:
    - container build -t $CONTAINER_IMAGE .
    - container push $CONTAINER_IMAGE

test:
  stage: test
  script:
    - container pull $CONTAINER_IMAGE
    - container create --name test-container -v "$PWD:/workspace" $CONTAINER_IMAGE
    - container start test-container
    - container exec test-container npm install
    - container exec test-container npm test
  after_script:
    - container stop test-container || true
    - container rm test-container || true
```

### Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any

    environment {
        CONTAINER_IMAGE = "myapp-dev:${env.BUILD_NUMBER}"
    }

    stages {
        stage('Build Image') {
            steps {
                script {
                    container.build(env.CONTAINER_IMAGE)
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    container.image(env.CONTAINER_IMAGE).inside('-v $WORKSPACE:/workspace') {
                        sh 'npm install'
                        sh 'npm test'
                        sh 'npm run lint'
                    }
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    container.image(env.CONTAINER_IMAGE).inside('-v $WORKSPACE:/workspace') {
                        sh 'npm run build'
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
```

## Debugging Techniques

### Interactive Debugging

#### Attach to Running Container

```bash
# Get a shell
container exec -it claude-workspace-myapp /bin/bash

# Run specific command
container exec claude-workspace-myapp ps aux

# As different user
container exec -u root -it claude-workspace-myapp /bin/bash
```

#### Node.js Debugging

**Configuration:**
```json
{
  "network": {
    "ports": {
      "9229": "9229"  // Node.js debugger port
    }
  }
}
```

**Start with debugging:**
```bash
# Inside container
node --inspect=0.0.0.0:9229 app.js
```

**VS Code `launch.json`:**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "attach",
      "name": "Attach to Container",
      "address": "localhost",
      "port": 9229,
      "localRoot": "${workspaceFolder}",
      "remoteRoot": "/workspace",
      "skipFiles": ["<node_internals>/**"]
    }
  ]
}
```

#### Python Debugging

**Install debugpy:**
```bash
# Inside container
pip install debugpy
```

**Start with debugging:**
```python
# app.py
import debugpy
debugpy.listen(("0.0.0.0", 5678))
debugpy.wait_for_client()  # Optional: wait for debugger

# Your code here
```

**VS Code `launch.json`:**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: Attach to Container",
      "type": "python",
      "request": "attach",
      "connect": {
        "host": "localhost",
        "port": 5678
      },
      "pathMappings": [
        {
          "localRoot": "${workspaceFolder}",
          "remoteRoot": "/workspace"
        }
      ]
    }
  ]
}
```

### Log Analysis

#### View Container Logs

```bash
# All logs
container logs claude-workspace-myapp

# Follow logs
container logs -f claude-workspace-myapp

# Last 100 lines
container logs --tail 100 claude-workspace-myapp

# Since timestamp
container logs --since 2025-01-15T10:00:00 claude-workspace-myapp

# With timestamps
container logs -t claude-workspace-myapp
```

#### Structured Logging

**In application:**
```javascript
// Use structured logging
const winston = require('winston');

const logger = winston.createLogger({
  format: winston.format.json(),
  transports: [
    new winston.transports.Console()
  ]
});

logger.info('Server started', { port: 3000, env: process.env.NODE_ENV });
```

**Parse logs:**
```bash
# Extract JSON logs
container logs claude-workspace-myapp 2>&1 | jq 'select(.level=="error")'
```

### Performance Profiling

#### Container Stats

```bash
# Real-time stats
container stats claude-workspace-myapp

# One-time stats
container stats --no-stream claude-workspace-myapp

# Format output
container stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

#### Process Inspection

```bash
# List processes
container top claude-workspace-myapp

# Detailed process tree
container exec claude-workspace-myapp ps auxf

# Resource usage by process
container exec claude-workspace-myapp top -b -n 1
```

### Network Debugging

#### Network Inspection

```bash
# Inspect network
container network inspect bridge

# Test connectivity
container exec claude-workspace-myapp ping -c 3 google.com

# DNS resolution
container exec claude-workspace-myapp nslookup github.com

# Port listening
container exec claude-workspace-myapp netstat -tlnp

# Active connections
container exec claude-workspace-myapp ss -tunap
```

#### Traffic Capture

```bash
# Install tcpdump in container
container exec -u root claude-workspace-myapp apt-get update
container exec -u root claude-workspace-myapp apt-get install -y tcpdump

# Capture traffic
container exec claude-workspace-myapp tcpdump -i eth0 -w /tmp/capture.pcap

# Analyze on host
container cp claude-workspace-myapp:/tmp/capture.pcap .
wireshark capture.pcap
```

## Troubleshooting

### Common Issues

#### Issue: Container Won't Start

**Symptoms:**
```bash
Error response from daemon: driver failed programming external connectivity
```

**Diagnosis:**
```bash
# Check port conflicts
lsof -i :3000

# Check container daemon
container info

# Check system resources
container system df
```

**Solutions:**
```bash
# Use different port
{
  "network": {
    "ports": {
      "3000": "3001"  // Use different host port
    }
  }
}

# Kill conflicting process
kill -9 $(lsof -t -i :3000)

# Restart container daemon
# Restart container service  # Linux
# or restart Apple Container
```

#### Issue: Volume Mount Empty

**Symptoms:**
- Directory appears empty in container
- Files not syncing

**Diagnosis:**
```bash
# Check mount
container exec claude-workspace-myapp ls -la /workspace

# Inspect mounts
container inspect -f '{{json .Mounts}}' claude-workspace-myapp | jq .

# Check permissions
ls -la /path/to/project
```

**Solutions:**
```bash
# Fix permissions on host
chmod -R 755 /path/to/project

# Use absolute paths
{
  "volumes": {
    "/workspace": {
      "type": "bind",
      "source": "/absolute/path/to/project"  // Not relative!
    }
  }
}

# Check Apple Container file sharing settings (macOS/Windows)
# Preferences -> Resources -> File Sharing
```

#### Issue: High CPU Usage

**Diagnosis:**
```bash
# Check container stats
container stats claude-workspace-myapp

# Check processes
container exec claude-workspace-myapp top

# Check for loops
container exec claude-workspace-myapp ps aux | grep -E "(node|python)"
```

**Solutions:**
```bash
# Limit CPU usage
{
  "resources": {
    "cpus": "2.0"
  }
}

# Find and fix infinite loops in code
# Check for file watchers (nodemon, webpack-dev-server)
# Reduce file watcher scope in .watchmanconfig or similar
```

#### Issue: Out of Memory

**Symptoms:**
```bash
Error: Cannot allocate memory
Killed
```

**Diagnosis:**
```bash
# Check memory usage
container stats --no-stream claude-workspace-myapp

# Check processes
container exec claude-workspace-myapp ps aux --sort=-%mem | head

# Check for memory leaks
container exec claude-workspace-myapp node --inspect app.js
# Use Chrome DevTools memory profiler
```

**Solutions:**
```bash
# Increase memory limit
{
  "resources": {
    "memory": "4g",
    "memorySwap": "4g"
  }
}

# Fix memory leaks in application
# Add heap size limits for Node.js
container exec claude-workspace-myapp node --max-old-space-size=2048 app.js
```

#### Issue: Network Connectivity Problems

**Symptoms:**
- Can't reach external services
- Can't connect between containers

**Diagnosis:**
```bash
# Test external connectivity
container exec claude-workspace-myapp ping -c 3 8.8.8.8
container exec claude-workspace-myapp curl https://google.com

# Test DNS
container exec claude-workspace-myapp nslookup google.com

# Check network configuration
container network inspect bridge

# Test inter-container connectivity
container exec claude-workspace-myapp ping -c 3 other-container
```

**Solutions:**
```bash
# Fix DNS
{
  "network": {
    "dns": ["8.8.8.8", "1.1.1.1"]
  }
}

# Restart container networking
# Restart container service

# Check firewall rules
sudo iptables -L CONTAINER-USER

# Verify containers on same network
container network connect claude-network claude-workspace-myapp
```

#### Issue: Permission Denied Errors

**Symptoms:**
```bash
EACCES: permission denied, open '/workspace/file.txt'
```

**Diagnosis:**
```bash
# Check file ownership
container exec claude-workspace-myapp ls -la /workspace

# Check user
container exec claude-workspace-myapp whoami
container exec claude-workspace-myapp id

# Check mount permissions
container inspect -f '{{json .Mounts}}' claude-workspace-myapp | jq .
```

**Solutions:**
```bash
# Run as root (temporary)
container exec -u root claude-workspace-myapp chown -R node:node /workspace

# Match user IDs (Containerfile)
FROM node:20-bookworm
RUN usermod -u 1000 node && groupmod -g 1000 node

# Use volume for permission-sensitive directories
{
  "volumes": {
    "/workspace/node_modules": {
      "type": "volume",
      "name": "myapp-node-modules"
    }
  }
}
```

### Diagnostic Commands

#### System Information

```bash
# Container version
container version

# Container system information
container info

# Disk usage
container system df

# Detailed disk usage
container system df -v
```

#### Container Inspection

```bash
# Full container details
container inspect claude-workspace-myapp

# Specific field
container inspect -f '{{.State.Status}}' claude-workspace-myapp

# Environment variables
container inspect -f '{{json .Config.Env}}' claude-workspace-myapp | jq .

# Network settings
container inspect -f '{{json .NetworkSettings}}' claude-workspace-myapp | jq .
```

#### Resource Monitoring

```bash
# Real-time resource usage
container stats

# Process list
container top claude-workspace-myapp

# Disk usage by container
container ps -s

# Events log
container events --since 1h
```

### Getting Help

If you're stuck:

1. **Check container logs:**
   ```bash
   # Check container system logs  # Linux
   # or check Apple Container logs
   ```

2. **Enable debug mode:**
   ```bash
   # # Container daemon configuration
   {
     "debug": true,
     "log-level": "debug"
   }
   ```

3. **Test minimal configuration:**
   ```json
   {
     "container": {
       "name": "test-container",
       "image": "alpine:latest",
       "workdir": "/workspace"
     }
   }
   ```

4. **Review documentation:**
   - README.md - Basic usage
   - CONFIGURATION.md - Configuration details
   - Container documentation - https://github.com/apple/container

5. **Check for known issues:**
   - Container GitHub issues
   - Claude Code documentation
   - Community forums
