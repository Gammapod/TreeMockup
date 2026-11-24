---
type: Architecture
title: V2 architecture and boundaries
description: Ownership boundaries for the Rooms as Skills V2 runtime and authoring path.
tags: [v2, architecture, godot, authoring]
status: stable
generated: { by: "openai/gpt-5.6-terra", at: 2026-11-15T00:00:00Z }
sources:
  - { resource: ../../main.gd, title: Run coordinator }
  - { resource: ../../progression.gd, title: Progression model }
  - { resource: ../../authoring/content_store.gd, title: Portable content store }
  - { resource: ../../authoring/runtime_adapter.gd, title: Runtime adapter }
---

# Purpose

V2 is an experimental Godot game where rooms are nodes in an allocatable
skill tree. It separates portable authored content from one transient run.

# Ownership

| Owner | Owns | Must not own |
| --- | --- | --- |
| `authoring/content_store.gd` | JSON source, validation, copied capability authoring metadata, lossless unknown fields, atomic saves | Engine/runtime state |
| `authoring/runtime_adapter.gd` | Compiling supported portable content into runtime dictionaries; explicit unsupported-mechanic rejection | Source mutation or silent fallback |
| `authoring/door_layout.gd` | Shared deterministic instance-door geometry for preview and compilation | Live-run state or source mutation |
| `authoring/studio.gd` / `edit_history.gd` | Editor source transactions, selection context and bounded undo/redo snapshots | Gameplay mutation or camera navigation as source history |
| `authoring/node_panel.gd` | Selected-node presentation and typed edit/navigation intents | Source mutation, independent copied node state, or runtime access |
| `authoring/room_panel.gd` | Selected-template/object presentation and typed edit intents | Source mutation, a second geometry model, or runtime access |
| `authoring/binding_editor.gd` | Typed picker/presentation for existing instance switch-to-wall bindings | New interaction semantics or runtime mutation |
| `authoring/preview.gd` | Canvas drawing, hit-testing, camera and gesture intents | Source document mutation |
| `progression.gd` | Activation, refunds/cascades, roots, clear/objective state, rewards, travel/edit permissions, derived capabilities | Input, physics, rendering, scene lifetime |
| `runtime/unified_actions.gd` | Staged unified action timing, captured action intents, restriction snapshots | Geometry, combat damage, room lifecycle or presentation |
| `main.gd` | Run lifecycle, room replacement, persistent per-node encounter/object state, event forwarding | Reimplementing progression legality or view state |
| `room.gd` / `player.gd` | Loaded-room physics, encounters, local interaction, event intent | Progression graph inspection or transaction authority |
| `roost_guardian.gd` | Loaded-room boss timing, tethered movement, telegraphs and swept wave geometry | Allocation graph, persistent clears, enemy HP mutation or run restart |
| `gameplay_tree.gd` | Copied snapshots, selection, presentation, action intents | A progression reference or mutations |
| `gameplay_map.gd` | Graph drawing, hit-testing, camera | Gameplay mutations |
| `gameplay_shell.gd` | Screen layout and gameplay-key forwarding | Room-world coordinates or game rules |

# Durable decisions

1. **Portable content is the authoring boundary.** Content is versioned JSON
   with stable IDs, not Godot scenes, executable code, or run saves. Unknown
   fields survive round trips. See the [content contract](content.md).
2. **The model is authoritative.** A preview is informational; activation,
   deactivation, travel, and collection are revalidated at execution by
   progression/coordinator code.
3. **Templates are reusable; run state is per node instance.** Persistent
   object identity is `(node_id, object_id)`. A template never owns shared
   rewards, clear state, or switch state.
4. **Content is immutable during a run.** Playtesting compiles a fresh
   document and starts a fresh runtime; editor source is retained separately.
5. **Transitions share one guarded path.** Door travel, root travel, defeat
   and arena trial restart use room generation to reject stale deferred work.
   Fresh-run initialization preserves editor visibility/pause; only explicit
   Playtest/launch intent exits authoring.
6. **Derived builds and action snapshots are distinct.** Progression composes
   active modifiers; the player captures action parameters at action start.
   Room combat consumes those parameters rather than recomputing the build.
   Max-HP allocation clamps current health but never heals.
7. **Arena retry is scoped to its fixture.** The coordinator restores the
   reward-free arena's allocations through model activation before initializing
   full build health. This is a test-trial lifecycle, not a general run-save
   format or a change to root travel. See the
   [BUILD-01 review](../archive/build-01-closeout.md).
8. **Boss behavior remains room-local.** The guardian controller emits wave-hit
   and summon intents. Room owns enemy records, damage, transient summons and
   defeat events; progression owns authored clear objectives. `player.hurt`
   distinguishes enemy contact from wave damage so Phase immunity does not
   silently apply to every hazard.
   Boss teardown removes its controller and owned summons before the authored
   defeat event. Summon IDs never enter the persistent defeated ledger.
   The [BOSS-01 review](../archive/boss-01-closeout.md) records the preset's
    geometry assumptions for reuse in the larger dungeon.
9. **Door placement belongs to tree instances.** V2 link endpoint overrides and
   graph layout resolve to per-node ports through one shared resolver. Template
   geometry is unchanged; compilation resolves every link regardless of active
   state. V1 migration retains exact arrival coordinates as manual overrides.
    The accepted selector and its canvas/history follow-up are described in
   [editor exploration](../editor-exploration.md).
10. **Editor panels emit source intents.** Canvas, node, room and binding views
    display copied source state and emit stable-ID edit/navigation intents.
    Studio validates and commits every source transaction, including one
    history record per gesture; source JSON remains available and invalid
    pending JSON blocks other authoring edits. This prevents contextual UI from
    becoming a competing mutable content model. See the accepted
     [EDITOR-01 review](../archive/editor-01-closeout.md).
11. **Unified Phase is an intent-to-resolution pipeline.** The action clock
    captures the build and schedules an arrival; Player forwards the intent,
    Room resolves it against live geometry and endpoint hazards, and the
    coordinator forwards only current-generation events. A committed transition
    cancels a pending arrival without refunding its captured recharge. Normal
    unified dashes and legacy Phase remain distinct mechanics. See the
    [runtime contract](content.md#unified-action-boundary) and UAB3–UAB9 in
    the [invariant index](invariants.md).

# Change guide

Preserve the owner above. If a proposed feature requires bypassing an owner,
add an explicit intent/API at that boundary rather than exposing internal
state. Record a new decision only when it changes an owner or a durable rule.
