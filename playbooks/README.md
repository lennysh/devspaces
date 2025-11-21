# Playbooks

This directory contains ready-to-use playbooks for the lennysh.devspaces collection.

## Available Playbooks

### install_code_server.yml

Installs or updates code-server system-wide on target hosts. Also installs system-wide dependencies (podman, git, python3.11, python3.11-pip).

**Basic Usage:**
```bash
ansible-playbook -i inventory playbooks/install_code_server.yml
```

**With specific version:**
```bash
ansible-playbook -i inventory playbooks/install_code_server.yml -e "code_server_version=4.20.0"
```

**Target specific hosts:**
```bash
ansible-playbook -i inventory playbooks/install_code_server.yml --limit dev_servers
```

### install_podman.yml

Installs podman container runtime system-wide on target hosts. Also installs python3-firewall (required for ansible.posix.firewalld module). By default, also builds the container image (`quay.io/lshirley/ansible-dev-space:latest`) for use with the `podman_devspace` role.

**Basic Usage:**
```bash
ansible-playbook -i inventory playbooks/install_podman.yml
```

**Skip image building (if image is already built or will be pulled from registry):**
```bash
ansible-playbook -i inventory playbooks/install_podman.yml -e "podman_build_image=false"
```

**Specify custom container build source path:**
```bash
ansible-playbook -i inventory playbooks/install_podman.yml \
  -e "podman_build_source_path=/path/to/containers/ansible-dev-space"
```

**Build with custom image name:**
```bash
ansible-playbook -i inventory playbooks/install_podman.yml \
  -e "podman_build_image_name=myregistry.io/my-image:latest"
```

**Target specific hosts:**
```bash
ansible-playbook -i inventory playbooks/install_podman.yml --limit dev_servers
```

### deploy_devspace.yml

Configures a development environment (devspace) for a specific user using code-server installed directly on the host. Requires code-server to be installed first (via `install_code_server.yml`). This uses the traditional approach where code-server runs as a systemd service on the host.

**Note:** For container-based deployments, use `deploy_podman_devspace.yml` instead.

**Basic Usage:**
```bash
ansible-playbook -i inventory playbooks/deploy_devspace.yml \
  -e "username=alice" \
  -e "code_server_pass=securepass123"
```

**With specific port:**
```bash
ansible-playbook -i inventory playbooks/deploy_devspace.yml \
  -e "username=alice" \
  -e "code_server_pass=securepass123" \
  -e "dev_server_port=8080"
```

**With custom port range:**
```bash
ansible-playbook -i inventory playbooks/deploy_devspace.yml \
  -e "username=alice" \
  -e "code_server_pass=securepass123" \
  -e "port_range_start=9000" \
  -e "port_range_end=9099"
```

**Using Ansible Vault for password:**
```bash
ansible-playbook -i inventory playbooks/deploy_devspace.yml \
  -e "username=alice" \
  -e "code_server_pass={{ vault_code_server_pass }}" \
  --ask-vault-pass
```

**Disable authentication (no password):**
```bash
ansible-playbook -i inventory playbooks/deploy_devspace.yml \
  -e "username=alice"
```

**Customize deployment options:**
```bash
ansible-playbook -i inventory playbooks/deploy_devspace.yml \
  -e "username=alice" \
  -e "code_server_pass=securepass123" \
  -e "deploy_inventory=false" \
  -e "deploy_example_repo=false"
```

### deploy_podman_devspace.yml

Configures a development environment (devspace) for a specific user using a Podman container with code-server. Uses systemd quadlets to manage the container as a user service. Requires podman to be installed first.

**Basic Usage:**
```bash
ansible-playbook -i inventory playbooks/deploy_podman_devspace.yml \
  -e "username=alice" \
  -e "code_server_pass=securepass123"
```

**With specific port:**
```bash
ansible-playbook -i inventory playbooks/deploy_podman_devspace.yml \
  -e "username=alice" \
  -e "code_server_pass=securepass123" \
  -e "dev_server_port=8080"
```

**With custom port range:**
```bash
ansible-playbook -i inventory playbooks/deploy_podman_devspace.yml \
  -e "username=alice" \
  -e "code_server_pass=securepass123" \
  -e "port_range_start=9000" \
  -e "port_range_end=9099"
```

**Using Ansible Vault for password:**
```bash
ansible-playbook -i inventory playbooks/deploy_podman_devspace.yml \
  -e "username=alice" \
  -e "code_server_pass={{ vault_code_server_pass }}" \
  --ask-vault-pass
```

