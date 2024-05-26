#
# handbrake Dockerfile
#
# https://github.com/jlesage/docker-handbrake
#

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=

# Define software versions.
ARG HANDBRAKE_VERSION=1.8.0
ARG LIBVA_VERSION=2.21.0
ARG INTEL_VAAPI_DRIVER_VERSION=2.4.1
ARG GMMLIB_VERSION=22.3.19
ARG INTEL_MEDIA_DRIVER_VERSION=24.1.5
ARG INTEL_MEDIA_SDK_VERSION=23.2.2
ARG INTEL_ONEVPL_GPU_RUNTIME_VERSION=24.1.5
ARG CPU_FEATURES_VERSION=0.9.0

# Define software download URLs.
ARG HANDBRAKE_URL=https://github.com/HandBrake/HandBrake/releases/download/${HANDBRAKE_VERSION}/HandBrake-${HANDBRAKE_VERSION}-source.tar.bz2
ARG LIBVA_URL=https://github.com/intel/libva/releases/download/${LIBVA_VERSION}/libva-${LIBVA_VERSION}.tar.bz2
ARG INTEL_VAAPI_DRIVER_URL=https://github.com/intel/intel-vaapi-driver/releases/download/${INTEL_VAAPI_DRIVER_VERSION}/intel-vaapi-driver-${INTEL_VAAPI_DRIVER_VERSION}.tar.bz2
ARG GMMLIB_URL=https://github.com/intel/gmmlib/archive/intel-gmmlib-${GMMLIB_VERSION}.tar.gz
ARG INTEL_MEDIA_DRIVER_URL=https://github.com/intel/media-driver/archive/intel-media-${INTEL_MEDIA_DRIVER_VERSION}.tar.gz
ARG INTEL_MEDIA_SDK_URL=https://github.com/Intel-Media-SDK/MediaSDK/archive/intel-mediasdk-${INTEL_MEDIA_SDK_VERSION}.tar.gz
ARG INTEL_ONEVPL_GPU_RUNTIME_URL=https://github.com/oneapi-src/oneVPL-intel-gpu/archive/refs/tags/intel-onevpl-${INTEL_ONEVPL_GPU_RUNTIME_VERSION}.tar.gz
ARG CPU_FEATURES_URL=https://github.com/google/cpu_features/archive/refs/tags/v${CPU_FEATURES_VERSION}.tar.gz

# Set to 'max' to keep debug symbols.
ARG HANDBRAKE_DEBUG_MODE=none

# Get Dockerfile cross-compilation helpers.
FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

# Build HandBrake.
FROM --platform=$BUILDPLATFORM alpine:3.19 AS handbrake
ARG TARGETPLATFORM
ARG HANDBRAKE_VERSION
ARG HANDBRAKE_URL
ARG HANDBRAKE_DEBUG_MODE
ARG LIBVA_URL
ARG INTEL_VAAPI_DRIVER_URL
ARG GMMLIB_URL
ARG INTEL_MEDIA_DRIVER_URL
ARG INTEL_MEDIA_SDK_URL
ARG INTEL_ONEVPL_GPU_RUNTIME_URL
COPY --from=xx / /
COPY src/handbrake /build
RUN /build/build.sh \
    "$HANDBRAKE_VERSION" \
    "$HANDBRAKE_URL" \
    "$HANDBRAKE_DEBUG_MODE" \
    "$LIBVA_URL" \
    "$INTEL_VAAPI_DRIVER_URL" \
    "$GMMLIB_URL" \
    "$INTEL_MEDIA_DRIVER_URL" \
    "$INTEL_MEDIA_SDK_URL" \
    "$INTEL_ONEVPL_GPU_RUNTIME_URL"
RUN xx-verify \
    /tmp/handbrake-install/usr/bin/ghb \
    /tmp/handbrake-install/usr/bin/HandBrakeCLI

