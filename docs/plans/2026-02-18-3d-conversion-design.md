# 3D Conversion Design

## Why

All animated content — the mermaid, customers, cooking animations, stations — will be `.glb` files exported from Moho. `.glb` imports as Node3D. Running a 2D/3D hybrid indefinitely means constant friction: SubViewport per character, rendering overhead, z-ordering issues, and two coordinate systems to reason about simultaneously. Converting fully to 3D now, while the codebase is small, is cleaner than doing it later with more systems on top.

---

## Coordinate System & Camera

Side-on view. Characters move on the **X/Y plane**:
- X = horizontal movement
- Y = vertical movement
- Z = depth (used for layering — background, midground, foreground, characters, UI)

`Vector2(x, y)` → `Vector3(x, y, 0)` — movement logic maps 1:1.

**Camera:** `Camera3D` in orthographic projection, positioned on the positive Z axis looking toward origin. This reproduces a 2D side-on view exactly. Camera follows the player in dive (replaces Camera2D); stays fixed in truck.

**Parallax layers** get actual Z positions instead of z_index — more natural and directly matches the art direction doc's parallax layer design.

**UI stays 2D.** `CanvasLayer` nodes (HUD, menus, labels) always composite over the 3D viewport automatically. No changes to any UI code.

---

## Player Controller

| Before | After |
|---|---|
| `CharacterBody2D` | `CharacterBody3D` |
| `Area2D` (InteractionZone) | `Area3D` |
| `Vector2` velocity | `Vector3` velocity (z = 0) |
| `move_and_slide()` | `move_and_slide()` (same call) |
| `CollisionShape2D` | `CollisionShape3D` |

All interaction logic — priority scoring, signal emissions, `interact()` dispatch — is unchanged. Only node types change.

`.glb` character asset attaches as a `Node3D` child of `CharacterBody3D`. No SubViewport needed.

---

## Interactable Objects

Every `Area2D` that implements `interact()` becomes `Area3D`. This covers:
- Gatherables (dive sites)
- ExtractionZone (dive sites)
- TruckStation
- OrderWindow
- PickupWindow

The `interact()` interface contract is unchanged. Signal names, return types, and handler logic are unchanged.

`Marker2D` (SpawnPoint in dive sites) → `Marker3D`.

---

## Conversion Scope

### Phase 1 — Dive + Truck (do together)

The player controller is shared across both phases. Once the player is `CharacterBody3D`, every scene containing the player needs `Area3D` interactables. Dive and truck are converted as a unit.

**Dive:**
- `controller_diver.gd` → CharacterBody3D, Vector3
- `PhaseDive.tscn` → Camera3D orthographic, Node3D world
- `Shallows.tscn`, `CoralReef.tscn` → all Area2D → Area3D, Marker2D → Marker3D
- Gatherable scripts → Area3D

**Truck:**
- `PhaseTruck.tscn` → Camera3D orthographic (fixed), Node3D world
- `TruckStation.tscn` → Area3D
- `truck_window_order.gd`, `truck_window_pickup.gd` → Area3D

### Phase 2 — Everything else

Planning phases, Results, and Store have no characters or spatial gameplay. They are pure UI phases and require **no changes**.

---

## What Does Not Change

- `GameState` — no spatial data
- Phase system (`PhaseManager`, `BasePhase`, payloads, signals)
- All resource files (`IngredientData`, `RecipeData`, `.tres` files)
- `Order`, customer logic, spawner positioning (update Vector2 → Vector3 where needed)
- HUD and all UI scenes
- The `interact()` interface contract
- Signal names throughout

---

## Open Questions

- Camera follow behavior in dive: does the Camera3D track the player directly, or with smoothing? (Replicate whatever Camera2D currently does.)
- Collision shape sizing: what dimensions work for the orthographic scale? (Tune during conversion.)
- Z positions for depth layers: establish a convention (e.g. background = z -10, midground = z -5, characters = z 0, foreground = z 5, UI = CanvasLayer).
