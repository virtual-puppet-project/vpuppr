extends BasicModel

enum ExpressionTypes { DEFAULT, HAPPY, ANGRY, SAD, SHOCKED, BASHFUL }

var is_blinking: bool = false
var current_animation: String

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	$DuckMovement.play("Idle")

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_1):
		change_expression_to(ExpressionTypes.DEFAULT)
	elif Input.is_key_pressed(KEY_2):
		change_expression_to(ExpressionTypes.HAPPY)
	elif Input.is_key_pressed(KEY_3):
		change_expression_to(ExpressionTypes.ANGRY)
	elif Input.is_key_pressed(KEY_4):
		change_expression_to(ExpressionTypes.SAD)
	elif Input.is_key_pressed(KEY_5):
		change_expression_to(ExpressionTypes.SHOCKED)
	elif Input.is_key_pressed(KEY_6):
		change_expression_to(ExpressionTypes.BASHFUL)

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
