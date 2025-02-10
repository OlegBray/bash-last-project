#! /bin/bash

list_of_files=("backup.sh" "cleanup.sh" "menu.sh" "monitor.sh")

crontab_validation(){
    cron_jobs=(
        "0 * * * * /usr/local/bin/monitor.sh" 
        "0 0 20,4 * * /usr/local/bin/backup.sh" 
        "0 0 1 * * /usr/local/bin/cleanup.sh"
    )

    echo "Updating cron..."
    for job in "${cron_jobs[@]}"; do

        current_crontab=$(crontab -l 2>/dev/null)

        [ -z "$current_crontab" ] && current_crontab=""

        echo "$current_crontab" | grep -Fq "$job"
        
        if [ $? -ne 0 ]; then
            
            if [ -z "$current_crontab" ]; then
                echo "$job" | crontab -
            else
                echo "$current_crontab" | (cat; echo "$job") | crontab -
            fi
        fi
    done


    echo "Cron updated."

    echo "Creating updated cron_tasks file..."
    touch ./cron_tasks
    crontab -l > "./cron_tasks"
    if [[ $? -eq 0 ]]; then
        echo "File created and updated successfuly."
    else
        echo "There was an issue updating file."
        exit 1
    fi
}


if [[ -t 0 ]]; then
    if [[ $(id -u) -eq 0 ]]; then
        for file in ${list_of_files[@]}; do
            install -m 755 $file "/usr/local/bin"
            echo "The file $file has been copied to /usr/local/bin"
        done
        crontab_validation

    else
        echo "Permission denied - make sure you are root."
        exit 1
    fi
fi

