# Mermaid Food Truck 🧜‍♀️

A cozy underwater cooking management game built in Godot 4.6. Dive for ingredients in waters that shift from cute to spooky, then run your food truck serving ocean-themed dishes.

## Game Loop

Each in-game day cycles through 6 phases:

**Dive Planning** → **Dive** → **Truck Planning** → **Truck** → **Results** → **Store**

- **Dive** — Swim through alien underwater environments gathering ingredients. Shallow waters are bright and strange; deeper waters are darker and more dangerous, with creatures that will steal from your pack if you're not careful.
- **Truck** — Run your food truck. Customers order from your menu and you prepare dishes by working through stations (Prep, Cook, Plate).
- **Store** — Spend earnings on upgrades between days.

## Running

Open the project in Godot 4.6 and run the main scene.

## Dev Console

Press backtick (`` ` ``) to toggle the debug console. Pauses the game while open.

| Command | Syntax | Description |
|---|---|---|
| `money` | `money [amount]` | Add money (default 500) |
| `add` | `add <ingredient> [amount]` | Add ingredient to inventory (default 1) |
| `stock` | `stock [amount]` | Add N of every ingredient (default 10) |
| `skip` | `skip <phase> [bare]` | Jump to phase with smart defaults, or `bare` for empty payload |
| `day` | `day [number]` | Set current day number |
| `upgrade` | `upgrade <id> [level]` | Set upgrade level (default 3) |
| `clear` | `clear` | Clear output log |
| `help` | `help` | Show commands |

**Phases:** `dive_planning`, `dive`, `truck_planning`, `truck`, `results`, `store`
**Ingredients:** `kelp`, `clam`, `coral_spice`, `glow_algae`, `sea_slug`
**Upgrades:** `swim_speed`, `cook_speed`, `inventory_capacity`

## Status

Early development — working toward a polished vertical slice demo. See `game-design-doc.md` for full MVP scope.
