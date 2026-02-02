extends BasePhase

func _ready() -> void:
	$Label.text = "Planning Phase - figure it out"
	$Button.text = "go to next phase: dive"
	$Button.pressed.connect(_on_next)

func enter(_payload: Dictionary) -> void:
	pass

func _on_next() -> void:
	emit_signal("phase_finished", PhaseIds.PhaseId.DIVE, {})
