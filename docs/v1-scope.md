# V1 Scope — Steam Demo / Open Beta

## What V1 Is

A polished, complete day loop that's fun to play for 30-60 minutes. Players experience the full game cycle (dive → truck → store → repeat) across a handful of days with enough variety to understand the game's potential. The goal is a Steam demo + open beta — get real players, get feedback, build the rest informed by what they want.

**Not a full game. A complete slice.**

---

## In Scope

### Core loop
- All 6 phases working and polished: Dive Planning → Dive → Truck Planning → Truck → Results → Store
- **5 days**, then a "demo complete" screen with a wishlist CTA. Tune once the loop length is known — if a day takes 20+ minutes, 5 may be too many; if it's 10 minutes, may need more.

### Programming systems
- **3D conversion** — dive + truck phases converted to 3D (orthographic Camera3D, CharacterBody3D, Area3D)
- **Stage tracking** — prevent dishes repeating a station
- **Customer patience/timeout** — patience timer, leaves + reputation/money hit on timeout
- **Dev tools** — debug console (stripped from release build)
- **Basic dive tension** — escalating danger over time, health pool, forced surface on zero HP
- **Hazardous creature** — one dangerous fish type; aggros on proximity, steals one ingredient on contact, deals 1 damage; fixed patrol route; pure hazard, not catchable in v1
- **Standard traps** — place near passive fish patrol route, collect passively; limited per dive
- **Title screen** — new game, continue, settings, quit
- **Save/load** — auto-save at end of each day
- **Settings** — music volume, SFX volume
- **Game feel** — tweens on station state changes, visual feedback on pickup/delivery, basic particle effects (bubbles, steam, sparkle)

### Content
- **Recipes:** 7 total — 5 existing + 2 new fish-based recipes for carnivore customers
- **Ingredients:** 7 total — 5 existing + 2 new passive fish types (different looks, different patrol behaviors, both trappable)
- **Customers:** 3-4 variants with patience/emotion states
- **Dive sites:** 2-3 hand-designed sites (Shallows and Coral Reef exist; 1 more optional)
- **Biomes:** 1 fully realized (Shallows/shallow zone aesthetic)
- **Upgrades:** existing 3 (swim speed, cook speed, inventory capacity) — no new upgrades for v1

### Art (produced by you)
- Mermaid diver (Moho rigged, animated: swim, gather, idle, surface)
- Mermaid truck (Moho rigged, animated: walk, idle, carry dish, interact)
- 3-4 customer characters (Moho rigged, emotion states: idle, impatient, happy, leaving)
- Truck environment background (painted in Procreate)
- Dive biome backgrounds — 1 biome, parallax layers (far, mid, foreground pieces)
- Gatherable world sprites (7 ingredients)

### Art (outsourced)
- Ingredient icons (7) + dish icons (7)
- UI theme — panels, buttons, fonts, custom theme applied globally
- Additional icon work as needed (upgrade icons, status icons)

### Audio (outsourced)
- Music: dive theme, truck theme, results/store theme, title theme
- SFX: station interactions, order taken/delivered, customer arrival/departure, UI clicks, money earned, error states, swimming/movement

---

## Explicitly Cut — Post-V1

These are good ideas. They're not v1 ideas.

| Feature | Why cut | When to revisit |
|---|---|---|
| Procedural map generation | Enormous scope, hand-designed maps are fine | After beta feedback confirms players want more map variety |
| Reputation system | Adds balance complexity, money is sufficient for v1 | Post-beta expansion |
| Reputation-gated upgrades | Depends on reputation system | Same |
| Dangerous fish as catchable ingredient | Hazard only in v1; predator trap unlock is post-beta | Post-beta, high value if players love the dive phase |
| Full stealth movement system (speed-based detection) | Predators aggro on proximity for v1; speed-based is refinement | Post-beta if dive feels too easy |
| More hazard types (currents, additional creatures) | 1 hazard type is enough to establish the mechanic | Post-beta based on whether players want harder dives |
| Multiple biomes | More art than 1 dev can do for a demo | Expansion content |
| More dive sites (beyond 2-3) | Hand-designing takes time | Add with biomes |
| More customer variants (beyond 3-4) | Art bottleneck | Expansion |
| More recipes (beyond 7) | Content expansion, not core | Post-beta based on player requests |
| Per-recipe results breakdown | Nice to have | Small post-launch update |
| Cooking interruptions | Complex, low priority | If players find truck too easy |
| Picnic area / outdoor seating | Major scope expansion | Only if game does well and warrants it |
| Story / lore | Not planned for this game | Never? Keep it gameplay-focused |

