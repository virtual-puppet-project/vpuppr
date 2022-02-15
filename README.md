# OpenSeeFace GD Edition

[![Chat on Discord](https://img.shields.io/discord/853476898071117865?label=chat&logo=discord)](https://discord.gg/6mcdWWBkrr)

A Godot renderer for [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace). Special thanks to the [V-Sekai](https://github.com/V-Sekai) team for their help with `.vrm` importing.

![](demo.gif)

The initial implementation was heavily based on [OpenSeeFaceSample](https://github.com/emilianavt/OpenSeeFaceSample).

All models should work as long as they are in `.glb` or `.vrm` format. `.gltf` has not been tested but might work. `.scn` files created with Godot should all import correctly as well.

## Prerequisites (Linux only)
* Python 3.6 - Python 3.9 (at time of writing, `onnxruntime` isn't compatible with Python 3.10)
* `python3-pip` and `python3-venv` are installed

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

### Controls
`Enter` or `Space`: Reset face tracking offsets

`Control` + `Left Click`: Spin the model

`Control` + `Right Click`: Move the model

`Control` + `Scroll`: Zoom the model in or out

`Control` + `Middle Click`: Reset the model's transform

`Tab`: Toggle the UI

## Building from source
1. Download Godot 3.4
2. Clone this project and load it in the editor
3. Clone the [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace) face tracker
4. If on Windows, move the `OpenSeeFace` repo into `$PROJECT_ROOT/export/OpenSeeFaceFolder`. If on Linux, run the facetracker via Python (currently only versions below 3.10 are supported)
5. Run the project from the editor
6. In the program, when starting face tracking and if you are running OpenSeeFace via Python, disable the option to have the program start the face tracker
7. Start face tracking
8. To export your own release binaries, you will need to use my patched version of Godot 3.4. Precompiled release templates can be downloaded from my [Godot fork](https://github.com/you-win/godot/releases/tag/3.3.2-gltf) (or compiled using `scons platform=<your platform> target=release tools=no use_module_gltf=yes -j<number of threads, no space between j>`

## Discussion
A Discord server [is available here](https://discord.gg/6mcdWWBkrr) if you need help, like to contribute, or just want to chat.
