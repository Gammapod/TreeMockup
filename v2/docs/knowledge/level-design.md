---
type: Design Guide
title: Dungeon and skill-tree level design
description: Evolving design strategies and evaluated lessons for interconnected dungeon scenarios.
tags: [v2, gameplay, level-design, authoring]
status: evolving
---

# Purpose

Use this guide to design a dungeon that is both a sensible place to explore
and a sensible skill tree to allocate. These are design strategies, not
runtime guarantees. The [content](content.md), [clear-state](clear-state.md)
and [UI](ui.md) contracts describe accepted behavior; the
[experiment record](experiments.md) records evaluated outcomes.

# Strategies

## Build a physical skill tree

* Design rooms, physical routes and ability nodes together. A useful graph
  should make sense both as a build and as a place the player traverses.
* Generally use physical connections and local activation to constrain
  activation order. For now, reserve explicit prerequisites for cases where
  an ability should have multiple prerequisites; they are ongoing requirements,
  not merely instructions about order. Check refunds and cascades as well.
* Give abilities both individual customization and opportunities for
  rewarding combinations. An upgrade can have an internal stat tradeoff, or
  its capacity cost can be the tradeoff instead. Tune numbers through play.
* Ability-node rooms should be miniature tutorials: favor challenges that
  make the node's benefit apparent, such as a high-health enemy for a damage
  upgrade. The challenge need not prove the player used that particular
  ability; allow other approaches where practical.
* Distinguish those encouraging tests from deliberate ability gates. When a
  route truly requires an ability, support that requirement with checked
  geometry or an explicitly designed mechanic; verify alternatives, refunds
  and safe exits rather than assuming a clear condition checks ability use.
* Treat map positions and instance doors as gameplay content. Automatic door
  placement can change when map positions change; check actual entry points,
  obstacles and walking routes rather than inferring them from the graph.

## Budget exploration

* Trace feasible sequences from the starting build: what can the player
  activate, physically reach, collect and refund with the available capacity?
  Include local activation, prerequisites, exclusivity, support, roots, clear
  rules and persistence. A structurally valid graph is not a reachability proof.
* At each stage, check that a further capacity upgrade can be reached with the
  capacity and resources available at that point. Distinguish **total** capacity
  earned from **unspent** capacity; a player may need to refund to make a
  particular allocation.
* Prefer capacity upgrades hidden behind cleared rooms or in distant nodes.
  An obvious early reward can be a deliberate teaching exception.
* For each reward, consider the builds a player could realistically bring to
  it. Aim for different configurations to make the challenge easier in
  different ways, including possible combat and mobility approaches. Do not
  assume a particular solution is feasible without checking geometry and
  runtime behavior.
* Plan persistent world changes and return routes alongside the budget.
  Preserve safe ways to recover from allocations and ensure rewards cannot be
  duplicated by re-entry.

## Teach through spaces and consequences

* Introduce a system with a visible purpose, let the player act, then show its
  consequence. The proposed opening starts with capacity to allocate before
  introducing a capacity pickup.
* Use memorable room geometry to support combat, navigation and orientation.
  A shortcut can depend on an ability or on a switch changing the world; the
  existing switch-to-wall interaction toggles rather than permanently opens.
* Consider the cost of revisiting puzzles. A maze can be interesting to solve
  once but tedious as a mandatory thoroughfare; placement and later shortcuts
  are potential mitigations.
* Place healing deliberately. Max-HP upgrades do not heal, so increasing max HP
  is not by itself preparation for combat. Check recovery after refunds,
  defeat, and collecting one-use healing.

## Targets for the interconnected prototype

The current design target is 14–18 nodes, built around the accepted Guardian.
Desired moments include an early obstacle with multiple skill solutions,
specialized follow-up challenges, mutually exclusive routes to a required
ability, a multi-room persistent-state/reallocation puzzle, and a halfway
mini-boss that earns a second root. Use at most two roots. At the final boss,
the budget should make retaining navigation versus combat investment a real
tradeoff. These are goals, not claims that the current candidate achieves them.

# Lessons and evidence

* **UI-02:** The user found walk-through doors more intuitive than deliberate
  door interaction. Continuous traversal is the accepted baseline; see the
  [experiment record](experiments.md#ui-02--walk-through-border-doors-2026-11-15).
* **Tutorial candidate:** The user described the opening as a good start for a
  real dungeon. Its detailed teaching, combat balance and recovery remain open
  playtest questions; see
  [`tutorial-slice.md`](../../examples/scenario-designs/tutorial-slice.md).

Add lessons only when grounded in observed feedback or evaluated experiments;
distinguish player observations from technical checks and unevaluated ideas.
