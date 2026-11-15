# Rooms as Skills — V2

Open **this directory's `project.godot`** in Godot 4.6 and run. This is a separate project from the original prototype. `.gdignore` prevents the parent project importing V2 scripts.

## Playable experiment

- WASD moves; E uses a nearby green doorway.
- The map shows authored node positions, travel links (solid), prerequisite arrows (dashed), and a yellow **YOU** marker. Click a node to select it, use the wheel to zoom, right/middle-drag to pan, and **Fit graph** to reset the view.
- Nodes show **✓ active**, **+ available to activate**, or **× blocked**, with allocation costs in their centers. Select any node to see its state and use **Activate / Deactivate** below the map. Unavailable actions explain why. Active markers describe allocation, not permission to deactivate. Selection (white ring) does not move the player or change the build.
- Selecting an active room previews removal with **orange boxes** around all affected nodes, a named cascade list, and a total refund/post-action point budget. **Red boxes** mark a blocked removal preview; no changes or refund can occur. Scroll the selected-node details for ongoing **ALL / ANY** prerequisites, each room's current active state, and exclusive-group conflicts. Hovering the action also shows the details.
- Entering a room centers it on the map and fits its directly linked neighbors, including inactive rooms, without changing selection. Pan/zoom remains manual until the next entry; **Fit graph** shows the whole graph.
- Drag the divider between room and map to adjust their space. The window can be resized (minimum 960×640); **F11** or the header button switches fullscreen/windowed. The room scales proportionally with letterboxing, keeping its 800×600 gameplay coordinates. Resizing the map refits the current neighborhood, or the whole graph after manual navigation.
- Space performs a timed directional sword attack when Sword is active.
- Shift dashes when Boots is active. Hit Dash halves its distance and bypasses enemy contact damage; Run replaces it with double-speed movement while Shift is held. Walls still block movement.
- Blue pickups permanently increase allocation capacity; yellow pickups grant gold.
- Pink diamond tokens are room-local objectives and respawn on re-entry only while uncleared. Cleared rooms contain no tokens. Map badges **C** (cleared) and **R** (root) are separate from activation. Select a room to inspect its clear conditions/effects.
- Select a cleared, active root and press **Travel to root** to reach its spawn from anywhere, even across disconnected branches. Travel preserves HP and your build.
- Rooms can optionally block build editing while occupied and uncleared. The map explains the lock; clearing the room immediately restores normal activation/deactivation. Travel remains available.
- Activate both landings to activate Prize. Removing either landing also removes Prize, even if its other entrance remains connected.
- Defeat returns you to Sanctuary at full health, retaining your build and rewards.

The default scenario follows [branching-dungeon.mmd](examples/scenario-designs/branching-dungeon.mmd): activate Sword or Boots with your initial point, collect both keys, choose a style, reach its landing and collect another key. Explore the other branch, then activate Prize with both landings active. There are 14 nodes and 18 connections; all six keys fund the seven active non-root rooms on the final route. Practice rooms are optional allocations. Each branch's three styles are mutually exclusive.

Big Swing grants 1.5× reach with a two-second attack cooldown; Fast Swing performs three half-range strikes. The HP+ choices grant five current/max HP, and the practice rooms grant one. Starting Room and Prize each grant one; this scenario starts with one HP. Defeated enemies stay defeated while their room remains active; keys remain collected permanently. See the [branching scenario record](docs/knowledge/branching-scenario.md) for the design mapping and test trace.

Press **F2** to open the content editors. The current run pauses while editing.

## Content editors

1. **Room editor:** select a template, choose an object brush, then click to place. Drag objects to move them. The JSON inspector edits names, ports, object IDs, geometry, enemy stats, pickup values and other properties. Remove entries in the inspector to delete them.
   Use **Clear rules…** to combine enemy, switch and token conditions, reveal authored pickups/chests, prevent enemy respawns, or grant permanent root status. All selected conditions are required. With none selected, the room starts cleared and its effects apply immediately. Use the `token` brush to place room-local tokens.
   The same dialog has **Disable tree editing while inside this uncleared room** (off by default).
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
- `cleared_rooms.json`: six-node clear-state lab with shared-template enemy rooms, a switch reward, token collection and combined objectives earning a second root. [Contracts](docs/knowledge/clear-state.md); the former walkthrough is [archived](docs/archive/cleared-rooms-closeout.md).

These use V2's room-activation rules. Health is configurable per scenario; the other examples retain five base HP. The original baseline's temporary capacity bonuses remain additional runtime work; unknown mechanics are retained by the format and reported by the playtest adapter rather than ignored.

**Format and compatibility:** [content contract](docs/knowledge/content.md) and [JSON Schema](docs/content.schema.json). Files use versioned, engine-neutral JSON; stable IDs; local coordinates; and explicit references. No Godot scene paths, executable code or live-run state are saved.

## Accepted rules

1. Roots are created by clear effects, permanently active and allocate zero points. Promotion releases the node's allocation and waives upstream support. The starting room uses the same effect. Other active rooms allocate points; deactivation refunds their authored costs.
2. Activation is local and respects authored activation direction. Travel between active linked rooms is bidirectional.
3. ALL and ANY prerequisites are ongoing requirements. Exclusive groups permit at most one active member.
4. Deactivation removes unsupported and root-disconnected rooms to a fixed point. Alternate support can preserve a room.
5. A transaction that would deactivate the occupied room is rejected, with no partial effects.
6. Abilities derive from active rooms, irrespective of which room scene is loaded.
7. Permanent reward IDs are scoped to node instances, so two nodes can reuse one template without sharing loot.
8. Clear state is per node, independent of activation, and persists through deactivation and defeat for the run. Conditionless rooms start cleared. All authored conditions must be met; all clear effects apply.

