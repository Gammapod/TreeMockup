---
type: Glossary
title: V2 gameplay glossary and primitives
description: Canonical short definitions for the Rooms as Skills vocabulary.
tags: [v2, glossary, gameplay, authoring]
status: stable
generated: { by: "openai/gpt-5.6-terra", at: 2026-11-15T00:00:00Z }
sources:
  - { resource: content.md, title: Portable content contract }
  - { resource: ../../progression.gd, title: Progression model }
---

# Core model

| Term | Meaning |
| --- | --- |
| **Room template** | Reusable local geometry, objects, ports, and optional clear rule authored in a content bundle. |
| **Node** | One dungeon/skill-tree instance of a room template; owns its own run state. |
| **Link** | A bidirectional travel connection between two instantiated named ports; its `activate_from` endpoints constrain activation, not return travel. |
| **Activation** | Spending available allocation capacity to make a locally reachable node active. |
| **Active** | In the current build; grants its abilities/modifiers and can participate in travel/support. |
| **Root** | A free, permanently active, cleared node that anchors connectivity; created by a `become_root` clear effect. |
| **Prerequisite** | Ongoing active-node requirement: ALL requires every listed node; ANY requires at least one. |
| **Exclusive group** | Nodes of the same group cannot be active together. |
| **Cascade** | Fixed-point removal of active non-roots that lose prerequisite support or connection to every root. |

# Room progress and rewards

| Term | Meaning |
| --- | --- |
| **Clear state** | Per-node run state independent of activation. Rooms without conditions are cleared immediately. |
| **Clear condition** | ALL-combined objective: defeat all enemies, hit a named switch, or collect all room tokens. |
| **Clear effect** | Completion result: reveal a pickup, prevent enemy respawn, or become a root. |
| **Token** | Room-local objective item; it is neither capacity nor gold, resets on uncleared departure, and disappears on clear. |
| **Permanent reward** | Gold or capacity pickup/chest collected once using `(node_id, object_id)` identity. |
| **Capacity** | Allocation budget: initial capacity plus collected capacity rewards, minus active non-root node costs. |

# Player primitives

| Term | Meaning |
| --- | --- |
| **Sword** | Space-triggered directional melee attack, granted by an active node. |
| **Dash** | Shift-triggered movement burst, granted by an active node. |
| **Flippers** | Ability that bypasses water collision. |
| **Modifier** | Numeric or behavior adjustment aggregated from active nodes; behavior styles require their base ability. |
| **Reach / arc** | Sword's forward extent and angular coverage; independent numeric stats. |
| **Attack interval** | Time between starting successive attacks, bounded by action duration. |
| **Phase Dash** | A dash behavior granting enemy-contact immunity while retaining 65% of normal distance. |
| **Max-HP upgrade** | Raises health capacity without healing; removal clamps current HP. |
| **Trial restart** | Arena-only fresh attempt: retains allocations, restores encounters and full build HP, and returns to Workshop. |
| **Root travel** | Map travel from any active room to another cleared, active root, preserving build and HP. |
| **Editing lock** | Optional uncleared-room policy that blocks activation and deactivation while occupied. |

# Authoring terms

| Term | Meaning |
| --- | --- |
| **Content bundle** | Versioned portable JSON document containing room library and dungeon graph; not a run save. |
| **Interaction binding** | Stable source node/object event to target node/object action address, valid even while the target room is unloaded. |
| **Map position** | Advisory tree-map coordinate, separate from room-local geometry. |
