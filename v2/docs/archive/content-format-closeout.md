# Portable content contract (version 1)

V2's editor save files are UTF-8 JSON, not Godot resources, scripts, scene paths, or serialized runtime objects. The owning boundary is `authoring/content_store.gd`; the gameplay adapter is separate. A project is a self-contained **content bundle**, not a save game. Bundling the room library makes sharing, copying, version control, and atomic saves straightforward. Room templates can also be imported/exported individually as JSON.

## Invariants and test trace

| ID | Contract | Evidence |
| --- | --- | --- |
| C1 | Round trips preserve IDs, unknown fields and extension payloads; editing does not compile runtime state back into source. | `tests/content_tests.gd`: round trip |
| C2 | Syntax/schema/reference errors reject a document without replacing the current editor document or overwriting a saved file. | content tests: invalid references, duplicate IDs, invalid values, failed save |
| C3 | Unsupported versions are rejected explicitly; no guessed migrations or silent version rewriting. | content tests: future version |
| C4 | Node instances of a shared template have independent persistent object identities `(node_id, object_id)`. | existing `run_tests.gd` reward tests; content tests: adapter |
| C5 | Cross-room bindings use stable node/object IDs and resolve without loading the target room. | content tests: bindings |
| C6 | Valid portable data may contain future mechanics; playtest must explicitly reject mechanics this runtime does not implement. | content tests: unsupported mechanic |

`tests/editor_tests.gd` also exercises C1/C2 through the actual editor: placement, template assignment, invalid inspector edits, save/reopen/overwrite, and playtest returning to the retained source document. `tests/content_tests.gd` compiles every shipped example and checks cross-branch water capability changes. The runtime collision policy follows the accepted flippers experiment rather than introducing activation-specific movement logic.

Existing activation/refund/cascade/player-safety invariants remain covered by `tests/run_tests.gd`. The previously accepted playable slice is the behavioral reference; this change replaces its authoring boundary, not its rules.

## Envelope

```json
{
  "format": "room-tree",
  "version": 1,
  "id": "my_scenario",
  "name": "My scenario",
  "rooms": [],
  "dungeon": {
    "root": "start",
    "initial_capacity": 4,
    "nodes": [],
    "links": [],
    "interactions": []
  },
  "extensions": {}
}
```

IDs are nonempty ASCII letters/digits/underscore/hyphen. They are stable authoring identities, not labels or array indices. Room IDs and node IDs each have their own namespace; object and port IDs are local to a template. Link/binding IDs are unique within their respective lists. Rename labels freely; changing an ID requires updating its references. The editor validates rather than guessing reference rewrites.

Rooms contain `id`, `name`, `size: [width, height]`, `ports: [{id, position: [x,y]}]`, and `objects: [{id, kind, position: [x,y], properties: {}}]`. Optional `spawn: [x,y]` sets the initial/recovery spawn (default `[400,400]`). Rectangular objects also have `size: [width,height]` with position at the top-left; circular actors/pickups use center positions. Coordinates are local world units with x right/y down. Runtime currently supports 800×600 rooms; other sizes can be saved but are rejected for playtest until runtime scaling exists. Port names are arbitrary IDs; geometry, not names, places them. Keep spawn and ports in the walkable interior (x 65–735, y 85–555) and clear of solid objects. The editor does not solve room navigation or detect unreachable content.

Optional `clear: {conditions: [...], effects: [...]}` authors ALL-combined objectives
and completion effects. Missing/empty conditions mean cleared immediately, even
for inactive nodes. Conditions: `all_enemies_defeated`, `all_tokens_collected`,
`switch_hit` (with local `object` switch ID). Effects: `reveal_pickup` (with local
pickup/chest `object` ID), `prevent_enemy_respawn`, `become_root`. Referenced objects
must exist with the correct kind; enemy/token objectives require matching objects.
Unknown condition/effect kinds survive storage but block playtest. `token` objects
have a position and empty properties; they never grant persistent currency.
They spawn only in uncleared rooms, reset on uncleared re-entry, and disappear
immediately when the room clears.

Optional `clear.block_tree_editing_until_cleared` is a boolean (default `false`).
When true, occupying this node while uncleared prevents both activation and
deactivation commands. Clearing or leaving the room restores ordinary editing
permissions. This is a runtime build restriction, not a restriction on the F2
authoring studio or on travel.

Clear state is runtime-only, per node instance, and persists until a fresh run.
Root effects waive allocation costs and upstream support and cannot be assigned to
exclusive-group nodes. `dungeon.root` identifies the starting/defeat-return room;
its explicit clear rule must produce an immediate root. For legacy V1 documents
with no `clear` field on that template, the adapter creates an isolated runtime
template copy with an immediate root effect. Other instances and source JSON are
unchanged. New projects and the default branching scenario author the effect
explicitly. This optional V1 vocabulary preserves existing gameplay without a
file-version migration. See the archived [clear contracts and lifecycle](cleared-rooms-closeout.md).

