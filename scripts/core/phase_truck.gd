extends BasePhase

signal order_queue_updated(queue: Array[Order])

var order_queue: Array[Order] = []

func _ready() -> void:
	$HUD/Label.text = "Truck Phase - let's eat some tasty food"
	$HUD/Button.text = "go to next phase: results"
	$HUD/CurrentDishLabel.text = "Holding: Nothing"
	$HUD/Button.pressed.connect(_on_next)

	$World/Diver.held_item_changed.connect(_on_held_item_changed)
	$World/PickupWindow.order_fulfilled.connect(_on_order_fulfilled)

	$World/CustomerSpawner.setup($World)
	$World/OrderWindow.customer_spawner = $World/CustomerSpawner
	$World/OrderWindow.order_taken.connect(_on_order_taken)
	$World/CustomerSpawner.line_origin = $World/OrderWindow.position + Vector2(0, 90)

	_refresh_orders()
	
	GameState.inventory.inventory_changed.connect(_refresh_inventory)
	_refresh_inventory()

func _refresh_orders() -> void:
	for child in $HUD/OrdersPanel.get_children():
		child.queue_free()

	for item in order_queue:
		var item_label = Label.new()
		var order_status: String= " (" + Order.Status.keys()[item.status] + ")"
		var recipe_name = GameState.recipeCatalog[item.recipe_id].display_name
		
		item_label.text = recipe_name + order_status
		$HUD/OrdersPanel.add_child(item_label)
	
	order_queue_updated.emit(order_queue)

func _refresh_inventory() -> void:
	var lines: Array[String] = []
	lines.append("Inventory %d/%d" % [GameState.inventory.total_count(), GameState.inventory.capacity])
	lines.append("Kelp: %d" % GameState.inventory.get_count(Ids.ING_KELP))
	lines.append("Clam: %d" % GameState.inventory.get_count(Ids.ING_CLAM))
	$HUD/InventoryLabel.text = "\n".join(lines)

func _on_next() -> void:
	emit_signal("phase_finished", PhaseIds.PhaseId.RESULTS, {})

func _on_held_item_changed(item: String) -> void:
	if item == "" :
		$HUD/CurrentDishLabel.text = "Holding: Nothing"
	else:
		var recipe: RecipeData = GameState.recipeCatalog[item]
		$HUD/CurrentDishLabel.text = "Holding: " + recipe.display_name

func _on_order_taken(order: Order) -> void:
	order_queue.append(order)
	_refresh_orders()

func _on_order_fulfilled(recipe_id: StringName) -> void:
	for order in order_queue:
		if (order.recipe_id == recipe_id):
			var recipe_price = GameState.recipeCatalog[recipe_id].base_price
			GameState.money += recipe_price
			
			order.status = Order.Status.FULFILLED
			order_queue.erase(order)

			if order.customer_ref != null:
				order.customer_ref.fulfill()
	  
			_refresh_orders()
			break
