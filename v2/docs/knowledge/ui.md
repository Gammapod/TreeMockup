---
type: UI Contract
title: Dungeon skill-tree map and shell
description: Accepted presentation behavior and boundaries for the V2 gameplay UI.
tags: [v2, ui, map, shell]
status: stable
generated: { by: "openai/gpt-5.6-terra", at: 2026-11-15T00:00:00Z }
sources:
  - { resource: ../../gameplay_tree.gd, title: Tree panel }
  - { resource: ../../gameplay_map.gd, title: Map renderer and camera }
  - { resource: ../../gameplay_shell.gd, title: Responsive shell }
  - { resource: ../archive/ui-01-review-closeout.md, title: Archived implementation closeout }
---

# Accepted behavior

* The map shows authored node positions, travel links, prerequisite arrows,
  active/available/blocked state, root/clear badges, selected node, and
  occupied-room marker as separate concepts.
* Selection is inspection only. It neither moves the player nor changes the
  build. Activation/deactivation are explicit intents, previewed from the
  model and revalidated at execution.
* Deactivation preview communicates affected nodes, refund, ongoing ALL/ANY
  requirements, exclusive conflicts, and occupied-room rejection.
* Entering a room frames the occupied node and direct travel neighbors without
  changing selection. Manual pan/zoom persists through ordinary refresh;
  Fit graph resets the full graph view.
* The shell owns responsive room/map/HUD layout. The displayed room is an
  independent fixed 800×600 world; unhandled gameplay keys are forwarded to
  it and authoring pauses it.
* Linked ports map to visible boundary doors. An active linked door is crossed
  by movement (including dash); unavailable links remain physically blocked and
  visibly distinct. Paired-port arrivals are held until the player moves away,
  preventing immediate bounce-back. `E` remains for deliberate interactions.
* BUILD-01 exposes final sword/dash stats and selected-node benefits/costs.
  The player's sector previews attack reach/arc and uses captured parameters
  during an attack. Its launch/restart controls send coordinator intents;
  restart obeys the same editor-pause and stale-transition boundaries as travel.

# Boundary

The tree panel receives copied snapshots and emits action/travel intents. The
map owns rendering, hit-testing, and camera state. The shell owns screen space
and input transport. None may mutate progression. Colors, wording, fixed
panel heights, and camera animation are presentation details, not contracts.

# Evidence

`tests/tree_panel_tests.gd`, `tests/map_tests.gd`,
`tests/map_preview_tests.gd`, `tests/map_camera_tests.gd`, and
`tests/shell_tests.gd` are the primary traces. The room-boundary mapping and
door transition trace are in `tests/shell_tests.gd`.
