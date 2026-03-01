extends Node
class_name CustomerSpawner

signal customer_line_changed(front_customer: Node3D, count: int)

var CustomerScene = preload("res://scenes/TruckCustomer.tscn")

var spawn_interval := 8.0
var line_origin: Vector3 = Vector3.ZERO
var line_spacing := 1.5
var customer_line: Array[Node3D] = []
var _parent_node: Node
var active_menu: Array[StringName] = []

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
	var recipe_keys := active_menu
	if (active_menu.is_empty()): return
	var random_id: StringName = recipe_keys[randi() % recipe_keys.size()]

	var customer: Node3D = CustomerScene.instantiate()
	customer.setup(random_id)
	customer.customer_left.connect(_on_customer_left)
	customer_line.append(customer)
	_parent_node.add_child(customer)
	_reposition_line()
	customer_line_changed.emit(get_front_customer(), customer_line.size())
	
func _on_customer_left(customer: Node3D) -> void:
	customer_line.erase(customer)
	_reposition_line()
	customer_line_changed.emit(get_front_customer(), customer_line.size())

func _reposition_line() -> void:
	for i in customer_line.size():
		customer_line[i].position = line_origin + Vector3(i * line_spacing, 0, 0)

func get_front_customer() -> Node3D:
	if (customer_line.is_empty()):
		return null
	else:
		return customer_line[0]
