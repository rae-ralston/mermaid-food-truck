# Dive Backpack Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a capacity-limited dive backpack with a grid overlay UI so the player can see and manage gathered ingredients during a dive.

**Architecture:** The dive phase creates a local `Inventory` instance (the backpack) with capacity derived from the `inventory_capacity` upgrade. `GameState.inventory` becomes unlimited (truck pantry). A new `BackpackGrid` Control scene reads from any `Inventory` instance and supports dropping items. Dropped items spawn as temporary re-gatherable `Gatherable` nodes.

**Tech Stack:** Godot 4.6, GDScript

**Design doc:** `docs/plans/2026-02-20-dive-backpack-design.md`

---

### Task 1: Make GameState.inventory unlimited

Remove the capacity constraint from the truck pantry so it accumulates freely across dives.

**Files:**
- Modify: `scripts/core/inventory.gd:43-52` (add method)
- Modify: `scripts/core/game_state.gd:8` (set unlimited capacity)
- Modify: `scripts/core/game_state.gd:98-101` (remove capacity from upgrade application)

**Step 1: Add an `add_checked()` method to Inventory**

The existing `add()` has its capacity check commented out. Rather than toggling behavior, add a new method that enforces capacity, and leave `add()` unchecked (truck pantry uses `add()`, backpack uses `add_checked()`).

In `scripts/core/inventory.gd`, add after the existing `add()` method (after line 52):

```gdscript
func add_checked(id: StringName, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if not has_space(amount):
		return false
	_items[id] = get_count(id) + amount
	emit_signal("inventory_changed")
	return true
```

**Step 2: Set GameState.inventory capacity to unlimited**

In `scripts/core/game_state.gd`, change line 8. The truck pantry never blocks adds, but set capacity high to be explicit:

```gdscript
# Before:
var inventory: Inventory = Inventory.new()

# After:
var inventory: Inventory = Inventory.new()  # Truck pantry — unlimited storage
```

And in `_ready()`, after `inventory = Inventory.new()` is created (or directly after line 8 in the var declaration area), add:

```gdscript
func _ready() -> void:
	inventory.capacity = 999999  # Unlimited truck pantry
	# ... rest of _ready
```

**Step 3: Remove capacity mutation from apply_upgrade()**

In `scripts/core/game_state.gd`, change `apply_upgrade()` (lines 98-101):

```gdscript
# Before:
func apply_upgrade(upgrade_id: String) -> void:
	# cook speed and swim speed are calculated in controller_diver and truck_station, respectively
	if upgrade_id == "inventory_capacity":
		inventory.capacity = 12 + (upgrades["inventory_capacity"] * 4)

# After:
func apply_upgrade(upgrade_id: String) -> void:
	# cook speed and swim speed are calculated at point of use
	# inventory_capacity upgrade is read at dive start when creating the backpack
	pass
```

**Step 4: Add a helper to get backpack capacity**

In `scripts/core/game_state.gd`, add a new method:

```gdscript
func get_backpack_capacity() -> int:
	return 12 + (upgrades["inventory_capacity"] * 4)
```

**Step 5: Test manually**

Run the game. Play through a full day loop (dive → truck planning → truck → results → store). Verify:
- Gathering still works (items still go into `run_gathered` dict for now)
- Truck planning still reads `GameState.inventory` correctly
- Store still shows inventory_capacity upgrade (buying it won't crash, but won't visibly change anything yet)

**Step 6: Commit**

```
feat: make truck inventory unlimited, add backpack capacity helper

Truck pantry (GameState.inventory) no longer has a capacity limit.
The inventory_capacity upgrade is now consumed via get_backpack_capacity()
at dive start instead of mutating the truck inventory directly.
```

---

### Task 2: Refactor Gatherable to support caller-controlled consumption

Currently `Gatherable.interact()` calls `queue_free()` on itself. The dive phase needs to be able to reject a harvest (backpack full) without consuming the Gatherable.

**Files:**
- Modify: `scripts/gatherable.gd:25-35`
- Modify: `scripts/controller_diver.gd:70-74`

**Step 1: Split interact() — return data without self-destructing**

In `scripts/gatherable.gd`, change `interact()`:

```gdscript
# Before:
func interact(_actor) -> Dictionary:
	if harvested or ingredient == null:
		return {}
	harvested = true
	queue_free()
	return {
		"type": "harvest",
		"items": { ingredient.id: amount }
	}

# After:
func interact(_actor) -> Dictionary:
	if harvested or ingredient == null:
		return {}
	harvested = true
	return {
		"type": "harvest",
		"items": { ingredient.id: amount },
		"source": self
	}

func consume() -> void:
	queue_free()

func cancel_harvest() -> void:
	harvested = false
```

