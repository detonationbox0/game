extends Node3D

@export var move_speed: float = 3.0
@export var mouse_sensitivity: float = 0.0025
@export var weapon_sway_amount: float = 0.0025
@export var weapon_sway_limit: float = 0.04
@export var weapon_sway_speed: float = 5.0

@onready var camera: Camera3D = $Camera3D
@onready var viewmodel_viewport: SubViewport = $ViewmodelLayer/ViewmodelContainer/ViewmodelViewport
@onready var viewmodel_camera: Camera3D = $ViewmodelLayer/ViewmodelContainer/ViewmodelViewport/ViewmodelCamera
@onready var weapon_mount: Node3D = $ViewmodelLayer/ViewmodelContainer/ViewmodelViewport/ViewmodelCamera/WeaponMount

var camera_pitch := 0.0
var weapon_rest_rotation := Vector3.ZERO
var weapon_sway_target := Vector3.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	weapon_rest_rotation = weapon_mount.rotation
	viewmodel_viewport.world_3d = get_viewport().world_3d
	_set_viewmodel_layer(weapon_mount)
	_sync_viewmodel_camera()


func _process(delta: float) -> void:
	_handle_movement(delta)
	_update_weapon_sway(delta)
	_sync_viewmodel_camera()


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
	_set_weapon_sway_target(mouse_delta)
	_sync_viewmodel_camera()


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


func _sync_viewmodel_camera() -> void:
	viewmodel_camera.global_transform = camera.global_transform


func _set_viewmodel_layer(node: Node) -> void:
	if node is VisualInstance3D:
		# Keep swapped weapon models visible only to the viewmodel camera.
		(node as VisualInstance3D).layers = 2

	for child in node.get_children():
		_set_viewmodel_layer(child)


func _set_weapon_sway_target(mouse_delta: Vector2) -> void:
	var sway_x: float = clamp(-mouse_delta.y * weapon_sway_amount, -weapon_sway_limit, weapon_sway_limit)
	var sway_y: float = clamp(-mouse_delta.x * weapon_sway_amount, -weapon_sway_limit, weapon_sway_limit)
	weapon_sway_target = Vector3(sway_x, sway_y, 0.0)


func _update_weapon_sway(delta: float) -> void:
	var weight := 1.0 - exp(-weapon_sway_speed * delta)
	weapon_mount.rotation = weapon_mount.rotation.lerp(weapon_rest_rotation + weapon_sway_target, weight)
	weapon_sway_target = weapon_sway_target.lerp(Vector3.ZERO, weight)
