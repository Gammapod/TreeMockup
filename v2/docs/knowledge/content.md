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
| Numeric modifiers | Move speed, sword range/damage, dash speed, max HP |
| Behavior modifiers | Sword `big`/`fast`; dash `phase`/`run` |
| Clear conditions | All enemies defeated, named switch hit, all tokens collected |
| Clear effects | Reveal pickup, prevent enemy respawn, become root |
| Interaction | Switch `toggled` → wall `set_open` |

The [JSON Schema](../content.schema.json) is structural only. The store and
adapter perform the semantic checks above.