Key changes:
- `queue_free()` removed from `interact()` — caller must call `consume()` explicitly
- `"source": self` added to result dict so the caller has a reference back to this Gatherable
- `cancel_harvest()` resets state if the pickup is rejected

**Step 2: Update phase_dive.gd to call consume()**

In `scripts/core/phase_dive.gd`, update the `"harvest"` branch of `_on_interaction()` (lines 30-33):

```gdscript
# Before:
"harvest":
	var harvested: Dictionary = result.get("items", {})
	_merge_into(run_gathered, harvested)
	_update_debug_ui(run_gathered)

# After:
"harvest":
	var harvested: Dictionary = result.get("items", {})
	var source = result.get("source")
	_merge_into(run_gathered, harvested)
	_update_debug_ui(run_gathered)
	if source and source.has_method("consume"):
		source.consume()
```

This preserves existing behavior — all harvests are accepted (capacity enforcement comes in Task 3).

**Step 3: Test manually**

Run the game, enter a dive, gather ingredients. Verify:
- Gatherables still disappear when gathered
- Items still appear in the debug loot label
- Extraction still works

**Step 4: Commit**

```
refactor: split Gatherable harvest into interact + consume

Gatherable.interact() no longer calls queue_free(). Callers must
call consume() to remove the node, or cancel_harvest() to reject.
Adds "source" key to harvest result for caller reference.
```

---

### Task 3: Replace run_gathered with backpack Inventory

Wire up the dive phase to use a real `Inventory` instance as the backpack, with capacity enforcement and the "backpack full" hint.

**Files:**
- Modify: `scripts/core/phase_dive.gd` (most of the file)

**Step 1: Replace run_gathered with backpack**

In `scripts/core/phase_dive.gd`, replace the `run_gathered` variable and update `enter()`:

```gdscript
# Before:
var run_gathered: Dictionary = {}
var extracted := false

# After:
var backpack: Inventory = null
var extracted := false
```

Update `enter()`:

```gdscript
func enter(payload: Dictionary) -> void:
	var dive_site = load(payload.dive_site) as PackedScene
	var site_instance := dive_site.instantiate()
	$World.add_child(site_instance)

	var spawn_point: Marker3D = site_instance.find_child("SpawnPoint")
	var extraction_zone = site_instance.find_child("ExtractionZone")

	$World/Diver.global_position = spawn_point.global_position

	extraction_zone.body_entered.connect(_on_extraction_body_entered)

	backpack = Inventory.new()
	backpack.capacity = GameState.get_backpack_capacity()
	extracted = false
	_refresh_loot_ui()
```

**Step 2: Update harvest handling with capacity check**

Replace `_on_interaction()`:

```gdscript
func _on_interaction(result: Dictionary) -> void:
	match result.get("type", ""):
		"harvest":
			var items: Dictionary = result.get("items", {})
			var source = result.get("source")
			var total_amount := 0
			for amt in items.values():
				total_amount += int(amt)

			if not backpack.has_space(total_amount):
				if source and source.has_method("cancel_harvest"):
					source.cancel_harvest()
				_show_message("Backpack full — press Tab to manage")
				return

			for id in items.keys():
				backpack.add_checked(id, int(items[id]))
			if source and source.has_method("consume"):
				source.consume()
			_refresh_loot_ui()
		"talk":
			_show_message(result.get("message", ""))
		"blocked":
			_show_message(result.get("message", "Can't."))
		_:
			pass
```

**Step 3: Update helper methods**

Remove `_merge_into()` and `_update_debug_ui()` (no longer needed). Update `_refresh_loot_ui()`:

```gdscript
func _refresh_loot_ui() -> void:
	if backpack == null:
		$HUD/InventoryLabel.text = ""
		return

	var lines: Array[String] = []
	lines.append("backpack (%d/%d):" % [backpack.total_count(), backpack.capacity])

	var dict := backpack.to_dict()
	var items: Dictionary = dict.get("items", {})
	var keys := items.keys()
	keys.sort()

	for id in keys:
		lines.append("  %s: %d" % [id, int(items[id])])

	$HUD/InventoryLabel.text = "\n".join(lines)
```

**Step 4: Update extraction to merge backpack into truck inventory**

Replace `_extract_and_finish()`:

