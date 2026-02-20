# Dive Backpack — Inventory Access During Diving

## Overview

The mermaid can open her backpack during a dive to see what she's gathered and drop items to make room for better finds. The backpack is capacity-limited (upgradeable). The truck pantry is unlimited and accumulates across dives.

---

## Data Model

### Truck inventory (`GameState.inventory`)

Unlimited capacity. The persistent pantry that accumulates ingredients across dives. Remove the capacity constraint from this instance.

### Dive backpack

A fresh `Inventory` instance created at the start of each dive.

- Capacity: `12 + (upgrades["inventory_capacity"] * 4)` — same formula as today, just applied to the right object.
- Lives on the dive phase (replaces `run_gathered` dict).
- Gatherables add to the backpack. Blocked if full.
- On extraction: `GameState.inventory.add_many()` merges backpack contents into the truck pantry.
- On forced surface (future): lose a portion of backpack contents before merging.

### Upgrade rewiring

`apply_upgrade("inventory_capacity")` no longer modifies `GameState.inventory.capacity`. The upgrade level is read at dive start when constructing the backpack. The upgrade data still lives in `GameState.upgrades`.

---

## Pickup Behavior

- `Gatherable.interact()` returns a harvest dict but **no longer calls `queue_free()` itself**.
- The dive phase checks `backpack.has_space(amount)`.
  - **Success:** `backpack.add()`, then `gatherable.queue_free()`.
  - **Full:** Show "Backpack full — press [Tab] to manage" hint. Gatherable stays in the world, unharvested.

### Gatherable refactor

Move `queue_free()` out of `Gatherable.interact()`. The caller decides whether to consume the Gatherable based on backpack space. Add a way to reset the Gatherable if the harvest is rejected (set `harvested = false`).

---

## Drop Behavior

- Player selects an item in the backpack grid and drops it.
- `backpack.remove(ingredient_id, 1)` — drops one at a time.
- A new `Gatherable` is spawned at the mermaid's position with that ingredient's data.
- The dropped Gatherable has a ~10 second despawn timer. Fully re-gatherable before it despawns.

### Dropped Gatherable spawning

A factory method on Gatherable (e.g., `create_dropped(ingredient_data, position)`) that:
- Instantiates the Gatherable scene from code
- Sets ingredient and amount
- Attaches a one-shot despawn timer

---

## Backpack UI

### Trigger

Press Tab during dive to open/close. The dive pauses (`get_tree().paused = true`) while open.

### Layout

- Grid of slots (4 columns, rows scale with capacity).
- Each slot shows ingredient sprite + count badge.
- Empty slots visible but dimmed — player sees remaining space at a glance.
- Selecting a filled slot highlights it and shows a "Drop" action.
- No drag-and-drop for MVP.

### Scene structure

- `BackpackGrid` scene: `PanelContainer` with `GridContainer`.
- Each slot: `TextureButton` or `PanelContainer` with `TextureRect` + `Label`.
- Takes an `Inventory` reference, rebuilds on `inventory_changed` signal.
- `process_mode = PROCESS_MODE_WHEN_PAUSED` so it responds to input while paused.
- Reusable: takes any `Inventory` instance (dive, truck planning, etc.).

---

## Dive Phase Integration

### `phase_dive.gd` changes

- Replace `run_gathered: Dictionary` with `var backpack: Inventory`.
- `enter()`: create backpack with upgrade-derived capacity.
- `_on_interaction()` harvest handling: check `backpack.has_space()` before accepting. Show hint if full.
- Tab input toggles BackpackGrid visibility and pause state.
- `_extract_and_finish()`: merge backpack into `GameState.inventory` via `add_many()`, emit `phase_finished`.

### Signal flow

```
Gatherable.interact() → returns harvest dict (doesn't self-destruct)
  → PhaseDive checks backpack.has_space()
    → success: backpack.add(), gatherable.queue_free()
    → full: show hint, gatherable stays
```

---

## Deferred

- Recipe preview in backpack ("can I make X with this haul?")
- Truck inventory preview ("what do I already have back home?")
- Drag-and-drop reordering of grid slots
- Visual polish (open/close animations, drop effects)
- Sort/filter options

## Interactions with Planned Features

- **Forced surface** (dive redesign): lose a portion of backpack contents before merging.
- **Traps** (fish mechanics): trapped fish go into backpack like any other ingredient.
