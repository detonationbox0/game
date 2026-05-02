extends Node3D

const DOOR_OPEN_SOUND: AudioStream = preload("res://Assets/audio/door_open.wav")
const DOOR_CLOSE_SOUND: AudioStream = preload("res://Assets/audio/door_close.wav")

@export var open_rotation_degrees: float = -90.0

@onready var door_pivot: Node3D = $DoorPivot
@onready var door_collision_shape: CollisionShape3D = $DoorPivot/DoorBody/CollisionShape3D
@onready var interaction_area: Area3D = $DoorPivot/InteractionArea
@onready var audio_player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()

var is_open := false

func _ready() -> void:
	if interaction_area != null:
		interaction_area.collision_layer = 4

	if door_pivot != null:
		door_pivot.add_child(audio_player)
		audio_player.position = Vector3(0.65, 1.0, 0.0)
		audio_player.max_distance = 12.0

	_apply_open_state(false)

func set_selected(_is_selected: bool) -> void:
	pass

func interact(_player: Node) -> void:
	is_open = not is_open
	_apply_open_state(true)

func _apply_open_state(play_sound: bool) -> void:
	if door_pivot != null:
		door_pivot.rotation.y = deg_to_rad(open_rotation_degrees) if is_open else 0.0

	if door_collision_shape != null:
		door_collision_shape.set_deferred("disabled", is_open)

	if play_sound and audio_player != null:
		audio_player.stream = DOOR_OPEN_SOUND if is_open else DOOR_CLOSE_SOUND
		audio_player.play()