```gdscript
func _extract_and_finish() -> void:
	if extracted: return
	extracted = true

	var gathered := backpack.to_dict().get("items", {})
	GameState.inventory.add_many(gathered)

	var payload: Dictionary = {
		"gathered": gathered
	}

	emit_signal("phase_finished", PhaseIds.PhaseId.TRUCK_PLANNING, payload)
```

**Step 5: Remove the gathered merge from PhaseManager**

In `scripts/core/phase_manager.gd`, line 44-45, remove the `gathered` handling since the dive phase now merges directly:

```gdscript
# Before:
func _on_phase_finished(next_phase: int, payload: Dictionary) -> void:
	if payload.has("gathered"):
		GameState.inventory.add_many(payload["gathered"])
	switch_to(next_phase, payload)

# After:
func _on_phase_finished(next_phase: int, payload: Dictionary) -> void:
	switch_to(next_phase, payload)
```

Note: The payload still carries `"gathered"` for display purposes (truck planning shows what was gathered). We just don't double-add to inventory.

**Step 6: Test manually**

Run the game:
- Dive and gather ingredients — verify debug label shows "backpack (X/12):"
- Gather until full (12 items) — verify "Backpack full" message appears
- Verify full Gatherables stay in the world (don't disappear)
- Extract — verify truck planning shows correct inventory
- Complete a full day loop — verify no crashes or missing items

**Step 7: Commit**

```
feat: replace run_gathered with capacity-limited backpack

Dive phase now uses an Inventory instance as the backpack. Capacity
is derived from the inventory_capacity upgrade. Rejects harvest when
full with a hint message. Merges into truck inventory on extraction.
```

---

### Task 4: Add "open_backpack" input action

Register the Tab key as the backpack toggle in the project input map.

**Files:**
- Modify: `project.godot` (input section)

**Step 1: Add the input action**

This is easiest done in the Godot editor: Project > Project Settings > Input Map. Add action `open_backpack`, bind to Tab key (physical keycode 4194306).

Alternatively, add to the `[input]` section of `project.godot`:

```
open_backpack={
"deadzone": 0.2,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194306,"key_label":0,"unicode":9,"location":0,"echo":false,"script":null)
]
}
```

**Step 2: Test**

Run the game, press Tab — nothing should happen yet (no handler wired), but verify no errors.

**Step 3: Commit**

```
feat: add open_backpack input action (Tab key)
```

---

### Task 5: Create the BackpackGrid UI scene

Build the grid overlay that displays backpack contents and supports dropping items.

**Files:**
- Create: `scripts/backpack_grid.gd`
- Create: `scenes/BackpackGrid.tscn`

**Step 1: Write the BackpackGrid script**

Create `scripts/backpack_grid.gd`:

```gdscript
extends PanelContainer
class_name BackpackGrid

signal item_dropped(ingredient_id: StringName)

const COLUMNS := 4

var _inventory: Inventory = null
var _slots: Array[PanelContainer] = []
var _selected_index: int = -1

@onready var grid: GridContainer = $MarginContainer/VBoxContainer/GridContainer
@onready var header_label: Label = $MarginContainer/VBoxContainer/HeaderLabel
@onready var drop_button: Button = $MarginContainer/VBoxContainer/DropButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	drop_button.pressed.connect(_on_drop_pressed)
	drop_button.disabled = true
	visible = false

func bind(inventory: Inventory) -> void:
	_inventory = inventory
	_inventory.inventory_changed.connect(_rebuild)
	_rebuild()

func _rebuild() -> void:
	# Clear existing slots
	for child in grid.get_children():
		child.queue_free()
	_slots.clear()
	_selected_index = -1
	drop_button.disabled = true

	if _inventory == null:
		return

	header_label.text = "Backpack (%d/%d)" % [_inventory.total_count(), _inventory.capacity]
	grid.columns = COLUMNS

	# Build item list from inventory
	var dict := _inventory.to_dict()
	var items: Dictionary = dict.get("items", {})
	var keys := items.keys()
	keys.sort()

	# Create filled slots
	var slot_index := 0
	for id in keys:
		var count: int = int(items[id])
		for i in count:
			var slot := _create_slot(StringName(id), slot_index)
			grid.add_child(slot)
			_slots.append(slot)
			slot_index += 1

	# Create empty slots to fill up to capacity
	while slot_index < _inventory.capacity:
		var slot := _create_empty_slot()
		grid.add_child(slot)
		_slots.append(slot)
		slot_index += 1

func _create_slot(ingredient_id: StringName, index: int) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(64, 64)

	var ingredient: IngredientData = _load_ingredient(ingredient_id)

	if ingredient and ingredient.sprite:
		var tex_rect := TextureRect.new()
		tex_rect.texture = ingredient.sprite
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.add_child(tex_rect)
	else:
		var label := Label.new()
		label.text = str(ingredient_id)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(label)

	slot.set_meta("ingredient_id", ingredient_id)
	slot.set_meta("slot_index", index)
	slot.gui_input.connect(_on_slot_input.bind(index))

	return slot

func _create_empty_slot() -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(64, 64)
	slot.modulate = Color(1, 1, 1, 0.3)
	return slot

func _on_slot_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select(index)

func _select(index: int) -> void:
	# Deselect previous
	if _selected_index >= 0 and _selected_index < _slots.size():
		_slots[_selected_index].modulate = Color.WHITE

	_selected_index = index

	if _selected_index >= 0 and _selected_index < _slots.size():
		var slot := _slots[_selected_index]
		if slot.has_meta("ingredient_id"):
			slot.modulate = Color(1, 1, 0.5)  # Highlight yellow
			drop_button.disabled = false
			return

	drop_button.disabled = true

func _on_drop_pressed() -> void:
	if _selected_index < 0 or _selected_index >= _slots.size():
		return
	var slot := _slots[_selected_index]
	if not slot.has_meta("ingredient_id"):
		return

	var ingredient_id: StringName = slot.get_meta("ingredient_id")
	emit_signal("item_dropped", ingredient_id)

func _load_ingredient(id: StringName) -> IngredientData:
	var path := "res://data/ingredients/%s.tres" % str(id)
	if ResourceLoader.exists(path):
		return load(path) as IngredientData
	return null
```

**Step 2: Create the BackpackGrid scene**

Create `scenes/BackpackGrid.tscn`. The node tree:

```
BackpackGrid (PanelContainer) — script: backpack_grid.gd
  MarginContainer
    VBoxContainer
      HeaderLabel (Label) — text: "Backpack"
      GridContainer — columns: 4
      DropButton (Button) — text: "Drop"
```

Set BackpackGrid anchors to center of screen. Set `process_mode = When Paused` on the root node.

This is easier to build in the Godot editor. The script expects these node paths:
- `$MarginContainer/VBoxContainer/HeaderLabel`
- `$MarginContainer/VBoxContainer/GridContainer`
- `$MarginContainer/VBoxContainer/DropButton`

**Step 3: Test in isolation**

Temporarily instance BackpackGrid in PhaseDive.tscn, bind it to a test Inventory with a few items, and verify:
- Grid shows items with sprites
- Empty slots are dimmed
- Clicking a slot highlights it
- Drop button enables when a slot is selected

**Step 4: Commit**

```
feat: add BackpackGrid UI scene

Grid overlay for viewing and dropping inventory items. Takes any
Inventory instance. Shows item sprites in a grid with empty slot
indicators and a drop button. Processes while paused.
```

---

### Task 6: Add dropped Gatherable spawning

Add the factory method to Gatherable for spawning dropped items with a despawn timer.

**Files:**
- Modify: `scripts/gatherable.gd`

**Step 1: Add the create_dropped() static method**

In `scripts/gatherable.gd`, add:

```gdscript
const DESPAWN_TIME := 10.0

static func create_dropped(ingredient_data: IngredientData, pos: Vector3) -> Gatherable:
	var scene: PackedScene = load("res://scenes/Gatherable.tscn")
	var instance: Gatherable = scene.instantiate() as Gatherable
	instance.ingredient = ingredient_data
	instance.amount = 1
	instance.global_position = pos
	return instance

func start_despawn_timer() -> void:
	var timer := Timer.new()
	timer.wait_time = DESPAWN_TIME
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(queue_free)
	add_child(timer)
```

Note: `create_dropped()` returns the instance but doesn't add it to the scene tree — the caller does that. And `start_despawn_timer()` is called separately after adding to the tree, because timers need to be in the tree to run.

Also update `_ready()` so the sprite updates even for code-spawned instances (it already does — `@onready` handles this).

**Step 2: Test manually**

This will be testable once wired into the backpack drop flow (Task 7). For now, verify the script parses without errors by running the game.

**Step 3: Commit**

```
feat: add Gatherable.create_dropped() factory for dropped items

Spawns a Gatherable from code with a 10-second despawn timer.
Used when the player drops items from the dive backpack.
```

---

### Task 7: Wire everything together in the dive phase

Connect the BackpackGrid to the dive phase — Tab toggles it, dropping an item spawns a Gatherable.

**Files:**
- Modify: `scripts/core/phase_dive.gd`
- Modify: `scenes/phases/PhaseDive.tscn`

**Step 1: Add BackpackGrid to PhaseDive.tscn**

In the Godot editor, instance `scenes/BackpackGrid.tscn` as a child of `HUD` in PhaseDive.tscn. Name it `BackpackGrid`. Set it to not visible by default.

Alternatively, the script can instantiate it in code (see step 2).

**Step 2: Update phase_dive.gd with backpack UI logic**

Add to `phase_dive.gd`:

```gdscript
@onready var backpack_grid: BackpackGrid = $HUD/BackpackGrid

func _ready() -> void:
	$HUD/LocationLabel.text = "Diving phase - swim baby, swim."
	$HUD/Button.text = "go to next phase: truck planning"
	$HUD/Button.pressed.connect(_extract_and_finish)
	$World/Diver.interaction_performed.connect(_on_interaction)
	backpack_grid.item_dropped.connect(_on_item_dropped)
	backpack_grid.visible = false

func enter(payload: Dictionary) -> void:
	# ... existing site loading code ...

	backpack = Inventory.new()
	backpack.capacity = GameState.get_backpack_capacity()
	backpack_grid.bind(backpack)
	extracted = false
	_refresh_loot_ui()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("open_backpack"):
		_toggle_backpack()

func _toggle_backpack() -> void:
	backpack_grid.visible = not backpack_grid.visible
	get_tree().paused = backpack_grid.visible

func _on_item_dropped(ingredient_id: StringName) -> void:
	if backpack == null:
		return
	if not backpack.remove(ingredient_id, 1):
		return

	var ingredient_data := load("res://data/ingredients/%s.tres" % str(ingredient_id)) as IngredientData
	if ingredient_data == null:
		return

	var dropped := Gatherable.create_dropped(ingredient_data, $World/Diver.global_position)
	$World.add_child(dropped)
	dropped.start_despawn_timer()

	_refresh_loot_ui()
```

**Step 3: Test the full flow**

Run the game and test:
1. Start a dive, gather a few ingredients — verify backpack label updates
2. Gather until full (12) — verify "Backpack full" message, Gatherable stays
3. Press Tab — verify grid overlay appears, game pauses
4. Click an item in the grid — verify it highlights, Drop button enables
5. Click Drop — verify item removed from grid, Gatherable appears at mermaid position
6. Press Tab to close — verify game unpauses
7. Walk to the dropped item and gather it — verify it goes back into backpack
8. Wait 10 seconds near a dropped item — verify it despawns
9. Extract — verify items merge into truck inventory, truck planning shows them

**Step 4: Commit**

```
feat: wire backpack grid into dive phase

Tab opens/closes the backpack overlay and pauses the dive.
Dropping items spawns temporary re-gatherable Gatherables at
the mermaid's position with a 10-second despawn timer.
```

---

### Task 8: Update CLAUDE.md

Document the new backpack system in CLAUDE.md so future sessions have context.

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Add backpack section under Dive phase**

Add a new section after the Dive Planning Phase section:

```markdown
## Dive Backpack (working)

Capacity-limited inventory for the dive phase. Player presses Tab to open a grid overlay showing gathered items. Items can be dropped to make room (spawns a re-gatherable with 10s despawn timer). Backpack merges into truck inventory on extraction.

Key files: `scripts/core/phase_dive.gd`, `scripts/backpack_grid.gd`, `scenes/BackpackGrid.tscn`.

**Data model:**
- `GameState.inventory` — unlimited truck pantry, accumulates across dives
- Dive backpack — fresh `Inventory` instance per dive, capacity from `GameState.get_backpack_capacity()` (base 12 + 4 per upgrade level)
- `Gatherable.interact()` returns data without self-destructing. Caller decides: `consume()` to remove, `cancel_harvest()` to reject.

**Deferred:**
- Recipe preview in backpack
- Truck inventory preview
- Drag-and-drop grid reordering
```

**Step 2: Update upgrade system note**

In the Store Phase section, update the upgrade description to clarify that inventory_capacity applies to the dive backpack, not the truck inventory.

**Step 3: Move "Stage tracking" TODO higher if needed**

Review the "Current Work" / "Next session priorities" section and add backpack if appropriate.

**Step 4: Commit**

```
docs: add dive backpack system to CLAUDE.md
```
