# V2 experiment backlog

## Goal and prioritization

**Find which game elements work well with “the dungeon is also a skill tree.”** V2 is a featureful testbed, not a production-game milestone list.

This is a backlog of proposals, not accepted gameplay rules. All items start **Backlog**. Priority is provisional; choose one experiment at a time and revise the order based on what the last experiment taught us.

Prefer work that:

1. Answers an important question about spatial exploration, build allocation, or their interaction.
2. Makes player decisions legible enough to evaluate that question.
3. Can be tested in a small scenario with existing primitives.
4. Removes authoring friction that is actually slowing experiments.

Breadth of content, visual polish, and general-purpose infrastructure are secondary. A lower-priority item can move up when a specific scenario needs it. “Implemented” does not mean “accepted”: keep a baseline to compare against and record whether to keep, revise, or discard the experiment.

### Priority bands

- **P1 — next experiments:** direct tests of the central conceit, or essential support for those tests.
- **P2 — pull when needed:** promising mechanics and authoring aids with a concrete experimental use.
- **P3 — parked:** broad, costly, or underspecified ideas that currently teach less than smaller experiments.

## Recommended initial sequence

1. **UI-01: interactive dungeon/skill-tree map.** Make the existing branching scenario understandable before changing its rules.
2. **CLEAR-01, then CLEAR-02:** establish separate clear state with one enemy-clear condition and one reward result. Test each increment.
3. **CLEAR-04: earn persistent activation by clearing.** Compare against today's freely retained active rooms on the same small layout.
4. **CLEAR-05: remote reconfiguration of cleared rooms.** Measure whether it removes tedious walking or removes meaningful spatial decisions.
5. **CLEAR-06: warping to cleared rooms.** Test independently of remote reconfiguration before trying both together.

**UI-02 (walk-through doors)** is a useful early supporting experiment, but need not block the clear-state experiments. Pull it forward if deliberate door interaction is obscuring how exploration feels. Use the existing branching scenario for map/transition work and a smaller 4–6-node fixture for new clear-state rules.

## Gameplay presentation and traversal

### UI-01 · Interactive dungeon map / skill tree — P1

- **Question:** Does seeing the graph make build choices, routes, and consequences easier to understand?
- **First slice:** replace the gameplay node list with a graph using authored map positions, following the supplied mockup: room on the left, tree/map on the right. Support fitting the graph and basic pan/zoom if needed for legibility. Show the occupied room, active nodes, activation costs, physical links, prerequisite direction and ALL/ANY requirements. Selecting a node exposes activation/deactivation and a short reason when unavailable; preview cascading removals/refunds.
- **Boundary:** clicking the map uses existing local-interaction validation. A map interface does not itself grant remote activation. Keep travel links distinguishable from prerequisite relationships. Use labels/symbols as well as color.
- **Evaluate:** can someone find a route to Prize, identify what funds their build, and predict what removing a style will deactivate without consulting the JSON?
- **Depends on:** current progression previews and authored coordinates; not automatic layout.

### UI-02 · Border doors with walk-through transitions — P1

- **Question:** Does continuous doorway movement make visiting and revisiting build branches feel more natural?
- **First slice:** a visible room boundary with physical openings for linked doors. Walking across an available opening transitions into the destination at its paired entrance. Inactive/unavailable destinations remain blocked and visibly distinct. Keep E for chests and other deliberate interactions.
- **Boundary:** preserve named port references; document how existing interior port positions map to boundary openings. Place arrivals inside the destination and prevent immediate bounce-back. Test both walking and dash crossing. Door passability remains separate from node cost/activation.
- **Evaluate:** can players intentionally enter/leave rooms without accidental transitions, wall snagging, or needing an extra interaction key?
- **Depends on:** current links and portal pairing. CLEAR-03 later adds encounter-controlled locks.

## Clear state and activation experiments

Keep **active**, **cleared**, **discovered**, **loaded**, and **physically traversable** as separate concepts. Clear state belongs to a node instance, not its shared room template. New rules are opt-in per scenario/room; existing scenarios remain the control condition.

