# lennysh.devspaces.devspace

Configures a development environment (devspace) for a specific user using code-server. This role assumes code-server is already installed (via `lennysh.devspaces.code_server`).

## Requirements

- code-server must be installed (run `lennysh.devspaces.code_server` first)
- Target user must exist on the system
- Root or sudo access

## Role Variables

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

## Dependencies

- `lennysh.devspaces.code_server` - Must be run first to install code-server

## Example Playbook

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

## Features

- **Smart Port Management**: Automatically discovers existing code-server services and assigns the next available port
- **Port Reuse**: If a user already has a service configured, reuses their existing port
- **Automatic Port Assignment**: Finds next available port in the specified range
- **User-Specific Configuration**: Each user gets their own code-server instance with isolated settings
- **Ansible Development Tools**: Installs ansible-dev-tools, ansible-navigator, and related tools
- **Podman Support**: Configures Podman with subuid/subgid allocation for rootless containers
- **VS Code Extensions**: Installs Red Hat Ansible extension and Red Hat Account extension
- **Systemd Integration**: Creates and manages systemd service for each user
- **Firewall Configuration**: Automatically opens the required port in firewalld

## What Gets Configured

- Systemd service: `code-server@{{ username }}.service`
- User configuration: `~/.config/code-server/config.yaml`
- VS Code settings: `~/.local/share/code-server/User/settings.json`
- Ansible directory structure: `~/ansible/`
- Ansible Navigator configuration
- Podman configuration (if needed)
- User lingering (for systemd user services)
- Firewall rules

## Access

After deployment, access the devspace at:
```
https://<hostname>:<port>/?folder=/home/<username>/ansible
```

The role will display the full URL at the end of execution.

## License

GPL-3.0-or-later

See the [LICENSE](../../LICENSE) file for the full text of the GNU General Public License version 3.

## Credits

This role was inspired by and started with code from [shadowman-lab/Ansible-Development](https://github.com/shadowman-lab/Ansible-Development) by Alex Dworjan.

## Author Information

This role is part of the lennysh.devspaces collection.

