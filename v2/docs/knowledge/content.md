---
type: Content Contract
title: Room-tree content bundle v1
description: The portable authoring contract, validation boundary, and runtime vocabulary for V2 content.
tags: [v2, content, authoring, json]
status: stable
generated: { by: "openai/gpt-5.6-terra", at: 2026-11-15T00:00:00Z }
sources:
  - { resource: ../content.schema.json, title: JSON Schema }
  - { resource: ../../authoring/content_store.gd, title: Content validation and storage }
  - { resource: ../../authoring/runtime_adapter.gd, title: Runtime compiler }
  - { resource: ../archive/content-format-closeout.md, title: Archived implementation closeout }
---

# Boundary

A bundle is UTF-8 JSON with `format: "room-tree"` and `version: 1`. It is
portable source content, never a Godot resource, executable code, scene path,
or run save. Stable IDs—not labels or array positions—are references.

```json
{"format":"room-tree","version":1,"id":"scenario","name":"Scenario",
 "rooms":[],"dungeon":{"root":"start","initial_capacity":4,
 "nodes":[],"links":[],"interactions":[]},"extensions":{}}
```

Unknown fields and `extensions` survive storage at every level. Unsupported
future vocabulary may be stored but must block playtest explicitly; do not
silently reinterpret it.

# Structure

| Element | Required/current meaning |
| --- | --- |
| Room template | `id`, `name`, `size`, `ports`, `objects`; optional `spawn` and `clear`. Coordinates are local; runtime playtest currently requires 800×600. |
| Node | `id`, `name`, `template`, nonnegative `cost`, ALL/ANY prerequisite ID arrays, ability IDs, and advisory `map_position`; optional exclusive group/modifiers. |
| Link | Two node IDs and their unique instantiated ports; travel is bidirectional, while `activate_from` controls local activation direction. |
| Interaction | Stable `{node, object, event}` → `{node, object, action}` binding. It must work when the target room is unloaded. |
| Clear rule | Optional template `conditions`, `effects`, and `block_tree_editing_until_cleared`; see the [clear-state contract](clear-state.md). |

IDs are ASCII letters, digits, underscores, or hyphens. Room and node IDs
have separate namespaces; object/port IDs are template-local. Changing an ID
requires updating references—validation does not guess rewrites.

# Validation and lifecycle

The store rejects malformed JSON, unsupported versions, duplicate IDs/ports,
invalid references, invalid values, prerequisite cycles, and invalid root
rules before replacing an editor document or saved file. Saves validate the
whole candidate, write a sibling temporary file, then rename it.

The adapter compiles valid source to runtime dictionaries without mutating
source. A run owns all mutable progress; editor playtest compiles a fresh
run. Single-room interchange is `{format: "room-template", version: 1,
room: {...}}` and rejects duplicate template IDs.

# Current runtime vocabulary

| Category | Supported values |
| --- | --- |
| Objects | `obstacle`, `water`, `wall`, `switch`, `enemy`, `pickup`, `chest`, `token` |
| Abilities | `sword`, `dash`, `flippers` |
| Enemy behaviors | `chase` (default), `roost_guardian` |
| Numeric modifiers | Move speed; sword reach, arc, damage, interval; dash speed, distance, recharge; max HP (see below) |
| Behavior modifiers | Sword `big`/`fast`; dash `phase`/`run` |
| Clear conditions | All enemies defeated, named switch hit, all tokens collected |
| Clear effects | Reveal pickup, prevent enemy respawn, become root |
| Interaction | Switch `toggled` → wall `set_open` |

The [JSON Schema](../content.schema.json) is structural only. The store and
adapter perform the semantic checks above.

## BUILD-01 modifier authoring

Multipliers must be finite and positive; additive `max_hp_bonus` and
`sword_damage_bonus` remain nonnegative integers. Damage is fractional at
runtime. All additive sword damage is applied before damage multipliers, so
node order cannot change the result.

| Upgrade | Node `modifiers` |
| --- | --- |
| Thrust | `{"sword_range_multiplier":1.3,"sword_arc_multiplier":0.7}` |
| Sweep | `{"sword_arc_multiplier":1.5,"sword_damage_multiplier":0.75}` |
| Quick Cut | `{"sword_cooldown_multiplier":0.75,"sword_range_multiplier":0.8}` |
| Long Dash | `{"dash_distance_multiplier":1.4,"dash_cooldown_multiplier":1.4}` |
| Quick Step | `{"dash_distance_multiplier":0.75,"dash_cooldown_multiplier":0.7}` |
| Phase Dash | `{"dash_style":"phase"}` — contact immunity, distance ×0.65 |
| HP | `{"max_hp_bonus":1}` — maximum only, never healing |

Base sword: reach 92 world units, arc 1.8 radians (~103°), damage 1, interval
0.32 seconds. `build_arena.json` adds 7 base damage, multiplies arc by 2/3 and
interval by 2: damage 8, arc 1.2 radians, interval 0.64s. This gives all four
Sweep/Quick Cut copies meaningful benefits before reaching runtime limits.
Base dash: speed 650 units/second, duration 0.16 seconds (104 units), recharge
0.65 seconds measured from dash start. Distance modifiers change duration, not
speed. Numeric modifiers multiply across active nodes; refund recomputes them.

Arc saturates at 360°. The single-strike attack has fixed 0.14-second startup
and a 0.16-second action duration; attack interval cannot undercut that duration.
Legacy multi-strike styles extend the duration by 0.08 seconds per extra strike.
Dash recharge cannot be shorter than its duration. These bounds matter for
authored stacks beyond the experiment's four-copy branches.

Attack direction/reach/arc/damage and dash direction/speed/duration/contact
immunity are captured at action start. Walls still occlude sword hits and block
dashes. Flippers alone bypass water collision. Legacy big/fast sword and run
styles remain usable by existing fixtures; Phase Dash now uses BUILD-01 tuning.

The runtime includes the source bundle ID as `scenario_id`. The coordinator
uses `build_arena` to expose an explicit fresh-trial reset; it does not change
ordinary dungeon travel/healing rules.

## BOSS-01 enemy behavior

Author the guardian as an ordinary `enemy` object with
`properties.behavior: "roost_guardian"`; unknown behaviors reject playtest.
The arena supplies `hp: 120`, `speed: 60`, `radius: 38`, and position `[400,320]`.
Ordinary enemies default to `chase`. No new schema version is needed.
Guardian radius must remain below its 560-unit wave extent so the expansion
phase has a positive duration; the adapter rejects invalid values.

The guardian's cycle/tether/wave/summon timings are currently a single behavior
preset in `roost_guardian.gd`, not a general boss scripting format. The boss
uses the authored enemy HP, radius and movement speed. Its authored dry, open
arena supports the fixed summon points and full-room 560-unit wave radius.

Summoned bats are transient runtime enemies owned by that guardian. They do
not create authored objectives or persistent defeated IDs. The authored
`all_enemies_defeated` condition sees the guardian; killing it removes its
summons before emitting its normal defeat event. Leaving/re-entering follows
ordinary room persistence; explicit trial restart creates a fresh encounter.
