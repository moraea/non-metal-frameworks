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

source $OUTDIR/moraea-common/Gadgets/versionToPreprocessor.zsh

mkdir -p $OUTDIR/Temp/IOSurface

DOWNGRADE_VERSION_WITH_DOTS=$(cat $OUTDIR/Temp/IOSurface/buildSettings.iosurfaceDowngrade.data)
DOWNGRADE_PADDED_VERSION=$(versionToPreprocessor $DOWNGRADE_VERSION_WITH_DOTS)

if [[ -z $DOWNGRADE_VERSION_WITH_DOTS ]]; then
    echo "IOSurface: No downgrade specified. Skipping."
    exit 0
fi

if [[ $DOWNGRADE_VERSION_WITH_DOTS == "10.15" ]]; then
    Renamer $BINARIES/10.15.7*/IOSurface $OUTDIR/Temp/IOSurface/IOSurface.cat.patched _IOSurfaceGetPropertyMaximum
    printf "$OUTDIR/Temp/IOSurface/IOSurface.cat.patched" > $OUTDIR/Temp/IOSurface/downgradeSources.data
    printf "-DFRAMEWORK_DOWNGRADE=$DOWNGRADE_PADDED_VERSION" > $OUTDIR/Temp/IOSurface/compilerFlags.data
elif [[ $DOWNGRADE_VERSION_WITH_DOTS == "10.14" ]]; then
    realpath $BINARIES/10.14.6*/IOSurface > $OUTDIR/Temp/IOSurface/downgradeSources.data
    printf "-DFRAMEWORK_DOWNGRADE=$DOWNGRADE_PADDED_VERSION" > $OUTDIR/Temp/IOSurface/compilerFlags.data
fi