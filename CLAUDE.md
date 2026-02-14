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
2. ~~**Delivery**~~ ✓ Done — PickupWindow (Area2D interactable) emits `order_fulfilled(recipe_id)`. PhaseTruck's `_on_order_fulfilled` matches order by recipe_id, pays via `GameState.recipeCatalog[recipe_id].base_price`, updates status, removes from queue, refreshes HUD.
3. **Customer nodes** — Next up. Design doc: `docs/plans/2026-02-14-customer-nodes-design.md`. Approach A: four pieces:
   - **Customer.tscn** (Node2D) — sprite + data holder (`recipe_id`, `order` ref). `fulfill()` does brief delay + visual feedback then `queue_free()`. Emits `customer_left`. Not interactable.
   - **CustomerSpawner** (Node) — Timer-driven spawning (~8s interval). Manages `customer_line` array, positions customers near OrderWindow. `get_front_customer()` exposes front of line. Listens for `customer_left` to reposition line.
   - **OrderWindow.tscn** (Area2D) — interactable like PickupWindow. `interact()` gets front customer from spawner, creates Order with `customer_ref`, emits `order_taken(order)`. Rejects if player is holding something or no customers in line.
   - **Order updated** — new `customer_ref: Node2D` field for back-reference to customer node.
   - **PhaseTruck wiring** — connects `order_taken` signal, replaces hardcoded orders. `_on_order_fulfilled` also calls `order.customer_ref.fulfill()`.
   - **Design decisions:** random recipe from all 5 (active menu later), timed spawns, soft queue limit via spawn rate, auto-collect with brief delay (customer walking deferred).
4. **Timeout + consequences** — Patience timer on customer. Timeout = customer leaves, food wasted, reputation hit. Reputation will eventually affect tips, pricing, story progression.

**Customer/order design decisions:**
- Two windows: order window (customers line up, player takes orders) and pickup window (player delivers, customers auto-collect)
- Customer line is FIFO — orders taken in sequence
- Orders can be delivered to pickup window in any order — not tied to line position
- Payment happens at pickup
- Order tracks `recipe_id`, `status`, and `customer_ref` for back-reference to customer node

**Known TODO:**
- Dishes should track completed stage so they can't go through the same station twice (e.g., prepped item can only go to COOK, not back to PREP)
- Handle cooking interruptions — player can cancel a station mid-work (WORKING state), recovering or losing the dish, resetting the station
- Connect `dish_completed` signals in `phase_truck.gd` to track order fulfillment

**Still needed (later):**
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
