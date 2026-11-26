# Rooms as Skills — V2

Open **this directory's `project.godot`** in Godot 4.6 and run. This is a separate project from the original prototype. `.gdignore` prevents the parent project importing V2 scripts.

## Playable experiments

### Unified abilities: Phase Dash lab

Open `examples/phase_dash_lab.json` via **F2 → Open… → Playtest**. The starting
room grants Sword and Dash and has two capacity points. Select and activate
**Phase and Rooted Recharge** to compare teleporting with an ordinary dash;
activate **Water Passage** to try landing in water.

Try crossing the narrow wall, aiming inside the thicker wall, and landing in
water before and after enabling Water Passage. Phase crosses interior obstacles
but cannot cross room boundaries. An invalid destination returns the player to
the start of the dash and consumes recharge; the attempted destination is
marked. If the return point is also blocked, normal defeat occurs. The optional
rooted-recharge contribution restricts ordinary movement during the dash and
recharge. The narrow wall can also be walked around: this is a comparison lab,
not a forced puzzle.

The user found Phase Dash worked as intended with and without rooted recharge;
the timing could be faster but is acceptable for now. Dungeon encounter tuning
remains open. See the [experiment record](docs/knowledge/experiments.md#unified-abilities--phase-dash-lab-2026-11-23).

### BUILD-01: stackable ability arena

**Completed and accepted as a baseline.**
See the [architectural closeout](docs/archive/build-01-closeout.md).

Click **BUILD-01 arena** in the header, or run:

```powershell
& 'C:\Godot\Godot.exe' --path v2 -- --arena
```

The same content is editable via F2 → Open → `examples/build_arena.json`.
The Workshop grants Sword and Dash, with **eight allocation points**.
Six straight branches each contain **four sequential one-point upgrades**:
Thrust, Sweep, Quick Cut, Long Dash, Quick Step, and Max HP (+1 per node).
Legacy Phase Dash is a separate one-point node. This workshop uses the legacy
capability model: its Phase is a shorter moving dash with contact immunity, not
the unified teleport in the lab above. Activate a branch's first node, walk
into it, and activate the next; each deeper node requires its predecessor.
Use **Travel to root** to return to Workshop. Refunding the first node there
refunds its entire branch; refund a later node from its predecessor to trim it.
Select a free Crowd Trial, Durable Trial, or Boss Trial node, activate it, and walk through
its north doorway. Use Fit graph for the full tree, or zoom/pan to inspect a branch.
**Restart trial (keep build)** resets enemies, clear state, position and HP
without changing allocations, including deep branches. Fresh trial health
includes allocated HP upgrades; allocating those upgrades or normal root travel
does not heal.

The footer shows final sword stats; the translucent sector previews the actual
attack footprint. Selected-node details show each modifier's benefit and cost.
Arena base slash: reach 92, arc 68.8°, damage 8, interval 0.64s. Four Sweeps
reach 348.1°; four Quick Cuts reach a 0.2025s interval, so all four copies give
benefits before the runtime limits. One/two Sweeps deal 6/4.5. The five weak bats have 4 HP each;
the durable bat has 24 HP, requiring 3/4/6 hits respectively.

Thrust, Sweep, Quick Cut, Long Dash and Quick Step use legacy numeric modifiers;
the workshop's Phase Dash uses a legacy behavior style. See the
[content vocabulary](docs/knowledge/content.md).
The expanded arena supports focused or mixed builds. HP upgrades raise maximum HP without healing;
Flippers remain binary. See [BUILD-01](docs/knowledge/experiments.md#build-01--stackable-ability-tradeoffs-2026-11-15).

### BOSS-01: Roost Guardian trial

**Completed and accepted as the dungeon capstone baseline.** Encounter tuning
and presentation polish remain follow-up work. See the
[architectural closeout](docs/archive/boss-01-closeout.md).

From Workshop, activate **Boss Trial** (zero points) and enter its north doorway
between Durable Trial and Phase Dash. The boss is damageable throughout:

1. **Pressure, 3s:** two short advances, never farther than 60 units from spawn.
2. **Yellow telegraph, 1.5s:** boss stops; green shading and dashed lines mark a
   fixed 90° safe gap.
3. **Red shockwave, ~2.9s:** a 20-unit ring expands across the room at 180
   units/second. Walk into the gap; dash helps reposition but does not skip
    collision. The workshop's legacy Phase Dash blocks enemy contact, **not**
    this wave.
4. **Teal recovery, 1.5s:** boss stays still with contact damage disabled.

Every second pressure cycle marks bat spawn locations for 0.8s, then replenishes
up to three 4-HP bats. The boss starts with 120 HP; its defeat removes summons
and clears the trial. These are initial encounter tuning values.

**Restart trial (keep build)** resets boss HP, position, cycle, summons and
clear state, restores full build health, and returns you to Workshop. Normal
retreat/root travel follows existing room persistence rules and does not heal.
Try different allocations after observing the cycle. The workshop has 29 nodes;
the next design target is a separate, interconnected 14–18-node dungeon.

### Controls and original branching scenario

- WASD moves through open green doorways; E opens nearby chests and remains for deliberate object interactions.
- The map shows authored node positions, travel links (solid), prerequisite arrows (dashed), and a yellow **YOU** marker. Click a node to select it, use the wheel to zoom, right/middle-drag to pan, and **Fit graph** to reset the view.
- Nodes show **✓ active**, **+ available to activate**, or **× blocked**, with allocation costs in their centers. Select any node to see its state and use **Activate / Deactivate** below the map. Unavailable actions explain why. Active markers describe allocation, not permission to deactivate. Selection (white ring) does not move the player or change the build.
- Selecting an active room previews removal with **orange boxes** around all affected nodes, a named cascade list, and a total refund/post-action point budget. **Red boxes** mark a blocked removal preview; no changes or refund can occur. Scroll the selected-node details for ongoing **ALL / ANY** prerequisites, each room's current active state, and exclusive-group conflicts. Hovering the action also shows the details.
- Entering a room centers it on the map and fits its directly linked neighbors, including inactive rooms, without changing selection. Pan/zoom remains manual until the next entry; **Fit graph** shows the whole graph.
- Drag the divider between room and map to adjust their space. The window can be resized (minimum 960×640); **F11** or the header button switches fullscreen/windowed. The room scales proportionally with letterboxing, keeping its 800×600 gameplay coordinates. Resizing the map refits the current neighborhood, or the whole graph after manual navigation.
- Space performs a timed directional sword attack when Sword is active.
- Shift dashes when Boots is active. In this legacy scenario, Phase/Hit Dash retains 65% distance and bypasses enemy contact damage; Run replaces it with double-speed movement while Shift is held. Walls still block movement. Unified Phase teleport behaves differently; see the lab above.
- Blue pickups permanently increase allocation capacity; yellow pickups grant gold. Health pickups show a cross and restore HP up to the current maximum; they remain available at full health.
- Pink diamond tokens are room-local objectives and respawn on re-entry only while uncleared. Cleared rooms contain no tokens. Map badges **C** (cleared) and **R** (root) are separate from activation. Select a room to inspect its clear conditions/effects.
- Select a cleared, active root and press **Travel to root** to reach its spawn from anywhere, even across disconnected branches. Travel preserves HP and your build.
- Rooms can optionally block build editing while occupied and uncleared. The map explains the lock; clearing the room immediately restores normal activation/deactivation. Travel remains available.
- Activate both landings to activate Prize. Removing either landing also removes Prize, even if its other entrance remains connected.
- Defeat returns you to Sanctuary at full health, retaining your build and rewards.

The default scenario follows [branching-dungeon.mmd](examples/scenario-designs/branching-dungeon.mmd): activate Sword or Boots with your initial point, collect both keys, choose a style, reach its landing and collect another key. Explore the other branch, then activate Prize with both landings active. There are 14 nodes and 18 connections; all six keys fund the seven active non-root rooms on the final route. Practice rooms are optional allocations. Each branch's three styles are mutually exclusive.

Big Swing grants 1.5× reach with a two-second attack cooldown; Fast Swing performs three half-range strikes. The HP+ choices grant five max HP, and the practice rooms grant one. Starting Room and Prize each grant one; this scenario starts with one HP. Increasing maximum HP does not heal. Defeated enemies stay defeated while their room remains active; keys remain collected permanently. See the [branching scenario record](docs/knowledge/branching-scenario.md) for the design mapping and test trace.

Press **F2** to open the content editors. The current run pauses while editing.

## Content editors

**Instance doors:** tree links own instance doors. Select a tree node
and choose **Instance doors…** to preview/drag its doors, set a wall and position,
or **Reset to automatic**. New links need only two node IDs. Existing files
upgrade to V2 in memory with their door positions preserved as manual overrides;
saving writes V2. See the [accepted editor exploration](docs/editor-exploration.md).

**Canvas and history:** click to select; Alt-click cycles overlaps. Choose
**Select** to drag objects, or another brush to place over existing terrain.
Wheel zooms, right/middle-drag pans, **F** fits, and **Escape** deselects.
**Ctrl+D** duplicates; **Delete** removes; **Ctrl+Z / Ctrl+Shift+Z** undo/redo.
Each drag is one undo step. Drag the canvas/JSON divider to adjust their space.
Referenced elements explain what must be repaired before deletion.

**Tree contextual panel:** selecting a node opens **Properties**: name, cost,
ability or contribution controls, and room-template assignment.
**Edit template** navigates to the reusable source; **Duplicate & assign**
isolates the current room instance. The panel previews instance doors, including
manual dragging and the full reset selector, and summarizes dimensions, clear
rules/effects and capacity rewards.

The dungeon capability model selector chooses **Legacy** or **Unified**.
Changing the model validates the whole document; it does not convert legacy
abilities/styles or delete incompatible data. New projects start as Legacy.
For unified nodes, **Player**, **Sword**, and **Dash** sections contain quality
checkboxes and additive/multiplicative stat contribution fields. These fields
describe the selected node, not the final build; action-specific contributions
do not grant their base action. Sections collapse independently as editor-session
view state. Repeated contributions and fractional additive HP use the
individual-entry controls or JSON rather than being silently combined or rounded.
The [UI contract](docs/knowledge/ui.md#node-editor-checkpoint) describes draft,
validation and undo behavior.

**Room contextual panel:** selecting an object exposes its ID and local position,
rectangle dimensions, supported enemy HP/speed/radius, or collectible kind/value
as appropriate. White rectangle handles support edge/corner resizing. With no
object selected, **Properties** exposes the template name, instance usage, fixed
playtest dimensions, and the existing clear-rules dialog. Per-enemy damage and
playable room resizing remain deferred.

**Switch bindings:** **Bindings…** creates/removes the supported persistent
`switch.toggled → wall.set_open` interaction using node-instance and object
pickers. Selected switches/walls and tree nodes show their inbound/outbound
bindings. Templates not used by any tree node cannot be bound yet.

1. **Room editor:** select a template, choose an object brush, then click to place. Choose **Select** and drag objects to move them; drag white rectangle handles to resize. Selected-object **Properties** edits IDs, geometry, supported enemy stats and pickup values. With no object selected it edits template metadata and opens clear rules. JSON retains advanced/experimental properties. Select an object and press **Delete** to remove it.
   Use **Clear rules…** to combine enemy, switch and token conditions, reveal authored pickups/chests, prevent enemy respawns, or grant permanent root status. All selected conditions are required. With none selected, the room starts cleared and its effects apply immediately. Use the `token` brush to place room-local tokens.
   The same dialog has **Disable tree editing while inside this uncleared room** (off by default).
2. **Tree editor:** add nodes using the selected room template, drag their map positions, and use **+ Link** to connect nodes with automatic doors. Selected-node **Properties** edits names, costs, model-appropriate abilities/contributions and template assignment; JSON retains prerequisites, exclusive groups and cross-room bindings. Solid lines show travel; dashed gold lines show prerequisites.
   Use **Bindings…** to connect an instantiated switch to an instantiated wall;
   the same picker is available from selected switches/walls.
3. **Apply JSON edits** validates changes. Selection changes, saves and playtests also apply pending inspector edits; invalid edits remain available for correction.
4. **Save / Save as** writes one portable content bundle; **Open** restores it. **Import/Export room** shares individual templates between bundles. Imports reject duplicate template IDs; change the exported ID before importing a second copy.
5. **Playtest** starts a fresh run from the editor's current document, without requiring a save. **F2** returns to your retained editor document; **Resume run** continues the current run.

The editors provide contextual panels for routine edits and JSON inspectors for
detailed or unsupported source. **Bundle JSON** exposes project metadata and the
entire document, including unknown extension fields. Save before quitting the
application; unsaved changes are retained across playtests, not application restarts.

### Example bundles

Open `v2/examples/*.json` from the editor:

- `branching.json`: the full Mermaid branching design, including practice rooms, sword/dash/HP choices, two-key ability rooms, alternate landing prerequisites and the shared Prize.
- `build_arena.json`: BUILD-01 hub, six four-deep upgrade chains, separate Phase Dash, eight-point budget, crowd/durable trials and the BOSS-01 Roost Guardian.
- `water_flippers.json`: the old water/flippers topology with an actual water barrier and a prize chest. Activate Flippers from Start to cross the barrier in Water.
- `switch_wall.json`: the old switch/wall topology, capacity pickups, and a sword-operated switch that changes a wall in another room. Its state persists while the target room is unloaded or inactive.
- `combat.json`: the old combat topology, capacity progression, bats and gold rewards adapted to node allocation.
- `cleared_rooms.json`: six-node clear-state lab with shared-template enemy rooms, a switch reward, token collection and combined objectives earning a second root. [Contracts](docs/knowledge/clear-state.md); the former walkthrough is [archived](docs/archive/cleared-rooms-closeout.md).
- `tutorial_candidate.json`: a separate introductory dungeon slice with capacity, health, a sword-operated switch and provisional branch endpoints.
- `unified_tutorial_boots.json`: the evolving unified tutorial, Boots and Sword Branch candidate; its mini-boss node, encounters and rewards are provisional. [Design notes](examples/scenario-designs/unified-tutorial-boots-candidate.md).
- `phase_dash_lab.json`: unified-model comparison of ordinary Dash, Phase teleport and Water Passage.
- `Test_Dungeon.json`: an exploratory collection of room and ability-node ideas, not a completed dungeon; the evolving design graph is `scenario-designs/Test_Dungeon.mmd`.

These use V2's room-activation rules. Health is configurable per scenario;
examples can override the default five base HP. The original baseline's
temporary capacity bonuses remain additional runtime work; unknown mechanics
are retained by the format and reported by the playtest adapter rather than
ignored.

**Format and compatibility:** [content contract](docs/knowledge/content.md) and [JSON Schema](docs/content.schema.json). Files use versioned, engine-neutral JSON; stable IDs; local coordinates; and explicit references. No Godot scene paths, executable code or live-run state are saved.

## Accepted rules

1. Roots are created by clear effects, permanently active and allocate zero points. Promotion releases the node's allocation and waives upstream support. The starting room uses the same effect. Other active rooms allocate points; deactivation refunds their authored costs.
2. Activation is local and respects authored activation direction. Travel between active linked rooms is bidirectional.
3. ALL and ANY prerequisites are ongoing active-node requirements; cleared-room prerequisites are not yet supported. Exclusive groups permit at most one active member.
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
- `roost_guardian.gd`: loaded-room boss cycle, tethered movement, wave collision and telegraphs; room owns health, summons and clear events.
- `player.gd`: physics motor, dash, timed directional attack and damage cooldown. Attack parameters are captured at action start.

The room editor authors reusable templates with stable object IDs. The tree editor authors instances, link-owned doors and cross-room bindings. Bindings use `(node_id, object_id, event/action)` addresses resolved by the run coordinator, including when the target scene is unloaded. Shared template instances have independent pickups, enemies and switch/wall states.

Map coordinates determine automatic door directions in V2, while manual overrides remain fixed. Room geometry stays local; no spatial packing constraint is enforced. Validation checks IDs, template/object references, prerequisite cycles, endpoint overrides and automatic doorway capacity. Legacy V1 bundles retain port-conflict validation. Runtime room geometry is currently 800×600; other sizes are preserved in content but rejected for playtest.

### Explicit prototype policies

- Encounters: surviving enemies reset on departure; defeated enemies stay defeated while the node remains active. Deactivation resets its encounter unless a cleared room has the no-respawn effect. Permanent pickups remain collected. Switch-hit objectives latch for the run; token objective progress resets on departure.
- Health: five base HP by default; `dungeon.base_hp` can override this. Legacy max-HP bonuses and unified HP contributions can increase maximum HP; increases never heal and decreases clamp current HP. Health pickups heal separately. Room transitions and refund/reactivation do not heal. Fresh runs, defeat returns, and explicit arena trial restarts initialize full health.
- Room activation is local to the current room, not proximity to a particular door. Remote activation is not implemented; add it later as an interaction permission rather than bypassing prerequisite/resource validation.
- The demo has sword, dash and an ALL merge. ANY merges and exclusive groups are exercised by model tests. Water, flippers, remote switches/walls, chests and numeric ability modifiers are supported. Content save/load is separate from run save/load, which is still future work.
- Unified capability nodes combine enabled qualities and additive/multiplicative contributions to eight stats; action-specific effects are dormant without the corresponding action. Legacy bundles retain their own abilities and styles. See the [content contract](docs/knowledge/content.md#unified-contributions).

## Verification

Use the structured runner for authoritative full-suite results:

```powershell
python v2/tests/run_suites.py --godot C:\Godot\Godot.exe
```

See [runner instructions and verification contracts](docs/knowledge/invariants.md#running-the-contract-suites)
for area/invariant selection, timeouts, JSON reports, and runner self-tests.
For a focused run, select a suite by its stable ID:

```powershell
python v2/tests/run_suites.py --godot C:\Godot\Godot.exe --suite node_panel
python v2/tests/run_suites.py --godot C:\Godot\Godot.exe --owner frontend
python v2/tests/run_suites.py --list
```

Run from the repository root. Suite scripts live in `tests/engine/` and
`tests/frontend/`; shared runner and fixtures remain in `tests/`. Tests cover
allocations/refunds, permanent rewards, ongoing ALL/ANY prerequisites,
exclusivity, player safety, transaction previews and room/coordinator integration.

## Experiment roadmap

See the [V2 knowledge bundle](docs/knowledge/index.md) for the compact handoff record and [experiment record](docs/knowledge/experiments.md) for accepted baselines. The [V2 experiment backlog](docs/backlog.md) holds candidate ideas. The guiding goal is **“the dungeon is also a skill tree.”** BUILD-01 and BOSS-01 are accepted baselines; the current design target is an interconnected 14–18-node dungeon. The earlier [editor exploration](docs/editor-exploration.md) is complete, and unified contribution authoring is available for the dungeon work.
