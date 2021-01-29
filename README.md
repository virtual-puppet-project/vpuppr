# OpenSeeFace GD Edition

A Godot renderer for [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace).

The mapper is located in `utils/OpenSeeGD.gd` and handles receiving OpenSeeFace packets and mapping them to GDScript objects. Heavily based on [OpenSeeFaceSample](https://github.com/emilianavt/OpenSeeFaceSample).

An example non-vrm 3d model (made by yours truly for practice) is included for basic face tracking. Custom, non-vrm models can be imported and should theoretically work as long as:
- the `entities/basic-models/BasicModel.gd` script is added to the model
- the model is rigged

See `entities/basic-models/Person.tscn` for an example of how what an imported model should look like.

## Quickstart
Import the project in [Godot](https://godotengine.org/) (developed with version 3.2.3). Run the OpenSeeFace binary from the OpenSeeFace repo with the host set to `127.0.0.1` and port set to `11573`. Those should be the default values for OpenSeeFace. Run the default scene in Godot by pressing F5.

### Quickstart controls
`Enter` or `Space`: reset face tracking offsets

`Control` + `Left Click`: spin the model

`Control` + `Right Click`: move the model

`Control` + `Scroll`: zoom the model in or out

`Control` + `Middle Click`: reset the model

`Escape`: quit

## Work notes
- [x] basic OpenSeeFace visualization
- [x] map data to a rigged, non-vrm model
- [x] make rigged, non-vrm models lean based on translation
- [ ] load vrm models
- [ ] map data to a vrm model
- [ ] support Live2D-style sprites

Dynamic gltf loading:
editor_scene_importer_gltf.cpp -> import_scene() -> gltf_document.cpp -> parse() -> generate_mesh_instance()

