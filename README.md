# Vpuppr

VTuber software made with Godot.

Godot 4 rewrite in progress.

## Status

- [x] VRM model loading
- [ ] Receive tracking data
- [ ] Map tracking data onto a VRM model

## Building From Source

Prerequisites:

* Rust 1.70+
* Python 3.8+ (any 3.x version is probably fine)

Run `setup.sh` to:

* refresh gitsubmodules
* build `libvpuppr`
* copy `libvpuppr`'s `.gdextension` file into the main project

