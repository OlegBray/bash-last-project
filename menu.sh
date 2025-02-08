#! /bin/bash

runing_proceses_count(){
    count="$(ps -e | wc -l)"
    echo "Current procceses amount - $count"
}

export ENV_MENU_FLAG=true

if [ $(id -u) -eq 0 ]; then
    echo "Welcome $(id -un)"
    PS3='~Please select an option :'
    options=('Monitor' 'Cleanup' 'Backup' 'Amount of Proceses runing' 'Exit')
    select option in "${options[@]}"; do
        case $option in
        "${options[0]}")
        echo "--------------------------------------------"
        /usr/local/bin/monitor.sh
        echo "--------------------------------------------"
        ;;
        "${options[1]}")
        echo "--------------------------------------------"
        /usr/local/bin/cleanup.sh
        echo "--------------------------------------------"
        ;;
        "${options[2]}")
        echo "--------------------------------------------"
        /usr/local/bin/backup.sh
        echo "--------------------------------------------"
        ;;
        "${options[3]}")
        echo "--------------------------------------------"
        runing_proceses_count
        echo "--------------------------------------------"
        ;;
        "${options[4]}")
        exit 0
        ;;
        esac
    done
else
    echo "Permission denied - make sure you are root."
    exit 1
fi

