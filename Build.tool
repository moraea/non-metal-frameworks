#!/bin/zsh

set -e
cd "$(dirname "$0")"

PATH+=:"$PWD/Build/non-metal-common/Build"

function build
{
	oldIn="$1"
	newIn="$2"
	mainInstall="$3"

	prefixOut="Build/$major/$4"
	mkdir -p "$prefixOut"
	
	name="$(basename "$mainInstall")"
	mainNameOut="$name"
	oldNameOut="${name}Old.dylib"
	
	prefixInstall="$(dirname "$mainInstall")"
	oldInstall="$prefixInstall/$oldNameOut"
	
	mainOut="$prefixOut/$mainNameOut"
	oldOut="$prefixOut/$oldNameOut"
	
	cp "$oldIn" "$oldOut"
	install_name_tool -id "$oldInstall" "$oldOut"
	
	mainIn="$prefixOut/${name}Wrapper.m"

	Stubber "$oldIn" "$newIn" "$PWD" "$mainIn"

	current="$(otool -l "$newIn" | grep -m 1 'current version' | cut -d ' ' -f 9)"
	compatibility="$(otool -l "$newIn" | grep -m 1 'compatibility version' | cut -d ' ' -f 3)"
	echo "current $current compatibility $compatibility"

	if test -n "$SENTIENT_PATCHER"
	then
		extraArgs=-DSENTIENT_PATCHER
	fi
	clang -dynamiclib -fmodules -I Build/non-metal-common/Utils -Wno-unused-getter-return-value -Wno-objc-missing-super-calls -mmacosx-version-min=$major -DMAJOR=$major -compatibility_version "$compatibility" -current_version "$current" -install_name "$mainInstall" -Xlinker -reexport_library "$oldOut" "$mainIn" -o "$mainOut" "${@:5}" $extraArgs
	
	codesign -f -s - "$oldOut"
	codesign -f -s - "$mainOut"
}

binaries=Build/non-metal-binaries

lipo -thin x86_64 $binaries/10.14.6*/SkyLight -output Build/SkyLight.patched

Renamer Build/SkyLight.patched Build/SkyLight.patched _SLSNewWindowWithOpaqueShape _SLSSetMenuBars _SLSCopyDevicesDictionary _SLSCopyCoordinatedDistributedNotificationContinuationBlock _SLSShapeWindowInWindowCoordinates _SLSEventTapCreate _SLSWindowSetShadowProperties _SLSSetWindowType

Binpatcher Build/SkyLight.patched Build/SkyLight.patched '
# the transparency hack
set 0x216c60
nop 0x4

# menubar height (22.0 --> 24.0)
set 0xb949c
write 0x38

# WSBackdropGetCorrectedColor remove 0x17 (MenuBarDark) material background (floats RGBA)
set 0x26ef70
write 0x00000000000000000000000000000000

# force 0x17 for light, inactive
set 0xb6db6
write 0x17
set 0xb6da3
write 0x17
set 0xb6db0
write 0x17

# override blend mode
# 0: works
# 1: invisible light
# 2: invisible dark
# 3+: corrupt
set 0xb6e4a
write 0x00
set +0x3
nop 0x4

# hide backstop
# TODO: weird
set 0xb88b6
nop 0x2
set 0xb8861
nop 0x2
set 0xb8877
nop 0x8

# prevent prefpane crash
# TODO: shim SLSInstallRemoteContextNotificationHandlerV2 instead
symbol ___SLSRemoveRemoteContextNotificationHandler_block_invoke
return 0x0

symbol __ZL26debug_connection_permittedv
return 0x1

# Fabio rim tweak
# https://github.com/ASentientBot/monterey/issues/3
set 0xf4430
write 0xff
set 0xf48b7
write 0xff'

lipo -thin x86_64 $binaries/10.14.4*/CoreDisplay -output Build/CoreDisplay.patched

Binpatcher Build/CoreDisplay.patched Build/CoreDisplay.patched '
# TODO: AGDC hack
set 0x7e53f
write 0xe9c5feffff'

function runWithTargetVersion
{
	major=$1
	echo begin $major

	rm -rf Build/$major
	mkdir Build/$major

	build Build/SkyLight.patched $binaries/$major.*/SkyLight /System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight Common -F /System/Library/PrivateFrameworks -framework AppleSystemInfo -framework CoreBrightness
	build Build/CoreDisplay.patched $binaries/$major.*/CoreDisplay /System/Library/Frameworks/CoreDisplay.framework/Versions/A/CoreDisplay Common
	if test -n "$USE_CAT_QC"
	then
		touch Build/$major/note_used_cat_qc.txt
		build $binaries/10.15.7*/QuartzCore $binaries/$major.*/QuartzCore /System/Library/Frameworks/QuartzCore.framework/Versions/A/QuartzCore Common -DCAT
	else
		touch Build/$major/note_used_mojave_qc.txt
		build $binaries/10.14.6*/QuartzCore $binaries/$major.*/QuartzCore /System/Library/Frameworks/QuartzCore.framework/Versions/A/QuartzCore Common
	fi

	build $binaries/10.15.7*/IOSurface $binaries/$major.*/IOSurface /System/Library/Frameworks/IOSurface.framework/Versions/A/IOSurface Zoe

	build $binaries/10.14.6*/IOSurface $binaries/$major.*/IOSurface /System/Library/Frameworks/IOSurface.framework/Versions/A/IOSurface Cass2
	build $binaries/10.13.6*/IOAccelerator $binaries/$major.*/IOAccelerator /System/Library/PrivateFrameworks/IOAccelerator.framework/Versions/A/IOAccelerator Cass2
}

runWithTargetVersion 11
runWithTargetVersion 12