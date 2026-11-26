# V2 experiment backlog

## Goal and prioritization

**Find which game elements work well with “the dungeon is also a skill tree.”** V2 is a featureful testbed, not a production-game milestone list.

This is a backlog of proposals, not accepted gameplay rules. Items start **Backlog**; UI-01/UI-02, CLEAR-01/02/07/08/09/10/11, BUILD-01 and BOSS-01 are **Completed** as accepted baselines. See the [experiment record](knowledge/experiments.md). Priority is provisional; choose one experiment at a time and revise the order based on what the last experiment taught us.

Prefer work that:

1. Answers an important question about spatial exploration, build allocation, or their interaction.
2. Makes player decisions legible enough to evaluate that question.
3. Can be tested in a small scenario with existing primitives.
4. Removes authoring friction that is actually slowing experiments.

Breadth of content, visual polish, and general-purpose infrastructure are secondary. A lower-priority item can move up when a specific scenario needs it. “Implemented” does not mean “accepted”: keep a baseline to compare against and record whether to keep, revise, or discard the experiment. The sprint groupings below are a proposed sequence of small, related slices, not a commitment to ship every item or an acceptance of new rules.

### Priority bands

- **P1 — next experiments:** direct tests of the central conceit, or essential support for those tests.
- **P2 — pull when needed:** promising mechanics and authoring aids with a concrete experimental use.
- **P3 — parked:** broad, costly, or underspecified ideas that currently teach less than smaller experiments.

## Proposed sprint sequence

Sprints are outcome-based, with no assumed duration. Work on one major gameplay
question at a time within a sprint; use the result to revise or skip later
sprints. Supporting editor and presentation work is pulled only when it affects
the slice. Items not listed remain in their priority bands below.

| Order | Outcome and grouped work | Exit evidence / decision |
| --- | --- | --- |
| **1 · Flesh out Sword Branch** | Retain the confirmed abilities and connections; develop more distinctive room layouts and enemy behaviors for Spear, Heavy, Sword Landing and Strength Up. Pick new enemy movement only where it tests a specific build choice. Tune rewards and funding through play. Pull **UI-03** if missing cues prevent a fair evaluation. | User playtests and decides what to keep/revise. Experimental layout is not gated on deterministic level-design checks. |
| **2 · Midpoint prerequisites and encounter** | Finalize which specific rooms in each branch are the mini-boss prerequisites. Implement **cleared-room prerequisites** with active and cleared conditions separate, then add a mini-boss enemy and arena that awards the second root on clear. | Engine checks new mechanic and encounter behavior; user evaluates the room choices, fight and pacing. The existing cost-1000 visual placeholder is not a miniboss implementation. |
| **3 · Connected branch and puzzle** | Design a continuation toward the target dungeon: individual upgrades and pairings, a required ability approached by mutually exclusive routes, and a multi-room refund/reallocation puzzle using persistent switch/wall state where feasible. Consider funding, return and persistence. Pull **EDIT-09/10/11** or **EDIT-06** if actual authoring friction warrants it. | A playable subsection; user evaluates whether the spatial and build decisions are meaningful. Identify unsupported mechanics rather than assuming them. |
| **4 · Capstone integration** | Connect the evaluated sections to the accepted Guardian in a shareable, approximately 14–18-node candidate, with at most two roots. Revisit **LOOT-01** placement and **STAT-01/02** as build and recovery comparisons; address **UI-03** before external sharing if needed. Tune the boss against dungeon builds rather than the workshop in isolation. | Trace at least representative navigation- and combat-leaning routes and final budgets, then playtest the end-to-end tradeoff, recovery and pacing. Decide keep/revise/discard; do not infer enjoyment or general solvability from validation. |
| **5 · Evidence-driven follow-ups** | Pull **LOOT-04**, other abilities/hazards, or broader layout and clear-state ideas only in response to a specific observation and hypothesis. Group related resource work (STAT-05 + LOOT-02, or STAT-06 + AB-01) as separate experiments rather than adding both pools at once. Presentation and editor priorities are sequenced separately below. | State the comparison, rule choices and evidence sought before implementation; retain accepted baselines and record user observations separately from automated checks. |

**Priority adjustments:** Sword Branch development and the midpoint prerequisite
and encounter are the next P1 work. The user requested cleared-room
prerequisites; specify the smallest supported semantics and presentation before
implementation. The presentation/editor sequence below is an ordered workstream,
not a replacement for these gameplay priorities. EDIT-06/09/10/11 remain P2
pull-as-needed. Random drops and new enemy locomotion remain P2 candidates, not
prerequisites to opening work.

**Checkpoint caveat:** after the user's geometry edits the candidate compiled;
the layout-specific route suite was subsequently retired at the user's request.
The full general regression run passed 30/30 suites. The user observed that
refunding Flippers in water pushes the player to an edge and explicitly deferred
general clipping prevention.

## Current checkpoint

