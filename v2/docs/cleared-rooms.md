# Cleared rooms — contracts and playtest

Status: accepted baseline; hardening completed. This document supersedes conflicting early
clear-state proposals in the backlog. ALL composition, run persistence, immediate
default-clear effects and free, independent permanent roots were confirmed by the
user. Partial-objective lifetimes and authoring restrictions below are the
accepted baseline policies. CLEAR-03 through CLEAR-06 remain potential future
experiments; the next experiment is undecided.

## Confirmed requirements

- A reusable room template can optionally declare multiple clear conditions and
  multiple clear effects.
- The skill-tree/progression model owns Cleared/Uncleared per **node instance**,
  parallel to Active/Inactive. Shared templates never share run state.
- A room with no clear condition is Cleared by default, including while inactive.
- Once cleared, a room stays cleared through deactivation.
- Requested conditions: defeat all enemies; hit a switch; collect all room tokens.
- Tokens are a new room-local collectible. They are not currency or persistent
  loot, and respawn when the player exits and revisits an uncleared room. Cleared
  rooms never spawn tokens; clearing removes any remaining tokens immediately.
- Requested effects: reveal a collectible (capacity key/gold); prevent enemy
  respawns in the cleared room; make the node a second root that stays permanently
  active. Effects can be combined.
- Optional room policy: block build editing while the player occupies that room
  and it is uncleared. Fast-travel targets any cleared, active root.
- Other consequences of clearing for the skill tree remain undecided.

## Ownership

V2 is the relevant project; the repository-root project is the older prototype.

- `progression.gd` owns cleared nodes, roots, objective progress, reward eligibility,
  allocation transactions and multi-root connectivity.
- `room.gd` reports enemy deaths, switch hits and token collections. Uncleared-room
  tokens reset each visit; cleared rooms suppress them.
- `main.gd` forwards events and departure/reset boundaries, restores no-respawn
  effects, and refreshes visible rewards and copied tree snapshots.
- The editor writes portable template declarations. The store validates structure
  and references; the adapter rejects unsupported vocabulary and root/exclusivity
  combinations. The tree panel is presentation-only.

## Data contract

Use optional template-level `clear` data with `conditions` and `effects` arrays.
Conditions describe objectives; effects reference stable local object IDs or name
a supported result. No executable scripts or dungeon-node references are needed
inside templates.

Supported vocabulary:

```json
{
  "clear": {
    "conditions": [
      {"kind": "all_enemies_defeated"},
      {"kind": "switch_hit", "object": "switch_a"},
      {"kind": "all_tokens_collected"}
    ],
    "effects": [
      {"kind": "reveal_pickup", "object": "reward_key"},
      {"kind": "prevent_enemy_respawn"},
      {"kind": "become_root"}
    ]
  }
}
```

Composition is **ALL conditions**, with every listed effect applied
on completion. Use the existing authored pickup geometry/value for revealed loot.
Tokens have stable object IDs but never enter `progression.collected`, capacity,
or gold. Switch/reward references and supported kinds are validated before playtest.

## Lifecycle and root rules

1. **Multiple objectives:** ALL. Switch hits latch across visits and deactivation,
   independently of the toggle's current on/off state. Enemy defeats retain the
   existing encounter lifetime (reset on deactivation). Token progress resets on
   every departure, even if that individual objective was complete before the
   combined room objective was satisfied.
2. **Clear lifetime:** retained through deactivation, defeat and room reload;
   reset for a fresh run or editor playtest. Disk run saves remain separate.
3. **Default-cleared effects:** applied at run creation for every node, including
   unvisited/inactive nodes. A default-clear root effect immediately activates it.
4. **Permanent-root economy:** promotion releases its allocation cost. Authored
   cost stays intact in content; effective runtime allocation is zero.
5. **Permanent-root dependencies:** promoted roots waive prerequisites and original
   root connectivity. Dependents retain normal support rules. Root-effect nodes
   cannot belong to exclusive groups in this slice.
6. **Empty objectives:** enemy/token conditions require matching authored objects.
7. **Starting room:** `dungeon.root` retains its existing name as the start/defeat
   destination. New content gives its template no conditions and a `become_root`
   effect. Progression has no special initial-root activation path. Legacy V1
   bundles without a start-template `clear` field are translated by the adapter
   to an isolated start-template copy with that effect; source data and other
   instances are unchanged. An explicit start clear rule must give an immediate root.
8. **No-respawn:** after clearing, future room loads omit enemies. This effect
   does not kill currently living enemies when a switch/token objective clears.

Clear completion is monotonic and effect application idempotent. Loading a
cleared room restores its consequences without granting rewards twice. Revealed
but uncollected rewards remain available after leaving or deactivating.

## Implemented scope

