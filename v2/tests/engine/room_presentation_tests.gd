extends "res://tests/suite_reporter.gd"

# RP1: copied room-local presentation facts follow live room lifecycle.
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _fixture() -> Dictionary:
	var data: Dictionary = preload("res://tests/fixtures/activation_fixture.gd").create()
	var t: Dictionary = data.templates.practice
	t.obstacles = [Rect2(110, 120, 30, 40)]
	t.objects = [
		{"id":"water", "kind":"water", "position":Vector2(220, 200), "bounds":Rect2(220, 200, 50, 70)},
		{"id":"gate", "kind":"wall", "position":Vector2(300, 200), "bounds":Rect2(300, 200, 30, 60)},
		{"id":"lever", "kind":"switch", "position":Vector2(350, 300)}]
	t.pickups = [
		{"id":"capacity", "position":Vector2(590, 180), "kind":"capacity", "value":2, "chest":false},
		{"id":"gold", "position":Vector2(540, 180), "kind":"gold", "value":4, "chest":false},
		{"id":"gold_chest", "position":Vector2(540, 240), "kind":"gold", "value":5, "chest":true},
		{"id":"medicine", "position":Vector2(500, 220), "kind":"health", "value":3, "chest":true}]
	t.tokens = [{"id":"token", "position":Vector2(400, 300)}]
	t.enemies = [{"id":"guardian", "position":Vector2(550, 350), "hp":120, "speed":0, "radius":38, "behavior":"roost_guardian"}]
	t.clear = {"conditions":[{"kind":"switch_hit", "object":"lever"}], "effects":[{"kind":"reveal_pickup", "object":"capacity"}]}
	return data

func _find(items: Array, id: String) -> Dictionary:
	for item in items:
		if item.get("id") == id:
			return item
	return {}

