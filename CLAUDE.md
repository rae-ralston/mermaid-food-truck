# Mermaid Food Truck

Cozy underwater cooking management game built in Godot 4.6. Target: Steam release 2026. Currently working toward a polished vertical slice demo.

## Game Loop

5-phase day cycle: Dive → Truck Planning → Truck → Results → Store

- **Dive**: Swim as a mermaid, gather ingredients (single map, no site selection)
- **Truck**: Run food truck — customers order, player processes food through stations, delivers

## Architecture

- **Phase system**: Phases loaded dynamically by `PhaseManager`. Each extends `BasePhase` with `enter()`, `exit()`, `phase_finished` signal. Payloads pass data between phases.
- **GameState**: Autoload. Holds `day`, `money`, `reputation`, `inventory`, `upgrades`. Property setters on `day` and `money` emit `day_changed` and `money_changed` signals. Upgrade system with `UPGRADE_CONFIG` constants, `buy_upgrade()`, `get_upgrade_cost()`, multiplier getters (`get_swim_speed()`, `get_cook_speed_multiplier()`). Recipe helpers: `can_make_recipe(recipe_id)` checks inventory has all ingredients for one serving.
- **Inventory**: Capacity-based (default 12). Tracks items by ID. Signals `inventory_changed`.
- **Interaction system**: Diver's `InteractionZone` (Area2D) finds nearby objects. Interactables implement `interact()`, optionally `can_interact()` and `get_interaction_priority()`. Triggered with E key.

## Key Directories

- `scenes/` — .tscn files, phases live in `scenes/phases/`
- `scripts/` — GDScript, core systems in `scripts/core/`
- `resources/` — Resource class definitions (IngredientData, RecipeData, RecipeStepIds)
- `data/ingredients/` — .tres ingredient resources (all 5 exist, all have sprites)
- `scenes/dive_sites/` — standalone dive site scenes (Shallows.tscn, CoralReef.tscn), loaded dynamically by Dive phase
- `data/recipes/` — .tres recipe resources (all 5 exist, inputs/steps/prices match design doc)
- `assets/` — Sprites and art. **Do not delete PNGs in `assets/characters/`** — they are extracted textures referenced by `.glb` files. Deleting them breaks character display silently (game runs but model is invisible).
- `assets/environments/` — Placeholder environment art (all temporary). `basic_rocks_tileset.png` (shared rock tileset), `shallows/` (parallax layers), `coral_reefs/` (parallax layers: `bg_far.png`, `bd_mid.png`, `fg_seaweed_01-03.png`)

## World Direction

The underwater world is alien, not realistic. Creatures, ingredients, and environments are not bound by real ocean biology — everything can be invented. This is a deliberate differentiator from Dave the Diver. Names, designs, and customer species should feel like they come from somewhere that doesn't exist.

## MVP Content

**Ingredients (5):** kelp, clam, coral_spice, glow_algae, sea_slug
**Recipes (5):** Kelp Wrap, Grandma's Glowing Soup, Clam Chowder, Spiced Kelp Bowl, Sea Slug Sushi

See `docs/game-design-doc.md` for full details on recipes, ingredients, and pricing.

## Truck Phase (redesigning)

Core truck gameplay loop is functional but undergoing major layout/camera redesign. See `docs/plans/2026-02-27-scope-simplification-and-truck-redesign.md` for full design notes.

Key files: `scripts/core/phase_truck.gd`, `scenes/phases/PhaseTruck.tscn`.

**Redesign summary:**
- **Layout:** Tight, compact food truck interior (1-2 steps between anything). Core fun is optimization/routing — juggling multiple orders through the pipeline.
```
        [Driving Cab / Front]
              |
     [PREP] [COOK] [PLATE]
              |
[Order Window] [gap] [Pickup Window]
           (customer side)
```
- **Camera:** Isometric perspective (easier to reason about truck layout, better visibility of all stations). Dive phase stays side view — different perspectives per phase is intentional.
- **Customer system:** Single portrait in order window + number badge for queue depth. No visible queue of character sprites.
- **Controls:** Keyboard (WASD + E) in both phases. Visible mermaid character.
- **Gap between windows:** Empty counter now, drink station later (backlog).

