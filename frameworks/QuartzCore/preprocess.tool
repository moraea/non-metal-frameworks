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

mkdir -p $OUTDIR/Temp/QuartzCore

DOWNGRADE_VERSION_WITH_DOTS=$(cat $OUTDIR/Temp/QuartzCore/buildSettings.qcDowngrade.data)
DOWNGRADE_PADDED_VERSION=$(versionToPreprocessor $DOWNGRADE_VERSION_WITH_DOTS)

if [[ -z $DOWNGRADE_VERSION_WITH_DOTS ]]; then
    echo "QuartzCore: No downgrade specified. Skipping."
    exit 0
fi

cp $(realpath $BINARIES/$DOWNGRADE_VERSION_WITH_DOTS*/QuartzCore) $OUTDIR/Temp/QuartzCore/QuartzCore.patched

if [[ $MAJOR -ge 13 && ($DOWNGRADE_PADDED_VERSION -lt 110000) ]]; then
    echo "QuartzCore: Applying _CASSynchronize hack"
    Binpatcher $OUTDIR/Temp/QuartzCore/QuartzCore.patched $OUTDIR/Temp/QuartzCore/QuartzCore.patched '
symbol __CASSynchronize
return 0x0'

    echo "QuartzCore: Applying _CARequiresColorMatching hack"
    Binpatcher $OUTDIR/Temp/QuartzCore/QuartzCore.patched $OUTDIR/Temp/QuartzCore/QuartzCore.patched '
symbol _CARequiresColorMatching
return 0x0'
fi

printf $OUTDIR/Temp/QuartzCore/QuartzCore.patched > $OUTDIR/Temp/QuartzCore/downgradeSources.data
printf "-DFRAMEWORK_DOWNGRADE=$DOWNGRADE_PADDED_VERSION" > $OUTDIR/Temp/QuartzCore/compilerFlags.data