class_name SignalPayload
extends Reference

## Used for sending collections over pubsub with an identifier so that the
## element that was changed can be determined. The only collections that
## this handles are Arrays and Dictionaries.
##
## Can also be used for regular pieces of data, but those can actually
## be sent over pubsub directly
##
## @example:
## Given [1, 2, 3]
## and the collection is changed to [1, 4, 3]
## then the identifer will be 1

var data 
var id
var signal_name := ""

func _init(p_signal_name: String, p_data, p_id = null) -> void:
	data = p_data
	id = p_id
	signal_name = p_signal_name

	# Verify the id type if applicable
	match typeof(data):
		# Vectors must be accessed by index
		TYPE_ARRAY:
			if typeof(id) != TYPE_INT:
				AM.logger.error("Invalid id for %s" % _to_string())
		# Dictionaries must always use String keys
		TYPE_DICTIONARY:
			if typeof(id) != TYPE_STRING:
				AM.logger.error("Invalid id for %s" % _to_string())

func _to_string() -> String:
	return JSON.print({
		"data": str(data),
		"id": str(id) if id != null else "null",
		"signal_name": signal_name
	}, "\t")

func get_changed():
	match typeof(data):
		TYPE_ARRAY, TYPE_DICTIONARY:
			return data[id]
		_:
			return data
