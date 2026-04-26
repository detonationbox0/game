extends Node3D

@export var ads_fov_delta: float = -10.0
@export var ads_tween_duration: float = 0.12

@onready var viewmodel_offset: Node3D = $ViewmodelOffset
@onready var ads_pose: Node3D = $AdsPose

var default_viewmodel_transform: Transform3D
var ads_tween: Tween


func _ready() -> void:
	default_viewmodel_transform = viewmodel_offset.transform


func set_aiming(is_aiming: bool) -> void:
	if ads_tween != null:
		ads_tween.kill()

	var target_transform := ads_pose.transform if is_aiming else default_viewmodel_transform
	ads_tween = create_tween()
	ads_tween.tween_property(viewmodel_offset, "transform", target_transform, ads_tween_duration)


func get_ads_fov_delta() -> float:
	return ads_fov_delta


func get_ads_tween_duration() -> float:
	return ads_tween_duration
