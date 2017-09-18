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

# Copy example hooks if needed.
mkdir -p /config/hooks
for hook in post_conversion.sh
do
  [ ! -f /config/hooks/$hook ] || continue
  [ ! -f /config/hooks/$hook.example ] || continue
  cp /defaults/hooks/$hook.example /config/hooks/
done

# Clear the fstab file to make sure its content is not displayed in HandBrake
# when opening the source video.
echo > /etc/fstab

# Take ownership of the config directory.
chown -R $USER_ID:$GROUP_ID /config

# Take ownership of the output directory.
chown $USER_ID:$GROUP_ID /output

# vim: set ft=sh :
