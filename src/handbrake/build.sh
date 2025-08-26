#!/bin/sh
#
# Script to build HandBrake.
#
# Support for QSV requires multiple components:
#
# - libva: implementation for VA-API (Video Acceleration API), an open-source
#   library and API specification, which provides access to graphics hardware
#   acceleration capabilities for video processing.  It consists of a main
#   library and driver-specific acceleration backends for each supported
#   hardware vendor (aka drivers for libva).
#
# - Intel VAAPI driver
#   - Driver for libva.
#   - Used for older Intel generation CPUs.
#   - Provides `i965_drv_video.so` (under `/usr/lib/dri/`).
#
# - Intel Media Driver
#   - Driver for libva.
#   - Used for newer Intel generation CPUs.
#   - Provides `iHD_drv_video.so` (under `/usr/lib/dri/`).
#   - Depends on gmmlib.
#
# - Intel Media SDK
#   - High level library that provides API to access hardware-accelerated video
#     decode, encode and filtering on Intel graphics hardware platforms.
#   - Discontinued.
#   - Depends on libva.
#   - Provides `libmfx.so`, the dispatcher used to select the runtime
#     implementation to use (`libmfxhw64.so` or `libmfx-gen.so) depending on the
#     CPU.
#     - It is not used by HandBrake.
#     - HandBrake has an embedded version of the oneVPL dispatcher (libvpl.so),
#       statically linked.
#   - Provides `libmfxhw64.so`, a runtime implementation for older Intel CPUs.
#     It also includes its plugins (under `/usr/lib/mfx/`):
#     - `plugins/libmfx_hevce_hw64.so`
#     - `plugins/libmfx_hevc_fei_hw64.so`
#     - `plugins/libmfx_vp9e_hw64.so`
#     - `plugins/libmfx_h264la_hw64.so`
#     - `plugins/libmfx_hevcd_hw64.so`
#     - `plugins/libmfx_hevcd_hw64.so`
#     - `plugins/libmfx_vp8d_hw64.so`
#     - `plugins/libmfx_vp9d_hw64.so`
#
# - libvpl
#   - Implementation of the Intel oneAPI Video Processing Library (oneVPL).
#     oneVPL is the new name of Intel Media SDK.  It is the 2.x API continuation
#     of Intel Media SDK API.
#   - HandBrake has its embedded version of the oneVPL dispatcher (libvpl.so),
#     statically linked.
#     - The dispatcher supports runtime implementations from both the Media SDK
#       (`libmfxhw64.so`) and oneVPL (`libmfx-gen.so`).
#   - This library is not compiled by this script.
#
# - oneVPL GPU Runtime
#   - Provides `libmfx-gen.so` (under `/usr/lib/`), a runtime implementation
#     for latest Intel CPUs.
#   - Can be used by the Media SDK and oneVPL dispatchers.
#   - Successor of the Media SDK's runtime implementation.
#
# Some interesting links:
#   - https://trac.ffmpeg.org/wiki/Hardware/QuickSync
#

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Set same default compilation flags as abuild.
export CFLAGS="-fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"

export CC=xx-clang
export CXX=xx-clang++

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

function log {
    echo ">>> $*"
}

HANDBRAKE_VERSION="${1:-}"
HANDBRAKE_URL="${2:-}"
HANDBRAKE_DEBUG_MODE="${3:-}"
LIBVA_URL="${4:-}"
INTEL_VAAPI_DRIVER_URL="${5:-}"
GMMLIB_URL="${6:-}"
INTEL_MEDIA_DRIVER_URL="${7:-}"
INTEL_MEDIA_SDK_URL="${8:-}"
INTEL_ONEVPL_GPU_RUNTIME_URL="${9:-}"

if [ -z "$HANDBRAKE_VERSION" ]; then
    log "ERROR: HandBrake version missing."
    exit 1
fi

if [ -z "$HANDBRAKE_URL" ]; then
    log "ERROR: HandBrake URL missing."
    exit 1
fi

if [ -z "$HANDBRAKE_DEBUG_MODE" ]; then
    log "ERROR: HandBrake debug mode missing."
    exit 1
fi

#if [ -z "$X264_URL" ]; then
#    log "ERROR: x264 URL missing."
#    exit 1
#fi

if [ -z "$LIBVA_URL" ]; then
    log "ERROR: libva URL missing."
    exit 1
fi

if [ -z "$INTEL_VAAPI_DRIVER_URL" ]; then
    log "ERROR: Intel VAAPI driver URL missing."
    exit 1
fi

