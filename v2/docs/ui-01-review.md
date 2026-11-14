# UI-01 accepted contract and architecture review

UI-01 is completed; the user accepted the baseline, room-entry framing and
consequence clarity. Visual polish and control refinements are deferred.

## Accepted invariants and test trace

| ID | Contract | Evidence |
| --- | --- | --- |
| UI-ACTION | Inspection never commits. Actions are explicit and revalidated by progression; presentation cannot grant remote permissions. | `map_tests.gd`, `run_tests.gd` |
| UI-PREVIEW | Removal highlights, refunds and requirements reflect model previews/current state, including rejected occupied-room cascades and alternate ANY support. | `map_preview_tests.gd` |
| UI-STATE | Rewards, allocations, travel and fresh playtests refresh presentation. Occupied room and selected node are independent; a fresh document clears selection. | `map_tests.gd` |
| UI-CAMERA | Entry centers the occupied node and fits travel neighbors without selecting it. Ordinary refresh preserves navigation. Fit/zoom work across authored coordinate ranges; wheel zoom anchors at the cursor. | `map_tests.gd`, `map_camera_tests.gd` |
| UI-SHELL | Room/map/HUD/status fit supported window sizes; the room remains an independent 800×600 world. Unhandled game keys reach the room; editor activity suspends gameplay. | `shell_tests.gd`, `editor_tests.gd`; standalone fullscreen manually verified |
| UI-BOUNDARY | Progression owns legality and transactions; coordinator owns run/room effects; tree panel consumes presentation snapshots and emits action intents; map owns drawing/navigation; shell owns screen space/input transport. | `tree_panel_tests.gd` and existing integration suites |

Presentation details (colors, label wording, fixed panel heights, immediate camera
snaps) are not stable contracts. Resize currently refits the neighborhood, or the
whole graph after manual navigation; that policy remains changeable.

## Hindsight architecture

With the requirements known upfront, the selected-node controls and their
formatting would belong to a reusable tree panel, not the run coordinator.
Extract that panel behind a snapshot/action-intent boundary. Keep the existing
map and shell boundaries, the portable content schema, and progression rules.
Do not introduce a general screen router, permission framework or layout engine.

## Hardening findings

- `main.gd` accumulated both scene orchestration and tree widget/description
  responsibilities. Extract the latter without changing accepted interaction.
- Whole-graph fitting clamps to a minimum zoom that can crop widely spaced
  authored positions. Neighborhood fitting can go below that minimum, making
  the next wheel-down input unexpectedly zoom **in**. Reproduce with a focused
  camera regression before correcting fit/manual zoom consistency.
- Keep existing integration assertions while moving their UI access to the new
  owning panel; do not retain coordinator UI aliases solely for test compatibility.

## Implemented checkpoint architecture

- `main.gd`: builds progression previews and a run snapshot, applies action
  transactions and encounter/room consequences, requests entry framing.
- `gameplay_tree.gd`: owns selection details and action controls. Receives a
  validated content definition plus `{current, active, available_points, previews}`.
  Copies the run snapshot so later mutations cannot partially change the view.
  Emits `action_requested(node_id)`; holds no progression reference.
- `gameplay_map.gd`: owns graph drawing, hit testing and camera state. Receives
  node states and removal previews; no gameplay mutations.
- `gameplay_shell.gd`: owns viewport placement/scaling, region layout and key
  transport. The room remains a fixed-coordinate physics world.
- `progression.gd`: remains the only owner of activation/deactivation legality,
  cascades and transaction execution.

Content is immutable for a run. Production document replacement configures the
panel before publishing a new snapshot and clears selection/highlights.
The portable-content test now starts a new run for its second scenario instead
of replacing coordinator internals without notifying the presentation.

## Verification record

- **Red:** `map_camera_tests.gd` reproduced both wide-coordinate fit cropping and
  wheel-down zoom reversal before production changes.
- **Red:** `tree_panel_tests.gd` reported the missing standalone presentation
  boundary before extraction.
- **Green:** fit no longer imposes an incompatible minimum zoom; manual wheel
  navigation respects the automatically fitted scale and cursor anchor.
- **Green:** panel isolation verifies action intents, no run-state mutation,
  snapshot ownership and document-reset behavior.
- Existing action tests additionally characterize execution-time rejection of
  a stale, previously enabled capacity preview.
- All nine V2 suites pass on Godot 4.7.2, with no script errors. Existing layout,
  room integration, content and editor checks were retained. Fullscreen was
  previously verified in a standalone run and confirmed by the user.

The accepted functional slice is ready for a checkpoint. No general UI framework
or gameplay-rule changes were required; further UX polish remains deferred.
