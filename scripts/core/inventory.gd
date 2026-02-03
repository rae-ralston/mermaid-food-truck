extends Resource
class_name Inventory

signal inventory_changed

@export var capacity: int = 12
var _items: Dictionary = {}

func to_dict() -> Dictionary:
	var out := {}
	for key in _items.keys():
		out[str(key)] = _items[key]
	
	return {
		"capacity": capacity,
		"items": out
	}

func from_dict(data: Dictionary) -> void:
	capacity = data.get("capacity", capacity)
	_items.clear()
	var items: Dictionary = data.get("items", {})
	
	for key in items.keys():
		_items[StringName(key)] = int(items[key])
	
	emit_signal("inventory_changed")

func total_count() -> int:
	var total := 0
	
	for value in _items.values():
		total += int(value)
	
	return total

func has_space(amount: int = 1) -> bool:
	return total_count() + amount <= capacity

func get_count(id: StringName)-> int:
	return int(_items.get(id, 0))

func add(id: StringName, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	
	#if not has_space(amount):
		#return false
	
	_items[id] = get_count(id) + amount
	emit_signal("inventory_changed")
	return true

func remove(id: StringName, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	
	var current := get_count(id)
	if current < amount:
		return false
	
	var next := current - amount
	if next <= 0:
		_items.erase(id)
	else: 
		_items[id] = next
	
	emit_signal("inventory_changed")
	return true

func add_many(items: Dictionary) -> void:
	var hasChanged := false
	for k in items.keys():
		var id : StringName= k if (k is StringName) else StringName(str(k))
		var amt := int(items[k])
		if amt <= 0:
			continue
		_items[id] = get_count(id) + amt
		hasChanged = true
	if hasChanged:
		emit_signal("inventory_changed")
