extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var script = load("res://authoring/content_store.gd")
	if script == null:
		push_error("C1-C6: portable content store is not implemented")
		quit(1)
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
	for example in ["branching", "water_flippers", "switch_wall", "combat"]:
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
	game.data = adapter.compile(water_doc.document).data
	game.progression = load("res://progression.gd").new(game.data)
	game.progression.activate("water", "start")
	game._enter_room("water", "east", 5)
	_expect(game.room.barriers.water_strip.collision_layer == 1, "Water blocks without flippers")
	game.progression.activate("flippers", "start")
	game._refresh()
	_expect(game.room.barriers.water_strip.collision_layer == 0, "Cross-branch flippers capability removes water collision")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if failures.is_empty():
		print("All portable content contract tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
