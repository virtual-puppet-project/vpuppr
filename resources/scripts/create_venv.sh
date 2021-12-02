#!/bin/bash

set -e

python_command=""

if python_command="$(type -p python3)"; then
    python_command="python3"
elif python_command="$(type -p python)"; then
    python_command="python"
else
    exit 1
fi

$python_command -m venv "$1venv"

source "$1venv/bin/activate"

pip install onnxruntime opencv-python pillow numpy
