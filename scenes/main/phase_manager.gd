extends Node

class_name PhaseManager

@onready var current_phase_root: Node = $"../CurrentPhaseRoot"

var _current_phase: BasePhase = null

var _phase_scenes := {
	PhaseIds.PhaseId.PLANNING: preload("res://scenes/phases/PhasePlanning.tscn"),
	PhaseIds.PhaseId.DIVE: preload("res://scenes/phases/PhaseDive.tscn"),
	PhaseIds.PhaseId.TRUCK: preload("res://scenes/phases/PhaseTruck.tscn"),
	PhaseIds.PhaseId.RESULTS: preload("res://scenes/phases/PhaseResults.tscn"),
	PhaseIds.PhaseId.SHOP: preload("res://scenes/phases/PhaseShop.tscn"),
}

func _ready() -> void:
	switch_to(PhaseIds.PhaseId.PLANNING, {})

func switch_to(phase_id: int, payload: Dictionary) -> void:
	#clean up old phase
	if _current_phase != null:
		_current_phase.exit()
		_current_phase.queue_free()
		_current_phase = null
	
	#instance new phase
	var scene: PackedScene = _phase_scenes[phase_id]
	var phase_instance := scene.instantiate()
	current_phase_root.add_child(phase_instance)
	
	_current_phase = phase_instance as BasePhase
	if _current_phase == null:
		push_error("phase scene root must extend BasePhase")
		return
	
	if not _current_phase.phase_finished.is_connected(_on_phase_finished):
		_current_phase.phase_finished.connect(_on_phase_finished)
	
	_current_phase.enter(payload)

func _on_phase_finished(next_phase: int, payload: Dictionary) -> void:
	switch_to(next_phase, payload)
