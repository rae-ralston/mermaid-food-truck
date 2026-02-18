# Art Direction Design

## World

The underwater world is **alien, not realistic**. We are not bound by real ocean creatures, real marine biology, or recognizable sea life. Creatures, plants, and ingredients can be entirely invented. This is a fantastical ocean with its own logic — bioluminescent, strange, beautiful, and occasionally dangerous.

This is a deliberate differentiator from games like Dave the Diver, which leans into real-world marine life. Our world should feel like somewhere that doesn't exist.

This applies to everything: predator creatures in the dive, ingredient names and appearances, customer designs, environmental elements. The only constraint is internal consistency and fitting the tonal range (bright/cozy in shallow zones, alien/eerie in deep zones).

---

## Style

Hand-painted illustrated 2D. Soft edges, visible brushwork, warm palette. No pixel grid, no heavy outlines — the art should feel like watercolor-meets-digital, somewhere between Hollow Knight's clean-but-painterly characters and the cozy warmth of Spiritfarer.

### Tonal range

The tonal shift across depth zones is the game's visual hook:

- **Shallow dive zones:** Bright, saturated, friendly. Warm aquas, golden light filtering through water.
- **Mid-depth:** Cooler palette, muted saturation. Strange but beautiful.
- **Deep zones:** Desaturated, bioluminescent lighting, eerie atmosphere.
- **Truck phase:** Snaps back to warm and inviting. Lantern light, steam, cozy wood tones.

### Palette discipline

Establish a master palette early (24-32 colors) with sub-palettes for each biome/zone and the truck. Individual assets pull from these sub-palettes. This keeps dozens of assets looking cohesive over months of production.

---

## Tools

- **Procreate (iPad Pro):** All painting and illustration work.
- **Moho (animation):** Skeletal rigging, mesh deformation, and animation for all characters. Exports `.glb` (binary glTF) for Godot import.
- **Godot 4.6:** Scene assembly, gameplay, UI theming. Characters are read-only imported assets — all animation work happens in Moho.

Pipeline validated: Moho `.glb` exports import cleanly into Godot. AnimationPlayer is populated automatically. Textures are embedded in the `.glb` — no separate texture files needed.

---

## Target Resolution

- **Game resolution:** 1920x1080 (1080p). Standard for Steam, scales cleanly to 4K.
- **Draw at 2x** in Procreate for crisp detail and downscale room, export at the size Godot uses.
- **Character sprites:** ~256-512px tall in-game (draw at ~512-1024px).
- **Icons (ingredients, dishes):** 128x128 or 256x256 in-game (draw at 256x256 or 512x512).
- **Environment layers:** Full width (1920px or wider for scroll room).
- **Color mode:** sRGB (Godot expects this).

---

## Asset Pipelines

### Characters (mermaid, customers)

**Base rig approach:**

All characters start from a naked base rig — the body with bones and mesh deformation set up, no outfit. Clothes and accessories are layered on top in Moho. This means:
- The rig and all its animations live once on the base
- Swapping outfits = swapping image layers, not re-rigging
- New character variants are fast once the base is solid

**Mermaid has two versions:**
- `mermaid_diver.glb` — adventure outfit, used in dive phase. Animations: swim, gather, idle (underwater), surface.
- `mermaid_truck.glb` — casual outfit, used in truck phase. Animations: walk, idle, carry dish, interact with station.

Both share the same base rig. Different outfit layers, different animation sets tuned to their context.

**Drawing (Procreate):**

