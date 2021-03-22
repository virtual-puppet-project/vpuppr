# OpenSeeFace GD Edition

A Godot renderer for [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace). Special thanks to the [V-Sekai](https://github.com/V-Sekai) team for their help with `.vrm` importing.

![](demo.gif)

The receiver is located in `utils/OpenSeeGD.gd` and handles receiving OpenSeeFace packets and wrapping that information to be Godot-compatible. `screens/ModelDisplayScreen` handles the mapping and displaying of models. Heavily based on [OpenSeeFaceSample](https://github.com/emilianavt/OpenSeeFaceSample).

All models should work as long as they are in `.glb` or `.vrm` format. `.gltf` have not been tested but might work. `.tscn` files created with Godot should all import correctly as well.

## Quickstart
### Windows
1. Download the latest release
2. Unzip all files into a directory (do not move any of the files)
3. Run the `.exe`
4. Start the facetracker from within the application

### Mac/Linux
TODO add Mac/Linux release

Refer to the 'Building from source' instructions. The facetracker only has a compiled binary for Windows but should still be runnable on Mac/Linux via Python. Performance might be a problem but lowering the facetracker FPS and tweaking the model interpolation rate in the program should help.

### Controls
`Enter` or `Space`: Reset face tracking offsets

`Control` + `Left Click`: Spin the model

`Control` + `Right Click`: Move the model

`Control` + `Scroll`: Zoom the model in or out

`Control` + `Middle Click`: Reset the model's transform

`Shift` + `Left Click`/`Right Click`: Move left/right IK cube

`Shift` + `Left Click`/`Right Click` + `Scroll`: Move left/right IK cube on the z-axis

`Tab`: Toggle the UI

## Building from source
1. Clone my fork of [Godot](https://github.com/you-win/godot), branch 3.2-gltf (should be the default branch)
3. [Compile](https://docs.godotengine.org/en/stable/development/compiling/index.html) the engine
4. Clone this project and load it in the new Godot binary
5. Clone the [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace)
6. Run the facetracker via Python or via the binary if on Windows
7. Run the project

## Known bugs
- after stopping the facetracker, if you don't wait long enough for the facetracker listener to stop, the program can crash on close. Probably, this is hard to reproduce
- the facetracker is not automatically closed when the program crashes
- there is no way to get back to the default Duck model (the bundled `tscn` file is not bundled)

## Work notes
- [x] basic OpenSeeFace visualization
- [x] map data to a rigged, non-vrm model
- [x] make rigged, non-vrm models lean based on translation
- [x] load vrm models 
- [x] map data to a vrm model
- [ ] support Live2D-style sprites
- [ ] make the raw OpenSeeFace visualization loadable
- [ ] create relay server so you can pull in other people's tracking data alongside your own (display 2+ models at once)

