extends "res://tests/suite_reporter.gd"

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var script = load("res://authoring/content_store.gd")
	if script == null:
		push_error("C1-C6: portable content store is not implemented")
		_complete(1)
		return
	var store = script.new()
	var doc: Dictionary = store.new_project()
	doc.extensions = {"test.custom": {"preserve": [1, "hello", true]}}
	doc.rooms[0].objects.append({"id": "loot", "kind": "pickup", "position": [200, 200], "properties": {"kind": "capacity"}, "future_field": {"x": 7}})
	var path := "user://content_contract_test.json"
	_expect(store.save_document(path, doc).ok, "C1: valid document saves")
	var loaded: Dictionary = store.load_document(path)
	# JSON has one number type; Godot parses numbers as floats. Compare normalized
	# JSON values rather than Godot's int-vs-float-sensitive container equality.
	_expect(loaded.ok and loaded.document == JSON.parse_string(JSON.stringify(doc)), "C1: unknown nested fields and stable IDs survive round trip")
	var original := FileAccess.get_file_as_string(path)
	var bad := doc.duplicate(true)
	bad.dungeon.nodes[0].template = "missing"
	_expect(not store.validate(bad).is_empty(), "C2: dangling template rejected")
	_expect(not store.save_document(path, bad).ok and FileAccess.get_file_as_string(path) == original, "C2: invalid save cannot overwrite valid document")
	bad = doc.duplicate(true)
	bad.rooms[0].objects.append(bad.rooms[0].objects[0].duplicate(true))
	_expect(not store.validate(bad).is_empty(), "C2: duplicate local object IDs rejected")
	bad = doc.duplicate(true)
	bad.dungeon.initial_capacity = -1
	_expect(not store.validate(bad).is_empty(), "C2: negative budgets rejected")
	bad = doc.duplicate(true)
	bad.version = 999
	_expect(not store.validate(bad).is_empty(), "C3: future version rejected")
	_expect(not store.parse_document("{broken").ok, "C2: malformed JSON rejected")
	bad = doc.duplicate(true)
	bad.rooms[0].size = "bad"
	_expect(not store.validate(bad).is_empty(), "C2: malformed geometry returns errors rather than crashing")
	var second: Dictionary = doc.dungeon.nodes[0].duplicate(true)
	second.id = "second"
	second.cost = 1
	second.requires_all = ["start"]
	doc.dungeon.nodes.append(second)
	doc.dungeon.links.append({"id": "passage", "a": "start", "b": "second", "a_port": "east", "b_port": "west", "activate_from": ["start", "second"]})
	var adapter = load("res://authoring/runtime_adapter.gd").new()
	for example in ["branching", "water_flippers", "switch_wall", "combat", "cleared_rooms"]:
		var fixture: Dictionary = store.load_document("res://examples/" + example + ".json")
		_expect(fixture.ok and adapter.compile(fixture.document).ok, "Example validates and compiles: " + example)
	var compiled: Dictionary = adapter.compile(doc)
	_expect(compiled.ok, "C4: reusable template compiles")
	if compiled.ok:
		var model = load("res://progression.gd").new(compiled.data)
		model.activate("second", "start")
		_expect(model.collect("start", "loot") and model.collect("second", "loot"), "C4: shared template rewards have separate identities")
	doc.rooms[0].objects.append({"id": "lever", "kind": "switch", "position": [400, 200], "properties": {}})
	doc.rooms[0].objects.append({"id": "barrier", "kind": "wall", "position": [400, 300], "size": [30, 160], "properties": {}})
	doc.dungeon.interactions.append({"id": "remote_wall", "source": {"node": "start", "object": "lever", "event": "toggled"}, "target": {"node": "second", "object": "barrier", "action": "set_open"}})
	_expect(store.validate(doc).is_empty(), "C5: cross-room stable references resolve")
	bad = doc.duplicate(true)
	bad.dungeon.interactions[0].target.object = "missing"
	_expect(not store.validate(bad).is_empty(), "C5: dangling interaction target rejected")
	bad = doc.duplicate(true)
	bad.rooms[0].objects.append({"id": "future", "kind": "future_enemy", "position": [100, 100], "properties": {}})
	_expect(store.validate(bad).is_empty() and not adapter.compile(bad).ok, "C6: future mechanics preserved but not silently played")
	# C5 runtime integration: a switch must update a currently unloaded target.
	var switch_doc: Dictionary = store.load_document("res://examples/switch_wall.json")
	var switch_data: Dictionary = adapter.compile(switch_doc.document)
	var game = load("res://main.tscn").instantiate()
	game.data_override = switch_data.data
	root.add_child(game)
	await process_frame
	game.progression.capacity = 20
	game.progression.activate("fork", "start")
	game.progression.activate("wall", "fork")
	game.progression.activate("sword", "fork")
	game.progression.activate("switch", "sword")
	game._enter_room("switch", "west", 5)
	game._switch_toggled("switch")
	game._enter_room("wall", "east", 5)
	_expect(game.room.object_states.get("barrier", false), "C5: unloaded wall receives persistent switch state")
	_expect(game.room.barriers.barrier.collision_layer == 0, "C5: loaded target applies persistent wall state")
	game._enter_room("switch", "west", 5)
	game._switch_toggled("switch")
	game._enter_room("wall", "east", 5)
	_expect(game.room.barriers.barrier.collision_layer == 1, "C5: toggling off restores unloaded wall")
	var water_doc: Dictionary = store.load_document("res://examples/water_flippers.json")
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	game.data_override = adapter.compile(water_doc.document).data
	root.add_child(game)
	await process_frame
	game.progression.activate("water", "start")
	game._enter_room("water", "east", 5)
	_expect(game.room.barriers.water_strip.collision_layer == 1, "Water blocks without flippers")
	game.progression.activate("flippers", "start")
	game._refresh()
	_expect(game.room.barriers.water_strip.collision_layer == 0, "Cross-branch flippers capability removes water collision")
	game.queue_free()
	await process_frame
	await _health_pickup_contract(store, adapter)
	var room_script = load("res://room.gd")
	_expect(room_script.has_method("pickup_visual_style"), "H3: room exposes a distinct health pickup/chest visual style")
	if room_script.has_method("pickup_visual_style"):
		var loose: Dictionary = room_script.pickup_visual_style({"kind": "health", "value": 4, "chest": false})
		var chest: Dictionary = room_script.pickup_visual_style({"kind": "health", "value": 4, "chest": true})
		_expect(loose.get("symbol") == "cross" and chest.get("symbol") == "cross" and loose.get("value") == 4 and chest.get("value") == 4, "H3: health pickup and chest expose a cross and authored value")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if failures.is_empty():
		print("All portable content contract tests passed.")
		_complete(0)
	else:
		for failure in failures:
			printerr("ASSERTION FAILED: " + failure)
		_complete(1)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)

