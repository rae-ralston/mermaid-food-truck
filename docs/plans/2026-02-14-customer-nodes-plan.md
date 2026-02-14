# Customer Nodes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace hardcoded orders with dynamic customers who arrive on a timer, line up at an order window, and auto-collect fulfilled orders.

**Architecture:** Four new pieces following Approach A from the design doc. Customer (data + sprite), CustomerSpawner (timer + line management), OrderWindow (interactable), and an updated Order class. PhaseTruck orchestrates via signals.

**Tech Stack:** Godot 4.6, GDScript with type hints, Area2D interaction pattern.

**Reference:** `docs/plans/2026-02-14-customer-nodes-design.md`

---

### Task 1: Add `customer_ref` to Order

**Files:**
- Modify: `scripts/order.gd`

**Step 1: Add the field**

Add a `customer_ref` variable to Order. It's a `Node2D` reference, null by default (hardcoded orders won't have one). Don't change `_init` — the ref gets set by OrderWindow after construction.

```gdscript
var customer_ref: Node2D = null
```

**Step 2: Verify no breakage**

Run the PhaseTruck scene in the editor. The hardcoded orders still work — `customer_ref` is just null and nothing reads it yet.

**Step 3: Commit**

```bash
git add scripts/order.gd
git commit -m "order: add customer_ref field for back-reference to customer node"
```

---

### Task 2: Create Customer scene and script

**Files:**
- Create: `scripts/customer.gd`
- Create: `scenes/Customer.tscn` (in Godot editor)

**Step 1: Write `customer.gd`**

```gdscript
extends Node2D
class_name Customer

signal customer_left(customer: Node2D)

var recipe_id: StringName
var order: Order = null

func setup(incoming_recipe_id: StringName) -> void:
	recipe_id = incoming_recipe_id

func fulfill() -> void:
	# Brief delay, then exit
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_leave)

func _leave() -> void:
	customer_left.emit(self)
	queue_free()
```

Notes:
- `setup()` instead of `_init()` because Node2D instances created from scenes don't support custom `_init` args.
- `fulfill()` uses a Tween: 0.5s pause, then 0.3s fade out, then cleanup. Simple visual feedback without animation framework.
- `customer_left` signal fires before `queue_free()` so the spawner can clean up its array.

**Step 2: Create the scene in Godot editor**

