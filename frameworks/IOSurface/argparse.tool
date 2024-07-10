#!/bin/zsh

# Exit status 0 | Argument not found or invalid
# Exit status 1 | Argument is boolean
# Exit status 2 | Argument is option with input

argparse() {
    POSITIONAL_ARGS=()
    SAVED_KWARGS=()
    
    while [[ $# -gt 0 ]]; do
    case $1 in 
        -o|--outdir)
        OUTDIR="$2"
        shift # Increment key index
        shift # Increment value index
        ;;
        -fw|--framework)
        FRAMEWORK="$2"
        shift # Increment key index
        shift # Increment value index
        ;;
        -*|--*)
        SAVED_KWARGS+=("$1" "$2")
        shift # Increment key index
        shift # Increment value index
		;;
		*)
		POSITIONAL_ARGS+=("$1") # save positional arg
		shift # past argument
		;;
    esac
    done

    set -- "${SAVED_KWARGS[@]}"

    while [[ $# -gt 0 ]]; do
    case $1 in 
        --iosurfaceDowngrade)
        local ALLOWED_VALUES=("10.14" "10.15")
        if [[ ! " ${ALLOWED_VALUES[@]} " =~ " $2 " ]]; then
            echo "Invalid value for $1. Allowed values: ${ALLOWED_VALUES[@]}"
            exit 1
        fi
        echo "Selected $FRAMEWORK downgrade: $2"
        mkdir -p $OUTDIR/Temp/$FRAMEWORK
        printf "$2" > $OUTDIR/Temp/$FRAMEWORK/buildSettings.${1#--}.data
        shift # Increment key index
        shift # Increment value index
        exit 2
        ;;
    esac
    done

    set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters
}
argparse "$@"
