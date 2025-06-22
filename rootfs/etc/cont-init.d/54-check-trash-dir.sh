#!/bin/sh
#
# Make sure the trash directory is properly mapped to the host.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

if is-bool-val-true "${AUTOMATED_CONVERSION_USE_TRASH:-0}"; then
    for i in $(seq 1 ${AUTOMATED_CONVERSION_MAX_WATCH_FOLDERS:-5}); do
        if [ "$i" -eq 1 ]; then
            TRASH_DIR="${AUTOMATED_CONVERSION_TRASH_DIR:-/trash}"
        else
            eval "TRASH_DIR=\"\${AUTOMATED_CONVERSION_TRASH_DIR_${i}:-}\""
        fi
        [ -n "$TRASH_DIR" ] || continue

        if [ -f "$TRASH_DIR"/.not_mapped ]; then
            echo "ERROR: Trash usage is enabled, but trash directory '$TRASH_DIR' is not mapped to the host."
            exit 1
        fi

        if [ ! -d "$TRASH_DIR" ]; then
            echo "ERROR: Trash usage is enabled, but trash directory '$TRASH_DIR' is not found."
            exit 1
        fi

        set +e
        TMPFILE="$(su-exec "$USER_ID:$GROUP_ID" mktemp "$TRASH_DIR"/.test_XXXXXX)"
        RC=$?
        set -e
        if [ $RC -eq 0 ]; then
            # Success, we were able to write a file.
            su-exec "$USER_ID:$GROUP_ID" rm "$TMPFILE"
        else
            echo "ERROR: Trash usage is enabled, but trash directory '$TRASH_DIR' is not writable."
            exit 1
        fi
    done
fi

# vim:ts=4:sw=4:et:sts=4