1. **UI-01: interactive dungeon/skill-tree map — Completed.** Baseline functionality accepted; UX polish deferred.
2. **CLEAR-01/02/07/08/09/10/11 — Completed, baseline accepted:** clear conditions/effects, permanent roots, optional occupied-uncleared editing locks and root travel. `examples/cleared_rooms.json` remains the demonstration fixture.
3. **Baseline hardening completed:** deferred transitions are isolated to their originating room/run, editor pause survives arrivals, and initial-health validation accounts for every immediate root. All 12 headless suites pass; see the [archived hardening record](archive/cleared-rooms-closeout.md#baseline-hardening).
4. **UI-02 — Completed, baseline accepted.** Walk-through border doors are the traversal baseline. CLEAR-03 through CLEAR-06 remain potential future experiments.
5. **BUILD-01 — Completed, baseline accepted.** Stackable sword/dash modifiers, max-HP-only upgrades, and the expanded eight-point workshop are retained. See the [architectural closeout](archive/build-01-closeout.md).
6. **BOSS-01 — Completed, capstone accepted (2026-11-16):** free Roost Guardian trial retained as the encounter to design the dungeon around. Tweaking/polish is deferred. See the [architectural closeout](archive/boss-01-closeout.md).
7. **Current focus:** develop the interconnected 14–18-node dungeon. The user confirmed the new Sword Branch abilities and connections; distinctive rooms and encounters remain to be developed. Finalize midpoint prerequisites, implement cleared-room prerequisites, and add the mini-boss and arena. See the [experiment record](knowledge/experiments.md).

See the current [clear-state contract](knowledge/clear-state.md).
The earlier CLEAR-03/04/05/06 proposals are retained below for future consideration.

Keep the branching scenario, clearing lab and BUILD-01 workshop as regression
baselines. The boss is now an accepted capstone for dungeon design.

### Next design target — interconnected prototype dungeon

Use the accepted ability and boss baselines to design rooms, build working
subsections, then connect them into one shareable 14–18-node dungeon.
Carry forward the user's desired moments:

* A constrained point budget that makes retaining navigation and combat
  investment a genuine tradeoff at the end boss.
* An early obstacle with multiple skill solutions, followed by specialized
  challenges; author within current mechanics or explicitly select additions.
* Individual skill customization plus merged branches rewarding pairings.
* A required progression ability reachable through mutually exclusive routes.
* A multi-room puzzle requiring deliberate ability use, refund and reallocation
  in sequence, with persistent world changes.
* A halfway mini-boss that earns the second root/warp point; two roots maximum.

Plan build funding and persistent-state transitions alongside physical routes.
The 29-node workshop remains a testing fixture, not the target dungeon layout.
Presentation legibility supports fair evaluation; boss tuning follows dungeon
design and feedback.

### Dungeon-enabling candidates

These are proposals for the interconnected dungeon, not accepted rules. Select
and evaluate small slices separately; preserve existing regression scenarios.
`examples/Test_Dungeon.json` is exploratory material, and
`examples/scenario-designs/Test_Dungeon.mmd` sketches the proposed opening,
branches and mini-boss; it is a design, not a validated playable route.
The separate `examples/unified_tutorial_boots.json` candidate brings the
tutorial and Boots Branch into the unified model; its temporary funding aid and
other placeholders are documented in
`examples/scenario-designs/unified-tutorial-boots-candidate.md`. The user
playtested and revised the opening; a provisional Sword Branch has since been
added and its abilities and connections confirmed by the user. Encounter
balance and layouts remain open. Earlier route checks predate the revised
geometry. Level-design iteration is experimental and is not gated on
deterministic scenario validation.

- **Cleared-node prerequisites — P1 next step (Sprint 2):** Finalize which
  specific rooms from each branch gate the mini-boss and implement the
  cleared-room prerequisite feature. Current ALL/ANY prerequisites test active
  nodes only; preserve the distinction between persistent clear state and active
  allocation. The current sketch requires both active and cleared; agree the
  exact scope, preview and execution semantics before implementation.
- **Midpoint mini-boss and arena — P1 next step (Sprint 2):** Replace the
  cost-1000 visual placeholder with a designed enemy and arena, with
  `become_root` on clear. Respect the two-root maximum and test the encounter
  experience with the user; its behavior is not yet selected.
- **LOOT-01 — HP pickups — implemented:** Authored health pickups and chests
  restore a fixed amount up to current maximum HP, remain available at full HP,
  and are collected once per node/object per run. The tutorial candidate places
  healing in Key Storage. Max-HP allocation itself still does not heal; see the
  [content contract](knowledge/content.md#health-pickups).
- **LOOT-04 — Random enemy health drops:** Test health drops from defeated
  enemies. Decide drop probability, reproducibility, pickup lifetime, and
  behavior on re-entry, respawn and repeated kills; check for farming and
  unreliable recovery. Depends on a defined HP pickup.
- **HAZ-04a — Enemy movement and locomotion:** Explore skeletons moving
  semi-randomly along cardinal directions and snakes moving along one axis
  and bouncing off obstacles. Proposed collision policy: flying bats and
  Guardian pass over water but not walls; walking enemies pass through neither.
  Specify behavior when Flippers are allocated or refunded, and validate
  Guardian arena assumptions separately. Future hazards and locomotion types
  need their own explicit interaction rules.
- **Sword/terrain interaction — P1 investigation if needed (Sprint 1):** Room 7 proposes a trapped
  enemy reachable with either a long sword or Flippers. Current hit checks
  without Flippers are blocked by water; decide whether to change that rule or
  use different geometry before treating this as a supported solution.
- **Water-passage refund / clipping — deferred:** The user observed that
  refunding Flippers while standing in water pushes the player to a water edge.
  The player can become stuck between water and another obstacle. The user does
  not want prevention or a general clipping solution for the current dungeon.

Existing `reveal_pickup` supports clear-revealed capacity or gold pickups and
chests; no new capacity-reveal mechanic is currently identified. Existing
switch-to-wall bindings toggle the wall, which is acceptable for the shortcut.
A permanent non-toggleable switch is a separate possible future element, not a
requirement for this opening.

## Gameplay presentation and traversal

### Presentation and editor UX sequence — proposed

Execute these dependency bands in order, selecting small reviewable slices; they
do not reorder unrelated dungeon experiments or authorize gameplay rule changes.

1. **Frontend-independent of engine changes:** create a coherent standard icon
   asset set; improve room-object labels/symbols, map visual hierarchy and editor
   organization using already available data. Prototype readable zoom, context
   controls and fallback labels. Do not invent state or supported mechanics.
2. **Existing engine capabilities through clean frontend contracts:** verify what
   facts are already supplied, then expose any missing facts through copied,
   authoritative snapshots/events and intents before consuming them. UI-03,
   map and editor context may span bands 1 and 2; an existing mechanic does not
   imply its presentation contract already exists. Engine and Frontend agree the
   contract first; execution remains authoritative.
3. **Actual engine/content capability changes:** only after explicit scope and
   rule decisions, consider authorable icon identifiers if current portable
   content cannot support them, new-project model defaults or migration, and
   other new mechanics. Cleared-room prerequisites remain the separately
   prioritized dungeon feature, not a UI prerequisite. Validate changes and
   preserve existing bundles rather than silently converting them.

#### UI-03 · Combat, room and map legibility — candidate

- **Observation:** The user reported that sword range/activation indicators
  disappeared after the unified ability change. Investigate and reproduce
  before assuming a cause or changing the accepted legacy presentation.
- **Combat:** Show the sword hitbox/sector and hit timing from captured,
  authoritative action geometry and timing; do not recompute from a changed
  build or imply the displayed sector is the set of targets actually hit.
  Convey occlusion and suppressed hits using authoritative resolution facts
  where available; investigate missing contracts rather than promising an exact
  occlusion display. Put graphical sword and dash cooldown/readiness cues by the avatar.
  Legacy and unified timing differ; distinguish cooldown/readiness from movement
  restriction timers, including overlapping restrictions. Existing restriction
  events are not cooldown clocks. Confirm available phase and readiness facts
  with Engine before specifying any missing presentation contract.
- **Room objects:** Make diagonal obstacle labels legible; distinguish enemy
  type and danger without color alone. Use recognizable gold `$`, capacity key
  and health cross cues, retaining values and existing health behavior.
- **Map:** Explore an icon-led minimap centered on the occupied room and its
  direct neighbors, preserving selection, manual pan/zoom, Fit graph, and
  existing state and consequence distinctions. Provide standard icons and an
  authorable choice where supported; investigate a portable, validated icon
  contract otherwise, preserving unknown content and a readable fallback.
  Test zoom and label density at practical sizes: zoom trades context for
  readability and cannot guarantee no overlap.
- **Evaluate:** Can players predict reach and action readiness, distinguish
  hazards and rewards, and orient themselves without losing map actions or
  consequences? Check representative sizes and legacy/unified scenarios; seek
  user playtest evidence before deciding keep/revise/discard.

### UI-01 · Interactive dungeon map / skill tree — P1 — Completed

- **Closeout:** user accepted baseline actions, room-entry framing and consequence clarity, and explicitly deferred UX polish. The original functional scope is complete. See the current [UI contract](knowledge/ui.md). This is a UI acceptance milestone, not a claim that the full scenario has been independently usability-tested.

- **Question:** Does seeing the graph make build choices, routes, and consequences easier to understand?
- **First slice:** replace the gameplay node list with a graph using authored map positions, following the supplied mockup: room on the left, tree/map on the right. Support fitting the graph and basic pan/zoom if needed for legibility. Show the occupied room, active nodes, activation costs, physical links, prerequisite direction and ALL/ANY requirements. Selecting a node exposes activation/deactivation and a short reason when unavailable; preview cascading removals/refunds.
- **Boundary:** clicking the map uses existing local-interaction validation. A map interface does not itself grant remote activation. Keep travel links distinguishable from prerequisite relationships. Use labels/symbols as well as color.
- **Evaluate:** can someone find a route to Prize, identify what funds their build, and predict what removing a style will deactivate without consulting the JSON?
- **Depends on:** current progression previews and authored coordinates; not automatic layout.

### UI-02 · Border doors with walk-through transitions — P1 — Completed

- **Question:** Does continuous doorway movement make visiting and revisiting build branches feel more natural?
- **First slice:** a visible room boundary with physical openings for linked doors. Walking across an available opening transitions into the destination at its paired entrance. Inactive/unavailable destinations remain blocked and visibly distinct. Keep E for chests and other deliberate interactions.
- **Accepted mapping:** a port maps to its nearest inner room edge (x=50/750 or y=70/570 in the fixed 800×600 room), and its coordinate along that edge centers a 64px boundary opening. An arrival starts at its paired port and cannot retrigger that exit until the player has moved 80px away.
- **Closeout:** playtesting found the walk-through doors more intuitive than deliberate door interaction. Keep the traversal behavior; visual polish remains deferred.
- **Boundary:** preserve named port references; document how existing interior port positions map to boundary openings. Place arrivals inside the destination and prevent immediate bounce-back. Test both walking and dash crossing. Door passability remains separate from node cost/activation.
- **Evaluate:** can players intentionally enter/leave rooms without accidental transitions, wall snagging, or needing an extra interaction key?
- **Depends on:** current links and portal pairing. CLEAR-03 later adds encounter-controlled locks.

## Clear state and activation experiments

Keep **active**, **cleared**, **discovered**, **loaded**, and **physically traversable** as separate concepts. The progression model owns clear state per node instance, parallel to activation; templates author optional condition/effect arrays. Rooms without a condition are cleared by default, and clear state persists through deactivation. Additional effects and permission rules are opt-in. Existing scenarios remain the activation/traversal control condition.

### CLEAR-01 · Optional clear conditions and visible clear state — Completed — Accepted baseline

- **Question:** Does “cleared” convey a useful kind of progress independent of the current build?
- **First slice:** a room can declare “all authored enemies defeated” within an optional condition array. Record model-owned clear state and show a separate cleared marker on the gameplay map. Rooms without conditions start cleared, including inactive rooms.
- **Confirmed:** ALL composition; persistence through deactivation, death and room reload for the run; default-clear effects apply immediately. Runtime save games remain a separate concern.
- **Evaluate:** can a player distinguish active-but-uncleared, cleared-but-inactive, and cleared-and-active rooms? Does the chosen persistence policy make sense?
- **Depends on:** encounter events and per-node run state; UI-01 is useful for feedback.

### CLEAR-02 · Clear-triggered results: reveal a pickup — Completed — Accepted baseline

- **Question:** Does rewarding completion strengthen the relationship between room challenges and build progression?
- **First slice:** clearing an enemy room reveals one pre-authored hidden capacity pickup or coin. Give it a stable object ID; the result fires once per intended clear lifecycle and collecting it cannot duplicate rewards on re-entry or scene reload.
- **Boundary:** implement one condition/result pairing before designing a general scripting language. Reusing a template must not share rewards or clear state between nodes.
- **Evaluate:** is the objective/reward understandable, and does the reward change the next allocation decision?
- **Depends on:** CLEAR-01.

### CLEAR-03 · Button-controlled persistent door locks — P3 — Potential future experiment

- **Question:** Can room objectives gate physical travel without making activation rules confusing?
- **First slice:** one authored door starts locked and becomes permanently unlocked for the run when a button is pressed. The destination must still be active to traverse it. Later compare a clear-triggered unlock using the same result mechanism.
- **Boundary:** distinguish “locked by an encounter” from “destination inactive.” Define whether the lock applies to both sides of a passage and ensure the button is reachable; provide a deliberate escape route in the test scenario.
- **Evaluate:** can players explain why a door is blocked and what will open it? Does the objective add a useful encounter decision?
- **Depends on:** UI-02 for the intended doorway experience; explicit run-state results similar to CLEAR-02.

### CLEAR-04 · Uncleared rooms lose activation on retreat — P3 — Potential future experiment

- **Question:** Is earning the ability to retain a room more interesting than retaining it immediately on activation?
- **First slice:** in a simple rooted branch, activate and enter an uncleared room normally; leaving back toward its parent deactivates it and refunds its allocation. Clearing it allows the same exit without deactivation. Compare the identical room without this rule.
- **Decide before implementation:** define “toward the root” for this experiment. Start with explicit parent/retreat edges; arbitrary graphs with merges, cycles, and multiple entries do not have a unique parent. Specify forward exits, death, cascade/refund order and the effect on dependents. Move the player to a valid destination before validating/applying automatic deactivation; never bypass occupied-room protection.
- **Evaluate:** does the room feel like an ability trial? Do players make different choices, or simply endure repeated encounters/backtracking? Watch for reward farming. BUILD-01 removes activation healing.
- **Depends on:** CLEAR-01; CLEAR-02 provides a useful comparison reward but is not mandatory.

### CLEAR-05 · Remote activation/deactivation of cleared rooms — P3 — Potential future experiment

- **Question:** Does earned remote reconfiguration preserve the meaningful part of local exploration while removing busywork?
- **First slice:** map interaction can remotely activate/deactivate cleared nodes. Uncleared nodes retain local rules. Keep costs, ongoing prerequisites, exclusivity, root connection, cascading refunds, and player-location safety.
- **Decide before implementation:** what does an activation-direction edge mean for a remote command with no local source room? Define eligible active upstream support explicitly. Also decide whether a cascade may remove uncleared dependent nodes when its cleared parent is remotely deactivated.
- **Evaluate:** compare walking/reconfiguration time and build changes before/after unlocking this permission. Are players still making spatial decisions?
- **Depends on:** CLEAR-01 and UI-01. Can be tested without CLEAR-04.

### CLEAR-06 · Warp to cleared rooms — P3 — Potential future experiment

- **Question:** Is travel between solved spaces useful pacing, or friction that conceals the interesting allocation decisions?
- **First slice:** warp between cleared, currently active rooms to authored safe arrival points. Compare to normal traversal with remote activation disabled, then test the combination separately.
- **Decide before implementation:** the proposal “any cleared room” includes inactive rooms, which conflicts with the current occupied-room invariant. A later variant can activate an inactive target first, but must obey allocation/support rules. Define whether warping is allowed during combat and from uncleared rooms; start with cleared source rooms so it is not an accidental encounter escape mechanic.
- **Evaluate:** does warping encourage trying more builds, or make the physical dungeon irrelevant?
- **Depends on:** CLEAR-01 and a target-selection interface, ideally UI-01.

### CLEAR-07 · Switch and room-token clear conditions — Completed — Accepted baseline

- Support hitting a named switch and collecting all room-local tokens, including combined objectives.
- Tokens respawn on exit/re-entry only while uncleared; clearing removes remaining tokens and prevents future spawns. They never enter currency or persistent reward ledgers.
- ALL composition; switch hits latch for the run, enemy progress lasts until deactivation, token progress lasts one visit. See the [clear-state contract](knowledge/clear-state.md).
- **Depends on:** CLEAR-01.

### CLEAR-08 · Clear effect: enemies do not respawn — Completed — Accepted baseline

- Optional template effect prevents enemy respawn after clearing, including after deactivation/reactivation.
- Clear state itself does not imply this effect; ordinary encounter reset behavior remains independent.
- **Depends on:** CLEAR-01.

### CLEAR-09 · Clear effect: permanent secondary root — Completed — Accepted baseline

- Clearing can make a node another root, permanently active and able to anchor connected branches.
- Promotion releases allocation, waives upstream support and protects the root from cascades. Root-effect nodes reject exclusive groups. The starting root is also created by an immediate clear effect.
- **Depends on:** CLEAR-01 and clear-effect handling.

### CLEAR-10 · Optional occupied-uncleared-room editing lock — Completed — Accepted baseline

- Templates can opt into `clear.block_tree_editing_until_cleared`; default is false. Gate build changes on the **occupied room's** clear state, not the target.
- Both model transaction previews and execution enforce the lock. Clearing immediately restores normal local rules. Travel and F2 content authoring remain available.
- **Depends on:** settable clear conditions/effects.

### CLEAR-11 · Fast-travel to roots — Completed — Accepted baseline

- Map selection exposes **Travel to root** for cleared, active roots, including disconnected earned roots.
- Any active source is allowed, including uncleared encounters and edit-locked rooms. Arrival uses authored spawn; HP/build unchanged; normal departure lifecycle applies.
- **Depends on:** CLEAR-09.

## Authoring quality of life

**EDITOR-01 — Completed and accepted.** The author accepted instance-owned
doors, canvas selection/history/direct manipulation, contextual node/room
properties, template navigation/copy, and switch-to-wall binding controls.
See the [closeout](archive/editor-01-closeout.md). This supersedes the narrower
JSON-focus-first implementation order below. Future flags and broader
interaction vocabulary require separate design rather than expansion by editor UI.

**Deferred from this change:** per-enemy damage authoring and runtime support
(current contact damage is not an authored enemy stat); playable room resizing
(LAYOUT-02); a general scoped/persistent variable-flag system. Existing
switch-to-wall bindings are sufficient for the first editor UX pass.

These generally follow gameplay experiments unless editing friction is preventing them. Preserve the portable content boundary: UI controls edit source JSON values and stable IDs, not runtime objects; unknown fields survive edits.

### EDIT-09 · Room geometry and door context — P2 — Explore

- **Observation:** The room editor's displayed bounds/grid extend beyond the
  playable interior and omit walls/instance doors, making placement harder.
- **Small comparison:** Investigate aligning the template editor's grid and
  boundaries to the actual playable interior; separately explore showing
  instance-door context while editing a template. Use the shared door resolver
  for the selected node instance, not a frontend approximation or
  template-global door layout.
- **Longer-term option, not an accepted direction:** Consider a combined
  instance/door/room editor or unique rooms instead of reusable templates.
  Compare against the smaller fix before changing the reusable-template
  boundary, portable content or existing bundles. Door placement is per
  instance; a reusable template can have multiple distinct door layouts.
- **Evaluate:** Can authors place objects relative to playable walls and the
  relevant doors without confusing template geometry with instance state?

### EDIT-10 · Multi-select and move tree nodes — P2 — Candidate

- **First slice:** Select multiple nodes and move them together as one deliberate
  gesture and one undo/redo transaction; preserve their relative positions.
- **Boundary:** Authored map positions can affect automatic doors. Show or
  otherwise make those consequences inspectable; preserve selection, pending
  JSON and source history semantics.
- **Evaluate:** Can an author rearrange a branch without individually moving
  every node or unintentionally changing doorway placement?

### EDIT-11 · Direct tree link creation — P2 — Candidate

- **First slice:** Compare selecting two nodes with a source-to-destination
  drag to create a link, avoiding manual ID entry.
- **Boundary:** Preserve explicit activation-direction semantics, door
  resolution, whole-document validation, undo/redo and stable IDs. Do not
  silently create an unsupported or unintended directional rule.
- **Evaluate:** Can authors connect the intended nodes and understand what
  direction, if any, they authored?

### EDIT-12 · Node Properties redesign — candidate

- **Goal:** Reduce visual clutter without hiding necessary authoring or
  compromising supported existing content.
- **Proposed layout:** Node Name first, Instance Preview below, Capacity Cost
  above Player stats, collapsible contribution sections initially collapsed,
  concise labels and tooltip explanations. Reduce routine clutter with
  contextual or advanced controls rather than removing recovery paths.
- **Boundary:** This is a proposal, not approval to remove recovery paths or
  silently migrate legacy content. Model selection is dungeon-level, and legacy
  bundles and ambiguous/unknown contributions need safe, discoverable access.
  Defining Unified new-project defaults, model selection and any migration or
  validation change requires separate Engine coordination and user decision;
  visual organization belongs to Frontend. Preserve stable IDs, drafts, invalid
  pending JSON blocking, validation and undo/redo.
- **Evaluate:** Can authors perform common edits quickly and still inspect,
  repair and preserve unusual or legacy data?

### EDIT-13 · Context-sensitive editor controls — candidate

- **Goal:** Simplify the top ribbon and present controls relevant to the current
  tree, room and selection context without hiding essential operations. Compare
  layouts before implementation and retain discoverable advanced/recovery paths.
- **Boundary:** Context is presentation, not a second content model or permission
  system. Preserve canvas gestures, instance-door context, validated transactions,
  pending JSON and history; see EDIT-09/10/11 for related authoring needs.
- **Evaluate:** Can authors find common actions and recover unusual content while
  switching contexts without unintended edits?

### EDIT-01 · Select a tree element to focus its JSON — Completed

- **First slice:** selecting a node or link focuses/highlights its JSON object with a clear way back to the full tree document. Apply edits to that identified element while retaining unrelated fields and pending text.
- **Evaluate:** can a larger graph be edited without searching through the full document or accidentally modifying the wrong node?
- **Depends on:** existing tree preview and inspector.
  The accepted panel goes beyond JSON focus while retaining JSON as the advanced
  view; see EDITOR-01.

### EDIT-02 · Select a room element to focus its JSON — Completed

- **First slice:** selecting an object or port focuses its JSON entry; show selection on the canvas and retain a full-template view. Handle overlapping objects deliberately.
- **Evaluate:** does this remove the main friction in changing dimensions, enemy stats, and pickup properties?
- **Depends on:** existing room preview and inspector; can share selection/inspector mechanics with EDIT-01.
  Accepted behavior includes typed object controls and direct rectangle resizing.

### EDIT-03 · Node template and ability selectors — Completed

- **First slice:** a selected tree node has dropdowns/lists for room template and granted abilities. Preserve JSON access for modifiers and experimental values. Allow multiple grants rather than assuming each node grants exactly one ability.
- **Boundary:** changing a template can invalidate linked ports and cross-room object references. Show those conflicts and let the author repair them; do not silently delete bindings or invent replacements. Existing unknown ability values must survive opening the selector.
- **Evaluate:** is assigning/reusing rooms appreciably faster without hiding the data model?
- **Depends on:** EDIT-01; a small supported-ability catalogue, not a new ability framework.

### EDIT-04 · Cross-room interaction indicators — Completed

- **First slice:** mark nodes containing switches or other cross-room endpoints; selecting one lists inbound/outbound bindings and identifies source and target objects.
- **Evaluate:** can an author locate and explain a remote wall interaction from the graph alone?
- **Depends on:** existing binding data; EDIT-01 helps navigation.

### EDIT-05 · Cross-room binding picker — Completed

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
| STAT-01 | P2 | **HP progression:** compare HP nodes against ability variants using current bonuses. | Are health nodes genuine build alternatives when allocations do not heal? | BUILD-01 max-HP-only rule; healing remains a separate future mechanic. |
| STAT-02 | P2 | **Speed progression:** one speed node and one traversal challenge. | Does speed change route/build choices beyond making walking faster? | Existing speed multiplier; compare with current sprint. |
| STAT-03 | P2 | **Vision / map reveal:** reveal inactive nodes up to an authored graph distance; one node increases it. | Is information valuable enough to allocate build resources to? | UI-01; specify graph-distance metric and whether previously discovered nodes remain visible after the bonus is lost. |
| STAT-04 | P3 | **Luck:** a seeded reward table and one modifier. | Can reward-oriented builds compete meaningfully with combat/traversal builds? | Reward/drop system; keep test progression solvable without lucky rolls, record seeds for comparison. |
| STAT-05 | P2 | **MP:** one resource pool and one ability consuming it. | Does a magic-resource branch add an interesting allocation decision or merely interrupt play? | AB-02 or AB-03 is a possible consumer; define recovery and behavior when max MP changes. |
| STAT-06 | P2 | **Stamina:** one pool, one consumer such as dash/block, one recovery rule. | Does a shared exertion budget create useful tradeoffs among abilities? | Existing dash or AB-01; test separately from MP first. |
| HAZ-01 | P2 | **Darkness:** one dark room and one illumination/vision benefit. | Can allocating perception alter how a room is explored? | A readable darkness representation; distinguish room visibility from STAT-03's map reveal. |
| HAZ-02 | P2 | **Pits:** one pit region and one defined crossing/recovery behavior. | Does traversal capability change which rooms/routes are attractive? | A movement solution and explicit fall/recovery rule; compare with existing water/flippers. |
| HAZ-03 | P2 | **Spikes:** one static or timed damage zone. | Can environmental timing make defensive/mobility choices relevant without extra enemy types? | Damage cooldown and clear visual feedback. |
| HAZ-04a | P2 | **Enemy locomotion:** skeleton/snake movement and flying/walking terrain policies, as described in the dungeon-enabling candidates. | Does a chosen movement pattern expose a useful build or spatial decision? | Explicit collision policies; test Guardian assumptions separately. |
| HAZ-04b | P2 | **New enemy attack behavior:** one telegraphed attacker, charger, or ranged enemy chosen to test one branch. | Does it expose a difference between builds that chasing bats cannot? | Pick the target build question first; avoid an enemy roster project. |
| LOOT-01 | Implemented | **Health pickups/chests:** restore HP up to the current maximum; not consumed at full health. | Does recovery placement support the intended dungeon pacing? | [Content contract](knowledge/content.md#health-pickups); dungeon playtesting. |
| LOOT-02 | P2 | **MP restoration:** one pickup restoring MP up to its maximum. | Does recovery placement make magic allocation and route choice interesting? | STAT-05. |
| LOOT-03 | P2 | **Temporary powerups:** one timed effect, such as speed, layered over the active build. | Does temporary power complement the skill tree or obscure which rooms grant the player's abilities? | Capability composition and an explicit expiry/stacking rule; test one effect. |
| LOOT-04 | P2 | **Enemy health drops:** one random drop from a defeated enemy. | Does recovery support exploration without making repeated encounters a farming loop? | LOOT-01; define randomness and drop lifecycle. |

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

The current, minimal experiment record and entry template live in the
[knowledge bundle](knowledge/experiments.md). Keep this backlog for proposed
work; record only evaluated outcomes in the knowledge bundle.

For each experiment:

1. Pick one hypothesis and a baseline scenario. Change one major rule at a time.
2. Define an observable success signal. Simple notes are enough; do not build telemetry infrastructure just to start.
3. Implement and check relevant behavioral invariants. Freeze presentation details only after the interaction proves useful.
4. Playtest, recording useful decisions separately from confusion, backtracking and authoring friction.
5. Decide **keep / revise / discard** and choose the next item from that evidence.

Suggested log entry (append to the [experiment record](knowledge/experiments.md)
or link a dedicated note):

```text
Item ID / date:
Status: Backlog | Selected | In progress | Ready to playtest | Evaluated | Completed
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

### Clearing — accepted baseline and hardening closeout

- **Status:** Completed — kept as the baseline.
- **Feedback:** user accepted the current functionality and requested hardening
  before selecting further work. CLEAR-03 through CLEAR-06 are potential future
  experiments.
- **Hardening:** reproduced and fixed stale deferred transitions crossing into a
  fresh playtest, editor pause bypass on arrival, door-travel validation/death
  races, and single-root initial-health validation.
- **Evidence:** [archived architectural review and red/green regression trace](archive/cleared-rooms-closeout.md#baseline-hardening);
  all 12 headless suites pass.
- **Next:** choose the next experiment separately. Presentation polish and new
  clear mechanics are not prerequisites for this checkpoint.

The following entries retain the history of the implementation slices; their
earlier “Ready to playtest” statuses are superseded by the closeout above.

### CLEAR-10/11 — root travel and optional editing lock

- **Status:** Ready to playtest.
- **Scope:** explicit map travel action, validated cleared/active-root targets;
  optional room-template editing lock enforced by progression and exposed in the
  clear-rules editor.
- **Fixture:** Token Clear in `cleared_rooms.json` locks editing until cleared.
  Escape to the initial root via map; earn the second root and travel to its
  disconnected branch after deactivating Token Clear.
- **Evidence:** [archived secondary-feature test trace](archive/cleared-rooms-closeout.md).
- **Evaluate:** whether combat escape via root travel and the optional editing
  lock produce useful encounter/build decisions.

### CLEAR-01/02/07/08/09 — authorable clear conditions and effects

- **Status:** Ready to playtest.
- **Implemented:** per-node clear state; ALL enemy/switch/token objectives; reveal
  collectible, no-respawn and permanent-root effects; immediate default-clear
  effects; root allocation release and independent connectivity.
- **Authoring:** Clear rules dialog, token brush, JSON declarations and a six-node
  `examples/cleared_rooms.json` fixture. Starting-root status uses the same effect.
- **Evidence:** [archived lifecycle, test trace and walkthrough](archive/cleared-rooms-closeout.md).
  Headless checks cover runtime events, persistence, reward eligibility, multi-root
  graph behavior, authoring validation and editor save/open/playtest.
- **Next:** foundation playtest was positively received; token spawning policy
  was revised, followed by CLEAR-10/11 above.

The entries below record successive slices; temporary controls described in earlier
entries were superseded by later slices. UI-01 is completed as a whole.

### UI-01 — slice 1: graph navigation

- **Status:** Evaluated — kept.
- **Question:** Are authored positions, graph connections, and a distinct player marker readable in the gameplay sidebar?
- **Scenario and baseline:** existing branching scenario; original node list retained in a temporary Actions tab.
- **Exact UI change:** Map tab renders authored positions, solid travel links and dashed prerequisite arrows. Click selects a node and shows its name/cost; wheel zooms around the pointer; right/middle drag pans; Fit graph resets framing. White selection ring and yellow YOU marker are separate.
- **Scope:** map state/action indicators and cascade previews follow in later slices. The Actions tab retains current activation/deactivation controls.
- **Playtest focus:** initial framing, label overlap, pan/zoom comfort, player orientation after travel, selection versus occupied-room clarity, and returning from editor/playtest.
- **Decision:** user confirmed functionality and useful pan/zoom; crowding motivated the responsive shell.
- **Next experiment:** connect map state indicators and selected-node actions to existing progression previews.

### UI-01 — intermediate slice: responsive gameplay shell

- **Status:** Evaluated — kept.
- **Feedback from slice 1:** graph interaction works; crowding remains, with pan/zoom useful. Add layout foundations before map actions.
- **Question:** Can players allocate enough space to the room and graph across window sizes?
- **Exact UI change:** anchored/container-based HUD, status and adjustable horizontal room/map split. Both panes start with equal allocation. Room rendering uses an independent 800×600 viewport scaled proportionally into its region. Minimum window size is 960×640; F11/header button toggles fullscreen.
- **Boundaries:** room geometry and movement coordinates remain fixed. The shell owns placement; the map owns its selection/view. Map resize currently refits the graph. Split settings are session-only; visual styling remains provisional.
- **Checks:** headless layout/input tests cover 960×640, 1280×720, 1920×1080 and 960×1000, adjustable allocation, attack/door input forwarding, and editor input isolation. Rendered windowed/fullscreen layouts were inspected.
- **Playtest focus:** divider usability, room/map proportions, fullscreen/window resize, map refitting, and combat/door controls after using the UI.
- **Decision:** user accepted proportions and verified fullscreen outside the embedded game panel.
- **Next experiment:** map state indicators and selected-node activation/deactivation, then cascade/requirement presentation.

### UI-01 — slice 2: map state and selected-node actions

- **Status:** Evaluated — kept.
- **Prior feedback:** responsive proportions are satisfactory for now; fullscreen works outside Godot's embedded game panel.
- **Exact UI change:** replace the temporary Actions tab with selected-node details and an explicit Activate/Deactivate button. Map badges distinguish active (✓), available (+), and blocked (×) nodes using symbols and color. Costs, selection ring, and occupied-room marker remain independent.
- **Rules:** indicators and action availability come from progression previews; transactions revalidate on execution. Active nodes remain marked active even when deactivation is unavailable. Selection never activates or travels.
- **Feedback:** selection shows unavailable reasons; state/action refresh follows allocations, refunds, rewards, room changes, and fresh playtests. The existing affected-room tooltip is retained.
- **Checks:** map integration tests cover click-versus-action, capacity/refunds, reward refresh, exclusive choices, remote/root protection, and playtest reset. Existing progression, shell and editor checks pass.
- **Friction / mitigation:** selected-node controls consume vertical map space; the adjustable split, fullscreen and pan/zoom remain useful. The reason text is provisional until richer prerequisite/cascade details are added.
- **Decision:** user accepted baseline functionality; control refinements deferred.
- **Next experiment:** cascade highlighting, refund previews, and clearer prerequisite details.

### UI-01 — room-entry framing experiment

- **Status:** Evaluated — kept.
- **Prior feedback:** baseline map states and actions work well; explore automatic orientation before continuing.
- **Exact UI change:** entering a room centers the occupied node and fits directly travel-linked neighbors, including inactive ones. Symmetric fitting keeps the player centered on one-sided branches; screen-space label margins are reserved. Selection is preserved.
- **Boundary:** only room entry requests this framing, including fresh runs and defeat returns. Rewards/allocations preserve manual navigation. Fit graph still shows everything; resizing retains neighborhood framing until manual navigation.
- **Tradeoff:** immediate reframing rather than animated movement; distant adjacent nodes can still require zooming out substantially.
- **Checks:** entry centering, neighbor visibility, preserved selection and manual camera after reward refresh.
- **Decision:** user liked and accepted framing; proceeded to consequence presentation.

### UI-01 — slice 3: consequences and prerequisites

- **Status:** Evaluated — kept.
- **Prior feedback:** room-entry framing is useful and should remain.
- **Exact UI change:** selecting an active node marks the selected removal and cascading removals with orange boxes. Details name the cascade, sum authored allocation costs for the refund, and show available points afterward. Rejected occupied-room cascades use red boxes and explicitly promise no changes/refund.
- **Prerequisites:** named ALL/ANY lists describe ongoing requirements and mark each room active/inactive. Exclusive groups list other active choices. Current local-interaction failure reasons remain visible.
- **Boundary:** previews come from progression; no speculative rule implementation in the renderer. Highlighting does not change selection or camera. The list exposes affected rooms even when they are outside the current map framing.
- **Friction / mitigation:** expanded details need scrolling; the panel is bounded and shrinks in short windows to preserve map space. Refund totals also appear on the action button.
- **Checks:** unequal-cost refunds, committed/preview agreement, side-effect-free inspection, blocked occupied-room cascades, ALL/ANY detail state, alternate-support survival, and clearing stale highlights. Existing map, responsive layout, progression, branching, content and editor suites pass.
- **Decision:** user confirmed each consequence is clear; UX polish deferred.
- **Next:** UI-01 completed. The recommended next gameplay experiment is CLEAR-01, subject to choosing its persistence policy and fixture.

### UI-01 — architectural closeout

- **Status:** Completed.
- **Hardening:** extracted a standalone snapshot-driven tree panel, retained coordinator/model transaction ownership, and corrected large-coordinate map fitting/wheel zoom.
- **Evidence:** accepted contracts are in the [UI contract](knowledge/ui.md); the red/green history is [archived](archive/ui-01-review-closeout.md).
- **Deferred:** visual polish, control redesign, map overlay/menu modes, warping and visibility experiments.