## Architecture and future authoring

- **Start a handoff here:** [V2 knowledge bundle](docs/knowledge/index.md) is an [Open Knowledge Format v0.2](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)-style, minimal handoff record. Read its [glossary and primitives](docs/knowledge/glossary.md), [architecture boundaries](docs/knowledge/architecture.md), [functional invariants and test traces](docs/knowledge/invariants.md), [content contract](docs/knowledge/content.md), [clear-state contract](docs/knowledge/clear-state.md), [UI contract](docs/knowledge/ui.md), [branching scenario](docs/knowledge/branching-scenario.md), and [experiment log](docs/knowledge/experiments.md) before changing V2. Its [recording policy](docs/knowledge/index.md#recording-policy) defines what future agents should—and should not—add. The former feature closeouts are [archived](docs/archive/README.md).
- `authoring/content_store.gd`: portable JSON, validation and temporary-file/rename saves. Source documents retain unknown fields.
- `authoring/runtime_adapter.gd`: translates portable values into runtime dictionaries and Godot geometry; explicitly reports unsupported mechanics.
- `authoring/studio.gd` / `preview.gd`: room/tree editors, source inspectors, placement and graph preview.
- `content.gd`: loads the default JSON fixture through the same adapter used by playtest.
- `progression.gd`: headless activation evaluation, cascade previews, transactions and capability derivation. Also holds the small prototype run ledger (capacity, rewards, gold). It has no movement, enemy, input or rendering dependencies.
- `main.gd`: run coordinator, local debug controls, scene transitions and per-node encounter records.
- `gameplay_shell.gd`: responsive HUD/status and adjustable room/map regions, fullscreen control, and an isolated fixed-size room viewport. Unhandled gameplay keys are forwarded to that viewport.
- `gameplay_tree.gd`: selected-node controls and presentation from copied run snapshots; emits action intents to the coordinator. It has no progression model reference or transaction authority.
- `gameplay_map.gd`: graph rendering, selection and pan/zoom; independent of progression transactions.
- `room.gd`: transient room gameplay, physics geometry, encounters and portals. Emits reward/transition intents; receives capabilities and persistent room data. Does not inspect the progression graph.
- `player.gd`: physics motor, dash, timed directional attack and damage cooldown. Attack parameters are captured at action start.

The room editor authors reusable templates with stable object IDs and named ports. The tree editor authors instances and cross-room bindings. Bindings use `(node_id, object_id, event/action)` addresses resolved by the run coordinator, including when the target scene is unloaded. Shared template instances have independent pickups, enemies and switch/wall states.

Map coordinates are advisory and distinct from room-local geometry. No spatial packing constraint is enforced. The authoring validator checks IDs, template/object references, prerequisite cycles and port conflicts. Runtime room geometry is currently 800×600; other sizes are preserved in content but rejected for playtest.

### Explicit prototype policies

- Encounters: surviving enemies reset on departure; defeated enemies stay defeated while the node remains active. Deactivation resets its encounter unless a cleared room has the no-respawn effect. Permanent pickups remain collected. Switch-hit objectives latch for the run; token objective progress resets on departure.
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
& 'C:\Godot\Godot.exe' --headless --path v2 --script tests/shell_tests.gd
& 'C:\Godot\Godot.exe' --headless --path v2 --script tests/map_tests.gd
& 'C:\Godot\Godot.exe' --headless --path v2 --script tests/map_preview_tests.gd
& 'C:\Godot\Godot.exe' --headless --path v2 --script tests/map_camera_tests.gd
& 'C:\Godot\Godot.exe' --headless --path v2 --script tests/tree_panel_tests.gd
& 'C:\Godot\Godot.exe' --headless --path v2 --script tests/clear_tests.gd
& 'C:\Godot\Godot.exe' --headless --path v2 --script tests/root_travel_tests.gd
& 'C:\Godot\Godot.exe' --headless --path v2 --script tests/clear_hardening_tests.gd
```

Run from the repository root (use `--path .` if already in `v2`). Tests cover allocations/refunds, permanent rewards, ongoing ALL/ANY prerequisites, exclusivity, player safety, transaction previews and room/coordinator integration.

## Experiment roadmap

See the [V2 knowledge bundle](docs/knowledge/index.md) for the compact handoff record and [experiment record](docs/knowledge/experiments.md) for accepted baselines and the required log format. The [V2 experiment backlog](docs/backlog.md) holds prioritized gameplay, UI, authoring, primitive and layout ideas. Its guiding goal is to learn what supports **“the dungeon is also a skill tree.”** UI-01 and the clearing functionality are accepted baselines. The [clear-state contract](docs/knowledge/clear-state.md) holds current rules; its walkthrough, architectural review and hardening trace are [archived](docs/archive/cleared-rooms-closeout.md). CLEAR-03 through CLEAR-06 are potential future experiments; the next experiment has not been selected.
