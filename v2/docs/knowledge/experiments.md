---
type: Experiment Record
title: V2 gameplay experiments
description: Accepted gameplay baselines and the minimal record for future experiments.
tags: [v2, design, experiments, level-design]
status: stable
generated: { by: "openai/gpt-6-astra", at: 2026-11-16T00:00:00Z }
sources:
  - { resource: ../backlog.md, title: Experiment candidates }
  - { resource: content.md, title: Ability vocabulary and tuning }
  - { resource: ../archive/build-01-closeout.md, title: BUILD-01 review and closeout }
  - { resource: ../archive/boss-01-closeout.md, title: BOSS-01 review and closeout }
---

# Current baseline

| Baseline | Scenario | Decision |
| --- | --- | --- |
| Dungeon/skill-tree map (UI-01) | `examples/branching.json` | Kept; functional clarity accepted, visual polish deferred. |
| Walk-through border doors (UI-02) | `examples/branching.json` | Kept; continuous traversal accepted. |
| Clear conditions/effects | `examples/cleared_rooms.json` | Kept; clearing, roots, editing locks and root travel accepted. |
| Branching build choices | `examples/branching.json` | Regression fixture for allocation, prerequisites, exclusivity and merges. |
| Stackable ability tradeoffs (BUILD-01) | `examples/build_arena.json` | Completed; user accepted the expanded workshop as a baseline. |
| Roost Guardian capstone (BOSS-01) | Boss Trial in `examples/build_arena.json` | Completed; accepted for larger-dungeon design, tuning/polish deferred. |

**Current design target:** the interconnected 14–18-node dungeon, using the
accepted abilities and boss capstone. The user has begun work in
`examples/Test_Dungeon.json`; `examples/unified_tutorial_boots.json` is the
opening/Boots/Sword candidate under continued design.
The grouped unified contribution editor is implemented; other candidates live
in the [backlog](../backlog.md).

# Recording an experiment

Selected experiments may record agreed scope and planned checks before
implementation. Mark them **selected** and leave observations pending.
After evaluation, use:

```markdown
## <ID> — <name> (<YYYY-MM-DD>)
* **Status**: evaluated | completed (accepted) | revised | discarded
* **Question**: one player/design hypothesis.
* **Slice**: scenario and the major rule/UI change.
* **Observation**: user feedback or observed behavior, distinct from automated evidence.
* **Decision**: keep, revise, or discard; link to current contracts.
* **Next**: one follow-up or `none`.
```

Keep this record short. Runtime rules belong in contracts, play instructions
in the README, future ideas in the backlog, and review/red-green history in
archived closeouts. Do not retain implementation diaries or duplicate tuning
tables here.

## Presentation icon set (2026-11-26)
* **Status**: evaluated; standalone asset set kept.
* **Question**: Are simple standard symbols a useful visual vocabulary for future gameplay presentation?
* **Slice**: Sword, boots, health, gold, capacity, token and neutral icons, reviewed at multiple sizes on light and dark backgrounds.
* **Observation**: The user reviewed the set and said it was good.
* **Decision**: keep the standalone set; this does not imply acceptance of any later map or room integration.
* **Next**: use explicit supported semantics and evaluate each integration separately.

## Gameplay presentation and editor layout (2026-11-26)
* **Status**: evaluated; revisions in progress.
* **Question**: Do the new gameplay cues and contextual editor layout communicate clearly without unnecessary text?
* **Slice**: Avatar cooldowns and sword sector, room labels and collectible cues, icon-led map, and contextual editor.
* **Observation**: The user liked cooldowns, water/wall labels, the default map icon and the cleaner editor layout. They requested same-radius cooldown hemispheres, no unavailable indicators, graphic enemy danger without behavior labels, no sword-sector text, and collectible icons in place of the old circles. Space after selecting a tree node caused unintended allocation changes. They want a later focused Node Properties pass.
* **Decision**: keep the successful directions and revise the identified cues and input conflict; visual acceptance of the revisions remains pending.
* **Next**: verify the revisions and collect user feedback; defer the deeper Node Properties exploration.

## Movement restriction anchor (2026-11-26)
* **Status**: evaluated; kept.
* **Question**: Can an avatar-local cue communicate an ordinary movement restriction without a text countdown?
* **Slice**: A shared tether appears during supplied sword or dash movement restrictions; routine Phase text is removed while blocked-destination feedback remains.
* **Observation**: The user playtested the result and said they were happy with it.
* **Decision**: keep the anchor direction. It indicates ordinary movement restriction, not a general action lock.
* **Next**: architectural review and checkpoint.

## Unified abilities — Phase Dash lab (2026-11-23)
* **Status**: evaluated; further dungeon testing remains open.
* **Question**: Does a teleport-like dash, with optional rooted recharge, match the intended movement tradeoff?
* **Slice**: `examples/phase_dash_lab.json` compares normal Dash, Phase teleport and water passage using the unified contribution model.
* **Observation**: The user reported that Phase Dash behaved exactly as intended, both with and without rooted recharge. They suggested timing could be a little faster but is fine for now.
* **Decision**: keep the Phase direction for continued dungeon development; leave timing adjustment for later testing. See `examples/scenario-designs/unified-abilities-proposal.md`.
* **Next**: use the unified contribution editor for dungeon design and evaluate Phase in actual branch encounters.

