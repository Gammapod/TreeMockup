extends "res://tests/suite_reporter.gd"

const STORE = preload("res://authoring/content_store.gd")
const LAYOUT = preload("res://authoring/door_layout.gd")
const ADAPTER = preload("res://authoring/runtime_adapter.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var store := STORE.new()
	var adapter := ADAPTER.new()
	for example in ["branching", "build_arena", "switch_wall", "water_flippers", "combat", "cleared_rooms"]:
		var old: Dictionary = store.load_document("res://examples/" + example + ".json").document
		var before := JSON.stringify(old)
		var upgraded := store.migrate(old)
		_expect(JSON.stringify(old) == before, "Migration does not mutate source")
		_expect(store.validate(upgraded).is_empty(), example + " migrates to valid v2")
		_expect(store.migrate(upgraded) == upgraded, "Migration is idempotent")
		var legacy: Dictionary = adapter.compile(old).data
		var compiled := adapter.compile(upgraded)
		_expect(compiled.ok, example + " compiles after migration")
		if compiled.ok:
			for link in old.dungeon.links:
				for end in ["a", "b"]:
					if old.version == 1:
						var old_point: Vector2 = legacy.templates[legacy.nodes[link[end]].template].ports[link[end + "_port"]]
						_expect(compiled.data.nodes[link[end]].ports[link.id + "_" + end] == old_point, "Migration preserves exact arrival")
					else:
						_expect(compiled.data.nodes[link[end]].ports.has(link.id + "_" + end), "V2 bundle keeps resolved instance door")
	var doc := store.migrate(store.new_project())
	doc.rooms[0].erase("ports")
	for i in range(3):
		var node := store.new_node("next" + str(i), "empty")
		node.map_position = [500, -100 + i * 100]
		doc.dungeon.nodes.append(node)
		doc.dungeon.links.append({"id": "edge" + str(i), "a": "start", "b": node.id, "activate_from": ["start", node.id]})
	doc.dungeon.nodes[0].map_position = [100, 0]
	var original := JSON.stringify(doc)
	var layout := LAYOUT.resolve(doc)
	_expect(JSON.stringify(doc) == original, "Resolution does not mutate source")
	_expect(layout.errors.is_empty(), "Three doors fit")
	var doors: Array = layout.nodes.start
	_expect(doors.all(func(d): return d.wall == "east"), "Angles choose east wall")
	_expect(doors[0].position.y < doors[1].position.y and doors[1].position.y < doors[2].position.y, "Angular order becomes spatial order")
	_expect(doors[1].position.y - doors[0].position.y >= 80, "Doors maintain clearance")
	_expect(layout == LAYOUT.resolve(doc), "Resolution deterministic")
	var reserved := doc.duplicate(true)
	reserved.dungeon.links[1].a_door = {"wall": "east", "offset": 0.5, "automatic": true, "id": "extension"}
	var fixed_layout := LAYOUT.resolve(reserved)
	_expect(fixed_layout.errors.is_empty(), "Automatic placement can reserve room for a manual door")
	var fixed_doors: Array = fixed_layout.nodes.start
	_expect(not fixed_doors[1].automatic and fixed_doors[1].id == "edge1_a", "Unknown override fields do not alter identity or mode")
	_expect(absf(fixed_doors[0].position.y - 320) >= 80 and absf(fixed_doors[2].position.y - 320) >= 80, "Automatic doors avoid manual door")
	doc.dungeon.links.reverse()
	var reverse := LAYOUT.resolve(doc)
	for door in doors:
		_expect(reverse.nodes.start.filter(func(d): return d.id == door.id)[0].position == door.position, "Array ordering cannot move doors")
	doc.dungeon.links.reverse()
	doc.dungeon.links[0].a_door = {"wall": "north", "offset": 0.25}
	doc.dungeon.nodes[1].map_position = [-400, 0]
	layout = LAYOUT.resolve(doc)
	_expect(layout.nodes.start[0].position == Vector2(250, 85), "Manual placement survives graph move")
	doc.dungeon.links[0].erase("a_door")
	layout = LAYOUT.resolve(doc)
	_expect(layout.nodes.start[0].wall == "west", "Reset resumes graph placement")
	var round_trip := store.parse_document(JSON.stringify(doc))
	_expect(round_trip.ok and adapter.compile(round_trip.document).ok, "V2 JSON round trip compiles without template ports")
	var malformed := doc.duplicate(true)
	malformed.dungeon.links[0].a_door = {"wall": "up", "offset": 2}
	_expect(not store.validate(malformed).is_empty(), "Malformed override rejected")
	var crowded := doc.duplicate(true)
	for i in range(10):
		var node := store.new_node("crowd" + str(i), "empty")
		node.map_position = [900, i]
		crowded.dungeon.nodes.append(node)
		crowded.dungeon.links.append({"id": node.id, "a": "start", "b": node.id, "activate_from": ["start"]})
	_expect(not adapter.compile(crowded).ok, "Crowded automatic wall blocks playtest")
	var data: Dictionary = adapter.compile(doc).data
	var game = load("res://main.tscn").instantiate()
	game.data_override = data
	root.add_child(game)
	await process_frame
	_expect(game.room.ports == data.nodes.start.ports, "Room receives instance ports")
	game.progression.activate("next0", "start")
	game._refresh()
	_expect(game.room.ports == data.nodes.start.ports, "Activation does not rearrange doors")
	var portal: Dictionary = game.room.portals.filter(func(p): return p.destination == "next0")[0]
	_expect(portal.port == "edge0_a" and portal.entry == "edge0_b", "Paired generated endpoint IDs")
	game._enter_room("next0", portal.entry, game.room.player.hp)
	await process_frame
	_expect(game.room.player.position.distance_to(data.nodes.next0.ports.edge0_b) < 1, "Arrival uses destination instance door")
	# The authoring panel displays the same resolved coordinates and resets source.
	var panel = load("res://authoring/door_editor.gd").new()
	root.add_child(panel)
	panel.setup(doc, "start")
	_expect(panel.canvas.instance_doors == LAYOUT.resolve(doc).nodes.start, "Preview matches runtime resolver")
	panel._drag("edge0_a", Vector2(400, 70))
	_expect(doc.dungeon.links[0].a_door.wall == "north", "Direct manipulation writes only endpoint override")
	panel._reset()
	_expect(not doc.dungeon.links[0].has("a_door"), "Reset removes endpoint override")
	panel.queue_free()
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("All instance door tests passed.")
	else:
		for failure in failures:
			printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
