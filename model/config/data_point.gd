class_name DataPoint
extends Reference

const TYPE_KEY := "type"
const VALUE_KEY := "value"

var data_type: int
var data_value

func _init(dt: int, dv) -> void:
	data_type = dt
	data_value = dv

func get_as_dict() -> Dictionary:
	return {
		TYPE_KEY: data_type,
		VALUE_KEY: data_value
	}