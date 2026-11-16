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
| `authoring/content_store.gd` | JSON source, validation, lossless unknown fields, atomic saves | Engine/runtime state |
| `authoring/runtime_adapter.gd` | Compiling supported portable content into runtime dictionaries; explicit unsupported-mechanic rejection | Source mutation or silent fallback |
| `progression.gd` | Activation, refunds/cascades, roots, clear/objective state, rewards, travel/edit permissions, derived capabilities | Input, physics, rendering, scene lifetime |
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

# Change guide

Preserve the owner above. If a proposed feature requires bypassing an owner,
add an explicit intent/API at that boundary rather than exposing internal
state. Record a new decision only when it changes an owner or a durable rule.
