#!/bin/sh
#
# Find and report issues with detected optical drives that would prevent them
# to be used by HandBrake.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

permissions_ok() {
    DEV_UID="$(stat -c "%u" "$1")"
    DEV_GID="$(stat -c "%g" "$1")"

    DEV_PERM="$(stat -c "%a" "$1")"
    DEV_PERM_U="$(echo "$DEV_PERM" | head -c 1 | tail -c 1)"
    DEV_PERM_G="$(echo "$DEV_PERM" | head -c 2 | tail -c 1)"
    DEV_PERM_O="$(echo "$DEV_PERM" | head -c 3 | tail -c 1)"

    # NOTE: Write access to the device *is* required.

    # OK: User permission of the device is R/W and the container runs as root.
    [ "$DEV_PERM_U" -ge 6 ] && [ "$USER_ID" = "0" ] && return 0

    # OK: User permission of the device is R/W and user matches the container
    #     user.
    [ "$DEV_PERM_U" -ge 6 ] && [ "$DEV_UID" = "$USER_ID" ] && return 0

    # OK: The group permission of the device is R/W and group maches the
    #     container group.
    [ "$DEV_PERM_G" -ge 6 ] && [ "$DEV_GID" = "$GROUP_ID" ] && return 0

    # OK: The group permission of the device is R/W and group is not root,
    #     meaning that a supplementary group can be automatically added.
    [ "$DEV_PERM_G" -ge 6 ] && [ "$DEV_GID" != "0" ] && return 0

    # OK: The other permission of the device is R/W.
    [ "$DEV_PERM_O" -ge 6 ] && return 0

    return 1
}

write_access_test() {
    [ -e "$1" ] || return 1
    output="$(2>&1 >> "$1")"
    rc=$?
    if [ $rc -ne 0 ]; then
        if ! echo "$output" | grep -iq "permission denied"; then
            # We just want error related to the lack of write permission.
            rc=0
        fi
    fi
    return $rc
}

using_initial_user_namespace() {
    [ "$(cat /proc/self/uid_map | xargs)" = "0 0 4294967295" ]
}

echo "looking for usable optical drives..."

USABLE_DRIVES_FOUND="$(mktemp)"
echo 0 > "$USABLE_DRIVES_FOUND"

lsscsi | grep -w "cd/dvd" | awk '{print $1}' | tr -d '[]' | while read -r DRV_ID
do
    DRV="$(lsscsi -b -k "$DRV_ID" | tr -s ' ' | xargs)"
    DRV_NAME="$(lsscsi -c "$DRV_ID" | grep Vendor: | sed -r 's/(Vendor:|Model:|Rev:)//g' | tr -s ' ' | xargs)"

    SR_DEV="$(echo "$DRV" | awk '{print $2}')"

    echo "found optical drive '$DRV_NAME' [$SR_DEV]"
    if [ "$SR_DEV" = "-" ]; then
        echo "  [ ERR  ] no associated SCSI CD-ROM (sr) device detected."
    else
        echo "  [ OK ]   associated SCSI CD-ROM (sr) device detected: $SR_DEV."
        if [ -e "$SR_DEV" ]; then
            echo "  [ OK ]   the host device $SR_DEV is exposed to the container."
            if permissions_ok "$SR_DEV"; then
                echo "  [ OK ]   the device $SR_DEV has proper permissions."
                is-bool-val-false "${CONTAINER_DEBUG:-0}" || echo "           permissions: $(ls -l "$SR_DEV" | awk '{print $1,$3,$4}')"
                if write_access_test "$SR_DEV"; then
                    echo 1 > "$USABLE_DRIVES_FOUND"
                    echo "  [ OK ]   the container can write to device $SR_DEV."
                else
                    echo "  [ ERR ]  the container cannot write to device $SR_DEV."
                    using_initial_user_namespace || echo "           problem might be caused by improper user namespace configuration."
                fi
            else
                echo "  [ ERR ]  the device $SR_DEV does not have proper permissions."
                is-bool-val-false "${CONTAINER_DEBUG:-0}" || echo "           permissions: $(ls -l "$SR_DEV" | awk '{print $1,$3,$4}')"
            fi
        else
            echo "  [ ERR ]  the host device $SR_DEV is not exposed to the container."
        fi
    fi
done

if [ "$(cat "$USABLE_DRIVES_FOUND")" -eq 0 ]; then
    echo "no usable optical drives found."
fi
rm "$USABLE_DRIVES_FOUND"

# vim:ft=sh:ts=4:sw=4:et:sts=4
