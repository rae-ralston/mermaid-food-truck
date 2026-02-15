extends BasePhase

const sites: Dictionary = {
	"coral_reef": "res://scenes/dive_sites/CoralReef.tscn",
	"shallows": "res://scenes/dive_sites/Shallows.tscn"
}

func _ready() -> void:
	$PhaseLabel.text = "Choose a Dive Site"
	$DiveSiteSelector/CoralReefButton.text = "Coral Reefs"
	$DiveSiteSelector/CoralReefButton.pressed.connect(_on_next.bind(sites["coral_reef"]))
	
	$DiveSiteSelector/ShallowsButton.text = "The Shallows"
	$DiveSiteSelector/ShallowsButton.pressed.connect(_on_next.bind(sites["shallows"]))

func enter(_payload: Dictionary) -> void:
	GameState.start_new_day()

func _on_next(next_dive_site: String) -> void:
	emit_signal("phase_finished", PhaseIds.PhaseId.DIVE, {"dive_site": next_dive_site})
