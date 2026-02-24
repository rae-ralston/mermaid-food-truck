extends Sprite3D

@export var scroll_factor: Vector2
var starting_position: Vector3

func _ready() -> void:
	starting_position = global_position

func _process(_delta: float) -> void:
	var camera = get_viewport().get_camera_3d()
	var camera_xy = Vector2(camera.global_position.x, camera.global_position.y)

	global_position.x = starting_position.x + camera_xy.x * (1.0 - scroll_factor.x)
	global_position.y = starting_position.y + camera_xy.y * (1.0 - scroll_factor.y)
