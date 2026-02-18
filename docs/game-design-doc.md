# Mermaid Food Truck — Design Doc

## Overview

A cozy underwater cooking management game. You play as a sea creature who
dives for ingredients and runs a food truck serving ocean-themed dishes.

**Target:** Steam release (2026)
**First milestone:** Polished vertical slice demo
**Art style:** Hand-painted illustrated 2D, skeletal animation (see `docs/plans/2026-02-16-art-direction-design.md`)

---

## Tone & Theme

The game has a dual personality:

**Dive phase — cute to spooky.** The surface and shallows are bright and
friendly. As the player dives deeper, the environment gets darker, stranger,
and more unsettling. Deeper = rarer ingredients, but also creepier. This
creates natural risk/reward tension without needing explicit fail states
in MVP.

**Truck phase — cozy and warm.** The food truck is a safe, inviting space.
Light time pressure from customers, but the vibe is friendly and satisfying.
The contrast with the dive makes returning to the truck feel like a relief.

Both phases share design language and color palette to feel like one world —
the truck is where you process the strange things you found in the deep.

---

## Day Loop

Each in-game day cycles through 6 phases:

Dive Planning → Dive → Truck Planning → Truck → Results → Store
│
┌───────────────────────────────────────────────┘
▼
Dive Planning (next day)

---

## Phase Details

### 1. Dive Planning

**What the player does:** Selects a dive site and chooses equipment before
heading out.

**MVP scope:** Single dive site (no choice yet), basic equipment selection
(bag size). This phase exists in MVP to establish the pattern — it becomes
more meaningful when multiple dive sites and equipment options are added.

**Reads:** GameState (unlocked sites, available equipment, current upgrades)
**Writes:** Nothing
**Payload out:** { dive_site_id, equipment }

---

### 2. Dive

**What the player does:** Swims through an underwater environment. Explores
shallow (cute) to deep (spooky) areas, gathering ingredients. Returns to
the extraction zone when ready.

**Depth as a design axis:**

- Shallow: common ingredients (kelp, clam), bright and friendly
- Mid-depth: uncommon ingredients (coral spice, glow algae), dimmer, stranger
- Deep: rare ingredients (sea slug), dark and unsettling

**Constraints:**

- Carrying capacity (inventory slots) — primary limiting factor
- No time limit, no air mechanic (player is a sea creature)

**MVP scope:** One hand-crafted map with depth zones, 5 ingredient types,
no hazards (atmosphere only).

**Future:** Procedural maps, multiple dive sites, hazards, light/pressure
mechanics.

