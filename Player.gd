extends Node3D

@export var move_speed: float = 3.0
@export var rotate_speed: float = 2.5
@export var orthographic_size: float = 8.0

const CAMERA_OFFSET := Vector3(6.0, 6.0, 6.0)

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	camera.top_level = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = orthographic_size
	_update_camera()


func _process(delta: float) -> void:
	_handle_rotation(delta)
	_handle_movement(delta)
	_update_camera()


func _handle_rotation(delta: float) -> void:
	var turn_input := Input.get_axis("rotate_right", "rotate_left")

	if is_zero_approx(turn_input):
		return

	rotate_y(turn_input * rotate_speed * delta)


func _handle_movement(delta: float) -> void:
	var move_direction := Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		move_direction -= global_transform.basis.z
	if Input.is_action_pressed("move_backward"):
		move_direction += global_transform.basis.z
	if Input.is_action_pressed("move_left"):
		move_direction -= global_transform.basis.x
	if Input.is_action_pressed("move_right"):
		move_direction += global_transform.basis.x

	move_direction.y = 0.0

	if move_direction.is_zero_approx():
		return

	global_position += move_direction.normalized() * move_speed * delta


func _update_camera() -> void:
	camera.global_position = global_position + CAMERA_OFFSET
	camera.look_at(global_position, Vector3.UP)
	camera.size = orthographic_size