---

## The Line

When in doubt about whether something is v1: **ask if the game is fun and complete without it.** If yes, it's post-v1.

Scope creep is the enemy. New ideas go on the post-v1 list first, not the v1 list.

---

## Time Estimate

| Area | Hours |
|---|---|
| Programming | ~200-300 hrs |
| Art (you) | ~150-250 hrs |
| Art (outsourced) | $ not hours |
| Audio (outsourced) | $ not hours |
| **Total** | **~350-550 hrs** |

At ~20 sustainable hrs/week: **9-14 months**. End of 2026 is achievable. Q1 2027 is comfortable.

**Biggest risk:** Art learning curve (Moho) front-loading time. First character takes longest. Gets faster after that.

---

## Milestones

Target dates from Feb 18, 2026. Estimated at sustainable ~20 hrs/week. Track actual vs. estimate to calibrate future planning.

| Milestone | Target | What's done |
|---|---|---|
| **3D Foundation** | Mar 14 | 3D conversion complete (dive + truck), placeholder .glb working in both scenes, stage tracking, dev tools. Game plays identically but on 3D architecture. |
| **Dive Phase MVP** | May 1 | Escalating danger, hazardous creature (patrol + aggro + steal), health/forced surface, standard traps, 2 passive fish types. Diving feels like a game. |
| **First Final Art** | Jul 15 | Mermaid (both versions) integrated. 2+ customers done. Style locked — brief outsourced artists for icons/UI and music. |
| **Content Complete** | Sep 1 | All 7 ingredients + recipes, 3-4 customers, 2-3 dive sites, title screen, save/load, day limit screen. Outsourced assets delivered and integrated. |
| **Polish Complete** | Oct 31 | Game feel (tweens, particles, SFX), full playtest pass, bug fixing. Demo feels shippable. |
| **Steam Demo Launch** | Dec 2026 | Trailer, Steam page live, demo release + open beta. |

**Outsourcing windows:**
- **Icons/UI:** brief at Jul 15 — first final character done, style is locked
- **Music/SFX:** brief Jul–Aug — you'll have gameplay video to share with the composer

---

## If You Fall Behind — Cut Order

In order of least-painful cuts. Only make these calls if a milestone is clearly slipping.

1. **3rd dive site** — stay with 2. Saves level design + art time, players won't feel the absence in 5 days.
2. **2nd passive fish type** — 6 ingredients instead of 7. Simplest content cut.
3. **Standard traps** — fall back to all static gathering. Diving loses depth but the loop still works.
4. **Hazardous creature** — last resort. This is what makes diving feel like a game. Only cut if genuinely out of time.

**Do not cut:** customer patience/timeout, save/load, title screen.

---

## Marketing (parallel track, not blocking)

- **Now:** dev-log style content, design/process videos, even grey-box gameplay works for dev communities
- **~1 month:** first gameplay clips worth saving; start short-form (TikTok, IG Reels, YouTube Shorts)
- **Streaming:** "study with me" format fits the cozy game audience — start when the game looks presentable
- **Steam page:** go up as soon as you have 30 seconds of trailer-worthy gameplay + concept art
- **Outsource marketing help:** not needed until close to launch; Keymailer for streamers, freelance PR for press coverage

---

## Open Questions

- ~~How many days?~~ **5 days**, tunable once loop length is known
- ~~Day limit or infinite?~~ **Day limit** — ends cleanly with wishlist CTA after day 5
- Exact pricing for Steam demo (free demo + paid full game, or early access?)
