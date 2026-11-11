# Door Network Prototype

Open `project.godot` in Godot 4, then run the project (F6/F5). The active experiment is **Switch & Wall**.

- Move the yellow player with **WASD**.
- Click an adjacent door to open or close it.
- Collect the Fork and Wall keys to permanently gain enough door capacity for the branch puzzle.
- Keep Sword Room connected to activate **Spacebar** sword swings, then toggle the switch in Switch Room.
- The switch makes Wall Room's barrier passable, allowing access to Prize.
- Each root-connected room grants +1 current and maximum HP. The HUD shows HP and collected gold.

## Testbed

Scenarios are data-driven and the graph simulation is separate from the renderer. See [docs/architecture.md](docs/architecture.md) for the scenario boundary, accepted rule invariants, and the headless test command.
