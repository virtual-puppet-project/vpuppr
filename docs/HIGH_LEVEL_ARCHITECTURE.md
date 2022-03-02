# High Level Architecture <!-- omit in toc -->
## Preface <!-- omit in toc -->
Most resources can be added to the application without requiring a re-export of the entire application.
However, this will generally require a configuration file to be created that describes how the
resource should be treated/loaded/etc.

# Table of Contents <!-- omit in toc -->

The application is split into several parts:

- [Landing](#landing)
  - [Runners](#runners)
  - [Settings](#settings)
  - [About](#about)
- [Runner](#runner)
- [Model](#model)
- [Tracker](#tracker)
- [GUI](#gui)
- [Plugin](#plugin)

# Landing
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

# Runner
A Runner is a container for the [Model](#model) and all associated assets (e.g. lights, environement, etc).
The Runner helps pass data from a [Tracker](#tracker) to the Model and also helps with loading/unloading
models as well.

# Model
A Model represents a trackable entity, which in most cases is a `.glb` or `.vrm` model. Default implementations
for both are provided in the form of `BaseModel` and `VRMModel`.

# Tracker
A Tracker represents some sort of external input. In most cases, this will be from a tracking device like
a webcam.

# GUI
The GUI (Graphical User Interface) is used to manipulate a [Runner](#runner) and may or may not be local to
a given Runner. This allows for Runners to define their own GUIs or reuse and existing one.

# Plugin
Plugins extend the functionality of the application. These may be be written in `GDScript` or be bundled
as a `GDNativeLibrary` with [gdnative-runtime-loader](https://github.com/you-win/gdnative-runtime-loader).

Loading a Godot `.scn` file as a plugin is possible, but all resources in that `.scn` must be bundled.
If the resources are not bundled (not local) to that `.scn` file, then the resulting paths will be incorrect
upon distribution.