func _run() -> void:
	var empty_game = load("res://main.tscn").instantiate()
	if empty_game.has_method("room_presentation_state"):
		_expect(empty_game.room_presentation_state().is_empty(), "no room returns an empty snapshot")
	empty_game.free()
	var game = load("res://main.tscn").instantiate()
	game.data_override = _fixture()
	root.add_child(game)
	await process_frame
	var overlay = game.get("room_feedback")
	_expect(overlay != null, "RP1: coordinator mounts room feedback")
	if overlay != null:
		_expect(overlay.get_parent() == game.shell.room_viewport and overlay.transform == Transform2D.IDENTITY, "room feedback is aligned in room viewport")
	if not game.has_method("room_presentation_state"):
		_expect(false, "RP1: coordinator exposes room presentation state")
	else:
		game._toggle("sword")
		game._enter_room("sword", "", 5)
		if overlay != null:
			_expect(overlay.get_parent() == game.shell.room_viewport and is_instance_valid(overlay), "room feedback survives replacement")
		var room = game.room
		room.set_physics_process(false)
		room.player.set_physics_process(false)
		var s: Dictionary = game.room_presentation_state()
		_expect(_find(s.pickups, "gold").position == Vector2(540, 180) and not _find(s.pickups, "gold").chest and _find(s.pickups, "gold_chest").chest, "visible loose gold and chest retain actual positions and chest distinction")
		if room.has_method("pickup_drawn_by_room"):
			_expect(not room.pickup_drawn_by_room(_find(s.pickups, "gold")) and not room.pickup_drawn_by_room({"kind":"capacity", "chest":false}) and room.pickup_drawn_by_room(_find(s.pickups, "gold_chest")) and room.pickup_drawn_by_room(_find(s.pickups, "medicine")) and room.pickup_drawn_by_room({"kind":"health", "chest":false}), "room delegates only loose gold and capacity drawing, retaining chests and health")
		else:
			_expect(false, "room exposes its pickup drawing ownership boundary")
		_expect(s.node_id == "sword" and s.generation == game.room_generation, "snapshot identifies current room instance and generation")
		_expect(s.room_bounds == Rect2(35,55,730,530) and s.obstacles == [Rect2(110,120,30,40)] and not s.boundary_walls.is_empty(), "room and current collision geometry exposed")
		_expect(_find(s.objects, "gate").passable == false and _find(s.objects, "water").passable == false and not _find(s.objects, "lever").on, "barriers and switch reflect live state")
		_expect(_find(s.pickups, "capacity").is_empty() and _find(s.pickups, "medicine").kind == "health" and _find(s.pickups, "medicine").value == 3 and _find(s.pickups, "medicine").chest, "hidden reward omitted; visible health chest has actual reward")
		_expect(s.tokens.size() == 1 and s.tokens[0].id == "token", "tokens separate from rewards")
		_expect(_find(s.enemies, "guardian").behavior == "roost_guardian" and _find(s.enemies, "guardian").radius == 38 and _find(s.enemies, "guardian").contact_dangerous and _find(s.enemies, "guardian").summoner == null, "guardian live facts")
		_expect(not s.doors.is_empty() and s.doors[0].has("bounds") and s.doors[0].has("passable"), "doors expose current resolved geometry and passability")
		var open_doors: Array = s.doors.filter(func(door): return door.destination == "start")
		var closed_doors: Array = s.doors.filter(func(door): return door.destination == "sword_landing")
		_expect(open_doors.size() == 1 and open_doors[0].passable and open_doors[0].bounds == Rect2(750,288,15,64) and closed_doors.size() == 1 and not closed_doors[0].passable, "door bounds and passability match enabled and disabled ports")
		s.pickups[0].kind = "changed"
		s.objects.clear()
		_expect(_find(game.room_presentation_state().pickups, "medicine").kind == "health" and not game.room_presentation_state().objects.is_empty(), "snapshots do not alias room state")
		room.apply_object_states({"gate":true, "lever":true})
		_expect(_find(game.room_presentation_state().objects, "gate").passable and _find(game.room_presentation_state().objects, "lever").on, "switch and wall updates are current")
		var caps: Dictionary = room.player.capabilities.duplicate(true)
		caps.abilities["flippers"] = true
		room.player.set_capabilities(caps)
		room.apply_object_states({"gate":true})
		_expect(_find(game.room_presentation_state().objects, "water").passable, "water reports actual collision passability")
		game._enter_room("start", "", 5)
		game._enter_room("sword", "", 5)
		room = game.room
		room.set_physics_process(false)
		room.player.set_physics_process(false)
		s = game.room_presentation_state()
		_expect(_find(s.pickups, "capacity").is_empty() and s.tokens.size() == 1 and s.generation == game.room_generation, "uncleared reentry retains hidden reward and restores token")
		room._summon_bats("guardian", [Vector2(200,200)])
		s = game.room_presentation_state()
		_expect(s.enemies.size() == 2 and s.enemies[1].summoner == "guardian" and s.enemies[1].behavior == "chase" and s.enemies[1].contact_dangerous, "transient summons have actual behavior and ownership")
		var boss = room.bosses.guardian
		boss.advance(8.0, Vector2(400,300), 1, false)
		_expect(not _find(game.room_presentation_state().enemies, "guardian").contact_dangerous, "guardian recovery is contact safe")
		game._switch_toggled("lever")
		s = game.room_presentation_state()
		_expect(not _find(s.pickups, "capacity").is_empty() and s.tokens.is_empty(), "clear reveals reward and suppresses token")
		game._collect("capacity")
		_expect(_find(game.room_presentation_state().pickups, "capacity").is_empty(), "collection immediately removes reward")
		game._collect("gold")
		_expect(_find(game.room_presentation_state().pickups, "gold").is_empty(), "loose gold collection immediately removes its presentation fact")
		room._defeat_enemy(room.enemies[0])
		game._enter_room("start", "", 5)
		game._enter_room("sword", "", 5)
		s = game.room_presentation_state()
		_expect(_find(s.pickups, "capacity").is_empty() and s.tokens.is_empty() and s.enemies.is_empty(), "reentry preserves collection, clear, and defeated enemy; summons do not persist")
		_expect(_find(s.pickups, "gold").is_empty() and not _find(s.pickups, "gold_chest").is_empty(), "reentry preserves collected loose gold and uncollected chest")
		game._start_run(_fixture())
		game._toggle("sword")
		game._enter_room("sword", "", 5)
		s = game.room_presentation_state()
		_expect(_find(s.pickups, "capacity").is_empty() and s.tokens.size() == 1 and s.enemies.size() == 1, "fresh run resets encounter and hidden reward")
		_expect(not _find(s.pickups, "gold").is_empty() and not _find(s.pickups, "gold_chest").is_empty(), "fresh run restores loose gold and chest")
	game.queue_free()
	await process_frame
	for failure in failures:
		printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _expect(value: bool, message: String) -> void:
	assertion_count += 1
	if not value:
		failures.append(message)
