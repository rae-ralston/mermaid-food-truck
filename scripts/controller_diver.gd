extends CharacterBody2D
class_name DiverController

signal interaction_performed(result: Dictionary)
signal held_item_changed(item_id: String)

@export var speed: float = 220.0
@onready var interaction_zone: Area2D = $InteractionZone

var nearby: Array[Area2D] = []
var held_item: String = "":
	set(value):
		held_item = value
		held_item_changed.emit(value)

func _ready() -> void:
	interaction_zone.area_entered.connect(_on_area_entered)
	interaction_zone.area_exited.connect(_on_area_exited)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		_try_interact()

func _physics_process(_delta: float) -> void:
	var input := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up"),
	)
	
	if input.length_squared() > 0.0:
		input = input.normalized()
	
	velocity = input * speed
	move_and_slide()

func _on_area_entered(area) -> void:
	if area.has_method("interact"):
		nearby.append(area)

func _on_area_exited(area) -> void:
	nearby.erase(area)

func _try_interact() -> void:
	nearby = nearby.filter(is_instance_valid)
	if nearby.is_empty():
		return

	var best: Area2D = null
	var best_score: float = -INF  # <-- FIX 1

	for candidate in nearby:
		if candidate.has_method("can_interact"):  # <-- FIX 2
			if not candidate.can_interact(self):
				continue

		var distance2: float = global_position.distance_squared_to(candidate.global_position)
		var score: float = -distance2

		if candidate.has_method("get_interaction_priority"):
			score += float(candidate.get_interaction_priority(self)) * 1_000_000.0

		if score > best_score:
			best_score = score
			best = candidate

	if best == null:
		return

	var result: Dictionary = best.interact(self)
	if result == null:
		result = {}

	emit_signal("interaction_performed", result)

func is_holding() -> bool: return held_item.length() > 0
