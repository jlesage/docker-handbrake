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

if [ "$(lspci -k | grep "^00:02.0 " | cut -d' ' -f5)" != "i915" ]; then
    log "Intel Quick Sync Video not supported: video adapter not using i915 driver."
    exit 0
fi

# Save the associated group.
DRI_GRP="$(stat -c "%g" "$DRI_DEV")"
log "DRM device group $DRI_GRP."
if [ -f /var/run/s6/container_environment/SUP_GROUP_IDS ]; then
    echo -n "," >> /var/run/s6/container_environment/SUP_GROUP_IDS
fi
echo -n "$DRI_GRP" >> /var/run/s6/container_environment/SUP_GROUP_IDS

# vim: set ft=sh :
