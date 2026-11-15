---
type: Experiment Record
title: V2 gameplay experiments
description: Accepted gameplay baselines and the minimal record for the next experiment.
tags: [v2, design, experiments, level-design]
status: stable
generated: { by: "openai/gpt-5.6-terra", at: 2026-11-15T00:00:00Z }
sources:
  - { resource: ../backlog.md, title: V2 experiment backlog }
  - { resource: branching-scenario.md, title: Branching scenario design }
  - { resource: clear-state.md, title: Clear-state contract }
---

# Current baseline

| Baseline | Scenario | Decision |
| --- | --- | --- |
| Dungeon/skill-tree map (UI-01) | `examples/branching.json` | Kept; functional clarity accepted, visual polish deferred. |
| Walk-through border doors (UI-02) | `examples/branching.json` | Kept; continuous traversal accepted as the baseline. |
| Clear conditions/effects | `examples/cleared_rooms.json` | Kept; clear state, rewards, roots, editing lock, and root travel are accepted. |
| Branching build choices | `examples/branching.json` | Regression scenario for local allocation, styles, prerequisites, and merge behavior. |

The next experiment is **EDIT-01 — focus selected tree JSON**. Candidate
questions live in the
[backlog](../backlog.md); that list is not an accepted-rule document.

# Required entry for a selected experiment

Append one short entry below only after an experiment produces evidence:

```markdown
## <ID> — <name> (<YYYY-MM-DD>)
* **Status**: evaluated | accepted | revised | discarded
* **Question**: one player/design hypothesis.
* **Slice**: scenario and the one major rule/UI change.
* **Observation**: what playtesting or checks showed.
* **Decision**: keep, revise, or discard; link to changed invariant/architecture only if applicable.
* **Next**: one follow-up or `none`.
```

Do not log implementation chronology, unplayed ideas, or every test run.
Use a dedicated scenario/feature note only when the entry cannot link to
existing content and needs reusable setup.

## UI-02 — walk-through border doors (2026-11-15)
* **Status**: accepted
* **Question**: Does continuous doorway movement make visiting and revisiting build branches feel more natural?
* **Slice**: `examples/branching.json`; linked ports open the fixed room border, and crossing an active opening transitions to the paired port.
* **Observation**: Walk-through doors were more intuitive than the prior deliberate door interaction.
* **Decision**: keep as the traversal baseline; blocked links remain visibly solid and arrivals suppress immediate bounce-back. See [UI contract](ui.md) and `tests/shell_tests.gd`.
* **Next**: EDIT-01.
