#!/bin/bash -e
# cspell: ignore makecache overlayfs libssh chgrp noplugins
set -eux pipefail

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

dnf --noplugins remove -y -q subscription-manager dnf-plugin-subscription-manager iptables-legacy
dnf install -y -q iptables-nft
dnf -y -q makecache
dnf -y -q update
dnf install -y -q \
    dumb-init \
    fuse-overlayfs \
    gcc \
    git \
    git-core \
    libssh-devel \
    ncurses \
    openssh-clients \
    podman \
    "python${PYV}" \
    "python${PYV}-cffi" \
    "python${PYV}-pip" \
    "python${PYV}-pyyaml" \
    "python${PYV}-wheel" \
    tar \
    util-linux-user \
    which \
    zsh \
    pinentry \
    --exclude container-selinux
#     python${PYV}-ruamel-yaml \
dnf -y -q clean all

# Fix pip cache directory permissions (running as root, but /home/user/.cache/pip may exist)
# Ensure the entire cache directory tree exists and is owned by root
mkdir -p /home/user/.cache/pip
chown -R 0:0 /home/user/.cache 2>/dev/null || true
chmod -R 755 /home/user/.cache 2>/dev/null || true

# Check if any .whl files exist before trying to install them
WHEEL_FILES=(./*.whl)
if [ -f "${WHEEL_FILES[0]}" ]; then
  # If a wheel file is found, install it with the server extra
  "/usr/bin/python${PYV}" -m pip install --root-user-action=ignore "${WHEEL_FILES[0]}[server]" -r requirements.txt
else
  # Otherwise, just install from requirements.txt
  "/usr/bin/python${PYV}" -m pip install --root-user-action=ignore -r requirements.txt
fi

# Install Ansible collections
# The Galaxy API has a bug where dependency resolution fails with KeyError: 'results'
# Install collections individually without dependency resolution to work around this
ansible-galaxy collection install ansible.netcommon --no-deps || true
ansible-galaxy collection install ansible.posix --no-deps || true
ansible-galaxy collection install ansible.scm --no-deps || true
ansible-galaxy collection install ansible.utils --no-deps || true

chgrp -R 0 /home && chmod -R g=u /etc/passwd /etc/group /home

# Configure the podman wrapper
cp podman.py /usr/bin/podman.wrapper
chown 0:0 /usr/bin/podman.wrapper
chmod +x /usr/bin/podman.wrapper

# shellcheck disable=SC1091
# source "$DIR/setup-image.sh"