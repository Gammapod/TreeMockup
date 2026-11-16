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

The next gameplay experiment is **BUILD-01 — stackable ability tradeoffs**,
selected below. **EDIT-01 — focus selected tree JSON** remains an authoring
candidate. Other candidate
questions live in the
[backlog](../backlog.md); that list is not an accepted-rule document.

# Required entry for a selected experiment

Selected experiments may record their agreed scope and planned checks before
implementation. Mark these as **selected** and leave observations pending;
selection is not evidence of successful gameplay. After playtesting, record:

```markdown
## <ID> — <name> (<YYYY-MM-DD>)
* **Status**: evaluated | accepted | revised | discarded
* **Question**: one player/design hypothesis.
* **Slice**: scenario and the one major rule/UI change.
* **Observation**: what playtesting or checks showed.
* **Decision**: keep, revise, or discard; link to changed invariant/architecture only if applicable.
* **Next**: one follow-up or `none`.
```

Do not log implementation chronology, unselected brainstorms, or every test run.
Use a dedicated scenario/feature note only when the entry cannot link to
existing content and needs reusable setup.

## UI-02 — walk-through border doors (2026-11-15)
* **Status**: accepted
* **Question**: Does continuous doorway movement make visiting and revisiting build branches feel more natural?
* **Slice**: `examples/branching.json`; linked ports open the fixed room border, and crossing an active opening transitions to the paired port.
* **Observation**: Walk-through doors were more intuitive than the prior deliberate door interaction.
* **Decision**: keep as the traversal baseline; blocked links remain visibly solid and arrivals suppress immediate bounce-back. See [UI contract](ui.md) and `tests/shell_tests.gd`.
* **Next**: EDIT-01.

## BUILD-01 — stackable ability tradeoffs (2026-11-15)

* **Status**: ready to playtest; implemented, player evaluation pending.
* **Question**: Do stackable, observable ability tradeoffs make players
  deliberately allocate and refund dungeon nodes to suit their preferred play
  style and the encounter?
* **Hypothesis**: Shaping an attack or movement action creates more meaningful
  allocation decisions than choosing among mutually exclusive presets.
* **Slice**: Implement the ability vocabulary below, then build a small
  allocation test arena. Start the arena with Thrust and Sweep rather than
  testing every modifier simultaneously.
* **Observation**: Player feedback pending; automated checks are not evidence
  that the tradeoffs are enjoyable.
* **Decision**: Scope selected by the user; tuning values are starting points,
  not accepted balance or validated gameplay.

### Ability vocabulary

Numeric modifiers multiply consistently across active nodes. Display resulting
stats rather than requiring players to calculate stacked percentages. Start
with at most two copies of each stackable sword/dash modifier in test content.
Behavioral modifiers are single upgrades rather than numeric stacks.

#### Sword

Expose **reach**, **arc**, **damage per enemy struck**, and **attack interval**
(time between starting successive attacks). Reach controls forward extent;
arc controls angular coverage. Do not add an overlapping "range size" stat.
Keep startup and active hit-window timing fixed for this first experiment.

| Upgrade | Benefit | Tradeoff | Intended use |
| --- | --- | --- | --- |
| Thrust | Reach ×1.3 | Arc ×0.7 | Pick off isolated targets from farther away; reduced crowd coverage. |
| Sweep | Arc ×1.5 | Damage ×0.75 | Cover groups; less damage against durable targets. |
| Quick Cut | Attack interval ×0.75 | Reach ×0.8 | Frequent close-range attacks at greater positional risk. |

Two Thrust nodes yield reach ×1.69 and arc ×0.49. Provide an attack-footprint
preview alongside final numeric stats. Choose base damage/enemy HP and numeric
precision so penalties remain meaningful; inspect hits-to-kill rather than
relying only on displayed damage or theoretical damage per second.

**Separate follow-up candidate:** Heavy Strike (damage ×2, attack interval ×2),
as a single impact rather than a multi-hit combo. It is not required for the
initial implementation or arena; revisit only if the initial modifiers do not
produce useful choices.

#### Dash

Expose **distance** and **recharge time**. Keep dash speed fixed initially, so
changing distance also changes duration.

| Upgrade | Benefit | Tradeoff | Stacking |
| --- | --- | --- | --- |
| Long Dash | Distance ×1.4 | Recharge ×1.4 | Numeric; up to two copies in test content. |
| Quick Step | Recharge ×0.7 | Distance ×0.75 | Numeric; up to two copies in test content. |
| Phase Dash | Immunity to enemy contact during the dash | Distance ×0.65 | Single behavioral upgrade. |

