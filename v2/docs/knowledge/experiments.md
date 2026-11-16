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

**Next design target:** the interconnected 14–18-node dungeon, using the
accepted abilities and boss capstone. Concrete layout and implementation scope
remain to be designed.
Other candidates, including EDIT-01, live in the [backlog](../backlog.md).

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

## UI-02 — walk-through border doors (2026-11-15)
* **Status**: completed (accepted).
* **Question**: Does continuous doorway movement make visiting and revisiting build branches feel more natural?
* **Slice**: `examples/branching.json`; linked ports open the room border and crossing an active opening transitions to its paired entrance.
* **Observation**: The user found walk-through doors more intuitive than deliberate door interaction.
* **Decision**: keep; see the [UI contract](ui.md) and `tests/shell_tests.gd`.
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
