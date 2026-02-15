extends BasePhase
class_name PhaseStore

func _ready() -> void:
	$PhaseLabel.text = "Store Phase - get better for next cycle"
	$MoneyLabel.text = "Available Money: $%s" % GameState.money
	$ContinueButton.text = "go to next phase: dive planning"
	$ContinueButton.pressed.connect(_on_next)

func enter(_payload: Dictionary) -> void:
	_refresh_upgrades()

func _on_next() -> void:
	emit_signal("phase_finished", PhaseIds.PhaseId.DIVE_PLANNING, {})

func _on_upgrade_purchased(upgrade_id: String) -> void:
	GameState.buy_upgrade(upgrade_id)
	_refresh_upgrades()
	$MoneyLabel.text = "Available Money: $%s" % GameState.money

func _refresh_upgrades() -> void:
	for child in $UpgradesPanel.get_children():
		child.queue_free()
	
	const available_upgrades = GameState.UPGRADE_CONFIG
	for upgrade_id in available_upgrades.keys():
		var upgrade = available_upgrades[upgrade_id]
		var display_name = upgrade.display_name
		var cost = GameState.get_upgrade_cost(upgrade_id)
		
		var container = HBoxContainer.new()
		container.name = "UpgradeContainer"
		$UpgradesPanel.add_child(container)
		
		var upgrade_label = Label.new()
		upgrade_label.name = "UpgradeLabel"
		if cost == -1:
			upgrade_label.text = "%s (MAXED)" % display_name
		else:
			upgrade_label.text = "Improve attribute: %s for $%d" % [display_name, cost]

		container.add_child(upgrade_label)
		
		var is_maxxed = upgrade.max_level < GameState.upgrades[upgrade_id] + 1
		var insufficent_funds = cost > GameState.money
		var disabled = is_maxxed or insufficent_funds or cost == -1
		var upgrade_button = Button.new()
		upgrade_button.name = "UpgradeButton"
		upgrade_button.text = "Buy Now" if not disabled else "Unavailable"
		upgrade_button.disabled = disabled
		#.bind to pass arguments to uncalled functions
		upgrade_button.pressed.connect(_on_upgrade_purchased.bind(upgrade_id))
		container.add_child(upgrade_button)
