extends Area2D
class_name Gatherable

@export var ingredient: IngredientData
@export var amount: int = 1

@onready var sprite: Sprite2D = $Sprite2D

var harvested := false

func _ready() -> void:
	if sprite == null:
		push_error("Sprite2D child missing under Gatherable.")
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
	queue_free()

	return {
		"type": "harvest",
		"items": { ingredient.id: amount }
	}
