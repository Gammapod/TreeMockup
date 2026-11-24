# Editor UX exploration

Status: **Completed and accepted.** The author accepted every planned editor UX
slice. The concise closeout is [EDITOR-01](archive/editor-01-closeout.md).
This document records the earlier exploration; the current unified capability
model selector and grouped contribution editor are described in the
[UI contract](knowledge/ui.md#node-editor-checkpoint).

## Direction

Develop in this order:

1. Instance-owned doors, automatic graph-derived placement, manual overrides
   and reset; migrate existing content without rearranging it.
2. Persistent selection, accurate hit-testing, undo/redo, responsive panes,
   pan/zoom, direct manipulation, duplication and deletion.
3. Tree contextual panel: abilities, modifiers, cost, template selection,
   edit/duplicate-and-assign template, instance room preview with doors,
   read-only clear rules and capacity-reward summary.
4. Room object contextual panel, rectangle resize handles, template clear rules.
5. Cross-room switch-to-wall binding picker using existing instance addresses.

Per-enemy damage, playable variable room dimensions, and a general flag system
are deferred. Existing enemy stats and fixed 800×600 room geometry remain.

## Slice 1: instance doors

F2 → Tree editor → select a node → **Instance doors…**.
Drag a doorway to a wall, or choose a link endpoint and edit wall/percentage.
**Reset to automatic** resumes following graph layout. Green is automatic;
yellow is manual. Close the dialog to rearrange graph nodes, then reopen to
inspect the result. New links ask only for node IDs and generate both doors.

The editor upgrades V1 documents to V2 in memory; saving writes V2.
Existing linked port positions become manual endpoint overrides, including
exact legacy arrival coordinates. Legacy fields and unknown metadata are
retained, but V2 template ports do not generate doors. Unconnected legacy
ports disappear from the preview. Existing on-disk examples remain V1.

`door_layout.gd` resolves all links, irrespective of activation, for both
preview and runtime compilation. A dominant-axis wall choice and angular
ordering produce evenly spaced doors with 80-unit center separation.
Coincident nodes use a deterministic east/west fallback; equal angles use
endpoint IDs. Automatic doors reserve space around manual endpoints.
Manual placements stay fixed. Overcrowded automatic walls block playtest.
Overlapping manual doors and arrival footprints intersecting terrain produce
diagnostics in the instance-door panel; this is not a navigability solver.

The runtime receives per-node resolved ports. Templates remain reusable and
unmodified; gameplay still pairs doors by stable endpoint identity.

Evidence: `tests/door_layout_tests.gd` covers legacy migration, deterministic
placement/order/clearance, overrides/reset, crowded walls, serialization,
preview/runtime agreement and paired arrivals. Existing content/editor
boundary suites also pass. The author accepted the door placement interface.

### Review after acceptance

Retain one shared, deterministic door resolver and per-instance runtime ports.
The canvas remains responsible for drawing/input coordinates; the studio owns
source editing and history. Door editing now exposes gesture boundaries so a
drag becomes one reversible source edit rather than a stream of motion records.
This keeps the accepted selector while preparing for contextual panels.

## Slice 2: canvas and history

* Click selects a node, travel link, or room object. White outlines and a
  selected-ID label identify the selection. Rectangle picking uses the whole
  rectangle; enemies use their authored radius. Topmost objects win; **Alt-click**
  cycles overlapping elements.
* **Select** brush drags objects without jumping their origin to the cursor.
  Other brushes place objects even over existing terrain. **Escape** deselects
  and returns to Select. A new object/node or duplicate becomes selected.
* **Wheel** zooms at the cursor; **right/middle-drag** pans; **F / Fit view**
  frames the room or graph, including negative node positions. **Snap 10**
  toggles placement-grid and movement-delta snapping.
* Selection and camera are retained separately for the tree and each template.
  The adjustable canvas/source split and wrapping toolbars fit a 960×640 window.
* **Ctrl+D / Duplicate** clones an object or node with a fresh ID and a position
  offset. Node copies reuse the template and retain prerequisites/grants/modifiers;
  incident links and cross-room bindings are not copied.
* **Delete** removes the selected element. Node deletion also removes its
  incident travel links. The starting node cannot be deleted; other prerequisite,
  binding, or clear-rule references must be repaired first. Rejected deletions
  leave source untouched and identify the offending references.
* **Ctrl+Z / Undo**, **Ctrl+Shift+Z or Ctrl+Y / Redo** cover source changes:
  placement, movement, duplication/deletion, JSON application, new rooms/nodes/
  links, imports, clear rules, and door overrides/reset. Each drag is one edit.
  Door selectors have Undo/Redo buttons. Text inputs retain their own native
  editing shortcuts; canvas commands never delete objects while typing.
* History retains up to 100 snapshot edits, including unknown source fields and
  selection context. Selection/camera navigation is not undoable. Saving marks
  a clean document without discarding history; undo/redo compares against that
  saved document. Opening/replacing the bundle starts a fresh history.
* Invalid pending JSON stays available for correction and blocks source edits
  and history traversal. Valid pending JSON is applied as its own history step.

Evidence: `tests/editor_canvas_tests.gd` covers pointer gestures, overlapping
selection, brush placement, camera preservation/zoom, snapshot history,
saved-state behavior, reference-safe deletion, open-door-selector history,
text isolation, and responsive layouts. The content, original editor, door
layout, and shell regression suites pass. Rendered tree, room, and door views
were inspected at small and large window sizes.

Next: playtest this slice, then add the tree contextual panel (abilities,
modifiers, cost, template selection, edit/duplicate-template navigation and
instance preview/read-only summaries).

### Review after acceptance

The canvas/history interaction is retained as the common authoring foundation:
the preview owns hit-testing/camera/gesture boundaries and Studio owns source
transactions/history. It works for both regular canvas edits and the accepted
door selector. The panel must use the same source edits rather than creating a
second mutable node representation.

## Slice 3: tree-node contextual panel

Selecting a tree node opens **Properties** beside the graph; **JSON** remains
available for prerequisites, exclusivity, bindings and experimental fields.

* Edit name, nonnegative capacity cost, a multi-select ability list, and the
  assigned room template. The menu displays unknown abilities as selected and
  preserves them when known grants change.
* **Modifiers** expands to opt-in controls for supported numeric modifiers and
  sword/dash behavior styles. Disabled modifiers are absent from source.
  Unknown modifier fields remain untouched and are called out for JSON editing.
* **Edit template** opens the selected node's assigned template. **Back to
  node** returns to the original graph selection and camera. **Duplicate &
  assign** copies the reusable template with a new stable template ID, then
  assigns only the selected node. It retains object IDs/unknown fields and
  intentionally leaves instance-addressed bindings unchanged.
* The compact **Instance preview** renders the template plus resolved doors;
  drag a door for a manual override, or open the existing **Door selector /
  reset** controls. Both views call the same resolver and share undo/redo.
* Read-only template information lists dimensions, ALL clear conditions/effects,
  the edit lock, and potential capacity rewards. It sums capacity-valued pickups
  and chests and marks clear-revealed rewards.
* Template replacement validates source references and runtime endpoint types.
  For example, a switch binding cannot quietly become a pickup binding. Invalid
  replacement restores the selector and leaves source/history unchanged.

The long form scrolls independently at the supported 960×640 window. Panel
values never write defaults merely by displaying. Each panel edit is an ordinary
undoable source transaction; invalid pending JSON remains visible and blocks
panel edits just like canvas edits.

Evidence: `tests/node_panel_tests.gd` characterizes multi-select grants,
modifiers/unknown-field retention, summaries, source-safe template switching,
copy/assignment and navigation, shared instance-door history, invalid JSON
isolation, save round-trip and compact layout. Rendered ordinary and expanded
modifier panels were inspected. Existing content, editor, canvas/history and
door-layout suites pass.

Next: playtest the node panel, then add the room-object contextual panel,
rectangle resize handles, and room/template properties.

### Review after acceptance

The tree contextual panel remains a presentation-only typed layer over Studio's
portable source transactions. Its inline door preview verifies that panel views
can reuse canvas gesture boundaries and history rather than introducing a
separate edit path.

## Slice 4: room-template contextual panel

Selecting a room object opens **Properties** beside the canvas. The form adapts
to its kind while retaining JSON for unsupported properties:

* All objects expose stable ID and local X/Y. Water, walls and obstacles also
  expose width/height. Selected rectangles have white edge/corner handles;
  drag them to resize. A whole resize drag is one undoable edit.
* Enemies expose supported HP, speed and collision radius. Per-enemy damage
  remains deferred rather than presenting a nonfunctional control.
* Pickups and chests expose supported gold/capacity kind and positive value.
  Other object properties are explicitly preserved for JSON editing.
* With no object selected, the panel exposes template name, usage count and
  the existing **Clear rules…** authoring dialog. Dimensions are visible but
  correctly marked fixed at 800×600 for playable V2 content; changing room
  dimensions remains the deferred LAYOUT-02/runtime task.
* Invalid IDs or geometry are rejected through the ordinary content validator.
  Referenced object IDs are not silently rewritten in clear rules/bindings.
  Typed fields, direct resize, canvas selection, JSON and undo/redo share one
  source/history path.

Evidence: `tests/room_panel_tests.gd` covers kind-specific fields, edge/corner
resize/history, unknown-field preservation, source-safe referenced-ID rejection,
template metadata/clear-rule navigation, invalid-JSON isolation, portable save
round trip and compact scrolling. Existing content, editor, canvas/history,
node-panel and door-layout suites pass. Rectangle/enemy panels were rendered
and inspected.

Next: build the cross-room switch-to-wall binding picker and indicators. A
general flag system stays deferred.

## Slice 5: instance switch-to-wall bindings

**Bindings…** opens a picker for the existing `switch.toggled → wall.set_open`
runtime interaction. It lists only **node instances** whose templates contain a
switch/wall, then their compatible objects. Choose the source switch and target
wall, add the binding, or remove an existing binding. Duplicate endpoints are
rejected. Add/remove share the normal undo/redo history.

Selected switches/walls show their matching outbound/inbound bindings in room
Properties; selected tree nodes show the same instance-addressed relationship.
For reused templates, room Properties lists every matching node instance instead
of pretending the template itself owns the binding. The picker explains when
objects exist only in unused templates: bindings need node instances.

This deliberately supports only the current persistent switch/wall vocabulary.
Flags, extra events/actions, and arbitrary scripting remain future design work.

Evidence: `tests/binding_editor_tests.gd` covers filtering, source/target focus,
duplicate prevention, indicators, add/remove undo/redo, invalid-JSON isolation,
portable round-trip and runtime compilation. Existing room/node/canvas/editor
and content/door regressions pass.

### Acceptance and stabilization

The author accepted the room panel and switch interface, completing the planned
wishlist. The final review kept the shared door resolver, canvas intent/history
boundary, panel intent-only design, instance-addressed bindings and portable
JSON validation boundary. Characterization and full-suite verification are in
[EDITOR-01](archive/editor-01-closeout.md).

Future work is polish or a separately scoped primitive: per-enemy damage,
playable variable room dimensions, flags, broader interaction vocabulary or
painting/tile authoring.
