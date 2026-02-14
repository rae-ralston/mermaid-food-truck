extends BasePhase

func _ready() -> void:
	$Label.text = "Store Phase - get better for next cycle"
	$Button.text = "go to next phase: dive planning"
	$Button.pressed.connect(_on_next)

func enter(_payload: Dictionary) -> void:
	pass

func _on_next() -> void:
	emit_signal("phase_finished", PhaseIds.PhaseId.DIVE_PLANNING, {})
