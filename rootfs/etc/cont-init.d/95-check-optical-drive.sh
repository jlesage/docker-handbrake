#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

log() {
    echo "[cont-init.d] $(basename $0): $*"
}

log "looking for usable optical drives..."

DRIVES_INFO="$(mktemp)"
lsscsi -g -k | grep -w "cd/dvd" | tr -s ' ' > "$DRIVES_INFO"

while read -r DRV; do
    DRV_DEV="$(echo "$DRV" | rev | sed -e 's/^[ \t]*//' | cut -d' ' -f2 | rev)"

    if [ -e "$DRV_DEV" ]; then
        # Save the associated group.
        DRV_GRP="$(stat -c "%g" "$DRV_DEV")"
        log "found optical drive $DRV_DEV, group $DRV_GRP."
        GRPS="${GRPS:- } $DRV_GRP"
    else
        log "found optical drive $DRV_DEV, but it is not usable because is not exposed to the container."
    fi
done < "$DRIVES_INFO"
rm "$DRIVES_INFO"

if [ "${DRV_GRP:-UNSET}" = "UNSET" ]; then
    log "no usable optical drive found."
else
    # Save as comma separated list of supplementary group IDs.
    if [ -f /var/run/s6/container_environment/SUP_GROUP_IDS ]; then
        echo -n "," >> /var/run/s6/container_environment/SUP_GROUP_IDS
    fi
    echo "$GRPS" | tr ' ' '\n' | grep -v '^$' | sort -nub | tr '\n' ',' | sed 's/.$//' >> /var/run/s6/container_environment/SUP_GROUP_IDS
fi

# vim: set ft=sh :
