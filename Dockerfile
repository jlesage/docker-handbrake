#
# handbrake Dockerfile
#
# https://github.com/jlesage/docker-handbrake
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.6-v3.1.2

# Define software versions.
ARG HANDBRAKE_VERSION=1.0.7

# Define software download URLs.
ARG HANDBRAKE_URL=https://download.handbrake.fr/releases/${HANDBRAKE_VERSION}/HandBrake-${HANDBRAKE_VERSION}.tar.bz2

# Define working directory.
WORKDIR /tmp

# Compile HandBrake
RUN \
    add-pkg --virtual build-dependencies \
        curl \
        build-base \
        yasm \
        autoconf \
        cmake \
        automake \
        libtool \
        m4 \
        patch \
        coreutils \
        tar \
        file \
        python \
        libxml2-dev \
        jansson-dev \
        libtheora-dev \
        x264-dev \
        lame-dev \
        opus-dev \
        libsamplerate-dev \
        libass-dev \
        libvorbis-dev \
        libogg-dev \
        linux-headers \
        harfbuzz-dev \
        intltool \
        # gtk
        gtk+3.0-dev \
        dbus-glib-dev \
        libnotify-dev \
        libgudev-dev \
        gstreamer0.10-dev \
        && \
    # Download sources.
    curl -# -L ${HANDBRAKE_URL} | tar xj && \
    # Compile.
    cd HandBrake-${HANDBRAKE_VERSION} && \
    ./configure --prefix=/usr \
                --disable-gtk-update-checks \
                --enable-x265 \
                --enable-fdk-aac \
                && \
    cd build && \
    make && make install && \
    cd .. && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/*

# Install dependencies.
RUN \
    add-pkg \
        gtk+3.0 \
        libgudev \
        dbus-glib \
        libnotify \
        x264-libs \
        libsamplerate \
        libtheora \
        libvorbis \
        libass \
        jansson \
        opus \
        lame \
        # To read encrypted DVDs
        libdvdcss \
        # For live preview:
        gst-libav1 \
        # For main, big icons:
        librsvg \
        # For all other small icons:
        adwaita-icon-theme \
        # For optical drive listing:
        lsscsi \
        # For watchfolder
        findutils


# Maximize only the main/initial window.
RUN sed-patch 's/<application type="normal">/<application type="normal" title="HandBrake">/' \
    /etc/xdg/openbox/rc.xml

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
