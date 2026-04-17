extends Node3D

@export var tile_size: float = 2.0
@export var grid_width: int = 2
@export var grid_height: int = 2
@export var move_duration: float = 0.2
@export var turn_duration: float = 0.15

const NORTH := 0
const EAST := 1
const SOUTH := 2
const WEST := 3

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0),
]

var grid_pos := Vector2i(1, 1)
var facing := NORTH
var is_busy := false
var start_y := 0.0


func _ready() -> void:
	start_y = position.y
	position = grid_to_world(grid_pos)
	rotation = Vector3(0.0, facing_to_y_rotation(facing), 0.0)


func _unhandled_input(_event: InputEvent) -> void:
	if is_busy:
		return

	if Input.is_action_just_pressed("move_forward"):
		attempt_forward_move()
	elif Input.is_action_just_pressed("turn_left"):
		attempt_turn_left()
	elif Input.is_action_just_pressed("turn_right"):
		attempt_turn_right()


func grid_to_world(grid: Vector2i) -> Vector3:
	var world_x := (grid.x - (grid_width - 1) * 0.5) * tile_size
	var world_z := (grid.y - (grid_height - 1) * 0.5) * tile_size
	return Vector3(world_x, start_y, world_z)


func facing_to_y_rotation(facing_index: int) -> float:
	return -facing_index * PI * 0.5


func attempt_forward_move() -> void:
	var next_grid: Vector2i = grid_pos + DIRECTIONS[facing]

	if next_grid.x < 0 or next_grid.x >= grid_width:
		return

	if next_grid.y < 0 or next_grid.y >= grid_height:
		return

	grid_pos = next_grid
	is_busy = true

	var tween := create_tween()
	tween.tween_property(self, "position", grid_to_world(grid_pos), move_duration)
	tween.finished.connect(_finish_move)


func attempt_turn_left() -> void:
	facing = (facing + 3) % 4
	is_busy = true

	var tween := create_tween()
	tween.tween_property(self, "rotation:y", facing_to_y_rotation(facing), turn_duration)
	tween.finished.connect(_finish_turn)


func attempt_turn_right() -> void:
	facing = (facing + 1) % 4
	is_busy = true

	var tween := create_tween()
	tween.tween_property(self, "rotation:y", facing_to_y_rotation(facing), turn_duration)
	tween.finished.connect(_finish_turn)


func _finish_move() -> void:
	position = grid_to_world(grid_pos)
	is_busy = false


func _finish_turn() -> void:
	rotation = Vector3(0.0, facing_to_y_rotation(facing), 0.0)
	is_busy = false
