# Extension Data Descriptor <!-- omit in toc -->

The Extension Data Descriptor is a file that describes an extension. It can take
a few different forms.

## Table of Contents <!-- omit in toc -->

- [UI](#ui)
  - [GDScript](#gdscript)
  - [JSON](#json)
  - [TOML](#toml)
- [POD](#pod)
  - [GDScript](#gdscript-1)
  - [JSON](#json-1)
  - [TOML](#toml-1)

## UI

Describes how a UI element should be laid out. How the UI is parsed depends
on the file type.

All data will be returned as a Dictionary containing an optional `name` and required
`nodes` array.

##### Example <!-- omit in toc -->
```JSON
{
    "name": "MyNodeName",
    "nodes": [
        "my_node": Node.new()
    ]
}
```

### GDScript

In the `config.ini` file, new key called `data` will be added to an extension manifest.

The value must be set to a relative file path (relative to the extension's context path). If an
entrypoint is required, it must be added to the value, delimited by a ":" character.

e.g. `data="my_data.gd:get_data"`

The entire GDScript file is parsed and then loaded into an in-memory GDScript file. The GDScript file
**must** inherit from `Reference` so that it can be automatically cleaned up.

Note: if no `extends` delcaration is given, the entire script is assumed to extend `Reference`.

The only reserved variable name is `name` which is used as the node name for the resulting `Node`.

#### Entrypoint <!-- omit in toc -->

If an entrypoint is given, then `call(<entrypoint_name>)` will be executed on a new
instance of the file.

The result of the function call **must** be a `Dictionary<String, Node>`.

##### Example <!-- omit in toc -->
```GDScript
func run() -> Dictionary:
    return {
        "name": "NameOfTheResultingNode",
        "nodes": [
          "my_control": _some_control()
        ]
    }

func _some_control() -> Control:
    return Control.new()
```

#### No Entrypoint <!-- omit in toc -->

If no entrypoint is given, then `get_property_list()` will be executed on a new instance
of the file.

All irrelevant, built-in properties will be ignored. Every property must contain
something that inherits from `Node`.

##### Example <!-- omit in toc -->
```GDScript
var name := "NameOfTheResultingNode"

var my_control = _some_control()

var my_other_control = _other_control()

func _some_control() -> Control:
    return Control.new()

func _other_control() -> Control:
    return Control.new()
```

### JSON

A JSON file that describes a `Node` layout can be supplied.

Reserved keys include:
* `name`
  * The name of the node
* `type`
  * The type of the node to create
* `nodes`
  * Children nodes

Keys, not including reserved keys, must refer to exact node properties.

##### Example <!-- omit in toc -->
```JSON
{
    "name": "OptionalNameOfNode",
    "type": "NodeType",
    "nodes": [
        {
            "name": "OptionalExampleName",
            "type": "Control",
            "anchor_left": "0.0",
            "nodes": [

            ]
        },
        {
            "name": "OptionalLabelName",
            "type": "Label",
            "text": "Some label text"
        }
    ]
}
```

### TOML

TODO TBD

## POD

TODO Stub

### GDScript

TODO Stub

### JSON

TODO Stub

### TOML

TODO Stub