if [ -z "$GMMLIB_URL" ]; then
    log "ERROR: gmmlib URL missing."
    exit 1
fi

if [ -z "$INTEL_MEDIA_DRIVER_URL" ]; then
    log "ERROR: Intel Media driver URL missing."
    exit 1
fi

if [ -z "$INTEL_MEDIA_SDK_URL" ]; then
    log "ERROR: Intel Media SDK URL missing."
    exit 1
fi

if [ -z "$INTEL_ONEVPL_GPU_RUNTIME_URL" ]; then
    log "ERROR: Intel OneVPL GPU Runtime URL missing."
    exit 1
fi

#
# Install required packages.
#
apk --no-cache add \
    curl \
    binutils \
    git \
    clang17 \
    llvm17 \
    make \
    cmake \
    pkgconf \
    autoconf \
    automake \
    libtool \
    yasm \
    m4 \
    patch \
    coreutils \
    tar \
    file \
    pythonispython3 \
    intltool \
    diffutils \
    bash \
    nasm \
    meson \
    gettext-dev \
    glib-dev \

xx-apk --no-cache --no-scripts add \
    musl-dev \
    gcc \
    g++ \
    linux-headers \

# misc libraries
xx-apk --no-cache --no-scripts add \
    jansson-dev \
    libxml2-dev \
    libpciaccess-dev \
    xz-dev \
    numactl-dev \
    libjpeg-turbo-dev \

# media libraries
xx-apk --no-cache --no-scripts add \
    libsamplerate-dev \
    libass-dev \

# media codecs
xx-apk --no-cache --no-scripts add \
    x264-dev \
    libtheora-dev \
    lame-dev \
    opus-dev \
    libvorbis-dev \
    speex-dev \
    libvpx-dev \

# gtk
xx-apk --no-cache --no-scripts add \
    gtk4.0-dev \
    dbus-glib-dev \
    libnotify-dev \
    libgudev-dev \

# Install Rust.
USE_RUST_FROM_ALPINE_REPO=false
if $USE_RUST_FROM_ALPINE_REPO; then
    apk --no-cache add \
        cargo \
        cargo-c
else
    apk --no-cache add \
        gcc \
        musl-dev
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y
    source /root/.cargo/env

    # NOTE: When not installing Rust from the Alpine repository, we must compile
    #       with `RUSTFLAGS="-C target-feature=-crt-static"` to avoid crash
    #       during GTK initialization.
    #       See https://github.com/qarmin/czkawka/issues/416.
    export RUSTFLAGS="-C target-feature=-crt-static"

    # Install cargo-c
    apk --no-cache add \
        openssl-dev
    CC=clang CXX=clang++ cargo install cargo-c
fi

#
# Download sources.
#

#log "Downloading x264 sources..."
#mkdir /tmp/x264
#curl -# -L -f ${X264_URL} | tar xz --strip 1 -C /tmp/x264

log "Downloading libva sources..."
mkdir /tmp/libva
curl -# -L -f ${LIBVA_URL} | tar xj --strip 1 -C /tmp/libva

if [ "$(xx-info arch)" = "amd64" ]; then
    log "Downloading Intel VAAPI driver sources..."
    mkdir /tmp/intel-vaapi-driver
    curl -# -L -f ${INTEL_VAAPI_DRIVER_URL} | tar xj --strip 1 -C /tmp/intel-vaapi-driver

    log "Downloading gmmlib sources..."
    mkdir /tmp/gmmlib
    curl -# -L -f ${GMMLIB_URL} | tar xz --strip 1 -C /tmp/gmmlib

    log "Downloading Intel Media driver sources..."
    mkdir /tmp/intel-media-driver
    curl -# -L -f ${INTEL_MEDIA_DRIVER_URL} | tar xz --strip 1 -C /tmp/intel-media-driver

    log "Downloading Intel Media SDK sources..."
    mkdir /tmp/MediaSDK
    curl -# -L -f ${INTEL_MEDIA_SDK_URL} | tar xz --strip 1 -C /tmp/MediaSDK

    log "Downloading Intel OneVPL GPU Runtime sources..."
    mkdir /tmp/oneVPL-intel-gpu
    curl -# -L -f ${INTEL_ONEVPL_GPU_RUNTIME_URL} | tar xz --strip 1 -C /tmp/oneVPL-intel-gpu
fi

