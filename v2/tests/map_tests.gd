extends "res://tests/suite_reporter.gd"

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	var ui = game.tree_ui
	for frame in range(5):
		await process_frame
	_expect(ui.gameplay_map._screen("start").is_equal_approx(ui.gameplay_map.size * 0.5), "Initial entry centers the occupied room")
	_expect(ui.gameplay_map.node_states.start == "active", "Root is active")
	_expect(ui.gameplay_map.node_states.sword == "available", "Local affordable room is available")
	_expect(ui.gameplay_map.node_states.prize == "blocked", "Remote room is blocked")
	# A map click selects; only the explicit action commits.
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = ui.gameplay_map._screen("sword")
	ui.gameplay_map._gui_input(click)
	_expect(ui.gameplay_map.selected == "sword" and not game.progression.active.has("sword"), "Selecting a map node does not allocate")
	_expect(not ui.node_action.disabled, "Selected available room has an enabled action")
	# UI-ACTION: a once-valid snapshot must not authorize a later invalid action.
	game.progression.capacity = 0
	ui.request_selected_action()
	_expect(not game.progression.active.has("sword"), "Stale enabled preview cannot bypass execution-time capacity validation")
	game.progression.capacity = 1
	game._refresh()
	ui.node_action.pressed.emit()
	_expect(game.progression.active.has("sword") and ui.gameplay_map.node_states.sword == "active", "Action activates and refreshes map")
	_expect(ui.gameplay_map.selected == "sword" and ui.gameplay_map.occupied == "start", "Selection and player marker remain independent")
	_expect(ui.node_action.text.begins_with("Deactivate / refund"), "Action changes to deactivation")
	ui.select_node("boots")
	_expect(ui.node_action.disabled and ui.selection.text.contains("Not enough"), "Spending capacity disables other actions with a reason")
	ui.select_node("sword")
	ui.node_action.pressed.emit()
	_expect(not game.progression.active.has("sword") and ui.gameplay_map.node_states.boots == "available", "Refund restores map availability")
	ui.node_action.pressed.emit()
	ui.select_node("boots")
	game._request_travel("sword", "east")
	await process_frame
	_expect(ui.gameplay_map.selected == "boots", "Travel framing preserves a different selected node")
	_expect(ui.gameplay_map._screen("sword").is_equal_approx(ui.gameplay_map.size * 0.5), "Travel centers the occupied room")
	var map_bounds := Rect2(Vector2.ZERO, ui.gameplay_map.size).grow(-25)
	for neighbor in game.progression.neighbors("sword"):
		_expect(map_bounds.has_point(ui.gameplay_map._screen(neighbor)), "Travel framing includes neighbor " + neighbor)
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_RIGHT
	motion.relative = Vector2(31, 19)
	ui.gameplay_map._gui_input(motion)
	var manual_offset: Vector2 = ui.gameplay_map.offset
	var manual_zoom: float = ui.gameplay_map.zoom
	ui.select_node("fast_swing")
	_expect(ui.node_action.disabled, "Unaffordable local action is blocked")
	game._collect("capacity")
	_expect(ui.gameplay_map.offset == manual_offset and ui.gameplay_map.zoom == manual_zoom, "Reward refresh preserves manual camera")
	_expect(not ui.node_action.disabled, "Reward refreshes the selected action")
	ui.node_action.pressed.emit()
	ui.select_node("big_swing")
	_expect(ui.node_action.disabled and ui.selection.text.contains("exclusive"), "Exclusive choice is explained")
	ui.select_node("prize")
	var before: Dictionary = game.progression.active.duplicate()
	ui.request_selected_action()
	_expect(ui.node_action.disabled and game.progression.active == before, "Execution still rejects remote actions")
	ui.select_node("start")
	_expect(ui.node_action.disabled and ui.selection.text.contains("permanently"), "Root cannot be deactivated")
	ui.select_node("")
	_expect(ui.node_action.disabled, "Clearing selection disables actions")
	game._open_studio()
	game._play_document(game.data)
	_expect(ui.gameplay_map.selected == "" and ui.node_action.disabled, "Fresh playtest clears selection")
	_expect(ui.gameplay_map.node_states.sword == "available", "Fresh playtest resets state indicators")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("All gameplay map action tests passed.")
		_complete(0)
	else:
		for failure in failures:
			printerr("ASSERTION FAILED: " + failure)
		_complete(1)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
