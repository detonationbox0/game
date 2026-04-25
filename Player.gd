extends Node3D

@export var move_speed: float = 3.0
@export var mouse_sensitivity: float = 0.0025

@onready var camera: Camera3D = $Camera3D

var camera_pitch := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	_handle_movement(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		_toggle_mouse_capture()
		return

	if event is InputEventMouseMotion:
		_handle_mouse_look(event.relative)


func _handle_mouse_look(mouse_delta: Vector2) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	rotate_y(-mouse_delta.x * mouse_sensitivity)

	# Pitch only the camera so the player's movement stays level on the floor.
	camera_pitch = clamp(camera_pitch - mouse_delta.y * mouse_sensitivity, -PI * 0.45, PI * 0.45)
	camera.rotation.x = camera_pitch


func _handle_movement(delta: float) -> void:
	var input_direction := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	if input_direction.is_zero_approx():
		return

	var move_direction := global_transform.basis.x * input_direction.x
	move_direction += global_transform.basis.z * input_direction.y
	global_position += move_direction.normalized() * move_speed * delta


func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
