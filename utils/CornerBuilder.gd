@tool
extends Node3D

# See docs/math/geometry/low-poly-corner-approximation.qmd

@export var source_segment_scene: PackedScene
@export_range(1, 64, 1) var segment_count: int = 4
@export var total_angle_degrees: float = 90.0
@export var rebuild_corner := false:
	set(value):
		rebuild_corner = false

		if not value:
			return

		if not Engine.is_editor_hint():
			return

		_rebuild_corner()


func _rebuild_corner() -> void:
	if source_segment_scene == null:
		push_warning("CornerBuilder: Assign a source_segment_scene before rebuilding.")
		return

	if segment_count <= 0:
		push_warning("CornerBuilder: segment_count must be at least 1.")
		return

	var generated_root := _get_generated_root()
	var scene_root := get_tree().edited_scene_root

	for child in generated_root.get_children():
		child.free()

	var source_segment := source_segment_scene.instantiate() as Node3D

	if source_segment == null:
		push_warning("CornerBuilder: source_segment_scene must instantiate a Node3D.")
		return

	var segment_bounds := _get_combined_mesh_aabb(source_segment)

	if segment_bounds.size == Vector3.ZERO:
		push_warning("CornerBuilder: source segment scene needs at least one MeshInstance3D.")
		return

	var step_radians := deg_to_rad(total_angle_degrees) / float(segment_count)
	var current_rotation := 0.0
	var back_z := segment_bounds.end.z
	var front_z := segment_bounds.position.z
	var inner_x := segment_bounds.position.x if step_radians >= 0.0 else segment_bounds.end.x
	var back_inner_corner := Vector3(inner_x, segment_bounds.get_center().y, back_z)
	var front_inner_corner := Vector3(inner_x, segment_bounds.get_center().y, front_z)
	var current_anchor := Vector3.ZERO

	for i in segment_count:
		var segment := source_segment_scene.instantiate() as Node3D

		segment.name = "Segment_%02d" % i
		generated_root.add_child(segment)
		segment.owner = scene_root
		var basis := Basis.from_euler(Vector3(0.0, current_rotation, 0.0))
		var origin := current_anchor - (basis * back_inner_corner)
		segment.transform = Transform3D(basis, origin)

		current_anchor = segment.transform * front_inner_corner
		current_rotation += step_radians


func _get_generated_root() -> Node3D:
	var generated_root := get_node_or_null("Generated") as Node3D

	if generated_root != null:
		return generated_root

	generated_root = Node3D.new()
	generated_root.name = "Generated"
	add_child(generated_root)
	generated_root.owner = get_tree().edited_scene_root
	return generated_root


func _get_combined_mesh_aabb(root: Node3D) -> AABB:
	var mesh_aabbs: Array[AABB] = []
	_collect_mesh_aabbs(root, Transform3D.IDENTITY, mesh_aabbs)

	if mesh_aabbs.is_empty():
		return AABB()

	var combined := mesh_aabbs[0]

	for i in range(1, mesh_aabbs.size()):
		combined = combined.merge(mesh_aabbs[i])

	return combined


func _collect_mesh_aabbs(node: Node, parent_transform: Transform3D, mesh_aabbs: Array[AABB]) -> void:
	var node_transform := parent_transform
	var node_3d := node as Node3D

	if node_3d != null:
		node_transform = parent_transform * node_3d.transform

	var mesh_instance := node as MeshInstance3D

	if mesh_instance != null and mesh_instance.mesh != null:
		mesh_aabbs.append(_transform_aabb(node_transform, mesh_instance.mesh.get_aabb()))

	for child in node.get_children():
		_collect_mesh_aabbs(child, node_transform, mesh_aabbs)


func _transform_aabb(transform: Transform3D, aabb: AABB) -> AABB:
	var corners: Array[Vector3] = [
		Vector3(aabb.position.x, aabb.position.y, aabb.position.z),
		Vector3(aabb.end.x, aabb.position.y, aabb.position.z),
		Vector3(aabb.position.x, aabb.end.y, aabb.position.z),
		Vector3(aabb.position.x, aabb.position.y, aabb.end.z),
		Vector3(aabb.end.x, aabb.end.y, aabb.position.z),
		Vector3(aabb.end.x, aabb.position.y, aabb.end.z),
		Vector3(aabb.position.x, aabb.end.y, aabb.end.z),
		Vector3(aabb.end.x, aabb.end.y, aabb.end.z),
	]

	var first_corner: Vector3 = transform * corners[0]
	var transformed_aabb := AABB(first_corner, Vector3.ZERO)

	for i in range(1, corners.size()):
		transformed_aabb = transformed_aabb.expand(transform * corners[i])

	return transformed_aabb