### CLEAR-01 · Optional clear conditions and visible clear state — P1

- **Question:** Does “cleared” convey a useful kind of progress independent of the current build?
- **First slice:** a room can declare “all authored enemies defeated.” Record clear state and show a separate cleared marker on the gameplay map. Do not change activation permissions yet. Make the condition opt-in so empty rooms are not silently auto-cleared.
- **Decide before implementation:** does clearing persist through deactivation, death, and encounter reset? Suggested first experiment: it persists for the current run, independently of current enemy respawns. Runtime save games remain a separate concern.
- **Evaluate:** can a player distinguish active-but-uncleared, cleared-but-inactive, and cleared-and-active rooms? Does the chosen persistence policy make sense?
- **Depends on:** encounter events and per-node run state; UI-01 is useful for feedback.

### CLEAR-02 · Clear-triggered results: reveal a pickup — P1

- **Question:** Does rewarding completion strengthen the relationship between room challenges and build progression?
- **First slice:** clearing an enemy room reveals one pre-authored hidden capacity pickup or coin. Give it a stable object ID; the result fires once per intended clear lifecycle and collecting it cannot duplicate rewards on re-entry or scene reload.
- **Boundary:** implement one condition/result pairing before designing a general scripting language. Reusing a template must not share rewards or clear state between nodes.
- **Evaluate:** is the objective/reward understandable, and does the reward change the next allocation decision?
- **Depends on:** CLEAR-01.

### CLEAR-03 · Button-controlled persistent door locks — P2

- **Question:** Can room objectives gate physical travel without making activation rules confusing?
- **First slice:** one authored door starts locked and becomes permanently unlocked for the run when a button is pressed. The destination must still be active to traverse it. Later compare a clear-triggered unlock using the same result mechanism.
- **Boundary:** distinguish “locked by an encounter” from “destination inactive.” Define whether the lock applies to both sides of a passage and ensure the button is reachable; provide a deliberate escape route in the test scenario.
- **Evaluate:** can players explain why a door is blocked and what will open it? Does the objective add a useful encounter decision?
- **Depends on:** UI-02 for the intended doorway experience; explicit run-state results similar to CLEAR-02.

### CLEAR-04 · Uncleared rooms lose activation on retreat — P1

- **Question:** Is earning the ability to retain a room more interesting than retaining it immediately on activation?
- **First slice:** in a simple rooted branch, activate and enter an uncleared room normally; leaving back toward its parent deactivates it and refunds its allocation. Clearing it allows the same exit without deactivation. Compare the identical room without this rule.
- **Decide before implementation:** define “toward the root” for this experiment. Start with explicit parent/retreat edges; arbitrary graphs with merges, cycles, and multiple entries do not have a unique parent. Specify forward exits, death, cascade/refund order and the effect on dependents. Move the player to a valid destination before validating/applying automatic deactivation; never bypass occupied-room protection.
- **Evaluate:** does the room feel like an ability trial? Do players make different choices, or simply endure repeated encounters/backtracking? Watch for reward farming and repeated activation healing under the existing HP rule.
- **Depends on:** CLEAR-01; CLEAR-02 provides a useful comparison reward but is not mandatory.

### CLEAR-05 · Remote activation/deactivation of cleared rooms — P1

- **Question:** Does earned remote reconfiguration preserve the meaningful part of local exploration while removing busywork?
- **First slice:** map interaction can remotely activate/deactivate cleared nodes. Uncleared nodes retain local rules. Keep costs, ongoing prerequisites, exclusivity, root connection, cascading refunds, and player-location safety.
- **Decide before implementation:** what does an activation-direction edge mean for a remote command with no local source room? Define eligible active upstream support explicitly. Also decide whether a cascade may remove uncleared dependent nodes when its cleared parent is remotely deactivated.
- **Evaluate:** compare walking/reconfiguration time and build changes before/after unlocking this permission. Are players still making spatial decisions?
- **Depends on:** CLEAR-01 and UI-01. Can be tested without CLEAR-04.

