extends "res://tests/suite_reporter.gd"

# UAB3: actions capture unified builds; overlapping locks and Phase hit timing
# are owned by one action-state boundary, independent of presentation.
const BUILD = preload("res://runtime/unified_build.gd")
var failures: Array[String] = []
var hits: Array = []
var arrivals: Array = []
var states: Array = []
var starts: Array = []

func _init() -> void:
	_run.call_deferred()

func _caps(phase: bool = true) -> Dictionary:
	var entries := [
		{"id":"s", "kind":"quality", "quality":"sword"},
		{"id":"d", "kind":"quality", "quality":"dash"},
		{"id":"sr", "kind":"quality", "quality":"sword_root"},
		{"id":"dr", "kind":"quality", "quality":"dash_root"},
		{"id":"damage", "kind":"stat", "stat":"sword_damage", "op":"add", "value":3.0}
	]
	if phase:
		entries.append({"id":"p", "kind":"quality", "quality":"phase_teleport"})
	return BUILD.compose({"nodes":{"root":{"contributions":entries}}}, {"root":true})

func _run() -> void:
	var path := "res://runtime/unified_actions.gd"
	if not FileAccess.file_exists(path):
		_expect(false, "unified action boundary exists")
	else:
		var actions = load(path).new()
		actions.attack_due.connect(func(snapshot): hits.append(snapshot))
		actions.phase_arrival_requested.connect(func(attempt): arrivals.append(attempt))
		actions.restriction_changed.connect(func(snapshot): states.append(snapshot))
		actions.dash_started.connect(func(snapshot): starts.append(snapshot))
		var caps := _caps()
		_expect(actions.start_sword(caps, Vector2.RIGHT), "sword begins")
		_expect(actions.restrictions().sword > 0.0, "sword root begins immediately")
		actions.advance(0.10)
		_expect(actions.start_dash(caps, Vector2.UP, Vector2(100, 200)), "phase may begin during sword root")
		_expect(starts.size() == 1 and starts[0].phase and starts[0].root and starts[0].duration == 0.16, "dash event exposes captured action and restriction")
		starts[0].distance = 999
		_expect(actions.restrictions().sword > 0.0 and actions.restrictions().dash > 0.0, "both roots coexist")
		caps.stats.sword_damage.effective = 99.0
		caps.stats.dash_distance.effective = 1.0
		caps.qualities.sword_root.effective = false
		caps.qualities.dash_root.effective = false
		actions.advance(0.05)
		_expect(hits.is_empty(), "sword hit during phase absence suppressed")
		actions.advance(0.11)
		_expect(arrivals.size() == 1 and arrivals[0].origin == Vector2(100, 200) and arrivals[0].destination == Vector2(100, 96), "arrival intent retains captured direction and distance")
		_expect(arrivals[0].distance == 104.0 and arrivals[0].root, "event mutation and build refund cannot change captured dash")
		_expect(not actions.start_dash(_caps(), Vector2.UP, Vector2.ZERO), "dash cannot repeat during captured recharge")
		_expect(actions.restrictions().sword > 0.0 and actions.restrictions().dash > actions.restrictions().sword, "dash does not cancel sword root")
		actions.advance(0.1)
		_expect(actions.restrictions().sword == 0.0 and actions.restrictions().dash > 0.0, "locks expire independently")
		actions.advance(1.0)
		_expect(not actions.restrictions().blocked and not states.is_empty(), "restriction notifications and expiry")
		var detached: Dictionary = actions.restrictions()
		detached.blocked = true
		_expect(not actions.restrictions().blocked, "restriction snapshot is detached")
		var normal = load(path).new()
		normal.attack_due.connect(func(snapshot): hits.append(snapshot))
		hits.clear()
		var original := _caps(false)
		_expect(normal.start_sword(original, Vector2.LEFT), "normal sword begins")
		original.stats.sword_damage.effective = 50
		normal.advance(0.14)
		_expect(hits.size() == 1 and hits[0].damage == 4.0 and hits[0].facing == Vector2.LEFT, "sword captures damage and direction")
		_expect(normal.start_dash(original, Vector2.RIGHT, Vector2.ZERO), "normal dash begins after due hit")
		normal.advance(0.02)
		_expect(not normal.start_sword(original, Vector2.RIGHT), "post-action cooldown remains")
		normal.advance(0.16)
		_expect(normal.start_sword(original, Vector2.RIGHT), "sword ready after full post-action cooldown")
		var concurrent = load(path).new()
		hits.clear()
		concurrent.attack_due.connect(func(snapshot): hits.append(snapshot))
		_expect(not concurrent.start_dash(original, Vector2.ZERO, Vector2.ZERO), "dash rejects zero direction")
		_expect(concurrent.start_sword(original, Vector2.RIGHT) and concurrent.start_dash(original, Vector2.RIGHT, Vector2.ZERO), "normal dash can overlap sword")
		concurrent.advance(0.14)
		_expect(hits.size() == 1, "normal dash does not cancel pending sword hit")
		var at_arrival = load(path).new()
		hits.clear()
		at_arrival.attack_due.connect(func(snapshot): hits.append(snapshot))
		at_arrival.start_dash(_caps(), Vector2.RIGHT, Vector2.ZERO)
		at_arrival.advance(0.02)
		at_arrival.start_sword(_caps(), Vector2.RIGHT)
		at_arrival.advance(0.15)
		_expect(hits.size() == 1, "hit due at arrival is not suppressed")
	for failure in failures:
		printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
