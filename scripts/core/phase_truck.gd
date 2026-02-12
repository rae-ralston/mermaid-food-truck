extends BasePhase

func _ready() -> void:
	$HUD/Label.text = "Truck Phase - let's eat some tasty food"
	$HUD/Button.text = "go to next phase: results"
	$HUD/CurrentDishLabel.text = "Holding: Nothing"
	$HUD/Button.pressed.connect(_on_next)
	$World/Diver.held_item_changed.connect(_on_held_item_changed)
	
	GameState.inventory.inventory_changed.connect(_refresh_inventory)
	_refresh_inventory()

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
