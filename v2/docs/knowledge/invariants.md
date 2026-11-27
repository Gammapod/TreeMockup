---
type: Contract
title: V2 functional invariants
description: Stable player-visible rules with the tests that characterize them.
tags: [v2, invariants, tests, gameplay]
status: stable
generated: { by: "openai/gpt-5.6-terra", at: 2026-11-15T00:00:00Z }
sources:
  - { resource: ../../tests/engine/run_tests.gd, title: Progression and room integration tests }
  - { resource: ../../tests/engine/clear_tests.gd, title: Clear-state tests }
  - { resource: ../../tests/engine/root_travel_tests.gd, title: Root travel and editing-permission tests }
---

# Observable behavior contracts

Suite references below retain their short historical names. Their authoritative
paths are in the owner manifests `tests/engine/suites.json` and
`tests/frontend/suites.json`: scripts live under `tests/engine/` or
`tests/frontend/`, while the runner and fixtures remain shared.

## Progression, clear state and travel

| ID | Contract | Primary trace |
| --- | --- | --- |
| P1 | Activation is local, direction-aware, capacity-limited, active-node-prerequisite-aware, and exclusive-group-aware; travel over active links is bidirectional. Room clear is not an allocation prerequisite. | `tests/run_tests.gd`, `tests/branching_tests.gd` |
| P2 | ALL and ANY prerequisites are ongoing. Deactivation removes unsupported or root-disconnected nodes to a fixed point, refunds affected non-roots, and is atomic if it would remove the occupied room. | `tests/run_tests.gd`, `tests/map_preview_tests.gd` |
| P3 | Active rooms derive abilities/modifiers; permanent rewards are collected once per node/object instance and survive deactivation. | `tests/run_tests.gd`, `tests/branching_tests.gd` |
| C1 | Clear state is per node, monotonic for a run, independent of activation, and default-cleared when a template has no conditions. Clear conditions combine with ALL. | `tests/clear_tests.gd` |
| C2 | Tokens are visit-local objectives, switch hits latch, enemy progress follows encounter lifetime, and clear effects apply once. | `tests/clear_tests.gd` |
| C3 | `become_root` makes a cleared node active, free, permanent, and an independent connectivity anchor; it cannot be an exclusive choice. | `tests/clear_tests.gd` |
| T1 | Root travel targets only another cleared, active root and preserves build/HP; occupied uncleared rooms may opt out of tree editing but not travel. | `tests/root_travel_tests.gd` |

## Portable content and authoring

| ID | Contract | Primary trace |
| --- | --- | --- |
| A1 | Source bundles validate before replacement, retain unknown fields, reject unsupported runtime vocabulary explicitly, and never contain live-run state. | `tests/content_tests.gd`, `tests/editor_tests.gd` |
| A2 | V2 links own instance doors: preview and compilation share deterministic placement over all links; manual overrides persist until reset, and V1 migration preserves linked arrival positions. | `tests/door_layout_tests.gd` |
| A3 | Routine editor controls, capability-model and grouped contribution-table edits, canvas gestures and binding pickers edit only validated portable source through one bounded undo/redo history; panels preserve unknown fields, ambiguous entries and cannot bypass invalid pending JSON. | `tests/editor_canvas_tests.gd`, `tests/node_panel_tests.gd`, `tests/room_panel_tests.gd`, `tests/binding_editor_tests.gd` |
| A4 | Switch/wall bindings remain stable node-instance/object addresses using only `toggled → set_open`; filtered authoring and template indicators do not create template-global switch state. | `tests/binding_editor_tests.gd`, `tests/content_tests.gd` |
| A5 | Capability authoring metadata is copied, matches runtime vocabulary and result bounds, and does not replace whole-document validation or perform model conversion. | `tests/capability_metadata_tests.gd` |
| A6 | Unified Player, Sword and Dash sections collapse independently as session-only view state, without changing source/history or losing pending drafts and JSON. | `tests/node_panel_tests.gd` |
| A7 | Optional node icon metadata round-trips across supported bundle versions, valid explicit IDs compile unchanged, and malformed legacy values remain source-preserved but cannot become runtime icon IDs; icons are not inferred from abilities or contributions. | `tests/engine/node_icon_contract_tests.gd` |

## Presentation

