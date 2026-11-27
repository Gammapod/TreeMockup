extends "res://tests/suite_reporter.gd"

# A7: explicit node icon identifiers are portable presentation-only metadata.
const STORE = preload("res://authoring/content_store.gd")
const ADAPTER = preload("res://authoring/runtime_adapter.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var store := STORE.new()
	var adapter := ADAPTER.new()
	var doc: Dictionary = store.new_project()
	doc.dungeon.nodes[0].abilities = ["sword"]
	doc.dungeon.nodes[0]["future_data"] = {"array":[1, {"keep":true}]}
	_expect(not doc.dungeon.nodes[0].has("icon_id"), "new project does not invent an icon")
	var without: Dictionary = adapter.compile(doc)
	_expect(without.ok and not without.data.nodes.start.has("icon_id"), "compilation does not infer icon from ability")
	doc.dungeon.nodes[0]["icon_id"] = "future_Icon-42"
	var before := JSON.stringify(doc)
	_expect(store.validate(doc).is_empty(), "unknown well-formed icon ID validates")
	var compiled: Dictionary = adapter.compile(doc)
	_expect(compiled.ok and compiled.data.nodes.start.icon_id == "future_Icon-42", "v1 runtime map definition preserves exact icon ID")
	_expect(JSON.stringify(doc) == before, "compilation never mutates source")
	compiled.data.nodes.start.future_data.array[1].keep = false
	_expect(doc.dungeon.nodes[0].future_data.array[1].keep, "compiled node metadata is detached")
	var roundtrip: Dictionary = store.parse_document(before)
	_expect(roundtrip.ok and roundtrip.document.dungeon.nodes[0].icon_id == "future_Icon-42" and roundtrip.document.dungeon.nodes[0].future_data.array[1].keep, "JSON parse preserves icon and unknown nested fields")
	var path := "user://node_icon_contract.json"
	_expect(store.save_document(path, doc).ok, "valid icon saves")
	var loaded: Dictionary = store.load_document(path)
	_expect(loaded.ok and loaded.document.dungeon.nodes[0].icon_id == "future_Icon-42" and loaded.document.dungeon.nodes[0].future_data.array[1].keep, "save/load preserves icon and unknown fields")
	_expect(store.has_method("is_valid_node_icon_id"), "typed editors have a shared strict icon predicate")
	if store.has_method("is_valid_node_icon_id"):
		_expect(store.is_valid_node_icon_id("future_Icon-42"), "typed icon predicate accepts stable ID")
	for bad_value in ["", "white space", "../sword", "icon.svg", "é", "line\n", null, 1, {"nested":[1, {"keep":true}]}, [1, "future"]]:
		var bad := doc.duplicate(true)
		bad.dungeon.nodes[0].icon_id = bad_value
		var original := JSON.stringify(bad)
		_expect(store.validate(bad).is_empty(), "opaque legacy icon value is accepted: " + str(bad_value))
		var legacy_compiled: Dictionary = adapter.compile(bad)
		_expect(legacy_compiled.ok and not legacy_compiled.data.nodes.start.has("icon_id"), "malformed icon is omitted only from runtime map definition")
		_expect(JSON.stringify(bad) == original, "runtime filtering never alters source")
		_expect(store.save_document(path, bad).ok, "opaque value can be saved")
		var reread: Dictionary = store.load_document(path)
		_expect(reread.ok and reread.document == JSON.parse_string(original), "save/load preserves opaque icon and other fields")
		var upgraded: Dictionary = store.migrate(bad)
		_expect(JSON.stringify(upgraded.dungeon.nodes[0].icon_id) == JSON.stringify(bad_value) and JSON.stringify(bad) == original, "explicit migration preserves opaque icon without source mutation")
		var compiled_v2: Dictionary = adapter.compile(upgraded)
		_expect(compiled_v2.ok and not compiled_v2.data.nodes.start.has("icon_id") and JSON.stringify(upgraded.dungeon.nodes[0].icon_id) == JSON.stringify(bad_value), "v2 filters opaque icon only from runtime")
		if store.has_method("is_valid_node_icon_id"):
			_expect(not store.is_valid_node_icon_id(bad_value), "typed editor rejects invalid ID")
	var migrated: Dictionary = store.migrate(doc)
	_expect(doc.version == 1 and migrated.version == 2 and migrated.dungeon.nodes[0].icon_id == "future_Icon-42" and migrated.dungeon.nodes[0].future_data == doc.dungeon.nodes[0].future_data, "explicit V1 migration preserves metadata without source mutation")
	compiled = adapter.compile(migrated)
	_expect(compiled.ok and compiled.data.nodes.start.icon_id == "future_Icon-42", "v2 compiles unknown icon unchanged")
	var invalid_v2 := migrated.duplicate(true)
	invalid_v2.dungeon.nodes[0].icon_id = "not/an/id"
	var v2_result: Dictionary = adapter.compile(invalid_v2)
	_expect(store.validate(invalid_v2).is_empty() and v2_result.ok and not v2_result.data.nodes.start.has("icon_id"), "v2 accepts and safely filters malformed icon")
	migrated.dungeon.nodes[0].erase("icon_id")
	compiled = adapter.compile(migrated)
	_expect(compiled.ok and not compiled.data.nodes.start.has("icon_id"), "missing icon remains missing in v2")
	migrated.dungeon.capability_model = "unified_1"
	migrated.dungeon.nodes[0].abilities = []
	migrated.dungeon.nodes[0].contributions = [{"id":"sword", "kind":"quality", "quality":"sword"}]
	migrated.dungeon.nodes[0].icon_id = "future_Icon-42"
	compiled = adapter.compile(migrated)
	_expect(compiled.ok and compiled.data.nodes.start.icon_id == "future_Icon-42", "unified model preserves explicit icon independently of contributions")
	migrated.dungeon.nodes[0].erase("icon_id")
	compiled = adapter.compile(migrated)
	_expect(compiled.ok and not compiled.data.nodes.start.has("icon_id"), "unified contributions do not infer an icon")
	var schema: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/content.schema.json"))
	_expect(schema["$defs"].node.properties.has("icon_id") and not schema["$defs"].node.properties.icon_id.has("type") and not schema["$defs"].node.properties.icon_id.has("$ref"), "schema permits opaque legacy icon values")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for failure in failures:
		printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _expect(value: bool, message: String) -> void:
	assertion_count += 1
	if not value:
		failures.append(message)
