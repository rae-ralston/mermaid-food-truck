extends Control


class_name BasePhase

@warning_ignore("unused_signal")
signal phase_finished(next_phase: int, payload: Dictionary)

func enter(_payload: Dictionary) -> void:
	pass

func exit() -> void:
	pass
