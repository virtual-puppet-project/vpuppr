class_name EnvironmentUtil
extends RefCounted

const EnvironmentBackground := {
	TRANSPARENT = &"Transparent",
	CHROMAKEY = &"Chromakey",
}

#-----------------------------------------------------------------------------#
# Builtin functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions
#-----------------------------------------------------------------------------#

static func background_mode_enum_to_string(mode: int) -> StringName:
	match mode:
		Environment.BG_CLEAR_COLOR:
			return EnvironmentBackground.TRANSPARENT
		Environment.BG_COLOR:
			return EnvironmentBackground.CHROMAKEY
		_:
			AM.logger.error("Invalid background mode enum {mode}, using chromakey".format({
				mode = mode
			}))
			return EnvironmentBackground.TRANSPARENT

static func background_mode_string_to_enum(mode: StringName) -> int:
	match mode:
		EnvironmentBackground.TRANSPARENT:
			return Environment.BG_CLEAR_COLOR
		EnvironmentBackground.CHROMAKEY:
			return Environment.BG_COLOR
		_:
			AM.logger.error("Invalid background mode string {mode}, using chromakey".format({
				mode = mode
			}))
			return Environment.BG_CLEAR_COLOR
