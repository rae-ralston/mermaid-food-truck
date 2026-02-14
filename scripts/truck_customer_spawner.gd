extends Node
class_name CustomerSpawner

var CustomerScene = preload("res://scenes/TruckCustomer.tscn")

var spawn_interval := 8.0
var line_origin: Vector2 = Vector2.ZERO
var line_spacing := 70.0
var customer_line: Array[Node2D] = []
var _parent_node: Node

func _ready() -> void:
	var timer := Timer.new()
	timer.one_shot = false
	timer.autostart = true
	timer.wait_time = spawn_interval
	timer.timeout.connect(_on_spawn_timer)
	add_child(timer)

func setup(incoming_parent_node) -> void:
	_parent_node = incoming_parent_node

func _on_spawn_timer() -> void:
	_spawn_customer()

func _spawn_customer() -> void:
	var recipe_keys := GameState.recipeCatalog.keys()
	var random_id: StringName = recipe_keys[randi() % recipe_keys.size()]
	
	var customer: Node2D = CustomerScene.instantiate()
	customer.setup(random_id)
	customer.customer_left.connect(_on_customer_left)
	customer_line.append(customer)
	_parent_node.add_child(customer)
	_reposition_line()
	
func _on_customer_left(customer: Node2D) -> void:
	customer_line.erase(customer)
	_reposition_line()

func _reposition_line() -> void:
	for i in customer_line.size():
		customer_line[i].position = line_origin + Vector2(i * line_spacing, 0)

func get_front_customer() -> Node2D:
	if (customer_line.is_empty()):
		return null
	else:
		return customer_line[0]
