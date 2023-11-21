class_name Metadata
extends Resource

## App metadata.

const SAVE_PATH := "user://metadata.tres"

## Common options to be used as defaults across runners. Is initially null and
## is only set once the first runner is created. It can optionally be adjusted
## in the settings menu.
@export
var common_options: CommonOptions = null

## The last time the application was used.
@export
var last_used := Time.get_datetime_dict_from_system()

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

static func try_load() -> Metadata:
	if not FileAccess.file_exists(SAVE_PATH):
		return null
	
	return load(SAVE_PATH)

func try_save() -> Error:
	return ResourceSaver.save(self, SAVE_PATH)

## Update the [member last_used] value using the system datetime.
func timestamp() -> void:
	last_used = Time.get_datetime_dict_from_system()
