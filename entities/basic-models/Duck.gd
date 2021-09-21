extends BasicModel

enum ExpressionTypes { DEFAULT, HAPPY, ANGRY, SAD, SHOCKED, BASHFUL }

var blink_threshold: float = 0.3
var is_blinking: bool = false
var current_animation: String

onready var animation_player: AnimationPlayer = $AnimationPlayer

###############################################################################
# Builtin functions                                                           #
###############################################################################

func _ready() -> void:
	has_custom_update = true
	animation_player.play("Default")
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

func custom_update(tracking_data: TrackingData, _interpolation_data: InterpolationData) -> void:
	if not is_blinking:
		if(tracking_data.get_left_eye_open_amount() < blink_threshold and tracking_data.get_right_eye_open_amount() < blink_threshold):
			blink()
	elif is_blinking:
		if(tracking_data.get_left_eye_open_amount() > blink_threshold and tracking_data.get_right_eye_open_amount() > blink_threshold):
			unblink()

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
			animation_player.play("Default")
		ExpressionTypes.HAPPY:
			animation_player.play("Happy")
		ExpressionTypes.SAD:
			animation_player.play("Blink")
		ExpressionTypes.ANGRY:
			animation_player.play("Angry")
		ExpressionTypes.SHOCKED:
			animation_player.play("Shocked")
		ExpressionTypes.BASHFUL:
			animation_player.play("Bashful")
		_:
			print_debug("Expression not handled")
