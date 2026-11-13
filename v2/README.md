# Rooms as Skills — V2

Open **this directory's `project.godot`** in Godot 4.6 and run. This is a separate project from the original prototype. `.gdignore` prevents the parent project importing V2 scripts.

## Playable experiment

- WASD moves; E uses a nearby green doorway.
- The side panel activates/deactivates adjacent rooms. Hover a button to preview affected nodes.
- Space performs a timed directional sword attack when Sword is active.
- Shift dashes when Boots is active. Dash collides with walls and does not grant invulnerability.
- Blue pickups permanently increase allocation capacity; yellow pickups grant gold.
- Activate both landings to activate Prize. Removing either landing also removes Prize, even if its other entrance remains connected.
- Defeat returns you to Sanctuary at full health, retaining your build and rewards.

Try activating Sword and Boots from Sanctuary, collecting their capacity pickups, and activating their landings. Prize can then be activated from either landing. Return to Sword and deactivate Sword Landing to see the two-room refund.

This slice uses placeholder graphics and physics-based movement. The side panel is a debug tree view, not the eventual skill-tree editor. Combat feel still needs interactive playtesting.

## Accepted rules

1. Root is permanently active and costs zero. Other active rooms allocate points; deactivation refunds their authored costs.
2. Activation is local and respects authored activation direction. Travel between active linked rooms is bidirectional.
3. ALL and ANY prerequisites are ongoing requirements. Exclusive groups permit at most one active member.
4. Deactivation removes unsupported and root-disconnected rooms to a fixed point. Alternate support can preserve a room.
5. A transaction that would deactivate the occupied room is rejected, with no partial effects.
6. Abilities derive from active rooms, irrespective of which room scene is loaded.
7. Permanent reward IDs are scoped to node instances, so two nodes can reuse one template without sharing loot.

## Architecture and future authoring

- `content.gd`: separate room-template and skill-tree documents, currently dictionaries. Templates own local obstacles, enemy placements and pickups. Nodes own template references, costs, requirements, abilities and advisory map positions. Physical links own named entrance pairs and activation direction.
- `progression.gd`: headless activation evaluation, cascade previews, transactions and capability derivation. Also holds the small prototype run ledger (capacity, rewards, gold). It has no movement, enemy, input or rendering dependencies.
- `main.gd`: run coordinator, local debug controls, scene transitions and per-node encounter records.
- `room.gd`: transient room gameplay, physics geometry, encounters and portals. Emits reward/transition intents; receives capabilities and persistent room data. Does not inspect the progression graph.
- `player.gd`: physics motor, dash, timed directional attack and damage cooldown. Attack parameters are captured at action start.

The room editor should eventually author template resources with stable object IDs and named ports. The skill-tree editor should author node instances, prerequisites, template references, portal pairings and cross-room bindings. Cross-room bindings should use `(node_id, object_id, property/action)` addresses resolved by the run coordinator; they must work when the target scene is unloaded. The `interactions` field reserves this boundary; cross-room switches and their editor are not implemented in this slice.

Map coordinates are advisory and distinct from room-local geometry. This fixture fits together schematically; no spatial packing constraint is enforced. Before content production, introduce typed/versioned resources and an authoring validator for IDs, template references, prerequisite cycles and port conflicts. Do not make an editor depend on runtime scene paths.

### Explicit prototype policies

- Encounters: surviving enemies reset on departure; defeated enemies stay defeated while the node remains active. Deactivation resets its encounter. Permanent pickups remain collected.
- Health: fixed five HP, no activation healing. Health-granting modifiers are deferred until their healing/removal policy is decided.
- Room activation is local to the current room, not proximity to a particular door. Remote activation is not implemented; add it later as an interaction permission rather than bypassing prerequisite/resource validation.
- The demo has sword, dash and an ALL merge. ANY merges and exclusive groups are exercised by model tests. Attack variants, hazards, chests, switches, save/load, editors and a graphical tree map are follow-up slices.
- Current capabilities use minimal numeric fields plus ability IDs; behavior variants should become separate implementations as they are explored.

## Verification

```powershell
& 'C:\Godot\Godot.exe' --headless --path v2 --script tests/run_tests.gd
```

Run from the repository root (use `--path .` if already in `v2`). Tests cover allocations/refunds, permanent rewards, ongoing ALL/ANY prerequisites, exclusivity, player safety, transaction previews and room/coordinator integration.

Next: playtest sword/dash timing and doorway transitions before expanding the content schema or building editors.
