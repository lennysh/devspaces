# Ansible Collection - lennysh.devspaces

This collection provides roles for setting up development environments using code-server (VS Code in the browser) with Ansible development tools.

## Collection Requirements

- Ansible >= 2.9.10
- Python >= 3.8
- RHEL/CentOS/Fedora (uses dnf package manager)
- Root or sudo access

## Collection Dependencies

- `ansible.posix` - For firewalld management
- `community.general` - For capabilities management
- `containers.podman` - For container image management

## Installation

Install the collection from Ansible Galaxy:

```bash
ansible-galaxy collection install lennysh.devspaces
```

Or install from source:

```bash
ansible-galaxy collection install git+https://github.com/lennysh/lennysh-devspaces.git
```

## Roles

### lennysh.devspaces.code_server

Installs code-server (VS Code Server) system-wide on the target host.

**Requirements:**
- RHEL/CentOS/Fedora with dnf package manager
- Internet access to download code-server from GitHub releases

**Role Variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `version` | `latest` | Code-server version to install. Use `latest` for automatic version detection or specify a version like `4.20.0` |
| `codeserver_url` | Auto-constructed | URL to download code-server RPM. Automatically constructed from `version` |
| `_github_api_headers` | Auto-detected | GitHub API headers for authentication (optional, uses GITHUB_TOKEN env var if available) |

**Example Playbook:**

```yaml
- hosts: all
  roles:
    - lennysh.devspaces.code_server
  vars:
    version: latest  # or specific version like "4.20.0"
```

**What Gets Installed:**
- code-server (VS Code Server)
- podman (container runtime)
- git (version control)
- python3.11 and python3.11-pip (Python runtime)

**Notes:**
- The role is idempotent and will skip installation if code-server is already installed
- Automatically discovers the latest version from GitHub releases when `version: latest`
- Downloads and installs the RPM package using dnf
- Installs system-wide dependencies required for development environments

### lennysh.devspaces.devspace

Configures a development environment (devspace) for a specific user using code-server. This role assumes code-server is already installed (via `lennysh.devspaces.code_server`).

**Requirements:**
- code-server must be installed (run `lennysh.devspaces.code_server` first)
- Target user must exist on the system

**Role Variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `username` | **required** | Username to configure the devspace for |
| `code_server_pass` | `null` | Password for code-server authentication. If not set, authentication is disabled |
| `dev_server_port` | `null` | Port for code-server to listen on. If `null`, automatically assigns next available port |
| `port_range_start` | `8080` | Starting port for automatic port assignment |
| `port_range_end` | `8099` | Ending port for automatic port assignment |
| `deploy_inventory` | `true` | Deploy Ansible inventory files |
| `deploy_example_repo` | `true` | Clone example Ansible repository |
| `deploy_ansiblegalaxy_repo` | `false` | Create example role structure using ansible-galaxy |
| `cert_name` | `null` | SSL certificate filename (optional) |
| `key_name` | `null` | SSL key filename (optional) |
| `certandkeysourcefolder` | `null` | Source folder for SSL certificates (optional) |
| `certandkeydestfolder` | `null` | Destination folder for SSL certificates (optional) |
| `additionalimagestores` | `null` | Additional Podman image stores (optional) |
| `ansible_image` | `null` | Ansible execution environment image to pull (optional) |
| `registry_user` | `null` | Registry username for pulling images (optional) |
| `registry_pass` | `null` | Registry password for pulling images (optional) |

**Example Playbook:**

```yaml
- hosts: all
  roles:
    - lennysh.devspaces.code_server
    - lennysh.devspaces.devspace
  vars:
    username: alice
    code_server_pass: securepass123
    dev_server_port: null  # Auto-assign port
    port_range_start: 8080
    port_range_end: 8099
    deploy_inventory: true
    deploy_example_repo: true
```

**Features:**
- **Smart Port Management**: Automatically discovers existing code-server services and assigns the next available port
- **Port Reuse**: If a user already has a service configured, reuses their existing port
- **Automatic Port Assignment**: Finds next available port in the specified range
- **User-Specific Configuration**: Each user gets their own code-server instance with isolated settings
- **Ansible Development Tools**: Installs ansible-dev-tools, ansible-navigator, and related tools
- **Podman Support**: Configures Podman with subuid/subgid allocation for rootless containers
- **VS Code Extensions**: Installs Red Hat Ansible extension and Red Hat Account extension
- **Systemd Integration**: Creates and manages systemd service for each user
- **Firewall Configuration**: Automatically opens the required port in firewalld

**What Gets Configured:**
- Systemd service: `code-server@{{ username }}.service`
- User configuration: `~/.config/code-server/config.yaml`
- VS Code settings: `~/.local/share/code-server/User/settings.json`
- Ansible directory structure: `~/ansible/`
- Ansible Navigator configuration
- Podman configuration (if needed)
- User lingering (for systemd user services)
- Firewall rules

**Access:**
After deployment, access the devspace at:
```
https://<hostname>:<port>/?folder=/home/<username>/ansible
```

The role will display the full URL at the end of execution.

## Complete Example

```yaml
---
- name: Setup development environment
  hosts: dev_servers
  become: true
  vars:
    username: developer1
    code_server_pass: "{{ vault_code_server_pass }}"
    port_range_start: 8080
    port_range_end: 8099
    deploy_inventory: true
    deploy_example_repo: true

  roles:
    # First, install code-server system-wide
    - lennysh.devspaces.code_server
    
    # Then, configure devspace for the user
    - lennysh.devspaces.devspace
```

## License

GPL-2.0-or-later

## Credits

This collection was inspired by and started with code from [shadowman-lab/Ansible-Development](https://github.com/shadowman-lab/Ansible-Development) by Alex Dworjan. The original repository provided the foundation for setting up Ansible development environments with code-server.

## Author Information

This collection is maintained by lennysh.

## Support

For issues, questions, or contributions, please visit the project repository.
