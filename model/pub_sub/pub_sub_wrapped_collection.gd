class_name PubSubWrappedCollection
extends Reference

## Used for sending collections over pubsub with an identifier so that the
## element that was changed can be determined
##
## e.g.
## Given [1, 2, 3]
## and the collection is changed to [1, 4, 3]
## then the identifer will be 1

var collection
var identifier
var signal_name := ""

func _init(p_collection, p_identifier, p_signal_name: String) -> void:
	collection = p_collection
	identifier = p_identifier
	signal_name = p_signal_name

func get_changed():
	return collection[identifier] if identifier in collection else -1

func get_data():
	return collection
