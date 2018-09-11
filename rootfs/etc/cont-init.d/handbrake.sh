#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

log() {
    echo "[cont-init.d] $(basename $0): $*"
}

# Generate machine id.
if [ ! -f /etc/machine-id ]; then
    log "generating machine-id..."
    cat /proc/sys/kernel/random/uuid | tr -d '-' > /etc/machine-id
fi

# Make sure mandatory directories exist.
mkdir -p /config/ghb
mkdir -p /config/hooks
mkdir -p /config/log/hb

# Copy default configuration if needed.
if [ ! -f /config/ghb/preferences.json ]; then
  cp /defaults/preferences.json /config/ghb/preferences.json
fi

# Copy example hooks if needed.
for hook in pre_conversion.sh post_conversion.sh
do
  [ ! -f /config/hooks/$hook ] || continue
  [ ! -f /config/hooks/$hook.example ] || continue
  cp /defaults/hooks/$hook.example /config/hooks/
done

# Make sure the debug log is under the proper directory.
[ ! -f /config/handbrake.debug.log ] || mv /config/handbrake.debug.log /config/log/hb/handbrake.debug.log

# Clear the fstab file to make sure its content is not displayed in HandBrake
# when opening the source video.
echo > /etc/fstab

# Print the core dump info.
log "core dump file location: $(cat /proc/sys/kernel/core_pattern)"
log "core dump file size: $(ulimit -a | grep "core file size" | awk '{print $NF}') (blocks)"

# Take ownership of the config directory content.
find /config -mindepth 1 -exec chown $USER_ID:$GROUP_ID {} \;

# Take ownership of the output directory.
if ! chown $USER_ID:$GROUP_ID /output; then
    # Failed to take ownership of /output.  This could happen when,
    # for example, the folder is mapped to a network share.
    # Continue if we have write permission, else fail.
    if s6-setuidgid $USER_ID:$GROUP_ID [ ! -w /output ]; then
        log "ERROR: Failed to take ownership and no write permission on /output."
        exit 1
    fi
fi

# vim: set ft=sh :
