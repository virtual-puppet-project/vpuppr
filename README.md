# Virtual Streamer Software (VSS)

Forked from the original [openseeface-gd](https://github.com/you-win/openseeface-gd) project since multiple tracking backends are supported.

# TODO update the rest of the README

Special thanks to the [V-Sekai](https://github.com/V-Sekai) team for their help with `.vrm` importing.

![](demo.gif)

All models should work as long as they are in `.glb` or `.vrm` format. `.gltf` have not been tested but might work. `.tscn` files created with Godot should all import correctly as well.

## Supported tracking backends
- [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace)
- Mouse tracking (WIP)

## Quickstart
1. Download the latest release
2. Unzip all files into a directory (do not move any of the files)
3. Run the `.exe`
4. Start the facetracker from within the application

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
4. Run the facetracker via Python or via the binary if on Windows
5. Run the project

## Discussion
A Discord server [is available here](https://discord.gg/6mcdWWBkrr) if you need help, like to contribute, or just want to chat.

## Known bugs
- after stopping the facetracker, if you don't wait long enough for the facetracker listener to stop, the program can crash on close. Probably, this is hard to reproduce
- the facetracker is not automatically closed when the program crashes

## Work notes
- [x] basic OpenSeeFace visualization
- [x] map data to a rigged, non-vrm model
- [x] make rigged, non-vrm models lean based on translation
- [x] load vrm models 
- [x] map data to a vrm model
- [ ] support Live2D-style sprites
- [ ] make the raw OpenSeeFace visualization loadable
- [ ] create relay server so you can pull in other people's tracking data alongside your own (display 2+ models at once)

