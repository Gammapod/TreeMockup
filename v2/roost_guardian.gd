extends Node2D

# Loaded-room encounter controller. The room owns health/damage/objectives;
# this node owns timing, tethered positioning, telegraphs and wave geometry.
signal wave_hit
signal summon_requested(positions: Array)

const PRESSURE_TIME := 3.0
const TELEGRAPH_TIME := 1.5
const RECOVERY_TIME := 1.5
const TETHER := 60.0
const MOVE_SPEED := 60.0
const WAVE_SPEED := 180.0
const WAVE_WIDTH := 20.0
const WAVE_END := 560.0
const GAP := PI / 2.0
const PLAYER_RADIUS := 13.0
const SUMMON_WARNING := 0.8
const ARENA_CENTER := Vector2(400, 320)
var enemy: Dictionary
var spawn: Vector2
var max_hp: float
var phase := "pressure"
var phase_time := 0.0
var cycle := 1
var move_goal: Vector2
var wave_origin: Vector2
var gap_angle := 0.0
var wave_radius := 0.0
var wave_touched := false
var previous_target: Vector2
var spawn_warnings: Array = []

func configure(record: Dictionary, target: Vector2) -> void:
	enemy = record
	spawn = enemy.body.position
	move_goal = spawn
	wave_origin = spawn
	max_hp = enemy.hp
	previous_target = target

func contact_dangerous() -> bool:
	return phase != "recovery"

func advance(delta: float, target: Vector2, living_adds: int) -> void:
	var remaining := delta
	while remaining > 0.000001:
		var duration := _duration()
		var step := minf(remaining, duration - phase_time)
		var old_time := phase_time
		if phase == "pressure":
			for burst in [0.0, 1.5]:
				if old_time <= burst and old_time + step > burst:
					move_goal = spawn + (target - spawn).limit_length(TETHER)
				var moving_time := maxf(0.0, minf(old_time + step, burst + 0.6) - maxf(old_time, burst))
				if moving_time > 0.0:
					var destination: Vector2 = enemy.body.position.move_toward(move_goal, enemy.get("speed", MOVE_SPEED) * moving_time)
					enemy.body.move_and_collide(destination - enemy.body.position)
			if not spawn_warnings.is_empty() and old_time < SUMMON_WARNING and old_time + step >= SUMMON_WARNING:
				var positions: Array = spawn_warnings.slice(0, maxi(0, 3 - living_adds))
				spawn_warnings.clear()
				if not positions.is_empty():
					summon_requested.emit(positions)
					living_adds += positions.size()
		elif phase == "wave":
			var old_radius := wave_radius
			wave_radius += WAVE_SPEED * step
			if not wave_touched and wave_intersects(previous_target, target, old_radius, wave_radius):
				wave_touched = true
				wave_hit.emit()
		phase_time += step
		remaining -= step
		previous_target = target
		if phase_time >= duration - 0.000001:
			_next_phase(target, living_adds)
	queue_redraw()

func _duration() -> float:
	match phase:
		"pressure": return PRESSURE_TIME
		"telegraph": return TELEGRAPH_TIME
		"wave": return (WAVE_END - enemy.radius) / WAVE_SPEED
		_: return RECOVERY_TIME

func _next_phase(target: Vector2, living_adds: int) -> void:
	phase_time = 0.0
	match phase:
		"pressure":
			phase = "telegraph"
			wave_origin = enemy.body.position
			var bearing := wave_origin.angle_to_point(target)
			# Prefer the quarter-turn pointing into the arena, rather than
			# asking a player at the boundary to take an outside route.
			var left := bearing - PI * 0.5
			var right := bearing + PI * 0.5
			var inward := wave_origin.direction_to(ARENA_CENTER)
			var difference := Vector2.from_angle(left).dot(inward) - Vector2.from_angle(right).dot(inward)
			gap_angle = left if difference > 0.001 else right
			if absf(difference) <= 0.001:
				gap_angle = left if cycle % 2 == 0 else right
			wave_radius = enemy.radius
			wave_touched = false
		"telegraph":
			phase = "wave"
		"wave":
			phase = "recovery"
		"recovery":
			phase = "pressure"
			cycle += 1
			if cycle % 2 == 0 and living_adds < 3:
				spawn_warnings = [Vector2(230, 190), Vector2(570, 190), Vector2(400, 455)].slice(0, 3 - living_adds)

