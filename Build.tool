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

	# TODO: stopgap for dlopening issues until Stubber 3

	hackNew="${newIn}.json"
	hackOld="${oldIn}.json"

	Stubber "$oldIn" "$newIn" "$PWD" "$mainIn" "$hackNew" "$hackOld"

	current="$(otool -l "$newIn" | grep -m 1 'current version' | cut -d ' ' -f 9)"
	compatibility="$(otool -l "$newIn" | grep -m 1 'compatibility version' | cut -d ' ' -f 3)"

	if test -n "$SENTIENT_PATCHER"
	then
		extraArgs=-DSENTIENT_PATCHER
	fi
	clang -dynamiclib -fmodules -I Build/non-metal-common/Utils -Wno-unused-getter-return-value -Wno-objc-missing-super-calls -mmacosx-version-min=14 -DMAJOR=14 -compatibility_version "$compatibility" -current_version "$current" -install_name "$mainInstall" -Xlinker -reexport_library -Xlinker "$oldOut" "$mainIn" -o "$mainOut" "${@:5}" -Xlinker -no_warn_inits $extraArgs -Xlinker -not_for_dyld_shared_cache

	# TODO: automatically handle in Stubber? move elsewhere? edit imports and binpatch?
	# idk. this works for now...

	if [[ ($name = SkyLight) && ($major -ge 14) ]]
	then
		clang -fmodules -dynamiclib -Xlinker -reexport_library -Xlinker /usr/lib/libSystem.B.dylib LibSystemWrapper.m -o "$prefixOut/LibSystemWrapper.dylib"
		codesign -fs - "$prefixOut/LibSystemWrapper.dylib"

		install_name_tool -change /usr/lib/libSystem.B.dylib /System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/LibSystemWrapper.dylib "$oldOut"
	fi

	codesign -f -s - "$oldOut"
	codesign -f -s - "$mainOut"
}

binaries=Build/non-metal-binaries

lipo -thin x86_64 $binaries/10.14.6*/SkyLight -output Build/SkyLight.patched

Renamer Build/SkyLight.patched Build/SkyLight.patched _SLSNewWindowWithOpaqueShape _SLSSetMenuBars _SLSCopyDevicesDictionary _SLSCopyCoordinatedDistributedNotificationContinuationBlock _SLSShapeWindowInWindowCoordinates _SLSEventTapCreate _SLSWindowSetShadowProperties _SLSSetWindowType _SLSHWCaptureWindowList

Binpatcher Build/SkyLight.patched Build/SkyLight.patched '
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

cp $binaries/10.14.6*/SkyLight.json Build/SkyLight.patched.json

lipo -thin x86_64 $binaries/10.14.4*/CoreDisplay -output Build/CoreDisplay.patched

Binpatcher Build/CoreDisplay.patched Build/CoreDisplay.patched '
# TODO: AGDC hack
set 0x7e53f
write 0xe9c5feffff'

Renamer $binaries/10.15.7*/IOSurface Build/IOSurface.cat.patched _IOSurfaceGetPropertyMaximum

