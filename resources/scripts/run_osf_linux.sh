#!/bin/bash

set -e

python_command="$1"

if [ "$python_command" == "" ]; then
    for v in "" "3" "3.9" "3.8" "3.7" "3.6"; do
        if "python$v" --version 2> /dev/null | grep -E -q "[2-3]\.[0-9]\."; then
            python_command="python$v"
            break
        fi
    done
fi

if [ "$python_command" == "" ]; then
    exit 1
fi

source "$1venv/bin/activate"

$python_command "$3" -c "$4" -F "$5" -v 0 -s 1 -P 1 --discard-after 0 --scan-every 0 --no-3d-adapt 1 --max-feature-updates 900 --ip "$6" --port "$7"
