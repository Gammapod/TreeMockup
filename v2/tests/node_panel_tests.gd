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
	var room: Dictionary = store.new_room("trial")
	room.objects = [
		{"id": "lever", "kind": "switch", "position": [300, 150], "properties": {}},
		{"id": "barrier", "kind": "wall", "position": [300, 300], "size": [20, 100], "properties": {}},
		{"id": "reward", "kind": "chest", "position": [600, 200], "properties": {"kind": "capacity", "value": 3}},
		{"id": "key", "kind": "pickup", "position": [600, 300], "properties": {"kind": "capacity", "value": 2}}
	]
	room.clear = {"conditions": [{"kind": "switch_hit", "object": "lever"}], "effects": [{"kind": "reveal_pickup", "object": "reward"}]}
	room.extension = {"preserve": "template"}
	editor.document.rooms.append(room)
	editor.document.rooms.append(store.new_room("blank"))
	for id in ["one", "two"]:
		var node: Dictionary = store.new_node(id, "trial")
		node.map_position = [100 if id == "one" else 300, 200]
		node.extension = {"preserve": "node"}
		editor.document.dungeon.nodes.append(node)
	editor.document.dungeon.links = [{"id": "travel", "a": "one", "b": "two", "activate_from": ["one", "two"]}]
	editor.document.dungeon.interactions = [{"id": "binding", "source": {"node": "one", "object": "lever", "event": "toggled"}, "target": {"node": "two", "object": "barrier", "action": "set_open"}}]
	editor._reset_history()
	editor._set_mode("tree")
	editor._select_element("node", "one")
	await process_frame
	var panel = editor.node_panel
	_expect(editor.inspector_tabs.current_tab == 0 and panel.node_id == "one", "Selecting a tree node populates Properties")
	_expect(panel.usage.text.begins_with("Used by 2"), "Template usage counts instances")
	_expect(panel.summary.text.contains("Potential capacity upgrades: +5") and panel.summary.text.contains("reward: +3 (chest, revealed on clear)"), "Capacity summary includes chest values and clear-hidden rewards")
	_expect(panel.summary.text.contains("Hit switch — lever") and panel.summary.text.contains("Reveal collectible — reward"), "Clear conditions/effects are named read-only summaries")
	var pristine: Dictionary = editor.document.duplicate(true)
	panel.configure(editor.document, "one")
	_expect(editor.document == pristine and editor.history.undo_stack.is_empty(), "Displaying Properties cannot author defaults or dirty source")
	panel.cost.value = 3
	_expect(_node("one").cost == 3 and _node("two").cost == 1, "Numeric cost only edits selected node")
	editor._undo()
	_expect(panel.cost.value == 1 and _node("one").cost == 1, "Undo synchronizes property controls")
	editor._redo()
	_expect(panel.cost.value == 3, "Redo restores property control")
	panel.abilities.get_popup().id_pressed.emit(0)
	panel.abilities.get_popup().id_pressed.emit(1)
	_expect(_node("one").abilities == ["sword", "dash"], "Ability picker supports multiple grants")
	_node("one").abilities.append("future_ability")
	_node("one").modifiers = {"future_modifier": {"keep": true}, "sword_range_multiplier": 1.3}
	editor._refresh()
	panel.abilities.get_popup().id_pressed.emit(0)
	_expect(_node("one").abilities == ["dash", "future_ability"], "Known ability edits retain unsupported grants")
	panel.numeric_controls.sword_arc_multiplier.enabled.button_pressed = true
	panel.numeric_controls.sword_arc_multiplier.value.value = 1.5
	panel.style_controls.dash_style.select(1)
	panel.style_controls.dash_style.item_selected.emit(1)
	_expect(_node("one").modifiers.sword_arc_multiplier == 1.5 and _node("one").modifiers.dash_style == "phase", "Numeric and behavior modifiers are authored")
	_expect(_node("one").modifiers.future_modifier.keep and _node("one").modifiers.sword_range_multiplier == 1.3, "Modifier editing retains unrelated and unknown fields")
	panel.numeric_controls.sword_arc_multiplier.enabled.button_pressed = false
	_expect(not _node("one").modifiers.has("sword_arc_multiplier"), "Disabling a modifier removes only that key")
	# Switching templates must reject missing references and wrong-kind objects.
	panel.templates.select(2)
	panel.templates.item_selected.emit(2)
	_expect(_node("one").template == "trial" and panel.templates.get_item_metadata(panel.templates.selected) == "trial", "Invalid template switch is rejected and picker restored")
	var wrong: Dictionary = room.duplicate(true)
	wrong.id = "wrong"
	wrong.objects[0].kind = "pickup"
	wrong.clear = {"conditions": [], "effects": []}
	editor.document.rooms.append(wrong)
	editor._refresh()
	editor._edit_node_field("one", "template", "wrong")
	_expect(_node("one").template == "trial" and editor.feedback.text.contains("Unsupported interaction"), "Template switch cannot silently retarget a switch binding to a pickup")
	var before_duplicate: Dictionary = editor.document.duplicate(true)
	var history_count: int = editor.history.undo_stack.size()
	panel.template_duplicate_requested.emit("one")
	var copy_id: String = _node("one").template
	_expect(copy_id != "trial" and _node("two").template == "trial", "Duplicate-and-assign isolates only the selected instance")
	var copy: Dictionary = editor.document.rooms.back()
	_expect(copy.extension.preserve == "template" and copy.objects[0].id == "lever", "Template clone preserves unknown fields and local object IDs")
	_expect(editor.document.dungeon.interactions == before_duplicate.dungeon.interactions, "Template clone retains stable instance bindings")
	_expect(editor.history.undo_stack.size() == history_count + 1, "Template duplication and assignment form one transaction")
	editor._undo()
	_expect(editor.document == before_duplicate, "Undo atomically removes template copy and restores assignment")
	editor._redo()
	_expect(_node("one").template == copy_id, "Redo restores the same stable template ID")
	editor.preview.pan = Vector2(41, 75)
	editor.preview.zoom = 0.7
	editor.preview.fitting = false
	panel.template_edit_requested.emit("one")
	_expect(editor.mode == "room" and editor.document.rooms[editor.room_index].id == copy_id and editor.return_button.visible, "Edit-template navigates to the assigned copy")
	editor._return_to_node()
	_expect(editor.mode == "tree" and editor.selected_node == "one" and editor.preview.pan == Vector2(41, 75) and editor.preview.zoom == 0.7, "Back-to-node preserves graph view and selection")
	# Inline preview and the accepted selector share endpoint placement/history.
	var expected: Dictionary = load("res://authoring/door_layout.gd").resolve(editor.document)
	_expect(panel.canvas.instance_doors == expected.nodes.one, "Inline preview uses the common resolver")
	history_count = editor.history.undo_stack.size()
	panel.canvas.gesture_started.emit()
	panel.canvas.door_moved.emit("travel_a", Vector2(200, 70))
	panel.canvas.door_moved.emit("travel_a", Vector2(500, 70))
	panel.canvas.gesture_finished.emit()
	_expect(editor.history.undo_stack.size() == history_count + 1 and editor.document.dungeon.links[0].a_door.wall == "north", "Inline door drag is one reversible instance edit")
	editor._undo()
	_expect(not editor.document.dungeon.links[0].has("a_door") and panel.canvas.instance_doors[0].automatic, "Undo restores automatic placement in preview")
	# Pending invalid JSON cannot be overwritten by the form or hidden by tab changes.
	var before_invalid: Dictionary = editor.document.duplicate(true)
	editor.inspector_tabs.current_tab = 2
	editor.inspector.text = "{invalid"
	editor.inspector_tabs.current_tab = 0
	_expect(editor.inspector_tabs.current_tab == 2 and editor.inspector.text == "{invalid", "Invalid JSON keeps its source tab and text")
	editor._edit_node_field("one", "cost", 7)
	_expect(editor.document == before_invalid and editor.inspector.text == "{invalid", "Invalid pending source blocks property edits")
	editor._refresh()
	editor._select_element("node", "two")
	_expect(panel.node_id == "two" and panel.cost.value == 1, "Selection changes do not show stale node data")
	editor._edit_node_field("one", "cost", 99)
	_expect(_node("one").cost != 99, "Stale node intent cannot edit previously selected node")
	var save_path := "user://node_panel_test.json"
	editor._save_to(save_path)
	var loaded: Dictionary = store.load_document(save_path)
	_expect(loaded.ok and loaded.document.dungeon.nodes[1].template == copy_id, "Property edits round-trip in portable content")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	# Both tabs fit at the minimum window size, including expanded modifiers.
	root.size = Vector2i(960, 640)
	editor.inspector_tabs.current_tab = 0
	panel.modifiers_box.show()
	await process_frame
	await process_frame
	_expect(editor.inspector_tabs.get_global_rect().end.x <= 960 and editor.feedback.get_global_rect().end.y <= 640, "Expanded properties fit minimum window")
	_expect(panel.get_v_scroll_bar().visible, "Long contextual form scrolls instead of displacing canvas")
	editor.queue_free()
	await process_frame
	if failures.is_empty():
		print("All node contextual panel tests passed.")
	else:
		for failure in failures:
			printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _node(id: String) -> Dictionary:
	for node in editor.document.dungeon.nodes:
		if node.id == id:
			return node
	return {}

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