| ID | Contract | Primary trace |
| --- | --- | --- |
| U1 | Presentation only consumes snapshots/intents. Inspection does not mutate the run; selection, player location, and camera are separate state. | `tests/tree_panel_tests.gd`, `tests/map_tests.gd`, `tests/map_camera_tests.gd` |
| U2 | The tree panel presents copied current and before/after unified build snapshots, including dormancy, without applying allocation rules or presenting a rejected after-state. | `tests/tree_panel_tests.gd` |
| U3 | Phase feedback presents authoritative transit, restriction, outcome, damage and reset events without deriving gameplay rules. | `tests/phase_feedback_tests.gd`, `tests/phase_integration_tests.gd` |
| RP1 | Room presentation exposes detached live room geometry, visible rewards and objectives, and current enemy contact danger to a room-aligned view surviving replacement, without leaking hidden or collected rewards or treating transient summons as authored objectives. | `tests/engine/room_presentation_tests.gd` |
| AP1 | Action presentation exposes detached, actual action-clock readiness and room-local emitted strike sectors, without treating movement restrictions or occluded sector candidates as confirmed hits; a room-aligned mounted view receives presence and pause-aware frames, and replacement and stale-event guards apply. | `tests/engine/action_clock_presentation_tests.gd` |

## Runtime lifecycle, combat and health

| ID | Contract | Primary trace |
| --- | --- | --- |
| L1 | Stale deferred transitions (including arena restart) cannot affect a fresh run; deferred arrivals/restarts preserve authoring visibility and loaded-gameplay pause. | `tests/clear_hardening_tests.gd`, `tests/editor_tests.gd`, `tests/arena_tests.gd` |
| R1 | Active linked ports are crossed through their room-boundary openings; unavailable links stay blocked, and paired arrivals cannot immediately retrigger travel. | `tests/shell_tests.gd` |
| B4 | BUILD-01 numeric modifiers multiply and refunds restore stats; fractional damage, sector geometry, real attack interval and dash distance/recharge match the derived build. Actions capture their parameters. | `tests/build_tests.gd` |
| UAB1 | Unified contribution source is validated and explicitly discriminated; unsupported or mixed vocabulary is rejected rather than silently executing legacy behavior. | `tests/unified_tests.gd` |
| UAB2 | Unified builds compose active contributions deterministically, preserve dormant effects, bound derived stats and expose copied before/after snapshots for legal allocation and cascade previews. | `tests/unified_tests.gd` |
| UAB3 | Unified actions capture their build at start; independent sword/dash movement restrictions overlap, and Phase absence suppresses a sword hit due during transit. | `tests/unified_action_tests.gd` |
| UAB4 | Room Phase geometry resolution checks the full player shape and current barriers, forbids room-boundary crossing, and distinguishes return from a blocked return without mutating the run. | `tests/phase_geometry_tests.gd` |
| UAB6 | A unified Player executes fixed-duration normal dashes, captures action parameters and forwards restriction and Phase-arrival intents. | `tests/unified_player_tests.gd` |
| UAB7 | A directly configured unified Room resolves Phase arrivals against live geometry, applies endpoint contact, excludes absent-player interactions and emits copied outcomes; canceled or stale arrivals cannot affect a replacement room. | `tests/unified_room_tests.gd` |
| UAB8 | Portable unified compilation preserves source and its discriminator through live progression, snapshots and Phase resolution; legacy bundles retain their own semantics. | `tests/unified_portable_tests.gd`, `tests/phase_integration_tests.gd` |
| UAB9 | The coordinator binds room-aligned Phase feedback, resets it on room replacement, and carries a blocked-return defeat explanation into the new room without delaying defeat. | `tests/phase_integration_tests.gd` |
| H1 | Max-HP allocations never heal; removal clamps current HP and reactivation cannot restore it. Fresh-run/retry initialization is separate. | `tests/build_tests.gd`, `tests/branching_tests.gd` |
| H2 | Authored health pickups restore a fixed positive amount up to maximum HP, remain uncollected at full HP, and persist once per node/object until a fresh run. | `tests/content_tests.gd` |
| H3 | Health pickups and health chests display a cross and their healing amount, distinct from ordinary rewards. | `tests/content_tests.gd` |
| B5 | The BUILD-01 arena offers six four-deep sequential upgrade chains, an eight-point budget and free encounter access; explicit trial restart restores encounters/full build HP at the root while retaining deep allocations. | `tests/arena_tests.gd` |
| E1 | Roost Guardian stays within its spawn tether and follows pressure → locked telegraph → expanding gapped wave → contact-safe recovery; waves sweep player motion, deal at most one hit, and bypass contact-only Phase immunity. | `tests/boss_tests.gd` |
| E2 | Guardian summons are warned and capped at three; boss death removes its transient summons/wave and completes its authored enemy objective. Fresh trial resets boss state while retaining the build. | `tests/boss_tests.gd` |

