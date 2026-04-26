extends Node3D

const AR_3_VIEWMODEL_SCENE: PackedScene = preload("res://player/viewport/ar_3.tscn")

@onready var selection_light: SpotLight3D = $SpotLight3D

func _ready() -> void:
	set_selected(false)

func set_selected(is_selected: bool) -> void:
	selection_light.visible = is_selected

func pickup(player: Node) -> void:
	if player != null and player.has_method("acquire_weapon_viewmodel"):
		player.acquire_weapon_viewmodel(AR_3_VIEWMODEL_SCENE)

	queue_free()