log "Downloading HandBrake sources..."
if echo "${HANDBRAKE_URL}" | grep -q '\.git$'; then
    # Sources from git for nightly builds.
    git clone ${HANDBRAKE_URL} /tmp/handbrake
    # HANDBRAKE_VERSION is in the format "nightly-<date>-<commit hash>".
    git -C /tmp/handbrake checkout "$(echo "${HANDBRAKE_VERSION}" | cut -d'-' -f3)"
else
    mkdir /tmp/handbrake
    curl -# -L -f ${HANDBRAKE_URL} | tar xj --strip 1 -C /tmp/handbrake
fi

#
# Compile HandBrake.
#

if [ "${HANDBRAKE_DEBUG_MODE}" = "none" ]; then
    CMAKE_BUILD_TYPE=Release
else
    CMAKE_BUILD_TYPE=Debug
    # Do not strip symbols.
    LDFLAGS=
fi

#log "Configuring x264..."
#if [ "${HANDBRAKE_DEBUG_MODE}" = "none" ]; then
#    X264_CMAKE_OPTS=--enable-strip
#else
#    X264_CMAKE_OPTS=--enable-debug
#fi
#(
#    cd /tmp/x264 && CFLAGS="${CFLAGS/-Os/}" ./configure \
#        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
#        --host=$(xx-clang --print-target-triple) \
#        --prefix=/usr \
#        --enable-shared \
#        --disable-static \
#        --enable-pic \
#        --disable-cli \
#        --extra-cflags=-fno-aggressive-loop-optimizations \
#        $X264_CMAKE_OPTS \
#)

#log "Compiling x264..."
#make -C /tmp/x264 -j$(nproc)
#
#log "Installing x264..."
#make -C /tmp/x264 install

log "Configuring libva..."
(
    cd /tmp/libva && ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
        --localstatedir=/var \
        --enable-x11 \
        --disable-glx \
        --disable-wayland \
        --disable-static \
        --enable-shared \
)

log "Compiling libva..."
make -C /tmp/libva -j$(nproc)

log "Installing libva..."
make -C /tmp/libva install
make DESTDIR=/tmp/handbrake-install -C /tmp/libva install

if [ "$(xx-info arch)" = "amd64" ]; then
    log "Configuring Intel VAAPI driver..."
    (
        cd /tmp/intel-vaapi-driver && ./configure \
            --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
            --host=$(xx-clang --print-target-triple) \
    )

    log "Compiling Intel VAAPI driver..."
    make -C /tmp/intel-vaapi-driver -j$(nproc)

    log "Installing Intel VAAPI driver..."
    make DESTDIR=/tmp/handbrake-install -C /tmp/intel-vaapi-driver install
fi

