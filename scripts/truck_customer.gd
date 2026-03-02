extends Node3D

signal customer_left(customer: Node3D)
signal patience_changed(ratio: float)
signal customer_timed_out(customer: Node3D)

var recipe_id: StringName
var order: Order
var patience_total: float
var patience_remaining: float
var patience_is_counting: bool = false

func _process(delta: float) -> void:
	if patience_is_counting:
		patience_remaining -= delta
		
		if patience_remaining <= 0:
			emit_signal("customer_timed_out", self)
			patience_is_counting = false
			_leave()
		else:
			emit_signal("patience_changed", (patience_remaining / patience_total))

func setup(incoming_recipe_id: StringName) -> void:
	recipe_id = incoming_recipe_id

func fulfill() -> void:
	patience_is_counting = false
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(_leave)

func _leave() -> void:
	customer_left.emit(self)
	queue_free()

func start_patience(duration: float) -> void:
	patience_total = duration
	patience_remaining = duration
	patience_is_counting = true
