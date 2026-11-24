extends "res://tests/suite_reporter.gd"

const MODEL = preload("res://progression.gd")
const STORE = preload("res://authoring/content_store.gd")
const ADAPTER = preload("res://authoring/runtime_adapter.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func fixture() -> Dictionary:
	var doc: Dictionary = STORE.new().load_document("res://examples/cleared_rooms.json").document
	for template in doc.rooms:
		if template.id == "tokens":
			template.clear.block_tree_editing_until_cleared = true
	return ADAPTER.new().compile(doc).data

func _run() -> void:
	var model = MODEL.new(fixture())
	if not model.has_method("preview_root_travel") or not model.has_method("can_edit_tree"):
		_expect(false, "TR1/EDIT1: root travel and occupied-room editing policy are missing")
	else:
		model.activate("tokens", "start")
		var active_before: Dictionary = model.active.duplicate()
		var points: int = model.available_points()
		_expect(not model.can_edit_tree("tokens"), "EDIT1: occupied uncleared opt-in room blocks editing")
		_expect(model.preview_activation("combined", "tokens").reason == "tree_editing_locked", "EDIT1: activation preview explains occupied-room lock")
		_expect(not model.activate("combined", "tokens").ok and not model.deactivate("start", "tokens").ok and model.active == active_before and model.available_points() == points, "EDIT1: direct transactions cannot bypass lock or spend/refund")
		# An already allocated neighbor must also resist direct refund requests.
		model.active.combined = true
		_expect(model.preview_deactivation("combined", "tokens").reason == "tree_editing_locked" and not model.deactivate("combined", "tokens").ok and model.active.has("combined"), "EDIT1: occupied-room lock blocks deactivation of an ordinary adjacent node")
		model.active.erase("combined")
		model.activate("combat_a", "start")
		_expect(model.can_edit_tree("combat_a"), "EDIT1: uncleared rooms remain editable by default")
		_expect(model.can_edit_tree("start") and model.preview_deactivation("tokens", "start").ok, "EDIT1: lock depends on occupied room, not target")
		_expect(model.preview_root_travel("start", "tokens").ok, "TR1: can escape uncleared edit-locked room to a cleared active root")
		_expect(not model.preview_root_travel("tokens", "start").ok and not model.preview_root_travel("combined", "start").ok, "TR1: non-roots and unearned roots reject travel")
		_expect(not model.preview_root_travel("missing", "start").ok and not model.preview_root_travel("start", "missing").ok and not model.preview_root_travel("start", "start").ok, "TR1: invalid endpoints and same-room travel reject")
		for token in ["token_a", "token_b", "token_c"]:
			model.record_objective("tokens", "token_collected", token)
		_expect(model.can_edit_tree("tokens") and model.activate("combined", "tokens").ok, "EDIT1: clearing immediately restores normal transactions")
		model.record_objective("combined", "enemy_defeated", "bat")
		model.record_objective("combined", "switch_hit", "lever")
		for token in ["token_a", "token_b"]:
			model.record_objective("combined", "token_collected", token)
		model.deactivate("tokens", "start")
		_expect(model.preview_root_travel("combined", "start").ok, "TR1: disconnected earned roots remain travel destinations")
		model.active.erase("combined")
		_expect(not model.preview_root_travel("combined", "start").ok, "TR1: target must be active even with root/clear flags")
		model.active.combined = true
		model.cleared.erase("combined")
		_expect(not model.preview_root_travel("combined", "start").ok, "TR1: target must be cleared even with root/active flags")
		await _integration()
	var doc: Dictionary = STORE.new().new_project()
	doc.rooms[0].clear.block_tree_editing_until_cleared = "yes"
	_expect(not STORE.new().validate(doc).is_empty(), "EDIT2: editing policy requires a boolean")
	if failures.is_empty():
		print("All root travel and editing permission contracts passed.")
		_complete(0)
	else:
		for failure in failures:
			printerr("ASSERTION FAILED: " + failure)
		_complete(1)

func _integration() -> void:
	var game = load("res://main.tscn").instantiate()
	game.data_override = fixture()
	root.add_child(game)
	await process_frame
	game._toggle("tokens")
	game._enter_room("tokens", "", 7)
	game.tree_ui.select_node("combined")
	root.size = Vector2i(960, 640)
	for frame in range(5):
		await process_frame
	_expect(game.tree_ui.node_action.disabled and "uncleared" in game.tree_ui.edit_permission.text, "EDIT1: UI explains and disables occupied-room editing")
	_expect(game.tree_ui.gameplay_map.size.y > 200, "TR2/EDIT1: travel controls and lock explanation preserve map area at minimum window size")
	game.tree_ui.select_node("start")
	_expect(not game.tree_ui.root_travel.disabled, "TR2: map exposes explicit root travel action")
	var before: Dictionary = game.progression.active.duplicate()
	var points: int = game.progression.available_points()
	game.room.player.hp = 3
	game.room.player.position = Vector2(250, 280)
	game.room._physics_process(0)
	game.tree_ui.root_travel.pressed.emit()
	await process_frame
	_expect(game.current == "start" and game.room.player.hp == 3 and game.room.player.position == Vector2(400, 400), "TR2: root travel uses authored spawn and preserves HP")
	_expect(game.progression.active == before and game.progression.available_points() == points, "TR2: travel does not edit build or allocate resources")
	game._enter_room("tokens", "", 3)
	_expect(game.room.tokens.size() == 3, "TR2: root travel uses normal departure/token-reset lifecycle")
	for token in ["token_a", "token_b", "token_c"]:
		game._objective_event("token_collected", token)
	game.tree_ui.select_node("combined")
	_expect(not game.tree_ui.node_action.disabled and game.tree_ui.edit_permission.text.is_empty(), "EDIT1: completing objectives immediately refreshes editing controls")
	game._toggle("combined")
	game._enter_room("combined", "", 3)
	game._objective_event("enemy_defeated", "bat")
	game._switch_toggled("lever")
	game._objective_event("token_collected", "token_a")
	game._objective_event("token_collected", "token_b")
	game._request_root_travel("start")
	await process_frame
	game._toggle("tokens")
	game.tree_ui.select_node("combined")
	_expect(not game.tree_ui.root_travel.disabled, "TR2: disconnected earned root is selectable for travel")
	game.tree_ui.root_travel.pressed.emit()
	await process_frame
	_expect(game.current == "combined" and game.room.player.hp == 3, "TR2: travel reaches disconnected earned root without healing")
	# UI intent is revalidated, including between queuing and scene replacement.
	game._request_root_travel("start")
	game.progression.active.erase("start")
	await process_frame
	_expect(game.current == "combined" and not game.transition_pending, "TR2: deferred travel revalidates target and releases pending state on rejection")
	game.progression.active.start = true
	game.queue_free()
	await process_frame

func _expect(value: bool, message: String) -> void:
	assertion_count += 1
	if not value:
		failures.append(message)
