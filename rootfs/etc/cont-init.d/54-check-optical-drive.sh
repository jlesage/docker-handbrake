#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

FOUND_USABLE_DRIVE=0

echo "looking for usable optical drives..."

DRIVES_INFO="$(mktemp)"
lsscsi -g -k | grep -w "cd/dvd" | tr -s ' ' > "$DRIVES_INFO"

while read -r DRV; do
    DRV_DEV="$(echo "$DRV" | rev | sed -e 's/^[ \t]*//' | cut -d' ' -f2 | rev)"

    if [ -e "$DRV_DEV" ]; then
        FOUND_USABLE_DRIVE=1
        DRV_GRP="$(stat -c "%g" "$DRV_DEV")"
        echo "found optical drive $DRV_DEV, group $DRV_GRP."
    else
        echo "found optical drive $DRV_DEV, but it is not usable because is not exposed to the container."
    fi
done < "$DRIVES_INFO"
rm "$DRIVES_INFO"

if [ "$FOUND_USABLE_DRIVE" -eq 0 ]; then
    echo "no usable optical drive found."
fi

# vim:ts=4:sw=4:et:sts=4
