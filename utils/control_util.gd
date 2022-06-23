class_name ControlUtil
extends Reference

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#

static func h_expand_fill(control: Control) -> void:
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL

static func v_expand_fill(control: Control) -> void:
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL

static func all_expand_fill(control: Control) -> void:
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL
