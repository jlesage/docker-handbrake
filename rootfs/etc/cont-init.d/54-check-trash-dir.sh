#!/bin/sh
#
# Make sure the trash directory is properly mapped to the host.
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

if is-bool-val-true "${AUTOMATED_CONVERSION_USE_TRASH:-0}"; then
    if [ -f /trash/.not_mapped ]; then
        echo "ERROR: Trash usage is enabled, but trash directory not mapped to the host."
        exit 1
    fi

    set +e
    TMPFILE="$(su-exec "$USER_ID:$GROUP_ID" mktemp /trash/.test_XXXXXX)"
    RC=$?
    set -e
    if [ $RC -eq 0 ]; then
        # Success, we were able to write a file.
        su-exec "$USER_ID:$GROUP_ID" rm "$TMPFILE"
    else
        echo "ERROR: Trash usage is enabled, but no write permission on it."
        exit 1
    fi
fi

# vim:ts=4:sw=4:et:sts=4
