class_name ExtensionResource
extends Reference

var resource_name := ""
var resource_type := ""
var resource_entrypoint := ""

func _init(p_resource_name: String, p_type: String, p_entrypoint: String) -> void:
	resource_name = p_resource_name
	resource_type = p_type
	resource_entrypoint = p_entrypoint