**Reads:** GameState (inventory capacity, swim speed)
**Writes:** GameState.inventory (items added as they're picked up)
**Payload out:** { dive_summary } (for Truck Planning UI display)

---

### 3. Truck Planning

**What the player does:** Reviews gathered ingredients, sets the menu for
service by choosing which recipes to offer.

**MVP scope:** Player sees their inventory and available recipes. Selects
which recipes are "on the menu" for the day. Recipes that can't be made
(missing ingredients) are greyed out.

**Reads:** GameState (inventory, unlocked recipes)
**Writes:** Nothing
**Payload out:** { active_menu: Array[recipe_id] }

---

### 4. Truck

**What the player does:** Runs the food truck. Customers arrive and order
from the active menu. Player walks between stations to prepare dishes.

**Cooking flow:**

1. Customer arrives, places order (a recipe)
2. Player takes the order
3. Player processes the recipe through its required stations (Prep → Cook → Plate)
4. Each station: interact to start, progress bar fills, interact to collect
5. Deliver finished dish to customer

**Customer behavior:**

- Arrive over time, queue if not served
- Patience timer — if it runs out, customer leaves (lost sale)
- Light time pressure, not punishing

**MVP scope:** Progress bar cooking, 3 stations, fixed recipe prices,
basic customer queue.

**Future:** Mini-games at stations, reputation affecting tips/ratings,
variable pricing, hiring workers.

**Reads:** GameState (inventory, cook speed), payload (active_menu)
**Writes:** GameState.inventory (ingredients consumed), GameState.money (earned per order)
**Payload out:** { orders_filled, orders_lost, money_earned }

---

### 5. Results

**What the player does:** Reviews the day's performance.

**MVP scope:** Summary screen showing orders filled, orders lost, money
earned. "Continue" button to proceed.

**Reads:** Payload (orders_filled, orders_lost, money_earned)
**Writes:** Nothing (money already written during Truck phase)
**Payload out:** {} (empty)

---

### 6. Store

**What the player does:** Spends money on upgrades between days.

**MVP upgrades:**

- Swim speed (faster movement in Dive)
- Cook speed (faster progress bars in Truck)
- Inventory expansion (more carrying capacity in Dive)

**Future:** New recipes, cosmetics, equipment, dive site unlocks.

**Reads:** GameState (money, current upgrade levels)
**Writes:** GameState (money spent, upgrades applied)
**Payload out:** {} (empty)

---

## Data Model

### GameState (autoload — persists across phases, save-file data)

day: int
money: int
inventory: Inventory # persistent — items survive across phases
upgrades: {
swim_speed: int, # level 0-N, affects Diver speed
cook_speed: int, # level 0-N, affects station progress rate
inventory_capacity: int # level 0-N, affects max slots
}
unlocked_recipes: Array[StringName]

### Resources

**IngredientData** (exists)

- id, display_name, sprite

**RecipeData** (exists, needs integration)

- id, display_name, sprite
- inputs: { ingredient_id: amount } (e.g., { "kelp": 2, "clam": 1 })
- steps: Array[RecipeStep] (e.g., [PREP, COOK, PLATE])
- base_price: int
- time_limit: float (cooking time per step)

### MVP Ingredients (5)

| ID          | Name        | Depth Zone |
| ----------- | ----------- | ---------- |
| kelp        | Kelp        | Shallow    |
| clam        | Clam        | Shallow    |
| coral_spice | Coral Spice | Mid        |
| glow_algae  | Glow Algae  | Mid        |
| sea_slug    | Sea Slug    | Deep       |

### MVP Recipes (5)

| Recipe                 | Ingredients                       | Steps             | Price |
| ---------------------- | --------------------------------- | ----------------- | ----- |
| Kelp Wrap              | 2 kelp                            | Prep, Plate       | $     |
| Grandma's Glowing Soup | 2 glow_algae                      | Prep, Plate       | $     |
| Clam Chowder           | 2 clam, 1 kelp                    | Prep, Cook, Plate | $$    |
| Spiced Kelp Bowl       | 1 kelp, 1 coral_spice             | Prep, Cook, Plate | $$    |
| Sea Slug Sushi         | 1 kelp, 1 coral_spice, 1 sea_slug | Prep, Cook, Plate | $$$   |

---

## Vertical Slice Scope

### In (MVP)

- [ ] 6-phase day loop, fully playable
- [ ] 1 hand-crafted dive map with depth zones (shallow/mid/deep)
- [ ] 5 ingredient types across depth zones
- [ ] Carrying capacity as dive constraint
- [ ] 5 recipes across 2 price tiers
- [ ] Progress bar cooking at 3 stations
- [ ] Customer queue with patience timers
- [ ] Results summary screen
- [ ] Store with 3 upgrade types (swim, cook, inventory)
- [ ] Polished pixel art and UI
- [ ] Spooky-to-cozy tonal contrast
- [ ] Basic audio/music

### Out (Post-MVP)

- [ ] Reputation system and tipping
- [ ] Cooking mini-games
- [ ] Multiple dive sites
- [ ] Procedural map generation
- [ ] Dive hazards, light/pressure mechanics
- [ ] Recipe unlocks in store
- [ ] Cosmetics and decorations
- [ ] Hiring workers for the Food truck
