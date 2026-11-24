# Unified tutorial + Boots Branch — candidate

**Status:** user playtested and revised; a promising foundation, not a
completed or accepted dungeon. Bundle: `../unified_tutorial_boots.json`. The legacy
`../tutorial_candidate.json` and exploratory `../Test_Dungeon.json` are
preserved. Design intent comes from `Test_Dungeon.mmd`.

## Intended direction to retain if playtesting supports it

* Begin with 1 HP and 1 capacity, spend it on Key Storage, collect healing and
  capacity, activate Sword, use it on the switch, then clear the Sword trial.
* After collecting the Sword reward and activating Boots, enter Boots Room with
  no unspent capacity. Its accessible capacity chest funds one of two mutually
  exclusive movement options.
* Each option's clear-revealed capacity can fund Boots Landing. Quick Step can
  reach the landing and return to the far side of the Boots Room gate; Phase
  can instead cross the narrow gate directly. The switch toggles the gate.
* Boots Room uses visit-local tokens; one is behind the gate. The two option
  rewards are separate and can both eventually be collected by reallocating.
* Physical links, rather than single-node prerequisites, constrain activation
  and connectivity. The branch is independent of the unfinished Sword Branch.

## Provisional content to assess

* All room geometry, doors and encounter placements may change. The Phase room
  has a walk-around narrow wall and token exercise; Quick Step uses two bats
  around a center obstacle. These are encouragements, not enforced uses.
* Quick Step (`distance ×1.4`, `recharge ×0.7`) and Speed Up (`speed +12`)
  are deliberately untuned. Phase grants teleport and dash-root qualities.
  Landing adds 5 max HP; its separate health pickup can heal.
* A **temporary clear-revealed capacity pickup in Boots Landing** funds either
  Speed Up or Flippers so both endpoints can be explored by reallocating in
  this standalone candidate. It is a funding aid, not a final placement. Gold
  rewards in Boots Room and both endpoints are placeholders for later budgeting.
* Speed and Flippers are optional trial endpoints, not a completed continuation.
  The user added a visually placed, cost-1000 mini-boss placeholder, not an
  encounter. There is no Sword Branch, cleared-node prerequisite, new enemy
  movement, random health drops or final boss in this slice.

## User playtest and revisions

The user found the abilities and connectivity match the design. Start's pillars
and Key Storage's lessons are good; Sword remains a functional placeholder.
Boots Crossroads' blocked door is its defining feature, while collectibles may
change. Quick Step, Phase and Speed work for now but need greater visual and
encounter distinction; the Phase room's thin wall is useful.

The user rearranged the map, reset most doors to automatic, added a miniboss
placeholder, placed water over the Flippers doorway in Landing, and filled the
Flippers room with water to teach that ability. These are authored changes to
preserve and evaluate, not claims that every revised route has been validated.

## Checks and playtest questions

Use playtesting to explore funding, movement paths, doors, the shortcut,
objectives, rewards, exclusivity/refunds and safe return. Automated scenario
checks are not a prerequisite for iteration or a proof of enjoyable level design.
Ask the user whether the first allocation and switch teach their intended
lessons, whether Phase and Quick Step feel distinct, whether the returning
shortcut is recognizable, and which placeholder encounters/rewards are worth
keeping. Check whether the temporary landing point provides too much flexibility
after collecting both mutually exclusive route rewards.

## Technical evidence

Before the user's map, doorway and water edits, Engine's candidate suite passed
169 assertions and the full Engine run passed
20/20 suites (`v2/test-results/20261124T001846.264086Z/report.json`). Checks
include allocation/refund funding, both route rewards, actual Phase and Quick
actions, token reset/clear, the gate/switch, optional endpoints and controlled
collision-checked routes. The route test uses scripted setup and freezes room
processing between controlled actions; it does not establish real-time combat
difficulty, continuous player-input handling or enjoyable pacing. Those checks
do not establish reachability of the subsequently revised geometry.

After the user's edits, the store accepted and adapter compiled the source,
but the old candidate suite passed 77/81 assertions: two old doorway checks
assumed water was always solid, and two route checks assumed the former west
Quick doorway. The early return prevented later physical-route checks. The user
does not want deterministic level-design validation to gate this experimental
dungeon's iteration.

In Landing, Flippers can currently be refunded while standing in water; water
then becomes solid under the player. Exact physical recovery was not tested.
This is distinct from the Flippers room itself, where occupied-node protection
prevents a normal refund that removes the occupied node. Root travel is a
model-supported escape, not proof of an unobstructed walking route.
