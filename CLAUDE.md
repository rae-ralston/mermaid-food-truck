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
- `data/ingredients/` — .tres ingredient resources (kelp, clam exist; coral_spice, glow_algae, sea_slug not yet created)
- `data/recipes/` — Empty, no recipe resources created yet
- `assets/` — Sprites and art

## MVP Content

**Ingredients (5):** kelp, clam, coral_spice, glow_algae, sea_slug
**Recipes (5):** Kelp Wrap, Grandma's Glowing Soup, Clam Chowder, Spiced Kelp Bowl, Sea Slug Sushi

See `game-design-doc.md` for full details on recipes, ingredients, and pricing.

## Current Work: Truck Cooking Phase

Working on `scripts/truck_station.gd` + `scenes/TruckStation.tscn`.

**What works:**
- TruckStation extends Area2D (matches interaction system pattern from Gatherable)
- Enums: `CookingPhaseIds` (IDLE, WORKING, DONE), `StationType` (PREP, COOK, PLATE)
- Timer node (one_shot) drives IDLE → WORKING → DONE cycle
- Player interacts to start work, timer counts down, interact again to advance
- Station transitions through PREP → COOK → PLATE → loops back to PREP
- PhaseLabel and StationLabel update to show current state
- ProgressBar on each station shows timer countdown (updated in _process)
- Tested and working in-game

**Next up:**
- Completion logic — signal when PLATE finishes instead of looping back to PREP
- Wire TruckStation into PhaseTruck scene (currently using standalone TruckStation.tscn for testing)

**Still needed (later):**
- Recipe data integration (recipes not yet defined as .tres resources)
- Customer system (spawning, ordering, patience timers)
- Delivery mechanic

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
