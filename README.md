# Virtual Puppet Project (VPupPr)

[![Chat on Discord](https://img.shields.io/discord/853476898071117865?label=chat&logo=discord)](https://discord.gg/6mcdWWBkrr)

All models should work as long as they are in `.glb` or `.vrm` format. `.gltf` has not been tested but might work. `.scn` files created with Godot should all import correctly as well.

The project status is tracked via a public [GitHub project here](https://github.com/orgs/virtual-puppet-project/projects/1/views/2).

## Available trackers
* [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace)
* [iFacialMocap](https://www.ifacialmocap.com/)
* [Mouse tracker](https://github.com/virtual-puppet-project/mouse-tracker)
* [VTubeStudio](https://github.com/virtual-puppet-project/vtube-studio-tracker)
* [MeowFace](https://github.com/virtual-puppet-project/meowface-tracker)

*More trackers may be available in the future, such as [MediaPipe](https://google.github.io/mediapipe/)*

## Controls

* <spacebar> - Calibrate your model. Useful when your camera is not directly in front of you
* <escape> - Show/hide the UI

## Quickstart

### Windows
1. Download the latest release
2. Unzip all files into a directory (do not move any of the files)
3. Run the `.exe` on Windows
4. Start the facetracker from within the application

### Linux

#### Flatpak
1. Ensure that [Flathub is enabled on your system](https://flatpak.org/setup/)
2. Using a graphical interface that supports Flatpak, search for "virtual puppet project"
   1. Alternatively, you can use `flatpak install vpuppr` to list any apps that have the same string
   * VPupPr will be available under the name `com.github.virtual_puppet_project.vpuppr`
   * For the latest (alpha, beta) builds of VPupPr, you can download them from [Flathub Beta](https://beta.flathub.org/)
4. Hit the install button and run it just like any other app!

#### Using binaries from the [releases page](https://github.com/virtual-puppet-project/vpuppr/releases)
1. Download the latest release
2. Unzip all files into a directory (do not move any of the files)
3. Run `chmod +x <binary names>` in a terminal to make the app binaries executable.
   1. Do this for `vpuppr.x86_64` and `resources/extensions/open_see_face/OpenSeeFaceFolder/OpenSeeFace/facetracker`
4. Run the binary
5. Start the facetracker from within the application

## Building from source
1. Clone or download this repository at the appropriate tag (or `master` for the latest commit)
   * This repository uses git submodules, so the `--recurse-submodules` flag will need to be passed in order to clone the submodules as well
2. Download a precompiled Godot editor binary from the [virtual-puppet-project's Godot fork](https://github.com/virtual-puppet-project/godot/releases) <!-- TODO update this to use the godot-builds binaries once that is complete -->
   * If you would rather compile the engine yourself, please see [the section on compiling the Godot fork](#building-the-godot-fork)
3. Download a precompiled Godot release template from the same repository in step 2
4. Run the custom Godot editor and open your local copy of `vpuppr` with the editor
5. Follow the [Godot instructions for exporting a project](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html) and use the custom templates downloaded from step 3 instead of the default templates
6. Next to your resulting binary, copy the `resources` folder next to it. The `resources` folder is read at runtime
7. Each tracker has its own dependencies. In the [list of trackers](https://github.com/virtual-puppet-project/.github/blob/master/profile/README.md), see each tracker's README for build instructions. The dependencies will need to be placed in the `resources` folder in their appropriate path

<!--Gonna uncomment this for now, when the forks to build are all set up the instructions can be moved over -->

## Building the Godot fork
0. Make sure you have the following tools installed and available on your `PATH` if applicable:
   * `git`
   * `python3` (preferably version 3.10+)
   * [All the tools needed for compiling Godot](https://docs.godotengine.org/en/stable/development/compiling/introduction_to_the_buildsystem.html)
   * A `bash`-compatible prompt. Git Bash comes preinstalled with Git for Windows
1. Clone the following utility repositories:
   1. [godot](https://github.com/godotengine/godot)
   2. [godot-module-applier](https://github.com/virtual-puppet-project/godot-module-applier)
   3. [godot-build-scripts](https://github.com/virtual-puppet-project/godot-build-scripts)
2. Your directory structure should look like
   * ./
       * godot/
       * godot-module-applier/
       * godot-build-scripts/
3. Inside of the `godot/` directory, run `cp ../godot-module-applier/applier.py .` to copy the `applier.py` script into the `godot/` directory. Do the same for `modules_file.txt`
4. Inside of the `godot/` directory, run `python3 applier.py apply`. This will pull in and apply all modules, third-party sources, and patches to Godot
5. Inside of the `godot/` directory, run `cp ../godot-build-scripts/build-* .` to copy all build scripts into the `godot/` directory
6. Inside of the `godot/` directory, to build various versions of the editor do:
   * Editor: `./build-editor.sh`
   * Release template: `./build-normal-template.sh`
7. The compiled Godot binary will be available in the `godot/` directory under the `bin/` directory

<!-- These instructions are probably more fit for the Godot fork, than here. -->

## Special thanks
* [V-Sekai](https://github.com/V-Sekai) team for their help with `.vrm` importing
* [emilianavt](https://github.com/emilianavt) for their [OpenSeeFaceSample](https://github.com/emilianavt/OpenSeeFaceSample)
