#! /bin/bash

# Date
creation_date=$(date +"[ %a %b %d %H:%M:%S %Z %Y ]")

# Check os interface name
interface_check(){
    for iface in /sys/class/net/*; do
        if [[ -d "$iface/device" ]]; then
            interface="$(basename "$iface")"
        fi
    done
}

# CPU %
cpu_check(){
    read -ra statistics <<< $(vmstat | sed -n 3p)
    cpu_usage=${statistics[-4]}
    cpu_usage=$((100-cpu_usage))
    cpu_usage=$(python3 -c "print(f'{$cpu_usage}%')")
}

# Memory %
memory_check(){    
    ram_statistics=$(free | awk 'NR==2 {print $3/$2 * 100}')
    ram_statistics=$(python3 -c "print(f'{$ram_statistics :.2f}%')")
}

# Rx Tx
rx_tx_byte_check(){
    rx=$(cat "/sys/class/net/$1/statistics/rx_bytes")
    tx=$(cat "/sys/class/net/$1/statistics/tx_bytes")
}

cpu_comparison(){
    cpu_check
    last_cpu=$1
    count_cpu=$2
    if [ $count_cpu -eq 2 ]; then
        substring_cpu=${last_cpu:0:1}
    else
        substring_cpu=${last_cpu:0:2}
    fi
    count_trasform_cpu=${#cpu_usage}
    if [ $count_trasform_cpu -eq 2 ]; then
        transformed_current_cpu_usage=${cpu_usage:0:1}
    else
        transformed_current_cpu_usage=${cpu_usage:0:2}
    fi
}

# Red color
RED='\033[31m'
# Green color
GREEN='\033[32m'
# Orange color (simulated using bright yellow or a custom color code)
ORANGE='\033[38;5;214m'
# Reset color
RESET='\033[0m'

# Device Check
interface_check
if [[ -d "/sys/class/net/$interface/device" ]]; then
    if [[ -t 0 ]]; then # Interactive user, usage
        if [[ $(id -u) -eq 0 ]]; then
            if [[ $ENV_MENU_FLAG == true ]]; then
                if [ -e /var/log/monitor.log ]; then
                    # echo "DATE                           CPU RAM TX RX"    #  For check
                    read -ra last_statistics <<< "$(tail -n 1 /var/log/monitor.log)"
                    # echo ${last_statistics[@]}   #  For check
                    cpu_check
                    memory_check
                    rx_tx_byte_check "$interface"

                    cpu_comparison "${last_statistics[-4]}" "${#last_statistics[-4]}"

                    echo "Current system metrics:"
                    if [[ $substring_cpu -gt $transformed_current_cpu_usage ]]; then
                        echo -e "CPU usage: current - $cpu_usage trend - ${RED}rise${RESET}"
                    elif [[ $substring_cpu -eq $transformed_current_cpu_usage ]]; then
                        echo -e "CPU usage: current - $cpu_usage trend - ${ORANGE}hold${RESET}"
                    else
                        echo -e "CPU usage: current - $cpu_usage trend - ${GREEN}fall${RESET}"
                    fi
                    
                    echo -e "Memory usage: current - $ram_statistics trend - ${GREEN}fall${RESET}"
                    echo "Tx/Rx bytes: $tx/$rx"
                else
                    echo "Monitor.log doesn't exist."
                    echo "Wait for next cron operation to be executed."
                    echo "Or run bootstrap.sh, if no cron job exist."
                fi
            else
                echo "Unidentified Autherization - Make sure you runing the script from menu.sh"
                exit 1
            fi
        else
            echo "Permission denied - make sure you are root."
            exit 1
        fi
    else
        ( # Creating and redirecting data to log file
        cpu_check
        memory_check
        rx_tx_byte_check "$interface"
        new_line_for_log="$creation_date $cpu_usage $ram_statistics $tx $rx"
        if [ -e "/var/log/monitor.log" ]; then
            echo $new_line_for_log >> /var/log/monitor.log
        else
            headers="Date                         CPU%  RAM%  TX  RX"
            echo $headers >> /var/log/monitor.log
            echo $new_line_for_log >> /var/log/monitor.log
        fi
        ) 2>/dev/null
    fi
else
    read -ra last_statistics <<< "$(tail -n 1 /var/log/monitor.log)"
    # echo ${last_statistics[@]}   #  For check
    cpu_check
    memory_check
    rx_tx_byte_check "$interface"

    cpu_comparison "${last_statistics[-4]}" "${#last_statistics[-4]}"

    echo "Current system metrics:"
    if [[ $substring_cpu -gt $transformed_current_cpu_usage ]]; then
        echo -e "CPU usage: current - $cpu_usage trend - ${RED}rise${RESET}"
    elif [[ $substring_cpu -eq $transformed_current_cpu_usage ]]; then
        echo -e "CPU usage: current - $cpu_usage trend - ${ORANGE}hold${RESET}"
    else
        echo -e "CPU usage: current - $cpu_usage trend - ${GREEN}fall${RESET}"
    fi

    echo -e "Memory usage: current - $ram_statistics trend - ${GREEN}fall${RESET}"
    # echo "Tx/Rx bytes: $tx/$rx"
    echo "Tx/Rx bytes: NULL/NULL"
fi


