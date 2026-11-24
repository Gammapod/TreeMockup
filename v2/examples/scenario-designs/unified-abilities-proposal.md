# Unified ability contributions — proposal for review

**Status:** user and Engine-Owner approved the clarified contract for a scoped
first experiment; Frontend-Owner reviewed the revised failure feedback. This
is an accepted experimental design, not a claim that runtime support exists.
This proposal is not a request to implement every possible capability.

## Goal and scope

Make base actions, traversal qualities and modifications authorable as one
typed collection of node contributions. A node may grant Sword, grant water
passage, and modify Dash without granting Dash. Use Sword, Dash, Flippers,
Quick Step, Heavy and a new teleport-like Phase Dash as concrete design cases.
Keep mini-boss clear prerequisites as a separate progression change.

## Composition

* Each of the eight registered numeric properties has additive and
  multiplicative contributions, units and bounds. Proposed composition:
  `clamp((base + sum(additions)) * product(multipliers))`. Source order must
  not change the result. Signed additions, rounding and bounds remain open.
* Enabled-only qualities combine by set union. Duplicate contributions have
  the same effect as one; absence means not enabled. No contribution disables
  a quality granted elsewhere.
* Action-specific contributions remain in the build but are dormant unless the
  base action is enabled. Adding or refunding the action changes their
  effectiveness without granting an action implicitly. Water passage is
  independent of Sword and Dash.
* Avoid conflicting qualities. If a real conflict is unavoidable, explicitly
  define and validate its resolution; never let node order decide.
* Max-HP increases do not heal; reductions clamp current HP.

## Concrete property inventory

This is the proposed initial scope, not an approved schema. Each property
accepts additive and multiplicative contributions. Sword and Dash effects are
dormant without their respective action.

| Property | Units / proposed behavior |
| --- | --- |
| Movement speed | World units per second |
| Sword reach | World units |
| Sword arc | Radians; cap at a full circle proposed |
| Sword damage | Damage per hit; fractional damage supported |
| Sword cooldown | Seconds after the attack ends |
| Dash distance | World units; does not alter fixed action duration |
| Dash recharge | Seconds after the dash ends |
| Maximum HP | Integer HP; no healing on increase, clamp on decrease |

Dash speed is no longer a separately authored stat: normal dash speed follows
from distance divided by fixed duration. Both dash forms use the same fixed
duration. As untested cadence-preserving starting points, Engine suggests a
0.16-second fixed action with 0.49-second dash recharge and 0.16-second sword
cooldown; these are not accepted tuning. Old dash-distance and cooldown
modifiers have different semantics and must not be silently reinterpreted.

| Proposed enabled-only quality | Requires action? | Meaning and status |
| --- | --- | --- |
| Sword attack enabled | No | Grants Sword; corresponds to existing base ability. |
| Dash enabled | No | Grants Dash; corresponds to existing base ability. |
| Water passage | No | Allows ordinary water traversal; corresponds to Flippers. |
| Sword cooldown movement restriction | Sword | Restricts ordinary movement from attack start through cooldown end; Dash can move without ending it. |
| Dash cooldown movement restriction | Dash | Restricts ordinary movement from dash start through recharge end; the dash itself can move. |
| Phase teleport | Dash | Proposed teleport through interior obstacles; not the current Phase style. |

The above list does not include an implicit disable operation or a generic
priority system. A Heavy node combines numeric sword contributions and the
sword restriction; a Phase node combines teleport and the dash restriction.
There is no separate dash enemy-contact immunity quality in this initial model.

The user intends to retire the old multi-strike sword style and hold-to-run
mode; replacements can be considered later. Old styles require actionable
rejection or explicitly chosen migration, not silent approximation. Numeric
overflow, deterministic aggregation and final bounds need explicit definitions.

### Illustrative contributions, not source syntax

| Node | Contributions | Intended result |
| --- | --- | --- |
| Sword | Enable Sword attack | Grants the action. |
| Boots | Enable Dash | Grants the action. |
| Flippers | Enable water passage | Traverses water without granting an attack. |
| Quick Step | Multiply dash distance and recharge | Modifies Dash only when Dash exists. Values and tradeoffs remain to tune. |
| Heavy | Multiply sword damage, reach, arc and post-action cooldown; enable sword-cooldown movement restriction | Stronger, slower attack with a positional commitment; exact tuning remains open. |
| Phase Dash | Enable phase teleport and dash-cooldown movement restriction | Modifies Dash without granting it; wall/water traversal and recovery rules below. |
| Mixed example | Enable Sword and water passage; multiply dash recharge; enable sword-cooldown movement restriction | Grants Sword and water passage, but does not grant Dash. |

Names, units and representation require Engine review.

## Authority and action timing

Progression composes active node contributions into an authoritative capability
snapshot. UI inspects that snapshot and sends intents; it never composes or
changes gameplay state. Player action handling captures effective parameters at
accepted action start. Room geometry resolves movement and teleport destination
against current authoritative state. Action duration, cooldown and movement
restriction are distinct concepts; action snapshots remain stable if the build
changes during an action.

Movement restriction does not itself prohibit attacks, interaction, Dash or
travel. A dash may move through a sword restriction without ending it or the
sword cooldown. It does not cancel a pending sword hit, but a hit due during
Phase absence is suppressed. Independent restrictions combine: ordinary
movement is allowed only after all have expired. Other action eligibility
continues to be validated separately.

## Proposed Phase Dash experiment

* Teleport to one destination at the captured dash distance; do not infer a
  safe nearer destination. Cross interior walls and water on the way. A narrow
  switch-controlled wall is a valid shortcut; room boundaries remain
  authoritative and the teleport does not travel through doors.
