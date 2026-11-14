extends SceneTree

const MODEL = preload("res://progression.gd")
const STORE = preload("res://authoring/content_store.gd")
const ADAPTER = preload("res://authoring/runtime_adapter.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func fixture() -> Dictionary:
	var data := preload("res://tests/fixtures/activation_fixture.gd").create()
	data.templates.home = data.templates.empty.duplicate(true)
	data.templates.home.clear = {"conditions": [], "effects": [{"kind": "become_root"}]}
	data.nodes.start.template = "home"
	data.templates.practice.enemies = [{"id": "bat", "position": Vector2(560, 350), "hp": 1}]
	data.templates.practice.objects = [{"id": "lever", "kind": "switch", "position": Vector2(300, 300)}]
	data.templates.practice.tokens = [{"id": "token", "position": Vector2(400, 300)}]
	data.templates.practice.clear = {"conditions": [{"kind": "all_enemies_defeated"}, {"kind": "switch_hit", "object": "lever"}, {"kind": "all_tokens_collected"}], "effects": [{"kind": "reveal_pickup", "object": "capacity"}, {"kind": "prevent_enemy_respawn"}]}
	return data

func _run() -> void:
	var data := fixture()
	var model = MODEL.new(data)
	if not model.has_method("record_objective"):
		_expect(false, "CL1-CL5: progression clear lifecycle is not implemented")
	else:
		_expect(model.cleared.has("start") and model.cleared.has("prize") and not model.active.has("prize"), "CL1: conditionless rooms start cleared, even inactive")
		_expect(model.roots.has("start"), "CL5: starting root comes from an immediate clear effect")
		model.activate("sword", "start")
		_expect(not model.collect("sword", "capacity"), "CL3: hidden rewards reject early model collection")
		model.record_objective("sword", "enemy_defeated", "bat")
		model.record_objective("sword", "token_collected", "token")
		model.leave_room("sword")
		model.record_objective("sword", "switch_hit", "lever")
		_expect(not model.cleared.has("sword"), "CL2: ALL objectives and token progress resets on departure")
		model.record_objective("sword", "token_collected", "missing")
		_expect(not model.cleared.has("sword"), "CL2: unknown events cannot complete objectives")
		model.record_objective("sword", "token_collected", "token")
		_expect(model.cleared.has("sword") and not model.cleared.has("boots"), "CL1/2: combined completion and shared-template isolation")
		_expect(model.collect("sword", "capacity") and not model.collect("sword", "capacity"), "CL3: reward grants exactly once")
		model.deactivate("sword", "start")
		_expect(model.cleared.has("sword") and model.prevents_respawn("sword"), "CL1/4: clear and no-respawn persist through deactivation")
		model.activate("sword", "start")
		_expect(not model.collect("sword", "capacity"), "CL3: reactivation cannot duplicate rewards")
		data = fixture()
		data.templates.practice.clear.effects.append({"kind": "become_root"})
		model = MODEL.new(data)
		model.activate("sword", "start")
		model.activate("sword_landing", "sword")
		model.record_objective("sword", "enemy_defeated", "bat")
		model.record_objective("sword", "switch_hit", "lever")
		model.record_objective("sword", "token_collected", "token")
		_expect(model.available_points() == 3 and model.roots.has("sword"), "CL5: promotion releases allocation")
		_expect(model.preview_deactivation("sword", "start").reason == "root", "CL5: earned roots cannot deactivate")
		# Promote a dependent, then remove its upstream support.
		data = fixture()
		data.templates.anchor = data.templates.practice.duplicate(true)
		data.templates.anchor.clear = {"conditions": [{"kind": "switch_hit", "object": "lever"}], "effects": [{"kind": "become_root"}]}
		data.nodes.sword_landing.template = "anchor"
		model = MODEL.new(data)
		model.activate("sword", "start")
		model.activate("sword_landing", "sword")
		model.record_objective("sword_landing", "switch_hit", "lever")
		_expect(model.deactivate("sword", "start").ok and model.active.has("sword_landing"), "CL5: promoted root survives loss of prerequisites and original-root connection")
		_expect(model.connected(model.active).has("sword_landing"), "CL5: connectivity starts at every root")
		_expect(not MODEL.new(data).cleared.has("sword_landing"), "CL1: fresh runs reset earned clear state")
		data = fixture()
		data.templates.practice.clear = {"conditions": [], "effects": [{"kind": "become_root"}, {"kind": "reveal_pickup", "object": "capacity"}, {"kind": "prevent_enemy_respawn"}]}
		model = MODEL.new(data)
		_expect(model.active.has("sword") and model.active.has("boots") and model.available_points() == 4 and model.prevents_respawn("boots") and model.collect("boots", "capacity"), "CL1/3/4/5: all default-clear effects apply to unvisited nodes immediately")
		data = fixture()
		data.templates.practice.clear.effects = []
		model = MODEL.new(data)
		model.activate("sword", "start")
		model.record_objective("sword", "enemy_defeated", "bat")
		model.record_objective("sword", "switch_hit", "lever")
		model.deactivate("sword", "start")
		model.activate("sword", "start")
		model.record_objective("sword", "token_collected", "token")
		_expect(not model.cleared.has("sword"), "CL2: deactivation resets enemy objective progress")
		model.record_objective("sword", "enemy_defeated", "bat")
		_expect(model.cleared.has("sword") and not model.prevents_respawn("sword"), "CL2/4: switch hits persist, clear alone does not suppress respawns")
		await _integration()
	_authoring()
	if failures.is_empty():
		print("All cleared-room contracts passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _authoring() -> void:
	var store = STORE.new()
	var doc: Dictionary = store.new_project()
	doc.rooms[0].clear = {"conditions": [{"kind": "switch_hit", "object": "missing"}], "effects": []}
	_expect(not store.validate(doc).is_empty(), "CL6: dangling objective references reject authoring")
	doc.rooms[0].clear = {"conditions": [{"kind": "future_condition"}], "effects": []}
	_expect(not ADAPTER.new().compile(doc).ok, "CL6: unsupported objectives block playtest")
	doc = store.new_project()
	doc.rooms[0].clear.effects.append({"kind": "future_effect"})
	_expect(not ADAPTER.new().compile(doc).ok, "CL6: unsupported effects block playtest")
	doc = store.new_project()
	doc.dungeon.nodes[0].exclusive_group = "choice"
	_expect(not ADAPTER.new().compile(doc).ok, "CL5/6: permanent roots reject exclusive groups")
	# Legacy V1 template reuse does not accidentally promote every instance.
	doc = store.new_project()
	doc.rooms[0].erase("clear")
	doc.dungeon.nodes.append(store.new_node("other", "empty"))
	var legacy: Dictionary = ADAPTER.new().compile(doc)
	_expect(legacy.ok, "CL6: legacy V1 start root remains playable")
	if legacy.ok:
		var model = MODEL.new(legacy.data)
		_expect(model.roots.has("start") and not model.roots.has("other") and not doc.rooms[0].has("clear"), "CL5/6: legacy translation isolates start instance and preserves source")

func _integration() -> void:
	var game = load("res://main.tscn").instantiate()
	game.data_override = fixture()
	root.add_child(game)
	await process_frame
	game._toggle("sword")
	game._enter_room("sword", "", 5)
	_expect(game.room.pickups.is_empty(), "CL3: hidden rewards absent from scene")
	game.room.player.position = Vector2(400, 300)
	game.room._physics_process(0)
	game._enter_room("start", "", 5)
	game._enter_room("sword", "", 5)
	_expect(game.room.tokens.size() == 1, "CL2: uncleared room tokens respawn on re-entry")
	game.room._attack(Vector2(560, 350), Vector2.RIGHT, 30, 10)
	game._switch_toggled("lever")
	game.room.player.position = Vector2(400, 300)
	game.room._physics_process(0)
	_expect(game.progression.cleared.has("sword") and game.room.pickups.size() == 1, "CL2/3: actual room events complete and reveal immediately")
	_expect(game.progression.gold == 0 and game.progression.collected.is_empty(), "CL2: tokens never enter permanent loot ledger")
	game._defeat()
	await process_frame
	_expect(game.progression.cleared.has("sword"), "CL1: defeat retains clear state")
	game._toggle("sword")
	game._toggle("sword")
	game._enter_room("sword", "", 5)
	_expect(game.room.enemies.is_empty() and game.room.tokens.is_empty() and game.room.pickups.size() == 1, "CL2/3/4: cleared reload restores effects without spawning tokens")
	game._collect("capacity")
	game._enter_room("start", "", 5)
	game._enter_room("sword", "", 5)
	_expect(game.room.pickups.is_empty(), "CL3: collected reward remains absent on reload")
	game.tree_ui.select_node("sword")
	_expect("Cleared" in game.tree_ui.selection.text, "CL1: clear status appears independently in tree details")
	game.queue_free()
	await process_frame
	game = load("res://main.tscn").instantiate()
	var data := fixture()
	data.templates.home.tokens = [{"id": "unused", "position": Vector2(300, 300)}]
	data.templates.practice.clear.conditions = [{"kind": "switch_hit", "object": "lever"}]
	game.data_override = data
	root.add_child(game)
	await process_frame
	_expect(game.room.tokens.is_empty(), "CL2: default-cleared rooms never spawn tokens")
	game._toggle("sword")
	game._enter_room("sword", "", 5)
	_expect(game.room.tokens.size() == 1, "CL2: uncleared switch room spawns authored tokens")
	game._switch_toggled("lever")
	_expect(game.room.tokens.is_empty(), "CL2: clearing removes remaining tokens immediately")
	game.queue_free()
	await process_frame

func _expect(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
