#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

DRI_DIR="/dev/dri"
DRI_DEV="$DRI_DIR/renderD128"
PROCESSOR_NAME="$(cat /proc/cpuinfo | grep "model name" | head -n1 | cut -d':' -f2 | xargs)"

echo "Processor: $PROCESSOR_NAME"

if ! echo "$PROCESSOR_NAME" | grep -qiwE "(INTEL|KVM|QEMU)"; then
    echo "Intel Quick Sync Video not supported: not a supported processor."
    exit 0
fi

if [ ! -d "$DRI_DIR" ]; then
    echo "Intel Quick Sync Video not supported: device directory $DRI_DIR not exposed to the container."
    exit 0
fi

if [ ! -e "$DRI_DEV" ]; then
    echo "Intel Quick Sync Video not supported: device $DRI_DEV not found."
    exit 0
fi

if ! lspci -k | grep -qw i915; then
    echo "Intel Quick Sync Video not supported: video adapter not using i915 driver."
    exit 0
fi

# Get group of devices under /dev/dri/.
find /dev/dri/ -type c | while read DRI_DEV
do
    G="$(stat -c "%g" "$DRI_DEV")"
    if [ "$G" -eq 0 ]; then
        # Device is owned by root.  If the configured user doesn't have access
        # to it, then QSV won't work (setting the supplementary group to 0
        # doesn't work).
        if ! (su-exec "$USER_ID:$GROUP_ID" test -r "$DRI_DEV") || \
           ! (su-exec "$USER_ID:$GROUP_ID" test -w "$DRI_DEV")
        then
            echo "Intel Quick Sync Video not supported: device $DRI_DEV owned "
                 "by group 'root' and configured user doesn't have permissions. "
                 "to access it."
            break
        fi
    fi
done

# vim:ts=4:sw=4:et:sts=4
