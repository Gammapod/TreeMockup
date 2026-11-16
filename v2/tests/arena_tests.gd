extends SceneTree

# BUILD-01 arena: six four-deep chains support focused/mixed eight-point builds.
# Encounters cost no points; fresh trials reset enemies/HP, retaining deep builds.
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
	var branches := ["thrust", "sweep", "quick_cut", "long_dash", "quick_step", "hp"]
	_expect(compiled.data.nodes.size() == 28, "Six four-node chains, root, Phase and two trials")
	_expect(compiled.data.initial_capacity == 8, "Eight-point testing budget")
	if not compiled.data.nodes.has("hp_d"):
		_finish()
		return
	for i in range(branches.size()):
		for j in range(i + 1, branches.size()):
			var model = MODEL.new(compiled.data)
			for branch in [branches[i], branches[j]]:
				var parent := "start"
				for suffix in ["a", "b", "c", "d"]:
					var id: String = branch + "_" + suffix
					if parent != "start":
						_expect(not model.activate(id, "start").ok, "Deeper upgrades require visiting branch")
						_expect(compiled.data.nodes[id].requires_all == [parent], "Chain retains ongoing predecessor support")
					_expect(model.activate(id, parent).ok and model.can_travel(parent, id), "All four stack levels are reachable")
					parent = id
			_expect(model.available_points() == 0, "Two full chains consume eight points")
			_expect(not model.activate("phase", "start").ok, "Additional ability requires a tradeoff")
			for id in ["crowd", "durable"]:
				_expect(model.activate(id, "start").ok and model.can_travel("start", id), "Encounter access costs no upgrade budget")
			var refund: Dictionary = model.deactivate(branches[i] + "_a", "start")
			_expect(refund.ok and refund.affected.size() == 4 and model.available_points() == 4, "Root refund cascades through entire branch")
	var defaults: Dictionary = MODEL.new(compiled.data).capabilities()
	_expect(defaults.abilities.has("sword") and defaults.abilities.has("dash"), "Both base actions are available for experimentation")
	for branch in ["sweep", "quick_cut"]:
		var model = MODEL.new(compiled.data)
		var parent := "start"
		var before: Dictionary = model.capabilities()
		for suffix in ["a", "b", "c", "d"]:
			var id: String = branch + "_" + suffix
			model.activate(id, parent)
			var after: Dictionary = model.capabilities()
			_expect(after.sword_arc > before.sword_arc if branch == "sweep" else after.sword_cooldown < before.sword_cooldown, "Every stack gives a real benefit before saturation")
			before = after
			parent = id
	var game = load("res://main.tscn").instantiate()
	game.data_override = compiled.data
	root.add_child(game)
	await process_frame
	game._toggle("sweep_a")
	game._enter_room("sweep_a", "west", 8)
	game._toggle("sweep_b")
	game._enter_room("start", "", 8)
	# Preserve deeper nodes and increased maximum health through trial restart.
	var parent := "start"
	for suffix in ["a", "b", "c", "d"]:
		var id: String = "hp_" + suffix
		game.progression.activate(id, parent)
		parent = id
	game._refresh()
	_expect(game.room.player.hp == 8 and game.room.player.max_hp == 12, "HP chain adds capacity without healing")
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
	# L1 applies to trial restarts as well as door/root/defeat transitions.
	game._request_trial_restart()
	game._open_studio()
	await process_frame
	_expect(game.studio.visible and not game.shell.visible and game.room.process_mode == Node.PROCESS_MODE_DISABLED and not game.room.visible, "L1: deferred trial restart preserves editor visibility and pause")
	game._close_studio()
	game._request_trial_restart()
	game._play_document(compiled.data)
	var fresh_room = game.room
	game.room.player.hp = 2
	await process_frame
	_expect(game.room == fresh_room and game.room.player.hp == 2, "L1: stale trial restart cannot reset a newer run")
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