function runWithTargetVersion
{
	major=$1
	echo begin $major

	if test "$major" -ge 13
	then
		Renamer Build/SkyLight.patched Build/SkyLight.patched _SLSTransactionCommit
	fi

	rm -rf Build/$major
	mkdir Build/$major

	build Build/SkyLight.patched $binaries/$major.*/SkyLight /System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight Common -F /System/Library/PrivateFrameworks -framework AppleSystemInfo -framework CoreBrightness
	build Build/CoreDisplay.patched $binaries/$major.*/CoreDisplay /System/Library/Frameworks/CoreDisplay.framework/Versions/A/CoreDisplay Common
	build Build/IOSurface.cat.patched $binaries/$major.*/IOSurface /System/Library/Frameworks/IOSurface.framework/Versions/A/IOSurface Zoe -DCAT
	build $binaries/10.14.6*/IOSurface $binaries/$major.*/IOSurface /System/Library/Frameworks/IOSurface.framework/Versions/A/IOSurface Cass2 -DMOJ
	build $binaries/10.13.6*/IOAccelerator $binaries/$major.*/IOAccelerator /System/Library/PrivateFrameworks/IOAccelerator.framework/Versions/A/IOAccelerator Cass2

	# TODO: MOJ/CAT/BS (downgrade version) vs 11/12/13 (target version) a bit confusing?

	if test -n "$AUTO_QC"
	then
		case "$AUTO_QC" in
			10.14)
				qc=MOJ
				;;
			10.15)
				qc=CAT
				;;
			11)
				qc=BS
				;;
		esac
	else
		clear
		echo "###################################\n# choose the QuartzCore downgrade #\n###################################"
		select opt in "Mojave" "Catalina" "Big Sur" "Skip"; do
			case $opt in
				"Mojave")
					qc=MOJ
					break
					;;
				"Catalina")
					qc=CAT
					break
					;;
				"Big Sur")
					qc=BS
					break
					;;
				"Skip")
					exit
					;;
				*)
					   echo "This is not an option, please try again"
					  ;;
				  esac
				done
	fi

	case "$qc" in
		MOJ)
			lipo -thin x86_64 $binaries/10.14.6*/QuartzCore -output Build/QuartzCore.patched
			cp $binaries/10.14.6*/QuartzCore.json Build/QuartzCore.patched.json || true
			;;
		CAT)
			cp $binaries/10.15.7*/QuartzCore Build/QuartzCore.patched
			cp $binaries/10.15.7*/QuartzCore.json Build/QuartzCore.patched.json || true
			;;
		BS)
			if [[ ! "$major" -eq 11 ]]
			then
				cp $binaries/11.*/QuartzCore Build/QuartzCore.patched
				cp $binaries/11.*/QuartzCore.json Build/QuartzCore.patched.json || true
			fi
			;;
	esac

	if [[ "$major" -ge 13 && ("$qc" = MOJ || "$qc" = CAT) ]]
	then
		echo 'applying _CASSynchronize hack'
		Binpatcher Build/QuartzCore.patched Build/QuartzCore.patched '
symbol __CASSynchronize
return 0x0'

	if [[ "$major" -ge 14 ]]
		echo 'applying _CARequiresColorMatching hack'
		Binpatcher Build/QuartzCore.patched Build/QuartzCore.patched '
symbol _CARequiresColorMatching
return 0x0'

	fi

	echo 'applying _CARequiresColorMatching hack'
	Binpatcher Build/QuartzCore.patched Build/QuartzCore.patched '
symbol _CARequiresColorMatching
return 0x0'

	if [[ -e Build/QuartzCore.patched ]]
	then
		build Build/QuartzCore.patched $binaries/$major.*/QuartzCore /System/Library/Frameworks/QuartzCore.framework/Versions/A/QuartzCore Common -D$qc

		touch Build/$major/note_used_${qc}_qc.txt
	else
		clear
		echo "#######################\n# Skipping QuartzCore #\n#######################"
		sleep 2
	fi
}

if test -n "$AUTO_TARGET"
then
	echo 'skipping target version prompt'
	target="$AUTO_TARGET"
else
	clear
	echo "#############\n# Build For #\n#############"
	select opt in "Big Sur" "Monterey" "Ventura" "Sonoma" "Sequoia" "Exit"; do
    case $opt in
    	"Big Sur")
			target=11
			break
			;;
    	"Monterey")
			target=12
			break
			;;
    	"Ventura")
			target=13
			break
			;;
    	"Sonoma")
			target=14
			break
			;;
    	"Sequoia")
			target=15
			break
			;;
	    "Exit")
	      exit
	      ;;
	    *)
	      echo "This is not an option, please try again"
	      ;;
	  esac
	done
fi

runWithTargetVersion "$target"
