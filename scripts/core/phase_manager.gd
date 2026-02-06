extends Node

class_name PhaseManager

@onready var current_phase_root: Node = $"../CurrentPhaseRoot"

var _current_phase: BasePhase = null

var _phase_paths := {
	PhaseIds.PhaseId.DIVE_PLANNING: "res://scenes/phases/PhaseDivePlanning.tscn",
	PhaseIds.PhaseId.DIVE: "res://scenes/phases/PhaseDive.tscn",
	PhaseIds.PhaseId.TRUCK_PLANNING: "res://scenes/phases/PhaseTruckPlanning.tscn",
	PhaseIds.PhaseId.TRUCK: "res://scenes/phases/PhaseTruck.tscn",
	PhaseIds.PhaseId.RESULTS: "res://scenes/phases/PhaseResults.tscn",
	PhaseIds.PhaseId.STORE: "res://scenes/phases/PhaseStore.tscn",
}

func _ready() -> void:
	switch_to(PhaseIds.PhaseId.DIVE_PLANNING, {})

func switch_to(phase_id: int, payload: Dictionary) -> void:
	#clean up old phase
	if _current_phase != null:
		_current_phase.exit()
		_current_phase.queue_free()
		_current_phase = null
	
	# instance new phase (load at runtime to avoid cyclic resource inclusion)
	var scene: PackedScene = load(_phase_paths[phase_id]) as PackedScene
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
	if payload.has("gathered"):
		GameState.inventory.add_many(payload["gathered"])
	switch_to(next_phase, payload)
