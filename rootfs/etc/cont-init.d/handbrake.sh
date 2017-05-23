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

# Take ownership of the config directory.
chown -R $USER_ID:$GROUP_ID /config

# Take ownership of the output directory.
chown $USER_ID:$GROUP_ID /output

# vim: set ft=sh :
