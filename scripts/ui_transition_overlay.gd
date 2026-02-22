extends CanvasLayer

signal transition_midpoint

var SECONDS_TO_MIDPOINT = .5

func _ready() -> void:
	layer = 100

func play() -> void:
	var overlay = $Overlay
	var tween := create_tween()
	
	tween.tween_property(overlay, "color:a", 1.0, SECONDS_TO_MIDPOINT)
	tween.tween_callback(transition_midpoint.emit)
	tween.tween_property(overlay, "color:a", 0.0, SECONDS_TO_MIDPOINT)
