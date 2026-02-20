extends Area3D
class_name PickupWindow

signal order_fulfilled(order: StringName)

func interact(actor) -> Dictionary:
	if not actor.is_holding(): 
		return {}
	
	#just emits that the recipe is complete
	var recipe_id: StringName = actor.held_item.recipe_id
	order_fulfilled.emit(recipe_id)
	actor.held_item = {}
	
	return {}
