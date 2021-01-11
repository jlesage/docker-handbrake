#
# handbrake Dockerfile
#
# https://github.com/jlesage/docker-handbrake
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.12-v3.5.6

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define software versions.
# NOTE: x264 version 20171224 is the most recent one that doesn't crash.
ARG HANDBRAKE_VERSION=1.3.3
ARG X264_VERSION=20171224
ARG LIBVA_VERSION=2.10.0
ARG INTEL_VAAPI_DRIVER_VERSION=2.4.1
ARG GMMLIB_VERSION=20.4.1
ARG INTEL_MEDIA_DRIVER_VERSION=20.4.5
ARG INTEL_MEDIA_SDK_VERSION=20.5.1
ARG YAD_VERSION=7.3

# Define software download URLs.
ARG HANDBRAKE_URL=https://github.com/HandBrake/HandBrake/releases/download/${HANDBRAKE_VERSION}/HandBrake-${HANDBRAKE_VERSION}-source.tar.bz2
ARG X264_URL=https://download.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-${X264_VERSION}-2245-stable.tar.bz2
ARG LIBVA_URL=https://github.com/intel/libva/releases/download/${LIBVA_VERSION}/libva-${LIBVA_VERSION}.tar.bz2
ARG INTEL_VAAPI_DRIVER_URL=https://github.com/intel/intel-vaapi-driver/releases/download/${INTEL_VAAPI_DRIVER_VERSION}/intel-vaapi-driver-${INTEL_VAAPI_DRIVER_VERSION}.tar.bz2
ARG GMMLIB_URL=https://github.com/intel/gmmlib/archive/intel-gmmlib-${GMMLIB_VERSION}.tar.gz
ARG INTEL_MEDIA_DRIVER_URL=https://github.com/intel/media-driver/archive/intel-media-${INTEL_MEDIA_DRIVER_VERSION}.tar.gz
ARG INTEL_MEDIA_SDK_URL=https://github.com/Intel-Media-SDK/MediaSDK/archive/intel-mediasdk-${INTEL_MEDIA_SDK_VERSION}.tar.gz
ARG YAD_URL=https://github.com/v1cont/yad/releases/download/v${YAD_VERSION}/yad-${YAD_VERSION}.tar.xz

# Other build arguments.

# Set to 'max' to keep debug symbols.
ARG HANDBRAKE_DEBUG_MODE=none

# Define working directory.
WORKDIR /tmp

