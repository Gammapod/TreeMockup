extends SceneTree

# BUILD-01: multiplicative, reversible tradeoffs; captured actions; HP never heals.
# A1: new modifiers compile and invalid multipliers are rejected.
const STORE = preload("res://authoring/content_store.gd")
const ADAPTER = preload("res://authoring/runtime_adapter.gd")
const MODEL = preload("res://progression.gd")
const PLAYER = preload("res://player.gd")
const ROOM = preload("res://room.gd")
var failures: Array[String] = []
var hits: Array = []

func _init() -> void:
	_run.call_deferred()

func _document(modifiers: Array) -> Dictionary:
	var store = STORE.new()
	var doc: Dictionary = store.new_project()
	doc.dungeon.initial_capacity = 20
	doc.dungeon.nodes[0].abilities = ["sword", "dash"]
	doc.dungeon.nodes[0].modifiers = {"sword_damage_bonus": 7}
	var leaf: Dictionary = store.new_room("leaf")
	doc.rooms.append(leaf)
	for i in range(modifiers.size()):
		var id := "upgrade_" + str(i)
		var node: Dictionary = store.new_node(id, "leaf")
		node.modifiers = modifiers[i]
		doc.dungeon.nodes.append(node)
		doc.rooms[0].ports.append({"id": id, "position": [100 + i * 60, 85]})
		doc.dungeon.links.append({"id": id, "a": "start", "b": id, "a_port": id, "b_port": "south", "activate_from": ["start", id]})
	return doc

func _run() -> void:
	var player = PLAYER.new()
	player.hp = 2
	player.set_capabilities({"max_hp": 10, "abilities": {}})
	_expect(player.hp == 2 and player.max_hp == 10, "HP increases never heal")
	player.set_capabilities({"max_hp": 1, "abilities": {}})
	player.set_capabilities({"max_hp": 10, "abilities": {}})
	_expect(player.hp == 1, "Refund and reactivation cannot heal")
	player.free()
	var doc := _document([
		{"sword_range_multiplier": 1.3, "sword_arc_multiplier": 0.7},
		{"sword_range_multiplier": 1.3, "sword_arc_multiplier": 0.7},
		{"sword_arc_multiplier": 1.5, "sword_damage_multiplier": 0.75},
		{"sword_arc_multiplier": 1.5, "sword_damage_multiplier": 0.75},
		{"sword_cooldown_multiplier": 0.75, "sword_range_multiplier": 0.8},
		{"sword_cooldown_multiplier": 0.75, "sword_range_multiplier": 0.8},
		{"dash_distance_multiplier": 1.4, "dash_cooldown_multiplier": 1.4},
		{"dash_distance_multiplier": 0.75, "dash_cooldown_multiplier": 0.7},
		{"dash_style": "phase"}
	])
	var compiled: Dictionary = ADAPTER.new().compile(doc)
	_expect(compiled.ok, "A1: BUILD-01 vocabulary compiles: " + str(compiled.errors))
	var bad := doc.duplicate(true)
	bad.dungeon.nodes[1].modifiers.sword_arc_multiplier = 0
	_expect(not ADAPTER.new().compile(bad).ok, "A1: zero multiplier rejected")
	if compiled.ok:
		var model = MODEL.new(compiled.data)
		var base: Dictionary = model.capabilities()
		for id in ["upgrade_0", "upgrade_1"]:
			_expect(model.activate(id, "start").ok, "Thrust stacks are allocatable")
		_expect(is_equal_approx(model.capabilities().sword_range, base.sword_range * 1.69), "Two Thrust reach multipliers compose")
		_expect(is_equal_approx(model.capabilities().get("sword_arc", 0.0), 1.8 * 0.49), "Two Thrust arc multipliers compose")
		model.deactivate("upgrade_0", "start")
		model.deactivate("upgrade_1", "start")
		_expect(model.capabilities() == base, "Refund restores base stats exactly")
		model.activate("upgrade_2", "start")
		model.activate("upgrade_3", "start")
		_expect(is_equal_approx(model.capabilities().sword_damage, 4.5), "Fractional damage survives stacking without truncation")
		model.deactivate("upgrade_2", "start")
		model.deactivate("upgrade_3", "start")
		model.activate("upgrade_4", "start")
		model.activate("upgrade_5", "start")
		player = PLAYER.new()
		player.set_capabilities(model.capabilities())
		player.attack.connect(func(_origin, _facing, reach, damage, arc): hits.append([reach, damage, arc]))
		_expect(player.start_attack(), "Quick Cut starts")
		var captured: Dictionary = model.capabilities()
		player.set_capabilities(base)
		player.advance_attack(0.14)
		_expect(hits.size() == 1 and is_equal_approx(hits[0][0], captured.sword_range), "Action retains captured reach and fixed startup")
		_expect(not player.start_attack(), "Attack interval still blocks early repeat")
		player.advance_attack(0.04)
		_expect(player.start_attack(), "Two Quick Cuts actually allow 0.18-second attack interval")
		model.activate("upgrade_6", "start")
		model.activate("upgrade_7", "start")
		model.activate("upgrade_8", "start")
		player.set_capabilities(model.capabilities())
		_expect(player.start_dash(), "Modified dash starts")
		_expect(is_equal_approx(player.dash_time * player.dash_speed, 104.0 * 1.4 * 0.75 * 0.65), "Distance includes numeric stacks and Phase tradeoff")
		_expect(is_equal_approx(player.dash_cooldown, 0.65 * 1.4 * 0.7), "Dash recharge uses composed stats")
		player.set_capabilities(base)
		_expect(not player.hurt(), "Phase protection captured for active dash")
		player.dash_time = 0
		_expect(player.hurt(), "Phase protection ends after dash")
		player.free()
		await _geometry(captured)
		await _dash_distance(model.capabilities())
	_finish()

func _geometry(caps: Dictionary) -> void:
	var room = ROOM.new()
	root.add_child(room)
	var target := Vector2(400, 300)
	var template := {"obstacles": [], "pickups": [], "enemies": [
		{"id": "front", "position": target + Vector2(60, 0), "hp": 20, "speed": 0},
		{"id": "side", "position": target + Vector2(45, 55), "hp": 20, "speed": 0}
	]}
	room.configure(template, [], {}, {}, "", caps, 5)
	room.set_physics_process(false)
	room.player.set_physics_process(false)
	await physics_frame
	room.call("_attack", target, Vector2.RIGHT, 92, 4.5, 0.5)
	_expect(is_equal_approx(room.enemies[0].hp, 15.5) and room.enemies[1].hp == 20, "Narrow arc hits forward enemy with fractional damage, misses side")
	room.call("_attack", target, Vector2.RIGHT, 92, 4.5, 2.2)
	_expect(is_equal_approx(room.enemies[1].hp, 15.5), "Widened arc reaches side enemy")
	room.queue_free()
	await process_frame

func _dash_distance(caps: Dictionary) -> void:
	var player = PLAYER.new()
	root.add_child(player)
	player.set_capabilities(caps)
	player.position = Vector2(100, 100)
	player.start_dash()
	for i in range(60):
		await physics_frame
		if player.dash_time <= 0.0:
			break
	_expect(is_equal_approx(player.position.x - 100.0, caps.dash_distance), "Unobstructed movement covers displayed dash distance, including partial final tick")
	player.queue_free()
	await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("All BUILD-01 ability tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
