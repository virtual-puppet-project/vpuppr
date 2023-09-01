# Architecture

## Table of Contents

- [Overview](#overview)
    - [vpuppr](#vpuppr)
    - [libvpuppr](#libvpuppr)
    - [Modules Loaded at Runtime](#modules-loaded-at-runtime)
- [Important Data Structures](#important-data-structures)
- [Application Flow](#application-flow)

## Overview

Code is split into 3 parts:

1. vpuppr ([repo](https://github.com/virtual-puppet-project/vpuppr))
2. libvpuppr ([repo](https://github.com/virtual-puppet-project/libvpuppr))
3. Modules loaded at runtime

`vpuppr` and `libvpuppr` and directly developed by the [Virtual Puppet Project](https://github.com/virtual-puppet-project) and comprise the core functionality of `vpuppr`.

Item 3. consists of 3rd party mods that are _not_ endorsed by the developers.

### vpuppr

The main code behind vpuppr. The [Godot Engine](https://godotengine.org/) is used for all application
features like windowing, rendering, etc.

[GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html) and
[Godot Scenes](https://docs.godotengine.org/en/stable/classes/class_packedscene.html) are
used for:

- GUI programming
- Loading Godot resources
- Binding code to other code

Code that is called frequently or is logic-heavy should _not_ be written in GDScript but instead
moved to [libvpuppr](#libvpuppr). Exceptions are made on an adhoc basis.

### libvpuppr

The core library behind vpuppr. libvpuppr consists of code written in [Rust](https://www.rust-lang.org/)
and bound to vpuppr via [godot-rust/gdext](https://github.com/godot-rust/gdext).
libvpuppr adds core classes like `Logger` and `VrmPuppet` to Godot and thus are accessible from vpuppr.

As much code as possible should be written in Rust (and thus libvpuppr) for a few reasons, listed in
order of importance:

1. Rust's type system
2. More advanced language features than GDScript
3. Performance

[Unsafe Rust](https://doc.rust-lang.org/book/ch19-01-unsafe-rust.html) is _not_ a concern for this project
and will be used wherever necessary, within reason. If a feature is possible to implement in safe Rust
with a slight performance penalty, then the feature should be implemented in safe Rust.

### Modules Loaded at Runtime

There are 2 points within vpuppr where modules can be loaded at runtime:

1. Home screen post-initialization
2. Runner post-initialization

By default, vpuppr will look for modules at `user://mods/`. Mods will be passed a context
for their own initialization.

Mods are _not_ sandboxed by vpuppr and are loaded at the user's own risk.

## Important Data Structures

Important data structures for understanding how vpuppr works.

### Context

Contains resources loaded for a specific `Runner`. The `Context` handles setup and cleanup
for the `Runner` as well as facilitating data passing between different parts of the application.

### Runner

Contains resources for displaying a `Puppet`. At the very least, a camera and light source should
be provided. A `Puppet` is provided to a `Runner` during initialization.

### Puppet

A `Puppet` is something that tracking data can be applied to. Each `Puppet` provides logic
for applying tracking data from a `Tracker` onto the `Puppet`.

### GUI

A Graphical User Interface. Contains controls necessary for interacting with vpuppr.

Data works on a "pull" model rather than a "push" model. GUIs "pull" data from the `Context`
and update data on the `Context` rather than a "push" model where data updated as an event that is
received by other parts of the application.

### Tracker

Something that provides tracking data. A `Tracker` does _not_ define how to apply data to a `Puppet`.
A `Tracker` only provides data.

## Application Flow

The general application flow is as follows:

1. Splash
    - Used for preloading resources
    - No application logic should run
2. Home
    - Application data loaded
    - Home mods loaded
    - `Runner`s can be run
3. `Context`
    - Loads a `Runner`, `GUI`, and `Puppet`
    - `Puppet` is added to the `Runner`
    - Signals back to Home when loading is completed/fails
4. `Context` (again)
    - Home is unloaded
    - `Context` is added to the `SceneTree` and displays the `Runner` + `GUI`
5. React to user input
    - A user interacts with the `GUI` to start tracking or tweak `Puppet` parameters
    - Data is saved on the `Context`
6. Quit to main menu/quit app
    - Data on the `Context` is saved to the `user://` directory
    - All resources are unloaded
