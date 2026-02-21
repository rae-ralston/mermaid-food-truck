extends BasePhase

var backpack: Inventory = null
var extracted := false

@onready var backpack_grid: BackpackGrid = $HUD/BackpackGrid

func _ready() -> void:
	$HUD/LocationLabel.text = "Diving phase - swim baby, swim."
	$HUD/Button.text = "go to next phase: truck planning"
	$HUD/Button.pressed.connect(_extract_and_finish)
	$World/Diver.interaction_performed.connect(_on_interaction)
	backpack_grid.item_dropped.connect(_on_item_dropped)
	$HUD.process_mode = Node.PROCESS_MODE_ALWAYS

func enter(payload: Dictionary) -> void:
	var dive_site = load(payload.dive_site) as PackedScene
	var site_instance := dive_site.instantiate()
	$World.add_child(site_instance)
	
	var spawn_point: Marker3D = site_instance.find_child("SpawnPoint")
	var extraction_zone = site_instance.find_child("ExtractionZone")

	$World/Diver.global_position = spawn_point.global_position
	
	extraction_zone.body_entered.connect(_on_extraction_body_entered)
	
	backpack = Inventory.new()
	backpack.capacity = GameState.get_backpack_capacity()
	backpack_grid.bind(backpack)
	extracted = false
	_refresh_loot_ui()

func _toggle_backpack() -> void:
	backpack_grid.visible = not backpack_grid.visible
	get_tree().paused = backpack_grid.visible

func _on_item_dropped(ingredient_id: StringName) -> void:
	if backpack == null:
		return
	if not backpack.remove(ingredient_id, 1):
		return

	var ingredient_data: IngredientData = load("res://data/ingredients/%s.tres" % str(ingredient_id))
	if ingredient_data == null:
		return

	var dropped := Gatherable.create_dropped(ingredient_data, $World/Diver.global_position)
	$World.add_child(dropped)
	dropped.global_position = $World/Diver.global_position
	dropped.start_despawn_timer()
	_refresh_loot_ui()

func _on_interaction(result: Dictionary) -> void:
	match result.get("type", ""):
		"harvest":
			var items: Dictionary = result.get("items", {})
			var source = result.get("source")
			var total_amount := 0
			for amt in items.values():
				total_amount += int(amt)

			if not backpack.has_space(total_amount):
				if source and source.has_method("cancel_harvest"):
					source.cancel_harvest()
				_show_message("Backpack full — press Tab to manage")
				return

			for id in items.keys():
				backpack.add_checked(id, int(items[id]))
			if source and source.has_method("consume"):
				source.consume()
			_refresh_loot_ui()
		"talk":
			_show_message(result.get("message", ""))
		"blocked":
			_show_message(result.get("message", "Can't."))
		_:
			pass
	  
func _refresh_loot_ui() -> void:
	if backpack == null:
		$HUD/InventoryLabel.text = ""
		return

	var lines: Array[String] = []
	lines.append("backpack (%d/%d):" % [backpack.total_count(), backpack.capacity])

	var items: Dictionary = backpack.to_dict().get("items", {})
	var keys := items.keys()
	keys.sort_custom(func(a, b): return str(a) < str(b))

	for id in keys:
		lines.append("  %s: %d" % [str(id), int(items[id])])

	$HUD/InventoryLabel.text = "\n".join(lines)

func _show_message(msg) -> void:
	print("[DIVE PHASE] showing message: ", msg)
	pass

func _on_extraction_body_entered(body: Node) -> void:
	if extracted: return
	if body != $World/Diver: return
	
	_extract_and_finish()

func _extract_and_finish() -> void:
	if extracted: return
	
	extracted = true
	var gathered: Dictionary = backpack.to_dict().get("items", {})
	GameState.inventory.add_many(gathered)
	
	var payload: Dictionary = { "gathered": gathered }
	emit_signal("phase_finished", PhaseIds.PhaseId.TRUCK_PLANNING, payload)
