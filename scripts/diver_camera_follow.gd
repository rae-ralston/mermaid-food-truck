extends Camera3D

var _current_lead: Vector3 = Vector3.ZERO

@export var target: Node3D
@export var lerp_speed: float = 5.0
@export var lead_distance: float = 2.0
@export var lead_smoothing: float = 3.0

func _physics_process(delta: float) -> void:
	if target == null: return
	
	var desired_lead: Vector3 = target.velocity.normalized() * lead_distance
	_current_lead = _current_lead.lerp(desired_lead, lead_smoothing * delta)
	var desired_pos: Vector3 = target.global_position + Vector3(0, 0, 8) + _current_lead
	global_position = global_position.lerp(desired_pos, lerp_speed * delta)
