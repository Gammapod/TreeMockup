extends Node2D

# Room-local presentation only. Host supplies snapshots, strike events and
# simulation-active presentation time; no model access or action scheduling.
const STRIKE_DISPLAY_SECONDS := 0.18
const READINESS_RADIUS := 26.0
var anchor := Vector2.ZERO
var avatar_present := false
var clocks: Dictionary = {}
var strikes: Array = []

func _ready() -> void:
	z_as_relative = false
	z_index = 100

func present_frame(position_in_room: Vector2, present: bool, state: Dictionary) -> void:
	anchor = position_in_room
	avatar_present = present
	clocks = state.duplicate(true)
	queue_redraw()

func present_strike(strike: Dictionary) -> void:
	strikes.append({"strike": strike.duplicate(true), "age": 0.0})
	queue_redraw()

func reset_room() -> void:
	strikes.clear()
	clocks.clear()
	avatar_present = false
	queue_redraw()

func advance(delta: float) -> void:
	# This is visual persistence only, never a cooldown or combat clock.
	var elapsed := maxf(delta, 0.0)
	for entry in strikes:
		entry.age += elapsed
	strikes = strikes.filter(func(entry): return entry.age < STRIKE_DISPLAY_SECONDS)
	queue_redraw()

func readiness_fraction(action: String) -> float:
	var clock: Dictionary = clocks.get(action, {})
	if not clock.get("available", false):
		return 0.0
	if clock.get("ready", false):
		return 1.0
	var total := float(clock.get("total", 0.0))
	if total <= 0.0:
		return 0.0
	return clampf(1.0 - float(clock.get("remaining", 0.0)) / total, 0.0, 1.0)

func _draw() -> void:
	for entry in strikes:
		_draw_strike(entry.strike)
	for arc in readiness_arcs():
		_draw_clock(arc.action, arc.radius, arc.start, arc.end, arc.color)

func readiness_arcs() -> Array:
	var result: Array = []
	if not avatar_present:
		return result
	for arc in [
		{"action": "sword", "radius": READINESS_RADIUS, "start": -PI * 0.9, "end": -PI * 0.1, "color": Color("ffcf75")},
		{"action": "dash", "radius": READINESS_RADIUS, "start": PI * 0.1, "end": PI * 0.9, "color": Color("8cddff")}
	]:
		if clocks.get(arc.action, {}).get("available", false):
			result.append(arc)
	return result

func _draw_clock(action: String, radius: float, start: float, end: float, color: Color) -> void:
	# Upper and lower arcs distinguish actions beyond color.
	draw_arc(anchor, radius, start, end, 32, Color("293645"), 3.0, true)
	var fraction := readiness_fraction(action)
	if fraction > 0.0:
		draw_arc(anchor, radius, start, lerpf(start, end, fraction), 32, color, 3.0, true)

func _draw_strike(strike: Dictionary) -> void:
	var origin: Vector2 = strike.get("origin", Vector2.ZERO)
	var facing: Vector2 = strike.get("facing", Vector2.ZERO)
	var reach := float(strike.get("reach", 0.0))
	var arc := float(strike.get("arc", 0.0))
	if facing.is_zero_approx() or reach <= 0.0 or arc <= 0.0:
		return
	var start := facing.angle() - arc / 2.0
	var end := facing.angle() + arc / 2.0
	var ink := Color("ffd27d", 0.9)
	draw_dashed_line(origin, origin + Vector2.from_angle(start) * reach, ink, 2.0, 5.0, true)
	draw_dashed_line(origin, origin + Vector2.from_angle(end) * reach, ink, 2.0, 5.0, true)
	# Dashed outline is a candidate swing, not an occlusion-clipped hit result.
	for i in range(0, 32, 2):
		var a := lerpf(start, end, float(i) / 32.0)
		var b := lerpf(start, end, float(i + 1) / 32.0)
		draw_line(origin + Vector2.from_angle(a) * reach, origin + Vector2.from_angle(b) * reach, ink, 2.0, true)
