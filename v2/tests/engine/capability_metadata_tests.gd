extends "res://tests/suite_reporter.gd"

# A5: authoring metadata mirrors runtime vocabulary/bounds without becoming a
# competing legality model. Model changes remain validated source transactions.
const STORE = preload("res://authoring/content_store.gd")
const BUILD = preload("res://runtime/unified_build.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var store = STORE.new()
	if not store.has_method("capability_metadata"):
		_expect(false, "shared capability authoring metadata is available")
	else:
		var metadata: Dictionary = store.capability_metadata()
		_expect(metadata.models == ["legacy", "unified_1"], "supported source models are explicit")
		_expect(metadata.stats.size() == 8 and metadata.qualities.size() == 6, "metadata includes complete unified vocabulary")
		for id in BUILD.STATS:
			var spec: Dictionary = metadata.stats[id]
			_expect(spec.base == BUILD.STATS[id].base and spec.min == BUILD.STATS[id].min and spec.max == BUILD.STATS[id].max and spec.requires == BUILD.STATS[id].requires, "stat metadata matches runtime: " + id)
			_expect(spec.operations == ["add", "multiply"] and not spec.label.is_empty() and not spec.unit.is_empty(), "stat has editor descriptions: " + id)
		for id in BUILD.QUALITIES:
			_expect(metadata.qualities[id].requires == BUILD.QUALITIES[id] and not metadata.qualities[id].label.is_empty(), "quality metadata matches runtime: " + id)
		var all := store.new_project()
		all.dungeon.capability_model = "unified_1"
		all.dungeon.nodes[0].contributions = []
		for id in metadata.stats:
			all.dungeon.nodes[0].contributions.append({"id":"stat_" + id, "kind":"stat", "stat":id, "op":"add", "value":0})
		for id in metadata.qualities:
			all.dungeon.nodes[0].contributions.append({"id":"quality_" + id, "kind":"quality", "quality":id})
		_expect(store.validate(all).is_empty(), "all exposed contribution IDs pass shared source validation")
		_expect(metadata.numeric_input.add == "finite_signed" and metadata.numeric_input.multiply == "finite_positive", "input rules distinguish result bounds")
		_expect(metadata.aggregate.max_absolute_sum == 1.0e100 and metadata.aggregate.max_log_product == 450.0, "whole-document safety limits are described")
		_expect(metadata.stats.max_hp.base_source == "dungeon.base_hp" and metadata.stats.sword_damage.base_source == "runtime_default", "metadata identifies configurable max HP base")
		metadata.stats.sword_damage.min = -999
		_expect(store.capability_metadata().stats.sword_damage.min == 0.0 and BUILD.STATS.sword_damage.min == 0.0, "metadata is detached from runtime and future calls")
		all.dungeon.nodes[0].contributions = [{"id":"negative", "kind":"stat", "stat":"move_speed", "op":"add", "value":-5000}]
		_expect(store.validate(all).is_empty(), "source operand may exceed composed-result bounds")
		all.dungeon.nodes[0].contributions[0].op = "multiply"
		_expect(not store.validate(all).is_empty(), "negative multiplier is rejected by source validation")
	var doc: Dictionary = store.new_project()
	_expect(store.validate(doc).is_empty() and not doc.dungeon.has("capability_model"), "new projects remain legacy")
	var candidate := doc.duplicate(true)
	candidate.dungeon.nodes[0].abilities = ["sword"]
	candidate.dungeon.capability_model = "unified_1"
	_expect(not store.validate(candidate).is_empty() and doc.dungeon.nodes[0].abilities.is_empty(), "legacy data prevents silent model switch without mutating source")
	candidate.dungeon.nodes[0].abilities = []
	candidate.dungeon.nodes[0].contributions = []
	_expect(store.validate(candidate).is_empty(), "empty unified candidate validates")
	candidate.dungeon.capability_model = "legacy"
	_expect(not store.validate(candidate).is_empty(), "even empty contributions cannot silently enter legacy")
	candidate.dungeon.nodes[0].erase("contributions")
	_expect(store.validate(candidate).is_empty(), "explicit compatible legacy candidate validates")
	for failure in failures:
		printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _expect(condition: bool, text: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(text)
