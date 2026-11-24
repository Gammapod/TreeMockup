extends RefCounted

# A room/player integration must consume these intents; this object never moves
# an actor, resolves collisions, applies damage, or owns room lifetime.
signal attack_due(snapshot: Dictionary)
signal dash_started(snapshot: Dictionary)
signal phase_arrival_requested(attempt: Dictionary)
signal restriction_changed(snapshot: Dictionary)

const ACTION_DURATION := 0.16
const SWORD_HIT_TIME := 0.14

var _time := 0.0
var _sword_end := 0.0
var _sword_ready := 0.0
var _sword_hit_at := -1.0
var _sword_root := false
var _sword: Dictionary = {}
var _dash_end := 0.0
var _dash_ready := 0.0
var _dash_root := false
var _dash_pending := false
var _dash: Dictionary = {}

func start_sword(build: Dictionary, facing: Vector2) -> bool:
	if not build.qualities.sword.effective or _time < _sword_ready:
		return false
	_sword = {
		"facing": facing, "reach": build.stats.sword_range.effective,
		"arc": build.stats.sword_arc.effective, "damage": build.stats.sword_damage.effective,
		"duration": ACTION_DURATION, "cooldown": build.stats.sword_cooldown.effective,
		"root": build.qualities.sword_root.effective
	}
	_sword_end = _time + ACTION_DURATION
	_sword_ready = _sword_end + float(_sword.cooldown)
	_sword_hit_at = _time + SWORD_HIT_TIME
	_sword_root = build.qualities.sword_root.effective
	_notify()
	return true

func start_dash(build: Dictionary, direction: Vector2, origin: Vector2) -> bool:
	if not build.qualities.dash.effective or _time < _dash_ready or direction.length_squared() <= 0.000001:
		return false
	direction = direction.normalized()
	var distance: float = build.stats.dash_distance.effective
	_dash = {
		"origin": origin, "direction": direction, "distance": distance,
		"destination": origin + direction * distance, "duration": ACTION_DURATION,
		"recharge": build.stats.dash_recharge.effective,
		"phase": build.qualities.phase_teleport.effective, "root": build.qualities.dash_root.effective
	}
	_dash_end = _time + ACTION_DURATION
	_dash_ready = _dash_end + float(_dash.recharge)
	_dash_root = build.qualities.dash_root.effective
	_dash_pending = true
	dash_started.emit(_dash.duplicate(true))
	_notify()
	return true

func advance(delta: float) -> void:
	if delta <= 0.0:
		return
	var target := _time + delta
	while true:
		var next := target + 1.0
		if _dash_pending and _dash_end <= target:
			next = minf(next, _dash_end)
		if _sword_hit_at >= 0.0 and _sword_hit_at <= target:
			next = minf(next, _sword_hit_at)
		if next > target:
			break
		_time = next
		# Arrival at exactly the hit time precedes the hit.
		if _dash_pending and _dash_end <= _time:
			_dash_pending = false
			if _dash.phase:
				phase_arrival_requested.emit(_dash.duplicate(true))
		if _sword_hit_at >= 0.0 and _sword_hit_at <= _time:
			_sword_hit_at = -1.0
			if not phase_absent():
				attack_due.emit(_sword.duplicate(true))
	_time = target
	_notify()

func phase_absent() -> bool:
	return _dash_pending and _dash.get("phase", false) and _time < _dash_end

# A committed room transition invalidates an outstanding arrival. Recharge
# remains captured; no arrival intent may be emitted by a later advance.
func cancel_phase() -> bool:
	if not _dash_pending or not _dash.get("phase", false):
		return false
	_dash_pending = false
	_notify()
	return true

func restrictions() -> Dictionary:
	var sword := maxf(0.0, _sword_ready - _time) if _sword_root else 0.0
	var dash := maxf(0.0, _dash_ready - _time) if _dash_root else 0.0
	return {"sword": sword, "dash": dash, "blocked": sword > 0.0 or dash > 0.0}

func _notify() -> void:
	restriction_changed.emit(restrictions())
