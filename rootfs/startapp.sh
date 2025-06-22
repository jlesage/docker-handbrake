#!/bin/sh

export HOME=/config
export GTK_A11Y=none
export LIBGL_ALWAYS_SOFTWARE=true

COMMON_ARGS="--config /config"

case "$(echo "${HANDBRAKE_GUI_QUEUE_STARTUP_ACTION:-NONE}" | tr '[:upper:]' '[:lower:]')" in
    process) COMMON_ARGS="$COMMON_ARGS --auto-start-queue" ;;
    clear) COMMON_ARGS="$COMMON_ARGS --clear-queue" ;;
esac

cd /storage
if is-bool-val-true "${HANDBRAKE_DEBUG:-0}"; then
  exec /usr/bin/ghb $COMMON_ARGS --debug >> /config/log/hb/handbrake.debug.log
else
  exec /usr/bin/ghb $COMMON_ARGS
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4
