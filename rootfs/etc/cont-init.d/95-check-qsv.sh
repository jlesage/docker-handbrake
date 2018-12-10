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
if [ "$DRI_GRP" -ne 0 ]; then
    log "Device $DRI_DEV group is $DRI_GRP."
    if [ -f /var/run/s6/container_environment/SUP_GROUP_IDS ]; then
        echo -n "," >> /var/run/s6/container_environment/SUP_GROUP_IDS
    fi
    echo -n "$DRI_GRP" >> /var/run/s6/container_environment/SUP_GROUP_IDS
else
    find /dev/dri/ -type c | while read DRI_DEV
    do
        if ! (s6-applyuidgid -u $USER_ID -g $GROUP_ID -G ${SUP_GROUP_IDS:-$GROUP_ID} test -r "$DRI_DEV") || \
           ! (s6-applyuidgid -u $USER_ID -g $GROUP_ID -G ${SUP_GROUP_IDS:-$GROUP_ID} test -w "$DRI_DEV")
        then
            log "Intel Quick Sync Video not supported: device $DRI_DEV owned by group 'root'."
            exit 0
        fi
    done
fi

# Save the livba driver to use.
# By default, use the new Intel Media driver (iHD).  If the CPU is not
# supported, use the Intel VAAPI driver (i965).
#
# According to https://github.com/intel/media-driver#supported-platforms, the
# following CPUs are not supported by the Intel Media driver:
#   - Sandy Bridge
#   - Ivy Bridge
#   - Haswell
#
# Family/model numbers taken from:
#   https://a4lg.com/tech/x86/database/x86-families-and-models.en.html
LIBVA_DRIVER_NAME=iHD

CPU_FAMILY="$(cat /proc/cpuinfo | grep "cpu family" | head -n1 | awk '{print $4}')"
CPU_MODEL="$(printf '%x\n' "$(cat /proc/cpuinfo | grep "model" | grep -v "model name" | head -n1 | awk '{print $3}')")"

if [ "$CPU_FAMILY" = "6" ]; then
    case "$CPU_MODEL" in
        # Sandy Bridge
        2a|2d) LIBVA_DRIVER_NAME=i965 ;;
        # Ivy Bridge
        3a|3e) LIBVA_DRIVER_NAME=i965 ;;
        # Haswell
        3c|3f|45|46) LIBVA_DRIVER_NAME=i965 ;;
    esac
fi

echo -n "$LIBVA_DRIVER_NAME" > /var/run/s6/container_environment/LIBVA_DRIVER_NAME

# vim:ts=4:sw=4:et:sts=4
