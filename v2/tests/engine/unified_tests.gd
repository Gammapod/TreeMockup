extends "res://tests/suite_reporter.gd"

# UAB1: unified source compiles only under its explicit discriminator.
const STORE = preload("res://authoring/content_store.gd")
const ADAPTER = preload("res://authoring/runtime_adapter.gd")
const MODEL = preload("res://progression.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var document: Dictionary = STORE.new().new_project()
	document.dungeon.capability_model = "unified_1"
	document.dungeon.nodes[0].contributions = [
		{"id": "blade", "kind": "quality", "quality": "sword"},
		{"id": "base_damage", "kind": "stat", "stat": "sword_damage", "op": "add", "value": 2},
		{"id": "damage_factor", "kind": "stat", "stat": "sword_damage", "op": "multiply", "value": 2}
	]
	_expect(STORE.new().validate(document).is_empty(), "valid unified source is accepted for editing")
	var adapter = ADAPTER.new()
	var result: Dictionary = adapter.compile(document)
	_expect(result.ok, "validated unified source compiles for normal Playtest")
	var methods: Array = adapter.get_method_list().filter(func(item): return item.name == "compile")
	_expect(not methods.is_empty() and methods[0].args.size() >= 2, "explicit experimental compilation is available")
	if not methods.is_empty() and methods[0].args.size() >= 2:
		result = adapter.call("compile", document, true)
		_expect(result.ok, "valid unified source compiles via explicit experiment")
	_expect(document.dungeon.nodes[0].contributions.size() == 3, "compilation preserves source")
	var bad := document.duplicate(true)
	bad.dungeon.nodes[0].abilities = ["dash"]
	_expect(not STORE.new().validate(bad).is_empty(), "mixed legacy abilities are rejected")
	bad = document.duplicate(true)
	bad.dungeon.nodes[0].contributions[0].quality = "future"
	_expect(not STORE.new().validate(bad).is_empty(), "unknown quality is rejected")
	bad = document.duplicate(true)
	bad.dungeon.capability_model = "future"
	_expect(not STORE.new().validate(bad).is_empty(), "unknown discriminator is rejected")
	bad = document.duplicate(true)
	bad.dungeon.erase("capability_model")
	_expect(not STORE.new().validate(bad).is_empty(), "contributions require the discriminator")
	bad = document.duplicate(true)
	bad.dungeon.nodes[0].contributions[2].value = 0
	_expect(not STORE.new().validate(bad).is_empty(), "nonpositive multipliers are rejected")
	bad = document.duplicate(true)
	bad.dungeon.nodes[0].contributions[1].id = "blade"
	_expect(not STORE.new().validate(bad).is_empty(), "duplicate contribution IDs are rejected")
	bad = document.duplicate(true)
	bad.dungeon.nodes[0].contributions[1].stat = "future"
	_expect(not STORE.new().validate(bad).is_empty(), "unknown stat is rejected")
	bad = document.duplicate(true)
	bad.dungeon.nodes[0].modifiers = {"dash_style": "phase"}
	_expect(not STORE.new().validate(bad).is_empty(), "legacy modifiers cannot be mixed")
	bad = document.duplicate(true)
	bad.dungeon.nodes[0].contributions = [
		{"id": "one", "kind": "stat", "stat": "sword_damage", "op": "multiply", "value": 1.0e200},
		{"id": "two", "kind": "stat", "stat": "sword_damage", "op": "multiply", "value": 1.0e200}
	]
	_expect(not STORE.new().validate(bad).is_empty(), "potential aggregate overflow rejected before activation")
	bad.dungeon.nodes[0].contributions[0].value = 1.0e-200
	bad.dungeon.nodes[0].contributions[1].value = 1.0e-200
	_expect(not STORE.new().validate(bad).is_empty(), "potential product underflow rejected")
	bad.dungeon.nodes[0].contributions = [
		{"id": "one", "kind": "stat", "stat": "max_hp", "op": "add", "value": 1.0e101}
	]
	_expect(not STORE.new().validate(bad).is_empty(), "potential additive overflow rejected")
	_build_contract()
	for failure in failures:
		printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)

