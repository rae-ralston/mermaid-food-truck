extends Node2D

enum CookingPhaseIds { IDLE, WORKING, DONE }
enum StationType { PREP, COOK, PLATE }

var cookingPhase: Dictionary = {
	CookingPhaseIds.IDLE: {
		"id": CookingPhaseIds.IDLE,
		"name": "Idle, waiting",
		"prepTime": 5 #seconds
	},
	CookingPhaseIds.WORKING: {
		"id": CookingPhaseIds.WORKING,
		"name": "Working...",
		"prepTime": 5 #seconds
	},
	CookingPhaseIds.DONE: {
		"id": CookingPhaseIds.DONE,
		"name": "Food done, initiate next",
		"prepTime": 5 #seconds
	}
}

var currentCookingPhase: CookingPhaseIds = CookingPhaseIds.IDLE
var currentStation: StationType = StationType.PREP
var isCooking: bool = false

func interact(_actor) -> Dictionary:
	if _current_cooking_phase_is(CookingPhaseIds.WORKING):
		return {}
	
	return {}
	#if harvested or ingredient == null:
		#return {}
#
	#harvested = true
	#queue_free()
#
	#return {
		#"type": "harvest",
		#"items": { ingredient.id: amount }
	#}

func _get_cooking_phase_info() -> CookingPhaseIds:
	return cookingPhase[currentCookingPhase]

func _current_cooking_phase_is(check_phase: CookingPhaseIds) -> bool:
	return currentCookingPhase == check_phase

func _set_cooking_phase(newPhase: CookingPhaseIds) -> void:
	currentCookingPhase = newPhase

func _transition_station_type_to(transition_to: StationType) -> void:
	currentStation = transition_to

func _timer() -> void:
	pass
