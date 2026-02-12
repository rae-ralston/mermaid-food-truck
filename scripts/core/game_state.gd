extends Node

var day: int = 1
var money: int = 0
var reputation: int = 0

var inventory: Inventory = Inventory.new()

var recipeCatalog: Dictionary = {}

func _ready() -> void:
	var dir := DirAccess.open("res://data/recipes/")
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var recipe = load("res://data/recipes/" + file_name)
			recipeCatalog[recipe.id] = recipe
		
		file_name = dir.get_next()

func reset_for_new_run() -> void:
	day = 1
	money = 0
	reputation = 0
	inventory = Inventory.new()

func start_new_day() -> void:
	pass