Cleared active roots are fast-travel destinations from any active occupied room,
without requiring a travel path. Arrival uses `spawn`; HP, capacity and allocation
are unchanged. Travel retains normal departure/re-entry encounter/token policies.

Nodes contain `id`, `name`, `template` (room ID), nonnegative integer `cost`, `requires_all` / `requires_any` (node ID arrays), `abilities` (string IDs), and `map_position: [x,y]` (advisory editor coordinates, independent of geometry). Optional `exclusive_group` and `modifiers` describe build constraints/effects. Prerequisites are ongoing, and ALL and ANY clauses are combined with AND. Cyclic prerequisite references are rejected in this first authoring contract; cycles in travel links are permitted.

Links contain `id`, `a`, `b` (node IDs), `a_port`, `b_port`, and `activate_from` (endpoint node IDs). Travel is bidirectional. Each instantiated port has at most one link. Links and prerequisites are deliberately separate.

Interactions contain `id`, `source: {node, object, event}`, and `target: {node, object, action}`. For example `toggled` on a switch can `set_open` on a wall in an unloaded room. Room templates do not contain dungeon-specific node references. Persistent state belongs to node instances, never to shared templates.

## Evolution

- Unknown fields and `extensions` are preserved at every level. Use namespaced keys for experimental metadata.
- Unknown object kinds, ability IDs, modifier names or interaction actions may be stored; the current runtime reports them as unsupported before playtest.
- `version` changes only when the structural/semantic contract changes. Future migrations must be explicit pure `N -> N+1` transformations, retain IDs and extension payloads, and have fixture-based tests. Version 1 is the first version; there is intentionally no invented version-0 migration.
- Saves validate the complete candidate, write a temporary sibling file, then replace the destination by rename. No live-run state enters the document. Keep content under version control for history; this is not a multi-file database.
- Single-template interchange uses `{format: "room-template", version: 1, room: {...}}`. Import rejects duplicate template IDs rather than silently replacing another template.

## Editor workflow

The room editor and tree editor share one bundle in memory. Their JSON inspectors expose the full portable document structures while visual previews make spatial placement and graph structure inspectable. The UI is intentionally provisional; the format is the durable boundary. Apply inspector changes before changing selection, saving or playtesting. Invalid edits remain in the inspector for correction.

`content.schema.json` is a Draft 2020-12 JSON Schema for external tools. Stable-reference resolution, duplicate IDs/ports, root rules and prerequisite-cycle checks are semantic validation performed by the content store, beyond the schema's structural checks.

## Current runtime vocabulary

| Data | Supported values |
| --- | --- |
| Object kinds | `obstacle`, `water`, `wall`, `switch`, `enemy`, `pickup`, `chest`, `token` |
| Enemy properties | `hp` (positive integer, default 2), `speed` (nonnegative, default 95), `radius` (positive, default 14; affects physics, contact, drawing and sword reach) |
| Pickup/chest properties | `kind`: `gold` or `capacity`; `value`: positive integer, default 1 |
| Node abilities | `sword`, `dash`, `flippers` |
| Numeric node modifiers | `move_speed_multiplier`, `sword_range_multiplier`, `sword_damage_bonus`, `dash_speed_multiplier`, `max_hp_bonus` (health/damage bonuses are nonnegative integers) |
| Behavior modifiers | `sword_style`: `big` or `fast`; `dash_style`: `phase` or `run` |
| Scenario health | `dungeon.base_hp`: nonnegative integer, default 5; base plus all immediately active root bonuses must provide at least one HP |
| Interaction | switch `toggled` → wall `set_open` |

Switch state and wall state persist for the run, including through node deactivation. Multiple writers use the most recent event. Water collision is bypassed by flippers. Chests are opened using E rather than walking over them. Node modifiers are aggregated from the active set; multiplier defaults are 1 and bonus defaults are 0. Maximum-HP increases grant the difference in current HP; decreases clamp current HP, and applying an unchanged snapshot never heals. Room loading preserves current HP. Behavior modifiers apply only when their base ability is active. Use exclusive groups to avoid competing styles; if multiple styles are authored active, the last in authored node order wins deterministically. Attacks and dashes capture their parameters at action start.

This vocabulary is the runtime adapter's contract, not a fixed enumeration in the storage schema. Future engines can interpret the same authored data through their own adapter. Activation-funded capacity upgrades and unrecognized behavior variants can be represented but explicitly block playtest until implemented; this avoids presenting a partially interpreted scenario as fully functional. The branching additions are optional vocabulary within version 1; existing files keep their prior default behavior.

## Implementation verification record

The initial C1–C6 tests failed before the content store/adapter existed. The unloaded cross-room interaction test then failed before the coordinator accepted authored data and persisted switch state. Implementing the JSON boundary, adapter and coordinator made those contracts pass. Round-trip comparisons normalize JSON numbers because JSON has one number type while Godot distinguishes integer and floating-point values in containers. Existing progression tests remain unchanged. Editor boundary tests cover source preservation and authored playtests; editor previews were also inspected in rendered screenshots.
