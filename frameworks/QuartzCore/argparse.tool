#!/bin/bash

# Exit status 0 | Argument not found or invalid
# Exit status 1 | Argument is boolean
# Exit status 2 | Argument is option with input

while [[ $# -gt 0 ]]; do
case $1 in 
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
    --qcDowngrade)
    export QC_DOWNGRADE="$2"
    shift # Increment key index
    shift # Increment value index
    return 2
    ;;
    -*|--*)
    return 0
    ;;
    *)
    return 0
    ;;
esac
done


# QUARTZCORE_ALLOWED_ARGUMENTS=("--qcDowngrade")

# if [[ ! " ${QUARTZCORE_ALLOWED_ARGUMENTS[@]} " =~ " $1 " ]]; then
#     exit 0
# fi

# QUARTZCORE_DOWNGRADE_ALLOWED_VALUES=("10.14" "10.15" "11")
# echo $1
# if [[ "$1" == "--qcDowngrade" ]]; then
#     if [[ ! " ${QUARTZCORE_DOWNGRADE_ALLOWED_VALUES[@]} " =~ " $2 " ]]; then
#         echo "Invalid value for --qcDowngrade. Allowed values: ${QUARTZCORE_DOWNGRADE_ALLOWED_VALUES[@]}"
#         exit 0
#     fi

#     printf "$2" > $OUTDIR/Temp/QuartzCore/buildSettings.qcDowngrade.data
#     echo "Selected QuartzCore downgrade: $2"
#     exit 1
# fi

# exit 0