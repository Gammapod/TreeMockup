extends "res://tests/suite_reporter.gd"

# UAB7: Room resolves Phase actions, excludes absent-player interactions,
# and emits actual outcomes; E1: absence cannot consume a guardian wave.
const ROOM = preload("res://room.gd")
const BUILD = preload("res://runtime/unified_build.gd")
const BOSS = preload("res://roost_guardian.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _caps() -> Dictionary:
	var entries := [
		{"id":"dash", "kind":"quality", "quality":"dash"},
		{"id":"phase", "kind":"quality", "quality":"phase_teleport"},
		{"id":"root", "kind":"quality", "quality":"dash_root"}
	]
	return BUILD.compose({"nodes":{"root":{"contributions":entries}}}, {"root":true})

func _room(enemies: Array = []) -> Node:
	var room = ROOM.new()
	root.add_child(room)
	room.set_physics_process(false)
	room.configure({"obstacles":[], "objects":[], "pickups":[{"id":"loot", "kind":"gold", "position":Vector2(400,300)}], "enemies":enemies, "spawn":Vector2(400,300)}, [], {}, {}, "", _caps(), 5)
	room.player.set_physics_process(false)
	return room

func _run() -> void:
	var room = ROOM.new()
	if not room.has_signal("phase_outcome") or not room.has_signal("restriction_changed"):
		_expect(false, "Room exposes authoritative Phase outcome and restriction signals")
		room.free()
	else:
		room.free()
		room = _room([{"id":"enemy", "position":Vector2(504,300), "hp":10, "speed":0}])
		var outcomes: Array = []
		var restrictions: Array = []
		room.phase_outcome.connect(func(value): outcomes.append(value))
		room.restriction_changed.connect(func(value): restrictions.append(value))
		room.player.facing = Vector2.RIGHT
		_expect(room.player.start_dash(), "phase action begins")
		room.pickups.append({"id":"chest", "kind":"gold", "chest":true, "position":Vector2(400,300)})
		var key := InputEventKey.new()
		key.pressed = true
		key.physical_keycode = KEY_E
		room._unhandled_key_input(key)
		room._physics_process(0.01)
		_expect(room.pickups.size() == 2, "absent player cannot collect pickup or interact with chest")
		room.player.advance_unified(0.16, Vector2.ZERO)
		_expect(outcomes.size() == 1 and outcomes[0].status == "landed", "room emits actual landed outcome")
		_expect(room.player.position == Vector2(504,300) and room.player.hp == 4, "arrival applies immediate ordinary enemy contact")
		_expect(outcomes[0].contact_damage == 1 and not restrictions.is_empty(), "outcome distinguishes contact and restriction signal")
		room.queue_free()
		await process_frame
		room = _room([{"id":"enemy", "position":Vector2(504,300), "hp":10, "speed":0}])
		outcomes.clear()
		room.phase_outcome.connect(func(value): outcomes.append(value))
		room.player.invulnerability = 1.0
		room.player.start_dash()
		room.player.advance_unified(0.16, Vector2.ZERO)
		_expect(outcomes.size() == 1 and outcomes[0].contact_damage == 0 and room.player.hp == 5, "arrival respects ordinary invulnerability")
		room.queue_free()
		await process_frame
		room = _room([{"id":"boss", "behavior":"roost_guardian", "position":Vector2(200,300), "hp":10, "speed":0, "radius":14}])
		var guardian = room.bosses.boss
		guardian.phase = "wave"
		guardian.wave_origin = Vector2(200,300)
		guardian.wave_radius = 252.0
		guardian.gap_angle = PI
		room.player.start_dash()
		room.player.advance_unified(0.16, Vector2.ZERO)
		room._physics_process(0.01)
		_expect(room.player.hp == 5 and not guardian.wave_touched, "teleport does not sweep an intervening guardian wave")
		room.queue_free()
		await process_frame
		room = _room([{"id":"boss", "behavior":"roost_guardian", "position":Vector2(200,300), "hp":10, "speed":0, "radius":14}])
		outcomes.clear()
		room.phase_outcome.connect(func(value): outcomes.append(value))
		guardian = room.bosses.boss
		guardian.phase = "wave"
		guardian.wave_origin = Vector2(200,300)
		guardian.wave_radius = 304.0
		guardian.gap_angle = PI
		room.player.start_dash()
		room.player.advance_unified(0.16, Vector2.ZERO)
		_expect(outcomes.size() == 1 and outcomes[0].wave_damage == 1 and room.player.hp == 4, "arrival point receives ordinary guardian wave damage")
		room.queue_free()
		await process_frame
		room = _room()
		var caps_with_sword: Dictionary = _caps()
		caps_with_sword.qualities.sword.effective = true
		caps_with_sword.stats.sword_range.effective = 92.0
		caps_with_sword.stats.sword_arc.effective = 1.8
		caps_with_sword.stats.sword_damage.effective = 1.0
		caps_with_sword.stats.sword_cooldown.effective = 0.16
		room.player.set_capabilities(caps_with_sword)
		var post_defeat_hits: Array = []
		room.player.attack.connect(func(_origin, _facing, _reach, _damage, _arc): post_defeat_hits.append(true))
		room.player.start_dash()
		room.player.advance_unified(0.02, Vector2.ZERO)
		room.player.start_attack()
		room.obstacles.append(Rect2(390,290,20,20))
		room.obstacles.append(Rect2(490,290,28,20))
		room.player.advance_unified(0.15, Vector2.ZERO)
		_expect(room.player.hp == 0 and post_defeat_hits.is_empty(), "same-tick blocked-return defeat suppresses a later sword hit")
		room.queue_free()
		await process_frame
		room = _room()
		outcomes.clear()
		var defeated: Array = []
		room.phase_outcome.connect(func(value): outcomes.append(value))
		room.player_defeated.connect(func(): defeated.append(true))
		room.player.facing = Vector2.RIGHT
		room.player.start_dash()
		room.obstacles.append(Rect2(490, 290, 28, 20))
		room.player.advance_unified(0.16, Vector2.ZERO)
		_expect(outcomes.size() == 1 and outcomes[0].status == "returned" and room.player.position == Vector2(400,300), "blocked arrival returns to origin")
		room.queue_free()
		await process_frame
		room = _room()
		outcomes.clear()
		room.phase_outcome.connect(func(value): outcomes.append(value))
		room.player_defeated.connect(func(): defeated.append(true))
		room.player.start_dash()
		room.obstacles.append(Rect2(390,290,20,20))
		room.obstacles.append(Rect2(490,290,28,20))
		room.player.advance_unified(0.16, Vector2.ZERO)
		_expect(outcomes.size() == 1 and outcomes[0].status == "blocked_return" and room.player.hp == 0 and defeated.size() == 1, "blocked origin and destination report and defeat once")
		room._phase_arrival({"origin":Vector2(400,300), "destination":Vector2(504,300)})
		_expect(outcomes.size() == 1 and defeated.size() == 1, "dead player cannot emit duplicate outcome or defeat")
		room.queue_free()
		await process_frame
		room = _room()
		outcomes.clear()
		room.phase_outcome.connect(func(value): outcomes.append(value))
		room.player.start_dash()
		if room.has_method("cancel_pending_phase"):
			room.cancel_pending_phase()
			room.player.advance_unified(0.2, Vector2.ZERO)
			_expect(outcomes.is_empty() and room.player.position == Vector2(400,300), "canceled Phase never resolves stale arrival")
			_expect(room.player.hurt(false), "canceling Phase restores player presence")
		else:
			_expect(false, "Room can invalidate an outstanding Phase")
		room.queue_free()
		await process_frame
	var boss = BOSS.new()
	var advance: Array = boss.get_method_list().filter(func(item): return item.name == "advance")
	_expect(not advance.is_empty() and advance[0].args.size() >= 4, "guardian can advance without a present target")
	if not advance.is_empty() and advance[0].args.size() >= 4:
		var body := CharacterBody2D.new()
		boss.configure({"body":body, "hp":10, "radius":14}, Vector2(100,0))
		boss.phase = "wave"
		boss.wave_origin = Vector2.ZERO
		boss.wave_radius = 80
		boss.gap_angle = PI
		boss.advance(0.1, Vector2(100,0), 0, false)
		_expect(not boss.wave_touched, "wave does not consume its hit while player absent")
		boss.advance(0.01, Vector2(100,0), 0, true)
		_expect(boss.wave_touched, "wave still hits the later present player")
		body.free()
	boss.free()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	if not game.has_signal("phase_outcome") or not game.has_signal("restriction_changed"):
		_expect(false, "coordinator exposes outcome and restriction events")
	else:
		var forwarded: Array = []
		game.phase_outcome.connect(func(value): forwarded.append(value))
		var previous = game.room
		previous.phase_outcome.emit({"status":"landed"})
		_expect(forwarded.size() == 1, "coordinator forwards current-room outcome")
		game._enter_room(game.current, "", game.room.player.hp)
		previous.phase_outcome.emit({"status":"returned"})
		_expect(forwarded.size() == 1, "old-room events are ignored after replacement")
	game.queue_free()
	await process_frame
	var scene = load("res://main.tscn").instantiate()
	if not scene.has_method("_build_max_hp"):
		_expect(false, "coordinator supports unified build HP and status")
		scene.free()
	else:
		scene.data_override = {
			"root":"start", "initial_capacity":1, "capability_model":"unified_1",
			"nodes":{"start":{"id":"start", "name":"Start", "template":"home", "cost":0, "requires_all":[], "requires_any":[], "abilities":[], "map_position":Vector2.ZERO, "contributions":[
				{"id":"dash", "kind":"quality", "quality":"dash"},
				{"id":"phase", "kind":"quality", "quality":"phase_teleport"}
			]}},
			"templates":{"home":{"obstacles":[], "enemies":[], "pickups":[], "objects":[], "spawn":Vector2(400,300), "clear":{"effects":[{"kind":"become_root"}]}}},
			"links":[], "interactions":[]
		}
		root.add_child(scene)
		await process_frame
		scene.room.player.set_physics_process(false)
		_expect(scene.tree_ui.snapshot.current_build.model == "unified_1" and scene.room.player.max_hp == 5, "coordinator publishes unified build and initializes player HP")
		var actual: Array = []
		var started: Array = []
		var lock_states: Array = []
		scene.phase_outcome.connect(func(value): actual.append(value))
		scene.phase_started.connect(func(value): started.append(value))
		scene.restriction_changed.connect(func(value): lock_states.append(value))
		var old_room = scene.room
		old_room.player.start_dash()
		_expect(started.size() == 1 and started[0].destination == Vector2(504,300) and not lock_states.is_empty(), "coordinator forwards actual start and restriction payloads")
		old_room.obstacles.append(Rect2(390,290,20,20))
		old_room.obstacles.append(Rect2(490,290,28,20))
		old_room.player.advance_unified(0.16, Vector2.ZERO)
		_expect(actual.size() == 1 and actual[0].status == "blocked_return" and scene.transition_pending, "blocked return emits outcome and queues guarded defeat")
		await process_frame
		_expect(scene.room != old_room and scene.room.player.hp == 5, "guarded defeat replaces room and restores build HP")
		old_room = scene.room
		old_room.player.set_physics_process(false)
		old_room.player.start_dash()
		scene._queue_transition("defeat", "start")
		old_room.player.advance_unified(0.16, Vector2.ZERO)
		_expect(actual.size() == 1, "queued transition invalidates a pending arrival")
		await process_frame
		scene.queue_free()
		await process_frame
	for failure in failures:
		printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
