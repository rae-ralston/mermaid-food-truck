extends BasePhase

signal order_queue_updated(queue: Array[Order])

var order_queue: Array[Order] = []
var orders_filled: int = 0
var orders_lost: int = 0
var money_earned: int = 0

var CustomerQueuePanel = preload("res://scenes/HUD/CustomerQueuePanel.tscn")

func _ready() -> void:
	$HUD/Label.text = "Truck Phase - let's eat some tasty food"
	$HUD/Button.text = "go to next phase: results"
	$HUD/CurrentDishLabel.text = "Holding: Nothing"
	$HUD/Button.pressed.connect(_on_next)

	$World/Diver.held_item_changed.connect(_on_held_item_changed)
	$World/PickupWindow.order_fulfilled.connect(_on_order_fulfilled)
	
	$World/Stations/PrepStation.dish_completed.connect(_on_cooking_phase_completed)
	$World/Stations/CookStation.dish_completed.connect(_on_cooking_phase_completed)
	$World/Stations/PlateStation.dish_completed.connect(_on_cooking_phase_completed)
	
	$World/CustomerSpawner.setup($World)
	$World/OrderWindow.customer_spawner = $World/CustomerSpawner
	$World/OrderWindow.order_taken.connect(_on_order_taken)
	$World/CustomerSpawner.line_origin = $World/OrderWindow.position + Vector3(0, -2, 0)
	
	_refresh_orders()
	
	GameState.inventory.inventory_changed.connect(_refresh_inventory)
	_refresh_inventory()

func enter(payload: Dictionary) -> void:
	if payload.has("active_menu"):
		$World/CustomerSpawner.active_menu = payload.active_menu
	var panel = CustomerQueuePanel.instantiate()
	GameHUD.get_zone(&"bottom_left").add_child(panel)
	panel.setup($World/CustomerSpawner)

func exit() -> void:
	GameHUD.clear_all_zones()

func _refresh_orders() -> void:
	
	for child in $HUD/OrdersPanel.get_children():
		child.queue_free()

	for order in order_queue:
		if not is_instance_valid(order.customer_ref): return
		
		var item_container = VBoxContainer.new()
		var item_label = Label.new()
		var order_status: String= " (" + Order.Status.keys()[order.status] + ")"
		var recipe = GameState.recipeCatalog[order.recipe_id]
		var recipe_name = recipe.display_name
		item_label.text = recipe_name + order_status
		
		var cooking_progress = ProgressBar.new()
		order.progress_bar = cooking_progress
		item_container.add_child(item_label)
		item_container.add_child(cooking_progress)

		$HUD/OrdersPanel.add_child(item_container)
	
	order_queue_updated.emit(order_queue)

func _on_patience_changed(ratio: float, order) -> void:
	if not is_instance_valid(order.progress_bar): return
	
	if ratio > 0.5:
		order.progress_bar.modulate = Color.GREEN
	elif ratio > 0.2:
		order.progress_bar.modulate = Color.YELLOW
	else:
		order.progress_bar.modulate = Color.RED

func _refresh_inventory() -> void:
	var lines: Array[String] = []
	lines.append("Inventory %d/%d" % [GameState.inventory.total_count(), GameState.inventory.capacity])
	lines.append("Kelp: %d" % GameState.inventory.get_count(Ids.ING_KELP))
	lines.append("Clam: %d" % GameState.inventory.get_count(Ids.ING_CLAM))
	$HUD/InventoryLabel.text = "\n".join(lines)

func _on_next() -> void:
	var payload = {
		"orders_filled": orders_filled, 
		"orders_lost": orders_lost, 
		"money_earned": money_earned
	}
	
	emit_signal("phase_finished", PhaseIds.PhaseId.RESULTS, payload)

func _on_held_item_changed(item: Dictionary) -> void:
	if item.is_empty():
		$HUD/CurrentDishLabel.text = "Holding: Nothing"
	else:
		var recipe: RecipeData = GameState.recipeCatalog[item.recipe_id]
		$HUD/CurrentDishLabel.text = "Holding: " + recipe.display_name

func _on_order_taken(order: Order) -> void:
	order_queue.append(order)
	if order.customer_ref != null:
		order.customer_ref.start_patience(30.0)
		order.customer_ref.customer_timed_out.connect(_on_customer_timeout)
		order.customer_ref.patience_changed.connect(_on_patience_changed.bind(order))
	_refresh_orders()

func _on_order_fulfilled(recipe_id: StringName) -> void:
	for order in order_queue:
		if (order.recipe_id == recipe_id):
			var recipe_price = GameState.recipeCatalog[recipe_id].base_price
			GameState.money += recipe_price
			money_earned += recipe_price
			
			orders_filled += 1
			order.status = Order.Status.FULFILLED
			order_queue.erase(order)
			
			if order.customer_ref != null:
				order.customer_ref.fulfill()
	 		 
			_refresh_orders()
			break

func _on_customer_timeout(customer: Node3D) -> void:
	for order in order_queue:
		if order.customer_ref == customer:
			order_queue.erase(order)
			orders_lost += 1
			_refresh_orders()
			break

func _on_cooking_phase_completed(recipe_id, _station_type) -> void:
	for order in order_queue:
		if recipe_id == order.recipe_id:
			order.steps_completed += 1

			var recipe_steps = GameState.recipeCatalog[order.recipe_id].steps.size()
			order.progress_bar.value = float(order.steps_completed) / recipe_steps * 100.0
			break
