extends Area3D

signal dish_completed(recipe_id: String, station_type: StationType)

enum CookingPhaseIds { IDLE, WORKING, DONE }
enum StationType { PREP, COOK, PLATE }

@export var station_type: StationType = StationType.PREP

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
	},
	CookingPhaseIds.DONE: {
		"id": CookingPhaseIds.DONE,
		"name": "Food done, pick up!",
	}
}

var currentCookingPhase: CookingPhaseIds = CookingPhaseIds.IDLE
var current_recipe: RecipeData
var current_completed_steps: Array[int] = []

func _ready() -> void:
	$Timer.timeout.connect(_on_timer_timeout)
	$PhaseLabel.text = cookingPhase[currentCookingPhase].name
	$StationLabel.text = stationPhase[station_type].name

func _process(_delta: float) -> void:
	pass

func interact(actor) -> Dictionary:
	match(currentCookingPhase):
		CookingPhaseIds.IDLE:
			if not actor.is_holding():
				print("you must be holding something for init a station")
				return {}
			
			var completed: Array[int] = []
			completed.assign(actor.held_item.get("completed_steps", []))
			var next_step_index: int = completed.size()
			current_recipe = GameState.recipeCatalog[actor.held_item.recipe_id]
			
			if next_step_index >= current_recipe.steps.size():
				print("this dish is already completly cooked.")
				return {}
			
			if current_recipe.steps[next_step_index] != station_type:
				var next_station_type = current_recipe.steps[next_step_index]
				var next_station_name = stationPhase[next_station_type].name
				print("this dish needs %s next" % next_station_name)
				return {}
			

			if station_type == StationType.PREP:
				if not _consume_ingredients(current_recipe):
					print("not enough ingredients for " + current_recipe.display_name)
					return {}

			current_completed_steps.assign(completed)
			actor.held_item = {}

			var workingPhase = cookingPhase[CookingPhaseIds.WORKING]
			$PhaseLabel.text = workingPhase.name
			
			var time = current_recipe.time_limit / GameState.get_cook_speed_multiplier()
			$Timer.start(time)
						
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
						
			dish_completed.emit(current_recipe.id, station_type)
			
			var current = current_recipe
			var updated_steps = current_completed_steps.duplicate()
			updated_steps.append(station_type)
			actor.held_item = {
				"recipe_id": current_recipe.id,
				"completed_steps": updated_steps
			}
			
			current_recipe = null
			
			_set_cooking_phase(CookingPhaseIds.IDLE)
			
			return { "recipeId": current.id }
		_:
			return {}

func _consume_ingredients(recipe: RecipeData) -> bool:
	if not GameState.can_make_recipe(recipe.id):
		return false

	for ingredient_id in recipe.inputs:
		GameState.inventory.remove(ingredient_id, recipe.inputs[ingredient_id])

	return true

func _get_cooking_phase_info() -> CookingPhaseIds:
	return cookingPhase[currentCookingPhase]

func _set_cooking_phase(newPhase: CookingPhaseIds) -> void:
	currentCookingPhase = newPhase

func _on_timer_timeout():
	_set_cooking_phase(CookingPhaseIds.DONE)
	$PhaseLabel.text = cookingPhase[CookingPhaseIds.DONE].name
