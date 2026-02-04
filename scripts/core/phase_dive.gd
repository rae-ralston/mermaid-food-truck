extends BasePhase

var run_gathered: Dictionary = {}
var extracted := false

func _ready() -> void:
	$HUD/LocationLabel.text = "Diving phase - swim baby, swim."
	$HUD/Button.text = "go to next phase: truck"
	$HUD/Button.pressed.connect(_extract_and_finish)
	$World/Diver.interaction_performed.connect(_on_interaction)
	$World/ExtractionZone.body_entered.connect(_on_extraction_body_entered)
	

func enter(_payload: Dictionary) -> void:
	run_gathered.clear()
	extracted = false
	_refresh_loot_ui()

func _on_interaction(result: Dictionary) -> void:
	match result.get("type", ""):
		"harvest":
			var harvested: Dictionary= result.get("items", {})
			_merge_into(run_gathered, harvested)
			_update_debug_ui(run_gathered)
		"talk":
			_show_message(result.get("message", ""))
		"blocked":
			_show_message(result.get("message", "Can't."))
		_:
			pass

func _merge_into(target: Dictionary, items: Dictionary) -> void:
	for id in items.keys():
		target[id] = int(target.get(id, 0)) + int(items[id])

func _update_debug_ui(items_gathered) -> void:
	print("[DIVE PHASE] updating UI with: ", items_gathered)
	#var lines: Array[String] = []
	#lines.append("Inventory %d/%d" % [GameState.inventory.total_count(), GameState.inventory.capacity])
	#lines.append("Kelp: %d" % GameState.inventory.get_count(Ids.ING_KELP))
	#lines.append("Clam: %d" % GameState.inventory.get_count(Ids.ING_CLAM))
	#$InventoryLabel.text = "\n".join(lines)
	pass

func _refresh_loot_ui() -> void:
	var lines: Array[String] = []
	lines.append("run loot: ")
	
	var keys := run_gathered.keys()
	keys.sort_custom(func(a, b): return str(a) < str(b))
	
	for id in keys:
		lines.append("%s: %d" % [str(id), int(run_gathered[id])])
	
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
	
	var payload: Dictionary = {
		"gathered": run_gathered.duplicate(true)
	}
	
	emit_signal("phase_finished", PhaseIds.PhaseId.TRUCK, payload)