func wave_intersects(from: Vector2, to: Vector2, from_radius: float, to_radius: float) -> bool:
	# Sweep both movement and ring expansion. Substeps are smaller than either
	# collision thickness, including long dashes and slow rendered frames.
	var steps := maxi(1, ceili((from.distance_to(to) + absf(to_radius - from_radius)) / 6.0))
	for i in range(steps + 1):
		var fraction := float(i) / steps
		var offset := from.lerp(to, fraction) - wave_origin
		var distance := offset.length()
		if absf(distance - lerpf(from_radius, to_radius, fraction)) > WAVE_WIDTH * 0.5 + PLAYER_RADIUS:
			continue
		var margin := asin(minf(1.0, PLAYER_RADIUS / maxf(distance, PLAYER_RADIUS)))
		if absf(wrapf(offset.angle() - gap_angle, -PI, PI)) > GAP * 0.5 - margin:
			return true
	return false

func _draw() -> void:
	if enemy.is_empty():
		return
	var point: Vector2 = enemy.body.position
	draw_arc(spawn, TETHER, 0, TAU, 48, Color(0.8, 0.65, 0.3, 0.22), 1)
	if phase in ["telegraph", "wave"]:
		var wedge := PackedVector2Array([wave_origin])
		for i in range(25):
			wedge.append(wave_origin + Vector2.from_angle(gap_angle - GAP * 0.5 + GAP * i / 24.0) * WAVE_END)
		draw_colored_polygon(wedge, Color(0.25, 0.9, 0.65, 0.09))
		for side in [-1.0, 1.0]:
			draw_dashed_line(wave_origin, wave_origin + Vector2.from_angle(gap_angle + side * GAP * 0.5) * WAVE_END, Color("83e8bc"), 2, 9)
		var radius := wave_radius if phase == "wave" else lerpf(enemy.radius, 160.0, phase_time / TELEGRAPH_TIME)
		draw_arc(wave_origin, radius, gap_angle + GAP * 0.5, gap_angle + TAU - GAP * 0.5, 100, Color("ff775e") if phase == "wave" else Color("ffd469"), WAVE_WIDTH if phase == "wave" else 4)
		draw_string(ThemeDB.fallback_font, wave_origin + Vector2.from_angle(gap_angle) * 145 - Vector2(15, 0), "GAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("83e8bc"))
	for warning in spawn_warnings:
		draw_arc(warning, 22 + 6 * sin(phase_time * 16), 0, TAU, 32, Color("e5a0f9"), 3)
		draw_string(ThemeDB.fallback_font, warning + Vector2(-20, -28), "BAT", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("e5a0f9"))
	var color := Color("86cdbb") if phase == "recovery" else (Color("ffd469") if phase == "telegraph" else Color("e07ba5"))
	var wing := 0.0 if phase == "recovery" else sin(phase_time * 8) * 9
	draw_colored_polygon(PackedVector2Array([point + Vector2(-23, -12), point + Vector2(-62, -30 - wing), point + Vector2(-44, 15), point + Vector2(-20, 22)]), color.darkened(0.25))
	draw_colored_polygon(PackedVector2Array([point + Vector2(23, -12), point + Vector2(62, -30 - wing), point + Vector2(44, 15), point + Vector2(20, 22)]), color.darkened(0.25))
	draw_circle(point, enemy.radius, color)
	draw_arc(point, enemy.radius, 0, TAU, 48, Color("fff1d7"), 2)
	draw_circle(point + Vector2(-12, -7), 5, Color("242338"))
	draw_circle(point + Vector2(12, -7), 5, Color("242338"))
	draw_rect(Rect2(200, 12, 400, 10), Color("412c3e"))
	draw_rect(Rect2(200, 12, 400 * maxf(0.0, enemy.hp / max_hp), 10), Color("e07ba5"))
	var label: String = {"pressure": "PRESSURE", "telegraph": "SHOCKWAVE — MOVE TO GAP", "wave": "SHOCKWAVE", "recovery": "RECOVERY — SAFE TO APPROACH"}[phase]
	draw_string(ThemeDB.fallback_font, Vector2(200, 43), "ROOST GUARDIAN  %.1f / %.0f   |   %s  %.1fs" % [enemy.hp, max_hp, label, _duration() - phase_time], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("fff1d7"))
