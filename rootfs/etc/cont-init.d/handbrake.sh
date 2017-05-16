#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Generate machine id.
echo "Generating machine-id..."
cat /proc/sys/kernel/random/uuid | tr -d '-' > /etc/machine-id

# Copy default configuration if needed.
if [ ! -f /config/ghb/preferences.json ]; then
  mkdir -p /config/ghb
  cp /defaults/preferences.json /config/ghb/preferences.json
fi

# Adjust config file permissions.
chown -R $USER_ID:$GROUP_ID /config

# vim: set ft=sh :
