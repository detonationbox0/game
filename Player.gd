extends Node3D

@export var move_duration: float = 0.2
@export var turn_duration: float = 0.15

# Indexes for the DIRECTIONS array
const NORTH := 0
const EAST := 1
const SOUTH := 2
const WEST := 3

# Direction offsets in grid space (x, y):
# Used to calculate the next grid cell when moving forward.
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(0, -1), # NORTH
	Vector2i(1, 0), # EAST
	Vector2i(0, 1), # SOUTH
	Vector2i(-1, 0), # WEST
]

# Current Player position state
var grid_pos := Vector2i.ZERO
var facing := NORTH
var is_busy := false
var has_valid_setup := false
var floor_world_positions: Dictionary = {}

func _ready() -> void:
	# Read the authored floor tiles on load, then use the nearest one as the starting grid cell.
	_discover_floor_tiles()

	if floor_world_positions.is_empty():
		push_error("Player: No floor tiles were found under World/Floors. Movement is disabled.")
		return

	var start_grid := _find_nearest_floor_grid(global_position)

	if start_grid.x < 0:
		push_error("Player: Could not match the starting Player position to a floor tile. Movement is disabled.")
		return

	grid_pos = start_grid
	rotation = Vector3(0.0, facing_to_y_rotation(facing), 0.0)
	has_valid_setup = true

func _unhandled_input(_event: InputEvent) -> void:
	if not has_valid_setup or is_busy:
		return

	# User input for movement and turning
	if Input.is_action_just_pressed("move_forward"):
		attempt_forward_move()
	elif Input.is_action_just_pressed("turn_left"):
		attempt_turn_left()
	elif Input.is_action_just_pressed("turn_right"):
		attempt_turn_right()

# Convert a grid position into the authored world position of its matching floor tile.
# See docs/math/grid-to-world-position.qmd
func grid_to_world(grid: Vector2i) -> Vector3:
	if not floor_world_positions.has(grid):
		push_error("Player: Tried to use missing floor tile %s." % [grid])
		return global_position

	return floor_world_positions[grid]

# Convert facing (N/E/S/W) into a Y rotation (90° per step)
# Remember: facing = how many 90° turns from NORTH
# See docs/math/facing-index-to-y-rotation.qmd
func facing_to_y_rotation(facing_index: int) -> float:
	return -facing_index * PI * 0.5

func _discover_floor_tiles() -> void:
	var floors := get_tree().current_scene.get_node_or_null("World/Floors")
	floor_world_positions.clear()

	if floors == null:
		push_error("Player: Could not find World/Floors. Movement is disabled.")
		return

	for child in floors.get_children():
		var floor_node := child as Node3D

		if floor_node == null:
			continue

		var floor_grid := _parse_floor_grid_pos(floor_node.name)

		if floor_grid.x < 0:
			continue

		floor_world_positions[floor_grid] = floor_node.global_position


func _parse_floor_grid_pos(node_name: String) -> Vector2i:
	if not node_name.begins_with("Floor_"):
		return Vector2i(-1, -1)

	var parts := node_name.split("_", false)

	# Floor_x12_y3 means x = 12, y = 3.
	if parts.size() != 3:
		return Vector2i(-1, -1)

	if not parts[1].begins_with("x") or not parts[2].begins_with("y"):
		return Vector2i(-1, -1)

	var x_text := parts[1].trim_prefix("x")
	var y_text := parts[2].trim_prefix("y")

	if x_text.is_empty() or y_text.is_empty():
		return Vector2i(-1, -1)

	if not x_text.is_valid_int() or not y_text.is_valid_int():
		return Vector2i(-1, -1)

	return Vector2i(x_text.to_int(), y_text.to_int())


func _find_nearest_floor_grid(start_position: Vector3) -> Vector2i:
	var nearest_grid := Vector2i(-1, -1)
	var nearest_distance := INF

	for floor_grid in floor_world_positions.keys():
		var floor_position: Vector3 = floor_world_positions[floor_grid]
		var distance := start_position.distance_to(floor_position)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_grid = floor_grid

	return nearest_grid

func attempt_forward_move() -> void:
	# Add to the direction quantity to get the next grid cell, then tween to it.
	var next_grid: Vector2i = grid_pos + DIRECTIONS[facing]

	# If there is no floor tile there, don't move.
	if not floor_world_positions.has(next_grid):
		return

	grid_pos = next_grid
	is_busy = true

	# Move the user to the matching floor tile position.
	var tween := create_tween()
	tween.tween_property(self , "global_position", grid_to_world(grid_pos), move_duration)
	tween.finished.connect(_finish_move)


func attempt_turn_left() -> void:
	# Works out to the direction to the left of the current facing
	# North -> West
	# East -> North
	facing = (facing + 3) % 4
	# Turning...
	is_busy = true

	# Tween one quarter-turn left from the current angle,
	# then snap to the exact facing angle when finished.
	var target_rotation := rotation.y + PI * 0.5
	var tween := create_tween()
	tween.tween_property(self , "rotation:y", target_rotation, turn_duration)
	tween.finished.connect(_finish_turn)


func attempt_turn_right() -> void:
	facing = (facing + 1) % 4
	is_busy = true

	# Tween one quarter-turn right from the current angle,
	# then snap to the exact facing angle when finished.
	var target_rotation := rotation.y - PI * 0.5
	var tween := create_tween()
	tween.tween_property(self , "rotation:y", target_rotation, turn_duration)
	tween.finished.connect(_finish_turn)


func _finish_move() -> void:
	global_position = grid_to_world(grid_pos)
	is_busy = false # Resume...


func _finish_turn() -> void:
	rotation = Vector3(0.0, facing_to_y_rotation(facing), 0.0)
	is_busy = false # Resume...
