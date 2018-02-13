#
# handbrake Dockerfile
#
# https://github.com/jlesage/docker-handbrake
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.6-v3.3.2

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
        jansson-dev \
        libtheora-dev \
        x264-dev \
        lame-dev \
        opus-dev \
        ffmpeg-dev \
        x265-dev \
        libbluray-dev \
        libvpx-dev \
        libsamplerate-dev \
        libass-dev \
        libvorbis-dev \
        libogg-dev \
        linux-headers \
        intltool \
        # gtk
        gtk+3.0-dev \
        dbus-glib-dev \
        libnotify-dev \
        libgudev-dev \
        gstreamer0.10-dev \
        && \
    # Download sources.
    mkdir HandBrake && \
    curl -# -L ${HANDBRAKE_URL} | tar xj --strip 1 -C HandBrake && \
    # Apply patches from https://git.alpinelinux.org/cgit/aports/tree/testing/handbrake?h=master
    wget https://git.alpinelinux.org/cgit/aports/plain/testing/handbrake/handbrake-9999-fix-missing-x265-link-flag.patch && \
    wget https://git.alpinelinux.org/cgit/aports/plain/testing/handbrake/handbrake-9999-remove-dvdnav-dup.patch && \
    patch -d HandBrake -p0 < handbrake-9999-fix-missing-x265-link-flag.patch && \
    patch -d HandBrake -p0 < handbrake-9999-remove-dvdnav-dup.patch && \
    # Use external libraries, except for libdvdread and libdvdnav.
    sed-patch -E '/.*contrib\/.*/{/libdvdread|libdvdnav/!d;}' HandBrake/make/include/main.defs && \
    # Compile.
    cd HandBrake && \
    ./configure --prefix=/usr \
                --disable-gtk-update-checks \
                --launch-jobs=$(nproc) \
                --launch \
                && \
    make --directory=build install && \
    cd .. && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

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
        libbluray \
        x265 \
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
        findutils \
        expect


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
