# Door Network Prototype

Open `project.godot` in Godot 4, then run the project (F6/F5). The active experiment is **Combat**.

- Move the yellow player with **WASD**.
- Click an adjacent door to open or close it.
- Collect the West Room key, then keep Sword Room connected while opening the Danger branch.
- **Spacebar** defeats nearby bats in one hit while Sword Room is connected.
- Bats pursue only in their own room, reset when the player leaves, and defeated bats respawn if their room disconnects.
- Each root-connected room grants +1 current and maximum HP. The HUD shows HP and collected gold.

## Testbed

Scenarios are data-driven and the graph simulation is separate from the renderer. See [docs/architecture.md](docs/architecture.md) for the scenario boundary, accepted rule invariants, and the headless test command.
