extends Node

var day: int = 1
var money: int = 0
var reputation: int = 0

var inventory: Inventory = Inventory.new()

func reset_for_new_run() -> void:
	day = 1
	money = 0
	reputation = 0
	inventory = Inventory.new()

func start_new_day() -> void:
	pass
