extends PanelContainer
class_name BackpackGrid

signal item_dropped(ingredient_id: StringName)

var backpack_inventory: Inventory = null
var _selected_index: int = -1
var _slots: Array = []

var _style_filled: StyleBoxFlat
var _style_empty: StyleBoxFlat
var _style_selected: StyleBoxFlat

func _create_styles() -> void:
	_style_filled = StyleBoxFlat.new()
	_style_filled.bg_color = Color(0.25, 0.3, 0.4, 1.0)
	_style_filled.border_color = Color(0, 0, 0, 0)
	_style_filled.border_width_top = 3
	_style_filled.border_width_bottom = 3
	_style_filled.border_width_left = 3
	_style_filled.border_width_right = 3
	_style_filled.corner_radius_top_left = 4
	_style_filled.corner_radius_top_right = 4
	_style_filled.corner_radius_bottom_left = 4
	_style_filled.corner_radius_bottom_right = 4

	_style_empty = StyleBoxFlat.new()
	_style_empty.bg_color = Color(0.18, 0.2, 0.25, 0.5)
	_style_empty.corner_radius_top_left = 4
	_style_empty.corner_radius_top_right = 4
	_style_empty.corner_radius_bottom_left = 4
	_style_empty.corner_radius_bottom_right = 4

	_style_selected = StyleBoxFlat.new()
	_style_selected.bg_color = Color(0.35, 0.45, 0.6, 1.0)
	_style_selected.border_color = Color(0.9, 0.85, 0.4, 1.0)
	_style_selected.border_width_top = 3
	_style_selected.border_width_bottom = 3
	_style_selected.border_width_left = 3
	_style_selected.border_width_right = 3
	_style_selected.corner_radius_top_left = 4
	_style_selected.corner_radius_top_right = 4
	_style_selected.corner_radius_bottom_left = 4
	_style_selected.corner_radius_bottom_right = 4

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_styles()
	$MarginContainer/VBoxContainer/DropButton.disabled = true
	$MarginContainer/VBoxContainer/DropButton.pressed.connect(_on_drop_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_backpack"):
		visible = not visible
		get_tree().paused = visible
		get_viewport().set_input_as_handled()
	elif visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		visible = false
		get_tree().paused = false
		get_viewport().set_input_as_handled()

func bind(inventory: Inventory) -> void:
	inventory.inventory_changed.connect(_rebuild)
	backpack_inventory = inventory
	_rebuild()

func _rebuild() -> void:
	var grid = $MarginContainer/VBoxContainer/GridContainer
	
	for child in grid.get_children():
		child.queue_free()
	_slots.clear()
	_selected_index = -1
	$MarginContainer/VBoxContainer/DropButton.disabled = true
	
	var nums: Array = [backpack_inventory.total_count(), backpack_inventory.capacity]
	$MarginContainer/VBoxContainer/HeaderLabel.text = "Backpack (%d/%d)" % nums
	
	var pack = backpack_inventory.to_dict()
	var backpack_items = pack.get("items", {})
	var capacity = pack.get("capacity", 0)
	
	var slot_index = 0
	for ingredient_id in backpack_items:
		var count = backpack_items[ingredient_id]
		for i in count:
			var img = TextureRect.new()
			img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			img.custom_minimum_size = Vector2(64, 64)
			var ingredient_data: IngredientData = load("res://data/ingredients/%s.tres" % str(ingredient_id))
			if ingredient_data and ingredient_data.sprite:
				img.texture = ingredient_data.sprite
			
			var slot = PanelContainer.new()
			slot.custom_minimum_size = Vector2(64, 64)
			slot.add_theme_stylebox_override("panel", _style_filled)
			slot.set_meta("ingredient_id", ingredient_id)
			slot.gui_input.connect(_on_slot_input.bind(slot_index))
			
			slot.add_child(img)
			grid.add_child(slot)
			_slots.append(slot)
			slot_index += 1
		
	while slot_index < capacity:
		var slot = PanelContainer.new()
		slot.custom_minimum_size = Vector2(64, 64)
		slot.add_theme_stylebox_override("panel", _style_empty)
		grid.add_child(slot)
		slot_index += 1

func _on_slot_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select(index)

func _select(index: int) -> void:
	# Deselect previous
	if _selected_index >= 0 and _selected_index < _slots.size():
		_slots[_selected_index].add_theme_stylebox_override("panel", _style_filled)

	_selected_index = index
	_slots[_selected_index].add_theme_stylebox_override("panel", _style_selected)
	$MarginContainer/VBoxContainer/DropButton.disabled = false

func _on_drop_pressed() -> void:
	if _selected_index < 0 or _selected_index >= _slots.size():
		return
	
	var slot = _slots[_selected_index]
	if not slot.has_meta("ingredient_id"):
		return
	
	var ingredient_id: StringName = slot.get_meta("ingredient_id")
	item_dropped.emit(ingredient_id)
