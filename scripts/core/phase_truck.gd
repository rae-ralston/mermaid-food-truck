extends BasePhase

func _ready() -> void:
	$Label.text = "Truck Phase - let's eat some tasty food"
	$Button.text = "go to next phase: results"
	$Button.pressed.connect(_on_next)

func enter(_payload: Dictionary) -> void:
	pass

func _on_next() -> void:
	emit_signal("phase_finished", PhaseIds.PhaseId.RESULTS, {})
