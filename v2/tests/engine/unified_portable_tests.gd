extends "res://tests/suite_reporter.gd"

# UAB8: portable source compiles non-destructively into an actual unified run.
const STORE = preload("res://authoring/content_store.gd")
const ADAPTER = preload("res://authoring/runtime_adapter.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _source() -> Dictionary:
	var store = STORE.new()
	var document: Dictionary = store.new_project()
	document.dungeon.capability_model = "unified_1"
	document.dungeon.nodes[0].contributions = [
		{"id":"dash", "kind":"quality", "quality":"dash"},
		{"id":"phase", "kind":"quality", "quality":"phase_teleport"},
		{"id":"root", "kind":"quality", "quality":"dash_root"}
	]
	document.rooms[0].spawn = [400, 300]
	document.rooms[0].objects = [
		{"id":"obstacle", "kind":"obstacle", "position":[440,250], "size":[20,100], "properties":{}},
		{"id":"enemy", "kind":"enemy", "position":[504,300], "properties":{"hp":10, "speed":0}}
	]
	document.rooms.append(store.new_room("leaf_room"))
	var leaf: Dictionary = store.new_node("leaf", "leaf_room")
	leaf.contributions = [{"id":"flippers", "kind":"quality", "quality":"water_pass"}]
	document.dungeon.nodes.append(leaf)
	document.dungeon.links.append({"id":"edge", "a":"start", "b":"leaf", "a_port":"east", "b_port":"west", "activate_from":["start", "leaf"]})
	document.extensions = {"future":{"retained":true}}
	return document

func _run() -> void:
	var document := _source()
	var before := document.duplicate(true)
	var adapter = ADAPTER.new()
	var methods: Array = adapter.get_method_list().filter(func(item): return item.name == "compile")
	if methods.is_empty() or methods[0].args.size() < 2:
		_expect(false, "explicit experimental compilation is available")
		for failure in failures:
			printerr("ASSERTION FAILED: " + failure)
		_complete(1)
		return
	var compiled: Dictionary = adapter.call("compile", document, true)
	_expect(compiled.ok, "V1 unified portable bundle compiles")
	_expect(document == before, "compilation never mutates source")
	var parsed: Dictionary = STORE.new().parse_document(JSON.stringify(document))
	_expect(parsed.ok and parsed.document.extensions.future.retained, "portable round trip preserves unknown content")
	var bad := document.duplicate(true)
	bad.dungeon.nodes[0].abilities = ["dash"]
	_expect(not adapter.call("compile", bad, true).ok, "experimental compile never bypasses mixed-vocabulary validation")
	bad = document.duplicate(true)
	bad.dungeon.nodes[0].contributions[0].quality = "future"
	_expect(not adapter.call("compile", bad, true).ok, "experimental compile rejects unknown quality")
	var legacy: Dictionary = STORE.new().new_project()
	legacy.dungeon.nodes[0].abilities = ["dash"]
	legacy.dungeon.nodes[0].modifiers = {"dash_style":"run"}
	var legacy_before := legacy.duplicate(true)
	var legacy_compiled: Dictionary = adapter.compile(legacy)
	_expect(legacy_compiled.ok and legacy == legacy_before, "legacy compilation remains non-destructive")
	if legacy_compiled.ok:
		_expect(preload("res://progression.gd").new(legacy_compiled.data).capabilities().sprint, "legacy run style keeps legacy meaning")
	var migrated: Dictionary = STORE.new().migrate(document)
	var v2: Dictionary = adapter.call("compile", migrated, true)
	_expect(v2.ok and migrated.version == 2, "V2 unified portable bundle compiles")
	if compiled.ok:
		var game = load("res://main.tscn").instantiate()
		game.data_override = compiled.data
		root.add_child(game)
		await process_frame
		game.room.player.set_physics_process(false)
		_expect(game.tree_ui.snapshot.current_build.model == "unified_1", "coordinator publishes compiled unified build")
		var preview: Dictionary = game.progression.preview_activation("leaf", "start")
		_expect(preview.ok and preview.build_after.qualities.water_pass.effective, "portable node produces authoritative activation preview")
		game._toggle("leaf")
		_expect(game.tree_ui.snapshot.current_build.qualities.water_pass.effective, "live activation updates copied current build")
		var outcomes: Array = []
		game.phase_outcome.connect(func(value): outcomes.append(value))
		game.room.player.facing = Vector2.RIGHT
		_expect(game.room.player.start_dash(), "portable Phase can start")
		game.room.player.advance_unified(0.16, Vector2.ZERO)
		_expect(outcomes.size() == 1 and outcomes[0].status == "landed" and outcomes[0].contact_damage == 1, "portable Phase crosses obstacle and applies arrival contact")
		game.queue_free()
		await process_frame
	for failure in failures:
		printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