1. Scene > New Scene > Other Node > Node2D (root, rename to "Customer")
2. Attach `scripts/customer.gd` to root
3. Add child: Sprite2D
   - Create a new GradientTexture2D (like PickupWindow's pattern)
   - Use a warm color (e.g., orange/coral gradient) to distinguish from stations/windows
   - Size: 60x60
4. Save as `scenes/Customer.tscn`

**Step 3: Verify**

Instance the Customer scene manually in PhaseTruck (temporarily drag it under World), run the scene. You should see the colored square. Remove it after verifying.

**Step 4: Commit**

```bash
git add scripts/customer.gd scenes/Customer.tscn
git commit -m "customer: add Customer scene with sprite and fulfill logic"
```

---

### Task 3: Create CustomerSpawner

**Files:**
- Create: `scripts/customer_spawner.gd`

**Step 1: Write the script**

```gdscript
extends Node
class_name CustomerSpawner

const CustomerScene := preload("res://scenes/Customer.tscn")

@export var spawn_interval: float = 8.0
@export var line_origin: Vector2 = Vector2.ZERO
@export var line_spacing: float = 70.0

var customer_line: Array[Node2D] = []
var _parent_node: Node  # where to add Customer children (World)

func setup(parent_node: Node) -> void:
	_parent_node = parent_node

func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = spawn_interval
	timer.one_shot = false
	timer.autostart = true
	timer.timeout.connect(_on_spawn_timer)
	add_child(timer)

func _on_spawn_timer() -> void:
	_spawn_customer()

func _spawn_customer() -> void:
	var recipe_keys := GameState.recipeCatalog.keys()
	var random_id: StringName = recipe_keys[randi() % recipe_keys.size()]

	var customer: Node2D = CustomerScene.instantiate()
	customer.setup(random_id)
	customer.customer_left.connect(_on_customer_left)

	customer_line.append(customer)
	_parent_node.add_child(customer)
	_reposition_line()

func get_front_customer():
	if customer_line.is_empty():
		return null
	return customer_line[0]

func _on_customer_left(customer: Node2D) -> void:
	customer_line.erase(customer)
	_reposition_line()

func _reposition_line() -> void:
	for i in customer_line.size():
		customer_line[i].position = line_origin + Vector2(i * line_spacing, 0)
```

Notes:
- `setup(parent_node)` is called by PhaseTruck so spawned customers appear under World (sharing coordinate space with the diver and stations).
- `line_origin` and `line_spacing` are exports — set in inspector to position the line near the OrderWindow.
- `_reposition_line()` snaps all customers into position. Simple horizontal line. When a customer leaves, the rest shift forward.
- Timer is created in code (not a child node in a scene) since CustomerSpawner is just a Node added in PhaseTruck's `_ready`.

**Step 2: Verify**

We'll test this as part of Task 5 (PhaseTruck wiring). No point testing in isolation.

**Step 3: Commit**

```bash
git add scripts/customer_spawner.gd
git commit -m "customer-spawner: timer-driven spawning with line management"
```

---

### Task 4: Create OrderWindow scene and script

**Files:**
- Create: `scripts/order_window.gd`
- Create: `scenes/OrderWindow.tscn` (in Godot editor)

**Step 1: Write `order_window.gd`**

```gdscript
extends Area2D

signal order_taken(order: Order)

var spawner: CustomerSpawner

func interact(actor) -> Dictionary:
	if actor.is_holding():
		return {}

	var customer = spawner.get_front_customer()
	if customer == null:
		return {}

	var order := Order.new(customer.recipe_id)
	order.customer_ref = customer
	customer.order = order

	order_taken.emit(order)
	return {}
```

Notes:
- `spawner` reference is set by PhaseTruck after both nodes exist.
- Same `interact(actor) -> Dictionary` pattern as PickupWindow and TruckStation.
- Creates the Order, wires up `customer_ref` both ways, emits signal. PhaseTruck handles the queue.

**Step 2: Create the scene in Godot editor**

Follow the same pattern as `scenes/TruckPickupWindow.tscn`:
1. Scene > New Scene > Other Node > Area2D (root, rename to "OrderWindow")
2. Attach `scripts/order_window.gd` to root
3. Add child: CollisionShape2D with RectangleShape2D (size ~94x95, same as PickupWindow)
4. Add child: Sprite2D with GradientTexture2D
   - Use a different color from PickupWindow (e.g., green/teal gradient) so they're visually distinct
   - Size: 100x100
5. Save as `scenes/OrderWindow.tscn`

**Step 3: Commit**

```bash
git add scripts/order_window.gd scenes/OrderWindow.tscn
git commit -m "order-window: interactable Area2D that takes orders from front customer"
```

---

### Task 5: Wire everything into PhaseTruck

**Files:**
- Modify: `scenes/phases/PhaseTruck.tscn` (in Godot editor)
- Modify: `scripts/core/phase_truck.gd`

**Step 1: Add nodes to PhaseTruck scene**

In the Godot editor:
1. Instance `scenes/OrderWindow.tscn` as child of `World`, name it "OrderWindow"
   - Position it on the left side of the scene (e.g., `Vector2(150, 553)` — near the bottom, opposite side from PickupWindow)
2. Add a plain `Node` as child of `World`, name it "CustomerSpawner"
   - Attach `scripts/customer_spawner.gd`
   - In inspector, set `spawn_interval` to `8.0`
   - Set `line_origin` to near the OrderWindow (e.g., `Vector2(150, 640)` — below the window)
   - Set `line_spacing` to `70.0`

Save the scene.

**Step 2: Update `phase_truck.gd`**

Replace the hardcoded orders and add new wiring. Full updated script:

```gdscript
extends BasePhase

signal order_queue_updated(queue: Array[Order])

var order_queue: Array[Order] = []

func _ready() -> void:
	$HUD/Label.text = "Truck Phase - let's eat some tasty food"
	$HUD/Button.text = "go to next phase: results"
	$HUD/CurrentDishLabel.text = "Holding: Nothing"
	$HUD/Button.pressed.connect(_on_next)
	$World/Diver.held_item_changed.connect(_on_held_item_changed)

	$World/PickupWindow.order_fulfilled.connect(_on_order_fulfilled)

	# Customer system setup
	$World/CustomerSpawner.setup($World)
	$World/OrderWindow.spawner = $World/CustomerSpawner
	$World/OrderWindow.order_taken.connect(_on_order_taken)
	$World/CustomerSpawner.line_origin = $World/OrderWindow.position + Vector2(0, 90)

	_refresh_orders()

	GameState.inventory.inventory_changed.connect(_refresh_inventory)
	_refresh_inventory()

func _refresh_orders() -> void:
	for child in $HUD/OrdersPanel.get_children():
		child.queue_free()

	for item in order_queue:
		var item_label = Label.new()
		var order_status: String = " (" + Order.Status.keys()[item.status] + ")"
		var name = GameState.recipeCatalog[item.recipe_id].display_name

		item_label.text = name + order_status
		$HUD/OrdersPanel.add_child(item_label)

	order_queue_updated.emit(order_queue)

func _refresh_inventory() -> void:
	var lines: Array[String] = []
	lines.append("Inventory %d/%d" % [GameState.inventory.total_count(), GameState.inventory.capacity])
	lines.append("Kelp: %d" % GameState.inventory.get_count(Ids.ING_KELP))
	lines.append("Clam: %d" % GameState.inventory.get_count(Ids.ING_CLAM))
	$HUD/InventoryLabel.text = "\n".join(lines)

func _on_next() -> void:
	emit_signal("phase_finished", PhaseIds.PhaseId.RESULTS, {})

func _on_held_item_changed(item: String) -> void:
	if item == "":
		$HUD/CurrentDishLabel.text = "Holding: Nothing"
	else:
		var recipe: RecipeData = GameState.recipeCatalog[item]
		$HUD/CurrentDishLabel.text = "Holding: " + recipe.display_name

func _on_order_taken(order: Order) -> void:
	order_queue.append(order)
	_refresh_orders()

func _on_order_fulfilled(recipe_id: StringName) -> void:
	for order in order_queue:
		if order.recipe_id == recipe_id:
			var recipe_price = GameState.recipeCatalog[recipe_id].base_price
			GameState.money += recipe_price

			order.status = Order.Status.FULFILLED
			order_queue.erase(order)

			if order.customer_ref != null:
				order.customer_ref.fulfill()

			_refresh_orders()
			break
```

Key changes from current version:
- Lines 16-18 (hardcoded orders) removed
- Added `$World/CustomerSpawner.setup($World)` — tells spawner where to add customer children
- Added `$World/OrderWindow.spawner = $World/CustomerSpawner` — gives OrderWindow its spawner ref
- Added `$World/OrderWindow.order_taken.connect(_on_order_taken)` signal connection
- Added `line_origin` set relative to OrderWindow position (90px below it)
- New `_on_order_taken` function pushes order into queue
- `_on_order_fulfilled` now calls `order.customer_ref.fulfill()` (null-checked for safety)

**Step 3: Test the full flow**

Run PhaseTruck scene. Verify:
1. After ~8 seconds, a customer (colored square) appears near the OrderWindow
2. More customers arrive every ~8s, lining up horizontally
3. Walk to OrderWindow and interact (E) — order appears in HUD OrdersPanel
4. Cook the recipe through PREP → COOK → PLATE stations
5. Deliver to PickupWindow — order removed from HUD, customer fades out and disappears
6. Remaining customers shift forward in line
7. Walk to OrderWindow with nothing held — if no customers, nothing happens

**Step 4: Commit**

```bash
git add scenes/phases/PhaseTruck.tscn scripts/core/phase_truck.gd
git commit -m "phase-truck: wire customer spawner and order window, remove hardcoded orders"
```

---

### Task 6: Polish pass

**Files:**
- Possibly tweak: `scripts/customer_spawner.gd` (spawn_interval, line_spacing)
- Possibly tweak: `scripts/customer.gd` (fulfill timing)

**Step 1: Playtest and tune**

Run through several orders. Check:
- Is 8s spawn interval too fast/slow? Adjust `spawn_interval`
- Is the line spacing right? Do customers overlap?
- Does the fulfill fade feel good? Adjust tween timing in `customer.gd`
- Is the OrderWindow positioned well relative to stations?

**Step 2: Commit any tuning**

```bash
git add -u
git commit -m "customer-system: tune spawn interval and positioning"
```
