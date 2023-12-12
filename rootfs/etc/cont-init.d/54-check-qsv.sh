#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

DRI_DIR="/dev/dri"
DRI_DEV="$(ls "$DRI_DIR"/renderD* 2>/dev/null || true)"
PROCESSOR_NAME="$(list_cpu_features | grep "^brand " | awk -F ':' '{ gsub(/^[ \t]+/,"",$2); print $2 }')"
MICROARCHITECTURE="$(list_cpu_features | grep "^uarch " | awk -F ':' '{ gsub(/^[ \t]+/,"",$2); print $2 }')"

CPU_QSV_CAPABLE=true
CPU_SUPPORTED_BY_HB=true

echo "Processor: $PROCESSOR_NAME"
echo "Microarchitecture: $MICROARCHITECTURE"
echo "Kernel: $(uname -r)"

#
# Determine if the microarchitecture supports QSV.  If it does, verify if it is
# supported by HandBrake.
#
# See the following references:
#     https://en.wikipedia.org/w/index.php?title=Intel_Quick_Sync_Video
#     https://en.wikipedia.org/wiki/List_of_Intel_CPU_microarchitectures
#     https://github.com/google/cpu_features/blob/main/include/cpuinfo_x86.h
#     https://handbrake.fr/docs/en/latest/technical/video-qsv.html
#
case "$MICROARCHITECTURE" in
    # QSV Version 1
    INTEL_SNB)              # SANDYBRIDGE
        CPU_SUPPORTED_BY_HB=false
        ;;
    # QSV Version 2
    INTEL_IVB)              # IVYBRIDGE
        CPU_SUPPORTED_BY_HB=false
        ;;
    # QSV Version 3
    INTEL_HSW)              # HASWELL
        CPU_SUPPORTED_BY_HB=false
        ;;
    # QSV Version 4
    INTEL_BDW)              # BROADWELL
        CPU_SUPPORTED_BY_HB=false
        ;;
    # QSV Version 5
    INTEL_SKL) ;;           # SKYLAKE
    INTEL_ATOM_GMT) ;;      # GOLDMONT
    INTEL_ATOM_GMT_PLUS) ;; # GOLDMONT+
    # QSV Version 6
    INTEL_KBL) ;;           # KABY LAKE
    INTEL_CFL) ;;           # COFFEE LAKE
    INTEL_WHL) ;;           # WHISKEY LAKE
    INTEL_CML) ;;           # COMET LAKE
    # QSV Version 7
    INTEL_ICL) ;;           # ICE LAKE
    # QSV Version 8
    INTEL_TGL) ;;           # TIGER LAKE
    INTEL_RCL) ;;           # ROCKET LAKE
    INTEL_ADL) ;;           # ALDER LAKE
    INTEL_RPL) ;;           # RAPTOR LAKE
    INTEL_ATOM_TMT) ;;      # TREMONT
    # QSV Version 9
    #     Only Intel ARC for now.
    # QSV not supported by the processor.
    *)
        CPU_QSV_CAPABLE=false
        ;;
esac

if [ ! -d "$DRI_DIR" ]; then
    echo "Intel Quick Sync Video not supported: device directory $DRI_DIR not exposed to the container."
    exit 0
fi

if [ -z "${DRI_DEV:-}" ]; then
    echo "Intel Quick Sync Video not supported: no Direct Rendering Manager (DRM) device found under $DRI_DIR."
    exit 0
fi

if ! lspci -k | grep -qw i915; then
    echo "Intel Quick Sync Video not supported: video adapter not using i915 driver."
    exit 0
fi

# Intel ARC is a discrete GPU that supports QSV.  This means that QSV might be
# usable even if CPU doesn't support it.
if ! $CPU_QSV_CAPABLE; then
    echo "Intel Quick Sync Video may not be supported: processor not QSV capable."
elif ! $CPU_SUPPORTED_BY_HB; then
    echo "Intel Quick Sync Video may not be supported: processor not supported by HandBrake."
fi

# Get group of devices under /dev/dri/.
find /dev/dri/ -type c | while read DRI_DEV
do
    G="$(stat -c "%g" "$DRI_DEV")"
    if [ "$G" -eq 0 ]; then
        # Device is owned by root.  If the configured user doesn't have access
        # to it, then QSV won't work (setting the supplementary group to 0
        # doesn't work).
        if ! (su-exec "$USER_ID:$GROUP_ID" test -r "$DRI_DEV") || \
           ! (su-exec "$USER_ID:$GROUP_ID" test -w "$DRI_DEV")
        then
            echo "Intel Quick Sync Video not supported: device $DRI_DEV owned" \
                 "by group 'root' and configured user doesn't have permissions" \
                 "to access it."
            break
        fi
    fi
done

# vim:ts=4:sw=4:et:sts=4