## Unified tutorial + Boots Branch (2026-11-24)
* **Status**: evaluated; revised candidate, not a completed dungeon.
* **Question**: Do the tutorial and first movement branch provide a coherent physical skill-tree foundation?
* **Slice**: `examples/unified_tutorial_boots.json`; tutorial, two mutually exclusive movement options, shortcut and optional endpoints.
* **Observation**: The user said the abilities and connectedness match the design, liked Start's pillars and Key Storage's lessons, and considered Sword and the movement trial encounters placeholders. They revised map/door placement and added water around the Flippers route. Refunding Flippers in water pushed the player to an edge; they noted possible trapping against another obstacle and deferred a general clipping solution.
* **Decision**: keep developing the candidate; prefer automatic doors except where an obstacle demands a specific placement. The user-created miniboss is a visual placeholder, not an implemented encounter.
* **Next**: develop placeholder room content and evaluate future presentation/authoring candidates as needed.

## Unified Sword Branch extension (2026-11-25)
* **Status**: evaluated for abilities and connectivity; encounters and layouts remain provisional.
* **Question**: Does the candidate express the intended Spear/Heavy/neither branch and its shared landing?
* **Slice**: Added Spear, Heavy, Sword Landing and Strength Up to `examples/unified_tutorial_boots.json`; encounters, values and rewards are placeholders.
* **Observation**: The user confirmed that the abilities and connections are correct.
* **Decision**: continue developing the branch; no conclusion about enemy behavior, balance or room layout is implied.
* **Next**: flesh out distinctive encounters and rooms, then finalize the mini-boss's prerequisite nodes and implement cleared-room prerequisites and the encounter.

## Unified contribution editor (2026-11-23)
* **Status**: implemented; grouped table positively reviewed, collapse controls implemented.
* **Question**: Can authors express unified qualities and stat contributions without editing source JSON for routine changes?
* **Slice**: Node properties group Player, Sword and Dash contributions in a table with collapsible sections, while preserving an individual-entry/JSON path for ambiguous or fractional entries.
* **Observation**: The user said the table was good and requested collapsible sections; no separate visual assessment of those controls is recorded.
* **Decision**: keep the functional milestone; see the [UI contract](ui.md).
* **Next**: apply it to the prototype dungeon; evaluate remaining authoring friction as it arises.

## UI-02 — walk-through border doors (2026-11-15)
* **Status**: completed (accepted).
* **Question**: Does continuous doorway movement make visiting and revisiting build branches feel more natural?
* **Slice**: `examples/branching.json`; linked ports open the room border and crossing an active opening transitions to its paired entrance.
* **Observation**: The user found walk-through doors more intuitive than deliberate door interaction.
* **Decision**: keep; see the [UI contract](ui.md) and `tests/frontend/shell_tests.gd`.
* **Next**: authoring improvements remained candidates; BUILD-01 subsequently became the gameplay focus.

## BUILD-01 — stackable ability tradeoffs (2026-11-15)
* **Status**: completed (accepted baseline).
* **Question**: Do visible, stackable ability tradeoffs provide a useful basis for dungeon allocation and build experimentation?
* **Slice**: Started with a two-point Thrust/Sweep comparison; expanded to six four-deep upgrade chains, standalone Phase Dash, eight points, and two free combat trials. Max-HP upgrades no longer heal. Trial restart retains the build and initializes fresh encounters and full build HP.
* **Observation**: The user requested the broader build space, then called it a good baseline and explicitly requested completion. Encounter balance and boss-driven respec decisions remain future evaluation.
* **Decision**: keep the 28-node workshop and implemented abilities. [Content contract](content.md#build-01-modifier-authoring) owns stats/tuning; [invariants](invariants.md) own B4/H1/B5 and lifecycle test traces; [README](../../README.md#build-01-stackable-ability-arena) owns play instructions.
* **Review**: [Architectural closeout](../archive/build-01-closeout.md). One deferred-restart/editor-pause defect was reproduced and fixed; no remaining blocking findings within BUILD-01 scope.
* **Next**: define the smallest boss encounter that makes multiple builds and movement choices relevant.

## BOSS-01 — tethered Roost Guardian (2026-11-15)
* **Status**: completed (accepted capstone baseline, 2026-11-16).
* **Question**: Does a readable boss cycle prompt useful changes between the accepted sword/movement builds?
* **Slice**: Free Boss Trial adds a tethered, always-vulnerable guardian with pressure, locked shockwave telegraph, gapped wave, contact-safe recovery and capped bat summons. The workshop now has 29 nodes; build-preserving trial restart also resets this encounter.
* **Observation**: The user accepted the fight as a good capstone to design the larger dungeon around, while explicitly leaving tweaking/polish for later. Final balance and dungeon-induced respec decisions remain to be evaluated.
* **Decision**: keep the encounter and ownership boundaries. [Content contract](content.md#boss-01-enemy-behavior) owns the preset's scope; [README](../../README.md#boss-01-roost-guardian-trial) owns current timings/play instructions; E1/E2 in [invariants](invariants.md) link to the tests.
* **Review**: [Architectural closeout](../archive/boss-01-closeout.md). No blocking findings for the current fixture; geometry assumptions and future extraction points are recorded there.
* **Next**: design the 14–18-node dungeon around this capstone.
