---
type: UI Contract
title: V2 gameplay and authoring UI
description: Gameplay and editor presentation behavior and boundaries for V2.
tags: [v2, ui, map, shell, authoring]
status: stable
generated: { by: "openai/gpt-5.6-terra", at: 2026-11-15T00:00:00Z }
sources:
  - { resource: ../../gameplay_tree.gd, title: Tree panel }
  - { resource: ../../gameplay_map.gd, title: Map renderer and camera }
  - { resource: ../../gameplay_shell.gd, title: Responsive shell }
  - { resource: ../../authoring/node_panel.gd, title: Node properties panel }
  - { resource: ../../presentation/phase_feedback.gd, title: Phase feedback }
  - { resource: ../archive/ui-01-review-closeout.md, title: Archived implementation closeout }
---

# Gameplay presentation

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
  during an attack. Launch/restart controls send coordinator intents; restart
  obeys the same editor-pause and stale-transition boundaries as travel.
* For unified builds the tree details show the supplied current build even
  without a selection. A selected node can show the supplied before build and,
  only for an allowed preview with an after build, the hypothetical after build.
  Quality grant/effectiveness, dormant requirements and capped stats are
  displayed. Supplied source node IDs are resolved to names using the run
  definition (falling back to IDs); the panel does not compose build values.
* Phase feedback presents coordinator events: transit, landing, return or
  blocked return, and separately reported contact or wave damage. A failed
  attempt can show its supplied destination as coordinates and a world marker.
  Outcome feedback expires after two seconds; movement restriction feedback
  names supplied sword/dash causes until the restriction state clears. This is
  presentation, not a second resolver for timing, damage or geometry.

# Node editor checkpoint

* The dungeon capability model selector offers Legacy and Unified. Switching
  validates the whole document; it does not convert or remove incompatible
  source. In particular Legacy rejects even an empty `contributions` field,
  which must be handled in JSON. Undo/redo applies to successful changes.
* Unified node properties replace legacy ability and modifier controls with
  contributions grouped under Player, Sword and Dash. Quality checkboxes and
  separate additive and multiplicative stat fields represent node-local
  contributions, not final build values. Blank stat fields remove a matching
  contribution; Enter commits. Requirements do not grant an action.
* The three named, keyboard-focusable sections start expanded and collapse
  independently. Expansion is editor view state shared across selection and
  refresh, not source history. Uncommitted table drafts survive section
  rebuilds and node selection; a discard control is available.
* Repeated contributions in a slot are not aggregated or edited by the table;
  fractional additive HP is also read-only there. Use individual contribution
  controls or JSON for these cases. Individual controls use node-local stable
  IDs and metadata; unsupported entries are preserved for JSON editing.
  Stale edits and invalid pending JSON do not silently overwrite source.
  Studio validates source transactions; editing existing entries preserves
  their IDs and unrelated unknown fields.

These are implementation checkpoint observations, not a new acceptance or
rendered-usability claim. The earlier accepted editor exploration remains
historical; its legacy panel description is not the complete unified workflow.

# Boundary

The tree panel receives copied snapshots and emits action/travel intents. The
map owns rendering, hit-testing, and camera state. The shell owns screen space
and input transport. Phase feedback displays coordinator events. The node
panel emits stable-ID source intents; Studio owns validated transactions and
history. None may mutate progression. Colors, wording, fixed panel heights,
and camera animation are presentation details, not contracts.

# Evidence

`tests/frontend/tree_panel_tests.gd`, `tests/frontend/map_tests.gd`,
`tests/frontend/map_preview_tests.gd`, `tests/frontend/map_camera_tests.gd`, and
`tests/frontend/shell_tests.gd` are the primary map and shell traces. The
room-boundary mapping and door transition trace are in `shell_tests.gd`.
`tests/frontend/tree_panel_tests.gd` covers unified current and before/after
build presentation; `tests/frontend/node_panel_tests.gd` covers the model
selector, contribution table, drafts, section view state and source safety;
`tests/frontend/phase_feedback_tests.gd` covers supplied phase and restriction
events. These traces describe automated coverage, not a rendered playtest.
