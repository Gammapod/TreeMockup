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
  and connectivity. The Boots loop is intended to be completable without
  depending on the Sword Branch.

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
  encounter. There are no cleared-node prerequisites, new enemy movement,
  random health drops or final boss in this slice.

## Sword Branch extension — provisional

The same bundle now includes Spear, Heavy, Sword Landing and Strength Up,
connected as in `Test_Dungeon.mmd`. Spear and Heavy are mutually exclusive;
Sword Landing also has a direct connection from Sword for choosing neither.
New links use automatic doorway placement. The original Sword room remains
unchanged. The user confirmed the branch's abilities and connections are
correct; its encounters, tuning and layouts remain open.

* **Spear:** reach ×1.8, arc ×0.55. Two placeholder bats and pillars are meant
  to encourage reach and deliberate facing.
* **Heavy:** damage ×1.6, reach ×1.2, arc ×1.2, sword cooldown ×3 and rooted
  sword cooldown. A durable and a weaker bat offer a first comparison.
* **Sword Landing:** +5 max HP, a mixed encounter, separate healing and
  clear-revealed Gold.
* **Strength Up:** damage ×1.5, a durable bat and clear-revealed Gold.

These numbers, encounters, geometry and rewards are provisional rather than
balance claims. Spear and Heavy each reveal a separate capacity on clear; the
question of whether visiting both should grant both rewards remains open. The
direct Landing route does not itself add capacity, so accessing Strength may
require later exploration or reallocating. The mini-boss is still a visual
placeholder, and cleared-node prerequisites remain unimplemented. Automatic
doors depend on map positions, so new links can affect existing auto placements.

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

In the user's playtest, refunding Flippers while standing in water pushed the
player to the nearest water edge. The user noted that the player can become
stuck between water and another obstacle, but does not want a general clipping
solution or prevention work at this stage. This is distinct from the Flippers
room itself, where occupied-node protection prevents a normal refund that
removes the occupied node.