### CLEAR-06 · Warp to cleared rooms — P1

- **Question:** Is travel between solved spaces useful pacing, or friction that conceals the interesting allocation decisions?
- **First slice:** warp between cleared, currently active rooms to authored safe arrival points. Compare to normal traversal with remote activation disabled, then test the combination separately.
- **Decide before implementation:** the proposal “any cleared room” includes inactive rooms, which conflicts with the current occupied-room invariant. A later variant can activate an inactive target first, but must obey allocation/support rules. Define whether warping is allowed during combat and from uncleared rooms; start with cleared source rooms so it is not an accidental encounter escape mechanic.
- **Evaluate:** does warping encourage trying more builds, or make the physical dungeon irrelevant?
- **Depends on:** CLEAR-01 and a target-selection interface, ideally UI-01.

## Authoring quality of life

These generally follow gameplay experiments unless editing friction is preventing them. Preserve the portable content boundary: UI controls edit source JSON values and stable IDs, not runtime objects; unknown fields survive edits.

### EDIT-01 · Select a tree element to focus its JSON — P2

- **First slice:** selecting a node or link focuses/highlights its JSON object with a clear way back to the full tree document. Apply edits to that identified element while retaining unrelated fields and pending text.
- **Evaluate:** can a larger graph be edited without searching through the full document or accidentally modifying the wrong node?
- **Depends on:** existing tree preview and inspector.

### EDIT-02 · Select a room element to focus its JSON — P2

- **First slice:** selecting an object or port focuses its JSON entry; show selection on the canvas and retain a full-template view. Handle overlapping objects deliberately.
- **Evaluate:** does this remove the main friction in changing dimensions, enemy stats, and pickup properties?
- **Depends on:** existing room preview and inspector; can share selection/inspector mechanics with EDIT-01.

### EDIT-03 · Node template and ability selectors — P2

- **First slice:** a selected tree node has dropdowns/lists for room template and granted abilities. Preserve JSON access for modifiers and experimental values. Allow multiple grants rather than assuming each node grants exactly one ability.
- **Boundary:** changing a template can invalidate linked ports and cross-room object references. Show those conflicts and let the author repair them; do not silently delete bindings or invent replacements. Existing unknown ability values must survive opening the selector.
- **Evaluate:** is assigning/reusing rooms appreciably faster without hiding the data model?
- **Depends on:** EDIT-01; a small supported-ability catalogue, not a new ability framework.

### EDIT-04 · Cross-room interaction indicators — P2

- **First slice:** mark nodes containing switches or other cross-room endpoints; selecting one lists inbound/outbound bindings and identifies source and target objects.
- **Evaluate:** can an author locate and explain a remote wall interaction from the graph alone?
- **Depends on:** existing binding data; EDIT-01 helps navigation.

### EDIT-05 · Cross-room binding picker — P2

- **First slice:** a submenu chooses a source switch, target node and compatible target wall/action. Show object IDs and template context; validate before applying.
- **Evaluate:** can the existing switch/wall example be recreated without manually typing addresses?
- **Depends on:** EDIT-04; start with the existing switch → wall pairing.

### EDIT-06 · Capacity-key budget HUD — P2, small

- **First slice:** show starting capacity, total capacity obtainable from authored pickups, and their sum. Count **node instances**, including reused templates, and sum pickup values rather than simply counting objects. Unused library templates do not contribute. Include chest rewards and, once supported, hidden clear rewards as authored potential capacity.
- **Boundary:** distinguish total potential capacity from currently collectible or provably reachable capacity. This is a budget summary, not a solvability claim.
- **Evaluate:** does it catch obvious allocation shortfalls while authoring a branching scenario?
- **Depends on:** current content graph; no solver required.

### EDIT-07 · Navigability / progression analysis — P3, research

