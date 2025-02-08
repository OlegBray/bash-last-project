#! /bin/bash

# Checking Byte size of the folder before compressing
folder_size_check() {
    if [ $# -eq 1 ]; then
        if [ -d "$1" ]; then
            read -ra folder_size <<< "$(du -sb "$1" 2>/dev/null)"
        else
            echo "The directory '$1' does not exist."
            echo "--------------------------------------------"
        fi
    else
        echo "Please provide exactly one path."
        echo "--------------------------------------------"
    fi
}

# Checking avaible disk size in Bytes
avaible_disk_size(){
    free_disk_space="$(df -h --total '/' | grep 'total' | awk '{print $4}')"
    # echo $free_disk_space
}

# Conversion of bit to GB
turn_bit_to_gb(){
    size_in_GB=$(echo "scale=0; $1 / (8 * 1024^3)" | bc)
}

# Checking avaible size + redirecting relevant message to log file >> backup
backup_func(){
    turn_bit_to_gb "$1"

    free_space=${2:0:-1}

    if [[ $size_in_GB -lt $free_space ]]; then
    # if [[ $free_space -lt $size_in_GB ]]; then    # For check
        echo "Starting backup..."
        tar czf $3$4 --ignore-failed-read $5 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "Backup succeeded."
            echo "--------------------------------------------"
            echo "[$6] Backup successful." >> "$7"
        else
            echo "[$6] Something went wrong - Backup Failed." >> "$7"
        fi
    else
        
        source_size=$size_in_GB
        
        overall_size=$2
        echo "--------------------------------------------"
        echo "Back up Failed."
        echo "Source to zip: $source_size GB --- Free disk space: ${overall_size:0:-1} GB"
        echo "Not enough disk space."
        echo "--------------------------------------------"
        echo "[$6] Not enough disk space - Backup Failed." >> "$7"
    fi
}

# providing the last 5 avaible backups
last_avaible_backups(){
    echo "--------------------------------------------"
    if [ -e $1 ]; then
        cat $1 | tail -n 5
        echo "--------------------------------------------"
    else
        echo "The file doesnt exist"
        echo "--------------------------------------------"
    fi
}

# Checking every file creation time and removing files above 7 days lifetime.
check_validation(){
    directory="/opt/sysmonitor/backups/"
    current_time=$(date +"%s")
    find "$directory" -type f | while read -r file; do
        file_creation_time=$(stat --format='%W' "$file")
        if [ "$file_creation_time" -eq 0 ]; then
            file_creation_time=$(stat --format='%Y' "$file")
        fi

        days_diff=$(( ($current_time - $file_creation_time) / 86400 ))

        if [ "$days_diff" -gt 7 ]; then
            echo "The file: $file deleted."
            rm $file
        fi
    done
}

if [[ -t 0 ]]; then
    if [[ $ENV_MENU_FLAG == true ]]; then
        if [[ $(id -u) -eq 0 ]]; then

            source_path="/home"
            backup_path="/opt/sysmonitor/backups/"
            date_format=$(date +"%Y_%m_%d_%H_%M_%S")
            format="${date_format}_home_backup.tar.gz"
            log_file_path="/var/log/backup.log"
            mkdir -p $backup_path

            folder_size_check $source_path
            avaible_disk_size

            PS3='~Select an option: '
            options=('Manual Backup' 'Check latest 5 backups avaible' 'Back to previous Menu')
            select option in "${options[@]}"; do
                case $option in
                "${options[0]}")
                backup_func "${folder_size[0]}" "$free_disk_space" "$backup_path" "$format" "$source_path" "$date_format" "$log_file_path"
                ;;
                "${options[1]}")
                last_avaible_backups "$log_file_path"
                ;;
                "${options[2]}")
                echo "-----------------------------"
                menu=('Monitor' 'Cleanup' 'Backup' 'Amount of Proceses runing' 'Exit')
                count=1
                for i in "${menu[@]}"; do
                    echo "$count) $i"
                    if [[ "$i" == "Exit" ]]; then
                        break
                    fi
                    count=$((count + 1))
                done
                exit 0
                ;;
                esac
            done
        else
            echo "Permission denied - make sure you are root."
            exit 1
        fi
    else
        echo "Unidentified Autherization - Make sure you runing the script from menu.sh"
        exit 1
    fi
else
    check_validation
fi

