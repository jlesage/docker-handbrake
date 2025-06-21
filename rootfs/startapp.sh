#!/bin/sh

export HOME=/config
export GTK_A11Y=none
export LIBGL_ALWAYS_SOFTWARE=true

# Added to avoid the following error message:
#   MESA-LOADER: failed to open swrast: Error loading shared library
#   /usr/lib/xorg/modules/dri/swrast_dri.so: No such file or directory
#   (search paths /usr/lib/xorg/modules/dri, suffix _dri)
# We could instead install `mesa-dri-gallium`, but this increases the image
# size a lot.
export GDK_GL=disable

COMMON_ARGS="--config /config"

case "$(echo "${HANDBRAKE_GUI_QUEUE_STARTUP_ACTION:-NONE}" | tr '[:upper:]' '[:lower:]')" in
    process) COMMON_ARGS="$COMMON_ARGS --auto-start-queue" ;;
    clear) COMMON_ARGS="$COMMON_ARGS --clear-queue" ;;
esac

cd /storage
if [ "${HANDBRAKE_DEBUG:-0}" -eq 1 ]; then
  exec /usr/bin/ghb $COMMON_ARGS --debug >> /config/log/hb/handbrake.debug.log
else
  exec /usr/bin/ghb $COMMON_ARGS
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4
