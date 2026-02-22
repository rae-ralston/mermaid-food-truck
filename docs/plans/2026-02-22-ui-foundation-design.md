# UI Foundation Design

Phase transitions, persistent HUD shell, and pause menu. Establishes the UI infrastructure that all future polish builds on.

## TransitionOverlay

CanvasLayer autoload (layer 100) with a full-screen ColorRect. Provides an awaitable API that PhaseManager calls during phase switches.

### Scene structure

```
TransitionOverlay (CanvasLayer, layer=100)
└── ColorRect (full screen, starts transparent, mouse_filter=IGNORE)
```

### API

```gdscript
signal transition_midpoint  # emitted when screen is fully covered

func play(effect_name: StringName = &"fade_black") -> void
    # Fades out, emits transition_midpoint, fades in

func get_effect(effect_name: StringName) -> Dictionary
    # Returns tween config for the named effect
```

### PhaseManager integration

```gdscript
func switch_to(phase_id, payload) -> void:
    TransitionOverlay.play()
    await TransitionOverlay.transition_midpoint
    # ... existing swap logic (exit, queue_free, instantiate, enter) ...
    # fade-in happens automatically after midpoint
```

### Effect system

Effects stored as a dictionary mapping names to configs (duration, color, etc). `fade_black` is the default and only effect for now.

Future effects (shader dissolves, animated overlays) slot in by adding dictionary entries and handling them in play(). PhaseManager can pass an effect name, or a per-transition mapping dictionary can be added later. Per-transition mapping would look like:

```gdscript
var transition_effects: Dictionary = {
    [PhaseId.DIVE, PhaseId.TRUCK]: &"surface_wipe",
    [PhaseId.TRUCK, PhaseId.RESULTS]: &"fade_black",
}
```

Unmapped transitions fall back to default. Zero changes to the overlay's public API when adding new effects.

## GameHUD (Persistent HUD Shell)

CanvasLayer autoload (layer 50) with anchored zone containers and a persistent info bar. Phases opt into zones during enter()/exit().

### Scene structure

```
GameHUD (CanvasLayer, layer=50, process_mode=ALWAYS)
└── Root (Control, full_rect, Theme resource applied)
    ├── PersistentBar (HBoxContainer, anchored top, horizontal)
    │   ├── DayLabel ("Day 1")
    │   └── MoneyLabel ("$150")
    ├── TopLeft (MarginContainer, anchored top-left)
    ├── TopRight (MarginContainer, anchored top-right)
    ├── BottomLeft (MarginContainer, anchored bottom-left)
    ├── BottomCenter (MarginContainer, anchored bottom-center)
    └── BottomRight (MarginContainer, anchored bottom-right)
```

### API

```gdscript
func get_zone(zone_name: StringName) -> MarginContainer
    # Returns the named zone container. Phase adds its own children.

func clear_zone(zone_name: StringName) -> void
    # Removes all children from a zone.

func clear_all_zones() -> void
    # Convenience for phase cleanup.
```

### Persistent bar

Listens to GameState signals to update day/money. Always visible. Small, top edge of screen.

### Theme resource

Shared Theme .tres applied to the Root control. Defines base fonts, font sizes, panel StyleBoxes, button styles, label colors. Phases inherit from this when their content is added to a zone. Self-contained phases (planning, store, results) can reference the Theme on their own root Control for visual consistency without using zones.

### Phase usage pattern

Phases that need screen-edge HUD info (dive, truck) add content to zones:

```gdscript
func enter(payload: Dictionary) -> void:
    var orders_panel = preload("res://scenes/hud/TruckOrdersPanel.tscn").instantiate()
    GameHUD.get_zone(&"top_right").add_child(orders_panel)

func exit() -> void:
    GameHUD.clear_all_zones()
```

Self-contained phases (planning, store, results) may not use zones at all. No forced migration.

## PauseMenu

CanvasLayer autoload (layer 90) toggled with ESC. Pauses the game tree.

### Scene structure

```
PauseMenu (CanvasLayer, layer=90, process_mode=ALWAYS, visible=false)
└── Overlay (ColorRect, semi-transparent black, full screen)
    └── CenterPanel (PanelContainer, centered)
        ├── Title ("Paused")
        ├── ResumeButton
        ├── SettingsButton (stub for now)
        └── QuitButton
```

### Behavior

- `_unhandled_input()` listens for `ui_cancel` (ESC)
- Toggle: show overlay + pause tree, hide + unpause
- Consumes input event to prevent propagation
- ResumeButton = same as pressing ESC
- QuitButton calls `get_tree().quit()`
- SettingsButton is a stub (disabled or empty panel) until audio exists

### ESC priority chain

Multiple systems use ESC. Priority order (highest first):

1. **Backpack** — if open, ESC closes it (consumed, stops here)
2. **DevConsole** — if open, ESC closes it (consumed, stops here)
3. **PauseMenu** — toggles open/closed

Implementation: each system uses `_unhandled_input()`. Whichever handles ESC first calls `get_viewport().set_input_as_handled()`. PauseMenu adds a guard checking `DevConsole.visible` and backpack visibility before toggling.

## Layer ordering

| Layer | System | Purpose |
|-------|--------|---------|
| 100 | TransitionOverlay | Covers everything during transitions |
| 90 | PauseMenu | Above HUD, below transitions |
| 50 | GameHUD | Persistent HUD zones |
| (default) | DevConsole | Existing autoload |
| (default) | Phase scenes | Gameplay content |

## Backlog items (not in this design)

- Themed transition effects (bubble wipe, wave dissolve) — future, overlay is designed for it
- Per-phase HUD migration to zone system — incremental, truck phase first
- Settings screen content (volume sliders) — when audio exists
- Title screen — separate design
