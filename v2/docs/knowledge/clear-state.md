---
type: Gameplay Contract
title: Clear state, roots, and root travel
description: Accepted lifecycle and permission rules for room objectives, permanent roots, and travel.
tags: [v2, gameplay, clear-state, roots]
status: stable
generated: { by: "openai/gpt-5.6-terra", at: 2026-11-15T00:00:00Z }
sources:
  - { resource: ../../progression.gd, title: Progression implementation }
  - { resource: ../../tests/clear_tests.gd, title: Clear-state test trace }
  - { resource: ../../tests/root_travel_tests.gd, title: Travel and editing-permission test trace }
  - { resource: ../archive/cleared-rooms-closeout.md, title: Archived implementation closeout }
---

# Accepted rules

* Clear state is owned by progression per node instance, independently of
  active/inactive state. A conditionless template is immediately cleared.
* Conditions combine with **ALL**. Supported conditions are all enemies
  defeated, a named switch hit, and all room tokens collected.
* Completion is monotonic and effects are idempotent for one run. Clear state
  persists through deactivation, defeat, and reload; a fresh run resets it.
* Tokens are objective-only. They reset on departure while uncleared, do not
  grant currency, and are removed/suppressed after clear.
* Switch hits latch for the run. Enemy progress follows encounter lifetime:
  deactivation clears enemy objective progress unless the room is already
  cleared; `prevent_enemy_respawn` prevents later respawns.
* `reveal_pickup` makes the authored reward eligible once; collection remains
  per node/object and cannot duplicate.

# Roots and permissions

* `become_root` makes a cleared node active, permanent, free, and exempt from
  its original prerequisites/root support. It anchors normal connectivity for
  dependents and cannot belong to an exclusive group.
* The start node is also an immediate `become_root` effect. Legacy content
  without that declaration receives an isolated runtime compatibility copy;
  source is unchanged.
* An active, cleared root can be selected as a root-travel destination from
  any other active room. It needs no path, uses its authored spawn, and
  preserves HP/build while applying normal departure/re-entry rules.
* A template may set `block_tree_editing_until_cleared`. While occupied and
  uncleared, activation and deactivation reject; inspection, normal travel,
  root travel, and F2 authoring remain available.

# Evidence

`tests/clear_tests.gd` characterizes clear/objective/reward/root behavior.
`tests/root_travel_tests.gd` characterizes travel eligibility, stale-request
revalidation, HP/build preservation, and the editing lock. See also the
[invariant index](invariants.md).