Enemy interaction is a named behavior, not a numerical 0/1/2 ladder. Phase
Dash does not imply wall passage, water crossing, damage to enemies, or
immunity to a future shockwave. Damaging dash and wall passage are deferred.
This proposed Phase Dash distance replaces the existing half-distance tuning
when the new ability system is implemented.

#### HP

HP upgrades remain stackable, with allocation cost as their tradeoff.
**They increase maximum HP without increasing current HP.** Removing an
upgrade clamps current HP to the new maximum if necessary; refunding and
reactivating cannot heal. Healing is a separate future mechanic. This is a
selected change from the current runtime's max-HP increase behavior.

Provide adequate baseline health for encounter learning. Use consistent
starting health for fresh arena trials; retry/reset initialization is separate
from an upgrade granting health.

#### Flippers

Retain the existing binary water-traversal ability. Swim endurance, exhaustion,
rescue, and graded swimming upgrades are outside this experiment.

### Initial test arena

* Provide the base sword and four upgrade nodes: two Thrust and two Sweep.
* Make each upgrade cost one point, with only two points available for upgrades
  after accounting for required base/route allocations.
* Ensure both matching pairs and a mixed pair are reachable and supportable;
  topology must not accidentally force one combination.
* Offer a crowd encounter and a durable-target encounter, with a safe place to
  refund/reallocate between attempts.
* Let players compare base sword, one upgrade, two matching upgrades, and a
  mixed pair. Do not require spending every available point.
* Display resulting reach, arc, damage, and attack interval, with a footprint
  preview. Make each node's benefit and penalty visible before activation.
* Tune target HP so Sweep's damage cost is observable, particularly against
  the durable target. Tune spacing so Thrust's narrower coverage matters.
* Keep starting conditions consistent across fresh trials. Do not add healing
  mechanics merely to support this arena.
* Implement the agreed dash/Quick Cut vocabulary, but evaluate it in follow-up
  arena configurations after the initial Thrust/Sweep comparison. Keep binary
  Flippers and HP available as system capabilities, not mandatory arena choices.

### Planned checks and feedback

Implementation checks should cover modifier composition and refund reversal,
actual attack geometry/timing, dash distance/recharge and contact immunity,
and HP allocation without healing.

During playtesting, observe:

1. Can players predict what each upgrade changes?
2. Do they notice its drawback while playing?
3. Do they choose matching upgrades, a mixed pair, or leave points unspent?
4. Does changing the encounter prompt voluntary reconsideration?
5. Is switching an interesting preference/tradeoff, or an obvious prescribed
   answer?

**Success signal:** "I prefer this shape of attack, but this room makes me
consider changing it." Record confusion separately from build preferences.

### Sequence and decision gates

1. Implement abilities and create the small arena.
2. Playtest; keep, revise, or discard tradeoffs based on observed choices.
3. If enjoyable, design and test the boss encounter using the validated builds.
   A telegraphed shockwave and periodic small bat group are the initial boss
   candidates, not part of this implementation slice.
4. If the boss supports meaningful build reconsideration, design the larger
   14–18-node dungeon, with at most two roots.

* **Playable slice**: `examples/build_arena.json`; launch from the header's
  **BUILD-01 arena** button, F2 content editor, or `-- --arena`. A trial restart
  retains allocations while resetting encounters, clear state, position and HP.
  The arena grants base sword damage 8, five crowd bats at 4 HP each, and one
  durable bat at 24 HP; zero/one/two Sweeps require 3/4/6 hits on that target.
* **Verification trace**: B4/H1 → `tests/build_tests.gd`; changed legacy HP and
  Phase rules → `tests/branching_tests.gd`; B5 → `tests/arena_tests.gd`.
  The HP tests failed on activation healing before implementation; ability
  tests first failed on unsupported modifier vocabulary, the movement check
  exposed truncated dash distance, and the arena check failed on missing
  content. These checks now pass; rendered review covers normal/minimum window
  sizes. See the [content contract](content.md#build-01-modifier-authoring)
  for authored modifiers, base values, and timing/arc bounds.
* **Next**: Playtest Thrust/Sweep; use feedback before adding further arena
  configurations or the boss.
