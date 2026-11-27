# V2 experiment backlog

**Goal:** Find which game elements work well with “the dungeon is also a skill
tree.” V2 is an experimental testbed, not a production milestone list.

## How to use this backlog

* **Previously:** Briefly summarize the latest completed or evaluated work.
  Before replacing this summary, move durable rules, evidence and decisions to
  the [knowledge bundle](knowledge/index.md) or
  [experiment record](knowledge/experiments.md).
* **Now:** A small set of highest-priority work, ideally serving one outcome.
* **Next:** Important work genuinely blocked by Now; name its dependency.
* **Later:** Other candidates, including important work that is independent
  but not currently selected.

Implementation is not acceptance: keep work awaiting a user playtest or a
keep/revise/discard decision visible as such. Select a small hypothesis, retain
appropriate baselines, and distinguish technical checks from player feedback.
Experimental level design is not gated on deterministic solvability tests.
Proposals do not change accepted gameplay rules.

## Previously

The user accepted the gameplay and editor presentation revisions as a good
baseline: important feedback is present, with individual tweaks possible
later. See the [experiment record](knowledge/experiments.md#gameplay-presentation-and-editor-layout-2026-11-26)
and [UI contract](knowledge/ui.md).

## Now

### Sword Branch · Develop distinctive rooms and encounters

The user confirmed the current abilities and connections; room layouts, enemy
behavior, tuning and rewards remain open. Continue in
[`examples/unified_tutorial_boots.json`](../examples/unified_tutorial_boots.json)
using the [design graph](../examples/scenario-designs/Test_Dungeon.mmd) and
[candidate notes](../examples/scenario-designs/unified-tutorial-boots-candidate.md).

* Develop distinctive rooms and encounters for Spear, Heavy, Sword Landing and
  Strength Up. Pick enemy behavior to expose a particular build choice; retain
  Spear/Heavy/neither paths. Tune rewards through play.
* Decide whether both exclusive-route capacity rewards should remain collectible
  after reallocation.
* **Decision:** User playtests and chooses what to keep/revise; no deterministic
  level-design validation gate.

## Next

### Midpoint prerequisites and mini-boss

**Blocked by:** choosing which rooms in the developing Sword and Boots
branches should gate the midpoint.

Finalize those room choices, then implement the requested cleared-room
prerequisite feature: current ALL/ANY prerequisites check active nodes only.
Keep active versus persistent clear as separate conditions, and define scope,
previews, execution and root behavior before implementation.

Replace the cost-1000 visual placeholder with a designed mini-boss enemy and
arena; clearing it should grant the second permanent root, with at most two
roots in the dungeon. Encounter behavior is not yet selected. Encounter design
can be explored independently; integrating its intended gate depends on the
room choices and prerequisite feature.

## Later

### Dungeon: further connections and capstone

The target remains a shareable interconnected **14–18-node** dungeon.
* **Connected puzzle:** Offer a required ability through mutually exclusive
  routes and a multi-room ability/refund/reallocation puzzle with persistent
  world changes. Consider budgets, local activation and return routes together.
* **Final Guardian:** Connect the accepted capstone and evaluate the final
  tradeoff between navigation and combat allocation. Tune against dungeon
  builds and assess recovery/pacing through user playtesting.

Desired moments also include an early obstacle with multiple skill solutions,
specialized challenges, and individual upgrades with rewarding combinations.
Prefer automatic doors except where obstacle relationships require a manual
placement. Gold may stand in for undecided rewards.

### UI and editor follow-ups

* **UI-03 · Individual presentation refinements:** The current UX is an
  accepted baseline. Revisit enemy-type/danger differentiation, practical
  scale and accessibility, pre-strike or occlusion feedback only when a
  concrete need arises. Any new gameplay facts must come from an agreed Engine
  snapshot or event, not frontend inference.
* **EDIT-12 · Node Properties redesign:** Conduct a focused design pass. The
  user's ideas include name, instance preview and cost near the top; initially
  collapsed contributions; concise labels/tooltips; and reduced advanced
  clutter. Preserve discoverable JSON/individual-entry recovery, unknown
  values, stable IDs, drafts, validation and undo/redo. Defaulting new projects
  to Unified or hiding the model selector needs a separate Engine contract and
  user decision; do not silently migrate legacy content.
* **EDIT-13 · Context-sensitive editor controls:** Simplify the ribbon and
  compare context-sensitive layouts without hiding essential operations or
  turning presentation into a second content model.
* **EDIT-09 · Room geometry and doors:** Compare aligning the grid/bounds with
  the playable interior against an instance-aware room/door view. Reusable
  templates can have multiple door layouts; use the shared resolver. Replacing
  reusable templates or combining editors is a long-term possibility, not an
  accepted content change.
* **EDIT-10 · Move multiple tree nodes:** Select and drag a group while
  preserving relative positions, pending JSON and one undo record per gesture.
  Map position changes can move automatic doors; make consequences inspectable.
* **EDIT-11 · Direct link creation:** Compare selecting two nodes with a
  source-to-destination drag instead of typing IDs. Preserve link direction,
  stable IDs, shared door resolution, validation and undo/redo.
* **EDIT-06 · Capacity budget HUD:** Summarize starting and potential authored
  capacity across node instances, including pickups and chests. Clearly
  distinguish potential from collectible/reachable; this is not a solver.
* **EDIT-07 · Progression analysis:** Park research into reachability or
  funding analysis until a specific question and useful evidence exist. Any
  analysis must explain assumptions and report unknown rather than claim a
  guarantee it cannot establish. The user does not want deterministic
  level-design validation to gate current dungeon iteration.
* **EDIT-08 · Grid/tile painting:** Revisit only if repeated evidence shows
  geometry authoring is the bottleneck. Decide whether a grid is an editor
  convenience or a versioned engine-visible representation.

### Gameplay candidates

Choose by a concrete room/build question rather than building the catalogue.

| ID | Candidate | Question or dependency |
| --- | --- | --- |
| AB-01 | Directional shield | Compare a readable defensive option with HP or mobility. |
| AB-02 | Ranged attack | Does distance and wall geometry make a projectile branch valuable? |
| AB-03 | Delayed bomb and breakable obstacle | Connect combat and routes; decide reusable versus consumable supply. |
| STAT-01 | HP progression | Compare HP with ability variants; maximum-HP allocation does not heal. |
| STAT-02 | Speed progression | Compare speed with existing traversal options in a specific room. |
| STAT-03 | Map vision/reveal | Define graph distance and whether discoveries persist after refund. |
| STAT-04 | Luck and seeded rewards | Keep baseline progression solvable without lucky drops. |
| STAT-05 | MP | Define one ability consumer, recovery and maximum-change behavior. |
| STAT-06 | Stamina | Test one shared exertion pool and recovery rule separately from MP. |
| HAZ-01 | Darkness | Distinguish room visibility from map discovery. |
| HAZ-02 | Pits | Define crossing, fall and recovery; compare with water. |
| HAZ-03 | Spikes | Define timing, damage cooldown and readable feedback. |
| HAZ-04a | Enemy locomotion | Explore cardinal semi-random skeletons and axis-bouncing snakes; define flying/walking obstacle and water interactions. Revisit Guardian geometry separately. |
| HAZ-04b | Enemy attacks | Choose one telegraphed attacker, charger or ranged enemy to test a particular build. |
| LOOT-02 | MP restoration | Depends on an MP experiment. |
| LOOT-03 | Temporary powerup | Define expiry and stacking with the active build. |
| LOOT-04 | Random health drops | Define probability, reproducibility, lifetime, respawn and farming behavior; fixed healing pickups already exist. |

**Sword/terrain question:** A trapped enemy in Room 7 was proposed as a long
sword *or* Flippers solution. Current hit checks without Flippers are blocked by
water. Decide on geometry or mechanics only if this solution is needed.

**Water refund/clipping:** The user observed that refunding Flippers in water
pushes the player to an edge; a player can become stuck against another
obstacle. General clipping prevention is explicitly deferred for the current
shareable-dungeon goal.

### Deferred clear-state experiments

* **CLEAR-03 · Persistent door lock:** A button unlocks an authored door while
  destination activation remains separate. Define direction, reachability and
  escape; current switch-to-wall bindings toggle rather than permanently latch.
* **CLEAR-04 · Deactivate uncleared rooms on retreat:** Define explicit retreat
  edges and forward/death/cascade behavior for a small comparison. Preserve
  occupied-room safety and prevent reward farming.
* **CLEAR-05 · Remote reconfiguration of cleared rooms:** Define how activation
  direction works without a local source and whether cascades may remove
  uncleared dependents.
* **CLEAR-06 · Warp to cleared active rooms:** Define source/combat eligibility,
  safe arrival and active-room invariant; compare with ordinary traversal.

### Layout research

* **LAYOUT-01 · Suggest layout:** Explore explainable, author-reviewed map
  placement before assuming graphs can be packed into physical spaces.
* **LAYOUT-02 · Variable room dimensions:** The adapter currently restricts
  playtests to 800×600. Generalize only for a concrete scenario that benefits
  from small/large rooms.

### Other deferred work

Per-enemy damage authoring/runtime support, a general persistent variable-flag
system and a permanent non-toggleable switch are separate possible designs, not
requirements for the current editor or dungeon slice.
