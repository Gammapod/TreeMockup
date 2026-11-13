# Rooms as Skills — V2

Open **this directory's `project.godot`** in Godot 4.6 and run. This is a separate project from the original prototype. `.gdignore` prevents the parent project importing V2 scripts.

## Playable experiment

- WASD moves; E uses a nearby green doorway.
- The side panel activates/deactivates adjacent rooms. Hover a button to preview affected nodes.
- Space performs a timed directional sword attack when Sword is active.
- Shift dashes when Boots is active. Hit Dash halves its distance and bypasses enemy contact damage; Run replaces it with double-speed movement while Shift is held. Walls still block movement.
- Blue pickups permanently increase allocation capacity; yellow pickups grant gold.
- Activate both landings to activate Prize. Removing either landing also removes Prize, even if its other entrance remains connected.
- Defeat returns you to Sanctuary at full health, retaining your build and rewards.

The default scenario follows [branching-dungeon.mmd](examples/scenario-designs/branching-dungeon.mmd): activate Sword or Boots with your initial point, collect both keys, choose a style, reach its landing and collect another key. Explore the other branch, then activate Prize with both landings active. There are 14 nodes and 18 connections; all six keys fund the seven active non-root rooms on the final route. Practice rooms are optional allocations. Each branch's three styles are mutually exclusive.

Big Swing grants 1.5× reach with a two-second attack cooldown; Fast Swing performs three half-range strikes. The HP+ choices grant five current/max HP, and the practice rooms grant one. Starting Room and Prize each grant one; this scenario starts with one HP. Defeated enemies stay defeated while their room remains active; keys remain collected permanently. See [branching-design.md](docs/branching-design.md) for the design mapping and test trace.

Press **F2** to open the content editors. The current run pauses while editing.

## Content editors

1. **Room editor:** select a template, choose an object brush, then click to place. Drag objects to move them. The JSON inspector edits names, ports, object IDs, geometry, enemy stats, pickup values and other properties. Remove entries in the inspector to delete them.
2. **Tree editor:** add nodes using the selected room template, drag their map positions, and use **+ Link** to connect named ports. Edit activation costs, prerequisites, abilities, modifiers, exclusive groups and cross-room bindings in the tree JSON inspector. Solid lines show travel; dashed gold lines show prerequisites.
3. **Apply JSON edits** validates changes. Selection changes, saves and playtests also apply pending inspector edits; invalid edits remain available for correction.
4. **Save / Save as** writes one portable content bundle; **Open** restores it. **Import/Export room** shares individual templates between bundles. Imports reject duplicate template IDs; change the exported ID before importing a second copy.
5. **Playtest** starts a fresh run from the editor's current document, without requiring a save. **F2** returns to your retained editor document; **Resume run** continues the current run.

The editors intentionally use JSON inspectors for detailed rules rather than polished property panels. **Bundle JSON** exposes project metadata and the entire document, including unknown extension fields. Save before quitting the application; unsaved changes are retained across playtests, not application restarts.

### Example bundles

Open `v2/examples/*.json` from the editor:

- `branching.json`: the full Mermaid branching design, including practice rooms, sword/dash/HP choices, two-key ability rooms, alternate landing prerequisites and the shared Prize.
- `water_flippers.json`: the old water/flippers topology with an actual water barrier and a prize chest. Activate Flippers from Start to cross the barrier in Water.
- `switch_wall.json`: the old switch/wall topology, capacity pickups, and a sword-operated switch that changes a wall in another room. Its state persists while the target room is unloaded or inactive.
- `combat.json`: the old combat topology, capacity progression, bats and gold rewards adapted to node allocation.

These use V2's room-activation rules. Health is configurable per scenario; the other examples retain five base HP. The original baseline's temporary capacity bonuses remain additional runtime work; unknown mechanics are retained by the format and reported by the playtest adapter rather than ignored.

**Format and compatibility:** [content-format.md](docs/content-format.md) and [JSON Schema](docs/content.schema.json). Files use versioned, engine-neutral JSON; stable IDs; local coordinates; and explicit references. No Godot scene paths, executable code or live-run state are saved.

## Accepted rules

