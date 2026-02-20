extends Node3D

signal customer_left(customer: Node3D)

var recipe_id: StringName
var order: Order

func setup(incoming_recipe_id: StringName) -> void:
	recipe_id = incoming_recipe_id

func fulfill() -> void:
	var tween := create_tween()
	tween.tween_interval(0.5)
	#tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_leave)

func _leave() -> void:
	customer_left.emit(self)
	queue_free()
	
	
