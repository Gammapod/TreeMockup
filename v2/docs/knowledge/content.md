---
type: Content Contract
title: Room-tree content bundles
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

**Accepted door-authoring baseline:** authoring now upgrades opened
bundles to version 2 in memory. See [editor exploration](../editor-exploration.md).
Version 1 remains supported for loading and runtime compilation with its
template-port door representation. Bundle version selects the door
representation, not the capability model: either version can use `legacy`
or `unified_1` under the validation rules below.
V2 links own optional `a_door` / `b_door` placements (`wall`, normalized
`offset`); omission means automatic. Template ports and link port references
are inert legacy metadata in V2. New template exports use version 2; both
versions import. The shared schema describes both versions.

A bundle is UTF-8 JSON with `format: "room-tree"` and `version: 1` or `2`. It is
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
| Node | `id`, `name`, `template`, nonnegative `cost`, ALL/ANY prerequisite ID arrays, `abilities`, and advisory `map_position`; optional exclusive group. Legacy nodes use ability IDs and optional `modifiers`; unified nodes keep `abilities` empty and may use `contributions` instead. |
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
run. Single-room interchange uses `format: "room-template"`, version 1 or 2,
and a `room` object; import rejects duplicate template IDs.

# Current runtime vocabulary

### Unified contributions

An optional dungeon `capability_model: "unified_1"` identifies unified
source. Nodes retain an empty `abilities` array, may not have nonempty legacy
`modifiers`, and may contain `contributions`: entries with stable node-local
`id` and either `{kind:"quality", quality:...}` or
`{kind:"stat", stat:..., op:"add"|"multiply", value:...}`. Supported quality
IDs are `sword`, `dash`, `water_pass`, `sword_root`, `dash_root`, and
`phase_teleport`; stat IDs are `move_speed`, `sword_range`, `sword_arc`,
`sword_damage`, `sword_cooldown`, `dash_distance`, `dash_recharge`, and
`max_hp`. Values must be finite and multipliers strictly positive. IDs cannot
repeat within a node. Contributions require the discriminator.

The editor can store valid source without loss. The normal
`runtime_adapter.compile(document)` path validates and compiles `unified_1`
for Playtest. The optional legacy experimental boolean parameter remains
accepted for compatibility but does not bypass structural, semantic,
vocabulary, root, or overflow validation.

No legacy bundle is automatically migrated to unified contributions. Absent or
explicit `legacy` discriminator keeps the existing legacy runtime semantics,
including legacy `phase`, `fast`, and `run` styles. Mixing nonempty legacy
abilities or modifiers with `unified_1` is rejected rather than reinterpreted.
`new_project()` is legacy by default; `migrate()` upgrades door authoring only,
not the capability model. Any model change is a whole-document editor source
transaction, not an implicit conversion. A legacy candidate containing even an
empty `contributions` field is invalid. Changing model must never silently drop
legacy abilities/modifiers, contributions, or unknown fields.

#### Editor metadata and validation

`content_store.capability_metadata()` returns fresh detached dictionaries:

* `models`: `["legacy", "unified_1"]`;
* `stats[id]`: runtime `base`, `min`, `max`, `requires`, plus `label`, `unit`,
  `operations` (`add`, `multiply`), and `base_source` (`dungeon.base_hp`
  for maximum HP, otherwise `runtime_default`);
* `qualities[id]`: `label` and `requires`;
* `numeric_input`: `add: "finite_signed"`, `multiply: "finite_positive"`;
* `aggregate`: `max_absolute_sum: 1e100`, `max_log_product: 450.0`.

`min` and `max` bound the composed effective stat, **not** a source operand.
`base` for HP is its fallback; use the document's `dungeon.base_hp` if present.
The aggregate limits apply conservatively across the entire document, not a
single row. Metadata is descriptive and is not a validator: stage an isolated
whole-document candidate and use `content_store.validate(candidate)` before a
Frontend-owned atomic history commit. `runtime_adapter.compile(candidate)`
also checks runtime-supported content and may reject a structurally valid source
for Playtest. Preserve unknown fields and pending invalid JSON rather than
reconstructing nodes from the metadata.

For example, after setting `dungeon.capability_model` to `"unified_1"`, a node
may use:

```json
"abilities": [],
"contributions": [
  {"id":"boots","kind":"quality","quality":"dash"},
  {"id":"phase","kind":"quality","quality":"phase_teleport"},
  {"id":"recovery","kind":"quality","quality":"dash_root"},
  {"id":"distance","kind":"stat","stat":"dash_distance","op":"multiply","value":1.2}
]
```

All standard v1/v2 room, node, link and root requirements still apply. The
normal editor can open a validated unified bundle and launch Playtest. This
snippet is not a complete standalone bundle.

For each stat, validation sums absolute additions conservatively across all
nodes (including exclusive nodes), starting with at least 1,000 or base HP,
and rejects a total above `1e100`. It also sums absolute natural logarithms of
all multipliers and rejects a total above 450. These conservative limits bound
intermediate sums and products for any active subset; validation may therefore
reject a bundle whose unreachable combinations would have been safe. Ordinary
floating-point precision and underflow of a final extremely small result still
apply. These checks occur before compilation or allocation.

### Unified progression snapshots

For a validated, compiled `unified_1` runtime definition,
`progression.capabilities()` returns a fresh dictionary with `model`,
`stats`, and `qualities`. It is not a player action snapshot. All eight stat records include
`base`, `additions`, `multiplier`, `raw`, clamped `value`, nullable `effective`,
`requires` (empty or the required `sword`/`dash` quality), `clamped`, `min`,
`max`, and `sources`. `max_hp.value` is floored once and is an integer.
Every quality record includes `granted`, `effective`, `requires`, and `sources`.
Each source is `{node_id, contribution}` with a deep copy of the original
entry. `effective` is null for a stat whose required action is absent; its
`value` and sources remain inspectable. Quality grants union idempotently.

