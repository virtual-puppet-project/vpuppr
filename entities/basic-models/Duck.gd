extends BasicModel

var is_blinking: bool = false
var current_animation: String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	$DuckMovement.play("Idle")

###############################################################################
# Connections                                                                 #
###############################################################################

###############################################################################
# Private functions                                                           #
###############################################################################

###############################################################################
# Public functions                                                            #
###############################################################################

func blink() -> void:
	current_animation = $AnimationPlayer.current_animation
	$AnimationPlayer.play("Blink")
	is_blinking = true

func unblink() -> void:
	$AnimationPlayer.play(current_animation)
	is_blinking = false

func change_expression_to(expression_type: int) -> void:
	match expression_type:
		ExpressionTypes.DEFAULT:
			$AnimationPlayer.play("Default")
		ExpressionTypes.HAPPY:
			$AnimationPlayer.play("Happy")
		ExpressionTypes.SAD:
			$AnimationPlayer.play("Blink")
		ExpressionTypes.ANGRY:
			$AnimationPlayer.play("Angry")
		ExpressionTypes.SHOCKED:
			$AnimationPlayer.play("Shocked")
		ExpressionTypes.BASHFUL:
			$AnimationPlayer.play("Bashful")
		_:
			print_debug("Expression not handled")
