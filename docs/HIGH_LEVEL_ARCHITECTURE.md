# High Level Architecture <!-- omit in toc -->

## Table of Contents <!-- omit in toc -->

The application is split into two main parts:

1. [Built-ins](#built-ins)
2. [Extensions](#extensions)

With the full table of contents being:

- [Built-ins](#built-ins)
  - [Landing](#landing)
    - [Runners](#runners)
    - [Settings](#settings)
    - [About](#about)
  - [Configuration](#configuration)
    - [Metadata](#metadata)
    - [Model Config](#model-config)
  - [Manager Singletons](#manager-singletons)
- [Extensions](#extensions)
  - [Runner](#runner)
  - [Model](#model)
  - [Tracker](#tracker)
  - [GUI](#gui)
  - [Plugin](#plugin)
  - [Resource Config](#resource-config)

# Built-ins
Any changes made to these will require a re-export of the entire application.

## Landing
This is the first page that user will see upon starting the application. This is configurable and the
user can instead load straight into a [Viewer](#viewer) instead.

There are three main tabs available on the Landing screen (other tabs may be available via [Plugins](#plugins)):

- [Runners](#runners)
- [Settings](#settings)
- [About](#about)

### Runners
Each configured runner for the current OS is listed here. When a runner is selected, the scene will
change to the selected runner.

More runners can be added without requiring a re-export of the application as a whole.

### Settings
Various metadata-related settings are configurable here. This includes the ability to select a default runner
to load into on application start.

### About
Data about the authors and associated projects are stored here.

## Configuration
There are two main types of configuration files in use:

1. [Metadata](#metadata)
2. [Model Config](#model-config)

### Metadata
Metadata stores data about all Model Config files along with application-wide information.

### Model Config
A Model Config is created per model. Additional Model Configs can be created for the same model, in which case a default Model Config can be configured.

This generally stores model-specific data like bone positions.

## Manager Singletons
There are various manager singletons in use. The primary singleton is the `AppManager` which manages the other
singletons.

These are singletons in the Godot-sense, as in there is nothing stopping a [Plugin](#plugin) from creating
another instance of the `AppManager`. This is generally a bad idea to do in practice.

# Extensions
Changes to any of these do not require a re-export of the application. However, a configuration file will
be required to register any new resource.

## Runner
A Runner is a container for the [Model](#model) and all associated assets (e.g. lights, environement, etc).
The Runner helps pass data from a [Tracker](#tracker) to the Model and also helps with loading/unloading
models as well.

## Model
A Model represents a trackable entity, which in most cases is a `.glb` or `.vrm` model. Default implementations
for both are provided in the form of `PuppetTrait` and `VRMModel`.

## Tracker
A Tracker represents some sort of external input. In most cases, this will be from a tracking device like
a webcam.

## GUI
The GUI (Graphical User Interface) is used to manipulate a [Runner](#runner) and may or may not be local to
a given Runner. This allows for Runners to define their own GUIs or reuse and existing one.

## Plugin
Plugins extend the functionality of the application. These may be be written in `GDScript` or be bundled
as a `GDNativeLibrary` with [gdnative-runtime-loader](https://github.com/you-win/gdnative-runtime-loader).

Loading a Godot `.scn` file as a plugin is possible, but all resources in that `.scn` must be bundled.
If the resources are not bundled (not local) to that `.scn` file, then the resulting paths will be incorrect
upon distribution.

## Resource Config
A resource config is an `.ini` file that describes how the runtime-loadable resource should be handled
by the application.

There is only one required section and field:
* General
  * Name
    * The canonical name of the plugin overall. This is used to refer to the plugin globally

Other sections will be regarded as describing plugin functionality (e.g. Runner, Model, etc).

The required fields for other keys are:
* Type
  * The intended type for the resource
  * e.g. `runner`, `model`, etc
* Entrypoint
  * The relative path to the script to use. This must be unique unless the `Type` is `plugin`
