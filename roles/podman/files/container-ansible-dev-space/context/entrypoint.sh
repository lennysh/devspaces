#!/bin/bash
set -e

# Get username from USER env var (passed from quadlet)
CONTAINER_USER=${USER:-user}

# Get current UID/GID (these are the mapped UIDs from --userns=keep-id)
# With --userns=keep-id, the host UID/GID are mapped to the same values in the container
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

# If we're running as root (UID 0), create the user matching the mapped UID/GID and switch to it
if [ "$CURRENT_UID" = "0" ]; then
  # When running as root, we need to get the target UID/GID from environment
  # These should match what --userns=keep-id will map to (the host user's UID/GID)
  TARGET_UID=${TARGET_UID:-1000}
  TARGET_GID=${TARGET_GID:-1000}
  
  echo "Running as root, creating user $CONTAINER_USER (UID: $TARGET_UID, GID: $TARGET_GID)"
  
  # Create group if it doesn't exist
  if ! getent group "$TARGET_GID" &>/dev/null && ! getent group "$CONTAINER_USER" &>/dev/null; then
    groupadd -g "$TARGET_GID" "$CONTAINER_USER" 2>/dev/null || true
  fi
  
  # Create user if it doesn't exist - use TARGET_UID which should match the host UID
  if ! id -u "$CONTAINER_USER" &>/dev/null; then
    # Check if UID is already in use by another user
    if getent passwd "$TARGET_UID" &>/dev/null; then
      EXISTING_USER=$(getent passwd "$TARGET_UID" | cut -d: -f1)
      echo "UID $TARGET_UID already exists as user $EXISTING_USER, using that user"
      CONTAINER_USER="$EXISTING_USER"
    else
      # Create user with the target UID (should match host UID due to --userns=keep-id)
      useradd -u "$TARGET_UID" -g "$TARGET_GID" -m -s /bin/bash "$CONTAINER_USER" 2>/dev/null || true
    fi
  else
    # User exists - use its existing UID (this is the correct approach)
    # With --userns=keep-id, we'll run as the host UID, which should match this user's UID
    EXISTING_UID=$(id -u "$CONTAINER_USER" 2>/dev/null || echo "")
    if [ -n "$EXISTING_UID" ]; then
      echo "User $CONTAINER_USER already exists with UID $EXISTING_UID"
      # Update TARGET_UID to match existing user (this is what we'll actually run as)
      TARGET_UID="$EXISTING_UID"
      TARGET_GID=$(id -g "$CONTAINER_USER" 2>/dev/null || echo "$TARGET_GID")
    fi
  fi
  
  # Ensure home directory exists and has correct permissions
  # Use the actual UID of the user (which may differ from TARGET_UID if user already existed)
  ACTUAL_USER_UID=$(id -u "$CONTAINER_USER" 2>/dev/null || echo "$TARGET_UID")
  ACTUAL_USER_GID=$(id -g "$CONTAINER_USER" 2>/dev/null || echo "$TARGET_GID")
  
  if [ -d "/home/$CONTAINER_USER" ]; then
    chown -R "$ACTUAL_USER_UID:$ACTUAL_USER_GID" "/home/$CONTAINER_USER" 2>/dev/null || true
  fi
  
  # Create devspace directory in user's home folder for code-server config
  # This avoids SELinux issues while keeping config in a logical location
  DEVSPACE_DIR="/home/$CONTAINER_USER/devspace"
  XDG_CONFIG_DIR="$DEVSPACE_DIR/.config"
  XDG_DATA_DIR="$DEVSPACE_DIR/.local/share"
  XDG_CACHE_DIR="$DEVSPACE_DIR/.cache"
  
  # Create parent directories and ensure they're writable
  mkdir -p "$XDG_CONFIG_DIR" "$XDG_DATA_DIR" "$XDG_CACHE_DIR" 2>/dev/null || true
  chown -R "$ACTUAL_USER_UID:$ACTUAL_USER_GID" "$DEVSPACE_DIR" 2>/dev/null || true
  chmod -R 755 "$DEVSPACE_DIR" 2>/dev/null || true
  
  # Create the code-server subdirectories
  CODE_SERVER_CONFIG_DIR="$XDG_CONFIG_DIR/code-server"
  CODE_SERVER_DATA_DIR="$XDG_DATA_DIR/code-server"
  CODE_SERVER_EXTENSIONS_DIR="$XDG_DATA_DIR/code-server/extensions"
  mkdir -p "$CODE_SERVER_CONFIG_DIR" "$CODE_SERVER_DATA_DIR" "$CODE_SERVER_EXTENSIONS_DIR" 2>/dev/null || true
  chown -R "$ACTUAL_USER_UID:$ACTUAL_USER_GID" "$CODE_SERVER_CONFIG_DIR" "$CODE_SERVER_DATA_DIR" "$CODE_SERVER_EXTENSIONS_DIR" 2>/dev/null || true
  chmod -R 755 "$CODE_SERVER_CONFIG_DIR" "$CODE_SERVER_DATA_DIR" "$CODE_SERVER_EXTENSIONS_DIR" 2>/dev/null || true
  
  # Export XDG variables for use after su
  export XDG_CONFIG_HOME="$XDG_CONFIG_DIR"
  export XDG_DATA_HOME="$XDG_DATA_DIR"
  export XDG_CACHE_HOME="$XDG_CACHE_DIR"
  
  # Set up sudo for the user
  if [ ! -f /etc/sudoers.d/$CONTAINER_USER ] || ! grep -q "^$CONTAINER_USER" /etc/sudoers.d/$CONTAINER_USER 2>/dev/null; then
    echo "$CONTAINER_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$CONTAINER_USER 2>/dev/null || true
    chmod 0440 /etc/sudoers.d/$CONTAINER_USER 2>/dev/null || true
  fi
  
  # Switch to the user and re-exec this script
  # Note: With --userns=keep-id, after su, we'll run as the mapped UID (host UID)
  # which should match TARGET_UID if it was set correctly
  # Preserve environment variables (especially PASSWORD) when switching users
  echo "Switching to user $CONTAINER_USER"
  # XDG variables are already set above, just need to pass them through su
  # Use su with explicit environment variable passing
  exec su - "$CONTAINER_USER" -c "export PASSWORD='$PASSWORD' && export USER='$USER' && export TARGET_UID='$TARGET_UID' && export TARGET_GID='$TARGET_GID' && export XDG_CONFIG_HOME='$XDG_CONFIG_HOME' && export XDG_DATA_HOME='$XDG_DATA_HOME' && export XDG_CACHE_HOME='$XDG_CACHE_HOME' && cd /home/$CONTAINER_USER && $0"
