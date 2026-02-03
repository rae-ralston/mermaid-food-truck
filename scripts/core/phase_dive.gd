extends BasePhase

func _ready() -> void:
	$Label.text = "Diving phase - swim baby, swim."
	$Button.text = "go to next phase: truck"
	$Button.pressed.connect(_on_next)

func enter(_payload: Dictionary) -> void:
	GameState.start_new_day()

func _on_next() -> void:
	var gathered := {
		Ids.ING_KELP: 3,
		Ids.ING_CLAM: 1
	}
	
	emit_signal(
		"phase_finished", 
		PhaseIds.PhaseId.TRUCK, 
		{ "gathered": gathered }
	)
