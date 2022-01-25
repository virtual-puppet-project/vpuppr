#!/bin/bash

set -e

python_command=""

for v in "" "3" "3.9" "3.8" "3.7" "3.6"; do
    if "python$v" --version 2> /dev/null | grep -E -q "[2-3]\.[0-9]\."; then
        python_command="python$v"
        break
    fi
done

if [ "$python_command" == "" ]; then
    exit 1
fi

$python_command -m venv "$1venv"

source "$1venv/bin/activate"

pip install onnxruntime opencv-python pillow numpy
