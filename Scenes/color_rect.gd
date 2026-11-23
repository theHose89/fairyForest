extends ColorRect

@onready var container := get_tree().current_scene.get_node("SubViewportContainer")
@onready var sub : = get_tree().current_scene.get_node("SubViewportContainer/SubViewport")

func _ready() -> void:
	_update_resolution()
	sub.size_changed.connect(_update_resolution)

func _update_resolution() -> void:
	material.set_shader_parameter("resolution", Vector2(sub.size))
