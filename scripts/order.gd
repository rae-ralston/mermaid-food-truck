extends RefCounted
class_name Order

enum Status { PENDING, COOKING, READY, FULFILLED }

var recipe_id: StringName
var status: Status

func _init(incoming_recipe_id: StringName) -> void:
	recipe_id = incoming_recipe_id
	status = Status.PENDING
