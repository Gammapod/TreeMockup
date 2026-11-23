# Boots and Sword branches — first sketch

**Status:** proposed for discussion, not validated or playtested. Extends the
separate tutorial candidate; preserves the original exploratory dungeon and
tutorial baseline. Each named node is one room and costs 1 capacity. The
diagrams show physical links, not prerequisite arrows.

## Shared junction and budget

The cleared Sword tutorial room is the junction. Its revealed capacity point
brings total capacity to 3: Key Storage and Sword normally cost 2, leaving 1
to start either branch. Each branch proposes one additional capacity pickup,
revealed by a clear in its deeper room. With both rewards, total capacity is
5. Across the two branches alone there are 10 points of authored costs; even
without counting the tutorial nodes, all ten cannot be active at once. Each
branch also has an explicit exclusive pair.

This is a budget hypothesis, not a proof of access. Trace local activation,
physical paths, rewards, refunds and cascades in the assembled candidate.
In particular, a cost-1 entry followed by cost-1 deeper rooms leaves no free
point to go deeper on the initial three-point budget while retaining both
tutorial nodes. The sketch requires an additional accessible funding source
or an intentional refund/reallocation route before either branch can be
completed; do not build it as-is and assume it is playable.

## Boots Branch — movement under pressure

```text
                    Quick Step ──┐
Sword trial ─ Boots ┤            ├── Pursuit
                    Long Dash ───┘
                    └── Phase Dash  (linked to Boots)
```

The intended links are Boots–Quick Step, Boots–Long Dash,
Quick Step–Pursuit, Long Dash–Pursuit and Boots–Phase Dash. Quick Step and
Long Dash are mutually exclusive; Pursuit is reachable from either. Five
branch rooms total. No prerequisite is implied by the drawing beyond local
activation and normal root connectivity.

| Node / room | Ability or role | Intended lesson |
| --- | --- | --- |
| Boots | Grants Dash. An open room with a few well-spaced enemies. | Learn the basic burst without requiring precise timing. |
| Quick Step | Shorter distance, faster recharge; `distance ×0.75`, `cooldown ×0.7`. | Repeated short repositioning around a central obstacle and enemies. |
| Long Dash | Longer distance, slower recharge; `distance ×1.4`, `cooldown ×1.4`. | Cross an exposed lane quickly; the recharge makes a second immediate move less available. |
| Pursuit | No ability proposed yet; clear reveals 1 capacity. | Revisit the movement choice in a more open encounter; both routes must work. |
| Phase Dash | Contact immunity during dash, distance ×0.65. | A visible enemy approach creates an opportunity to pass through contact safely; walls still block dash. |

Quick Step and Long Dash should feel distinct, not just different in a stats
panel. Movement challenges are encouraging tests, not claims that dashing is
required. Existing bats alone may not create readable timing or reward these
differences; choose and validate encounters after the movement/enemy collision
work, rather than inventing a hazard.

## Sword Branch — shape versus power

```text
                       Thrust ───┐
Sword trial ─ Armory ┤           ├── Proving Room
                       Sweep ────┘
                       └── Power  (linked to Armory)
```

The intended links are Armory–Thrust, Armory–Sweep, Thrust–Proving Room,
Sweep–Proving Room and Armory–Power. Thrust and Sweep are mutually exclusive;
Proving Room is reachable from either. Five branch rooms total.

| Node / room | Ability or role | Intended lesson |
| --- | --- | --- |
| Armory | No modifier selected yet; a simple encounter. | Introduce the branch and show both nearby choices. Its cost needs a clear benefit before this becomes a playable design. |
| Thrust | Longer reach, narrower arc; `range ×1.3`, `arc ×0.7`. | A separated enemy or exposed approach lets reach help while narrow coverage matters against a second threat. |
| Sweep | Wider arc, lower damage; `arc ×1.5`, `damage ×0.75`. | A small group makes coverage easy to see; lower damage is a cost against a tougher target. |
| Proving Room | No modifier proposed yet; clear reveals 1 capacity. | A mixed encounter offers either style something to handle. |
| Power | Proposed `damage ×1.5`, `cooldown ×1.3`; numbers untested. | A high-health enemy makes damage visible; a slower attack interval is the tradeoff. |

Sword attacks start no faster than their action duration. The proposed Power
node must use a cooldown multiplier greater than 1 to slow attacks; exact
values and enemy HP require testing. Avoid claiming that a particular modifier
is necessary to clear its room.

## Design issues before implementation

1. **Funding:** choose how the player gets enough capacity to reach the first
   deeper node without forcing an unexplained, undesirable refund. An extra
   early reward or revised node costs are competing options; test the budget
   globally, including cross-branch spending.
2. **Meaningful entry nodes:** Armory and Pursuit/Proving Room currently have
   no build benefit. Decide whether their cost is justified, grant appropriate
   benefits, or use free connector rooms without accidentally weakening the
   intended budget.
3. **Local alternatives:** exclusive selection and refunds must remain
   possible from sensible physical locations; the player must not strand
   themselves in a dependent room. Check how changing either fork affects
   support for its merge.
4. **Current prototype prerequisites:** tutorial candidate explicitly makes
   Sword require Key Storage and its provisional branches require Sword.
   Revisit these when building the combined candidate, consistent with the
   preference for physical links over single prerequisites.
5. **Room count:** three tutorial rooms plus these ten rooms gives 13 nodes,
   before the mini-boss, final boss and larger-dungeon connections.
6. **Evidence:** engine validation and route checks precede user playtesting;
   enjoyable build distinctions and pacing require the latter.