- **First slice:** define the question before implementing a solver: structural reachability, a feasible allocation sequence, reward accessibility, physical room traversability, or a guaranteed route to an objective are different problems. A useful first tool may only report disconnected nodes and insufficient total potential capacity.
- **Boundary:** existing validation already checks references, duplicate ports and prerequisite cycles. A future search must account for local interactions, refunds, pickups, player position and any clear/lock policies. It must state which hazards/combat outcomes it assumes away and report “unknown” rather than claiming a proof it does not have.
- **Evaluate:** does it identify actual scenario mistakes with explainable evidence?
- **Depends on:** an agreed definition of solvability and sufficiently stable experimental rules.

### EDIT-08 · Grid/tile painting for room templates — P3

- **First slice:** a fixed-resolution grid for painting water/solid terrain, with existing objects still placeable as objects. Determine whether the grid is an authoring convenience compiled to current geometry or an engine-visible tile layer before expanding it to pickups/items.
- **Boundary:** preserve arbitrary object/port IDs and existing templates. If persisted representation changes, define a versioned migration or explicit conversion rather than making editor widgets the save format.
- **Evaluate:** can typical rooms be authored faster, and does a grid improve designs enough to justify the change?
- **Depends on:** repeated evidence that coordinate/rectangle editing is the bottleneck; not required for current V2 scenarios.

## Gameplay primitives — choose by scenario need

Avoid building the whole catalogue first. Each primitive should enable a choice or room relationship that current sword/dash/HP modifiers cannot test. HP and speed already exist; their entries below concern new uses of them.

| ID | Priority | Experiment / smallest slice | Question / useful evidence | Dependencies |
| --- | --- | --- | --- | --- |
| AB-01 | P2 | **Shield:** one directional block against a clearly telegraphed attack. | Does a defensive branch offer a meaningful alternative to extra HP or mobility? | An enemy attack the player can read; existing capability grants. |
| AB-02 | P2 | **Ranged attack:** one projectile, one enemy/target, basic wall collision. | Do range and room geometry make allocating this branch situationally valuable? | A room where distance matters; projectile hit ownership. |
| AB-03 | P2 | **Bomb:** one delayed area effect and one compatible breakable obstacle. | Can an ability connect combat choices to opening a useful route? | Damageable objects/results; decide reusable cooldown versus consumable supply for the experiment. |
| STAT-01 | P2 | **HP progression:** compare HP nodes against ability variants using current bonuses. | Are health nodes genuine build alternatives? Does activation healing dominate the choice? | Existing HP implementation; no new stat engine needed. |
| STAT-02 | P2 | **Speed progression:** one speed node and one traversal challenge. | Does speed change route/build choices beyond making walking faster? | Existing speed multiplier; compare with current sprint. |
| STAT-03 | P2 | **Vision / map reveal:** reveal inactive nodes up to an authored graph distance; one node increases it. | Is information valuable enough to allocate build resources to? | UI-01; specify graph-distance metric and whether previously discovered nodes remain visible after the bonus is lost. |
| STAT-04 | P3 | **Luck:** a seeded reward table and one modifier. | Can reward-oriented builds compete meaningfully with combat/traversal builds? | Reward/drop system; keep test progression solvable without lucky rolls, record seeds for comparison. |
| STAT-05 | P2 | **MP:** one resource pool and one ability consuming it. | Does a magic-resource branch add an interesting allocation decision or merely interrupt play? | AB-02 or AB-03 is a possible consumer; define recovery and behavior when max MP changes. |
| STAT-06 | P2 | **Stamina:** one pool, one consumer such as dash/block, one recovery rule. | Does a shared exertion budget create useful tradeoffs among abilities? | Existing dash or AB-01; test separately from MP first. |
| HAZ-01 | P2 | **Darkness:** one dark room and one illumination/vision benefit. | Can allocating perception alter how a room is explored? | A readable darkness representation; distinguish room visibility from STAT-03's map reveal. |
| HAZ-02 | P2 | **Pits:** one pit region and one defined crossing/recovery behavior. | Does traversal capability change which rooms/routes are attractive? | A movement solution and explicit fall/recovery rule; compare with existing water/flippers. |
| HAZ-03 | P2 | **Spikes:** one static or timed damage zone. | Can environmental timing make defensive/mobility choices relevant without extra enemy types? | Damage cooldown and clear visual feedback. |
| HAZ-04 | P2 | **New enemy behavior:** one telegraphed attacker, charger, or ranged enemy chosen to test one branch. | Does it expose a difference between builds that chasing bats cannot? | Pick the target build question first; avoid an enemy roster project. |
| LOOT-01 | P2 | **Hearts:** one collectible restoring HP up to the current maximum. | Can encounter rewards provide recovery without relying on reallocating HP rooms? | Existing health; decide whether a full-health pickup is consumed. |
| LOOT-02 | P2 | **MP restoration:** one pickup restoring MP up to its maximum. | Does recovery placement make magic allocation and route choice interesting? | STAT-05. |
| LOOT-03 | P2 | **Temporary powerups:** one timed effect, such as speed, layered over the active build. | Does temporary power complement the skill tree or obscure which rooms grant the player's abilities? | Capability composition and an explicit expiry/stacking rule; test one effect. |

