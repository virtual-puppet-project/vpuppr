#!/bin/bash

set -e

source "$1venv/bin/activate"

python "$2" -c "$3" -F "$4" -v 0 -s 1 -P 1 --discard-after 0 --scan-every 0 --no-3d-adapt 1 --max-feature-updates 900 --ip "$5" --port "$6"
