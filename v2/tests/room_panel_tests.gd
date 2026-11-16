extends SceneTree

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
	var room: Dictionary = editor.document.rooms[0]
	room.name = "Laboratory"
	room.extension = {"keep": "template"}
	room.objects = [
		{"id": "water", "kind": "water", "position": [100, 100], "size": [200, 120], "properties": {"future": true}, "extension": {"keep": "rectangle"}},
		{"id": "bat", "kind": "enemy", "position": [500, 160], "properties": {"hp": 3, "speed": 80, "radius": 18, "behavior": "chase", "future": "preserve"}},
		{"id": "coin", "kind": "pickup", "position": [500, 300], "properties": {"kind": "gold", "value": 4}},
		{"id": "box", "kind": "chest", "position": [600, 300], "properties": {"kind": "capacity", "value": 2}},
		{"id": "lever", "kind": "switch", "position": [400, 400], "properties": {}}
	]
	room.clear = {"conditions": [{"kind": "switch_hit", "object": "lever"}], "effects": [{"kind": "reveal_pickup", "object": "box"}]}
	var second: Dictionary = store.new_node("second", "empty")
	editor.document.dungeon.nodes.append(second)
	editor._reset_history()
	editor._set_mode("room")
	editor._select_element("object", "water")
	await process_frame
	var panel = editor.room_panel
	_expect(editor.inspector_tabs.current_tab == 1 and panel.object_id == "water", "Selected room object opens contextual Properties")
	_expect(panel.rectangle_box.visible and not panel.enemy_box.visible and not panel.pickup_box.visible, "Rectangle controls vary by object kind")
	_expect(panel.usage.text.begins_with("Used by 2"), "Template panel counts every instance")
	_expect(panel.dimensions.text.contains("fixed for playtest"), "Dimensions clearly state deferred runtime limitation")
	var source: Dictionary = editor.document.duplicate(true)
	_expect(editor.history.undo_stack.is_empty() and panel.width.value == 200 and editor.document == source, "Displaying contextual values is source-safe")
	panel.width.value = 230
	_expect(_object("water").size == [230.0, 120.0], "Width control edits rectangle geometry")
	editor._undo()
	_expect(_object("water").size == [200, 120] and panel.width.value == 200, "Undo restores rectangle geometry and panel")
	editor._redo()
	_expect(_object("water").size == [230.0, 120.0], "Redo restores rectangle geometry")
	# Selected rectangle edges/corners resize as one gesture and preserve unknown fields.
	var canvas = editor.preview
	var start: Vector2 = canvas.pan + Vector2(330, 220) * canvas.zoom
	var down := InputEventMouseButton.new()
	down.position = start
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	canvas._gui_input(down)
	var history_count: int = editor.history.undo_stack.size()
	var motion := InputEventMouseMotion.new()
	motion.position = start + Vector2(50, 30) * canvas.zoom
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	canvas._gui_input(motion)
	var up := InputEventMouseButton.new()
	up.position = motion.position
	up.button_index = MOUSE_BUTTON_LEFT
	canvas._gui_input(up)
	_expect(_object("water").size == [280.0, 150.0] and editor.history.undo_stack.size() == history_count + 1, "Corner drag resizes width/height in one history entry")
	_expect(_object("water").extension.keep == "rectangle" and _object("water").properties.future, "Direct resize preserves unknown fields")
	editor._undo()
	_expect(_object("water").size == [230.0, 120.0], "Undo direct resize restores geometry")
	editor._select_element("object", "bat")
	_expect(panel.enemy_box.visible and not panel.rectangle_box.visible, "Enemy selection shows enemy stats")
	panel.enemy_hp.value = 7
	panel.enemy_speed.value = 120
	panel.enemy_radius.value = 22
	_expect(_object("bat").properties.hp == 7 and _object("bat").properties.speed == 120 and is_equal_approx(_object("bat").properties.radius, 22), "Enemy health/speed/radius fields author supported stats")
	_expect(_object("bat").properties.future == "preserve", "Enemy controls retain unknown properties")
	editor._select_element("object", "coin")
	_expect(panel.pickup_box.visible and panel.pickup_kind.selected == 0, "Pickup selection exposes reward controls")
	panel.pickup_kind.select(1)
	panel.pickup_kind.item_selected.emit(1)
	panel.pickup_value.value = 6
	_expect(_object("coin").properties == {"kind": "capacity", "value": 6}, "Collectible kind and value are editable")
	editor._select_element("object", "box")
	_expect(panel.pickup_box.visible and panel.pickup_kind.selected == 1, "Chest uses the same reward controls")
	editor._select_element("object", "water")
	panel.id_input.focus_entered.emit()
	panel.id_input.text = "river"
	panel.id_input.focus_exited.emit()
	_expect(_object("river").extension.keep == "rectangle" and editor.preview.selection == "river", "Object ID edit preserves data and updates selection")
	editor._undo()
	_expect(not _object("water").is_empty() and editor.preview.selection == "water", "Undo object rename restores selection")
	# In-use IDs cannot become invalid; no partial source mutation is allowed.
	editor._select_element("object", "lever")
	editor.document.rooms[0].clear = {"conditions": [{"kind": "switch_hit", "object": "lever"}], "effects": []}
	editor._refresh()
	panel.id_input.focus_entered.emit()
	panel.id_input.text = "renamed_lever"
	panel.id_input.focus_exited.emit()
	_expect(not _object("lever").is_empty() and editor.feedback.text.begins_with("Object edit rejected"), "Referenced object rename is rejected rather than silently rewriting clear rules")
	panel.template_requested.emit("missing", {"name": "Wrong"})
	_expect(editor.document.rooms[0].name == "Laboratory", "Stale template intent cannot edit another template")
	panel.room_name.focus_entered.emit()
	panel.room_name.text = "Lab copy"
	panel.room_name.focus_exited.emit()
	_expect(editor.document.rooms[0].name == "Lab copy" and editor.document.rooms[0].extension.keep == "template", "Template name is editable and preserves extensions")
	panel.clear_rules_requested.emit("empty")
	var windows: Array = editor.find_children("*", "ConfirmationDialog", false, false)
	_expect(not windows.is_empty() and windows.back().title.begins_with("Clear rules"), "Template panel opens existing clear-rule editor")
	windows.back().queue_free()
	# Pending invalid JSON blocks typed controls exactly like canvas tools.
	var before_invalid: Dictionary = editor.document.duplicate(true)
	editor.inspector_tabs.current_tab = 2
	editor.inspector.text = "{invalid"
	editor.inspector_tabs.current_tab = 1
	_expect(editor.inspector_tabs.current_tab == 2 and editor.inspector.text == "{invalid", "Invalid JSON retains source tab")
	panel.enemy_hp.value = 99
	_expect(editor.document == before_invalid and editor.inspector.text == "{invalid", "Invalid pending JSON blocks room contextual edits")
	editor._refresh()
	var path := "user://room_panel_test.json"
	editor._save_to(path)
	var loaded: Dictionary = store.load_document(path)
	_expect(loaded.ok and loaded.document.rooms[0].name == "Lab copy", "Room contextual edits round-trip")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	root.size = Vector2i(960, 640)
	await process_frame
	await process_frame
	_expect(editor.inspector_tabs.get_global_rect().end.x <= 960 and panel.get_v_scroll_bar().visible, "Room contextual panel remains scrollable in minimum window")
	editor.queue_free()
	await process_frame
	if failures.is_empty():
		print("All room contextual panel tests passed.")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _object(id: String) -> Dictionary:
	for object in editor.document.rooms[0].objects:
		if object.id == id:
			return object
	return {}

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
