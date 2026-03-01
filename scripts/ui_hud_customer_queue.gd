extends PanelContainer

@onready var line_count = $HBoxContainer/LineCountLabel
@onready var customer_img = $HBoxContainer/CustomerImg

func setup(spawner: CustomerSpawner) -> void:
	line_count.text = "0"
	customer_img.visible = false
	spawner.customer_line_changed.connect(_on_customer_line_changed)
	
func _on_customer_line_changed(front_customer: Node3D, count: int) -> void:
	line_count.text = str(count)
	customer_img.visible = front_customer != null
