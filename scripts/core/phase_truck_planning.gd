extends BasePhase

func _ready() -> void:
	$Label.text = "Truck Planning Phase - choose recipes"
	$Button.text = "go to next phase: truck"
	$Button.pressed.connect(_on_next)

func enter(_payload: Dictionary) -> void:
	pass

func _on_next() -> void:
	emit_signal("phase_finished", PhaseIds.PhaseId.TRUCK, {})
