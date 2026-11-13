# Branching dungeon implementation

Source: `examples/scenario-designs/branching-dungeon.mmd`, with ability/enemy definitions from the adjacent glossary.

## Mapping

- 14 nodes, 18 links, one starting allocation point. Each non-root room costs one.
- Existing stable IDs `sword`, `boots`, and `prize` correspond to Mermaid `sword_room`, `boots_room`, and `final_branch`. The JSON records these aliases.
- Neutral edges allow activation from either endpoint. Directed edges allow activation only from their source; travel remains bidirectional.
- Each landing has an ongoing ANY prerequisite across its three styles. Prize has an ongoing ALL prerequisite across both landings.
- Style groups are mutually exclusive, following the earlier branching scenario and agreed experiment. Removing a style removes its landing and Prize unless their requirements remain satisfied. Occupancy protection still applies.
- Sword and Boots each contain two permanent capacity pickups. Both landings contain one each. Prize contains only its coin. Practice rooms contain one bat; big-swing/hit-dash rooms ten; HP rooms three; fast-swing/run rooms one big bat.
- Bats have one HP and move at 110 units/s (half the default player speed). Big bats have three HP and double radius (28 instead of 14).
- Big Swing: 1.5× sword reach, two-second cooldown measured from activation. Fast Swing: half reach, three strikes at 0.14/0.22/0.30 seconds, then recovery through 0.48 seconds.
- Hit Dash uses the glossary's **big dash** definition: half distance, no enemy-contact damage during the dash; it does not damage enemies. Run replaces dash with double movement speed while Shift is held. These modifiers require Boots.
- Starting Room grants one current/max HP; each practice room one; each HP+ room five; Prize one. Other rooms grant no HP. The scenario sets base HP to zero so the initial total is exactly one. Activation increases current/max HP; deactivation clamps current HP. This deliberately permits healing through reallocation, as in the diagram; it is not a separate healing-on-entry effect.
- Gameplay controls retain V2's Space/Shift bindings. Template port locations are authored for readable transitions; map coordinates do not enforce a globally packed dungeon.

## Verification trace

`tests/branching_tests.gd` covers:

- **B1:** node/link counts, initial budget, room contents and a funded golden path using all six keys.
- **B2:** alternate-style landing support, continuous Prize prerequisites, exclusive styles, cascade refunds and occupied-room protection.
- **B3:** max/current HP changes without refresh/transition healing, actual big-bat physics size, triple strike/action snapshots, big-sword cooldown, phase-dash contact protection and held sprint.

The new tests first failed against the six-room demo's topology and starting budget. The authored scenario and runtime additions make them pass. Existing activation tests retain their original six-room reference in `tests/fixtures/activation_fixture.gd`, rather than silently adopting the new scenario's rules. Content and editor suites continue to validate the expanded default bundle and playtest boundary.
