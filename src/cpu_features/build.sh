#!/bin/sh

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

CPU_FEATURES_URL="${1:-}"

if [ -z "$CPU_FEATURES_URL" ]; then
    log "ERROR: URL missing."
    exit 1
fi

#
# Install required packages.
#
apk --no-cache add \
    curl \
    clang15 \
    make \
    cmake \

#    binutils \
#    git \
#    llvm15 \
#    pkgconf \
#    autoconf \
#    automake \
#    libtool \
#    yasm \
#    m4 \
#    patch \
#    coreutils \
#    tar \
#    file \
#    pythonispython3 \
#    intltool \
#    diffutils \
#    bash \
#    nasm \
#    meson \
#    cargo \
#    cargo-c \
#    gettext-dev \
#    glib-dev \

xx-apk --no-cache --no-scripts add \
    musl-dev \
    gcc \

#    g++ \
#    linux-headers \

#
# Download sources.
#

#log "Downloading x264 sources..."
#mkdir /tmp/x264
#curl -# -L -f ${X264_URL} | tar xz --strip 1 -C /tmp/x264

log "Downloading cpu_features sources..."
mkdir /tmp/cpu_features
curl -# -L -f ${CPU_FEATURES_URL} | tar xz --strip 1 -C /tmp/cpu_features

#
# Compile cpu_features.
#

log "Configuring cpu_features..."
(
    mkdir /tmp/cpu_features/build && \
    cd /tmp/cpu_features/build && cmake \
        $(xx-clang --print-cmake-defines) \
        -DCMAKE_FIND_ROOT_PATH=$(xx-info sysroot) \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_INSTALL_PREFIX=/tmp/cpu_features-install \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTING=OFF \
        -DENABLE_INSTALL=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_EXECUTABLE=ON \
        ../
)

log "Compiling cpu_features..."
make -C /tmp/cpu_features/build  -j$(nproc)

log "Installing cpu_features..."
make -C /tmp/cpu_features/build install