1. Design the character as a single illustration first to nail the look.
2. Redraw as separate layers per body part: head, torso, upper arms, lower arms, tail/legs, accessories, outfit pieces.
3. Each layer needs overlap at the joints (hidden area under the connecting part) so there are no gaps when bones rotate.
4. Export each layer as individual PNGs with transparency (Procreate's "Share > PNG files" exports all layers).

**Rigging & Animation (Moho):**

1. Build the naked base rig — import body part PNGs, place bones, set up mesh deformation, IK, smart bones.
2. Add outfit layers on top of the base without modifying the rig.
3. Animate all states for that version. Each named animation clip in Moho becomes a named clip in Godot's `AnimationPlayer` — one `.glb` holds all of them (idle, swim, carry, emotion_happy, etc.).
4. Export as `.glb` (binary glTF). Textures are embedded — single file, no separate PNGs.

**Importing into Godot:**

1. Drop the `.glb` into `assets/characters/`.
2. Godot auto-imports and populates `AnimationPlayer` with all exported animation clips.
3. Play a clip from code: `animation_player.play("swim")`, `animation_player.play("emotion_impatient")`, etc.
4. The asset is read-only in Godot. To change anything, edit in Moho and re-export to the same path — Godot picks up the update automatically.

**Customer variants at scale:**

- Same base rig approach: one naked base, outfit/species layers swapped on top.
- Each variant is a separate `.glb` (e.g. `customer_fish.glb`, `customer_shark.glb`).
- Emotion states (happy, impatient, angry) are named animation clips within the same `.glb`.
- Shared animation names across all customers means code drives them identically.
- Note: workflow for efficiently sharing/reusing the base rig across customer variants in Moho is still to be explored. Build the mermaid first and use that as the reference.

### Static sprites (ingredients, dishes, UI icons)

1. Paint in Procreate at 256x256 or 512x512 on a shared template canvas (consistent lighting, consistent framing).
2. Export PNG, drop into the appropriate `assets/` subfolder.
3. Assign to the `.tres` resource.

**Consistency approach:** Paint the first 5 ingredients in one sitting to lock in the style (lighting direction, detail level, color saturation, edge treatment). Use those as a reference sheet for every future ingredient.

### Environments

**Dive phase (parallax layers):**

The mermaid swims freely in all directions, so parallax scrolls on both axes. The vertical axis carries meaning — swimming deeper shifts the palette from bright/warm to dark/eerie. This depth gradient must be reflected in the background layers.

**Layer structure (4 layers per biome):**

| Layer | Role | Scroll (x, y) | Notes |
|---|---|---|---|
| Deep background | Open water, distant silhouettes, light rays | (0.1, 0.1) | Barely moves. Pure atmosphere. |
| Mid-ground | Rock formations, coral, environmental landmarks | (0.5, 0.4) | Establishes biome character. |
| Play layer | Terrain, gatherables, interactive objects | (1.0, 1.0) | Not a parallax layer — the game world itself. |
| Foreground | Overhanging rocks, floating particles, seaweed fronds | (1.3, 1.2) | Sparse. Slightly blurred/transparent to avoid obscuring gameplay. |

**Painting approach (phased):**

- **Now (style test and early production):** Paint tall canvases with the depth gradient baked in. Each layer covers the full vertical extent of the level, with the palette shifting from bright at the top to eerie at the bottom. Maximum artistic control. A level that's 3x screen width and 4x screen height means a mid-ground layer at 0.5 scroll is ~3000x2200px — large but manageable in Procreate on iPad Pro.
- **Later (larger levels):** Tile horizontally to extend level width without enormous canvases. The vertical gradient stays hand-painted; horizontal repetition handles width. Careful seam work needed.
- **Later (reinforcement):** Add a y-based color shift shader that subtly tints all layers based on camera depth. Reinforces the hand-painted gradient and ensures consistency across biomes without repainting.

**Separation between layers:** Use value contrast (lighter = farther) and saturation shifts (less saturated = farther) — standard atmospheric perspective, amplified by underwater light scattering. Each layer should have clear silhouette separation from adjacent layers.

**Scroll ratios are tunable.** Start with the values above, then adjust by feel with placeholder art in Godot before committing to final paintings.

**Truck phase:**

- One illustrated background scene (the truck interior/exterior).
- Interactive objects (stations, windows) are separate sprites layered on top.
- Painted once, reused every day.

### UI

- Paint custom panel/button textures in Procreate.
- Apply via Godot's `Theme` resource for global consistency.
- Standard design principles apply: spacing, hierarchy, visual feedback.

---

## File Organization

```
assets/
  characters/
    mermaid_diver.glb       # adventure outfit, dive phase animations
    mermaid_truck.glb       # casual outfit, truck phase animations
    customer_fish.glb
    customer_shark.glb
    customer_crab.glb
    ...
  # Source .moho files and raw Procreate exports live outside the Godot project.
  # Godot only receives the final .glb exports.
  ingredients/          # already exists
  dishes/
  environments/
	shallows/
	  bg_far.png
	  bg_mid.png
	  fg_seaweed_01.png
	  fg_seaweed_02.png
	  fg_rock_overhang.png
	coral_reef/
	  ...
  ui/
	panels/
	buttons/
	icons/
```

---

## Style Test (First Step)

Before committing to full production, validate the pipeline and look with a small proof of concept:

1. **Mermaid character** — full piece breakdown, rigged and animated in Moho, exported as `.glb`, imported into Godot. Proves the Procreate → Moho → Godot pipeline end to end and validates the look.
2. **3 ingredient icons** — painted at final quality. Proves the icon style and consistency approach.
3. **Shallows environment** — parallax layers at final quality. Proves the biome look and atmospheric feel.

If these three look cohesive and the speed feels sustainable, the pipeline is validated. If something feels wrong (stiff rigs, icons too detailed to sustain, environments too slow to paint), adjust before going deeper into production.

### Parallax style test — canvas sizes

Test play area: 2 screens wide by 2 screens tall (3840x2160). Layer canvas sizes calculated from: `layer_size = viewport + (play_area - viewport) * scroll_ratio`.

**Background layers (one painting each):**

| # | File | Scroll ratio | In-game size | Procreate canvas | Description |
|---|---|---|---|---|---|
| 1 | `bg_far.png` | (0.1, 0.1) | 2112x1188 | 2200x1200 (1x) | Open water gradient, faint light rays, distant rock silhouettes. Bright at top, dark at bottom. Draw at 1x — it's blurry and atmospheric, extra resolution is wasted. |
| 2 | `bg_mid.png` | (0.5, 0.4) | 2880x1512 | 5800x3100 (2x) | Coral formations, rock walls, kelp in the distance. Biome character. Depth gradient baked in. Biggest single painting. |

**Foreground elements (individual transparent PNGs, not one big canvas):**

Paint as separate pieces, scatter as `Sprite2D` nodes inside the foreground `ParallaxLayer` (scroll ratio 1.3, 1.2). More flexible, reusable, and avoids an enormous canvas.

| # | File | Procreate canvas | Description |
|---|---|---|---|
| 3 | `fg_seaweed_01.png` | 400x1200 (2x) | Single seaweed frond, transparent background |
| 4 | `fg_seaweed_02.png` | 400x1200 (2x) | Variant seaweed frond |
| 5 | `fg_rock_overhang.png` | 1600x600 (2x) | Rocky overhang element, transparent background |
| 6 | `fg_particles.png` | 256x256 (2x) | Floating debris / bubbles (or use Godot's `GPUParticles2D` instead) |

**Note:** The play layer (scroll 1.0) is not a parallax painting — it's the game world itself (terrain, gatherables, etc.).

---

## Key Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Art style | Hand-painted illustrated | Transfers directly from traditional art skills; supports cozy-to-spooky tonal range; distinctive on Steam |
| Animation approach | Skeletal (Godot-native) | Scales to many characters via part-swapping and rig reuse; avoids frame-by-frame grind |
| Drawing tool | Procreate (iPad Pro) | Already comfortable; strong painting tool; simple PNG export |
| Rigging tool | Moho | Tested and validated. Superior mesh deformation, IK, and animation quality. Exports `.glb` which imports cleanly into Godot with AnimationPlayer populated. Godot is read-only for character assets — all animation work in Moho. |
| Game resolution | 1920x1080 | Steam standard; clean 2x scale to 4K |
| Drawing resolution | 2x target size | Crisp detail with downscale room |
