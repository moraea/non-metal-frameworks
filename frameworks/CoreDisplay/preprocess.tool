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

mkdir -p $OUTDIR/Temp/CoreDisplay

lipo -thin x86_64 $BINARIES/10.14.4*/CoreDisplay -output $OUTDIR/Temp/CoreDisplay/CoreDisplay.patched

Binpatcher $OUTDIR/Temp/CoreDisplay/CoreDisplay.patched $OUTDIR/Temp/CoreDisplay/CoreDisplay.patched '
# TODO: AGDC hack
set 0x7e53f
write 0xe9c5feffff'

printf "$OUTDIR/Temp/CoreDisplay/CoreDisplay.patched" > $OUTDIR/Temp/CoreDisplay/downgradeSources.data
printf "" > $OUTDIR/Temp/CoreDisplay/compilerFlags.data