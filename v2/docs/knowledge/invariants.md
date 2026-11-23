---
type: Contract
title: V2 functional invariants
description: Stable player-visible rules with the tests that characterize them.
tags: [v2, invariants, tests, gameplay]
status: stable
generated: { by: "openai/gpt-5.6-terra", at: 2026-11-15T00:00:00Z }
sources:
  - { resource: ../../tests/run_tests.gd, title: Progression and room integration tests }
  - { resource: ../../tests/clear_tests.gd, title: Clear-state tests }
  - { resource: ../../tests/root_travel_tests.gd, title: Root travel and editing-permission tests }
---

# Contracts

| ID | Contract | Primary trace |
| --- | --- | --- |
| P1 | Activation is local, direction-aware, capacity-limited, prerequisite-aware, and exclusive-group-aware; travel over active links is bidirectional. | `tests/run_tests.gd`, `tests/branching_tests.gd` |
| P2 | ALL and ANY prerequisites are ongoing. Deactivation removes unsupported or root-disconnected nodes to a fixed point, refunds affected non-roots, and is atomic if it would remove the occupied room. | `tests/run_tests.gd`, `tests/map_preview_tests.gd` |
| P3 | Active rooms derive abilities/modifiers; permanent rewards are collected once per node/object instance and survive deactivation. | `tests/run_tests.gd`, `tests/branching_tests.gd` |
| C1 | Clear state is per node, monotonic for a run, independent of activation, and default-cleared when a template has no conditions. Clear conditions combine with ALL. | `tests/clear_tests.gd` |
| C2 | Tokens are visit-local objectives, switch hits latch, enemy progress follows encounter lifetime, and clear effects apply once. | `tests/clear_tests.gd` |
| C3 | `become_root` makes a cleared node active, free, permanent, and an independent connectivity anchor; it cannot be an exclusive choice. | `tests/clear_tests.gd` |
| T1 | Root travel targets only another cleared, active root and preserves build/HP; occupied uncleared rooms may opt out of tree editing but not travel. | `tests/root_travel_tests.gd` |
| A1 | Source bundles validate before replacement, retain unknown fields, reject unsupported runtime vocabulary explicitly, and never contain live-run state. | `tests/content_tests.gd`, `tests/editor_tests.gd` |
| A2 | V2 links own instance doors: preview and compilation share deterministic placement over all links; manual overrides persist until reset, and V1 migration preserves linked arrival positions. | `tests/door_layout_tests.gd` |
| A3 | Routine editor controls, canvas gestures and binding pickers edit only validated portable source through one bounded undo/redo history; panels preserve unknown fields and cannot bypass invalid pending JSON. | `tests/editor_canvas_tests.gd`, `tests/node_panel_tests.gd`, `tests/room_panel_tests.gd`, `tests/binding_editor_tests.gd` |
| A4 | Switch/wall bindings remain stable node-instance/object addresses using only `toggled → set_open`; filtered authoring and template indicators do not create template-global switch state. | `tests/binding_editor_tests.gd`, `tests/content_tests.gd` |
| U1 | Presentation only consumes snapshots/intents. Inspection does not mutate the run; selection, player location, and camera are separate state. | `tests/tree_panel_tests.gd`, `tests/map_tests.gd`, `tests/map_camera_tests.gd` |
| L1 | Stale deferred transitions (including arena restart) cannot affect a fresh run; deferred arrivals/restarts preserve authoring visibility and loaded-gameplay pause. | `tests/clear_hardening_tests.gd`, `tests/editor_tests.gd`, `tests/arena_tests.gd` |
| R1 | Active linked ports are crossed through their room-boundary openings; unavailable links stay blocked, and paired arrivals cannot immediately retrigger travel. | `tests/shell_tests.gd` |
| B4 | BUILD-01 numeric modifiers multiply and refunds restore stats; fractional damage, sector geometry, real attack interval and dash distance/recharge match the derived build. Actions capture their parameters. | `tests/build_tests.gd` |
| H1 | Max-HP allocations never heal; removal clamps current HP and reactivation cannot restore it. Fresh-run/retry initialization is separate. | `tests/build_tests.gd`, `tests/branching_tests.gd` |
| H2 | Authored health pickups restore a fixed positive amount up to maximum HP, remain uncollected at full HP, and persist once per node/object until a fresh run. | `tests/content_tests.gd` |
| H3 | Health pickups and health chests display a cross and their healing amount, distinct from ordinary rewards. | `tests/content_tests.gd` |
| B5 | The BUILD-01 arena offers six four-deep sequential upgrade chains, an eight-point budget and free encounter access; explicit trial restart restores encounters/full build HP at the root while retaining deep allocations. | `tests/arena_tests.gd` |
| E1 | Roost Guardian stays within its spawn tether and follows pressure → locked telegraph → expanding gapped wave → contact-safe recovery; waves sweep player motion, deal at most one hit, and bypass contact-only Phase immunity. | `tests/boss_tests.gd` |
| E2 | Guardian summons are warned and capped at three; boss death removes its transient summons/wave and completes its authored enemy objective. Fresh trial resets boss state while retaining the build. | `tests/boss_tests.gd` |
| Q1 | A suite passes only after process termination, zero exit, exactly one valid completion record with assertions and no failures, and no unexpected engine errors. Missing/malformed completion cannot pass. | `tests/test_runner_test.py` |
| Q2 | Full runs account for every V2 `*_tests.gd` script. Selectors are validated, overlapping selections run once, and timeouts terminate the suite process tree. | `tests/test_runner_test.py` |
| Q3 | Failures do not stop other selected suites; reports retain per-suite evidence and accurate totals. Failed, incomplete, interrupted, or invalid runs return nonzero. | `tests/test_runner_test.py` |

