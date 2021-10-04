#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

run() {
    j=1
    while eval "\${pipestatus_$j+:} false"; do
        unset pipestatus_$j
        j=$(($j+1))
    done
    j=1 com= k=1 l=
    for a; do
        if [ "x$a" = 'x|' ]; then
            com="$com { $l "'3>&-
                        echo "pipestatus_'$j'=$?" >&3
                      } 4>&- |'
            j=$(($j+1)) l=
        else
            l="$l \"\$$k\""
        fi
        k=$(($k+1))
    done
    com="$com $l"' 3>&- >&4 4>&-
               echo "pipestatus_'$j'=$?"'
    exec 4>&1
    eval "$(exec 3>&1; eval "$com")"
    exec 4>&-
    j=1
    while eval "\${pipestatus_$j+:} false"; do
        eval "[ \$pipestatus_$j -eq 0 ]" || return 1
        j=$(($j+1))
    done
    return 0
}

log() {
    if [ -n "${1-}" ]; then
        echo "[cont-init.d] $(basename $0): $*"
    else
        while read OUTPUT; do
            echo "[cont-init.d] $(basename $0): $OUTPUT"
        done
    fi
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
for hook in pre_conversion.sh post_conversion.sh post_watch_folder_processing.sh
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

# Install requested packages.
if [ "${AUTOMATED_CONVERSION_INSTALL_PKGS:-UNSET}" != "UNSET" ]; then
    log "installing requested package(s)..."
    for PKG in $AUTOMATED_CONVERSION_INSTALL_PKGS; do
        if cat /etc/apk/world | grep -wq "$PKG"; then
            log "package '$PKG' already installed"
        else
            log "installing '$PKG'..."
            run add-pkg "$PKG" 2>&1 \| log
        fi
    done
fi

# Print the core dump info.
log "core dump file location: $(cat /proc/sys/kernel/core_pattern)"
log "core dump file size: $(ulimit -a | grep "core file size" | awk '{print $NF}') (blocks)"

# Take ownership of the config directory content.
find /config -mindepth 1 -exec chown $USER_ID:$GROUP_ID {} \;

# Take ownership of the output directory.
for i in $(seq 1 ${AUTOMATED_CONVERSION_MAX_WATCH_FOLDERS:-5}); do
    eval "DIR=\"\${AUTOMATED_CONVERSION_OUTPUT_DIR_$i:-/output}\""

    if [ ! -d "$DIR" ]; then
        log "ERROR: Output folder '$DIR' doesn't exist."
        exit 1
    elif ! chown $USER_ID:$GROUP_ID "$DIR"; then
        # Failed to take ownership of /output.  This could happen when,
        # for example, the folder is mapped to a network share.
        # Continue if we have write permission, else fail.
        TMPFILE="$(s6-setuidgid $USER_ID:$GROUP_ID mktemp "$DIR"/.test_XXXXXX 2>/dev/null)"
        if [ $? -eq 0 ]; then
            # Success, we were able to write file.
            s6-setuidgid $USER_ID:$GROUP_ID rm "$TMPFILE"
        else
            log "ERROR: Failed to take ownership and no write permission on '$DIR'."
            exit 1
        fi
    fi
done

# vim: set ft=sh :
