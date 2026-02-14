# Mermaid Food Truck

Cozy underwater cooking management game built in Godot 4.6. Target: Steam release 2026. Currently working toward a polished vertical slice demo.

## Game Loop

6-phase day cycle: Dive Planning → Dive → Truck Planning → Truck → Results → Store

- **Dive**: Swim as a mermaid, gather ingredients from depth zones (shallow/mid/deep)
- **Truck**: Run food truck — customers order, player processes food through stations, delivers

## Architecture

- **Phase system**: Phases loaded dynamically by `PhaseManager`. Each extends `BasePhase` with `enter()`, `exit()`, `phase_finished` signal. Payloads pass data between phases.
- **GameState**: Autoload. Holds `day`, `money`, `reputation`, `inventory`.
- **Inventory**: Capacity-based (default 12). Tracks items by ID. Signals `inventory_changed`.
- **Interaction system**: Diver's `InteractionZone` (Area2D) finds nearby objects. Interactables implement `interact()`, optionally `can_interact()` and `get_interaction_priority()`. Triggered with E key.

## Key Directories

- `scenes/` — .tscn files, phases live in `scenes/phases/`
- `scripts/` — GDScript, core systems in `scripts/core/`
- `resources/` — Resource class definitions (IngredientData, RecipeData, RecipeStepIds)
- `data/ingredients/` — .tres ingredient resources (all 5 exist; coral_spice, glow_algae, sea_slug missing sprites)
- `data/recipes/` — .tres recipe resources (all 5 exist, inputs/steps/prices match design doc)
- `assets/` — Sprites and art

## MVP Content

**Ingredients (5):** kelp, clam, coral_spice, glow_algae, sea_slug
**Recipes (5):** Kelp Wrap, Grandma's Glowing Soup, Clam Chowder, Spiced Kelp Bowl, Sea Slug Sushi

See `game-design-doc.md` for full details on recipes, ingredients, and pricing.

## Current Work: Truck Cooking Phase

Working on `scripts/truck_station.gd` + `scenes/TruckStation.tscn` + `scenes/phases/PhaseTruck.tscn`.

**What works:**
- TruckStation extends Area2D (matches interaction system pattern from Gatherable)
- Enums: `CookingPhaseIds` (IDLE, WORKING, DONE), `StationType` (PREP, COOK, PLATE)
- Each station is single-purpose — `@export var station_type` set in inspector, no cycling
- Timer node (one_shot) drives IDLE → WORKING → DONE cycle
- Player interacts to start work, timer counts down, interact again to pick up finished dish
- `dish_completed` signal emits recipe_id and station_type on pickup, then resets to IDLE
- ProgressBar on each station shows timer countdown (updated in _process)
- PhaseTruck scene wired up with three station instances (PREP, COOK, PLATE) under World/Stations
- Diver in scene, can walk between stations and interact
- HUD: CurrentDishLabel wired to `held_item_changed` signal (shows recipe display_name), InventoryLabel shows counts, OrdersPanel shows order queue with recipe name + status
- Order system: `Order` class (extends RefCounted) with `recipe_id`, `status` enum (PENDING/COOKING/READY/FULFILLED). Order queue (`Array[Order]`) managed in `phase_truck.gd`, `_refresh_orders()` rebuilds OrdersPanel labels dynamically. Test orders hardcoded for now.
- Player held item: DiverController has `held_item: String` with setter that emits `held_item_changed` signal, `is_holding() -> bool`
- Stations check held item state: PREP rejects if holding, COOK/PLATE require held item
- Stations take item from player on start (COOK/PLATE), give item on pickup (all)
- All 5 recipe .tres resources created with correct inputs, steps, prices
- Stations use RecipeData resources — `time_limit` from recipe drives timer, catalog lookup via `GameState.recipeCatalog`
- `GameState.recipeCatalog` loads all recipe `.tres` from `data/recipes/` on `_ready()`
- Diver positioned under World node (shares coordinate space with stations)