**Stations** (`scripts/truck_station.gd`, `scenes/TruckStation.tscn`):
- Three single-purpose stations (PREP, COOK, PLATE) — player carries items between them
- Each is Area2D with `@export station_type`. Three-phase state machine: IDLE → WORKING → DONE
- Timer node (one_shot) drives work phase, duration from `RecipeData.time_limit`
- `dish_completed` signal on pickup, then resets to IDLE
- Stations check held item state: PREP rejects if holding, COOK/PLATE require held item

**Customer/Order system** (`scripts/truck_customer.gd`, `scripts/truck_customer_spawner.gd`, `scripts/truck_window_order.gd`, `scripts/truck_window_pickup.gd`, `scripts/order.gd`):
- `Order` (RefCounted): `recipe_id`, `status` (PENDING/COOKING/READY/FULFILLED), `customer_ref`
- `CustomerSpawner` (Node): Timer-driven (~8s), manages FIFO `customer_line` array. `get_front_customer()` for order taking. Emits `customer_line_changed(front_customer, count)` on any line change.
- `OrderWindow` (Area2D interactable): `interact()` gets front customer, creates Order, emits `order_taken(order)`. Rejects if player holding or no customers.
- `PickupWindow` (Area2D interactable): `interact()` emits `order_fulfilled(recipe_id)`, clears held item.
- `PhaseTruck` orchestrates: connects signals, manages order queue, handles fulfillment (payment via `GameState.recipeCatalog[recipe_id].base_price`), refreshes HUD.

**Player:** DiverController has `held_item: Dictionary` (`{ "recipe_id": StringName, "completed_steps": Array[int] }`, empty `{}` when not holding) with setter emitting `held_item_changed`, `is_holding() -> bool`. Swim speed from `GameState.get_swim_speed()` (base 220 * multiplier).

**Design decisions:**
- Station holds finished dish until pickup (blocks station)
- Stations track recipe_id only — order matching at delivery
- Two windows on same side: order window and pickup window with gap between
- Payment happens at pickup
- Customers order from `active_menu` (set by Truck Planning payload), not all recipes
- `held_item` is a Dictionary with `recipe_id` and `completed_steps` — stations check and append their step on pickup
- Cook speed affected by upgrade multiplier: `recipe.time_limit / GameState.get_cook_speed_multiplier()`

**Truck phase TODO:**
- **Must have:** Patience/timeout system — patience timer on orders, timeout = customer leaves. Creates the time pressure that makes routing optimization matter.
- **Must have:** Station progress bar — lost in 3D conversion. Re-add.
- ~~**Customer portrait + badge UI**~~ ✓ Done — `CustomerQueuePanel` in bottom_left GameHUD zone, shows generic portrait + queue count via `customer_line_changed` signal
- ~~Stage tracking~~ ✓ Done
- **Backlog:** Per-customer portraits (needs portrait data on TruckCustomer, placeholder generic sprite for now)
- **Nice to have:** Cooking interruptions — cancel mid-work, recover or lose dish
- **Nice to have:** Reputation effects on tips, pricing, story progression
- **Backlog:** Drink station (in gap between order/pickup windows)

## Results Phase (working)

Display-only summary at end of each truck day. Truck phase passes `{ orders_filled, orders_lost, money_earned }` payload. Shows day summary, stats, total balance. Increments `GameState.day` on continue. Transitions to Store with empty payload.

Key files: `scripts/core/phase_results.gd`, `scenes/phases/PhaseResults.tscn`.

## Store Phase (working)

Upgrade shop between days. Player spends money on three upgrades (swim speed, cook speed, inventory capacity), each with 3 levels and escalating costs (`base_cost * (level + 1)`). Upgrades apply immediately. Transitions to Dive (skipping Dive Planning).

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

## Truck Planning Phase (working)

Player selects which recipes to offer before the truck opens. Shows inventory and recipe list with checkboxes. Recipes greyed out if player lacks all ingredients for one full serving (via `GameState.can_make_recipe()`). Must select at least 1 recipe. Passes `{ "active_menu": Array[StringName] }` payload to Truck phase. CustomerSpawner picks randomly from `active_menu` only.

Key files: `scripts/core/phase_truck_planning.gd`, `scenes/phases/PhaseTruckPlanning.tscn`.

## Dive Planning Phase (cut)

Removed to simplify scope. Single dive map loads automatically — no site selection. Can add site choice back later as a progression reward. Store phase transitions directly to Dive.

