extends RefCounted
class_name Order

enum Status { PENDING, COOKING, READY, FULFILLED }

var recipe_id: StringName
var status: Status
var customer_ref: Node3D = null
var steps_completed: int = 0
var progress_bar: ProgressBar

func _init(incoming_recipe_id: StringName) -> void:
	recipe_id = incoming_recipe_id
	status = Status.PENDING
