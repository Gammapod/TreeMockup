---
type: Scenario Reference
title: Branching dungeon regression scenario
description: Design intent and test-relevant mapping for the default 14-node branching experiment.
tags: [v2, scenario, branching, regression]
status: stable
generated: { by: "openai/gpt-5.6-terra", at: 2026-11-15T00:00:00Z }
sources:
  - { resource: ../../examples/branching.json, title: Playable scenario }
  - { resource: ../../examples/scenario-designs/branching-dungeon.mmd, title: Scenario diagram }
  - { resource: ../../tests/branching_tests.gd, title: Branching scenario test trace }
  - { resource: ../archive/branching-design-closeout.md, title: Archived implementation closeout }
---

# Purpose

`examples/branching.json` is the default playable regression scenario for
“the dungeon is also a skill tree.” It has 14 nodes, 18 links, one starting
allocation point, and one cost per non-root room.

# Mapping

* `sword`, `boots`, and `prize` are stable JSON aliases for the diagram's
  corresponding rooms. Neutral links allow activation from either endpoint;
  directed links allow it only from their source. Travel remains bidirectional.
* Each landing requires ANY of its three mutually exclusive styles. Prize
  requires ALL of both landings. Removing support cascades unless alternate
  support preserves it.
* Sword and Boots each supply two permanent capacity pickups; each landing
  supplies one. All six keys fund the final seven active non-root rooms.
* Big Sword: 1.5× reach and two-second cooldown. Fast Sword: three half-range
  strikes. Phase Dash: half distance and contact immunity. Run: held sprint.
* Base HP is zero; Starting Room grants one HP. Practice rooms and Prize grant
  one, HP+ rooms grant five. Allocation changes current/max HP by the authored
  modifier rule.

# Evidence

`tests/branching_tests.gd` covers topology/funding, prerequisite and
exclusive-choice cascades, occupied-room protection, ability styles, and HP
behavior. The scenario is a regression fixture, not a claim of final balance.
