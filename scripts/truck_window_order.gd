extends Area2D
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
	actor.held_item = customer.recipe_id
	
	return {}
