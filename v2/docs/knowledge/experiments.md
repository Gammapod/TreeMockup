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
| Clear conditions/effects | `examples/cleared_rooms.json` | Kept; clear state, rewards, roots, editing lock, and root travel are accepted. |
| Branching build choices | `examples/branching.json` | Regression scenario for local allocation, styles, prerequisites, and merge behavior. |

The next experiment is **not selected**. Candidate questions live in the
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
