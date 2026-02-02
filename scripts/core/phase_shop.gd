extends BasePhase

func _ready() -> void:
	$Label.text = "Shop Phase - get better for next cycle"
	$Button.text = "go to next phase: planning"
	$Button.pressed.connect(_on_next)

func enter(_payload: Dictionary) -> void:
	pass

func _on_next() -> void:
	GameState.day += 1
	emit_signal("phase_finished", PhaseIds.PhaseId.PLANNING, {})
