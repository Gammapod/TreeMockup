extends "res://tests/suite_reporter.gd"

# BOSS-01: vulnerable tethered boss, locked telegraph/gap, one wave hit,
# contact-only Phase immunity, capped warned summons, death cleanup and retry.
# A1: enemy behavior is explicit portable vocabulary; unsupported values reject.
const STORE = preload("res://authoring/content_store.gd")
const ADAPTER = preload("res://authoring/runtime_adapter.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var source: Dictionary = STORE.new().load_document("res://examples/build_arena.json")
	var compiled: Dictionary = ADAPTER.new().compile(source.document)
	_expect(compiled.ok and compiled.data.nodes.has("boss"), "Free Boss Trial is authored and compiled")
	if not compiled.ok or not compiled.data.nodes.has("boss"):
		_finish()
		return
	var definition: Dictionary = compiled.data.templates.boss_trial.enemies[0]
	_expect(definition.get("behavior", "") == "roost_guardian", "A1: guardian behavior survives compilation")
	var bad: Dictionary = source.document.duplicate(true)
	for template in bad.rooms:
		if template.id == "boss_trial":
			template.objects[0].properties.behavior = "unknown_boss"
	_expect(not ADAPTER.new().compile(bad).ok, "A1: unknown behavior rejects instead of silently becoming a bat")
	for template in bad.rooms:
		if template.id == "boss_trial":
			template.objects[0].properties.behavior = "roost_guardian"
			template.objects[0].properties.radius = 560
	_expect(not ADAPTER.new().compile(bad).ok, "A1: guardian radius must leave a positive wave expansion interval")
	if definition.get("behavior", "") != "roost_guardian":
		_finish()
		return
	_check_walkable_gaps()
	var game = load("res://main.tscn").instantiate()
	game.data_override = compiled.data
	root.add_child(game)
	await process_frame
	game._toggle("phase")
	game._toggle("boss")
	_expect(game.progression.available_points() == 7 and game.progression.can_travel("start", "boss"), "Boss access costs no allocation points")
	game._enter_room("boss", "south", 8)
	var room = game.room
	room.set_physics_process(false)
	room.player.set_physics_process(false)
	var boss = room.bosses.guardian
	var origin: Vector2 = boss.spawn
	# Two advances, not continuous pursuit. Distance is from original spawn.
	boss.advance(0.6, origin + Vector2(300, 0), 0)
	var first: Vector2 = boss.enemy.body.position
	_expect(first.x > origin.x, "Boss advances during pressure")
	boss.advance(0.8, origin + Vector2(300, 0), 0)
	_expect(boss.enemy.body.position == first, "Boss pauses between advances")
	boss.advance(1.6, origin + Vector2(300, 0), 0)
	_expect(boss.phase == "telegraph" and boss.enemy.body.position.distance_to(origin) <= 60.001, "Boss stays within 60-unit spawn tether and enters telegraph")
	var locked_position: Vector2 = boss.wave_origin
	var locked_gap: float = boss.gap_angle
	boss.advance(0.7, origin + Vector2(-300, 0), 0)
	_expect(boss.wave_origin == locked_position and boss.gap_angle == locked_gap and boss.enemy.body.position == locked_position, "Telegraph locks center/gap and stops movement")
	# Every phase is vulnerable, with fractional damage preserved.
	await physics_frame
	var before: float = boss.enemy.hp
	room._attack(boss.enemy.body.position, Vector2.RIGHT, 100, 4.5, TAU)
	_expect(is_equal_approx(boss.enemy.hp, before - 4.5), "Boss is vulnerable during telegraph")
	boss.advance(0.8, origin + Vector2(-300, 0), 0)
	_expect(boss.phase == "wave", "Full 1.5-second telegraph precedes wave")
	var safe: Vector2 = boss.wave_origin + Vector2.from_angle(boss.gap_angle) * 150
	var danger: Vector2 = boss.wave_origin - Vector2.from_angle(boss.gap_angle) * 150
	_expect(not boss.wave_intersects(safe, safe, 100, 200), "Safe wedge avoids swept ring")
	_expect(boss.wave_intersects(danger, danger, 100, 200), "Ring catches stationary player without tunneling across a long frame")
	_expect(boss.wave_intersects(boss.wave_origin - Vector2.from_angle(boss.gap_angle) * 50, boss.wave_origin - Vector2.from_angle(boss.gap_angle) * 250, 150, 153), "Dashing across the ring is still a collision")
	room.player.position = danger
	room.player.dash_phase = true
	room.player.dash_time = 1
	room.player.invulnerability = 0
	_expect(not room.player.hurt(), "Phase protects against boss/bat contact")
	boss.advance(1.0, danger, 0)
	_expect(room.player.hp == 7, "Shockwave bypasses Phase contact immunity")
	room.player.invulnerability = 0
	boss.advance(0.1, boss.wave_origin - Vector2.from_angle(boss.gap_angle) * boss.wave_radius, 0)
	_expect(room.player.hp == 7, "Same wave cannot deal damage twice")
	while boss.phase == "wave":
		boss.advance(0.05, safe, 0)
	_expect(boss.phase == "recovery" and not boss.contact_dangerous(), "Recovery disables boss contact")
	var resting: Vector2 = boss.enemy.body.position
	boss.advance(1.5, origin + Vector2(300, 0), 0)
	_expect(boss.phase == "pressure" and boss.cycle == 2 and boss.enemy.body.position == resting, "Recovery lasts 1.5 seconds, then second pressure cycle starts")
	_expect(not boss.spawn_warnings.is_empty() and room.enemies.size() == 1, "Second cycle warns before spawning bats")
	boss.advance(0.8, safe, 0)
	_expect(room.enemies.size() == 4, "Three bats join after warning")
	for i in range(400):
		boss.advance(0.05, safe, room.enemies.size() - 1)
	_expect(room.enemies.size() == 4, "Repeated summon cycles never accumulate more than three bats")
	_expect(boss.enemy.body.position.distance_to(origin) <= 60.001, "Movement cannot accumulate beyond tether across cycles")
	# Boss death clears transient adds and completes the authored clear objective.
	room._attack(boss.enemy.body.position, Vector2.RIGHT, 100, 1000, TAU)
	_expect(room.enemies.is_empty() and room.bosses.is_empty(), "Boss death removes bats and wave controller")
	_expect(game.progression.cleared.has("boss"), "Boss death clears Boss Trial")
	var build: Dictionary = game.progression.active.duplicate()
	game._request_trial_restart()
	await process_frame
	await process_frame
	_expect(game.progression.active == build and not game.progression.cleared.has("boss"), "Trial restart retains build and resets boss clear state")
	game._enter_room("boss", "south", game.room.player.hp)
	boss = game.room.bosses.guardian
	_expect(boss.enemy.hp == 120 and boss.phase == "pressure" and boss.cycle == 1 and boss.enemy.body.position == boss.spawn, "Fresh boss trial resets health, phase, summons and position")
	game.queue_free()
	await process_frame
	_finish()

func _check_walkable_gaps() -> void:
	# BOSS-01: ordinary movement has a concrete escape path even at corners,
	# with the boss at the edge of its tether. No dash or immunity is used.
	var script = load("res://roost_guardian.gd")
	for displacement in [Vector2.ZERO, Vector2(60, 0), Vector2(-60, 0), Vector2(0, 60), Vector2(0, -60), Vector2(42, 42), Vector2(-42, -42)]:
		for x in [63, 150, 300, 400, 500, 650, 737]:
			for y in [83, 160, 260, 380, 480, 557]:
				var body := CharacterBody2D.new()
				body.position = Vector2(400, 320) + displacement
				var target := Vector2(x, y)
				if target.distance_to(body.position) < 60:
					body.free()
					continue
				var probe = script.new()
				probe.configure({"body": body, "hp": 120.0, "radius": 38.0}, target)
				probe._next_phase(target, 3)
				var destination: Vector2 = probe.wave_origin + Vector2.from_angle(probe.gap_angle) * 150
				var hits: Array = []
				probe.wave_hit.connect(func(): hits.append(true))
				for tick in range(300):
					target = target.move_toward(destination, 220.0 / 60.0)
					probe.advance(1.0 / 60.0, target, 3)
					if probe.phase == "recovery":
						break
				_expect(hits.is_empty(), "Walking reaches the gap from (%d,%d), tether offset %s" % [x, y, displacement])
				probe.free()
				body.free()

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("All BOSS-01 encounter tests passed.")
		_complete(0)
	else:
		for failure in failures:
			printerr("ASSERTION FAILED: " + failure)
		_complete(1)
