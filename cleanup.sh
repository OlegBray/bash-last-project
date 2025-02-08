#! /bin/bash

shopt -s globstar dotglob

# Checking the last time the file was updated if outdated - delete
check_last_update_of_file(){
    last_modification_seconds=$(stat --format=%Y "$1")
    last_modification_days=$((($(date +%s) - last_modification_seconds) / 86400 ))
    if [ $last_modification_days -ge 17 ]; then
        echo $?
    fi
}

# Checking file size in MiB
get_file_size_in_mib(){
    size="$(stat --format=%s "$1")"
    size="$(( $size/1048576 ))"
}

# Asking user for confirmation and ensuring valid input
get_user_confirmation(){
    while true; do
        read -p "The file: $1  -  Is greater than 10 MiB, you sure to delete it?(yes/no): " answer
        case "$answer" in
            [Yy] | [Yy]es )
                echo "Attempting to delete..."
                rm -f "$1"
                echo "File: $1 - Was deleted successfully."
                break
                ;;
            [Nn] | [Nn]o )
                echo "Skipping deletion of $1."
                break
                ;;
            * )
                echo "Invalid input. Please type 'yes' or 'no'."
                ;;
        esac
    done
}

paths_array=('/tmp' '/var/tmp' '/var/log')
bool="false"

if [[ -t 0 ]]; then
    if [[ $(id -u) -eq 0 ]]; then
        if [[ $ENV_MENU_FLAG == true ]]; then
            MIB_10=10
            echo "Starting cleanup proccess..."
            for dir in "${paths_array[@]}"; do
                cd $dir
                for file in "$dir"/**; do
                    if [ -f "$file" ]; then
                        get_file_size_in_mib "$file"
                        if [[ "$(check_last_update_of_file "$file")" -eq 0 ]]; then
                            if [[ $size -ge $MIB_10 ]]; then
                                echo "--------------------------------------------------------------"
                                get_user_confirmation "$file"
                                bool="true"
                            fi
                        fi
                    fi
                done
            done
            if [[ $bool == "false" ]]; then
                echo "Proccess finished - Nothing to clean."
            fi
        else
            echo "Unidentified Autherization - Make sure you runing the script from menu.sh"
        fi
    else
        echo "Permission denied - make sure you are root."
        exit 1
    fi
else
    for dir in "${paths_array[@]}"; do
        cd $dir
        for file in "$dir"/**; do
            if [ -f "$file" ]; then
                if [[ "$(check_last_update_of_file "$file")" -eq 0 ]]; then
                    echo "File: $file    - Deleted - Cause: Outdated & Unused."
                    rm -f $file
                fi
            fi
        done
    done
fi