# Dive Phase Redesign

## World Direction

The underwater world is alien, not realistic. Creatures, ingredients, and environments are not bound by real ocean biology. "Reef fish" and "deepsea predator" are archetypes — movement and behavior patterns — not species. What they actually look like is an open creative question. Names and designs will be invented, not borrowed from real marine life.

---

## Context & Inspirations

The dive phase needs genuine tension and decision-making. Current state: no way to lose, inventory cap is the only reason to surface. Target feel: **Dome Keeper** (tight cycles, risk/reward of going deeper, exploration on every run) meets the cozy aesthetic of the game. Dave the Diver is a reference to avoid — particularly spearfishing and action-oriented fishing mechanics.

Key differentiators from Dave the Diver:
- Mermaid is native to water (no oxygen/air mechanic)
- Fishing is passive (traps, not spears)
- Stealth is the core skill, not combat reflexes
- The truck is the game — diving is resourcing

---

## Core Loop Shape

Danger escalates the longer you stay in a dive. Every ~30 seconds a danger level ticks up: more predators appear, existing predators get slightly larger detection radii. Inventory filling is still the natural endpoint, but now there's a competing pressure — the longer you push for better ingredients, the harder it becomes to leave safely.

**The interesting decision:** Surface now with a safe haul, or push deeper/longer for better ingredients and risk a bad exit?

### Health & Forced Surface

- Player has a small HP pool (3–5 hits)
- Predator contact: deals 1 damage AND steals one ingredient from your pack
- HP reaches zero → forced to surface, losing a portion of gathered ingredients
- No death screen, no run wipe — just a costly surface. Cozy-compatible but consequential.

---

## Stealth System

Predators have a **visible detection radius** (subtle circle or atmospheric effect). Inside that radius:

- **Moving slowly** → undetected, predator ignores you
- **Moving fast** → spotted, predator gives chase

**Cover** (coral formations, rock overhangs) breaks line of sight — duck in to lose a chasing predator. Cover is terrain, not a special system. It serves double duty: environmental detail and functional stealth tool.

No constant stealth bar to manage. Default state is free movement. Tension spikes situationally when a predator is nearby.

### Safe Zones

Shallower areas have fewer and less dangerous predators. Danger scales with depth — the good ingredients are deeper, but so is the risk. Dense coral provides natural cover and acts as a refuge. Open deep water is the most exposed.

### Deferred

- Depth-gated danger zones (Option B from design exploration) — evaluate post-MVP once we can feel how Option A plays.

---

## Fishing: Traps & New Ingredients

Fishing is passive. No spears, no active chase mechanics.

### Trap Mechanic

- Player carries a limited number of traps per dive (carried item, not inventory slots)
- Place a trap near a fish's patrol area, gather other ingredients, return to collect
- Collected fish go into inventory as normal ingredients
- Traps don't occupy inventory slots until you pick up the catch

See `docs/plans/2026-02-18-fish-mechanics-design.md` for full fish mechanics design.

### Two New Fish Ingredient Types

**Reef Fish** (non-dangerous)
- Swims a slow patrol route
- Flees if player moves fast nearby
- Caught passively with a standard trap
- Pure cozy mechanic — patience and positioning, no risk
- New ingredient for carnivore-friendly recipes (TBD)

**Deepsea Predator Fish** (dangerous, name TBD)
- Large detection radius, aggressive
- Steals ingredients on contact
- Also a potential ingredient — the harvesting mechanic (special trap? lure-away? guards something you want?) is intentionally left open for prototyping. Spec this once we've played the basic system.
- Appears in deeper zones only

### Existing Ingredients — No Change

- **Clam** — hand-gather from ground
- **Sea slug** — hand-gather from ground
- **Kelp, glow algae, coral spice** — gathered from plants

---

## New Recipes (Scope Note)

Two new fish ingredients will require new carnivore-friendly recipes and potentially new customer types (carnivorous guests). This is a separate design task — not scoped here. For MVP: add the ingredients and the gathering mechanics; recipes and customer types follow.

---

## Map Design

**MVP:** Hand-designed maps. This gives full control over tuning the experience — predator placement, cover density, trap-worthy patrol routes, depth zone transitions.

**Future:** The system is designed to be generation-compatible. All mechanics are rule-based scatter operations:
- Predators: scatter by depth zone (deeper = more/stronger)
- Cover: part of terrain geometry, generated naturally
- Fish patrol routes: open water near terrain — abundant in any map
- No hand-crafted puzzle requirements, no guaranteed safe corridors needed

Procedural generation is a later upgrade that doesn't require rethinking these mechanics.

---

## Open Questions

- Name and visual design for the dangerous deepsea fish
- Harvesting mechanic for the dangerous fish as an ingredient
- How many traps can the player carry per dive? (Tuning question)
- Danger escalation rate — needs playtesting to feel right
- What do carnivore customers look like? What recipes do they want?
- Does trap capacity scale with upgrades? (Probably yes — natural upgrade path)
