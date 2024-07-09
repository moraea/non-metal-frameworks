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

mkdir -p $OUTDIR/Temp/IOSurface

Renamer $BINARIES/10.15.7*/IOSurface $OUTDIR/Temp/IOSurface/IOSurface.cat.patched _IOSurfaceGetPropertyMaximum

printf "$OUTDIR/Temp/IOSurface/IOSurface.cat.patched" > $OUTDIR/Temp/IOSurface/downgradeSources.data
printf "-DCAT" > $OUTDIR/Temp/IOSurface/compilerFlags.data
# $(realpath $BINARIES/10.14.6*/IOSurface)" > $OUTDIR/Temp/IOSurface/downgradeSources.data
# FIXME: switch to plists to allow for better pipeline