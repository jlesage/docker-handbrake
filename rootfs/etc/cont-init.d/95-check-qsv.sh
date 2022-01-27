#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

log() {
    echo "[cont-init.d] $(basename $0): $*"
}

DRI_DIR="/dev/dri"
DRI_DEV="$DRI_DIR/renderD128"
PROCESSOR_NAME="$(cat /proc/cpuinfo | grep "model name" | head -n1 | cut -d':' -f2 | xargs)"

log "Processor: $PROCESSOR_NAME"

if ! echo "$PROCESSOR_NAME" | grep -qiw "INTEL"; then
    log "Intel Quick Sync Video not supported: not an Intel processor."
    exit 0
fi

if [ ! -d "$DRI_DIR" ]; then
    log "Intel Quick Sync Video not supported: device directory $DRI_DIR not exposed to the container."
    exit 0
fi

if [ ! -e "$DRI_DEV" ]; then
    log "Intel Quick Sync Video not supported: device $DRI_DEV not found."
    exit 0
fi

if ! lspci -s "00:02.0" -k | grep -q -w i915; then
    log "Intel Quick Sync Video not supported: video adapter not using i915 driver."
    exit 0
fi

# Get group of devices under /dev/dri/.
GRPS=$(mktemp)
find /dev/dri/ -type c | while read DRI_DEV
do
    G="$(stat -c "%g" "$DRI_DEV")"
    if [ "$G" -ne 0 ]; then
        echo "$G " >> "$GRPS"
    else
        # Device is owned by root.  If the configured user doesn't have access
        # to it, then QSV won't work (setting the supplementary group to 0
        # doesn't work).
        if ! (s6-applyuidgid -u $USER_ID -g $GROUP_ID -G ${SUP_GROUP_IDS:-$GROUP_ID} test -r "$DRI_DEV") || \
           ! (s6-applyuidgid -u $USER_ID -g $GROUP_ID -G ${SUP_GROUP_IDS:-$GROUP_ID} test -w "$DRI_DEV")
        then
            log "Intel Quick Sync Video not supported: device $DRI_DEV owned "
                "by group 'root' and configured user doesn't have permissions. "
                "to access it."
            rm "$GRPS"
            exit 0
        fi
    fi
done

# Save as comma separated list of supplementary group IDs.
if [ "$(cat "$GRPS")" != "" ]; then
    if [ -f /var/run/s6/container_environment/SUP_GROUP_IDS ]; then
        echo -n "," >> /var/run/s6/container_environment/SUP_GROUP_IDS
    fi
    cat "$GRPS" | tr ' ' '\n' | grep -v '^$' | sort -nub | tr '\n' ',' | sed 's/.$//' >> /var/run/s6/container_environment/SUP_GROUP_IDS
fi
rm "$GRPS"

# vim:ts=4:sw=4:et:sts=4
