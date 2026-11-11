# Door Network Prototype

Open `project.godot` in Godot 4, then run the project (F6/F5).

- Move the yellow player with **WASD**.
- Click any door to open or close it.
- The map contains Starting Room plus Rooms A–D. The cyan overlay is the open-door graph rooted at Starting Room.
- Open doors form a loop-free tree rooted at Starting Room. A closed door is openable only when exactly one endpoint is root-connected. Closing a root-side door automatically closes all now-disconnected doors in its branch.
- At most **one** door can be open at a time.
- The player may operate a door only while standing in one of the two rooms it connects.
- Root-connected rooms grant abilities: Room A doubles movement speed; Room B enables a blue **Spacebar** flash; Room C adds 1 open-door slot; Room D adds 2 open-door slots. Starting Room always provides movement and one open-door slot.

## Testbed

The baseline dungeon is a data-driven scenario and the graph simulation is separate from the renderer. See [docs/architecture.md](docs/architecture.md) for the scenario boundary, accepted rule invariants, and the headless test command.
- An open door is **Propped Open** while closing it would disconnect the player from Starting Room. It becomes closable again when the player returns to the root-side of that door.