1. Root is permanently active and costs zero. Other active rooms allocate points; deactivation refunds their authored costs.
2. Activation is local and respects authored activation direction. Travel between active linked rooms is bidirectional.
3. ALL and ANY prerequisites are ongoing requirements. Exclusive groups permit at most one active member.
4. Deactivation removes unsupported and root-disconnected rooms to a fixed point. Alternate support can preserve a room.
5. A transaction that would deactivate the occupied room is rejected, with no partial effects.
6. Abilities derive from active rooms, irrespective of which room scene is loaded.
7. Permanent reward IDs are scoped to node instances, so two nodes can reuse one template without sharing loot.

## Architecture and future authoring

- `authoring/content_store.gd`: portable JSON, validation and temporary-file/rename saves. Source documents retain unknown fields.
- `authoring/runtime_adapter.gd`: translates portable values into runtime dictionaries and Godot geometry; explicitly reports unsupported mechanics.
- `authoring/studio.gd` / `preview.gd`: room/tree editors, source inspectors, placement and graph preview.
- `content.gd`: loads the default JSON fixture through the same adapter used by playtest.
- `progression.gd`: headless activation evaluation, cascade previews, transactions and capability derivation. Also holds the small prototype run ledger (capacity, rewards, gold). It has no movement, enemy, input or rendering dependencies.
- `main.gd`: run coordinator, local debug controls, scene transitions and per-node encounter records.
- `room.gd`: transient room gameplay, physics geometry, encounters and portals. Emits reward/transition intents; receives capabilities and persistent room data. Does not inspect the progression graph.
- `player.gd`: physics motor, dash, timed directional attack and damage cooldown. Attack parameters are captured at action start.

The room editor authors reusable templates with stable object IDs and named ports. The tree editor authors instances and cross-room bindings. Bindings use `(node_id, object_id, event/action)` addresses resolved by the run coordinator, including when the target scene is unloaded. Shared template instances have independent pickups, enemies and switch/wall states.

Map coordinates are advisory and distinct from room-local geometry. No spatial packing constraint is enforced. The authoring validator checks IDs, template/object references, prerequisite cycles and port conflicts. Runtime room geometry is currently 800×600; other sizes are preserved in content but rejected for playtest.

### Explicit prototype policies

- Encounters: surviving enemies reset on departure; defeated enemies stay defeated while the node remains active. Deactivation resets its encounter. Permanent pickups remain collected.
- Health: five base HP by default; `dungeon.base_hp` can override this. Active nodes add `max_hp_bonus`. Increases grant the same amount of current HP, decreases clamp it, and room transitions never heal. Reactivating a health node grants its increase again, matching the graph's explicit current/max-HP rule.
- Room activation is local to the current room, not proximity to a particular door. Remote activation is not implemented; add it later as an interaction permission rather than bypassing prerequisite/resource validation.
- The demo has sword, dash and an ALL merge. ANY merges and exclusive groups are exercised by model tests. Water, flippers, remote switches/walls, chests and numeric ability modifiers are supported. Content save/load is separate from run save/load, which is still future work.
- Current capabilities use minimal numeric fields plus ability IDs; behavior variants should become separate implementations as they are explored.

## Verification

```powershell
& 'C:\Godot\Godot.exe' --headless --path v2 --script tests/run_tests.gd
& 'C:\Godot\Godot.exe' --headless --path v2 --script tests/content_tests.gd
& 'C:\Godot\Godot.exe' --headless --path v2 --script tests/editor_tests.gd
& 'C:\Godot\Godot.exe' --headless --path v2 --script tests/branching_tests.gd
```

Run from the repository root (use `--path .` if already in `v2`). Tests cover allocations/refunds, permanent rewards, ongoing ALL/ANY prerequisites, exclusivity, player safety, transaction previews and room/coordinator integration.

## Experiment roadmap

See the [V2 experiment backlog](docs/backlog.md) for prioritized gameplay, UI, authoring, primitive and layout ideas. Its guiding goal is to learn what supports **“the dungeon is also a skill tree.”** The recommended next experiment is an interactive gameplay map/skill tree, followed by separate tests of room clearing, retained activation, remote reconfiguration and warping.
