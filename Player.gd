extends Node3D

@export var tile_size: float = 2.0
@export var grid_width: int = 2
@export var grid_height: int = 2
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
var grid_pos := Vector2i(1, 1)
var facing := NORTH
var is_busy := false
var start_y := 0.0 # Lock Y

func _ready() -> void:
	# Position the player on load
	start_y = position.y
	position = grid_to_world(grid_pos)
	rotation = Vector3(0.0, facing_to_y_rotation(facing), 0.0)

func _unhandled_input(_event: InputEvent) -> void:
	if is_busy:
		return

	# User input for movement and turning
	if Input.is_action_just_pressed("move_forward"):
		attempt_forward_move()
	elif Input.is_action_just_pressed("turn_left"):
		attempt_turn_left()
	elif Input.is_action_just_pressed("turn_right"):
		attempt_turn_right()

# Convert a grid position (like 1,1) into a world position,
# keeping the grid centered around (0,0)
# See docs/math/grid-to-world-position.qmd
func grid_to_world(grid: Vector2i) -> Vector3:
	var world_x := (grid.x - (grid_width - 1) * 0.5) * tile_size
	var world_z := (grid.y - (grid_height - 1) * 0.5) * tile_size
	return Vector3(world_x, start_y, world_z)

# Convert facing (N/E/S/W) into a Y rotation (90° per step)
# Remember: facing = how many 90° turns from NORTH
# See docs/math/facing-index-to-y-rotation.qmd
func facing_to_y_rotation(facing_index: int) -> float:
	return -facing_index * PI * 0.5

func attempt_forward_move() -> void:
	# Add to the direction quantity to get the next grid cell, then tween to it
	var next_grid: Vector2i = grid_pos + DIRECTIONS[facing]

	# If grid out of bounds (wall), don't move
	if next_grid.x < 0 or next_grid.x >= grid_width:
		return

	if next_grid.y < 0 or next_grid.y >= grid_height:
		return

	grid_pos = next_grid
	is_busy = true

	# Move the user
	var tween := create_tween()
	tween.tween_property(self , "position", grid_to_world(grid_pos), move_duration)
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
	position = grid_to_world(grid_pos)
	is_busy = false # Resume...


func _finish_turn() -> void:
	rotation = Vector3(0.0, facing_to_y_rotation(facing), 0.0)
	is_busy = false # Resume...