**With custom container image:**
```bash
ansible-playbook -i inventory playbooks/deploy_podman_devspace.yml \
  -e "username=alice" \
  -e "code_server_pass=securepass123" \
  -e "podman_devspace_image=quay.io/myorg/my-image:latest"
```

**Disable authentication (no password):**
```bash
ansible-playbook -i inventory playbooks/deploy_podman_devspace.yml \
  -e "username=alice"
```

## Complete Workflow Examples

### Traditional Code-Server Workflow

1. **Install code-server on all hosts:**
   ```bash
   ansible-playbook -i inventory playbooks/install_code_server.yml
   ```

2. **Deploy devspace for user alice:**
   ```bash
   ansible-playbook -i inventory playbooks/deploy_devspace.yml \
     -e "username=alice" \
     -e "code_server_pass=securepass123"
   ```

3. **Deploy devspace for user bob:**
   ```bash
   ansible-playbook -i inventory playbooks/deploy_devspace.yml \
     -e "username=bob" \
     -e "code_server_pass=anotherpass456"
   ```

### Podman Container Workflow

1. **Install podman on all hosts:**
   ```bash
   ansible-playbook -i inventory playbooks/install_podman.yml
   ```

2. **Deploy podman devspace for user alice:**
   ```bash
   ansible-playbook -i inventory playbooks/deploy_podman_devspace.yml \
     -e "username=alice" \
     -e "code_server_pass=securepass123"
   ```

3. **Deploy podman devspace for user bob:**
   ```bash
   ansible-playbook -i inventory playbooks/deploy_podman_devspace.yml \
     -e "username=bob" \
     -e "code_server_pass=anotherpass456"
   ```

## Variables Reference

### install_code_server.yml

| Variable | Default | Description |
|----------|---------|-------------|
| `code_server_version` | `latest` | Code-server version to install. Use `latest` for auto-detection or specify like `4.20.0` |

### deploy_devspace.yml

| Variable | Default | Description |
|----------|---------|-------------|
| `username` | **required** | Username to configure devspace for |
| `code_server_pass` | `null` | Password for code-server. If null, authentication is disabled |
| `dev_server_port` | `null` | Specific port. If null, auto-assigns next available port |
| `port_range_start` | `8080` | Starting port for auto-assignment |
| `port_range_end` | `8099` | Ending port for auto-assignment |
| `deploy_inventory` | `true` | Deploy Ansible inventory files |
| `deploy_example_repo` | `true` | Clone example Ansible repository |
| `deploy_ansiblegalaxy_repo` | `false` | Create example role structure using ansible-galaxy |

### install_podman.yml

| Variable | Default | Description |
|----------|---------|-------------|
| `podman_build_image` | `true` | Whether to build the container image. Set to `false` to skip |
| `podman_build_image_name` | `quay.io/lshirley/ansible-dev-space:latest` | Name and tag of the container image to build |
| `podman_build_source_path` | `{{ role_path }}/files/container-ansible-dev-space` | Path to container build directory on control node. Defaults to role's files directory |
| `podman_build_set_selinux_context` | `true` | Whether to set SELinux context on build context files |

### deploy_podman_devspace.yml

| Variable | Default | Description |
|----------|---------|-------------|
| `username` | **required** | Username to configure devspace for |
| `code_server_pass` | `null` | Password for code-server. If null, authentication is disabled |
| `dev_server_port` | `null` | Specific port. If null, auto-assigns next available port |
| `port_range_start` | `8080` | Starting port for auto-assignment |
| `port_range_end` | `8099` | Ending port for auto-assignment |
| `podman_devspace_image` | `quay.io/lshirley/ansible-dev-space:latest` | Container image to use for the devspace |
| `podman_devspace_container_name_prefix` | `code-server` | The name prefix for the deployed container |

## Notes

- The `install_code_server.yml` and `install_podman.yml` playbooks are idempotent and can be run multiple times safely
- The `deploy_devspace.yml` and `deploy_podman_devspace.yml` playbooks will reuse existing ports if a user already has a devspace configured
- All playbooks require root/sudo access
- The playbooks are designed to work with RHEL/CentOS/Fedora systems using dnf
- The `deploy_podman_devspace.yml` playbook uses systemd quadlets and runs containers as the user (rootless)
- The `deploy_podman_devspace.yml` playbook automatically enables user lingering for systemd user services