1. **CLEAR-01 — foundation:** authorable condition/effect arrays, enemy condition,
   model-owned clear state, default-cleared initialization, room/coordinator events
   and separate map/detail indicators.
2. **CLEAR-02 — visible reward:** one or several revealed pickups, persistent
   eligibility and collection, immediate scene refresh and reload restoration.
3. **CLEAR-07 — switch and token objectives:** reuse sword-hit switches; introduce
   room-local tokens and verify combined-condition/reset behavior.
4. **CLEAR-08 — enemy persistence effect:** preserve cleared enemies across
   encounter resets without changing the clear state of other rooms.
5. **CLEAR-09 — permanent secondary roots:** released allocation/support, with
   multi-root connectivity, cascade protection and root presentation.
6. **CLEAR-10 / CLEAR-11 — secondary features:** optional occupied-uncleared-room
   editing lock and fast-travel to cleared, active roots.

## Root travel and occupied-room editing permissions

- Select a destination on the map and press **Travel to root**. It must be a cleared,
  active root other than the current room; no link/path is required. Disconnected
  earned roots remain eligible.
- Any active occupied room can be the source, including an uncleared encounter or
  an editing-locked room. Fast-travel does not spend points, change the active
  build, heal, or automatically clear the source.
- Arrival uses the destination's authored `spawn` (default `[400,400]`). Authors
  should keep it clear of geometry. Normal departure/re-entry lifecycle applies:
  uncleared tokens reset, enemy records and permanent rewards retain their policies.
- The progression model supplies travel previews; the coordinator revalidates
  requests and deferred scene replacement. A pending transition blocks overlapping
  travel/build commands, and a dead player follows the normal defeat path.
- In **Clear rules…**, enable **Disable tree editing while inside this uncleared
  room**. This writes `clear.block_tree_editing_until_cleared: true` (default false).
  While occupied and uncleared, both activation and deactivation transactions
  reject with `tree_editing_locked`. Map inspection and ordinary travel remain
  available, as does the F2 content-authoring studio.
- The restriction depends on the occupied room, not the selected target.
  Completion immediately restores normal local editing rules; leaving also
  removes that room's restriction. Default-cleared rooms never impose the lock.

## Editor and fixture walkthrough

Open F2 → Open → `examples/cleared_rooms.json` → Playtest. Sword is already granted
by the starting root. The six-node lab includes two independent enemy-clear rooms
using the same template, a switch/chest room, a token room and a combined-objective
room with all three effects.

- Clear one enemy room; verify the other remains uncleared. Collect its revealed
  key, deactivate/reactivate it from Start, and verify no enemies or duplicate key.
- Hit the switch with Space; open the revealed chest with E.
- Collect some tokens, leave before clearing, and return to verify all tokens
  return. After clearing, revisit to verify no tokens spawn.
- Complete all objectives in Earned Root. Its two-point allocation is released.
  Return to Start and deactivate Token Clear: the earned root stays active despite
  its missing prerequisite and disconnected branch.
- In the room editor, place objects with the brushes (including `token`), then use
  **Clear rules…** to select conditions and effects. Multiple switches/rewards
  appear as individual checkboxes. JSON remains available for details/extensions.
  Save/Open and room import/export preserve clear declarations.
- Token Clear now enables the editing lock: try activating Earned Root before
  collecting all tokens, then after clearing. Before clearing, select Immediate
  Root and use **Travel to root** to verify that travel remains available.
- After earning the second root, travel home and deactivate Token Clear. Select
  Earned Root and travel back to its disconnected branch; HP and build are retained.

## Behavioral checks

- Default-cleared inactive nodes; active-but-uncleared and cleared-but-inactive UI.
- Independent state/rewards for two instances of the same template.
- Completion occurs immediately on the final required event, exactly once.
- Deactivation, re-entry, defeat and fresh-run behavior follow the chosen lifecycle.
- Token resets cannot grant currency or duplicate persistent loot.
- Hidden rewards cannot be collected early through the model; revealed rewards
  remain available until collected and cannot be awarded twice.
- No-respawn effects survive deactivation; ordinary encounters retain their policy.
- A promoted root survives upstream removal, supports its own connected branch,
  and cannot be directly or indirectly deactivated. Costs and previews agree.
- Authoring round trips preserve declarations; invalid references and unsupported
  conditions/effects fail playtest explicitly.

## Invariant and test trace

