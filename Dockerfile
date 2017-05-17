#
# dupeguru Dockerfile
#
# https://github.com/jlesage/docker-handbrake
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.5-v1.3.1

# Define working directory.
WORKDIR /tmp

# Install HandBrake
RUN \
    echo "@edge-testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    echo "@edge-main http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    apk --no-cache add \
        libass@edge-main \
        x265@edge-main \
        ffmpeg-libs@edge-main \
        libbluray@edge-main \
        # For live preview:
        gst-libav1 \
        gst-plugins-good1 \
        # For main, big icons:
        librsvg \
        # For all other small icons:
        adwaita-icon-theme \
        handbrake@edge-testing \
        handbrake-gtk@edge-testing

# Maximize only the main/initial window.
RUN sed -i 's/<application type="normal">/<application type="normal" title="HandBrake">/' \
    $HOME/.config/openbox/rc.xml

# Install other dependencies.
RUN \
    apk --no-cache add inotify-tools

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/handbrake-icon.png && \
    /opt/install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="HandBrake" \
    AUTOMATED_CONVERSION_PRESET="Very Fast 1080p30" \
    AUTOMATED_CONVERSION_FORMAT="mp4"

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/output"]
VOLUME ["/watch"]

# Metadata.
LABEL \
      org.label-schema.name="handbrake" \
      org.label-schema.description="Docker container for HandBrake" \
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-handbrake" \
      org.label-schema.schema-version="1.0"
