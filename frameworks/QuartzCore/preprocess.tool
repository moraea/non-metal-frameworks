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

mkdir -p $OUTDIR/Temp/QuartzCore

# Handle no selected QuartzCore downgrade
if [[ -z "$QC_DOWNGRADE" ]]; then
    echo "No QuartzCore downgrade specified. Skipping QuartzCore."
    printf '' > $OUTDIR/Temp/QuartzCore/downgradeSources.data
    printf "" > $OUTDIR/Temp/QuartzCore/compilerFlags.data
    exit 0
fi
