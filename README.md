# Virtual Puppet Project: Puppeteer (VPupPr)

[![Chat on Discord](https://img.shields.io/discord/853476898071117865?label=chat&logo=discord)](https://discord.gg/6mcdWWBkrr)

All models should work as long as they are in `.glb` or `.vrm` format. `.gltf` has not been tested but might work. `.scn` files created with Godot should all import correctly as well.

## Available renderers
* [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace)

## Prerequisites (Linux only)
* Python 3.6 - Python 3.9 (at time of writing, `onnxruntime` isn't compatible with Python 3.10)
* If your distro doesn't supply older versions of python, use `ort-nightly` for the time being.
* `python3-pip` and `python3-venv` are installed
## Installing dependencies, creating env. (Linux only)
* Python 3.6 - 3.9: 
* `pip install onnxruntime opencv-python pillow numpy`
* Python 3.10 and above:
* Create the virtual environment
* `cd ~/.local/share/godot/app_userdata/OpenSeeFaceGD`
* `python -m venv venv`
* `source venv/bin/activate`
* `python -m pip install ort-nightly opencv-python pillow numpy`

## Quickstart

### Windows
1. Download the latest release
2. Unzip all files into a directory (do not move any of the files)
3. Run the `.exe` on Windows
4. Start the facetracker from within the application

### Linux
1. Download the latest release
2. Unzip all files into a directory (do not move any of the files)
3. Run `chmod +x <binary name>` in a terminal to make the binary executable
4. Run the binary
5. Start the facetracker from within the application

## Building from source
1. TODO

## Special thanks
* [V-Sekai](https://github.com/V-Sekai) team for their help with `.vrm` importing
* [emilianavt](https://github.com/emilianavt) for their [OpenSeeFaceSample](https://github.com/emilianavt/OpenSeeFaceSample)