# Running the contract suites

Requires Python 3.10+ (standard library only) and Godot 4.6. Commands below run
from the repository root; the runner resolves the Godot project independently of
the working directory.

```powershell
# Complete V2 regression run (21 suites).
python v2/tests/run_suites.py --godot C:\Godot\Godot.exe

# Inventory and focused selections.
python v2/tests/run_suites.py --list
python v2/tests/run_suites.py --godot C:\Godot\Godot.exe --area editor
python v2/tests/run_suites.py --godot C:\Godot\Godot.exe --invariant A3
python v2/tests/run_suites.py --godot C:\Godot\Godot.exe --suite node_panel

# Runner's own protocol/process/report regression checks; no Godot needed.
python -m unittest discover -s v2/tests -p test_runner_test.py
```

`--godot` defaults to the `GODOT` environment variable, then `godot` on PATH.
`--timeout 60` is the default per-suite limit in seconds; it must be positive.
The runner executes isolated headless processes sequentially and waits for each.
Timeouts terminate the process tree. Ctrl+C terminates the active suite and
reports the unfinished selection as `not_run`.

Repeat or combine `--suite`, `--area`, and `--invariant` to select their **union**,
deduplicated in manifest order. Omit selectors to run all suites. Areas are
`progression`, `lifecycle`, `content`, `editor`, `presentation`, and `combat`.
Tags describe the contracts exercised, not exhaustive coverage or proof that
every assertion maps individually to that invariant.

## Evidence and failure semantics

Each run writes a unique, ignored `v2/test-results/<UTC timestamp>/` directory.
Use `--output <directory>` for a fixed destination (files in that destination
are overwritten). It contains:

- `report.json`, schema version 1: start time, duration, Godot version,
  configuration/selection, overall status, errors, status totals, and suite results.
- `<suite>/stdout.log` and `stderr.log`: complete captured output.
- Suite results: identity, script, area, invariant IDs, status, duration,
  exit code, total/passed/failed assertions, failure messages, execution errors,
  and absolute log paths. Unexecuted suites retain identity and `not_run` status;
  assertion counts are unavailable when the completion protocol fails.

Console output gives one result line per suite, totals, and the report path.
Statuses distinguish `passed`, `failed` (assertions), `error` (execution/protocol),
`timeout`, and `not_run`. Unexpected engine diagnostics take precedence over
assertion failures. A zero exit or engine banner alone is insufficient.
Run-level configuration errors are reported as `error`. Exit zero means every
selected suite passed; `--list` is inventory-only and also exits zero on success.

## Maintaining the test boundary

`tests/suites.json` owns the inventory and the area/invariant selection labels;
the contracts above remain the behavioral specification. Add a manifest entry
when adding a `tests/*_tests.gd` file. Missing, duplicate, and stale entries fail
validation before execution, including for focused runs.

Godot suites extend `tests/suite_reporter.gd`, increment `assertion_count` in
their assertion helper, accumulate failure messages, and call `_complete(code)`
only after all asynchronous checks and cleanup finish. This emits one
`V2_TEST_RESULT` JSON record. Assertion failures use `printerr`, leaving engine
`ERROR:` and `SCRIPT ERROR:` diagnostics distinguishable from assertion failures.
Keep direct Godot invocation available for debugging, but use this runner's
report as evidence for regression completion.

For a negative-path test that intentionally triggers an engine error, list its
**exact diagnostic line** in that suite's optional `expected_diagnostics` array.
Matching is occurrence-counted: extra or absent expected lines fail the suite.
Do not suppress broad patterns or add exceptions merely to make a run green.

# Change rule

Add an entry only for a behavior future work must preserve. Put detailed
setup, edge cases, and red/green history in the relevant test or feature
document; this table should remain a scanable index.