* A phase attempt can start even if the destination is invalid. At arrival,
  check the player's full collision shape against current geometry. If the
  destination is invalid, return to the starting place, start recharge, and
  visually indicate the attempted destination. Landing on an enemy is allowed.
  This supersedes the earlier no-cooldown-on-failure proposal.
* If both the destination and return origin are invalid at arrival, the player
  dies via the ordinary guarded defeat lifecycle. This exceptional rule does
  not define the separate case of refunding water passage while standing in water.
  Check both against current geometry and current water-passage capability.
  Crossing a room boundary invalidates the attempt even if its endpoint is inside.
* Landing in water requires water passage; a wall or out-of-room destination
  is invalid. Check the whole path against room boundaries, including door
  openings, not only the destination. Multiple interior obstacles can be crossed.
* Normal and phase dashes have the same fixed action duration. During Phase
  transit the player is absent from contact and spatial damage and does not
  sweep the intervening space. Landing on an enemy applies ordinary contact
  damage immediately, including ordinary existing invulnerability rules.
  Damage already resolved before departure remains applied. Return to origin
  follows the same contact rules.
* Dash movement restriction, when enabled, lasts from dash start through
  recharge end, including on a failed arrival; the dash itself can move.
* Capture direction, distance, duration, recharge and restriction at action
  start; revalidate geometry and water passage at arrival. Travel, defeat,
  restart or room replacement invalidates any outstanding arrival. A sword hit
  already due in the same simulation step resolves before dash acceptance;
  later hits due during Phase absence are suppressed.
* A single teleport cannot cross an obstacle thicker than the usable distance
  while landing beyond it. Test narrow and thick geometry, corners, multiple
  obstacles, enemy overlap and boundary/door cases.

## Content lifecycle and presentation

Use an unambiguous versioned or otherwise explicitly discriminated authoring
contract, with semantic validation and actionable unsupported-vocabulary
errors. Do not silently reinterpret legacy styles, especially old Phase Dash
as teleport. The user permits older workshop dungeons to break or retire;
preserve source non-destructively where practical and decide migration versus
explicit rejection per behavior. Avoid letting legacy compatibility dictate
the new design.

Frontend input is needed on authoring typed contributions and explaining
effective versus dormant effects, cooldown restriction, teleport outcomes,
and failed attempts. The authoritative snapshot, preview and intent contracts
must be agreed with Engine before dependent interaction is implemented.

### Frontend review: minimum presentation proposal

* Show each selected node's contributions grouped by ability, explicitly
  distinguishing a granted action from a modifier that is **dormant because
  its action is absent**. Use text and symbols, not color alone.
* Show current effective values and qualities; allow sources and any applied
  caps to be inspected without making stacking math the default view.
  Activation/refund previews must come from Engine and include effects becoming
  effective or dormant, alongside existing cascade information.
* Present cooldown movement restrictions by cause and remaining time without
  implying a full stun. Show Phase absence without implying a physical sweep.
  On invalid arrival, mark the attempted destination, show the return and
  recharge, and distinguish restriction from full stun. Any destination
  preview is informational and execution is revalidated.
* Distinguish exceptional blocked-return defeat from an ordinary return,
  without delaying the guarded defeat lifecycle. Make ordinary contact damage
  on arrival or return readable separately from a failed teleport.
* The editor should offer a registered contribution list with permitted
  operations, units and bounds, plain-language summaries, row-level validation
  and preserved unknown source. Retain validated transactions, undo/redo and
  JSON access. A general build simulator is not required for the first slice.
* These views depend on authoritative identifiers, labels, source and dormant
  details, before/after previews, restriction state, attempt outcomes and
  authoring metadata. Room/player drawing needs an explicit integration for
  world-space cues; Frontend must not duplicate geometry or action rules.

## Acceptance and evidence

Before implementation, obtain Engine-Owner approval of technical integrity,
Frontend-Owner input on legibility and authoring, and user approval of rules
and tradeoffs. Then test composition, validation, dormancy and refunds,
mid-action snapshot stability, max HP, root/cooldown interactions, and
teleport geometry and failure. Run a small playable Phase Dash comparison and
request a user playtest; technical checks do not prove the behavior feels good.

## Scoped engineering defaults

Engine-Owner approved using the full player collision shape with a 0.01-world-unit
safety margin; tangency within that margin is invalid. Check the whole path
against room boundaries, including doors. Interior obstacles may be crossed.
Stable node-ID/contribution-ID ordering, finite signed additions, finite positive
multipliers and final clamping define numeric composition. Floor composed HP
once before clamping. Validate bounded inputs and conservative aggregate
overflow before playtest, with actionable errors.

| Stat | Final range |
| --- | --- |
| Movement speed | 1–2,000 units/s |
| Sword reach | 1–1,000 units |
| Sword arc | 0.01–2π radians |
| Sword damage | 0–100,000 |
| Sword cooldown | 0–60 s |
| Dash distance | 1–1,000 units |
| Dash recharge | 0–60 s |
| Maximum HP | 1–100,000 integer HP |

These are engineering safety limits, not balance targets. Source must use an
explicit discriminator; preserve old source and translate only behaviors proven
exact, otherwise reject playtest with actionable node-specific diagnostics.
Never silently map legacy Phase to teleport. Retire old multi-strike and run.

## Remaining scope choices

1. Which existing styles are migrated exactly, explicitly rejected, or
   intentionally retired? Decide based on cost and user priorities, never
   by silently converting to a different behavior.
2. Removing water passage while occupying water is deferred; identify any
   immediate safety dependency without expanding this change into that system.
