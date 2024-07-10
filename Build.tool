#!/bin/zsh

set -e
cd "$(dirname "$0")"

build() {
	COMPILER_FLAGS=()

	while [[ $# -gt 0 ]]; do
	case $1 in 
		-fw|--framework)
		FRAMEWORK="$2"
		shift # Increment key index
		shift # Increment value index
		;;
		-ob|-db|--downgradeBinary)
		DOWNGRADE_BINARY="$2"
		shift # Increment key index
		shift # Increment value index
		;;
		-nb|--newBinary)
		NEW_BINARY="$2"
		shift # Increment key index
		shift # Increment value index
		;;
		-in|--installName)
		INSTALL_NAME="$2"
		shift # Increment key index
		shift # Increment value index
		;;
		-od|--outDir)
		OUTDIR="$2"
		shift # Increment key index
		shift # Increment value index
		;;
		*)
		# Save the rest of the arguments as compiler flags
		COMPILER_FLAGS+=("$1")
		shift # past argument
		;;
	esac
	done

	if [[ -z "$FRAMEWORK" ]]; then
		echo "No framework specified."
		exit 1
	fi
	FRAMEWORK_NAME=${FRAMEWORK##*/}

	if [[ -z "$DOWNGRADE_BINARY" ]]; then
		echo "No downgrade binary specified."
		exit 1
	fi

	if [[ -z "$NEW_BINARY" ]]; then
		echo "No new binary specified."
		exit 1
	fi

	if [[ -z "$INSTALL_NAME" ]]; then
		echo "No install name specified."
		exit 1
	fi

	if [[ -z "$OUTDIR" ]]; then
		echo "No output directory specified."
		exit 1
	fi
	
	mkdir -p "$OUTDIR/$major/$FRAMEWORK_NAME"

	cp -c "$DOWNGRADE_BINARY" "$OUTDIR/$major/$FRAMEWORK_NAME/${FRAMEWORK_NAME}Old.dylib"
	install_name_tool -id "${INSTALL_NAME}Old.dylib" "$OUTDIR/$major/$FRAMEWORK_NAME/${FRAMEWORK_NAME}Old.dylib"

	WRAPPER=$OUTDIR/$major/$FRAMEWORK_NAME/${FRAMEWORK_NAME}Wrapper.m
	# Is stubber overriden via an environment variable?
	if [[ -z "$STUBBER_BIN" ]]; then
		STUBBER_BIN="stubber"
	fi
	$STUBBER_BIN -sop "$WRAPPER" -odp "$DOWNGRADE_BINARY" -ndp "$NEW_BINARY" -shim "$FRAMEWORK/src/Main.m" \
		-dynamiclib -fmodules -I$OUTDIR/moraea-common/Utils -D__MAC_OS_X_VERSION_MIN_REQUIRED=$major"0000" $COMPILER_FLAGS
	                                                        # ^ Required as libclang doesn't accept -mmacosx-version-min.

	CURRENT_VERSION="$(otool -l "$NEW_BINARY" | grep -m 1 'current version' | cut -d ' ' -f 9)"
	COMPATIBILITY_VERSION="$(otool -l "$NEW_BINARY" | grep -m 1 'compatibility version' | cut -d ' ' -f 3)"
	# FIXME: force x86_64 clang to resolve issue with modules not being found.
	arch -x86_64 clang -dynamiclib -fmodules -Wno-unused-getter-return-value -Wno-objc-missing-super-calls \
		-mmacosx-version-min=$major -compatibility_version "$COMPATIBILITY_VERSION" -current_version "$CURRENT_VERSION" \
		-install_name "$INSTALL_NAME" -Xlinker -reexport_library -Xlinker "$OUTDIR/$major/$FRAMEWORK_NAME/${FRAMEWORK_NAME}Old.dylib" \
		-include "$WRAPPER" "$FRAMEWORK/src/Main.m" -o "$OUTDIR/$major/$FRAMEWORK_NAME/$FRAMEWORK_NAME" -Xlinker -no_warn_inits $COMPILER_FLAGS
	# arch -x86_64 clang -Xclang -ast-dump=json -fsyntax-only -fmodules -Wno-unused-getter-return-value -Wno-objc-missing-super-calls \
	# 	-mmacosx-version-min=$major -include "$WRAPPER" "$FRAMEWORK/src/Main.m" $COMPILER_FLAGS > "$OUTDIR/$major/$FRAMEWORK_NAME/$FRAMEWORK_NAME.ast.json"
	codesign -fs - "$OUTDIR/$major/$FRAMEWORK_NAME/$FRAMEWORK_NAME"
	codesign -fs - "$OUTDIR/$major/$FRAMEWORK_NAME/${FRAMEWORK_NAME}Old.dylib"
}

