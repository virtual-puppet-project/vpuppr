class_name Prop
extends Spatial

var prop_path := ""

var offset := Transform()
var parent_offset := Transform()

func _init() -> void:
	pass

func _to_string() -> String:
	return JSON.print(get_as_dict(), "\t")

func get_as_dict() -> Dictionary:
	return {
		"prop_path": prop_path,
		"offset": offset,
		"parent_offset": parent_offset
	}
