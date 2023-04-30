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

## Controls

* spacebar - Calibrate your model. Useful when your camera is not directly in front of you
* escape - Show/hide the UI

## Quickstart

[Regular releases](https://github.com/virtual-puppet-project/vpuppr/releases) are available under Releases.

[Nightly releases](https://github.com/virtual-puppet-project/vpuppr/actions/workflows/nightly-release.yml) for
all supported operating systems are available via GitHub actions.

### Windows

1. Download the latest release
2. Unzip all files into a directory (do not move any of the files)
3. Run the `.exe`
4. Start the facetracker from within the application

### Linux

#### Flatpak

1. Ensure that [Flathub is enabled on your system](https://flatpak.org/setup/)
2. Using a graphical interface that supports Flatpak, search for "virtual puppet project"
   1. Alternatively, you can use `flatpak install vpuppr` to list any apps that have the same string
   * VPupPr will be available under the name `pro.vpup.vpuppr`
   * For the latest (alpha, beta) builds of VPupPr, you can download them from [Flathub Beta](https://beta.flathub.org/)
4. Hit the install button and run it just like any other app!

#### Gentoo (GURU)

vpuppr is available on the [GURU overlay for Gentoo](https://gitweb.gentoo.org/repo/proj/guru.git/tree/media-gfx/vpuppr).

1. Add the GURU overlay with either eselect-repository or layman
2. Sync and emerge vpuppr as normal 

#### Using a precompiled binary

1. Download the latest release
2. Unzip all files into a directory (do not move any of the files)
3. Run the binary
4. Start the facetracker from within the application

## Building from source

1. Clone or download this repository at the appropriate tag (or `master` for the latest commit)
   * This repository uses git submodules, so the `--recurse-submodules` flag will need to be passed in order to clone the submodules as well
2. Download a precompiled Godot editor binary from the [virtual-puppet-project's Godot fork](https://github.com/virtual-puppet-project/godot-builds/releases/tag/latest)
   * If you would rather compile the engine yourself, please see [the repo wiki page](https://github.com/virtual-puppet-project/vpuppr/wiki/1.-Building-the-Godot-Fork)
3. Download a precompiled Godot release template from the same repository in step 2
4. Run `python3 scripts/setup_extensions.py --setup` to setup extensions
5. Run the custom Godot editor and open your local copy of `vpuppr` with the editor
6. Follow the [Godot instructions for exporting a project](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html) and use the custom templates downloaded from step 3 instead of the default templates
7. Next to your resulting binary, copy the `resources` folder next to it. The `resources` folder is read at runtime

## Special thanks
* [V-Sekai](https://github.com/V-Sekai) team for their help with `.vrm` importing
* [emilianavt](https://github.com/emilianavt) for their [OpenSeeFaceSample](https://github.com/emilianavt/OpenSeeFaceSample)
