# Vpuppr

[![Chat on Discord](https://img.shields.io/discord/853476898071117865?label=chat&logo=discord)](https://discord.gg/6mcdWWBkrr)

VTuber software made with Godot.

Godot 4 rewrite in progress.

The Godot 3 version is currently located on the `godot-3` branch.

## Status

General:

- [x] VRM model loading
- [x] Receive tracking data
- [x] Map tracking data onto a VRM model
- [ ] GUI
- [ ] Save data

Tracking

- [ ] [MediaPipe](https://github.com/google/mediapipe)
- [ ] [iFacialMocap](https://www.ifacialmocap.com/)
- [x] [MeowFace](https://play.google.com/store/apps/details?id=com.suvidriel.meowface)
- [ ] [VTube Studio](https://denchisoft.com/)
- [ ] [OpenSeeFace](https://github.com/emilianavt/OpenSeeFace)
- [ ] [Mouse tracking](https://github.com/virtual-puppet-project/mouse-tracker)
- [ ] [Lip sync](https://github.com/virtual-puppet-project/real-time-lip-sync-gd)

## Building From Source

Prerequisites:

* Godot 4.1.x
* Rust 1.70+
* Python 3.8+ (any 3.x version is probably fine)

Run `setup.sh` to:

* refresh gitsubmodules
* build `libvpuppr`
* copy `libvpuppr`'s `.gdextension` file into the main project

In order to build GDMP, follow the instructions in [that repo](https://github.com/j20001970/GDMP).

## Contributing

Please see [the document about contributing](CONTRIBUTING.md).

Various technical documents are stored under the `docs` directory.
