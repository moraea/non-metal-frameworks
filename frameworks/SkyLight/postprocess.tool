#!/bin/zsh

while [[ $# -gt 0 ]]; do
case $1 in 
    -b|--binaries)
    BINARIES="$2"
    shift # Increment key index
    shift # Increment value index
    ;;
    -o|--outdir)
    OUTDIR="$2"
    shift # Increment key index
    shift # Increment value index
    ;;
    -f|--framework)
    FRAMEWORK="$2"
    shift # Increment key index
    shift # Increment value index
    ;;
    -m|--major)
    MAJOR="$2"
    shift # Increment key index
    shift # Increment value index
    ;;
esac
done

# Finish building LibSystemWrapper.dylib
if [[ $MAJOR -ge 14 ]]; then
    install_name_tool -change /usr/lib/libSystem.B.dylib /System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/LibSystemWrapper.dylib "$OUTDIR/$MAJOR/SkyLight/SkyLightOld.dylib"
    codesign -fs - "$OUTDIR/$MAJOR/SkyLight/LibSystemWrapper.dylib"
fi
