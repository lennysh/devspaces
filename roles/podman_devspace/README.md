# lennysh.devspaces.podman_devspace

Configures a development environment (devspace) for a specific user using a Podman container with code-server. This role uses systemd quadlets to manage the container as a user service, running both inside and outside the container as the specified user (no root required).

## Requirements

- Podman must be installed
- Target user must exist on the system
- Root or sudo access (for initial setup only)
- Container image with code-server and development tools pre-installed

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `username` | **required** | Username to configure the devspace for |
| `podman_devspace_image` | `quay.io/lshirley/ansible-dev-space:latest` | Container image to use for the devspace |
| `code_server_pass` | `null` | Password for code-server authentication. If not set, authentication is disabled |
| `dev_server_port` | `null` | Port for code-server to listen on. If `null`, automatically assigns next available port |
| `port_range_start` | `8080` | Starting port for automatic port assignment |
| `port_range_end` | `8099` | Ending port for automatic port assignment |
| `podman_devspace_container_name_prefix` | `code-server` | Prefix for the container name |

## Dependencies

None (this role only requires podman, not code-server installation)

## Example Playbook

```yaml
- hosts: all
      roles:
    - lennysh.devspaces.podman_devspace
  vars:
    username: alice
    podman_devspace_image: quay.io/lshirley/ansible-dev-space:latest
    code_server_pass: securepass123
    dev_server_port: null  # Auto-assign port
    port_range_start: 8080
    port_range_end: 8099
```

## Features

- **Smart Port Management**: Automatically discovers existing quadlet containers and assigns the next available port
- **Port Reuse**: If a user already has a container configured, reuses their existing port
- **Automatic Port Assignment**: Finds next available port in the specified range
- **User-Specific Configuration**: Each user gets their own container instance with isolated settings
- **Rootless Operation**: Container runs as the user both inside and outside (no root required)
- **Systemd Quadlet Integration**: Uses systemd quadlets for container lifecycle management
- **User Lingering**: Automatically enables user lingering for systemd user services
- **Firewall Configuration**: Automatically opens the required port in firewalld (if available)

## What Gets Configured

- Systemd quadlet file: `~/.config/containers/systemd/code-server-{{ username }}.container`
- Systemd user service: `code-server-{{ username }}.service`
- Container: `code-server-{{ username }}` (managed by systemd)
- User's home directory mounted into container at `/home/{{ username }}`
- Firewall rules (if firewalld is running)

## Access

After deployment, access the devspace at:
```
https://<hostname>:<port>/?folder=/home/<username>/devspace
```

The role will display the full URL at the end of execution.

## Container Image Requirements

Your container image should:
- Have code-server installed and configured
- Have development tools pre-installed (ansible-dev-tools, etc.)
- Be configured to run code-server on port 8080 inside the container
- Support the `PASSWORD` environment variable for authentication
- Support the `USER` environment variable

## Managing the Container

The container is managed via systemd user services:

```bash
# Check status
systemctl --user status code-server-{{ username }}.service

# Stop container
systemctl --user stop code-server-{{ username }}.service

# Start container
systemctl --user start code-server-{{ username }}.service

# Restart container
systemctl --user restart code-server-{{ username }}.service

# View logs
journalctl --user -u code-server-{{ username }}.service
```

## Differences from `devspace` Role

- **Container-based**: Uses a pre-built container image instead of installing code-server directly
- **Rootless**: Runs entirely as the user (no root inside container)
- **Quadlet-based**: Uses systemd quadlets instead of traditional systemd service files
- **No code-server installation**: Does not require code-server to be installed on the host
- **Simpler setup**: Container image contains all tools, reducing host configuration

## License

GPL-3.0-or-later

See the [LICENSE](../../LICENSE) file for the full text of the GNU General Public License version 3.

## Credits

This role was inspired by and started with code from [shadowman-lab/Ansible-Development](https://github.com/shadowman-lab/Ansible-Development) by Alex Dworjan.

## Author Information

This role is part of the lennysh.devspaces collection.
