extends "res://tests/suite_reporter.gd"

# UAB9: gameplay attaches feedback and preserves defeat explanation; UAB8:
# normal portable editor Playtest compiles and launches a unified document.
const STORE = preload("res://authoring/content_store.gd")
const ADAPTER = preload("res://authoring/runtime_adapter.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _source() -> Dictionary:
	var doc: Dictionary = STORE.new().new_project()
	doc.dungeon.capability_model = "unified_1"
	doc.dungeon.nodes[0].contributions = [
		{"id":"dash", "kind":"quality", "quality":"dash"},
		{"id":"phase", "kind":"quality", "quality":"phase_teleport"},
		{"id":"root", "kind":"quality", "quality":"dash_root"}
	]
	doc.rooms[0].spawn = [400,300]
	return doc

func _run() -> void:
	var doc := _source()
	var compiled: Dictionary = ADAPTER.new().compile(doc)
	_expect(compiled.ok, "normal compiler accepts validated unified source")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var props: Array = game.get_property_list().filter(func(item): return item.name == "phase_feedback")
	if props.is_empty() or game.get("phase_feedback") == null:
		_expect(false, "coordinator attaches room-viewport Phase feedback")
	else:
		var feedback = game.phase_feedback
		_expect(feedback.get_parent() == game.shell.room_viewport and feedback.position == Vector2.ZERO, "feedback shares room world coordinates")
		feedback.attempted = Vector2(10, 20)
		game.phase_started.emit({"phase":true})
		_expect(feedback.attempted == null, "feedback listens after attachment and clears the previous marker")
		game._enter_room(game.current, "", game.room.player.hp)
		_expect(feedback.message.text.is_empty(), "ordinary room replacement resets feedback")
		if compiled.ok:
			game._open_studio()
			await process_frame
			game.studio._set_mode("bundle")
			game.studio.inspector.text = JSON.stringify(doc)
			game.studio._play()
			_expect(not game.studio.visible and game.data.get("capability_model") == "unified_1", "normal editor Playtest launches compiled unified source")
			game.room.player.set_physics_process(false)
			feedback.attempted = Vector2(10, 20)
			game.room.player.start_dash()
			_expect(feedback.attempted == null, "actual Phase start reaches feedback")
			game.room.obstacles.append(Rect2(390,290,20,20))
			game.room.obstacles.append(Rect2(490,290,28,20))
			var old_room = game.room
			game.room.player.advance_unified(0.16, Vector2.ZERO)
			_expect(game.transition_pending and "Return blocked" in feedback.message.text, "blocked return feedback precedes guarded defeat")
			await process_frame
			_expect(game.room != old_room and "Return blocked" in game.status.text, "defeat is immediate and reason survives room replacement")
			_expect(feedback.attempted == null, "old-room failure marker is cleared on replacement")
	game.queue_free()
	await process_frame
	for failure in failures:
		printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