| ID | Contract | Evidence |
| --- | --- | --- |
| CL1 | Model-owned per-instance clear state, default clear, monotonic run lifetime and visible state | `tests/clear_tests.gd`: defaults, reuse, deactivate/reactivate, defeat, new run, tree details |
| CL2 | ALL objectives, event validation and explicit partial-progress lifetimes; tokens never become currency or spawn in cleared rooms | clear tests: event combinations, invalid IDs, uncleared token respawn, cleared/default-cleared token suppression, immediate removal, enemy reset, latched switches, actual room-event integration |
| CL3 | Revealed rewards are model-gated, persistent and granted once | clear tests: early rejection, immediate scene reveal, reload, collection/deactivation |
| CL4 | Optional no-respawn is independent of clear state | clear tests: plain clear vs effect, default effects, reload after deactivation |
| CL5 | Every root is effect-created, free, permanent and supports independent connectivity | clear tests: default/promotion, cost release, upstream loss, direct protection, exclusive rejection, legacy isolation |
| CL6 | Portable authoring, reference validation and unsupported-mechanic rejection | clear tests, `tests/content_tests.gd` (all examples), `tests/editor_tests.gd` (actual clear form, save/open, playtest) |

Red phase: the new clear suite failed before production changes for missing clear
lifecycle, accepted dangling objective references and silently ignored unsupported
conditions. Implementation added the model/event/authoring path and made it pass.
Existing progression, branching, content, editor, shell, map-action, map-preview
and tree-panel suites pass. Baseline behavior was accepted after user playtesting;
presentation polish remains optional.

Token-policy revision: integration checks first failed for cleared-room re-entry,
default-cleared spawns and remaining tokens on completion. Supplying clear state
at room configuration and suppressing tokens on completion makes those checks pass;
uncleared re-entry still restores tokens.

### Secondary-feature test trace

| ID | Contract | Evidence |
| --- | --- | --- |
| TR1 | Travel targets only cleared active roots; no path/source-clear requirement | `tests/root_travel_tests.gd`: eligible/ineligible destinations, invalid endpoints, same-room rejection, disconnected roots, locked source |
| TR2 | Snapshot-driven travel intent is revalidated; normal scene lifecycle, HP/build preserved | root travel tests: map button, authored spawn, unchanged points/HP, token reset, disconnected arrival, stale deferred request; minimum-window layout |
| EDIT1 | Opt-in occupied-room lock blocks both model transactions until cleared | root travel tests: activation/deactivation rejection, unchanged allocation, source-vs-target, default editable rooms, immediate UI refresh |
| EDIT2 | Boolean editing policy survives authoring and rejects invalid values | root travel tests: boolean validation; `tests/editor_tests.gd`: checkbox, save/open, compiled playtest |

Red phase: the new suite failed for missing travel/permission APIs and acceptance
of a nonboolean editing policy. Model validation, coordinator transitions,
snapshot UI controls and the editor checkbox made those checks pass. Existing
progression, clear-state, content, editor, shell, map-action, map-preview,
tree-panel and branching suites also pass.

## Baseline hardening

The user accepted the current clearing functionality as a baseline and deferred
CLEAR-03 through CLEAR-06. No new gameplay mechanics were added in this pass.

### Architectural review

- Progression remains the authority for clear state, roots, reward eligibility,
  connectivity and edit/travel permissions. Room scenes report objective events;
  the tree panel consumes snapshots and emits intent.
- The coordinator now uses one deferred transition path for doors, root travel
  and defeat. Each request captures a room generation. Scene replacement,
  including a fresh playtest, invalidates old requests before they can touch the
  new run. Stale callbacks do not clear a newer request's pending state.
- Door and root travel revalidate destination eligibility and use live HP at
  execution. Death before arrival takes the existing defeat path.
- A room created while the studio is visible inherits the paused/hidden state;
  closing the studio resumes the current room.
- The adapter checks starting HP using the progression model's actual initial
  capabilities, so all immediately active roots contribute. This avoids a second,
  single-root interpretation of initial build state in authoring validation.
- The current module boundaries remain sufficient; no new subsystem framework
  was needed.

### Invariants and red/green evidence

| Invariant | Existing trace | Added regression in `tests/clear_hardening_tests.gd` |
| --- | --- | --- |
| LIFE1: fresh playtests have isolated runtime state | editor tests: fresh authored playtest; clear tests: clear-state reset | queued root travel, door travel and defeat cannot move, heal or replace the fresh run's room |
| LIFE2: content authoring pauses gameplay | editor/shell tests: suspend/resume and input isolation | deferred arrival remains hidden/disabled until studio resume |
| TR2: transitions preserve player safety and revalidate eligibility | root travel tests: stale destination and retained HP | queued door rejects inactive target; death before arrival returns to start rather than restoring captured HP |
| CL5: every immediate root contributes to initial capabilities | clear tests: immediate-root activation and allocation | zero base/start HP is valid when another immediate root grants HP; zero total remains invalid |

All seven failure checks reproduced before production edits. The unified,
generation-guarded transition path, inherited pause state and model-derived
initial-health check made the suite pass.

Verification: all **12** headless suites passed, with process exit codes checked:
progression/room integration, content, editor, branching, responsive shell/input,
map actions, map previews, map camera, tree-panel boundary, clear state, root
travel/editing permissions, and baseline hardening.