if [ "$(xx-info arch)" = "amd64" ]; then
    log "Patching Intel Media Driver..."
    patch -d /tmp/intel-media-driver -p1 < "$SCRIPT_DIR"/intel-media-driver-compile-fix.patch
    patch -d /tmp/gmmlib -p1 < "$SCRIPT_DIR"/gmmlib-compile-fix.patch
    rm -rf /tmp/gmmlib/ULT
    rm -rf /tmp/intel-media-driver/media_driver/*/ult

    log "Configuring Intel Media driver..."
    (
        mkdir /tmp/intel-media-driver/build && \
        cd /tmp/intel-media-driver/build && cmake -G Ninja \
            $(xx-clang --print-cmake-defines) \
            -DCMAKE_FIND_ROOT_PATH=$(xx-info sysroot) \
            -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
            -DCMAKE_INSTALL_PREFIX=/usr \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_VERBOSE_MAKEFILE=OFF \
            -Wno-dev \
            -DBUILD_TYPE=Release \
            -DBUILD_CMRTLIB=OFF \
            -DINSTALL_DRIVER_SYSCONF=OFF \
            -DMEDIA_RUN_TEST_SUITE=OFF \
            -DSKIP_GMM_CHECK=ON \
            ../
    )

    log "Compiling Intel Media driver..."
    cmake --build /tmp/intel-media-driver/build

    log "Installing Intel Media driver..."
    DESTDIR=/tmp/handbrake-install cmake --install /tmp/intel-media-driver/build
fi

if [ "$(xx-info arch)" = "amd64" ]; then
    if [ "${HANDBRAKE_DEBUG_MODE}" = "none" ]; then
        INTEL_MEDIA_SDK_BUILD_TYPE=RELEASE
    else \
        INTEL_MEDIA_SDK_BUILD_TYPE=DEBUG
    fi

    log "Patching Intel Media SDK..."
    patch -d /tmp/MediaSDK -p1 < "$SCRIPT_DIR"/intel-media-sdk-debug-no-assert.patch
    patch -d /tmp/MediaSDK -p1 < "$SCRIPT_DIR"/intel-media-sdk-compile-fix.patch

    log "Configuring Intel Media SDK..."
    (
        mkdir /tmp/MediaSDK/build && \
        cd /tmp/MediaSDK/build && cmake \
            $(xx-clang --print-cmake-defines) \
            -DCMAKE_FIND_ROOT_PATH=$(xx-info sysroot) \
            -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
            -DCMAKE_INSTALL_PREFIX=/usr \
            -DCMAKE_BUILD_TYPE=$INTEL_MEDIA_SDK_BUILD_TYPE \
            -DENABLE_OPENCL=OFF \
            -DENABLE_X11_DRI3=OFF \
            -DENABLE_WAYLAND=OFF \
            -DBUILD_DISPATCHER=ON \
            -DENABLE_ITT=OFF \
            -DENABLE_TEXTLOG=OFF \
            -DENABLE_STAT=OFF \
            -DBUILD_SAMPLES=OFF \
            ../
    )

    log "Compiling Intel Media SDK..."
    make -C /tmp/MediaSDK/build -j$(nproc)

    log "Installing Intel Media SDK..."
    make DESTDIR=/tmp/handbrake-install -C /tmp/MediaSDK/build install
fi

if [ "$(xx-info arch)" = "amd64" ]; then
    log "Configuring Intel oneVPL GPU Runtime..."
    (
        mkdir /tmp/oneVPL-intel-gpu/build && \
        cd /tmp/oneVPL-intel-gpu/build && cmake -G Ninja \
            $(xx-clang --print-cmake-defines) \
            -DCMAKE_FIND_ROOT_PATH=$(xx-info sysroot) \
            -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
            -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX=/usr \
            -DCMAKE_INSTALL_LIBDIR=lib \
            ../
    )

    log "Compiling Intel oneVPL GPU Runtime..."
    cmake --build /tmp/oneVPL-intel-gpu/build

    log "Installing Intel oneVPL GPU Runtime..."
    DESTDIR=/tmp/handbrake-install cmake --install /tmp/oneVPL-intel-gpu/build
fi

log "Patching HandBrake..."
if xx-info is-cross; then
    patch -d /tmp/handbrake -p1 < "$SCRIPT_DIR"/cross-compile-fix.patch
fi
patch -d /tmp/handbrake -p1 < "$SCRIPT_DIR"/maximized-window.patch

# Create the meson cross compile config file.
if xx-info is-cross; then
    cat << EOF > /tmp/handbrake/contrib/cross-config.meson
[binaries]
pkgconfig = '$(xx-info)-pkg-config'

[properties]
sys_root = '$(xx-info sysroot)'
pkg_config_libdir = '$(xx-info sysroot)/usr/lib/pkgconfig'

[host_machine]
system = 'linux'
cpu_family = '$(xx-info arch)'
cpu = '$(xx-info arch)'
endian = 'little'
EOF
fi

log "Configuring HandBrake..."
(
    if [ "$(xx-info arch)" = "amd64" ]; then
        CONF_FLAGS="--enable-qsv"
    else
        CONF_FLAGS="--disable-qsv --disable-nvenc"
    fi

    if xx-info is-cross; then
        CONF_FLAGS="$CONF_FLAGS --cross $(xx-info)"
    fi

    cd /tmp/handbrake && ./configure \
        --verbose \
        --prefix=/usr \
        --build=build \
        --debug=$HANDBRAKE_DEBUG_MODE \
        --enable-fdk-aac \
        --enable-x265 \
        --enable-libdovi \
        $CONF_FLAGS \
)

log "Compiling HandBrake..."
make -C /tmp/handbrake/build -j$(nproc)

log "Installing HandBrake..."
make DESTDIR=/tmp/handbrake-install -C /tmp/handbrake/build -j1 install
make DESTDIR=/tmp/handbrake-install -C /tmp/libva install

# Remove uneeded installed files.
if [ "$(xx-info arch)" = "amd64" ]; then
    rm -r \
        /tmp/handbrake-install/usr/include \
        /tmp/handbrake-install/usr/lib/*.la \
        /tmp/handbrake-install/usr/lib/libmfx.* \
        /tmp/handbrake-install/usr/lib/dri/*.la \
        /tmp/handbrake-install/usr/lib/pkgconfig \
        /tmp/handbrake-install/usr/share/metainfo \
        /tmp/handbrake-install/usr/share/applications \

fi

log "Handbrake install content:"
find /tmp/handbrake-install
