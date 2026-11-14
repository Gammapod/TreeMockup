extends SceneTree

# UI-BOUNDARY: panel consumes snapshots and emits intent without mutating run state.
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	if not FileAccess.file_exists("res://gameplay_tree.gd"):
		push_error("UI-BOUNDARY: standalone snapshot-driven tree panel is missing")
		quit(1)
		return
	var panel = load("res://gameplay_tree.gd").new()
	root.add_child(panel)
	var data: Dictionary = load("res://tests/fixtures/activation_fixture.gd").create()
	panel.configure(data)
	var snapshot := {"current": "start", "active": {"start": true}, "available_points": 4, "previews": {}}
	for id in data.nodes:
		snapshot.previews[id] = {"ok": id == "sword", "reason": "" if id == "sword" else "not_local", "affected": [id] if id == "sword" else []}
	var before: Dictionary = snapshot.duplicate(true)
	panel.refresh(snapshot)
	panel.select_node("sword")
	var requests: Array = []
	panel.action_requested.connect(func(id): requests.append(id))
	panel.node_action.pressed.emit()
	_expect(requests == ["sword"], "Panel emits the selected node's action intent")
	_expect(snapshot == before and not snapshot.active.has("sword"), "Panel never applies transactions")
	snapshot.active.sword = true
	snapshot.previews.sword.ok = false
	panel.select_node("sword")
	_expect(not panel.node_action.disabled and panel.gameplay_map.node_states.sword == "available", "Presentation snapshot does not alias mutable run dictionaries")
	panel.configure(data)
	_expect(panel.gameplay_map.selected.is_empty() and panel.node_action.disabled and panel.gameplay_map.removal_preview.is_empty(), "Document replacement atomically clears panel state")
	panel.queue_free()
	await process_frame
	if failures.is_empty():
		print("All tree panel boundary tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
