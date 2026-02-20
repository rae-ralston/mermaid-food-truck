extends Area3D
class_name OrderWindow

signal order_taken(order: Order)

var customer_spawner: CustomerSpawner

func interact(actor) -> Dictionary:
	if actor.is_holding(): return {}
	
	var customer = customer_spawner.get_front_customer()
	if customer == null: return {}
	
	var order := Order.new(customer.recipe_id)
	order.customer_ref = customer
	customer.order = order
	
	order_taken.emit(order)
	actor.held_item = {
		"recipe_id": customer.recipe_id,
		"completed_steps": []
	}
	
	return {}