Stats use `(base + sum(additions)) * product(multipliers)` in sorted node-ID
then contribution-ID order, then clamp; HP is floored before clamping. Starting
values are move speed 220, sword reach 92, arc 1.8, damage 1, post-action
cooldown 0.16, dash distance 104, post-action recharge 0.49, and `base_hp`
(default 5). Bounds are respectively 1–2000, 1–1000, 0.01–2π, 0–100000,
0–60, 1–1000, 0–60, and 1–100000.

Successful unified `preview_activation` and `preview_deactivation` results
include `build_before` and `build_after` in addition to `ok`, `reason`, and
`affected`. The after snapshot includes the complete fixed-point refund cascade.
Rejected previews retain their existing failure shape and have no build-after
snapshot. Previews do not mutate state; execution revalidates. These APIs are
not proof that an authored scenario has been playtested.

### Unified action boundary

`runtime/unified_actions.gd` is an action clock connected to a directly
configured Player and Room. The coordinator forwards its events to room-aligned
presentation. It consumes the unified build
snapshot at `start_sword(build, facing)` or `start_dash(build, direction, origin)`
and captures the values needed for the action. A dash requires a nonzero
direction, which is normalized. `advance(delta)` advances the action clock;
action duration is 0.16 seconds, sword hit time is 0.14 seconds, and captured
cooldown/recharge begins after the action. Separate captured movement locks
continue through their corresponding cooldowns. Dash itself can run during a
sword lock. A hit due during Phase absence is suppressed; at an exact shared
arrival/hit time, the arrival intent is emitted first.

The boundary emits copied payloads:

* `attack_due({facing, reach, arc, damage, duration, cooldown, root})`
* `dash_started({origin, direction, distance, destination, duration, recharge, phase, root})`
* `phase_arrival_requested` with the same captured dash fields.
* `restriction_changed({sword, dash, blocked})` on accepted starts and advances;
  numeric fields are captured-lock seconds remaining. `restrictions()` returns
  a fresh dictionary of the same shape, and `phase_absent()` reports transit.

These action-clock signals are scheduling intents, not proof of a hit,
movement, a resolved landing, or a Phase outcome. Callers must not treat
`phase_arrival_requested` as success.

Room exposes informational `resolve_phase_geometry(origin, attempted)`, which
does not move the player or apply damage. It returns a fresh dictionary with
`status` (`landed`, `returned`, or `blocked_return`), `reason` (empty,
`boundary`, or `blocked_destination`), `origin`, `attempted`, and `position`
(destination, origin, or null). It reads the current player circle radius,
wall state and water-passage capability. It uses a 0.01-unit collision margin;
touching the margin is invalid, including at corners. A full player-circle
path must remain strictly within room bounds, even through open doors.
`blocked_return` from this geometry method alone is not an emitted defeat.

The coordinator's copied tree state includes `current_build`, independently of
the selected node's previews. It has the same shape as the current progression
capability snapshot (legacy for legacy runs, unified for unified definitions).
The normal Playtest path compiles unified source through the same validation.

`player.gd` is configured with the current unified build in unified runs. It
captures action values through the unified action clock, executes an ordinary
dash at captured distance over the fixed duration, and forwards copied
`unified_restriction_changed(state)`, `unified_dash_started(attempt)`, and
`phase_arrival_requested(attempt)` signals. These are Player-local intents,
not presentation events. Room consumes Phase arrivals synchronously, checks
current geometry and water passage, moves to a valid landing or return,
and applies ordinary endpoint contact and guardian-wave damage. The absent
player cannot collect, interact, take spatial damage, or consume a guardian
wave. A teleport does not sweep the intervening path. A blocked return emits
the outcome before requesting guarded defeat.

Room and coordinator expose `phase_started(attempt)`,
`restriction_changed(state)`, and `phase_outcome(outcome)`. Payloads are
copied. The start payload is the dash attempt above. Restriction state is
`{sword, dash, blocked}` in seconds. Outcome is `{status, reason, origin,
attempted, position, contact_damage, wave_damage}`; positions are room-local
Vector2 values and damage fields report actual HP lost. The coordinator
forwards only current-generation events when no transition is pending.
A committed transition cancels an outstanding Phase without emitting an
arrival outcome, restores presence at the origin, and retains its captured
recharge. The coordinator signal is a presentation hook, not a listener or
world-space cue; Frontend owns that presentation. The coordinator mounts the
feedback component in the room viewport, resets it on room replacement, and
retains a blocked-return defeat explanation in the post-transition status.

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

### Health pickups

Both bundle versions support the following room object (coordinates are local):

```json
{"id":"medicine","kind":"pickup","position":[400,400],"properties":{"kind":"health","value":3}}
```

`properties.value` is a finite positive integer, defaulting to 1, and is
validated by the runtime adapter; the store and structural schema preserve
unknown vocabulary. `chest` with the same properties is also supported and
uses the ordinary E-key chest interaction. A visible pickup heals a living
player by that fixed amount, capped at current maximum HP. It is not collected
at full HP; it remains available for a later visit or interaction. Clear
`reveal_pickup` rules apply normally. Collection is once per node/object for
the run, survives room departure, deactivation and defeat, and resets on a
fresh run. It grants neither gold nor capacity. There are no random drops.
Increasing maximum HP remains non-healing.

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
