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
  - { resource: ../../authoring/studio.gd, title: Editor shell and source transactions }
  - { resource: ../../authoring/preview.gd, title: Editor canvas }
  - { resource: ../../presentation/phase_feedback.gd, title: Phase feedback }
  - { resource: ../../presentation/action_feedback.gd, title: Action feedback }
  - { resource: ../../presentation/room_feedback.gd, title: Room feedback }
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
* The map displays an explicit node `icon_id` using the frontend icon set;
  missing, unknown or malformed values use a neutral fallback. It does not infer
  a symbol from a node's name, capabilities or benefits. Cost remains a
  separate badge. Names are persistently shown for the occupied node, its
  direct travel neighbors and the selected node; selecting another node reveals
  its name. When no room is occupied, all names are shown.
* The map and action buttons are keyboard-focusable. When the map has focus,
  arrows cycle through definition order rather than spatial direction, changing
  inspection only. Cycling does not automatically pan to an off-screen node.
  Fit graph and manual pan/zoom retain their existing roles. Space is forwarded
  as gameplay input even when a tree button has focus; Enter deliberately
  activates the focused button. Authoring still blocks gameplay input.
* The shell owns responsive room/map/HUD layout. The displayed room is an
  independent fixed 800×600 world; unhandled gameplay keys are forwarded to
  it and authoring pauses it.
* Linked ports map to visible boundary doors. An active linked door is crossed
  by movement (including dash); unavailable links remain physically blocked and
  visibly distinct. Paired-port arrivals are held until the player moves away,
  preventing immediate bounce-back. `E` remains for deliberate interactions.
* BUILD-01 exposes final sword/dash stats and selected-node benefits/costs.
  There is no avatar-relative sword-sector preview in either capability model.
  Launch/restart controls send coordinator intents; restart obeys the same
  editor-pause and stale-transition boundaries as travel.
* The action presenter overlays upper sword and lower dash readiness arcs at
  the same radius around the supplied room-local player position. They use
  supplied availability and action clocks; an unavailable action has no arc,
  and both are hidden while the supplied player presence is false. Emitted
  strikes produce an unlabelled brief dashed candidate sector at the emitted
  origin, not a confirmed hit or an occlusion-clipped footprint. Its lifetime
  advances only while the room processes and resets on replacement. The sector
  appears only after strike emission; the supplied contract does not expose
  pre-strike telegraph geometry.
* Supplemental room feedback uses the current detached room snapshot. Where
  bounds allow it labels Water, Wall, Wall (open), and Obstacle diagonally;
  enemy rings distinguish supplied dangerous and non-dangerous contact, with a
  neutral color for unknown contact status, without behavior or contact text.
  Contact status is not overall safety: Guardian waves remain a separate hazard.
  The snapshot does not supply Guardian wave geometry, and this feedback neither
  redraws nor resolves those telegraphs. Explicitly loose gold and capacity use
  centered glyphs; chests and ambiguous pickup records do not reveal their
  contents. Existing health and token marks are not duplicated.
* For unified builds the tree details show the supplied current build even
  without a selection. A selected node can show the supplied before build and,
  only for an allowed preview with an after build, the hypothetical after build.
  Quality grant/effectiveness, dormant requirements and capped stats are
  displayed. Supplied source node IDs are resolved to names using the run
  definition (falling back to IDs); the panel does not compose build values.
* Phase feedback shows the supplied attempted destination of a failed attempt
  with a world-space X, not a predicted valid landing, without routine transit,
  landing, return or coordinate text. A blocked return retains a warning and
  its defeat explanation survives the transition; actual reported contact and
  wave damage retain distinct messages. Outcome feedback expires after two
  seconds. An avatar-relative tether indicates the supplied blocked ordinary
  movement restriction state, not readiness, identically for sword, dash or
  overlapping causes, without explaining the cause or showing text or numbers.
  It hides while the avatar is absent, including Phase transit, and clears with
  the supplied state or room replacement. A visual reset does not change an
  action clock. This is presentation, not a second resolver for timing, damage
  or geometry; dash can still be possible during a sword movement lock.

# Node editor checkpoint

* Studio keeps file actions and Undo/Redo global, shows room or tree creation
  controls in their respective views, places Fit and Snap by the canvas, and
  places selection actions by Properties. Bundle JSON hides canvas-specific
  controls. Mode changes still respect invalid pending JSON.
* Node Properties offers an explicit map icon picker. Opening it is read-only;
  unknown or malformed legacy values are shown as preserved and can be
  explicitly replaced or cleared. Edits use the typed-ID predicate and
  validated source transactions, including undo/redo; clearing removes the
  field. Raw opaque source values are not coerced. See the
  [content contract](content.md#optional-node-icon-identifier).
* In the room editor canvas, water, wall and obstacle have distinct fills and
  diagonal type labels where their projected bounds fit. Explicitly typed
  health, gold and capacity pickups/chests and tokens can show their supplied
  symbols when sufficiently large on screen; missing or unknown reward kinds
  are not inferred. Selection, hit-testing, handles and shared instance-door
  geometry remain independent of these marks.
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
* The individual-contribution editor is a separately collapsible view, initially
  collapsed. Toggling it does not commit source or discard its current draft.

These are implementation checkpoint observations, not a new acceptance or
rendered-usability claim. The earlier accepted editor exploration remains
historical; its legacy panel description is not the complete unified workflow.

# Boundary

The tree panel receives copied snapshots and emits action/travel intents. The
map owns rendering, hit-testing, and camera state. The shell owns screen space
and input transport. Phase and action feedback display coordinator events and
snapshots; room feedback displays supplied room facts. None resolves combat,
infers gameplay rules or owns room geometry. The node
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
events. `tests/frontend/action_visuals_tests.gd`,
`tests/frontend/room_visuals_tests.gd`, and `tests/frontend/icons_tests.gd`
cover presentation boundaries, room replacement, fallback and icon registry
behavior. These traces describe automated coverage, not a rendered playtest.
The tether and Phase feedback are a prototype, not a rendered acceptance.
Whether players understand the shared tether and can time around it remains a
playtest question; review its visibility against readiness arcs, terrain and
Guardian effects at practical viewport sizes.
The current work has not established rendered acceptance: labels, icons and
badges may overlap at dense graph scales or room edges, and small room labels may
be unreadable at reduced viewport size. Terrain labels are suppressed when they
do not fit. No minimum zoom guarantees non-overlap. Guardian and action-overlay
interactions especially need visual review.
