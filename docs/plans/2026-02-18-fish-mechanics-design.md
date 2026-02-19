# Fish Mechanics Design

Part of the dive phase redesign. See `docs/plans/2026-02-18-dive-phase-redesign.md` for full context.

---

## Two Fish Types

Both fish have fixed patrol routes for MVP — predictable and learnable by the player. More unpredictable variants are a potential later addition for difficulty escalation, not an MVP concern.

---

## Passive Fish

A slow, skittish creature swimming a fixed patrol loop.

**Behavior:**
- Fixed patrol route
- Has a **flee radius** — if the player moves fast inside it, the fish bolts and resets to its patrol path
- No threat to the player

**Catching:**
- Caught with a **standard trap** (comes with the player at the start of every dive, limited quantity ~2-3)
- Place the trap in or near the patrol path via interact key, move away, return to collect
- No stealth required — patience and basic positioning

**Teaching role:**
Introduces two things: (1) traps as a mechanic, (2) that slow movement matters near animals. First lesson before the player encounters the dangerous fish.

---

## Dangerous Predator Fish

An aggressive creature with a visible detection radius. Pure hazard early in the game; huntable once the player unlocks the predator trap.

**Behavior:**
- Fixed patrol route
- Has a **detection radius** visible to the player
- Inside the radius: slow movement = undetected, fast movement = spotted
- When spotted: chases player, steals one ingredient on contact, deals 1 damage
- After stealing/hitting, returns to patrol (does not chase indefinitely)

**Early game (no predator trap):**
The player learns to read the patrol route and give it a wide berth. The detection radius makes it readable — you can see when you're in danger. The threat teaches stealth through natural consequences.

**Catching (after unlock):**
- **Predator trap** is a permanent store unlock — probably higher cost, possibly reputation-gated
- Once unlocked, the player carries predator traps per dive (limited quantity, separate from standard traps)
- Catching requires placing the predator trap in the fish's patrol path while staying undetected — slow movement through its detection radius to reach the placement spot
- The same stealth skill used to avoid the fish gets repurposed to hunt it

**Ingredient value:**
Higher than passive fish — the difficulty and unlock cost need a meaningful reward. Should enable a distinct recipe or be required for a premium dish.

---

## Shared Trap Mechanic

| | Standard trap | Predator trap |
|---|---|---|
| Unlocked | From day 1 | Store purchase (permanent) |
| Targets | Passive fish | Dangerous fish |
| Skill required | Basic positioning | Stealth + patrol reading |
| Placement | Interact key near patrol path | Interact key, requires being undetected |
| Quantity per dive | ~2-3 | ~1-2 (rarer, harder to use) |

Traps do not occupy inventory slots until the player picks up the catch.

---

## Skill Progression (Intentional)

The two fish types form a natural tutorial arc without explicit instruction:

1. **Passive fish** → learn traps, learn that slow movement matters near animals
2. **Dangerous fish (hazard phase)** → learn detection radius, learn patrol routes, learn to avoid
3. **Dangerous fish (hunting phase)** → combine both skills — stealth from lesson 1 applied offensively

No tutorial needed. Mechanics introduce themselves through play.

---

## Open Questions (resolve through playtesting)

- How long does it take a trap to fill? (Tune for pacing — too fast = trivial, too slow = frustrating)
- Does a nearby predator scare passive fish away from a standard trap?
- What happens to a placed trap if the player surfaces early? (Lost? Retrieved on next dive?)
- Does the predator return to patrol immediately after hitting the player, or linger/chase for a beat?
- Exact quantity of traps per dive — tune based on map size and desired pacing
- Predator trap store cost and reputation gate — tie to overall store balance