# Build cpu_features.
FROM --platform=$BUILDPLATFORM alpine:3.19 AS cpu_features
ARG TARGETPLATFORM
ARG CPU_FEATURES_URL
COPY --from=xx / /
COPY src/cpu_features /build
RUN /build/build.sh "$CPU_FEATURES_URL"
RUN xx-verify /tmp/cpu_features-install/bin/list_cpu_features

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.19-v4.5.3

ARG HANDBRAKE_VERSION
ARG DOCKER_IMAGE_VERSION

# Define working directory.
WORKDIR /tmp

# Install dependencies.
RUN \
    add-pkg \
        libstdc++ \
        gtk4.0 \
        mesa-dri-gallium \
        libgudev \
        libnotify \
        libsamplerate \
        libass \
        libdrm \
        jansson \
        xz \
        numactl \
        libturbojpeg \
        # Media codecs:
        libtheora \
        lame-libs \
        opus \
        libvorbis \
        speex \
        libvpx \
        x264-libs \
        # For QSV detection
        pciutils \
        # To read encrypted DVDs
        libdvdcss \
        # A font is needed.
        font-cantarell \
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
        expect \
        && \
    # Save some space by removing unused DRI drivers.
    find /usr/lib/xorg/modules/dri/ -type f ! -name swrast_dri.so ! -name libgallium_dri.so -exec echo "Removing {}..." ';' -delete

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/handbrake-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /
COPY --from=handbrake /tmp/handbrake-install /
COPY --from=cpu_features /tmp/cpu_features-install/bin/list_cpu_features /usr/bin/

# Set internal environment variables.
RUN \
    set-cont-env APP_NAME "HandBrake" && \
    set-cont-env APP_VERSION "$HANDBRAKE_VERSION" && \
    set-cont-env DOCKER_IMAGE_VERSION "$DOCKER_IMAGE_VERSION" && \
    true

# Set public environment variables.
ENV \
    HANDBRAKE_DEBUG=0 \
    HANDBRAKE_GUI=1 \
    AUTOMATED_CONVERSION=1 \
    AUTOMATED_CONVERSION_PRESET="General/Very Fast 1080p30" \
    AUTOMATED_CONVERSION_FORMAT=mp4 \
    AUTOMATED_CONVERSION_SOURCE_STABLE_TIME=5 \
    AUTOMATED_CONVERSION_SOURCE_MIN_DURATION=10 \
    AUTOMATED_CONVERSION_SOURCE_MAIN_TITLE_DETECTION=0 \
    AUTOMATED_CONVERSION_KEEP_SOURCE=1 \
    AUTOMATED_CONVERSION_OUTPUT_DIR=/output \
    AUTOMATED_CONVERSION_OUTPUT_SUBDIR= \
    AUTOMATED_CONVERSION_OVERWRITE_OUTPUT=0 \
    AUTOMATED_CONVERSION_VIDEO_FILE_EXTENSIONS= \
    AUTOMATED_CONVERSION_NON_VIDEO_FILE_ACTION=ignore \
    AUTOMATED_CONVERSION_NON_VIDEO_FILE_EXTENSIONS="jpg jpeg bmp png gif txt nfo" \
    AUTOMATED_CONVERSION_MAX_WATCH_FOLDERS=5 \
    AUTOMATED_CONVERSION_CHECK_INTERVAL=5 \
    AUTOMATED_CONVERSION_HANDBRAKE_CUSTOM_ARGS= \
    AUTOMATED_CONVERSION_INSTALL_PKGS= \
    AUTOMATED_CONVERSION_NO_GUI_PROGRESS=0 \
    AUTOMATED_CONVERSION_USE_TRASH=0

# Define mountable directories.
VOLUME ["/storage"]
VOLUME ["/output"]
VOLUME ["/watch"]
VOLUME ["/trash"]

# Metadata.
LABEL \
      org.label-schema.name="handbrake" \
      org.label-schema.description="Docker container for HandBrake" \
      org.label-schema.version="${DOCKER_IMAGE_VERSION:-}" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-handbrake" \
      org.label-schema.schema-version="1.0"