# Compile HandBrake, libva and Intel Media SDK.
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
        python2 \
        linux-headers \
        intltool \
        git \
        diffutils \
        bash \
        nasm \
        meson \
        # misc libraries
        jansson-dev \
        libxml2-dev \
        libpciaccess-dev \
        xz-dev \
        numactl-dev \
        # media libraries
        libsamplerate-dev \
        libass-dev \
        # media codecs
        libtheora-dev \
        lame-dev \
        opus-dev \
        libvorbis-dev \
        speex-dev \
        libvpx-dev \
        # gtk
        gtk+3.0-dev \
        dbus-glib-dev \
        libnotify-dev \
        libgudev-dev \
        && \
    # Set same default compilation flags as abuild.
    export CFLAGS="-Os -fomit-frame-pointer" && \
    export CXXFLAGS="$CFLAGS" && \
    export CPPFLAGS="$CFLAGS" && \
    export LDFLAGS="-Wl,--as-needed" && \
    # Download x264 sources.
    echo "Downloading x264 sources..." && \
    mkdir x264 && \
    curl -# -L ${X264_URL} | tar xj --strip 1 -C x264 && \
    # Download libva sources.
    echo "Downloading libva sources..." && \
    mkdir libva && \
    curl -# -L ${LIBVA_URL} | tar xj --strip 1 -C libva && \
    # Download Intel VAAPI driver sources.
    echo "Downloading Intel VAAPI driver sources..." && \
    mkdir intel-vaapi-driver && \
    curl -# -L ${INTEL_VAAPI_DRIVER_URL} | tar xj --strip 1 -C intel-vaapi-driver && \
    # Download gmmlib sources.
    echo "Downloading gmmlib sources..." && \
    mkdir gmmlib && \
    curl -# -L ${GMMLIB_URL} | tar xz --strip 1 -C gmmlib && \
    # Download Intel Media driver.
    echo "Downloading Intel Media driver sources..." && \
    mkdir intel-media-driver && \
    curl -# -L ${INTEL_MEDIA_DRIVER_URL} | tar xz --strip 1 -C intel-media-driver && \
    # Download Intel Media SDK sources.
    echo "Downloading Intel Media SDK sources..." && \
    mkdir MediaSDK && \
    curl -# -L ${INTEL_MEDIA_SDK_URL} | tar xz --strip 1 -C MediaSDK && \
    # Download HandBrake sources.
    echo "Downloading HandBrake sources..." && \
    if echo "${HANDBRAKE_URL}" | grep -q '\.git$'; then \
        git clone ${HANDBRAKE_URL} HandBrake && \
        git -C HandBrake checkout "${HANDBRAKE_VERSION}"; \
    else \
        mkdir HandBrake && \
        curl -# -L ${HANDBRAKE_URL} | tar xj --strip 1 -C HandBrake; \
    fi && \
    # Download helper.
    echo "Downloading helpers..." && \
    curl -# -L -o /tmp/run_cmd https://raw.githubusercontent.com/jlesage/docker-mgmt-tools/master/run_cmd && \
    chmod +x /tmp/run_cmd && \
    # Download patches.
    echo "Downloading patches..." && \
    curl -# -L -o MediaSDK/intel-media-sdk-debug-no-assert.patch https://raw.githubusercontent.com/jlesage/docker-handbrake/master/intel-media-sdk-debug-no-assert.patch && \
    curl -# -L -o intel-media-driver/media-driver-c-assert-fix.patch https://raw.githubusercontent.com/jlesage/docker-handbrake/master/media-driver-c-assert-fix.patch && \
    # Compile x264.
    echo "Compiling x264..." && \
    cd x264 && \
    if [ "${HANDBRAKE_DEBUG_MODE}" = "none" ]; then \
        X264_CMAKE_OPTS=--enable-strip; \
    else \
        X264_CMAKE_OPTS=--enable-debug; \
    fi && \
    ./configure \
        --prefix=/usr \
        --enable-shared \
        --enable-pic \
        --disable-cli \
        $X264_CMAKE_OPTS \
        && \
    make -j$(nproc) install && \
    cd ../ && \
    # Compile libva.
    echo "Compiling libva..." && \
    cd libva && \
    ./configure \
        --prefix=/usr \
        --mandir=/tmp/libva-man \
        --infodir=/tmp/liva-info \
        --localstatedir=/var \
        --enable-x11 \
        --disable-glx \
        --disable-wayland \
        --disable-static \
        --enable-shared \
        --with-drivers-path=/opt/intel/mediasdk/lib64 \
        && \
    make -j$(nproc) && \
    make install && \
    cd ../ && \
    # Compile Intel VAAPI driver.
    echo "Compiling Intel VAAPI driver..." && \
    cd intel-vaapi-driver && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    # Compile Intel Media driver.
    echo "Compiling Intel Media driver..." && \
    add-pkg libexecinfo-dev && \
    cd intel-media-driver && \
    patch -p1 < media-driver-c-assert-fix.patch && \
    mkdir build && cd build && \
    cmake \
        -Wno-dev \
        -DBUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/opt/intel/mediasdk \
        -DLIBVA_DRIVERS_PATH=/opt/intel/mediasdk/lib64 \
        -DINSTALL_DRIVER_SYSCONF=OFF \
        -DMEDIA_RUN_TEST_SUITE=OFF \
        ../ && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    cd .. && \
    # Compile Intel Media SDK.
    echo "Compiling Intel Media SDK..." && \
    cd MediaSDK && \
    patch -p1 < intel-media-sdk-debug-no-assert.patch && \
    mkdir build && \
    cd build && \
    if [ "${HANDBRAKE_DEBUG_MODE}" = "none" ]; then \
        INTEL_MEDIA_SDK_BUILD_TYPE=RELEASE; \
    else \
        INTEL_MEDIA_SDK_BUILD_TYPE=DEBUG; \
    fi && \
    cmake \
        -DCMAKE_BUILD_TYPE=$INTEL_MEDIA_SDK_BUILD_TYPE \
        # HandBrake's libmfx is looking at /opt/intel/mediasdk/plugins for MFX plugins.
        -DMFX_PLUGINS_DIR=/opt/intel/mediasdk/plugins \
        -DMFX_PLUGINS_CONF_DIR=/opt/intel/mediasdk/plugins \
        -DENABLE_OPENCL=OFF \
        -DENABLE_X11_DRI3=OFF \
        -DENABLE_WAYLAND=OFF \
        -DBUILD_DISPATCHER=ON \
        -DENABLE_ITT=OFF \
        -DENABLE_TEXTLOG=OFF \
        -DENABLE_STAT=OFF \
        -DBUILD_SAMPLES=OFF \
        .. && \
    make -j$(nproc) install && \
    cd .. && \
    cd .. && \
    # Compile HandBrake.
    echo "Compiling HandBrake..." && \
    cd HandBrake && \
    ./configure --prefix=/usr \
                --debug=$HANDBRAKE_DEBUG_MODE \
                --disable-gtk-update-checks \
                --enable-fdk-aac \
                --enable-x265 \
                --enable-qsv \
                --launch-jobs=$(nproc) \
                --launch \
                && \
    /tmp/run_cmd -i 600 -m "HandBrake still compiling..." make --directory=build install && \
    cd .. && \
    # Strip symbols.
    if [ "${HANDBRAKE_DEBUG_MODE}" = "none" ]; then \
        find /usr/lib -type f -name "libva*.so*" -exec strip -s {} ';'; \
        find /opt/intel/mediasdk -type f -name "*.so*" -exec strip -s {} ';'; \
        strip -s /usr/bin/ghb; \
        strip -s /usr/bin/HandBrakeCLI; \
    fi && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -r \
        /usr/lib/libva*.la \
        /opt/intel/mediasdk/include \
        /opt/intel/mediasdk/lib64/pkgconfig \
        /opt/intel/mediasdk/lib64/*.la \
        # HandBrake already include a statically-linked version of libmfx.
        /opt/intel/mediasdk/lib64/libmfx.* \
        /usr/lib/pkgconfig/libva*.pc \
        /usr/lib/pkgconfig/x264.pc \
        /usr/include \
        && \
    rm -rf /tmp/* /tmp/.[!.]*

# Install YAD.
# NOTE: YAD is compiled manually because the version on the Alpine repository
#       pulls too much dependencies.
RUN \
    # Install packages needed by the build.
    add-pkg --virtual build-dependencies \
        build-base \
        curl \
        intltool \
        gtk+3.0-dev \
        && \
    # Set same default compilation flags as abuild.
    export CFLAGS="-Os -fomit-frame-pointer" && \
    export CXXFLAGS="$CFLAGS" && \
    export CPPFLAGS="$CFLAGS" && \
    export LDFLAGS="-Wl,--as-needed" && \
    # Download.
    mkdir yad && \
    echo "Downloading YAD package..." && \
    curl -# -L ${YAD_URL} | tar xJ --strip 1  -C yad && \
    # Compile.
    cd yad && \
    ./configure \
        --prefix=/usr \
        --enable-standalone \
        --disable-icon-browser \
        --disable-html \
        --disable-pfd \
        && \
    make && make install && \
    strip /usr/bin/yad && \
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
        xz \
        numactl \
        # Media codecs:
        libtheora \
        lame \
        opus \
        libvorbis \
        speex \
        libvpx \
        # To read encrypted DVDs
        libdvdcss \
        # For main, big icons:
        librsvg \
        # For all other small icons:
        adwaita-icon-theme \
        # For optical drive listing:
        lsscsi \
        # For watchfolder
        bash \
        coreutils \
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
    AUTOMATED_CONVERSION_PRESET="General/Very Fast 1080p30" \
    AUTOMATED_CONVERSION_FORMAT="mp4"

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]
VOLUME ["/output"]
VOLUME ["/watch"]

# Expose ports
EXPOSE 5800
EXPOSE 5900

# Metadata.
LABEL \
      org.label-schema.name="handbrake" \
      org.label-schema.description="Docker container for HandBrake" \
      org.label-schema.version="$DOCKER_IMAGE_VERSION" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-handbrake" \
      org.label-schema.schema-version="1.0"
