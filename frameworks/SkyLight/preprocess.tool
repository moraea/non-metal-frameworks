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

mkdir -p "$OUTDIR/$MAJOR/SkyLight"
mkdir -p $OUTDIR/Temp/SkyLight

lipo -thin x86_64 $BINARIES/10.14.6*/SkyLight -output $OUTDIR/Temp/SkyLight/SkyLight.patched

Renamer $OUTDIR/Temp/SkyLight/SkyLight.patched $OUTDIR/Temp/SkyLight/SkyLight.patched _SLSNewWindowWithOpaqueShape _SLSSetMenuBars _SLSCopyDevicesDictionary _SLSCopyCoordinatedDistributedNotificationContinuationBlock _SLSShapeWindowInWindowCoordinates _SLSEventTapCreate _SLSWindowSetShadowProperties _SLSSetWindowType _SLSHWCaptureWindowList

Binpatcher $OUTDIR/Temp/SkyLight/SkyLight.patched $OUTDIR/Temp/SkyLight/SkyLight.patched '
# the transparency hack
set 0x216bb0
nop 0x4

# menubar height (22.0 --> 24.0)
set 0xb93c4
write 0x38

# WSBackdropGetCorrectedColor remove 0x17 (MenuBarDark) material background (floats RGBA)
set 0x26ef60
write 0x00000000000000000000000000000000

# force 0x17 for light, inactive
set 0xb6ccb
write 0x17
set 0xb6cd8
write 0x17
set 0xb6cde
write 0x17

# override blend mode
# 0: works
# 1: invisible light
# 2: invisible dark
# 3+: corrupt
set 0xb6d72
write 0x00
set +0x3
nop 0x4

# hide backstop
# TODO: weird
set 0xb8789
nop 0x2
set 0xb879f
nop 0x8
set 0xb87de
nop 0x2

# prevent prefpane crash
# TODO: look at this again now that we have SLSInstallRemoteContextNotificationHandlerV2 shim
symbol ___SLSRemoveRemoteContextNotificationHandler_block_invoke
return 0x0

# disable entitlement check
symbol __ZL26debug_connection_permittedv
return 0x1

# Fabio rim tweak
# https://github.com/ASentientBot/monterey/issues/3
# set 0xf4360
# write 0xff
# set 0xf47e7
# write 0xff

# Menubar background
# warning: almost certainly breaks CAPL and defenestrator-off!

# override blur radius (cannibalizes stack canary)
set 0x21677c
write 0xbe80000000
nop 0x5
set 0x21687e
nop 0x2

# disable saturation (GLSL)
# set 0x294e62
# write 0x2f2f
# set 0x29625a
# write 0x2f2f

# disable saturation (identity matrix)
# set 0x26ed60
# write 0x0000803f000000000000000000000000000000000000803f000000000000000000000000000000000000803f00000000

# default saturation 1.2
set 0x26ed60
write 0xfe27943f888112be68a36cbc0000000080332ebd6949873f68a36cbc0000000080332ebd888112be53c0973f00000000
'

if [[ $MAJOR -ge 14 ]]; then
    Renamer $OUTDIR/Temp/SkyLight/SkyLight.patched $OUTDIR/Temp/SkyLight/SkyLight.patched _SLSTransactionCommit
fi

echo "$OUTDIR/Temp/SkyLight/SkyLight.patched" > $OUTDIR/Temp/SkyLight/downgradeSources.data
printf "-F /System/Library/PrivateFrameworks -framework AppleSystemInfo -framework CoreBrightness" > $OUTDIR/Temp/SkyLight/compilerFlags.data

# Build LibSystemWrapper.dylib
if [[ $MAJOR -ge 14 ]]; then
    clang -fmodules -dynamiclib -Xlinker -reexport_library -Xlinker /usr/lib/libSystem.B.dylib $FRAMEWORK/extras/LibSystemWrapper.m -o "$OUTDIR/$MAJOR/SkyLight/LibSystemWrapper.dylib"
    codesign -fs - "$OUTDIR/$MAJOR/SkyLight/LibSystemWrapper.dylib"
    install_name_tool -change /usr/lib/libSystem.B.dylib /System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/LibSystemWrapper.dylib "$OUTDIR/$MAJOR/SkyLight/SkyLightOld.dylib"
fi
