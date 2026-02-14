# Customer Nodes Design (Bite 3)

Adds dynamic customers to the truck phase, replacing hardcoded orders.

## Decisions

- Customers pick a random recipe from all 5 (active menu filtering added later)
- Customers arrive on a timer (no starting batch)
- Soft queue limit via spawn rate tuning (no hard cap)
- Player interacts with an OrderWindow node (not the customer directly)
- Fulfilled customers auto-collect with a brief delay, then disappear (walking to pickup window deferred to later)

## Architecture: Approach A — Customer + Spawner + OrderWindow

Four new pieces, each with a focused role:

### Customer (Node2D)

`Customer.tscn` / `customer.gd`

- `recipe_id: StringName` — assigned at spawn, what they want to order
- `order: Order` — null until the player takes their order at the OrderWindow
- `fulfill()` — brief delay (~0.5-1s) with visual feedback (flash/fade), then emits `customer_left` and `queue_free()`s
- Signal: `customer_left(customer: Node2D)`
- Placeholder sprite (colored rect)
- No Area2D, no collision — not interactable

### CustomerSpawner (Node)

`customer_spawner.gd` — child of `World` in PhaseTruck

- `@export var spawn_interval: float` — seconds between spawns (~8s starting value)
- `var customer_line: Array` — ordered list, index 0 is front of line
- Timer child (repeating, autostart) drives spawning
- `@export var order_window_position: Vector2` — line forms near OrderWindow
- Line positioning: each customer offset horizontally from order window position
- `get_front_customer() -> Customer` — returns front of line or null
- On spawn: instances Customer.tscn, assigns random recipe from `GameState.recipeCatalog.keys()`, adds to line, positions it
- On `customer_left`: removes from array, shifts remaining customers forward

### OrderWindow (Area2D)

`OrderWindow.tscn` / `order_window.gd`

- Area2D + CollisionShape2D + placeholder sprite (same pattern as PickupWindow)
- Holds reference to CustomerSpawner
- `interact(actor) -> Dictionary`:
  - Rejects if player is holding something
  - Gets front customer via `spawner.get_front_customer()`; returns empty if no customers
  - Creates `Order` from customer's `recipe_id`
  - Sets `customer.order = order`
  - Emits `order_taken(order: Order)`
- Thin script — bridges customer line to order queue

### Order (updated)

- New field: `customer_ref: Node2D` — back-reference to the Customer node, set by OrderWindow when order is taken

## Wiring in PhaseTruck

- `$World/OrderWindow.order_taken.connect(_on_order_taken)`
- `_on_order_taken(order)`: pushes order into `order_queue`, calls `_refresh_orders()`
- Remove hardcoded orders (lines 16-18 of current phase_truck.gd)
- Update `_on_order_fulfilled`: after payment/queue removal, call `order.customer_ref.fulfill()`
- CustomerSpawner listens for each customer's `customer_left` to reposition the line

## Fulfillment Data Flow

1. Spawner creates Customer (has `recipe_id`)
2. Player interacts with OrderWindow -> creates Order (has `recipe_id` + `customer_ref`) -> pushed to queue
3. Player cooks, delivers to PickupWindow -> `_on_order_fulfilled` finds Order -> pays, removes from queue, calls `customer.fulfill()`
4. Customer does brief reaction, emits `customer_left`, frees itself
5. Spawner repositions remaining customers
