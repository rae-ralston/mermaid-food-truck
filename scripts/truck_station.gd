extends Area2D

signal dish_completed(recipe_id: String, station_type: StationType)

enum CookingPhaseIds { IDLE, WORKING, DONE }
enum StationType { PREP, COOK, PLATE }

@export var station_type: StationType

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
		"name": "Food done, pick up!",
	}
}

var currentCookingPhase: CookingPhaseIds = CookingPhaseIds.IDLE
var currentRecipeId: String = "" #TODO make this real not hardcoded

func _ready() -> void:
	$Timer.timeout.connect(_on_timer_timeout)
	$PhaseLabel.text = cookingPhase[currentCookingPhase].name
	$StationLabel.text = stationPhase[station_type].name

func _process(_delta: float) -> void:
	if currentCookingPhase == CookingPhaseIds.WORKING:
		$ProgressBar.value = (1 - $Timer.time_left/$Timer.wait_time) * 100 

func interact(actor) -> Dictionary:
	# how do we recieve the currentRecipeId? Should it just pick the next item in the queue? or should the player determine what we're cooking next?
	match(currentCookingPhase):
		CookingPhaseIds.IDLE:
			# TODO: if there is an order in the queue
			if station_type == StationType.PREP:
				if actor.is_holding(): 
					print("you can't use PREP station while holding something")
					return {}
				currentRecipeId = "test_recipe"
			
			else:
				if not actor.is_holding():
					print("you must be holding something for COOK or PLATE stations to init")
					return {}
			
				currentRecipeId = actor.held_item
				actor.held_item = ""
				
			var workingPhase = cookingPhase[CookingPhaseIds.WORKING]
			$PhaseLabel.text = workingPhase.name
			$Timer.start(workingPhase.prepTime)
			$ProgressBar.value = 0
			
			_set_cooking_phase(CookingPhaseIds.WORKING)
			return {}
		CookingPhaseIds.WORKING:
			# do nothing for now. Future enhancement: cancel current action
			if actor.is_holding(): 
				print("you can't pick up if you're holding something")
				return {}
			
			$PhaseLabel.text = cookingPhase[CookingPhaseIds.DONE].name
			_set_cooking_phase(CookingPhaseIds.DONE)
			return {}
		CookingPhaseIds.DONE:
			if actor.is_holding(): 
				print("you can pick up if you're holding something")
				return {}
			
			$PhaseLabel.text = cookingPhase[CookingPhaseIds.IDLE].name
			$ProgressBar.value = 0
			
			dish_completed.emit(currentRecipeId, station_type)
			
			var current_recipe = currentRecipeId
			actor.held_item = currentRecipeId
			currentRecipeId = ""
			
			_set_cooking_phase(CookingPhaseIds.IDLE)
			
			return { "recipeId": current_recipe }
		_:
			return {}


func _get_cooking_phase_info() -> CookingPhaseIds:
	return cookingPhase[currentCookingPhase]

func _set_cooking_phase(newPhase: CookingPhaseIds) -> void:
	currentCookingPhase = newPhase

func _on_timer_timeout():
	_set_cooking_phase(CookingPhaseIds.DONE)
	$PhaseLabel.text = cookingPhase[CookingPhaseIds.DONE].name