fi

# At this point, we're running as the mapped UID from --userns=keep-id
# Get the actual UID/GID we're running as (this is the mapped UID from the host)
ACTUAL_UID=$(id -u)
ACTUAL_GID=$(id -g)

# If we don't have a proper username (running as numeric UID), set up environment
if ! id -un &>/dev/null || [ "$(id -un)" = "$ACTUAL_UID" ] || [ -z "$(id -un)" ]; then
  # We're running as a numeric UID, set environment variables
  if [ -n "$CONTAINER_USER" ] && [ "$CONTAINER_USER" != "$ACTUAL_UID" ]; then
    export USER="$CONTAINER_USER"
    if [ -d "/home/$CONTAINER_USER" ]; then
      export HOME="/home/$CONTAINER_USER"
    else
      # Create home directory if it doesn't exist
      mkdir -p "/home/$CONTAINER_USER" 2>/dev/null || export HOME="/tmp"
    fi
  else
    # No username available, use numeric UID
    export USER="user$ACTUAL_UID"
    export HOME="/home/$USER"
    mkdir -p "$HOME" 2>/dev/null || export HOME="/tmp"
  fi
fi

# Ensure HOME is set
export HOME="${HOME:-/tmp}"

# Create devspace directory in user's home folder for code-server config
# This avoids SELinux issues while keeping config in a logical location
ACTUAL_UID=$(id -u)
ACTUAL_GID=$(id -g)

