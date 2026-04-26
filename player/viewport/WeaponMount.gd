extends Node3D
class_name WeaponMount

@export_flags_3d_render var viewmodel_render_layer := 2
@export var equipped_viewmodel_scene: PackedScene
@export var available_viewmodel_scenes: Array[PackedScene] = []

var equipped_viewmodel: Node3D


func _ready() -> void:
	_spawn_equipped_viewmodel(equipped_viewmodel_scene)


func equip_viewmodel(scene: PackedScene) -> Node3D:
	equipped_viewmodel_scene = scene
	return _spawn_equipped_viewmodel(scene)


func cycle_viewmodel() -> Node3D:
	if available_viewmodel_scenes.is_empty():
		return equipped_viewmodel

	var current_index := available_viewmodel_scenes.find(equipped_viewmodel_scene)
	var next_index := 0 if current_index == -1 else (current_index + 1) % available_viewmodel_scenes.size()
	return equip_viewmodel(available_viewmodel_scenes[next_index])


func clear_viewmodel() -> void:
	if equipped_viewmodel == null:
		return

	remove_child(equipped_viewmodel)
	equipped_viewmodel.queue_free()
	equipped_viewmodel = null


func _spawn_equipped_viewmodel(scene: PackedScene) -> Node3D:
	clear_viewmodel()

	if scene == null or not is_inside_tree():
		return null

	var instance := scene.instantiate()
	if instance is not Node3D:
		push_warning("WeaponMount requires scenes rooted with Node3D.")
		instance.free()
		return null

	equipped_viewmodel = instance as Node3D
	add_child(equipped_viewmodel)
	_apply_viewmodel_render_layer(equipped_viewmodel)
	return equipped_viewmodel


func _apply_viewmodel_render_layer(node: Node) -> void:
	if node is VisualInstance3D:
		(node as VisualInstance3D).layers = viewmodel_render_layer

	for child in node.get_children():
		_apply_viewmodel_render_layer(child)
