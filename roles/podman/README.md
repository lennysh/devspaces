# lennysh.devspaces.podman

Installs podman container runtime system-wide on the target host and optionally builds the container image for use with `podman_devspace` role.

## Requirements

- RHEL/CentOS/Fedora with dnf package manager
- Root or sudo access
- `containers.podman` collection (for image building)

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `podman_build_image` | `true` | Whether to build the container image. Set to `false` to skip image building |
| `podman_build_image_name` | `quay.io/lshirley/ansible-dev-space:latest` | Name and tag of the container image to build |
| `podman_build_code_server_version` | `latest` | Code-server version to use in the container. Use `latest` to auto-discover, or specify like `4.91.1` |
| `podman_build_source_path` | `{{ role_path }}/files/container-ansible-dev-space` | Path to container build directory on control node. Defaults to role's files directory |
| `podman_build_set_selinux_context` | `true` | Whether to set SELinux context on build context files (required on SELinux-enabled systems) |
| `podman_build_cleanup_intermediate` | `true` | Whether to clean up intermediate/dangling images after build |

## Dependencies

- `containers.podman` collection

## Example Playbook

```yaml
- hosts: all
  roles:
    - lennysh.devspaces.podman
```

## What Gets Installed

- podman (container runtime)
- python3-firewall (required for ansible.posix.firewalld module)

## What Gets Built

- Container image: `quay.io/lshirley/ansible-dev-space:latest` (if `podman_build_image: true`)

## Notes

- The role is idempotent and will skip installation if podman is already installed
- Image building is idempotent - it will skip building if the image already exists (unless forced)
- Installs only podman and its minimal dependencies (no git, python3.11, etc.)
- Use this role when you only need podman (e.g., for `podman_devspace` role)
- For full development environment setup, use `lennysh.devspaces.code_server` instead
- The container build source path defaults to the role's files directory (`{{ role_path }}/files/container-ansible-dev-space`)
- Falls back to `{{ playbook_dir }}/../containers/ansible-dev-space` if `role_path` is not available
- If the container build directory is in a different location, set `podman_build_source_path` to the correct path
- To skip image building (e.g., if image is already built or will be pulled from registry), set `podman_build_image: false`
- The Containerfile is templated with the code-server version. Set `podman_build_code_server_version: "latest"` to auto-discover the latest version, or specify a version like `"4.91.1"`
- Intermediate and dangling images are automatically cleaned up after build (set `podman_build_cleanup_intermediate: false` to disable)

## License

GPL-3.0-or-later

See the [LICENSE](../../LICENSE) file for the full text of the GNU General Public License version 3.

## Credits

This role was inspired by and started with code from [shadowman-lab/Ansible-Development](https://github.com/shadowman-lab/Ansible-Development) by Alex Dworjan.

## Author Information

This role is part of the lennysh.devspaces collection.

