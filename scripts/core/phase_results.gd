extends BasePhase

func _ready() -> void:
	$PhaseLabel.text = "Results Phase - how'd we do?"
	$ContinueButton.text = "go to next phase: store"
	$ContinueButton.pressed.connect(_on_next)

func enter(payload: Dictionary) -> void:
	$DayLabel.text = "Summary for Day %s" % [GameState.day]
	$Stats/OrdersFilledLabel.text = "Orders Filled: %s" % [payload.orders_filled]
	$Stats/OrdersLostLabel.text = "Orders Lost: %s" % [payload.orders_lost]
	$Stats/MoneyEarnedLabel.text = "Money Earned: $%s" % [payload.money_earned]
	$Stats/TotalBalanceLabel.text = "Total Avaialbe Balance: $%s" % [payload.orders_lost]
	

func _on_next() -> void:
	GameState.day += 1
	emit_signal("phase_finished", PhaseIds.PhaseId.STORE, {})