func _build_contract() -> void:
	var root := {"template": "root", "cost": 0, "requires_all": [], "requires_any": [], "contributions": [
		{"id": "damage", "kind": "stat", "stat": "sword_damage", "op": "add", "value": 2},
		{"id": "factor", "kind": "stat", "stat": "sword_damage", "op": "multiply", "value": 2},
		{"id": "phase", "kind": "quality", "quality": "phase_teleport"}
	]}
	var leaf := {"template": "empty", "cost": 1, "requires_all": [], "requires_any": [], "contributions": [
		{"id": "sword", "kind": "quality", "quality": "sword"},
		{"id": "dash", "kind": "quality", "quality": "dash"},
		{"id": "arc", "kind": "stat", "stat": "sword_arc", "op": "multiply", "value": 10}
	]}
	var data := {"capability_model": "unified_1", "initial_capacity": 3, "nodes": {"start": root, "leaf": leaf}, "templates": {
		"root": {"clear": {"effects": [{"kind": "become_root"}]}}, "empty": {}
	}, "links": [{"a": "start", "b": "leaf", "activate_from": ["start", "leaf"]}]}
	var model = MODEL.new(data)
	var before: Dictionary = model.capabilities()
	_expect(before.get("model") == "unified_1", "unified capability snapshot is discriminated")
	_expect(before.get("stats", {}).get("sword_damage", {}).get("effective") == null, "sword stat dormant without sword")
	_expect(before.qualities.phase_teleport.granted and not before.qualities.phase_teleport.effective, "phase grant remains visible while dormant")
	_expect(before.stats.sword_damage.value == 6.0 and before.stats.sword_damage.sources.size() == 2, "dormant stat retains derived value and sources")
	before.stats.sword_damage.sources[0].contribution.value = 999
	_expect(model.capabilities().stats.sword_damage.value == 6.0, "snapshot source is copied")
	before = model.capabilities()
	var preview: Dictionary = model.preview_activation("leaf", "start")
	_expect(preview.ok and preview.has("build_before") and preview.has("build_after"), "activation preview provides build snapshots")
	if preview.has("build_after"):
		var after: Dictionary = preview.build_after
		_expect(is_equal_approx(after.stats.sword_damage.effective, 6.0), "additions apply before multiplication")
		_expect(is_equal_approx(after.stats.sword_arc.effective, TAU) and after.stats.sword_arc.clamped, "arc capped and cap reported")
		_expect(after.qualities.phase_teleport.effective, "dormant phase becomes effective with dash")
		_expect(not model.active.has("leaf"), "preview does not mutate allocation")
		model.activate("leaf", "start")
		_expect(model.capabilities() == after, "execution matches preview")
		var refund: Dictionary = model.preview_deactivation("leaf", "start")
		_expect(refund.has("build_after") and refund.build_after == before, "refund preview recomposes dormant build")
		_expect(model.deactivate("leaf", "start").ok and model.capabilities() == before, "refund execution matches preview")
	var denied: Dictionary = model.preview_activation("leaf", "missing")
	_expect(not denied.ok and not denied.has("build_after"), "denied preview does not report a hypothetical result")
	_numeric_contract()
	_cascade_contract()

func _cascade_contract() -> void:
	var data := {"capability_model": "unified_1", "initial_capacity": 3,
		"nodes": {
			"start": {"template": "root", "cost": 0},
			"leaf": {"template": "empty", "cost": 1},
			"tail": {"template": "empty", "cost": 1, "requires_all": ["leaf"], "contributions": [{"id": "water", "kind": "quality", "quality": "water_pass"}]}
		},
		"templates": {"root": {"clear": {"effects": [{"kind": "become_root"}]}}, "empty": {}},
		"links": [{"a": "start", "b": "leaf", "activate_from": ["start", "leaf"]}, {"a": "leaf", "b": "tail", "activate_from": ["leaf", "tail"]}]}
	var model = MODEL.new(data)
	model.activate("leaf", "start")
	model.activate("tail", "leaf")
	var preview: Dictionary = model.preview_deactivation("leaf", "start")
	_expect(preview.ok and preview.affected.has("tail") and preview.build_before.qualities.water_pass.effective and not preview.build_after.qualities.water_pass.effective, "cascade preview removes all affected contributions")
	_expect(model.active.has("tail") and model.deactivate("leaf", "start").ok and model.capabilities() == preview.build_after, "cascade preview is pure and matches execution")

func _numeric_contract() -> void:
	var contributions := [
		{"id": "a", "kind": "quality", "quality": "sword"},
		{"id": "b", "kind": "quality", "quality": "sword"},
		{"id": "c", "kind": "stat", "stat": "move_speed", "op": "add", "value": -1000},
		{"id": "d", "kind": "stat", "stat": "sword_range", "op": "add", "value": 10},
		{"id": "e", "kind": "stat", "stat": "sword_cooldown", "op": "add", "value": -1},
		{"id": "f", "kind": "stat", "stat": "dash_distance", "op": "multiply", "value": 2},
		{"id": "g", "kind": "stat", "stat": "dash_recharge", "op": "add", "value": 0.5},
		{"id": "h", "kind": "stat", "stat": "max_hp", "op": "multiply", "value": 1.5},
		{"id": "i", "kind": "quality", "quality": "water_pass"},
		{"id": "j", "kind": "quality", "quality": "sword_root"},
		{"id": "k", "kind": "quality", "quality": "dash_root"}
	]
	var data := {"capability_model": "unified_1", "base_hp": 5, "initial_capacity": 0,
		"nodes": {"start": {"template": "root", "cost": 0, "contributions": contributions}},
		"templates": {"root": {"clear": {"effects": [{"kind": "become_root"}]}}}, "links": []}
	var caps: Dictionary = MODEL.new(data).capabilities()
	_expect(caps.stats.size() == 8 and caps.qualities.size() == 6, "snapshot reports eight stats and six qualities")
	_expect(caps.stats.move_speed.effective == 1.0 and caps.stats.move_speed.clamped, "signed additions clamp speed")
	_expect(caps.stats.sword_range.effective == 102.0 and caps.stats.sword_cooldown.effective == 0.0, "reach and cooldown use approved bases and bounds")
	_expect(caps.stats.dash_distance.value == 208.0 and caps.stats.dash_distance.effective == null and is_equal_approx(caps.stats.dash_recharge.value, 0.99), "dash stats compose while dormant")
	_expect(caps.stats.max_hp.effective == 7 and caps.qualities.water_pass.effective, "HP floors after composition and water is independent")
	_expect(caps.qualities.sword.sources.size() == 2 and caps.qualities.sword_root.effective and not caps.qualities.dash_root.effective, "quality union is idempotent and dependent")
	contributions.reverse()
	_expect(MODEL.new(data).capabilities() == caps, "source order does not change snapshot")
