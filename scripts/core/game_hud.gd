extends CanvasLayer

var zones: Dictionary

@onready var day_label = $Root/PersistentBar/DayLabel
@onready var money_label = $Root/PersistentBar/MoneyLabel

func _ready() -> void:
	zones = {
		&"top_right": $Root/TopRight,
		&"top_left": $Root/TopLeft,
		&"bottom_right": $Root/BottomRight,
		&"bottom_center": $Root/BottomCenter,
		&"bottom_left": $Root/BottomLeft,
	}
	
	day_label.text = "Day: %s" % GameState.day
	money_label.text = "$%s" % GameState.money
	
	GameState.day_changed.connect(_on_day_changed)
	GameState.money_changed.connect(_on_money_changed)

func _on_day_changed(day: int) -> void:
	day_label.text = "Day: %s" % day

func _on_money_changed(money: int) -> void:
	money_label.text = "$%s" % money

func get_zone(zone_name: StringName) -> MarginContainer:
	if zones.has(zone_name): 
		return zones[zone_name]
	else:
		push_warning("invalid HUD zone")
		return null
	
func clear_zone(zone_name: StringName) -> void:
	var current_zone = get_zone(zone_name)
	
	if current_zone == null:
		return
	
	for child in current_zone.get_children():
		child.queue_free()

func clear_all_zones() -> void:
	for zone in zones:
		clear_zone(zone)
