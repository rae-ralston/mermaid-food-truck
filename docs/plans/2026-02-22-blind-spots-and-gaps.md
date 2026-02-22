# Blind Spots and Gaps

Review of what's missing or under-designed as of Feb 22, 2026. Not all of these need action now — many are post-playtest or pre-launch concerns. Captured here so nothing falls through the cracks.

## Priority: Design before building

These need design docs before implementation starts.

### Save/Load System
Required for V1 demo. No design doc exists. Key decisions:
- What gets persisted: GameState (day, money, inventory, upgrades) at minimum
- When: auto-save between Results and Store phases (end of each day)
- Format: Godot Resource save/load or JSON. Resource is simpler but JSON is more debuggable.
- Versioning: save files need a version number so future format changes don't break old saves
- Steam cloud saves: uses Steamworks API, requires explicit implementation. Design the local save first, cloud sync wraps it later.

Risk if deferred: retrofitting serialization into systems built without it in mind.

### Customer Patience / Timeout
Required for V1. Partially designed (CLAUDE.md mentions it) but missing key decisions:
- Timer duration per customer (fixed? varies by recipe complexity? increases with day?)
- Visual indicator (patience bar above customer head, color change, animation state)
- What happens on timeout: customer leaves (lost sale). Money penalty? Or just lost revenue?
- Reputation is cut from V1, so timeout penalty is purely economic for now
- How does this interact with customer queue? Does the *next* customer's timer start when they reach the front, or on spawn?

### Day Pacing Targets
No doc specifies how long anything should take. Tuning numbers to establish through playtesting, but need starting targets:
- How many customers per truck phase? (suggest: Day 1: 3, Day 5: 8-10)
- How long per truck phase? (suggest: 2-4 minutes)
- How long per dive? (soft-capped by danger escalation, suggest: 2-3 minutes)
- Total day duration target? (suggest: 5-8 minutes including planning/results/store)
- v1-scope says "20 min/day × 5 days = 100 min demo" — this feels long. Revisit after playtesting.

## Priority: Start early, avoid painful retrofits

### Localization / String Externalization
All strings are currently hardcoded in scenes and scripts. Godot has a built-in `tr()` function and CSV-based translation system. Don't need to translate anything now, but switching to `tr("Day %d")` instead of `"Day " + str(day)` going forward prevents a painful retrofit later. Could also adopt this incrementally — new code uses `tr()`, old code migrated opportunistically.

### Controller Support
Most cozy games support gamepad. Input map is small right now (WASD, E, Tab, ESC, backtick). Adding controller mappings to project.godot input actions is low-effort if done now. Gets harder as more interactions are added. Decide: support gamepad or explicitly document "keyboard only for V1."

## Priority: Before Steam launch (not urgent now)

### Achievements
Steam achievement system. Design early because achievements lock you into balance decisions. Example set for a 5-day demo:
- Complete Day 1, Complete all 5 days
- Earn $X total
- Cook each recipe at least once
- Fill backpack completely on a dive
- Serve X customers without a timeout

### IARC Age Rating
Required for Steam. Straightforward for a cozy game (likely E or E10+). No violence, no real-world currency. Just need to fill out the questionnaire before publishing.

### Cloud Saves
Wraps around local save system. Design local saves first, cloud sync is a layer on top via Steamworks API.

### Build Versioning
Demo vs full game versioning strategy. Suggest: semver (0.1.0 for first playtest, 1.0.0 for Steam launch). No branching strategy needed until there are multiple release tracks.

### Performance Targets
No FPS or memory targets set. Game is simple 3D (orthographic, low poly count). Should easily hit 60 FPS on 2020-era hardware, but validate during playtesting on a lower-spec machine.

### Crash Reporting
No error logging or telemetry. Players will hit bugs and not report them. Options: third-party service (Sentry has Godot plugins), or simple local log file that players can send manually. Not critical for playtest, important for public demo.

## Priority: Worth thinking about

### Tutorial / Onboarding
Fish mechanics doc assumes "mechanics teach themselves." This might work for dive phase (explore, see things, pick them up). Truck phase has a non-obvious flow: order window → prep station → cook station → plate station → pickup window. Even tooltip-style hints on Day 1 would help first-time players.

Options:
- Scripted Day 1 with guided steps (most work, best UX)
- Contextual tooltips that appear once per station (moderate work)
- Nothing — let players figure it out (least work, risky for demo)

Decide after first external playtest.

### Per-Recipe Pricing
Recipes exist as .tres resources with `base_price` field. Are actual gold values filled in? game-design-doc.md shows $ / $$ / $$$ but no numbers. Needs concrete values for the economy to work. Related to day pacing — if recipes pay too much, upgrades come too fast.

### Difficulty Scaling
No design for how difficulty increases across the 5 demo days. Levers available:
- Customer count per day
- Customer patience duration
- Recipe complexity (number of steps)
- Dive danger escalation rate
- Ingredient scarcity