## Dungeon layout and geometry

### LAYOUT-01 · Suggest a spatial layout from the skill tree — P3, research

- **Question:** Can automatic placement make the dungeon's geography reinforce the build graph?
- **First slice:** an editor command suggests a layout for one small graph, with author review and manual overrides. Distinguish arranging map nodes from physically packing rooms and pairing entrances; the latter is much more constrained.
- **Boundary:** arbitrary prerequisite/travel graphs may have crossings, incompatible directions or no tidy non-overlapping embedding. Prefer a rough, explainable suggestion with unresolved constraints over an implicit guarantee. Keep authored map coordinates, room geometry and prerequisite edges separate.
- **Evaluate:** does the result improve orientation or authoring time compared with hand placement?
- **Depends on:** clearer preferences from hand-authored scenarios; UI-02 informs doorway constraints. Variable room sizes are not a prerequisite for a first study.

### LAYOUT-02 · Variable room dimensions — P3

- **Question:** Does room scale create meaningful encounter/traversal choices for the skill tree?
- **First slice:** one small and one large room, with correct boundaries, camera/view fitting, named doors and safe spawns.
- **Boundary:** portable room data already has `size`; the adapter currently restricts playtests to 800×600. Generalize runtime geometry/rendering/editor framing rather than adding a competing size field.
- **Evaluate:** can a specific scenario exploit size in a way the current fixed rooms cannot?
- **Depends on:** a demonstrated scenario need; coordinate with UI-02 rather than requiring automatic layout.

## How to run and record an experiment

Before implementing an item, agree on its smallest slice and unresolved rule choices. Use scenario-specific policy/data where practical so competing rules can be compared. Preserve current portable IDs and unknown fields; introduce explicit, tested migrations when content semantics require a format change. Experimental clear/permission state should not be inferred from whether a scene happens to be loaded.

For each experiment:

1. Pick one hypothesis and a baseline scenario. Change one major rule at a time.
2. Define an observable success signal. Simple notes are enough; do not build telemetry infrastructure just to start.
3. Implement and check relevant behavioral invariants. Freeze presentation details only after the interaction proves useful.
4. Playtest, recording useful decisions separately from confusion, backtracking and authoring friction.
5. Decide **keep / revise / discard** and choose the next item from that evidence.

Suggested log entry (append here or link a dedicated note):

```text
Item ID / date:
Status: Backlog | Selected | In progress | Ready to playtest | Evaluated
Question and predicted benefit:
Scenario and baseline:
Exact rule/UI change:
Unresolved choices resolved for this slice:
Checks and playtest observations:
User-facing result:
Friction and mitigation:
Decision: keep | revise | discard
Accepted rules (only after confirmation):
Next experiment:
```

### Experiment log

No experiments from this backlog have been selected or implemented yet. The existing branching scenario and its tests are the starting baseline.
