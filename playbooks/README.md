# Playbooks

This directory contains ready-to-use playbooks for the lennysh.devspaces collection.

## Available Playbooks

### install-code-server.yml

Installs or updates code-server system-wide on target hosts. Also installs system-wide dependencies (podman, git, python3.11, python3.11-pip).

**Basic Usage:**
```bash
ansible-playbook -i inventory playbooks/install-code-server.yml
```

**With specific version:**
```bash
ansible-playbook -i inventory playbooks/install-code-server.yml -e "code_server_version=4.20.0"
```

**Target specific hosts:**
```bash
ansible-playbook -i inventory playbooks/install-code-server.yml --limit dev_servers
```

### deploy-devspace.yml

Configures a development environment (devspace) for a specific user. Requires code-server to be installed first.

**Basic Usage:**
```bash
ansible-playbook -i inventory playbooks/deploy-devspace.yml \
  -e "username=alice" \
  -e "code_server_pass=securepass123"
```

**With specific port:**
```bash
ansible-playbook -i inventory playbooks/deploy-devspace.yml \
  -e "username=alice" \
  -e "code_server_pass=securepass123" \
  -e "dev_server_port=8080"
```

**With custom port range:**
```bash
ansible-playbook -i inventory playbooks/deploy-devspace.yml \
  -e "username=alice" \
  -e "code_server_pass=securepass123" \
  -e "port_range_start=9000" \
  -e "port_range_end=9099"
```

**Using Ansible Vault for password:**
```bash
ansible-playbook -i inventory playbooks/deploy-devspace.yml \
  -e "username=alice" \
  -e "code_server_pass={{ vault_code_server_pass }}" \
  --ask-vault-pass
```

**Disable authentication (no password):**
```bash
ansible-playbook -i inventory playbooks/deploy-devspace.yml \
  -e "username=alice"
```

**Customize deployment options:**
```bash
ansible-playbook -i inventory playbooks/deploy-devspace.yml \
  -e "username=alice" \
  -e "code_server_pass=securepass123" \
  -e "deploy_inventory=false" \
  -e "deploy_example_repo=false"
```

## Complete Workflow Example

1. **Install code-server on all hosts:**
   ```bash
   ansible-playbook -i inventory playbooks/install-code-server.yml
   ```

2. **Deploy devspace for user alice:**
   ```bash
   ansible-playbook -i inventory playbooks/deploy-devspace.yml \
     -e "username=alice" \
     -e "code_server_pass=securepass123"
   ```

3. **Deploy devspace for user bob:**
   ```bash
   ansible-playbook -i inventory playbooks/deploy-devspace.yml \
     -e "username=bob" \
     -e "code_server_pass=anotherpass456"
   ```

## Variables Reference

### install-code-server.yml

| Variable | Default | Description |
|----------|---------|-------------|
| `code_server_version` | `latest` | Code-server version to install. Use `latest` for auto-detection or specify like `4.20.0` |

### deploy-devspace.yml

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

## Notes

- The `install-code-server.yml` playbook is idempotent and can be run multiple times safely
- The `deploy-devspace.yml` playbook will reuse existing ports if a user already has a devspace configured
- Both playbooks require root/sudo access
- The playbooks are designed to work with RHEL/CentOS/Fedora systems using dnf

