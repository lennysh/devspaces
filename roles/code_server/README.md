# lennysh.devspaces.code_server

Installs code-server (VS Code Server) system-wide on the target host.

## Requirements

- RHEL/CentOS/Fedora with dnf package manager
- Internet access to download code-server from GitHub releases
- Root or sudo access

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `version` | `latest` | Code-server version to install. Use `latest` for automatic version detection or specify a version like `4.20.0` |
| `codeserver_url` | Auto-constructed | URL to download code-server RPM. Automatically constructed from `version` |
| `_github_api_headers` | Auto-detected | GitHub API headers for authentication (optional, uses GITHUB_TOKEN env var if available) |

## Dependencies

None

## Example Playbook

```yaml
- hosts: all
  roles:
    - lennysh.devspaces.code_server
  vars:
    version: latest  # or specific version like "4.20.0"
```

## What Gets Installed

- code-server (VS Code Server)
- podman (container runtime)
- git (version control)
- python3.11 and python3.11-pip (Python runtime)

## Notes

- The role is idempotent and will skip installation if code-server is already installed
- Automatically discovers the latest version from GitHub releases when `version: latest`
- Downloads and installs the RPM package using dnf
- Installs system-wide dependencies required for development environments

## License

GPL-2.0-or-later

## Credits

This role was inspired by and started with code from [shadowman-lab/Ansible-Development](https://github.com/shadowman-lab/Ansible-Development) by Alex Dworjan.

## Author Information

This role is part of the lennysh.devspaces collection.

