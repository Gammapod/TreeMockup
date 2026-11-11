# Door Network Prototype

Open `project.godot` in Godot 4, then run the project (F6/F5). The active experiment is **Water & Flippers**.

- Move the yellow player with **WASD**.
- Click an adjacent door to open or close it.
- Connect Water Room and Flippers Room, then cross Water Room's blue strip to reach Prize Room and collect its gold.
- Each root-connected room grants +1 current and maximum HP. The HUD shows HP and collected gold.
- This scenario uses a three-door capacity so Water, Flippers, and Prize can remain connected simultaneously.

## Testbed

Scenarios are data-driven and the graph simulation is separate from the renderer. See [docs/architecture.md](docs/architecture.md) for the scenario boundary, accepted rule invariants, and the headless test command.
