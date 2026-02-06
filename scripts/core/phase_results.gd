extends BasePhase

func _ready() -> void:
	$Label.text = "Results Phase - how'd we do?"
	$Button.text = "go to next phase: store"
	$Button.pressed.connect(_on_next)

func enter(_payload: Dictionary) -> void:
	pass

func _on_next() -> void:
	emit_signal("phase_finished", PhaseIds.PhaseId.STORE, {})
