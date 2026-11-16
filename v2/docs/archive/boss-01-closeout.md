# BOSS-01 closeout — 2026-11-16

**Completed; accepted as the capstone baseline for larger-dungeon design.**
The user considers the fight suitable to build around, with substantial room
for tuning and presentation polish. This acceptance does not establish final
balance or demonstrate that every build is equally viable.

## Architectural review

| Boundary | Finding / decision |
| --- | --- |
| Content → runtime | `enemy.properties.behavior` selects `chase` or `roost_guardian`; unknown values reject compilation. HP, speed, radius and spawn remain authored values. Guardian radius validation keeps wave duration positive. |
| Guardian → room | `roost_guardian.gd` owns its phase clock, tethered movement, locked gap, swept wave geometry and presentation. It emits wave-hit/summon intents. The shared enemy record remains room-owned; the controller reads HP without maintaining a competing health value. |
| Room → player | Room resolves contact and wave damage through `player.hurt`. Phase immunity applies only to contact; ordinary post-hit invulnerability still applies to both. A wave consumes its collision opportunity once, even when ordinary invulnerability prevents health loss. |
| Summons → progression | Summons are transient room enemies tagged with their owner. They never enter the persistent defeated ledger or authored clear objectives. Boss death removes its controller/summons before emitting its normal defeat event. Stable attack iteration tolerates that batch removal. |
| Encounter → lifecycle | Room drives the controller; editor pause therefore pauses the encounter. Destroying the room destroys its controller and summons, with no independent timers to survive unloading. Trial restart uses the existing generation-guarded fresh-run path, preserving the selected build. |
| Ordinary travel → trial restart | Ordinary departure resets surviving enemy health/behavior on re-entry and retains authored defeated IDs while the node remains active. A cleared boss stays defeated until normal encounter reset rules permit respawn. Explicit trial restart resets encounters and clears as a fresh run. |

**Disposition:** no blocking architectural findings within the current
single-boss, open-arena scope. No runtime refactor was required for this closeout.

## Constraints to carry into dungeon design

* This is one concrete boss preset, not a general encounter scripting system.
  Its arena center, summon points, wave extent, phase durations and tether are
  local constants. Repositioning the boss or adding interior hazards requires
  revisiting those assumptions and the walking-route checks.
* The 560-unit wave extent also appears in adapter validation; the 13-unit
  player radius is shared by convention with player/contact geometry. Change
  these together if the corresponding geometry becomes configurable.
* Summon count is enforced by both controller intent and room admission.
  Any change to the three-bat cap must update both sides.
* Controller state and rendering can remain together at this scale. Extract
  reusable definitions or presentation components when a second encounter or
  concrete authoring need justifies them.
* The arena's build-preserving retry remains fixture-specific. Dungeon roots,
  boss rewards and checkpoint rules should use the existing progression and
  lifecycle owners rather than inheriting workshop retry behavior implicitly.

## Verification

`tests/boss_tests.gd` traces A1/E1/E2: behavior validation, tether/cycle,
telegraph locking, fractional boss damage, wave collision along movement,
contact-vs-wave immunity, once-per-wave collision, recovery, warned/capped
summons, boss death/clear, and fresh-trial reset. It also samples ordinary
walking escape paths across room positions and tether offsets. These samples
support the current dry arena; they are not proof for arbitrary future layouts.

`tests/arena_tests.gd` covers free boss access alongside full builds and the
shared restart/editor boundary. Existing progression, room, content and
hardening suites cover surrounding contracts.

All 15 headless suites pass at closeout. Prior rendered review covered
telegraph, wave, recovery and summon warnings. Initial implementation red
phases reproduced missing Boss Trial content and invalid guardian radius
acceptance; the final architecture review introduced no changed invariants.

## Handoff

* Current play instructions: [README](../../README.md#boss-01-roost-guardian-trial).
* Accepted behavior vocabulary: [content contract](../knowledge/content.md#boss-01-enemy-behavior).
* Experiment decision: [BOSS-01](../knowledge/experiments.md#boss-01--tethered-roost-guardian-2026-11-15).
* Next session: design the interconnected 14–18-node dungeon around this
  capstone, using the accepted stackable ability system. Keep encounter
  tuning and visual polish as follow-up tasks rather than reopening the
  baseline implementation by default.