Previous files still exist (`scripts/core/phase_dive_planning.gd`, `scenes/phases/PhaseDivePlanning.tscn`) but phase is skipped in the day cycle.

**Sites** (`scenes/dive_sites/`):
- **Shallows** — sea slug, glow algae, coral spice
- **Coral Reef** — clam, kelp

**Dive phase** (`scripts/core/phase_dive.gd`): Site-agnostic — loads any scene with the expected node structure (Gatherables, ExtractionZone, SpawnPoint). Currently loads a single hardcoded site. Designed to swap hand-designed scenes for procedural generation later with zero phase code changes.

**Payload flow:** Store emits empty payload → Dive loads single site, gathers ingredients, emits `{ "gathered": {...} }` → PhaseManager adds to inventory → Truck Planning receives for display.

**Parallax backgrounds** (`scripts/core/parallax_background.gd`): Sprite3D-based. Script reads camera XY each frame, offsets layer position by `camera_xy * (1.0 - scroll_factor)`. `@export scroll_factor: Vector2` — lower = moves less (background), higher = moves more. Coral Reef has 2 background layers (far at Z=-2, mid at Z=-1). Foreground parallax doesn't work well for free-roaming movement — foreground elements (seaweed etc.) should be placed as static world objects instead.

**Dive camera**: Orthographic, size 4 (was 10, zoomed in for better character readability). Sits at Z=8, follows diver on XY plane with lerp smoothing + velocity-based look-ahead (`diver_camera_follow.gd`).

**Parallax art sizing**: At ortho size 4, viewport shows ~4 units tall. Target ~1300px tall for full-screen layers at 1080p. `pixel_size = desired_world_height / texture_pixel_height`. Procreate DPI doesn't matter (72 is fine) — only canvas pixel dimensions affect the game.

## Dive Backpack (working)

Capacity-limited inventory for the dive phase. Player presses Tab (or Escape to close) to open a grid overlay showing gathered items. Items can be dropped to make room — spawns a re-gatherable Gatherable at the diver's position with a 10s despawn timer. Backpack merges into truck inventory on extraction.

Key files: `scripts/core/phase_dive.gd`, `scripts/dive_backpack.gd`, `scenes/DiveBackpack.tscn`.

**Data model:**
- `GameState.inventory` — unlimited truck pantry (`capacity = 999999`), accumulates across dives
- Dive backpack — fresh `Inventory` instance per dive, capacity from `GameState.get_backpack_capacity()` (base 12 + 4 per upgrade level)
- `Gatherable.interact()` returns data without self-destructing. Caller decides: `consume()` to remove, `cancel_harvest()` to reject.
- `Gatherable.create_dropped()` — static factory for spawning dropped items at scale 0.2 with despawn timer.

**UI:** `BackpackGrid` (PanelContainer) with GridContainer (4 columns). Slots have three visual states via StyleBoxFlat: filled, empty (dimmed), selected (yellow border). `process_mode = ALWAYS` so Tab/Escape input works while paused. HUD also set to `PROCESS_MODE_ALWAYS`.

**Deferred:**
- Recipe preview in backpack
- Truck inventory preview
- Drag-and-drop grid reordering
- Dropped item animation (float downward, shrink over 10s before despawn)

## Dev Console (working)

