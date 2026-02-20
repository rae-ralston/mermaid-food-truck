extends CanvasLayer

var previous_commands: Array[String] = []
var current_command_index: int = -1 # -1 = non history selected, typing new command

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$PanelContainer/VBoxContainer/CommandLine.text_submitted.connect(_match_command)

func _toggle_console() -> void:
	self.visible = !self.visible
	var command_line := $PanelContainer/VBoxContainer/CommandLine as LineEdit
	if self.visible:
		get_tree().paused = true
		# Clear on next frame to prevent backtick character leaking into input
		await get_tree().process_frame
		command_line.clear()
		command_line.grab_focus()
	else:
		get_tree().paused = false
		command_line.release_focus()

func _unhandled_input(event) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_QUOTELEFT:
			_toggle_console()
			get_viewport().set_input_as_handled()
			return

		if not self.visible:
			return

		if event.keycode == KEY_UP and previous_commands.size() > 0:
			current_command_index = clampi(current_command_index - 1, 0, previous_commands.size() - 1)
			var command_line := $PanelContainer/VBoxContainer/CommandLine as LineEdit
			command_line.text = previous_commands[current_command_index]
			command_line.caret_column = command_line.text.length()

		if event.keycode == KEY_DOWN:
			var command_line := $PanelContainer/VBoxContainer/CommandLine as LineEdit
			current_command_index = clampi(current_command_index + 1, 0, previous_commands.size())
			if current_command_index >= previous_commands.size():
				command_line.text = ""
			else:
				command_line.text = previous_commands[current_command_index]
			command_line.caret_column = command_line.text.length()

func _match_command(raw_args: String) -> void:
	if raw_args.strip_edges() == "":
		return

	previous_commands.append(raw_args)
	current_command_index = previous_commands.size()
	$PanelContainer/VBoxContainer/CommandLine.clear()
	_print_output("> " + raw_args)

	var parts := raw_args.split(" ", false)
	var command := parts[0]
	var args := parts.slice(1)

	match command:
		"money":
			_cmd_money(args)
		"add":
			_cmd_add(args)
		"stock":
			_cmd_stock(args)
		"skip":
			_cmd_skip(args)
		"day":
			_cmd_day(args)
		"upgrade":
			_cmd_upgrade(args)
		"help":
			_cmd_help()
		"clear":
			$PanelContainer/VBoxContainer/OutputLog.clear()
		_:
			_print_output("Unknown command: " + command + ". Type 'help' for commands.")


func _cmd_money(args: Array) -> void:
	var amount := int(args[0]) if args.size() > 0 else 500
	GameState.money += amount
	_print_output("Added %d money (total: %d)" % [amount, GameState.money])

func _cmd_add(args: Array) -> void:
	if args.size() == 0:
		_print_output("Usage: add <ingredient> [amount]")
		return
	var ingredient_id := StringName(args[0])
	var amount := int(args[1]) if args.size() > 1 else 1
	GameState.inventory.add(ingredient_id, amount)
	_print_output("Added %d %s" % [amount, ingredient_id])

func _cmd_stock(args: Array) -> void:
	var amount := int(args[0]) if args.size() > 0 else 10
	_stock_all_ingredients(amount)

func _cmd_day(args: Array) -> void:
	if args.size() > 0:
		GameState.day = int(args[0])
	_print_output("Day: %d" % GameState.day)

func _cmd_upgrade(args: Array) -> void:
	if args.size() == 0:
		_print_output("Usage: upgrade <swim_speed|cook_speed|inventory_capacity> [level]")
		return
	
	var upgrade_id: String = args[0]
	if upgrade_id not in GameState.upgrades:
		_print_output("Unknown upgrade: %s" % upgrade_id)
		return
	
	var level := int(args[1]) if args.size() > 1 else 3
	GameState.upgrades[upgrade_id] = level
	GameState.apply_upgrade(upgrade_id)
	
	_print_output("Set %s to level %d" % [upgrade_id, level])

func _cmd_help() -> void:
	_print_output("Commands:")
	_print_output("  money [amount]        - Add money (default 500)")
	_print_output("  add <ingredient> [n]  - Add ingredient (default 1)")
	_print_output("  stock [amount]        - Add N of every ingredient (default 10)")
	_print_output("  skip <phase> [bare]   - Jump to phase")
	_print_output("  day [number]          - Set day number")
	_print_output("  upgrade <id> [level]  - Set upgrade level (default 3)")
	_print_output("  clear                 - Clear output")
	_print_output("  help                  - Show this list")

# need reasonable defaults
var phases: Dictionary = {
	"dive_planning": {
		"id": PhaseIds.PhaseId.DIVE_PLANNING,
		"default_args": {}
	},
	"dive": {
		"id": PhaseIds.PhaseId.DIVE,
		"default_args": {"dive_site": "res://scenes/dive_sites/Shallows.tscn"}
	},
	"truck_planning": {
		"id": PhaseIds.PhaseId.TRUCK_PLANNING,
		"default_args": {}
	},
	"truck": {
		"id": PhaseIds.PhaseId.TRUCK,
		"default_args": {
			"active_menu": [&"kelp_wrap", &"glowing_soup", &"clam_chowder", &"kelp_bowl", &"slug_sushi"]
		}
	},
	"results": {
		"id": PhaseIds.PhaseId.RESULTS,
		"default_args": {"orders_filled": 3, "orders_lost": 1, "money_earned": 150}
	},
	"store": {
		"id": PhaseIds.PhaseId.STORE,
		"default_args": {}
	},
}

func _stock_all_ingredients(amount: int = 10) -> void:
	var ingredients: Array[StringName] = [&"kelp", &"clam", &"coral_spice", &"glow_algae", &"sea_slug"]
	for id in ingredients:
		GameState.inventory.add(id, amount)
	_print_output("Stocked %d of each ingredient" % amount)

func _cmd_skip(raw_args: Array) -> void:
	if raw_args.size() == 0 or raw_args[0] not in phases:
		_print_output("Usage: skip <phase_name> [bare]")
		return

	var new_phase = phases[raw_args[0]]
	var is_bare = raw_args.size() > 1 and raw_args[1] == "bare"
	var args = {} if is_bare else new_phase.default_args

	# Auto-stock ingredients when skipping to truck with smart defaults
	if raw_args[0] == "truck" and not is_bare:
		_stock_all_ingredients()

	_print_output("Skipping to %s%s..." % [raw_args[0], " (bare)" if is_bare else ""])

	# Unpause and hide console so the phase can run
	self.visible = false
	get_tree().paused = false
	$PanelContainer/VBoxContainer/CommandLine.release_focus()

	get_tree().current_scene.get_node("PhaseManager").switch_to(new_phase.id, args)

func _print_output(msg) -> void:
	$PanelContainer/VBoxContainer/OutputLog.append_text("\n" + msg)