func _health_pickup_contract(store, adapter) -> void:
	var doc: Dictionary = store.new_project()
	doc.dungeon.base_hp = 1
	doc.rooms[0].objects.append({"id": "medicine", "kind": "pickup", "position": [400, 400], "properties": {"kind": "health", "value": 3}})
	var compiled: Dictionary = adapter.compile(doc)
	_expect(compiled.ok, "H2: authored positive health pickup compiles")
	var bad: Dictionary = doc.duplicate(true)
	bad.rooms[0].objects[0].properties.value = 0
	_expect(not adapter.compile(bad).ok, "H2: zero healing is rejected")
	bad.rooms[0].objects[0].properties.value = 1.5
	_expect(not adapter.compile(bad).ok, "H2: fractional healing is rejected")
	if not compiled.ok:
		return
	var game = load("res://main.tscn").instantiate()
	game.data_override = compiled.data
	root.add_child(game)
	await process_frame
	game.room.player.position = Vector2(400, 400)
	game.room._physics_process(0.0)
	_expect(not game.progression.collected.has("start/medicine"), "H2: full-health contact does not consume pickup")
	game.data.nodes.start.modifiers = {"max_hp_bonus": 4}
	game._refresh()
	_expect(game.room.player.hp == 1 and game.room.player.max_hp == 5, "H2: maximum increase does not heal")
	game.room._physics_process(0.0)
	_expect(game.room.player.hp == 4 and game.progression.collected.has("start/medicine"), "H2: pickup heals fixed amount and persists")
	game._enter_room("start", "", 4)
	_expect(game.room.pickups.is_empty(), "H2: collected pickup stays absent on reentry")
	game._start_run(compiled.data)
	_expect(not game.progression.collected.has("start/medicine"), "H2: fresh run resets collection")
	game.room.player.hp = 4
	game.room.player.position = Vector2(400, 400)
	game.room._physics_process(0.0)
	_expect(game.room.player.hp == 5, "H2: healing is capped at maximum HP")
	var second: Dictionary = compiled.data.nodes.start.duplicate(true)
	compiled.data.nodes.other = second
	game.progression.active.other = true
	_expect(game.progression.collect("other", "medicine", 1, 5), "H2: reused template has independent node/object collection")
	_expect(game.progression.gold == 0, "H2: healing does not grant gold")
	game.queue_free()
	await process_frame
