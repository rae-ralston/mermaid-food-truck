extends Area3D
class_name Gatherable

@export var ingredient: IngredientData
@export var amount: int = 1

@onready var sprite: Sprite3D = $Sprite3D

var harvested := false

func _ready() -> void:
	if sprite == null:
		push_error("Sprite3D child missing under Gatherable.")
		return
	
	if ingredient != null and ingredient.sprite != null:
		sprite.texture = ingredient.sprite

func can_interact(_actor) -> bool:
	return not harvested and ingredient != null

func get_interaction_priority(_actor) -> int:
	return 1

func interact(_actor) -> Dictionary:
	if harvested or ingredient == null:
		return {}

	harvested = true

	return {
		"source": self,
		"type": "harvest",
		"items": { ingredient.id: amount }
	}

func consume() -> void:
	queue_free()

func cancel_harvest() -> void:
	harvested = false

static func create_dropped(ingredient_data: IngredientData, _pos: Vector3) -> Gatherable:
	var gatherable = load("res://scenes/Gatherable.tscn").instantiate()
	gatherable.amount = 1
	gatherable.ingredient = ingredient_data
	gatherable.scale = Vector3(0.2, 0.2, 0.2)
	return gatherable

func start_despawn_timer() -> void:
	var timer = Timer.new()
	timer.wait_time = 10.0
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(queue_free)
	add_child(timer)
