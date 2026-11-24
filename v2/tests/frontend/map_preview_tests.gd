extends "res://tests/suite_reporter.gd"

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var game = load("res://main.tscn").instantiate()
	game.data_override = load("res://tests/fixtures/activation_fixture.gd").create()
	game.data_override.initial_capacity = 20
	game.data_override.nodes.sword_landing.cost = 2
	game.data_override.nodes.prize.cost = 3
	root.add_child(game)
	var ui = game.tree_ui
	await process_frame
	for id in game.data.nodes:
		game.progression.active[id] = true
	game._enter_room("sword", "", 5)
	var before: Dictionary = game.progression.active.duplicate()
	var available: int = game.progression.available_points()
	ui.select_node("sword_landing")
	_expect(ui.gameplay_map.removal_preview == ["sword_landing", "prize"], "Preview marks selected room and ALL cascade")
	_expect(ui.selection.text.contains("Refund: 5 points total"), "Refund sums authored costs, not node count")
	_expect(ui.selection.text.contains("Available afterward: %d" % (available + 5)), "Preview shows post-refund budget")
	_expect(game.progression.active == before and game.progression.available_points() == available, "Selection preview has no gameplay effects")
	ui.node_action.pressed.emit()
	_expect(game.progression.available_points() == available + 5 and not game.progression.active.has("prize"), "Committed transaction matches preview")
	_expect(ui.gameplay_map.removal_preview.is_empty(), "Activation selection clears removal highlights after refund")
	# Occupied-room safety still exposes the rejected transaction's consequences.
	game.progression.active = before.duplicate()
	game._enter_room("prize", "", 5)
	ui.select_node("sword_landing")
	_expect(ui.node_action.disabled and ui.gameplay_map.removal_blocked, "Unsafe cascade is disabled and highlighted as blocked")
	_expect("prize" in ui.gameplay_map.removal_preview and ui.selection.text.contains("No refund"), "Blocked preview includes occupied room and promises no refund")
	ui.request_selected_action()
	_expect(game.progression.active == before, "Blocked action remains atomic")
	ui.select_node("prize")
	_expect(ui.selection.text.contains("ALL") and ui.selection.text.contains("sword_landing (active)") and ui.selection.text.contains("boots_landing (active)"), "ALL prerequisites are named and marked")
	# With ANY support, the alternate branch preserves Prize.
	game.data.nodes.prize.requires_all = []
	game.data.nodes.prize.requires_any = ["sword_landing", "boots_landing"]
	game._enter_room("sword", "", 5)
	ui.select_node("sword_landing")
	_expect(ui.gameplay_map.removal_preview == ["sword_landing"], "ANY alternate support prevents false cascade highlights")
	ui.node_action.pressed.emit()
	ui.select_node("prize")
	_expect(ui.selection.text.contains("ANY") and ui.selection.text.contains("sword_landing (inactive)") and ui.selection.text.contains("boots_landing (active)"), "ANY prerequisites show mixed support states")
	ui.select_node("")
	_expect(ui.gameplay_map.removal_preview.is_empty(), "Clearing selection clears preview")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("All map cascade, refund and prerequisite tests passed.")
		_complete(0)
	else:
		for failure in failures:
			printerr("ASSERTION FAILED: " + failure)
		_complete(1)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
