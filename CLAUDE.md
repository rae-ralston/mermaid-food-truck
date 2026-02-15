# Mermaid Food Truck

Cozy underwater cooking management game built in Godot 4.6. Target: Steam release 2026. Currently working toward a polished vertical slice demo.

## Game Loop

6-phase day cycle: Dive Planning → Dive → Truck Planning → Truck → Results → Store

- **Dive**: Swim as a mermaid, gather ingredients from depth zones (shallow/mid/deep)
- **Truck**: Run food truck — customers order, player processes food through stations, delivers

## Architecture

- **Phase system**: Phases loaded dynamically by `PhaseManager`. Each extends `BasePhase` with `enter()`, `exit()`, `phase_finished` signal. Payloads pass data between phases.
- **GameState**: Autoload. Holds `day`, `money`, `reputation`, `inventory`, `upgrades`. Upgrade system with `UPGRADE_CONFIG` constants, `buy_upgrade()`, `get_upgrade_cost()`, multiplier getters (`get_swim_speed()`, `get_cook_speed_multiplier()`).
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

See `docs/game-design-doc.md` for full details on recipes, ingredients, and pricing.

## Truck Phase (working)

Core truck gameplay loop is functional. Key files: `scripts/core/phase_truck.gd`, `scenes/phases/PhaseTruck.tscn`.

**Stations** (`scripts/truck_station.gd`, `scenes/TruckStation.tscn`):
- Three single-purpose stations (PREP, COOK, PLATE) — player carries items between them
- Each is Area2D with `@export station_type`. Three-phase state machine: IDLE → WORKING → DONE
- Timer node (one_shot) drives work phase, duration from `RecipeData.time_limit`
- ProgressBar shows countdown. `dish_completed` signal on pickup, then resets to IDLE
- Stations check held item state: PREP rejects if holding, COOK/PLATE require held item

**Customer/Order system** (`scripts/truck_customer.gd`, `scripts/truck_customer_spawner.gd`, `scripts/truck_window_order.gd`, `scripts/truck_window_pickup.gd`, `scripts/order.gd`):
- `Order` (RefCounted): `recipe_id`, `status` (PENDING/COOKING/READY/FULFILLED), `customer_ref: Node2D`
- `TruckCustomer` (Node2D): sprite + data (`recipe_id`, `order` ref). `fulfill()` tweens fade-out then `queue_free()`. Emits `customer_left`.
- `CustomerSpawner` (Node): Timer-driven (~8s), manages FIFO `customer_line` array, positions customers with linear spacing. `get_front_customer()` for order taking.
- `OrderWindow` (Area2D interactable): `interact()` gets front customer, creates Order, emits `order_taken(order)`. Rejects if player holding or no customers.
- `PickupWindow` (Area2D interactable): `interact()` emits `order_fulfilled(recipe_id)`, clears held item.
- `PhaseTruck` orchestrates: connects signals, manages order queue, handles fulfillment (payment via `GameState.recipeCatalog[recipe_id].base_price`), calls `customer_ref.fulfill()`, refreshes HUD.

**HUD:** CurrentDishLabel (held item name), InventoryLabel (counts), OrdersPanel (order queue with recipe name + status, rebuilt dynamically).

**Player:** DiverController has `held_item: String` with setter emitting `held_item_changed`, `is_holding() -> bool`. Swim speed from `GameState.get_swim_speed()` (base 220 * multiplier).

**Design decisions:**
- Station holds finished dish until pickup (blocks station)
- Stations track recipe_id only — order matching at delivery
- Two windows: order (FIFO customer line) and pickup (any-order delivery)
- Payment happens at pickup
- Random recipe from all 5 (active menu system later)
- `held_item` is plain String (recipe_id) — upgrade to richer type when needed
- Cook speed affected by upgrade multiplier: `recipe.time_limit / GameState.get_cook_speed_multiplier()`

**Truck phase TODO (deferred):**
- Patience/timeout system — patience timer on customer, timeout = leaves + reputation hit
- Stage tracking — dishes should track completed stage so they can't repeat a station
- Cooking interruptions — cancel mid-work, recover or lose dish
- Reputation effects on tips, pricing, story progression

## Results Phase (working)

Display-only summary at end of each truck day. Truck phase passes `{ orders_filled, orders_lost, money_earned }` payload. Shows day summary, stats, total balance. Increments `GameState.day` on continue. Transitions to Store with empty payload.

Key files: `scripts/core/phase_results.gd`, `scenes/phases/PhaseResults.tscn`.

## Store Phase (working)

Upgrade shop between days. Player spends money on three upgrades (swim speed, cook speed, inventory capacity), each with 3 levels and escalating costs (`base_cost * (level + 1)`). Upgrades apply immediately. Transitions to Dive Planning.

Key files: `scripts/core/phase_store.gd`, `scenes/phases/PhaseStore.tscn`.

**Upgrade system:** Data in `GameState.UPGRADE_CONFIG` + `GameState.upgrades` dict (level per upgrade). Consumers pull multipliers — Diver calls `GameState.get_swim_speed()`, TruckStation divides timer by `GameState.get_cook_speed_multiplier()`, inventory capacity set directly in `apply_upgrade()`.

**Design decisions:**
- Payload-only for results (no persistent day history yet)
- Multiplier pattern for speed upgrades — base values stay where they belong, GameState provides modifiers
- Escalating cost model (base_cost * (level + 1))
- Immediate application on purchase

**TODO (deferred):**
- Some upgrades gated by reputation score (not just money)
- Per-recipe breakdown on results screen
- Results/store UI polish and animations

## Current Work

Remaining stub phases: **Dive Planning** (pick dive site) and **Truck Planning** (choose menu). Store phase closes the progression loop — next priority TBD.

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
