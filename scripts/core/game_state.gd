extends Node

var day: int = 1
var money: int = 0
var reputation: int = 0
var swim_speed: float = 220.0

var inventory: Inventory = Inventory.new()

var recipeCatalog: Dictionary = {}

var upgrades: Dictionary = {
	"swim_speed": 0,
	"cook_speed": 0,
	"inventory_capacity": 0,
}

const UPGRADE_CONFIG: Dictionary = {
	"swim_speed": {
		"max_level": 3,
		"base_cost": 50,
		"display_name": "Swim Speed"
	},
	"cook_speed": {
		"max_level": 3,
		"base_cost": 50,
		"display_name": "Cook Speed"
	},
	"inventory_capacity": {
		"max_level": 3,
		"base_cost": 75,
		"display_name": "Inventory Capacity"
	},
}

func _ready() -> void:
	var dir := DirAccess.open("res://data/recipes/")
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var recipe = load("res://data/recipes/" + file_name)
			recipeCatalog[recipe.id] = recipe
		
		file_name = dir.get_next()
	
	#inventory.add(&"kelp", 4)
	#inventory.add(&"clam", 3)
	#inventory.add(&"coral_spice", 2)

func reset_for_new_run() -> void:
	day = 1
	money = 0
	reputation = 0
	inventory = Inventory.new()

func start_new_day() -> void:
	pass

func get_swim_speed() -> float:
	return swim_speed * get_swim_speed_multiplier()

func get_swim_speed_multiplier() -> float:
	# base 1.0, 15% faster per level
	return 1.0 + (upgrades["swim_speed"] * 0.15)

func get_cook_speed_multiplier() -> float:
	# base 1.0, 15% faster per level
	return 1.0 + (upgrades["cook_speed"] * 0.15)

func _calculate_upgrade_cost(upgrade: Dictionary, level: int) -> int:
	return upgrade.base_cost * (level + 1)

func get_upgrade_cost(upgrade_id: String) -> int:
	var current_upgrade: Dictionary = UPGRADE_CONFIG[upgrade_id]
	var current_level: int = upgrades[upgrade_id]
	
	if current_upgrade.max_level <= current_level + 1:
		return -1
	
	return _calculate_upgrade_cost(current_upgrade, current_level)

func buy_upgrade(upgrade_id: String) -> bool:
	var current_upgrade: Dictionary = UPGRADE_CONFIG[upgrade_id]
	var current_level: int = upgrades[upgrade_id]
	if current_upgrade.max_level <= current_level + 1:
		return false
	
	var upgrade_cost: int = _calculate_upgrade_cost(current_upgrade, current_level)
	if upgrade_cost > money:
		return false
	
	money -= upgrade_cost
	upgrades[upgrade_id] = current_level + 1
	apply_upgrade(upgrade_id)
	return true

func apply_upgrade(upgrade_id: String) -> void:
	# cook speed and swim speed are calculated in controller_diver and truck_station, respectively
	if upgrade_id == "inventory_capacity":
		inventory.capacity = 12 + (upgrades["inventory_capacity"] * 4)

func can_make_recipe(recipe_id: StringName) -> bool:
	var recipe: RecipeData = recipeCatalog[recipe_id]
	for ingredient_id in recipe.inputs:
		if inventory.get_count(ingredient_id) < recipe.inputs[ingredient_id]:
			return false
	return true
