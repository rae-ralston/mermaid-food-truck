extends Area3D

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
	},
	CookingPhaseIds.DONE: {
		"id": CookingPhaseIds.DONE,
		"name": "Food done, pick up!",
	}
}

var currentCookingPhase: CookingPhaseIds = CookingPhaseIds.IDLE
var current_recipe: RecipeData

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
		
			current_recipe = GameState.recipeCatalog[actor.held_item]

			if station_type == StationType.PREP:
				if not _consume_ingredients(current_recipe):
					print("not enough ingredients for " + current_recipe.display_name)
					return {}

			actor.held_item = ""

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
			actor.held_item = current_recipe.id
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
