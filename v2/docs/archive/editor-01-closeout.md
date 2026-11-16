# EDITOR-01 closeout — accepted authoring UX baseline

**Status:** Completed and accepted, 2026-11-16.

## Accepted outcome

The in-project authoring workflow now supports direct graph/room editing without
requiring JSON for routine work:

* V2 tree links own instance doors. A shared resolver produces automatic
  placement, manual endpoint overrides and reset-to-automatic while preserving
  V1 arrivals on migration.
* Both canvases support selection, overlapping-item cycling, direct movement,
  rectangle resizing, pan/zoom/fit, duplication/deletion, and bounded undo/redo.
* Node properties author common grants, modifiers, cost/template assignment,
  isolated template copies, instance-door preview, and read-only template
  information.
* Room properties author common geometry, supported enemy/pickup fields,
  template name and clear-rule navigation.
* A filtered instance picker authors the existing switch-toggle/wall-open
  binding, with contextual inbound/outbound indicators.

Portable JSON remains the advanced authoring surface and retains unknown fields.
Per-enemy damage, playable variable room dimensions, flags, broader
events/actions and a general scripting language are not implied by this baseline.

## Architecture review

The exploration validated the following seams:

1. `door_layout.gd` is the sole resolver for editor preview and compilation.
   Door placement is not duplicated in `room.gd`, panels, or Studio.
2. `preview.gd` owns screen/world transforms, hit-testing and gesture
   boundaries; Studio applies validated source transactions and owns the
   history snapshots.
3. Contextual panels hold copied display data only and emit stable-ID intents.
   They cannot mutate content or runtime state directly.
4. Bindings remain `(node_id, object_id)` instance addresses. Template context
   therefore lists all matching instances rather than creating template-global
   switch state.
5. Source-content validation remains authoritative. UI controls do not repair
   dangling references, reinterpret unknown fields, or bypass pending invalid
   JSON.

No further ownership extraction is justified at this scale. Snapshot history is
bounded at 100 source-document edits, intentionally favoring simple,
lossless/unknown-field-safe undo over granular patch infrastructure.

## Verification

Primary characterization:

* `tests/door_layout_tests.gd`
* `tests/editor_canvas_tests.gd`
* `tests/node_panel_tests.gd`
* `tests/room_panel_tests.gd`
* `tests/binding_editor_tests.gd`

The full V2 headless suite passed after closeout. Manual rendering review covered
tree, node/room panels, door selector and switch-binding picker.

## Handoff

The active contract is [the editor exploration summary](../editor-exploration.md)
alongside [architecture](../knowledge/architecture.md),
[invariants](../knowledge/invariants.md), and the
[content contract](../knowledge/content.md). Future work should select one
deferred primitive or polish task at a time rather than expanding this accepted
baseline implicitly.
