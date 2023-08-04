- [日本語](README.ja.md)

# VRM addon for Godot Engine

This Godot addon fully implements an importer for models with the [VRM specification, version 0.0](https://github.com/vrm-c/vrm-specification/tree/master/specification/0.0).
Compatible with Godot Engine 4.0 stable or newer.

Proudly brought to you by the [V-Sekai team](https://v-sekai.org/about).

This package also includes a standalone full implementation of the MToon Shader for Godot Engine.

![Example of VRM Addon used to import two example characters](vrm_samples/screenshot/vrm_sample_screenshot.png)

IMPORT support for VRM 0.0 is fully supported. Retargeting for animation currently requires an external script.

## What is VRM?

See [https://vrm.dev/en/](https://vrm.dev/en/) (English) or [https://vrm.dev/](https://vrm.dev/) (日本語)

"VRM" is a file format for handling 3D humanoid avatar (3D model) data for VR applications.
It is based on [glTF 2.0](https://www.khronos.org/gltf/). Anyone is free to use it.

## What VRM Specification features are currently supported in Godot Engine?

* vrm.blendshape
  * binds / blend shapes: implemented (Animation tracks)
  * material binds: implemented (Animation tracks)
* vrm.firstperson
  * firstPersonBone: implemented (Metadata)
  * meshAnnotations / head shrinking: implemented (Animation method track `TODO_scale_bone`)
  * lookAt: implemented (Animation tracks)
* vrm.humanoid
  * humanBones: implemented (Metadata dictionary)
  * Unity HumanDescription values: **unsupported**
  * Automatic mesh retargeting: **planned**
  * humanBones renamer: **planned**
* vrm.material
  * shader
    * `VRM/MToon`: fully implemented
    * `VRM/UnlitTransparentZWrite`: fully implemented
    * `VRM_USE_GLTFSHADER` with PBR: fully implemented
    * `VRM_USE_GLTFSHADER` with `KHR_materials_unlit`: fully implemented
    * legacy UniVRM shaders (`VRM/Unlit*`): supported
    * legacy UniGLTF shaders (`UniGLTF/UniUnlit`, `Standard`): uses GLTF material
  * renderQueue: implemented (maps to render_priority; not consistent between models)
  * floatProperties, vectorProperties, textureProperties: implemented
* vrm.meta (Metadata, including License information and screenshot): implemented
* vrm.secondaryanimation (Springbone)
  * boneGroups: fully implemented (engine optimization patch is recommended)
  * colliderGroups: implemented (engine optimization patch is recommended)

EXPORT is completely unsupported. Support will be added using the Godot 4.x GLTF Export feature in the future

## Godot 4.x

VRM works in latest Godot master.

Caveat: Scenes with realtime omni or spot lights will have clustering artifacts, because there is no current way to detect if a given light is directional. After some missing variables are added, we can provide a way to detect this.

## Godot 3.x

For VRM compatible with Godot Engine 3.2.2 or later, use the `godot3` branch of this repository.

https://github.com/V-Sekai/godot-vrm

## How to use

Install the vrm addon folder into addons/vrm. MUST NOT BE RENAMED: This path will be referenced by generated VRM meta scripts.

Install Godot-MToon-Shader into addons/Godot-MToon-Shader. MUST NOT BE RENAMED: This path is referenced by generated materials.

Install the godot_gltf GDNative helper into addons/godot_gltf. MUST NOT BE RENAMED: The GDNative C++ code also hardcodes this path.

Enable the VRM and MToon plugins in Project Settings -> Plugins -> VRM and Godot-MToon-Shader.

## Credits

Thanks to the [V-Sekai team](https://v-sekai.org/about) and contributors:

- https://github.com/fire
- https://github.com/TokageItLab
- https://github.com/lyuma
- https://github.com/SaracenOne

For their extensive help testing and contributing code to Godot-VRM.

Special thanks to the authors of UniVRM, MToon and other VRM tooling

- The VRM Consortium ( https://github.com/vrm-c )
- https://github.com/Santarh
- https://github.com/ousttrue
- https://github.com/saturday06
- https://github.com/FMS-Cat