These are tuning knobs, not systems to build. But having a target curve helps playtesting.

## Not a problem (flagged but dismissed)

- **Untyped payloads between phases** — with 6 phases this is fine. Over-engineering to type them now.
- **Z-ordering convention** — will emerge naturally when building larger dive levels.
- **Recipe catalog loading** — already works via .tres resources. No architectural risk.

## Content Expansion Process

The richness of this game comes from variety — weird alien ingredients, inventive recipes, diverse dive sites. Adding content should be easy and consistent. This is the checklist for each content type.

### Adding a New Ingredient

1. **Design:** Name, description, which dive site(s) it appears in, depth zone (shallow/mid/deep), rarity/frequency
2. **Art:** World sprite (gatherable in dive), inventory icon (backpack + truck HUD). Paint at 256-512px in Procreate, export PNG.
3. **Data:** Create `data/ingredients/<ingredient_id>.tres` (IngredientData resource). Fields: `id`, `display_name`, `description`, `icon`, `world_sprite`
4. **Dive site:** Add Gatherable nodes to the relevant dive site scene(s) in `scenes/dive_sites/`. Set the ingredient reference on each Gatherable.
5. **Verify:** Run game, dive to the site, gather the ingredient, confirm it appears in backpack and truck inventory.

### Adding a New Recipe

1. **Design:** Name, required ingredients (with quantities), station steps (PREP → COOK → PLATE or subset), base_price, time_limit per step, which dive sites provide all ingredients (important for menu viability)
2. **Art:** Dish icon for HUD/order display. Paint at 256-512px.
3. **Data:** Create `data/recipes/<recipe_id>.tres` (RecipeData resource). Fields: `id`, `display_name`, `ingredients` (array of {ingredient_id, quantity}), `steps` (array of station types), `base_price`, `time_limit`
4. **Balance check:** Can the player gather all ingredients in a single dive? If not, is that intentional (multi-dive recipe)?
5. **GameState:** Recipe is automatically available if the .tres exists and is in `data/recipes/`. Verify `can_make_recipe()` works with the new ingredient requirements.
6. **Verify:** Stock ingredients via dev console (`add <ingredient> <count>`), enter truck planning, confirm recipe appears, select it, play truck phase, cook the full dish through all stations.

### Adding a New Dive Site

1. **Design:** Name, biome theme, which ingredients appear here (and relative frequency), layout sketch (where are gatherables clustered? where is the extraction zone? where does the player spawn?)
2. **Art:** Parallax background layers for the biome (if new biome). Individual foreground elements (coral, rocks, plants). Follow art-direction-design.md palette discipline.
3. **Scene:** Create `scenes/dive_sites/<SiteName>.tscn`. Required node structure:
   - `Gatherables` (Node3D) — parent for all Gatherable instances
   - `ExtractionZone` (Area3D) — where player surfaces
   - `SpawnPoint` (Marker3D) — where diver starts
4. **Dive Planning:** Add the site to `phase_dive_planning.gd` site list with name and scene path.
5. **Verify:** Select site in dive planning, confirm diver spawns at SpawnPoint, gather ingredients, extract, confirm inventory updated.

### Adding a New Customer Variant

1. **Design:** Species name, visual style, any personality quirks (purely cosmetic for now — all customers behave the same mechanically)
2. **Art:** Character painted in Procreate, rigged in Moho on the shared base rig, exported as `.glb` with standard animation clips (idle, emotion_happy, emotion_impatient). See art-direction-design.md for pipeline.
3. **Scene:** The customer spawner should pick from a pool of customer scenes/models. Currently uses a single customer type — when adding variants, the spawner needs a customer pool to randomly select from.
4. **Verify:** Play truck phase, confirm new customer variant appears in the line, takes orders, fulfills normally.

### Naming Conventions

- Ingredient IDs: `snake_case` (e.g., `coral_spice`, `glow_algae`)
- Recipe IDs: `snake_case` (e.g., `kelp_wrap`, `clam_chowder`)
- Dive site scenes: `PascalCase.tscn` (e.g., `Shallows.tscn`, `CoralReef.tscn`)
- Resource files: `snake_case.tres` matching the ID
- Art assets: `snake_case.png` in the relevant `assets/` subdirectory

### Balance Considerations

When adding content, check:
- **Ingredient distribution:** Each dive site should have 2-4 ingredients. Not every ingredient needs to be in every site — scarcity drives dive site choice.
- **Recipe ingredient overlap:** Recipes that share ingredients create interesting planning decisions (do I make Kelp Wrap or Spiced Kelp Bowl with my kelp?)
- **Price scaling:** More complex recipes (more ingredients, more steps) should pay more. Rough guideline: base_price ≈ sum of ingredient "value" × 1.5
- **Step count:** Most recipes should be 3 steps (PREP → COOK → PLATE). 2-step recipes are quick/cheap, 3-step are standard. Avoid 4+ steps unless introducing a new station type.
