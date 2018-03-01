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

# Other build arguments.

# Set to 'max' to keep debug symbols.
ARG HANDBRAKE_DEBUG_MODE=none

# Define working directory.
WORKDIR /tmp

# Compile HandBrake
RUN \
    add-pkg --virtual build-dependencies \
        # build tools.
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
        linux-headers \
        intltool \
        git \
        # misc libraries
        jansson-dev \
        libxml2-dev \
        # media libraries
        libsamplerate-dev \
        libass-dev \
        # media codecs
        libtheora-dev \
        x264-dev \
        lame-dev \
        opus-dev \
        libvorbis-dev \
        # gtk
        gtk+3.0-dev \
        dbus-glib-dev \
        libnotify-dev \
        libgudev-dev \
        && \
    # Download sources.
    if echo "${HANDBRAKE_URL}" | grep -q '\.git$'; then \
        git clone ${HANDBRAKE_URL} HandBrake && \
        git -C HandBrake checkout "${HANDBRAKE_VERSION}"; \
    else \
        mkdir HandBrake && \
        curl -# -L ${HANDBRAKE_URL} | tar xj --strip 1 -C HandBrake; \
    fi && \
    # Download the patch that fixes flac encoder crash.
    curl -# -L -o HandBrake/contrib/ffmpeg/A20-flac-encoder-crash.patch https://raw.githubusercontent.com/jlesage/docker-handbrake/master/A20-flac-encoder-crash.patch && \
    # Compile.
    cd HandBrake && \
    ./configure --prefix=/usr \
                --debug=$HANDBRAKE_DEBUG_MODE \
                --disable-gtk-update-checks \
                --enable-fdk-aac \
                --enable-x265 \
                --launch-jobs=$(nproc) \
                --launch \
                && \
    make --directory=build install && \
    if [ "${HANDBRAKE_DEBUG_MODE}" = "none" ]; then \
        strip /usr/bin/ghb \
              /usr/bin/HandBrakeCLI; \
    fi && \
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
        libsamplerate \
        libass \
        jansson \
        # Media codecs:
        libtheora \
        x264-libs \
        lame \
        opus \
        libvorbis \
        # To read encrypted DVDs
        libdvdcss \
        # For main, big icons:
        librsvg \
        # For all other small icons:
        adwaita-icon-theme \
        # For optical drive listing:
        lsscsi \
        # For watchfolder
        findutils \
        expect

# Adjust the openbox config.
RUN \
    # Maximize only the main/initial window.
    sed-patch 's/<application type="normal">/<application type="normal" title="HandBrake">/' \
        /etc/xdg/openbox/rc.xml && \
    # Make sure the main window is always in the background.
    sed-patch '/<application type="normal" title="HandBrake">/a \    <layer>below</layer>' \
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
