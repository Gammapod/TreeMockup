# Prototype architecture

This project is a reusable testbed, not a production game. New experiments should preserve the separation below.

## Responsibilities

- `scripts/dungeon_model.gd` owns graph state, rule evaluation, traversal, and derived player capabilities. It has no rendering or input dependencies.
- `scripts/*_definition.gd` defines scenario data and runtime values.
- `scenarios/*.gd` builds isolated room/door/rule arrangements.
- `Dungeon.gd` renders the current scenario and translates mouse/keyboard input into model actions.

## Stable behavioral invariants

1. Open doors form a root-connected, loop-free tree when those rules are enabled.
2. Doors in a disconnected branch close when their root-side connection closes.
3. A door on the only root-to-player path is propped open.
4. Room abilities are derived from the rooms currently connected to the root.
5. Door capacity is derived from root-connected room abilities.
6. A player may operate only a door adjacent to their current room.

`tests/run_tests.gd` characterizes these invariants against the baseline scenario.

## Creating an experiment

1. Add a scenario builder under `scenarios/` that returns a `ScenarioDefinition`.
2. Set its room bounds, door endpoints, room ability modifiers, and `RuleConfig` switches.
3. Add focused model tests for any behavior that is accepted as stable.
4. Point the view at the scenario while exploring it; do not add scenario-specific rules to `Dungeon.gd`.

Reusable room content belongs in definitions, not graph rules: `RoomDefinition` provides passive capability modifiers and water hazards, while `CollectableDefinition` provides persistent per-scenario rewards.

## Test command

```powershell
& 'C:\Godot\Godot.exe' --headless --path . --script tests/run_tests.gd
```