**Design decisions:**
- Stations are single-purpose (one PREP, one COOK, one PLATE) — player carries items between them
- Station holds finished dish until player picks it up (blocks station until pickup)
- Stations track recipe_id only, not order_id — order matching happens at delivery
- `held_item` is a plain String (recipe_id) for now — will upgrade to richer type when needed

**Next up — Customer/Order system (4 bites):**
1. ~~**Order data + HUD**~~ ✓ Done
2. **Delivery** — In progress on `add-pickup-window` branch. Pickup window script done (`scripts/truck_pickup_window.gd` — thin, just emits `order_fulfilled` with recipe_id and clears held item). PhaseTruck has `_on_order_fulfilled` handler but needs fixes before it works:
   - **Signal wiring wrong:** Line 14 connects `order_queue_updated` (PhaseTruck's own signal) to `_on_order_fulfilled` — should connect the pickup window's `order_fulfilled` signal instead (e.g., `$World/PickupWindow.order_fulfilled.connect(_on_order_fulfilled)`)
   - **Signal type mismatch:** `order_fulfilled` emits a `StringName` (recipe_id), but signal is declared as `order: Order`. Update the signal declaration in pickup window to `order_fulfilled(recipe_id: StringName)`
   - **Order matching:** `_on_order_fulfilled` uses `order_queue.find(recipe_id)` and `order_queue.erase(recipe_id)` — but `order_queue` contains `Order` objects, not strings. Need to loop through queue and match on `order.recipe_id` instead
   - **Missing:** Payment (`GameState.money += recipe.base_price`), status update (`order.status = Order.Status.FULFILLED`), call `_refresh_orders()` after fulfillment
   - **Still needs:** PickupWindow scene (`.tscn` with Area2D + CollisionShape2D), placed in PhaseTruck scene under World
   - **`order_queue_updated` signal on line 3/36:** Currently emitted inside `_refresh_orders()` — may not be needed since we simplified the pickup window to not track orders locally. Can remove unless needed later.
3. **Customer nodes** — Visual node with sprite, spawns at order window, gets in line (FIFO). Player interacts with front-of-line customer to take order → pushes into order queue. Customer waits. Auto-picks up from pickup window when their order is fulfilled.
4. **Timeout + consequences** — Patience timer on customer. Timeout = customer leaves, food wasted, reputation hit. Reputation will eventually affect tips, pricing, story progression.

**Customer/order design decisions:**
- Two windows: order window (customers line up, player takes orders) and pickup window (player delivers, customers auto-collect)
- Customer line is FIFO — orders taken in sequence
- Orders can be delivered to pickup window in any order — not tied to line position
- Payment happens at pickup
- Order tracks `recipe_id` and `status`, eventually `customer_ref` for back-reference to customer node

**Known TODO:**
- Dishes should track completed stage so they can't go through the same station twice (e.g., prepped item can only go to COOK, not back to PREP)
- Handle cooking interruptions — player can cancel a station mid-work (WORKING state), recovering or losing the dish, resetting the station
- Connect `dish_completed` signals in `phase_truck.gd` to track order fulfillment

**Still needed (later):**
- Delivery mechanic (bite 2 above)
- Customer visual system (bite 3 above)
- Patience/timeout system (bite 4 above)

## Teaching Mode

The user is learning game development. Act as a teacher:
- Explain concepts and reasoning rather than just providing solutions
- Do NOT edit files directly unless the user explicitly asks you to
- Guide the user to write the code themselves
- When suggesting code, explain *why* it works, not just *what* to write

User background: 8 years professional frontend/fullstack (JS/Node/React). Solid engineering fundamentals. One prior Godot game jam project (heavily AI-assisted). New to game dev proper.

Calibration: Focus on how Godot does things — don't over-explain general programming concepts. Offer to go deeper on game dev or Godot-specific concepts when they come up, but don't assume they need it.

## Conventions

- GDScript with type hints
- Snake_case for files, PascalCase for scenes/classes
- Interaction pattern: objects implement `interact(_actor) -> Dictionary`