Text-based debug console toggled with backtick (`` ` ``). Autoload singleton with its own CanvasLayer (renders above everything). Pauses the game tree while open. Commands: `money`, `add`, `stock`, `skip`, `day`, `upgrade`, `help`, `clear`. Command history with up/down arrows.

Key files: `scripts/core/dev_console.gd`, `scenes/main/DevConsole.tscn`.

**Architecture:** CanvasLayer autoload with `process_mode = ALWAYS`. PanelContainer > VBoxContainer > RichTextLabel (output) + LineEdit (input). Commands parsed via `split()` + `match` statement — adding a new command means adding one match branch and one `_cmd_*` function.

**Phase skipping:** `skip <phase>` uses smart default payloads (e.g. truck gets all recipes + stocked ingredients). `skip <phase> bare` passes empty payload. Phases dict maps name strings to `PhaseIds.PhaseId` enums + default payloads.

**Known issue:** LineEdit loses focus after submitting a command — requires clicking back into the input field. Likely a Godot focus quirk with paused trees.

**TODO (deferred):**
- Customer/order spawning commands
- Game speed controls
- Fix LineEdit focus persistence
- Strip from production builds

## Scope Simplification (2026-02-27)

Simplified scope to focus on vertical slice. See `docs/plans/2026-02-27-scope-simplification-and-truck-redesign.md`.

**Key cuts:** Dive Planning phase removed (single map). Cooking interruptions, reputation effects, tips moved to nice-to-have. Dive complexity (stealth, HP, traps) is medium priority — playtest simple gathering first.

**Priority buckets:**
- **Must have:** Truck redesign (layout + camera + customer UI), GameHUD, patience/timeout, station progress bar
- **Should have:** Dive complexity (stealth/HP — if gathering feels flat)
- **Nice to have:** Cooking interruptions, reputation effects, tips, drink station

## GameHUD (working)

Persistent HUD shell — CanvasLayer autoload (layer 50) with zone system. See `docs/plans/2026-02-22-ui-foundation-design.md` for full design.

Key files: `scripts/core/game_hud.gd`, `scenes/HUD/GameHUD.tscn`, `resources/hud_theme.tres`.

**Scene structure:**
```
GameHUD (CanvasLayer, layer=50, process_mode=ALWAYS)
└── Root (Control, full_rect, Theme=hud_theme.tres, mouse_filter=IGNORE)
    ├── PersistentBar (HBoxContainer, anchored top-center)
    │   ├── DayLabel
    │   └── MoneyLabel
    ├── TopLeft (MarginContainer, mouse_filter=IGNORE)
    ├── TopRight (MarginContainer, mouse_filter=IGNORE)
    ├── BottomLeft (MarginContainer, mouse_filter=IGNORE)
    ├── BottomCenter (MarginContainer, mouse_filter=IGNORE)
    └── BottomRight (MarginContainer, mouse_filter=IGNORE)
```

**Important:** All non-interactive GameHUD nodes must have `mouse_filter = IGNORE` (2), otherwise the CanvasLayer (layer 50) blocks mouse input from reaching game UI on lower layers.

**Theme:** `resources/hud_theme.tres` — DanhDa-Bold font, deep blue/teal PanelContainer with rounded corners, styled Button states (normal/hover/pressed/disabled), teal-white Label color, font size 20/24.

**Script:** Registered as autoload. Zone dictionary maps `StringName` → `MarginContainer`. API: `get_zone(zone_name) -> MarginContainer` (returns null + warning if invalid), `clear_zone(zone_name)`, `clear_all_zones()`. Persistent bar updates via GameState `day_changed`/`money_changed` signals.

**Customer Queue Panel** (`scenes/HUD/CustomerQueuePanel.tscn`, `scripts/ui_hud_customer_queue.gd`): PanelContainer with portrait (TextureRect, generic placeholder) + count label. `setup(spawner)` connects to `customer_line_changed` signal. PhaseTruck instantiates and adds to `bottom_left` zone in `enter()`, `clear_all_zones()` in `exit()`.

## Current Work

All phases functional — full day loop plays end to end. Currently building GameHUD and redesigning truck phase.

**Next priorities (in order):**
1. ~~**Dev tools**~~ ✓ Done — debug console with backtick toggle
2. ~~**Dive backpack**~~ ✓ Done — capacity-limited backpack with grid UI, drop-to-world
3. ~~**Dive camera smoothing**~~ ✓ Done — lerp follow + velocity-based look-ahead
4. ~~**Dive parallax backgrounds**~~ ✓ Done — Coral Reef has 2 background layers, camera ortho size tuned to 4
5. ~~**GameHUD script**~~ ✓ Done — zone system, persistent bar with signals, registered as autoload
6. ~~**Customer portrait + queue badge**~~ ✓ Done — CustomerQueuePanel in bottom_left zone, generic portrait + count
7. **Truck layout tightening** — compact spacing, both windows on customer side, isometric camera
8. **Customer patience/timeout** — time pressure that makes routing matter
9. **Dive level blockout** — set up GridMap, build playable layout
10. **UI foundation (remaining)** — TransitionOverlay, PauseMenu (see design doc)
11. **Wire up mermaid .glb animations** — integrate with DiverController states
12. **Game feel / juice** — tweens, particles, basic SFX

## Roadmap

### Architecture
- ~~**3D conversion**~~ ✓ Done — dive + truck converted to 3D (orthographic Camera3D, CharacterBody3D, Area3D). Test .glb sprite integrated for diver. See `docs/plans/2026-02-18-3d-conversion-design.md`.
- **.glb character integration** — drop mermaid_diver.glb and mermaid_truck.glb into the converted scenes. Validate pipeline end to end (Procreate → Moho → .glb → Godot → in-scene animation).
- **Moho multi-state animation export** — Moho file has multiple animation states but only idle came through in the .glb export. Investigate how to export multiple animation clips (idle, walk, carry, etc.) from Moho into a single .glb so Godot's AnimationPlayer sees all clips. Naming convention: suffix `-loop` for auto-looping on Godot import.

### Gameplay systems
- ~~**Truck Planning phase**~~ ✓ Done
- ~~**Dive Planning phase**~~ Cut — single map, no site selection (see Scope Simplification)
- ~~**Ingredient consumption**~~ ✓ Done — PREP station deducts ingredients via `_consume_ingredients()` in `truck_station.gd`
- ~~**Dive backpack**~~ ✓ Done — capacity-limited backpack with grid UI. Tab to open/close (Escape also closes). Drop items to make room (spawns re-gatherable with 10s despawn). `inventory_capacity` upgrade applies to per-dive backpack, truck pantry is unlimited.
- ~~**Stage tracking**~~ ✓ Done — dishes track `completed_steps` via `held_item` Dictionary; stations reject dishes at the wrong step with a hint message
- **Truck phase redesign** (must have) — tight layout, isometric camera. Customer portrait + queue badge done.
- **Customer patience/timeout** (must have) — pressure during truck phase, timeout = customer leaves
- **Cooking interruptions** (nice to have) — cancel station mid-work, recover or lose dish
- **Reputation system** (nice to have) — affects tips, pricing, unlocks, story progression
- **Reputation-gated store upgrades** (nice to have) — some upgrades require money + high reputation
- **Predator trap** (nice to have) — store unlock; enables catching dangerous fish. See `docs/plans/2026-02-18-fish-mechanics-design.md`.

### Dive phase — mechanics (designed, not yet built — medium priority)
See `docs/plans/2026-02-18-dive-phase-redesign.md` for full design. Medium priority — playtest simple gathering first (backpack capacity already creates meaningful choices). Add complexity only if dive feels flat.
- **Stealth system** — proximity-reactive; predators have visible detection radii; slow = undetected, fast = spotted; cover (coral, rocks) breaks line of sight
- **Health & forced surface** — player has HP pool; predator contact deals damage + steals one ingredient; reach zero HP → forced to surface, losing some gathered ingredients
- **Escalating danger** — danger level ticks up over time; more predators, larger detection radii the longer you stay
- **Traps** — carried item (limited per dive); place near creature patrol routes, collect passively while gathering elsewhere
- **New ingredients** — 2 new passive fish types (different looks/patrol behaviors, both trappable via standard traps); plus 2 new carnivore-friendly recipes
- **Hazardous creature** — 1 dangerous fish type; aggros on proximity, steals ingredient on contact, deals damage; pure hazard in v1 (not catchable). See `docs/plans/2026-02-18-fish-mechanics-design.md` for full design including post-v1 catching mechanic.

### Dive levels

**GridMap tileset setup (next step):**
- `basic_rocks_tileset.png` in `assets/environments/` — shared rock tileset, tile size TBD (likely 16x16)
- Approach: build a MeshLibrary manually with 4-6 starter tiles (solid fill, top edge, side edge, corner, accent). Start small, add more later.
- Setup flow: create scene with MeshInstance3D per tile (QuadMesh + StandardMaterial3D with UV offset/scale into atlas) → Scene > Export As > MeshLibrary → save as .tres → add GridMap node to dive site, assign library, paint
- UV math: `uv1_scale` = `Vector3(1/cols, 1/rows, 1)`, `uv1_offset` = `Vector3(col * scale.x, row * scale.y, 0)`. Use Alpha Scissor transparency.
- World scale: 1 tile = 1 world unit as starting point. Diver currently operates in single-digit unit range. May need adjustment after seeing diver next to tiles.
- Deferred: `@tool` script to auto-generate MeshLibrary from tileset atlas (run once, regenerate when tiles change)

- **Block out dive levels** — build larger, playtestable dive sites using placeholder geo and rock sprites. Define walls, open areas, cover spots, and ingredient placement. Critical path for playtesting.
- Larger hand-designed dive levels (evolve from blockouts above)
- Multiple dive sites with different ingredient distributions
- Procedural dive level generation (layout, ingredient placement, depth zones)
- Dive hazards / obstacles (currents, creatures)

### Game feel / juice
- Screen shake on order completion or customer arrival
- Tween animations on station state changes (bounce, scale pop)
- Visual feedback on pickup/delivery (flash, scale pop)
- Particle effects — bubbles (swimming), steam (cook station), sparkle (completed dish)
- ~~**UI transitions**~~ Designed — fade-to-black overlay with future-proofed effect system. See `docs/plans/2026-02-22-ui-foundation-design.md`. Themed wipe/dissolve effects deferred.
- ~~**Dive camera**~~ ✓ Done — lerp follow with smoothed velocity-based look-ahead (`follow_camera.gd`)
- Camera work — gentle sway in dive (deferred), framing in truck
- **Dropped item animation** — items dropped from backpack should float downward and gradually shrink over the 10s despawn timer, rather than popping in/out.

### Menus & persistence
- **Pause menu** — ESC to pause, resume/settings/quit options. CanvasLayer overlay like dev console.
- **Title screen** — start new game, load game, settings, quit
- **Save/load system** — auto-save at end of each day (between Results and Store), load from title screen
- **Settings screen** — music volume, SFX volume (accessible from title + pause menu)

### Dev tools (development only — strip from production builds)
- ~~Debug console / cheat menu~~ ✓ Done — add money, add ingredients, set upgrade levels, set day
- ~~Phase skipper~~ ✓ Done — jump to any phase with smart default payloads or bare
- Order/customer controls — spawn specific customers, set queue
- Game speed controls — fast forward through timers

### Art assets needed (all current art is placeholder)
Art direction: hand-painted illustrated 2D with skeletal animation. Painted in Procreate, rigged and animated in Moho, exported as `.glb` for Godot. See `docs/plans/2026-02-16-art-direction-design.md` for full pipeline, canvas sizes, and style test plan.

**Characters:** All characters use a naked base rig in Moho with outfit/species layers on top. Rigged and animated in Moho, imported into Godot as `.glb`. Each `.glb` contains all animation clips for that character (idle, walk, carry, emotion states, etc.) and is read-only in Godot.

Mermaid has two versions: `mermaid_diver.glb` (adventure outfit, dive phase) and `mermaid_truck.glb` (casual outfit, truck phase). Customer variants (fish, crab, shark, etc.) each get their own `.glb` with shared animation clip names so code drives them identically.
**Ingredients (5):** kelp, clam, coral spice, glow algae, sea slug — world sprites + inventory icons
**Dishes (5):** kelp wrap, glowing soup, clam chowder, spiced kelp bowl, sea slug sushi — HUD/order icons
**Truck:** three distinct station sprites (prep, cook, plate), station state indicators, order window, pickup window, truck background/environment
**Dive:** parallax background layers per biome (2-axis scrolling, depth gradient baked in), foreground elements as individual pieces, extraction zone marker, gatherable world sprites, hazards/obstacles
**UI:** custom theme (fonts, panels, buttons), phase transition overlays, inventory icons, money/reputation icons, upgrade icons
**Effects:** bubble particles (swimming), steam/sizzle (cooking), sparkle/completion (dish done), screen transition effects

### Audio assets needed (likely outsourced)
**Music (looping tracks):** title/menu theme, dive phase (calm, underwater, exploratory), truck phase (upbeat, busy, cooking energy), results screen (chill, reflective), store phase (cozy, shopping), planning phases (preparation vibe — could share a track)
**Ambience:** underwater (bubbles, water flow, distant whale sounds), truck (crowd murmur, ocean nearby)
**SFX — Dive:** swimming/movement, ingredient pickup, extraction zone enter/exit, surfacing
**SFX — Truck:** station start (chop, sizzle, clink per type), station working loop, station complete ding, order taken, order delivered, customer arrival, customer happy/leaving
**SFX — UI:** button click, purchase upgrade, phase transition swoosh, money earned (cha-ching), error/can't afford, day complete fanfare
**SFX — General:** menu open/close, inventory add/remove

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
