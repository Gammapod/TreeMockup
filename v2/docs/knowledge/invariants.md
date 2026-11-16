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
| U1 | Presentation only consumes snapshots/intents. Inspection does not mutate the run; selection, player location, and camera are separate state. | `tests/tree_panel_tests.gd`, `tests/map_tests.gd`, `tests/map_camera_tests.gd` |
| L1 | Stale deferred transitions (including arena restart) cannot affect a fresh run; deferred arrivals/restarts preserve authoring visibility and loaded-gameplay pause. | `tests/clear_hardening_tests.gd`, `tests/editor_tests.gd`, `tests/arena_tests.gd` |
| R1 | Active linked ports are crossed through their room-boundary openings; unavailable links stay blocked, and paired arrivals cannot immediately retrigger travel. | `tests/shell_tests.gd` |
| B4 | BUILD-01 numeric modifiers multiply and refunds restore stats; fractional damage, sector geometry, real attack interval and dash distance/recharge match the derived build. Actions capture their parameters. | `tests/build_tests.gd` |
| H1 | Max-HP allocations never heal; removal clamps current HP and reactivation cannot restore it. Fresh-run/retry initialization is separate. | `tests/build_tests.gd`, `tests/branching_tests.gd` |
| B5 | The BUILD-01 arena offers six four-deep sequential upgrade chains, an eight-point budget and free encounter access; explicit trial restart restores encounters/full build HP at the root while retaining deep allocations. | `tests/arena_tests.gd` |

# Change rule

Add an entry only for a behavior future work must preserve. Put detailed
setup, edge cases, and red/green history in the relevant test or feature
document; this table should remain a scanable index.
