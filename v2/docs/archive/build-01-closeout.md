# BUILD-01 closeout — 2026-11-15

**Completed; user accepted the expanded arena as a baseline.**
Current rules live in the [knowledge bundle](../knowledge/index.md);
this document records the architectural review and verification evidence.

## Accepted scope

* Multiplicative sword/dash tradeoffs, fractional damage, captured actions,
  numeric readouts and an attack-footprint preview.
* HP upgrades affect maximum health only; Flippers remain binary.
* The initial two-point Thrust/Sweep fixture expanded at the user's request
  into six four-node chains, standalone Phase Dash, eight points, and free
  crowd/durable-target trials: 28 nodes total.
* Arena-only base arc/interval tuning keeps all four Sweep/Quick Cut copies
  useful. The planned dungeon remains a separate 14–18-node design.
* Fresh trials restore the retained build and full build health, reset
  encounter/clear state, and return to the root.

User acceptance establishes a reusable baseline, not final balance or evidence
that a boss already induces meaningful respec decisions.

## Architectural review

| Boundary | Finding / decision |
| --- | --- |
| Authored content → adapter | Numeric vocabulary is validated and compiled from portable JSON. Arena topology, costs and base tuning remain authored data; no new content format is needed. |
| Progression → capabilities | Allocation/support/refunds and deterministic stat composition remain in `progression.gd`. Additive damage precedes multipliers; clamping happens after composition. |
| Capabilities → actions | `player.gd` captures action parameters and owns timing, motion and current HP. `room.gd` owns sector/body intersection, wall occlusion and enemy damage. Neither inspects the allocation graph. |
| Views → mutations | Tree/shell controls emit intent; the coordinator/model remain authoritative. Readouts and the footprint consume derived or captured values. |
| Arena restart → run lifecycle | Restart uses the generation-guarded deferred transition path and restores allocations through model activation before initializing health. Explicit Playtest and fresh-run initialization now have separate responsibilities. |
| Compatibility | Legacy big/fast sword and run fixtures remain supported. The selected HP no-healing and Phase distance changes apply to them; current docs/tests reflect that. |

### Resolved finding: deferred restart could exit authoring

Requesting trial restart and opening F2 before the deferred callback caused the
restart to call `_play_document`, which unconditionally closed the editor.
This violated existing L1: authoring must keep loaded gameplay paused.

`tests/arena_tests.gd` reproduced the failure before the fix. `_start_run`
now initializes runtime state without changing editor visibility;
`_play_document` alone exits authoring for explicit Playtest/launch intent.
The arena regression also checks that a stale trial callback cannot reset a
newer run.

### Bounded prototype decisions

* The `build_arena` scenario ID enables its launch/reset UI and instructions.
  Reset replay relies on this fixture's rooted, sequential, reward-free
  branches and the active set's allocation order. It is not a general save/load
  or arbitrary-graph build restoration API.
* Timing floors are represented in both capability derivation and action
  execution. They currently agree and are tested; a shared timing definition
  becomes useful if another action type or independently configurable startup
  is introduced.
* Numeric labels and the footprint are sufficient baseline presentation.
  A generalized ability registry, modifier editor, or UI overhaul is not
  required to close this experiment.

**Disposition:** no remaining blocking findings within the accepted scope.

## Verification

* B4/H1 → `tests/build_tests.gd`: composition/refunds, fractional damage,
  geometry, actual attack intervals/dash distance, captured actions and no
  healing from max-HP allocation.
* B5 → `tests/arena_tests.gd`: all pairs of fully allocated branches, capacity,
  prerequisites, cascade refunds, four useful stack levels, retained deep
  builds and full build HP on fresh trials.
* Legacy behavior/H1 → `tests/branching_tests.gd`.
* L1 → `tests/arena_tests.gd` plus existing editor/hardening suites.
* Earlier red phases exposed unsupported modifiers, activation healing,
  truncated dash movement, lost deep allocations on restart and a saturated
  fourth Quick Cut. The closeout red phase reproduced the editor-pause defect.
* All 14 headless suites pass after the closeout fix. Prior rendered checks
  covered the arena at normal and minimum window sizes.

## Next

Define a small boss encounter using these abilities, then evaluate build
reconsideration before designing the larger dungeon. A telegraphed shockwave
and periodic small bat group remain design candidates, not implemented scope.
