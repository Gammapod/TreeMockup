# V2 Knowledge Update Log

## 2026-11-25
* **Sword Branch checkpoint:** The user confirmed the candidate's abilities and
  connections; encounter and room design remain open. The [experiment
  record](experiments.md#unified-sword-branch-extension-2026-11-25) and
  [backlog](../backlog.md#proposed-sprint-sequence) record the next Sword,
  cleared-prerequisite and mini-boss work.

## 2026-11-23
* **Unified abilities and editor checkpoint:** The
  [content contract](content.md#unified-contributions) and
  [architecture](architecture.md) describe the implemented contribution model
  and Phase lifecycle; the [UI contract](ui.md) covers build previews, Phase
  feedback and grouped contribution authoring. The
  [experiment record](experiments.md#unified-abilities--phase-dash-lab-2026-11-23)
  distinguishes positive user feedback from unresolved dungeon testing.
* **Test ownership:** Engine and Frontend maintain separate suite manifests;
  the [invariant index](invariants.md#running-the-contract-suites) documents
  independent owner runs and the combined regression run.

## 2026-11-16
* **Instance doors accepted**: V2 tree links own door placements; a shared
  resolver keeps editor preview and runtime geometry aligned. Manual overrides,
  reset and legacy arrival preservation are captured by A2. Editor UX is now
  the active focus; [canvas/history exploration](../editor-exploration.md)
  precedes contextual panels and the larger dungeon design.
* **Canvas authoring accepted; node panel completed**: persistent selection,
  direct manipulation, camera controls and bounded source history form the
  editor foundation. The tree node panel now exposes typed grants/modifiers,
  template navigation/copy and instance summaries without replacing portable
  JSON as the advanced surface; room-object controls were completed in EDITOR-01.
* **Room contextual panel completed**: selected objects now receive typed,
  kind-specific controls and direct rectangle resize gestures, while template
  clear rules remain shared with the existing dialog. Fixed playable dimensions,
  per-enemy damage and flags remain deliberately deferred.
* **EDITOR-01 accepted**: automatic/manual instance doors, canvas/history,
  node/room contextual panels and filtered switch-to-wall bindings are the
  accepted authoring baseline. The [closeout](../archive/editor-01-closeout.md)
  records the retained ownership seams and deferred scope.
* **BOSS-01 accepted**: Closed the Roost Guardian as the capstone baseline.
  [Architectural review](../archive/boss-01-closeout.md) records ownership,
  lifecycle and fixture-specific geometry constraints; tuning/polish remains
  follow-up work. README, experiment record and backlog now point to
  interconnected 14–18-node dungeon design as the next session's target.

## 2026-11-15
* **BOSS-01 ready for evaluation**: Added the room-local guardian behavior and
  free Boss Trial. Content/architecture document transient summons and
  contact-vs-wave damage; E1/E2 link to encounter tests. BUILD-01 stays accepted.
* **BUILD-01 accepted**: Closed the expanded stackable-ability workshop.
  Consolidated current vocabulary in `content.md`, acceptance in
  `experiments.md`, and review history in
  [`../archive/build-01-closeout.md`](../archive/build-01-closeout.md).
  Architecture/L1 now explicitly cover arena restart preserving editor pause.
* **Creation**: Established the OKF handoff bundle with current architecture,
  invariants, experiment record, glossary, and a minimal recording policy.
* **Migration**: Promoted active content, clear-state, UI, and branching
  contracts into concepts; moved their feature-closeout histories to
  [`../archive/`](../archive/README.md).
