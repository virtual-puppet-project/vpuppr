# Writing Custom Extensions <!-- omit in toc -->

This document will go over how to create a custom vpuppr extension from scratch. It will
be assumed that the developer has beginner-intermediate level knowledge of programming.

The extension that will be created in this document will be very simple but should showcase
how a developer would create an interactive extension for vpuppr.

## Table of Contents <!-- omit in toc -->

- [Example Extension Overview](#example-extension-overview)
- [Basic Extension Setup](#basic-extension-setup)
- [Creating the GUI](#creating-the-gui)
- [Creating the Confetti Emitter](#creating-the-confetti-emitter)

## Example Extension Overview

The extension to be created will be called `Confetti`.

The extension will have a GUI element that a user can interact with. All the extension will
do is generate some particle effects on screen when the user presses a button.

## Basic Extension Setup

The folder structure of an extension is very simple:

* resources/
  * extensions/
    * Confetti/ <-- our extension
      * `config.toml`
      * translations/
        * ... translation files for this extension ...
      * ... other extension files ...
    * ... other extensions ...

In the `config.toml` file, the following text should be present:

```TOML
[extension]
# The name of the extension in vpuppr
# Must be unique among all other extensions
name = "ConfettiExtension"
# An optional translation key to use when displaying this extension in the UI
translation-key = "CONFETTI_EXTENSION_NAME"

[[resources]]
# The name of a resource used by the extension
# Must be unique among resources in this extension
name = "Confetti"
# A tag to apply to the extension
# Used internally for auto-applying extensions to different parts of vpuppr
tags = ["gui"]
# The script to execute when the resource is loaded
entrypoint = "confetti_gui.gd"
# An optional translation key to use when displaying this extension in the UI
# Does not need to be unique
translation-key = "CONFETTI_EXTENSION_NAME"
# Whether this should be treated as a gdnative library
# Optional and defaults to false
gdnative = false
can-popup = true

[[resources]]
# Spaces are technically fine in the name but should be avoided
# Spaces will be used for demonstration purposes in this example
name = "Confetti Emitter"
tags = ["plugin"]
entrypoint = "emitter.gd"

# Other resources can be added using the same format
# [[resources]]

```

The above `toml` file can also be written as `json` if desired:

```JSON
{
    "extension": {
        "name": "ConfettiExtension",
        "translation-key": "CONFETTI_EXTENSION_NAME"
    },
    "resources": [
        {
            "name": "Confetti",
            "tags": ["gui"],
            "entrypoint": "confetti_gui.gd",
            "translation-key": "CONFETTI_EXTENSION_NAME",
            "gdnative": false,
            "can-popup": true
        },
        {
          "name": "Confetti Emitter",
          "tags": ["plugin"],
          "entrypoint": "emitter.gd"
        }
    ]
}
```

If using json, the `config.toml` file should be named `config.json` to ensure it
is parsed correctly.

## Creating the GUI

The GUI for this will be created via code rather than via a Godot `tscn` file. This is because
`tscn` files are not natively portable (their resources paths use absolute paths which
can be difficult to reconcile).

Under the `Confetti/` folder, create a file called `confetti_gui.gd`. Note that this matches
the `entrypoint` key defined in the `config.toml` file.

In the `confetti_gui.gd` file, use the following code:

```GDScript
# Most GUI elements should extend PanelContainer but any valid container node should be fine
extends PanelContainer

# Define a constant value so we can lookup our emitter later
# TCM stands for "TempCacheManager"
const TCM_KEY := "confetti_emitter"

# Create a logger that can be traced back to this GUI element
var logger := Logger.new("ConfettiGUI")

func _init() -> void:
	# Create a scroll container so the GUI can scroll up/down
	var sc := ScrollContainer.new()
	# Helper class for setting expand/fill flags
	ControlUtil.all_expand_fill(sc)

	# Adds the ScrollContainer as a child of this class, the PanelContainer
	add_child(sc)

	# GUI elements should be laid out top-to-bottom
	var vbox := VBoxContainer.new()
	ControlUtil.all_expand_fill(vbox)

	sc.add_child(vbox)

	var usage_label := Label.new()
	ControlUtil.h_expand_fill(usage_label)

	# Pull an appropriate translation from the extension's translation files
	usage_label.text = tr("CONFETTI_USAGE_LABEL_TEXT")

	vbox.add_child(usage_label)

	var confetti_button := Button.new()
	ControlUtil.h_expand_fill(confetti_button)

	confetti_button.text = tr("CONFETTI_SHOW_PARTICLES_BUTTON_TEXT")
	# Hover text can be applied using the hint_tooltip property
	confetti_button.hint_tooltip = tr("CONFETTI_HINT")

	vbox.add_child(confetti_button)

	var emitter

	# Persistent data/elements can be stored at runtime using vpuppr's TempCacheManager
	# It is good practice to manually cleanup data once it is no longer needed
	# Here, we are checking to see if there is already an emitter and using it if it exists
	var result := AM.tcm.pull(TCM_KEY)
	if result.is_err():
		# If the emitter does not exist, we create one
		result = AM.em.get_extension("ConfettiExtension")
		if result.is_err():
			logger.error("Unable to get Confetti extension")
			return
		
		var extension: Extension = result.unwrap()

		result = extension.load_resource("Confetti Emitter")
		if result.is_err():
			logger.error("Unable to load Emitter resource")
			return
		
		emitter = result.unwrap().new()
		# Store the emitter in the TempCacheManager and set it to auto-delete
		# when we navigate away from the current scene
		AM.tcm.push(TCM_KEY, emitter).cleanup_on_signal(Engine.get_main_loop().current_scene, "tree_exiting")
		# NOTE: This is technically a memory leak if it is not properly cleaned up
		Engine.get_main_loop().root.add_child(emitter)
	else:
		emitter = result.unwrap()
	
	# Remember to hook up the appropriate callbacks so that the GUI actually responds to user input
	# The emitter is passed as a parameter to the callback function
	confetti_button.connect("pressed", self, "_on_confetti_button_pressed", [emitter])

func _on_confetti_button_pressed(emitter) -> void:
	emitter.emit_confetti()
```

Because this is just a GDScript file, the usual functions and classes are also
available to the developer.

## Creating the Confetti Emitter

The code below should be placed into a file called `emitter.gd`. This creates a new
`CanvasLayer` and creates a new particle emitter when `emit_confetti` is called.

```GDScript
extends CanvasLayer

var active_particles := []

func _process(_delta: float) -> void:
	for p in active_particles:
		if not p.emitting:
			p.queue_free()

func emit_confetti() -> void:
	var particles = CPUParticles2D.new()
	particles.one_shot = true
	particles.emitting = true
	particles.lifetime = 3.0
	particles.scale *= 5
	
	particles.emission_shape = ParticlesMaterial.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 10.0
	particles.gravity = Vector2(0.0, 98.0)
	particles.linear_accel = 50.0
	particles.tangential_accel = 50.0
	particles.scale_amount = 5.0
	particles.scale_amount_random = 0.5
	particles.hue_variation = 1.0
	particles.hue_variation_random = 1.0

	particles.position = Vector2(randi() % int(OS.window_size.x), randi() % int(OS.window_size.y))

	add_child(particles)
```

## Creating the Translation Files

Under the translations folder under the `Confetti` extension folder, create a file called `en.txt`.
This will create a translation file for all English locales. Please reference i18 for the
relevant language codes if translations other than English are needed.

Inside of that file, paste the following translations:

```
CONFETTI_EXTENSION_NAME="Confetti!"

CONFETTI_HINT="This is a secret piece of text :)

New lines are possible here."

CONFETTI_USAGE_LABEL_TEXT="Create confetti on screen by clicking the button below!"

CONFETTI_SHOW_PARTICLES_BUTTON_TEXT="Spawn confetti"
```
