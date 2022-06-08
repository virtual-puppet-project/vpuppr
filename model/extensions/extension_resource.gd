class_name ExtensionResource
extends Reference

var extension_name := ""
var resource_name := ""
var resource_type := ""
## Absolute path to the entrypoint
var resource_entrypoint := ""
# This is set retroactively
var is_gdnative := false

var other := {}

func _init(p_extension_name: String, p_resource_name: String, p_type: String, p_entrypoint: String) -> void:
	extension_name = p_extension_name
	resource_name = p_resource_name
	resource_type = p_type
	resource_entrypoint = p_entrypoint
