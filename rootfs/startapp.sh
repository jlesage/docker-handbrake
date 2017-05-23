#!/bin/sh
COMMON_ARGS="--config /config"

if [ "$HANDBRAKE_DEBUG" -eq 1 ]; then
  exec /usr/bin/ghb $COMMON_ARGS --debug >> /config/handbrake.debug.log
else
  exec /usr/bin/ghb $COMMON_ARGS
fi
