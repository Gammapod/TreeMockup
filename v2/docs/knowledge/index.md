---
okf_version: "0.2"
---

# V2 knowledge

Read this bundle before changing V2. It is a compact, current map of the
game and its accepted contracts; code and tests remain authoritative for
implementation detail.

## Start here

* [Game primitives and glossary](glossary.md) - What “the dungeon is also a skill tree” means and the terms used in code and design.
* [Architecture and boundaries](architecture.md) - Module ownership and decisions that changes must preserve.
* [Functional invariants](invariants.md) - Stable behavioral contracts and their test traces.
* [Content contract](content.md) - Portable bundle structure, validation, and supported runtime vocabulary.
* [Clear-state contract](clear-state.md) - Objectives, effects, roots, travel, and editing permissions.
* [UI contract](ui.md) - Map/shell behavior and presentation boundaries.
* [Branching scenario](branching-scenario.md) - Default regression scenario and design mapping.
* [Experiment record](experiments.md) - Current baselines, open questions, and the only log format for new gameplay experiments.

## Recording policy

Record only durable, decision-relevant knowledge:

| If a change… | Record it in… | Minimum record |
| --- | --- | --- |
| Chooses or changes a cross-module rule/boundary | [Architecture](architecture.md) | Decision, consequence, code/test evidence |
| Adds or changes a behavior that must not regress | [Invariants](invariants.md) | One-sentence contract and test path |
| Tests a player/design hypothesis | [Experiments](experiments.md) | Hypothesis, scenario/change, observation, decision |
| Introduces a player-facing term or primitive | [Glossary](glossary.md) | Term and one-sentence meaning |

Do **not** record routine implementation steps, source walkthroughs, test
command output, speculative ideas, or duplicate prose already clear in code,
fixtures, schema, or tests. Link to that evidence instead. Delete or replace
superseded statements; use [the update log](log.md) only to make meaningful
knowledge changes discoverable.

## Detailed references

* [Experiment backlog](../backlog.md)
* [Archived feature closeouts](../archive/README.md)
