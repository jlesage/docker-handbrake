#
# handbrake Dockerfile
#
# https://github.com/jlesage/docker-handbrake
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.6-v2.0.1

# Define working directory.
WORKDIR /tmp

# Install HandBrake
RUN \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    add-pkg \
        # For live preview:
        gst-libav1 \
        gst-plugins-good \
        # For main, big icons:
        librsvg \
        # For all other small icons:
        adwaita-icon-theme \
        handbrake \
        handbrake-gtk

# Maximize only the main/initial window.
RUN sed-patch 's/<application type="normal">/<application type="normal" title="HandBrake">/' \
    /etc/xdg/openbox/rc.xml

# Install dependencies.
RUN \
    add-pkg \
        # For watchfolder
        findutils

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/handbrake-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="HandBrake" \
    AUTOMATED_CONVERSION_PRESET="Very Fast 1080p30" \
    AUTOMATED_CONVERSION_FORMAT="mp4"

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]
VOLUME ["/output"]
VOLUME ["/watch"]

# Metadata.
LABEL \
      org.label-schema.name="handbrake" \
      org.label-schema.description="Docker container for HandBrake" \
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-handbrake" \
      org.label-schema.schema-version="1.0"
