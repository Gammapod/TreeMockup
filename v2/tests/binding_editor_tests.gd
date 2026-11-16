extends "res://tests/suite_reporter.gd"

var failures: Array[String] = []
var editor

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280, 800)
	editor = load("res://authoring/studio.gd").new()
	root.add_child(editor)
	await process_frame
	var store = editor.store
	editor.document = store.migrate(store.new_project())
	var source: Dictionary = store.new_room("switch_room")
	source.objects = [
		{"id": "lever_a", "kind": "switch", "position": [200, 200], "properties": {}},
		{"id": "lever_b", "kind": "switch", "position": [300, 200], "properties": {}}
	]
	var target: Dictionary = store.new_room("wall_room")
	target.objects = [
		{"id": "wall_a", "kind": "wall", "position": [300, 200], "size": [20, 120], "properties": {}},
		{"id": "wall_b", "kind": "wall", "position": [500, 200], "size": [20, 120], "properties": {}}
	]
	editor.document.rooms.append(source)
	editor.document.rooms.append(target)
	for pair in [["source_a", "switch_room"], ["source_b", "switch_room"], ["target_a", "wall_room"], ["target_b", "wall_room"]]:
		var node: Dictionary = store.new_node(pair[0], pair[1])
		editor.document.dungeon.nodes.append(node)
	editor._reset_history()
	editor._set_mode("room")
	editor.room_index = 1
	editor._select_element("object", "lever_a")
	await process_frame
	_expect(not editor.binding_button.disabled and editor.room_panel.binding_box.visible, "Switch selection exposes binding indicator/action")
	_expect(editor.room_panel.binding_summary.text == "No switch/wall bindings.", "Unbound switch explains its state")
	editor.room_panel.bindings_requested.emit({"source_node": "source_a", "source_object": "lever_a"})
	var dialog = editor.get_children().filter(func(child): return child is AcceptDialog).back()
	_expect(dialog.source_node.get_item_metadata(dialog.source_node.selected) == "source_a" and dialog.source_object.get_item_metadata(dialog.source_object.selected) == "lever_a", "Source focus preselects switch instance/object")
	_expect(dialog.target_node.item_count == 2 and dialog.target_object.item_count == 2, "Picker filters targets to node instances containing walls")
	var history_count: int = editor.history.undo_stack.size()
	dialog.target_node.select(0)
	dialog.target_node.item_selected.emit(0)
	dialog.target_object.select(1)
	dialog.target_object.item_selected.emit(1)
	dialog._add()
	_expect(editor.document.dungeon.interactions.size() == 1 and editor.history.undo_stack.size() == history_count + 1, "Picker creates stable source/target binding in one undoable transaction")
	var binding: Dictionary = editor.document.dungeon.interactions[0]
	_expect(binding.source == {"node": "source_a", "object": "lever_a", "event": "toggled"} and binding.target == {"node": "target_a", "object": "wall_b", "action": "set_open"}, "Picker writes the existing runtime interaction vocabulary")
	_expect(editor.room_panel.binding_summary.text.contains("source_a opens: target_a.wall_b"), "Source indicator names target")
	dialog._add()
	_expect(editor.document.dungeon.interactions.size() == 1 and dialog.feedback.text == "That binding already exists.", "Duplicate binding is prevented")
	editor._undo()
	_expect(editor.document.dungeon.interactions.is_empty() and editor.room_panel.binding_summary.text == "No switch/wall bindings.", "Undo removes binding and refreshes room indicator")
	editor._redo()
	_expect(editor.document.dungeon.interactions.size() == 1, "Redo restores binding")
	editor.room_index = 2
	editor._refresh()
	editor._select_element("object", "wall_b")
	_expect(editor.room_panel.binding_summary.text.contains("target_a opened by: source_a.lever_a"), "Target wall indicator identifies its source")
	editor._set_mode("tree")
	editor._select_element("node", "source_a")
	_expect(editor.node_panel.bindings.text.contains("Switch binding out: lever_a → target_a.wall_b"), "Tree source node displays outbound binding")
	editor._select_element("node", "target_a")
	_expect(editor.node_panel.bindings.text.contains("Switch binding in: source_a.lever_a → wall_b"), "Tree target node displays inbound binding")
	dialog.queue_free()
	await process_frame
	editor._edit_bindings({"target_node": "target_a", "target_object": "wall_b"})
	var remove_dialog = editor.get_children().filter(func(child): return child is AcceptDialog).back()
	_expect(remove_dialog.target_node.get_item_metadata(remove_dialog.target_node.selected) == "target_a", "Target focus preselects wall instance")
	remove_dialog.binding_removed.emit(binding.id)
	_expect(editor.document.dungeon.interactions.is_empty(), "Binding removal works from picker list")
	editor._undo()
	_expect(editor.document.dungeon.interactions.size() == 1, "Undo removal restores binding")
	# Source JSON remains authoritative: binding controls cannot overwrite invalid text.
	editor.inspector_tabs.current_tab = 2
	editor.inspector.text = "{invalid"
	var before: Dictionary = editor.document.duplicate(true)
	editor._edit_bindings()
	_expect(editor.document == before and editor.inspector.text == "{invalid", "Invalid pending JSON blocks binding editor")
	editor._refresh()
	var data: Dictionary = load("res://authoring/runtime_adapter.gd").new().compile(editor.document)
	_expect(data.ok, "Picker-authored binding compiles for runtime")
	var path := "user://binding_editor_test.json"
	editor._save_to(path)
	_expect(store.load_document(path).ok, "Picker-authored binding round-trips")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	editor.queue_free()
	await process_frame
	if failures.is_empty():
		print("All switch binding editor tests passed.")
	else:
		for failure in failures:
			printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