## Test infrastructure

| ID | Contract | Primary trace |
| --- | --- | --- |
| Q1 | A suite passes only after process termination, zero exit, exactly one valid completion record with assertions and no failures, and no unexpected engine errors. Missing/malformed completion cannot pass. | `tests/test_runner_test.py` |
| Q2 | Full runs account for every V2 `*_tests.gd` script recursively; owner runs validate only their own manifest and directory. Selectors are validated, overlapping selections run once, and timeouts terminate the suite process tree. | `tests/test_runner_test.py` |
| Q3 | Failures do not stop other selected suites; reports retain per-suite evidence and accurate totals. Failed, incomplete, interrupted, or invalid runs return nonzero. | `tests/test_runner_test.py` |

# Architectural boundary trace

| ID | Requirement | Primary trace |
| --- | --- | --- |
| UAB5 | The coordinator publishes a copied current-build snapshot independently of selected-node previews. | `tests/phase_geometry_tests.gd` |
| AP2 | Player retains avatar drawing but does not draw a second avatar-relative legacy sword sector; the room-aligned strike presenter owns the emitted-sector cue. | `tests/engine/action_clock_presentation_tests.gd` |
| RP2 | The room-aligned presenter owns loose gold and capacity pickup drawing; Room retains health and chest drawing so a pickup has no duplicate base and chests remain identifiable. | `tests/engine/room_presentation_tests.gd`, `tests/frontend/room_visuals_tests.gd` |

# Running the contract suites

Requires Python 3.10+ (standard library only) and Godot 4.6. Commands below run
from the repository root; the runner resolves the Godot project independently of
the working directory.

```powershell
# Complete V2 regression run (see owner manifests for current inventory).
python v2/tests/run_suites.py --godot C:\Godot\Godot.exe

# Inventory and focused selections.
python v2/tests/run_suites.py --list
python v2/tests/run_suites.py --godot C:\Godot\Godot.exe --area editor
python v2/tests/run_suites.py --godot C:\Godot\Godot.exe --invariant A3
python v2/tests/run_suites.py --godot C:\Godot\Godot.exe --suite node_panel
python v2/tests/run_suites.py --godot C:\Godot\Godot.exe --owner engine
python v2/tests/run_suites.py --godot C:\Godot\Godot.exe --owner frontend

# Runner's own protocol/process/report regression checks; no Godot needed.
python -m unittest discover -s v2/tests -p test_runner_test.py
```

`--godot` defaults to the `GODOT` environment variable, then `godot` on PATH.
`--timeout 60` is the default per-suite limit in seconds; it must be positive.
The runner executes isolated headless processes sequentially and waits for each.
Timeouts terminate the process tree. Ctrl+C terminates the active suite and
reports the unfinished selection as `not_run`.

Repeat or combine `--suite`, `--area`, and `--invariant` to select their **union**,
deduplicated in manifest order. `--owner` restricts inventory validation and
selection to that owner; omit it to validate and run both. Omit the other
selectors to run all suites in scope. Areas are
`progression`, `lifecycle`, `content`, `editor`, `presentation`, and `combat`.
Tags describe the contracts exercised, not exhaustive coverage or proof that
every assertion maps individually to that invariant.
For example, the Engine `tutorial_candidate` suite exercises
`examples/tutorial_candidate.json`; it is not a test of the evolving
`examples/unified_tutorial_boots.json` or its Sword Branch.

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

Each owner maintains `tests/<owner>/suites.json` and its suite scripts; the
shared runner and fixtures remain Engine-owned and coordinated across owners.
The contracts above remain the behavioral specification. Add an entry to the
owning manifest when adding a suite. Missing, duplicate, cross-owner and stale
entries fail validation before execution. Owner-scoped runs validate their own
inventory; full runs additionally detect duplicate IDs across manifests and
unregistered scripts anywhere under `tests/`.

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
