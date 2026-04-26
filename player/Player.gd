@tool
extends Node3D

@export var move_speed: float = 3.0
@export var mouse_sensitivity: float = 0.0025
@export var gamepad_look_sensitivity: float = 3.0
@export var weapon_sway_amount: float = 0.0025
@export var weapon_sway_limit: float = 0.04
@export var weapon_sway_speed: float = 5.0
@export var ads_tween_duration: float = 0.12

@onready var camera: Camera3D = $Camera3D
@onready var viewmodel_viewport: SubViewport = $ViewmodelLayer/ViewmodelContainer/ViewmodelViewport
@onready var viewmodel_camera: Camera3D = $ViewmodelLayer/ViewmodelContainer/ViewmodelViewport/ViewmodelCamera
@onready var weapon_mount: WeaponMount = $ViewmodelLayer/ViewmodelContainer/ViewmodelViewport/ViewmodelCamera/WeaponMount
@onready var interact_ray: RayCast3D = $Camera3D/RayCast3D
@onready var reticle: Sprite2D = $ViewmodelLayer/Sprite2D

var camera_pitch := 0.0
var weapon_rest_rotation := Vector3.ZERO
var weapon_sway_target := Vector3.ZERO
var current_selected_prop: Node = null
var default_camera_fov := 0.0
var default_viewmodel_camera_fov := 0.0
var is_iron_sights_active := false
var ads_fov_tween: Tween

#region Runtime Logic

func _ready() -> void:
	print("RUNNING...")
	weapon_rest_rotation = weapon_mount.rotation
	default_camera_fov = camera.fov
	default_viewmodel_camera_fov = viewmodel_camera.fov
	# Match weapon's camera to main camera
	_sync_viewmodel_camera()

	# Disable mouse input
	# if rendered in editor
	if not Engine.is_editor_hint():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_viewmodel_camera()
		return

	_handle_movement(delta)
	_update_iron_sights()
	_handle_gamepad_look(delta)
	_update_weapon_sway(delta)
	_sync_viewmodel_camera()

func _physics_process(delta: float) -> void:
	var hit_prop := _get_hit_selectable_prop()
	if hit_prop != current_selected_prop:
		if current_selected_prop != null:
			current_selected_prop.set_selected(false)

		current_selected_prop = hit_prop

		if current_selected_prop != null:
			current_selected_prop.set_selected(true)

#endregion

#region Godot Built-Ins

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	if event.is_action_pressed("menu"):
		_toggle_mouse_capture()
		return

	if event.is_action_pressed("toggle_weapon"):
		cycle_weapon_viewmodel()
		return

	if event.is_action_pressed("select"):
		_handle_select()
		return

	if event is InputEventMouseMotion:
		_handle_mouse_look(event.relative)

#endregion


func _get_hit_selectable_prop() -> Node:
	if not interact_ray.is_colliding():
		return null

	var collider := interact_ray.get_collider()

	if collider == null:
		return null

	var node := collider as Node

	while node != null:
		if node.is_in_group("selectable_prop"):
			return node

		node = node.get_parent()

	return null

func _handle_select() -> void:
	if current_selected_prop == null:
		return

	if current_selected_prop.has_method("pickup"):
		var selected_prop := current_selected_prop
		current_selected_prop = null
		selected_prop.pickup(self)

func _update_iron_sights() -> void:
	var should_aim := Input.is_action_pressed("iron_sights") and _equipped_viewmodel_can_aim()
	reticle.visible = not should_aim
	if should_aim == is_iron_sights_active:
		return
	
	is_iron_sights_active = should_aim
	_apply_iron_sights_state()

func _equipped_viewmodel_can_aim() -> bool:
	var equipped_viewmodel := weapon_mount.equipped_viewmodel
	return equipped_viewmodel != null and equipped_viewmodel.has_method("set_aiming")

func _apply_iron_sights_state() -> void:
	var equipped_viewmodel := weapon_mount.equipped_viewmodel
	var fov_delta := 0.0
	var tween_duration := ads_tween_duration

	if equipped_viewmodel != null:

		if equipped_viewmodel.has_method("set_aiming"):
			equipped_viewmodel.set_aiming(is_iron_sights_active)

		if equipped_viewmodel.has_method("get_ads_tween_duration"):
			tween_duration = equipped_viewmodel.get_ads_tween_duration()

		if is_iron_sights_active and equipped_viewmodel.has_method("get_ads_fov_delta"):
			fov_delta = equipped_viewmodel.get_ads_fov_delta()

	if ads_fov_tween != null:
		ads_fov_tween.kill()

	ads_fov_tween = create_tween()
	ads_fov_tween.set_parallel(true)
	ads_fov_tween.tween_property(camera, "fov", default_camera_fov + fov_delta, tween_duration)
	ads_fov_tween.tween_property(viewmodel_camera, "fov", default_viewmodel_camera_fov + fov_delta, tween_duration)

func _handle_mouse_look(mouse_delta: Vector2) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	_apply_look_delta(mouse_delta, mouse_sensitivity)
	_set_weapon_sway_target(mouse_delta)

func _handle_gamepad_look(delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	var look_axis := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if look_axis.is_zero_approx():
		return

	var look_delta := look_axis * delta
	var sway_delta := look_delta * (gamepad_look_sensitivity / mouse_sensitivity)
	_apply_look_delta(look_delta, gamepad_look_sensitivity)
	_set_weapon_sway_target(sway_delta)

func _apply_look_delta(look_delta: Vector2, sensitivity: float) -> void:
	rotate_y(-look_delta.x * sensitivity)

	# Pitch only the camera so the player's movement stays level on the floor.
	camera_pitch = clamp(camera_pitch - look_delta.y * sensitivity, -PI * 0.45, PI * 0.45)
	camera.rotation.x = camera_pitch
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

#region Weapon Viewport Logic

func _sync_viewmodel_camera() -> void:
	viewmodel_camera.global_transform = camera.global_transform

func equip_weapon_viewmodel(scene: PackedScene) -> void:
	weapon_mount.equip_viewmodel(scene)
	_update_iron_sights()

func acquire_weapon_viewmodel(scene: PackedScene) -> void:
	if not weapon_mount.available_viewmodel_scenes.has(scene):
		weapon_mount.available_viewmodel_scenes.append(scene)

	equip_weapon_viewmodel(scene)

func cycle_weapon_viewmodel() -> void:
	weapon_mount.cycle_viewmodel()
	_update_iron_sights()

#endregion


#region  Weapon Sway

func _set_weapon_sway_target(mouse_delta: Vector2) -> void:
	var sway_x: float = clamp(-mouse_delta.y * weapon_sway_amount, -weapon_sway_limit, weapon_sway_limit)
	var sway_y: float = clamp(-mouse_delta.x * weapon_sway_amount, -weapon_sway_limit, weapon_sway_limit)
	weapon_sway_target = Vector3(sway_x, sway_y, 0.0)

func _update_weapon_sway(delta: float) -> void:
	var weight := 1.0 - exp(-weapon_sway_speed * delta)
	weapon_mount.rotation = weapon_mount.rotation.lerp(weapon_rest_rotation + weapon_sway_target, weight)
	weapon_sway_target = weapon_sway_target.lerp(Vector3.ZERO, weight)

#endregion
