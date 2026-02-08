extends Area2D

enum CookingPhaseIds { IDLE, WORKING, DONE }
enum StationType { PREP, COOK, PLATE }

var stationPhase: Dictionary = {
	StationType.PREP: { "name": 'prep phase' },
	StationType.COOK: { "name": 'cook phase' },
	StationType.PLATE: { "name": 'plate phase' },
}

var cookingPhase: Dictionary = {
	CookingPhaseIds.IDLE: {
		"id": CookingPhaseIds.IDLE,
		"name": "Idle, waiting",
	},
	CookingPhaseIds.WORKING: {
		"id": CookingPhaseIds.WORKING,
		"name": "Working...",
		"prepTime": 5 #seconds
	},
	CookingPhaseIds.DONE: {
		"id": CookingPhaseIds.DONE,
		"name": "Food done, initiate next",
	}
}

var currentCookingPhase: CookingPhaseIds = CookingPhaseIds.IDLE
var currentStation: StationType = StationType.PREP
var isCooking: bool = false

func _ready() -> void:
	$Timer.timeout.connect(_on_timer_timeout)
	$PhaseLabel.text = cookingPhase[currentCookingPhase].name
	$StationLabel.text = stationPhase[StationType.PREP].name

func interact(_actor) -> Dictionary:
	match(currentCookingPhase):
		CookingPhaseIds.IDLE:
			# TODO: if there is an order in the queue
			var workingPhase = cookingPhase[CookingPhaseIds.WORKING]
			$PhaseLabel.text = workingPhase.name
			$Timer.start(workingPhase.prepTime)
			_set_cooking_phase(CookingPhaseIds.WORKING)
			return {}
		CookingPhaseIds.WORKING:
			# do nothing for now. Future enhancement: cancel current action
			$PhaseLabel.text = cookingPhase[CookingPhaseIds.DONE].name
			_set_cooking_phase(CookingPhaseIds.DONE)
			return {}
		CookingPhaseIds.DONE:
			# TODO: pick up item into inventory.
			# TODO: check if item has been cooked
			$PhaseLabel.text = cookingPhase[CookingPhaseIds.IDLE].name
			_set_cooking_phase(CookingPhaseIds.IDLE)
			_set_next_cooking_phase() # TODO: next in recipe
			return {}
		_:
			return {}


func _get_cooking_phase_info() -> CookingPhaseIds:
	return cookingPhase[currentCookingPhase]

func _set_cooking_phase(newPhase: CookingPhaseIds) -> void:
	currentCookingPhase = newPhase

func _set_next_cooking_phase() -> void:
	# TODO set to next as designated in the recipe
	match currentStation:
		StationType.PREP:
			_transition_station_type_to(StationType.COOK)
		StationType.COOK:
			_transition_station_type_to(StationType.PLATE)
		StationType.PLATE:
			_transition_station_type_to(StationType.PREP)
		_:
			pass
		


func _transition_station_type_to(transition_to: StationType) -> void:
	$StationLabel.text = stationPhase[transition_to].name
	currentStation = transition_to

func _on_timer_timeout():
	_set_cooking_phase(CookingPhaseIds.DONE)
	$PhaseLabel.text = cookingPhase[CookingPhaseIds.DONE].name
