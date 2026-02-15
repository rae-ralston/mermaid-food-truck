extends BasePhase

var selected_recipes: Array[StringName] = []

func _ready() -> void:
	$PhaseLabel.text = "Plan Your Menu"
	$ContinueButton.text = "Start Cooking!"
	$ContinueButton.pressed.connect(_on_next)

func enter(_payload: Dictionary) -> void:
	$ContinueButton.disabled = true
	
	var lines: Array[String] = []
	for ingredient_id in [Ids.ING_KELP, Ids.ING_CLAM, Ids.ING_CORAL_SPICE, Ids.ING_GLOW_ALGAE, Ids.ING_SEA_SLUG]:
		var count = GameState.inventory.get_count(ingredient_id)
		if count > 0:
			lines.append("%s: %d" % [ingredient_id, count])
	$InventoryLabel.text = "Inventory:\n" + "\n".join(lines)
	
	for recipe_id in GameState.recipeCatalog.keys():
		var recipe = GameState.recipeCatalog[recipe_id]
		var container = HBoxContainer.new()
		container.name = "RecipeContainer"
		$Menu.add_child(container)
		
		var can_make = GameState.can_make_recipe(recipe_id)
		var disabled = not can_make
		var add_recipe_check = CheckBox.new()
		add_recipe_check.name = "AddRecipeCheck"
		add_recipe_check.text = "Add" if can_make else "❌"
		add_recipe_check.disabled = not can_make
		add_recipe_check.toggled.connect(_on_recipe_toggled.bind(recipe_id))
		container.add_child(add_recipe_check)
		
		var recipe_label = Label.new()
		recipe_label.name = "RecipeLabel"
		recipe_label.text = recipe.display_name
		container.add_child(recipe_label)

func _on_recipe_toggled(is_checked: bool, recipe_id: StringName) -> void:
	if is_checked:
		selected_recipes.append(recipe_id)
	else:
		selected_recipes.erase(recipe_id)
	$ContinueButton.disabled = selected_recipes.is_empty()

func _on_next() -> void:
	emit_signal("phase_finished", PhaseIds.PhaseId.TRUCK, { "active_menu": selected_recipes })