# Determine the user's home directory
USER_HOME="${HOME:-/home/${CONTAINER_USER:-user}}"
DEVSPACE_DIR="$USER_HOME/devspace"
XDG_CONFIG_DIR="$DEVSPACE_DIR/.config"
XDG_DATA_DIR="$DEVSPACE_DIR/.local/share"
XDG_CACHE_DIR="$DEVSPACE_DIR/.cache"

# Create parent directories and ensure they're writable
mkdir -p "$XDG_CONFIG_DIR" "$XDG_DATA_DIR" "$XDG_CACHE_DIR" 2>/dev/null || true
chmod -R 755 "$DEVSPACE_DIR" 2>/dev/null || true
chown -R "$ACTUAL_UID:$ACTUAL_GID" "$DEVSPACE_DIR" 2>/dev/null || true

# Create the code-server subdirectories that code-server will use
CODE_SERVER_CONFIG_DIR="$XDG_CONFIG_DIR/code-server"
CODE_SERVER_DATA_DIR="$XDG_DATA_DIR/code-server"
CODE_SERVER_EXTENSIONS_DIR="$XDG_DATA_DIR/code-server/extensions"
mkdir -p "$CODE_SERVER_CONFIG_DIR" "$CODE_SERVER_DATA_DIR" "$CODE_SERVER_EXTENSIONS_DIR" 2>/dev/null || true
chmod -R 755 "$CODE_SERVER_CONFIG_DIR" "$CODE_SERVER_DATA_DIR" "$CODE_SERVER_EXTENSIONS_DIR" 2>/dev/null || true
chown -R "$ACTUAL_UID:$ACTUAL_GID" "$CODE_SERVER_CONFIG_DIR" "$CODE_SERVER_DATA_DIR" "$CODE_SERVER_EXTENSIONS_DIR" 2>/dev/null || true

# Set XDG environment variables to control where code-server stores its config
# This uses the devspace directory in the user's home folder
export XDG_CONFIG_HOME="$XDG_CONFIG_DIR"
export XDG_DATA_HOME="$XDG_DATA_DIR"
export XDG_CACHE_HOME="$XDG_CACHE_DIR"

# Ensure extensions directory exists
EXTENSION_DIR="$XDG_DATA_HOME/code-server/extensions"
mkdir -p "$EXTENSION_DIR" 2>/dev/null || true
chown -R "$ACTUAL_UID:$ACTUAL_GID" "$EXTENSION_DIR" 2>/dev/null || true
chmod -R 755 "$EXTENSION_DIR" 2>/dev/null || true

# Install VSCode extensions for the user (if not already installed)
# Extensions are installed to XDG_DATA_HOME which points to the devspace directory
CS_EXTENSIONS="redhat.ansible redhat.vscode-redhat-account redhat.vscode-yaml"
for extension in $CS_EXTENSIONS; do
  # Check if extension is already installed by looking for it in the extensions directory
  if [ -z "$(find "$EXTENSION_DIR" -maxdepth 2 -name "*${extension}*" -type d 2>/dev/null)" ]; then
    echo "Installing extension: $extension"
    /usr/local/bin/code-server --install-extension "$extension" --force 2>/dev/null || echo "Warning: Failed to install extension $extension"
  else
    echo "Extension $extension already installed"
  fi
done

# If PASSWORD environment variable is set, code-server will automatically use it
# No need to pass --password flag (code-server reads $PASSWORD env var directly)
if [ -n "$PASSWORD" ]; then
  echo "✅ Starting with password authentication."
  # code-server will automatically use $PASSWORD env var for authentication
  # XDG environment variables will make it use the devspace directory
  exec code-server --bind-addr 0.0.0.0:8080 .
else
  echo "⚠️  Starting with no authentication. Set the PASSWORD env var for security."
  exec code-server --bind-addr 0.0.0.0:8080 --auth none .
fi