#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Generate machine id.
if [ ! -f /config/machine-id ]; then
    echo "generating machine-id..."
    cat /proc/sys/kernel/random/uuid | tr -d '-' > /config/machine-id
fi

# Make sure mandatory directories exist.
mkdir -p /config/ghb
mkdir -p /config/hooks
mkdir -p /config/log/hb
ln -sf ghb /config/.ghb

# Copy default configuration if needed.
if [ ! -f /config/ghb/preferences.json ]; then
  cp /defaults/preferences.json /config/ghb/preferences.json
fi

# Copy example hooks if needed.
for hook in pre_conversion.sh post_conversion.sh post_watch_folder_processing.sh hb_custom_args.sh
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
echo "core dump file location: $(cat /proc/sys/kernel/core_pattern)"
echo "core dump file size: $(ulimit -a | grep "core file size" | awk '{print $NF}') (blocks)"

# Take ownership of the output directory.
for i in $(seq 1 ${AUTOMATED_CONVERSION_MAX_WATCH_FOLDERS:-5}); do
    eval "DIR=\"\${AUTOMATED_CONVERSION_OUTPUT_DIR_$i:-/output}\""

    if [ ! -d "$DIR" ]; then
        log "ERROR: Output folder '$DIR' doesn't exist."
        exit 1
    fi
    take-ownership --not-recursive --skip-if-writable "$DIR"
done

# vim:ts=4:sw=4:et:sts=4
