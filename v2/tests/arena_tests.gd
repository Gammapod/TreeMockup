extends SceneTree

# BUILD-01 arena: all two-upgrade combinations are locally reachable, encounters
# consume no build points, and explicit fresh trials reset enemies/HP, not build.
const STORE = preload("res://authoring/content_store.gd")
const ADAPTER = preload("res://authoring/runtime_adapter.gd")
const MODEL = preload("res://progression.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var source: Dictionary = STORE.new().load_document("res://examples/build_arena.json")
	_expect(source.ok, "Arena bundle exists and validates")
	if not source.ok:
		_finish()
		return
	var compiled: Dictionary = ADAPTER.new().compile(source.document)
	_expect(compiled.ok, "Arena compiles")
	if not compiled.ok:
		_finish()
		return
	var upgrades := ["thrust_a", "thrust_b", "sweep_a", "sweep_b"]
	for i in range(4):
		for j in range(i + 1, 4):
			var model = MODEL.new(compiled.data)
			_expect(model.activate(upgrades[i], "start").ok and model.activate(upgrades[j], "start").ok, "Every pair is reachable from safe root")
			_expect(model.available_points() == 0, "Exactly two upgrades fit")
			for id in upgrades:
				if not model.active.has(id):
					_expect(not model.activate(id, "start").ok, "Third upgrade is unaffordable")
			for id in ["crowd", "durable"]:
				_expect(model.activate(id, "start").ok and model.can_travel("start", id), "Encounter access costs no upgrade budget")
			_expect(model.deactivate(upgrades[i], "start").ok, "Safe root allows refund")
	var game = load("res://main.tscn").instantiate()
	game.data_override = compiled.data
	root.add_child(game)
	await process_frame
	game._toggle("sweep_a")
	game._toggle("sweep_b")
	game._toggle("crowd")
	game._enter_room("crowd", "south", 2)
	game.room.defeated["bat_0"] = true
	var old_active: Dictionary = game.progression.active.duplicate()
	game.call("_request_trial_restart")
	await process_frame
	await process_frame
	_expect(game.current == "start" and game.room.player.hp == game.room.player.max_hp, "Fresh trial returns to root at full health")
	_expect(game.progression.active == old_active, "Fresh trial retains chosen build")
	game._enter_room("crowd", "south", game.room.player.hp)
	_expect(game.room.enemies.size() == 5, "Fresh trial restores every crowd enemy")
	_expect(game.status.text.contains("4.50") and game.status.text.contains("Reach"), "Resulting fractional damage and reach are visible")
	game.tree_ui.select_node("sweep_a")
	_expect(game.tree_ui.selection.text.contains("Damage") and game.tree_ui.selection.text.contains("Arc"), "Upgrade benefit and penalty are inspectable")
	game.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("All BUILD-01 arena tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