main() {
	POSITIONAL_ARGS=()
    UNRECOGNIZED_ARGS=()

	AVAILABLE_FRAMEWORK_SHIMS=()
	for folder in ${0:a:h}/frameworks/*; do
		if [[ -d $folder ]]; then
			AVAILABLE_FRAMEWORK_SHIMS+="$folder"
		fi
	done

	ALLOWED_VERSION_TARGETS=("11" "12" "13" "14" "15")

	while [[ $# -gt 0 ]]; do
	case $1 in
		-h|--help)
		echo "Usage: Build.tool --versionTargets [11 | 12 | 13 | 14 | 15] --binaries [moraea-sources] --outdir [path] -t [moraea-common] [framework specific arguments]"
		exit 0
		;;
		--versionTarget|--versionTargets)
		SELECTED_VERSION_TARGETS=(${(@s/ /)2})
		for version in "${SELECTED_VERSION_TARGETS[@]}"; do
			if [[ ! " ${ALLOWED_VERSION_TARGETS[@]} " =~ " ${version} " ]]; then
				echo "Invalid version target: $version. Allowed values (any combination of): ${ALLOWED_VERSION_TARGETS[@]}"
				exit 1
			fi
		done
		shift # Increment key index
		shift # Increment value index
		;;
		-f|--frameworkShimsToBuild)
		SELECTED_FRAMEWORKS=(${(@s/ /)2})
		FRAMEWORKS_TO_BUILD=()
		for framework in "${SELECTED_FRAMEWORKS[@]}"; do
			if [[ ! " ${AVAILABLE_FRAMEWORK_SHIMS[@]##*/} " =~ " ${framework##*/} " ]]; then
				echo "Invalid framework shim: ${framework##*/}. Allowed values (any combination of): ${AVAILABLE_FRAMEWORK_SHIMS[@]##*/}"
				exit 1
			fi
		done
		for available_framework in $AVAILABLE_FRAMEWORK_SHIMS; do
			if [[ " ${SELECTED_FRAMEWORKS[@]##*/} " =~ " ${available_framework##*/} " ]]; then
				FRAMEWORKS_TO_BUILD+="$available_framework"
			fi
		done
		shift # Increment key index
		shift # Increment value index
		;;
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
		-t|--toolchain)
		TOOLCHAIN="$2"
		shift # Increment key index
		shift # Increment value index
		;;
		-*|--*)
        UNRECOGNIZED_ARGS+=("$1" "$2")
        shift # Increment key index
        shift # Increment value index
		;;
		*)
		POSITIONAL_ARGS+=("$1") # save positional arg
		shift # past argument
		;;
	esac
	done

    ## Default values
	# Handle target version omission
	if [[ -z "$SELECTED_VERSION_TARGETS" ]]; then
		SELECTED_VERSION_TARGETS=( "${$(sw_vers -productVersion):0:2}" )
		echo "No target version specified. Defaulting to booted macOS version: $SELECTED_VERSION_TARGETS..."
	fi
	# Handle target framework omission
	if [[ -z "$SELECTED_FRAMEWORKS" ]]; then
		FRAMEWORKS_TO_BUILD=($AVAILABLE_FRAMEWORK_SHIMS)
		echo "No framework shim(s) specified. Defaulting to building all available frameworks..."
	fi
	# Handle repository path omission
	if [[ -z "$BINARIES" ]]; then
		BINARIES="${0:a:h}/moraea-sources"
		echo "No repository path specified. Defaulting to \"$BINARIES\"..."
	fi
	if [[ ! -d "$BINARIES" ]]; then
		echo "Repository path does not exist. Exiting..."
		exit 1
	fi

	# Handle output directory omission
	if [[ -z "$OUTDIR" ]]; then
		OUTDIR="${0:a:h}/Build"
		echo "No output directory specified. Defaulting to \"$OUTDIR\"..."
	fi
	# Handle toolchain omission
	if [[ -z "$TOOLCHAIN" ]]; then
		TOOLCHAIN="${0:a:h}/moraea-common"
		echo "No toolchain specified. Defaulting to \"$TOOLCHAIN\"..."
	fi

    ## Ensure directory structure
	# Create output directory if it doesn't exist
	if [[ ! -d $OUTDIR ]]; then
		mkdir -p $OUTDIR
	fi
	# Build and configure the toolchain
	$TOOLCHAIN/Build.tool -o $OUTDIR/moraea-common -s $TOOLCHAIN -f
	export C_INCLUDE_PATH="$C_INCLUDE_PATH:$OUTDIR/moraea-common/Utils"
	export OBJC_INCLUDE_PATH="$OBJC_INCLUDE_PATH:$OUTDIR/moraea-common/Utils"
	export CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:$OUTDIR/moraea-common/Utils"
	export OBJCPLUS_INCLUDE_PATH="$OBJCPLUS_INCLUDE_PATH:$OUTDIR/moraea-common/Utils"
	export PATH="$PATH:$OUTDIR/moraea-common"
    
    set -- "${UNRECOGNIZED_ARGS[@]}" # handle unrecognized arguments

	while [[ $# -gt 0 ]]; do
	case $1 in
        -*|--*)
        # Pass unknown arguments to the frameworks to handle
        # framework specific arguments. (e.g. QC Downgrade)
        # If no framework can handle the argument, exit with an error.
        set +e
        ARG_HANDLED=NO
        for framework in $FRAMEWORKS_TO_BUILD; do
            if [[ -e $framework/argparse.tool ]]; then
                echo "Passing $1 argument with $2 value to ${framework##*/} shim..."
                
                $framework/argparse.tool --outdir $OUTDIR --framework ${framework##*/} $1 $2
                if [[ $? -eq 2 ]]; then # Exit status 1 is an option with input
                    shift # Increment key index
                    shift # Increment value index
                    ARG_HANDLED=YES
                elif [[ $? -eq 1 ]]; then # Exit status 2 is a boolean argument
                    shift # Increment key index
                    ARG_HANDLED=YES
                else
                    echo "${framework##*/} shim did not handle the argument."
                    continue
                fi
            fi
        done
        set -e
        if [[ $ARG_HANDLED == "NO" ]]; then
            echo "Unknown argument: $1"
            exit 1
        fi
        ;;
    esac
    done
    
    set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

	## The main event!
	# Build the frameworks
	for major in $SELECTED_VERSION_TARGETS; do
		for framework in $FRAMEWORKS_TO_BUILD; do
			echo "Building ${framework##*/} shim for macOS $major..."
			# Preprocess the old binary with binary patches.
			# This will also write to downgradeSources.data the needed downgrades.
			$framework/preprocess.tool -b $BINARIES -o $OUTDIR -f $framework -m $major
			DOWNGRADE_SOURCES=(${(@s/\n/)$(cat $OUTDIR/Temp/${framework##*/}/downgradeSources.data)})
			for downgrade in $DOWNGRADE_SOURCES; do
				build --framework $framework --downgradeBinary $downgrade --newBinary $BINARIES/$major.*/${framework##*/} --installName $(cat $framework/installName.data) $(cat $OUTDIR/Temp/${framework##*/}/compilerFlags.data)
			done
		done
	done
	
}

main "$@"