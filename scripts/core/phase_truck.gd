extends BasePhase

func _ready() -> void:
	$Label.text = "Truck Phase - let's eat some tasty food"
	$Button.text = "go to next phase: results"
	$Button.pressed.connect(_on_next)
	
	GameState.inventory.inventory_changed.connect(_refresh_inventory)
	_refresh_inventory()

func _refresh_inventory() -> void:
	var lines: Array[String] = []
	lines.append("Inventory %d/%d" % [GameState.inventory.total_count(), GameState.inventory.capacity])
	lines.append("Kelp: %d" % GameState.inventory.get_count(Ids.ING_KELP))
	lines.append("Clam: %d" % GameState.inventory.get_count(Ids.ING_CLAM))
	$InventoryLabel.text = "\n".join(lines)

func _on_next() -> void:
	emit_signal("phase_finished", PhaseIds.PhaseId.RESULTS, {})
