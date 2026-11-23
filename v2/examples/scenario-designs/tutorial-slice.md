# Tutorial slice — ready for playtest

Source: `Test_Dungeon.mmd`. This is a small, separate candidate, not a
replacement for `Test_Dungeon.json` or a completed dungeon.
Playable bundle: `../tutorial_candidate.json`. Dash and Flippers are
provisional branch endpoints, not a completed dungeon.

## Player journey

1. Start with 1 total capacity and 1 current/maximum HP. Activate Key Storage
   for 1 point to open the first door. Key Storage grants +4 maximum HP, not
   healing.
2. In Key Storage, collect a capacity upgrade and a healing pickup. Activate
   Sword for 1 point; its sword is available immediately, before entry. Use it
   on a visible switch to open the wall covering the Sword doorway.
3. In Sword, defeat two bats. Clearing reveals another capacity pickup.
4. That point permits one of two prospective branch nodes. These are tutorial
   endpoints for comparison, not a claim that the wider dungeon is complete.

## Constraints to verify

* Check the physical doorway, switch line of attack, switch/wall binding,
  arrival positions, and reward collection in the compiled scenario.
* A one-point budget after the second reward cannot fund both cost-one
  branches while retaining Key Storage and Sword. Protect the intended sword
  dependency and test refund/cascade and occupied-room safety.
* Healing is a separate pickup; max-HP allocation must not heal. Check pickup
  lifecycle and behavior at full health against the implemented contract.
* A clear-revealed reward should remain obtainable after retreat, re-entry, or
  reallocation, without duplication.
* Check what happens on defeat and retry; do not assume a fresh run or healing.
* The branch rooms and benefits are provisional. User playtesting determines
  whether the lessons and first choice are legible and enjoyable.

## Technical evidence and open question

Engine-Owner reports that the bundle validates and compiles, and that its
scenario suite passes 25 assertions; the full structured regression run passed
21/21 suites (`v2/test-results/20261120T193503.442435Z/report.json`). A
player-radius grid check and collision test support the gate route, but do not
prove every possible continuous route. No user playtest has been recorded.

After collecting medicine, refunding Key Storage clamps HP to 1; reallocating
it does not heal and the medicine remains spent. Defeat with Key Storage active
returns the player to Start at full active-build HP. Whether this recovery
friction needs another remedy is a playtest question; do not assume that a
second one-use pickup solves repeatable recovery.
