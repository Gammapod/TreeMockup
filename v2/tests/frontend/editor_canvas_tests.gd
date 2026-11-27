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
	_fresh()
	await process_frame
	_expect(editor.room_tools.visible and not editor.tree_tools.visible and editor.viewport_tools.visible and editor.selection_tools.visible, "Room view exposes room and viewport tools")
	_expect(editor.undo_button.is_visible_in_tree() and editor.redo_button.is_visible_in_tree(), "History remains visible in room view")
	editor._set_mode("tree")
	_expect(editor.tree_tools.visible and not editor.room_tools.visible and editor.viewport_tools.visible and editor.selection_tools.visible, "Tree view exposes tree and viewport tools")
	editor.inspector.text = "{invalid"
	editor.mode_buttons.room.pressed.emit()
	_expect(editor.mode == "tree" and editor.tree_tools.visible and not editor.room_tools.visible and editor.inspector.text == "{invalid", "Rejected mode change preserves contextual controls and JSON")
	editor.inspector.text = editor.inspector_original
	editor._set_mode("bundle")
	_expect(not editor.room_tools.visible and not editor.tree_tools.visible and not editor.viewport_tools.visible and not editor.selection_tools.visible, "Bundle view hides canvas-specific tools")
	_expect(editor.undo_button.is_visible_in_tree() and editor.redo_button.is_visible_in_tree(), "History remains visible in bundle view")
	editor._set_mode("room")
	var room: Dictionary = editor.document.rooms[0]
	room.objects = [
		{"id": "water", "kind": "water", "position": [100.0, 100.0], "size": [300, 200], "properties": {}, "extension": {"keep": true}},
		{"id": "enemy", "kind": "enemy", "position": [200.0, 200.0], "properties": {"radius": 20}}
	]
	editor._reset_history()
	editor._refresh()
	await process_frame
	var canvas = editor.preview
	_expect(canvas._object_icon_id({"kind": "token"}) == "token", "Explicit token has a token cue")
	for reward in ["health", "gold", "capacity"]:
		_expect(canvas._object_icon_id({"kind": "pickup", "properties": {"kind": reward}}) == reward, "Explicit pickup reward has a matching cue: " + reward)
		_expect(canvas._object_icon_id({"kind": "chest", "properties": {"kind": reward}}) == reward, "Explicit chest reward has a matching cue: " + reward)
	_expect(canvas._object_icon_id({"kind": "pickup", "properties": {}}).is_empty() and canvas._object_icon_id({"kind": "pickup", "properties": {"kind": "future"}}).is_empty(), "Missing or unknown reward never gains an inferred cue")
	_expect(canvas._object_icon_id({"kind": "enemy", "properties": {"kind": "gold"}}).is_empty(), "Reward-shaped properties do not change another object kind")
	_expect(canvas._terrain_label_fits("water", Vector2(250, 150), 1.0), "Large terrain can show a diagonal type label")
	_expect(not canvas._terrain_label_fits("water", Vector2(20, 10), 1.0) and not canvas._terrain_label_fits("water", Vector2(250, 150), 0.05), "Small or zoomed-out terrain suppresses labels")
	_expect(not canvas._terrain_label_fits("future", Vector2(250, 150), 1.0), "Unknown terrain kind has no inferred type label")
	_expect(canvas.hit_items(Vector2(390, 290))[0].id == "water", "Rectangles pick across their full area")
	_expect(canvas.hit_items(Vector2(219, 200))[0].id == "enemy", "Topmost visible object and authored radius win hit-testing")
	_click(Vector2(200, 200))
	_expect(canvas.selection == "enemy", "Object click establishes persistent selection")
	_click(Vector2(200, 200), true)
	_expect(canvas.selection == "water", "Alt-click cycles to underlying rectangle")
	var anchor := Vector2(350, 260)
	var start_screen: Vector2 = canvas.pan + anchor * canvas.zoom
	_mouse(start_screen, MOUSE_BUTTON_LEFT, true)
	var count: int = editor.history.undo_stack.size()
	_motion(start_screen + Vector2(10, 20) * canvas.zoom)
	_motion(start_screen + Vector2(40, 30) * canvas.zoom)
	_expect(editor.history.undo_stack.size() == count, "Motion frames do not become individual history entries")
	_mouse(start_screen + Vector2(40, 30) * canvas.zoom, MOUSE_BUTTON_LEFT, false)
	_expect(editor.document.rooms[0].objects[0].position == [140.0, 130.0], "Dragging preserves grab offset instead of jumping origin to cursor")
	_expect(editor.history.undo_stack.size() == count + 1 and editor.dirty, "One drag creates one dirty history entry")
	editor._undo()
	_expect(editor.document.rooms[0].objects[0].position == [100.0, 100.0] and not editor.dirty, "Undo restores geometry and saved-state marker")
	_expect(editor.preview.selection == "water" and editor.document.rooms[0].objects[0].extension.keep, "Undo restores selection and unknown data")
	editor._redo()
	_expect(editor.document.rooms[0].objects[0].position == [140.0, 130.0], "Redo reapplies full drag")
	var saved_path := "user://editor_canvas_test.json"
	editor._save_to(saved_path)
	editor._undo()
	_expect(editor.dirty, "Undo away from saved contents marks document dirty")
	editor._redo()
	_expect(not editor.dirty, "Redo to saved contents is clean")
	editor._duplicate_selection()
	_expect(editor.document.rooms[0].objects.size() == 3 and editor.preview.selection == "water_copy_1", "Duplicate creates and selects a fresh stable ID")
	_expect(editor.document.rooms[0].objects[2].extension.keep, "Duplicate preserves extension fields")
	editor._delete_selection()
	_expect(editor.document.rooms[0].objects.size() == 2 and editor.preview.selection.is_empty(), "Delete removes selected object")
	editor._undo()
	_expect(editor.document.rooms[0].objects.size() == 3 and editor.preview.selection == "water_copy_1", "Undo deletion restores source and selection")
	editor._undo()
	editor.preview.brush = "pickup"
	_click(Vector2(250, 250))
	_expect(editor.document.rooms[0].objects.back().kind == "pickup", "Brush can place on top of terrain")
	_expect(editor.history.redo_stack.is_empty(), "New source edit clears redo branch")
	editor.preview.brush = "select"
	var source: Dictionary = editor.document.duplicate(true)
	editor.inspector.text = "{broken"
	editor._delete_selection()
	editor._undo()
	_click(Vector2(200, 200))
	_expect(editor.document == source and editor.inspector.text == "{broken", "Invalid JSON survives selection/delete/history attempts without source mutation")
	editor._refresh()
	editor.inspector.grab_focus()
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_DELETE
	editor._unhandled_key_input(key)
	_expect(editor.document == source, "Delete while editing text cannot delete a canvas object")
	canvas.grab_focus()
	var pointer := Vector2(230, 170)
	var world_before: Vector2 = canvas.to_world(pointer)
	_mouse(pointer, MOUSE_BUTTON_WHEEL_UP, true)
	_expect(canvas.to_world(pointer).distance_to(world_before) < 0.001, "Wheel zoom is anchored at the cursor")
	_mouse(pointer, MOUSE_BUTTON_RIGHT, true)
	var pan_before: Vector2 = canvas.pan
	var motion := InputEventMouseMotion.new()
	motion.position = pointer + Vector2(70, -30)
	motion.relative = Vector2(70, -30)
	canvas._gui_input(motion)
	_mouse(motion.position, MOUSE_BUTTON_RIGHT, false)
	_expect(canvas.pan == pan_before + Vector2(70, -30), "Right-drag pans in screen coordinates")
	var camera := {"pan": canvas.pan, "zoom": canvas.zoom}
	var selection: String = canvas.selection
	editor._set_mode("tree")
	await process_frame
	editor._set_mode("room")
	_expect(canvas.pan.is_equal_approx(camera.pan) and is_equal_approx(canvas.zoom, camera.zoom) and canvas.selection == selection, "Returning to a template preserves camera and selection")
	_test_tree()
	await process_frame
	_test_doors()
	await process_frame
	# Responsive layout checks exercise container geometry, not just window settings.
	for dimensions in [Vector2i(960, 640), Vector2i(1600, 900), Vector2i(960, 1000)]:
		root.size = dimensions
		for mode in ["room", "tree", "bundle"]:
			editor._set_mode(mode)
			await process_frame
			await process_frame
			_expect(editor.preview.size.x >= 300 and editor.preview.size.y >= 200, "Canvas remains useful in %s at %s" % [mode, dimensions])
			_expect(editor.inspector_tabs.get_global_rect().end.x <= dimensions.x and editor.feedback.get_global_rect().end.y <= dimensions.y, "Inspector and feedback fit in %s at %s" % [mode, dimensions])
			_expect(editor.preview.get_global_rect().end.x <= editor.inspector_tabs.global_position.x, "Split panes do not overlap in " + mode)
			_expect(editor.undo_button.get_global_rect().end.x <= dimensions.x and editor.redo_button.get_global_rect().end.x <= dimensions.x, "History controls fit in %s at %s" % [mode, dimensions])
			if mode != "bundle":
				_expect(editor.viewport_tools.get_global_rect().end.y <= editor.preview.get_global_rect().position.y, "Viewport tools sit above canvas")
				_expect(editor.selection_tools.get_global_rect().end.y <= editor.inspector_tabs.get_global_rect().position.y, "Selection tools sit above Properties")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saved_path))
	editor.queue_free()
	await process_frame
	if failures.is_empty():
		print("All editor canvas/history tests passed.")
	else:
		for failure in failures:
			printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _fresh() -> void:
	editor.document = editor.store.migrate(editor.store.new_project())
	editor.room_index = 0
	editor.mode = "room"
	editor._reset_history()
	editor._refresh()

func _test_tree() -> void:
	_fresh()
	editor._add_node()
	var id: String = editor.selected_node
	editor.document.dungeon.links.append({"id": "passage", "a": "start", "b": id, "activate_from": ["start"]})
	editor.document.dungeon.nodes[1].abilities = ["sword"]
	editor._reset_history()
	editor._set_selection("node", id)
	editor._refresh()
	editor._duplicate_selection()
	_expect(editor.document.dungeon.nodes.size() == 3 and editor.document.dungeon.links.size() == 1, "Node duplication reuses template without cloning connections")
	_expect(editor.document.dungeon.nodes[2].abilities == ["sword"], "Node duplication retains grants")
	editor._undo()
	editor._set_selection("node", id)
	editor._delete_selection()
	_expect(editor.document.dungeon.nodes.size() == 1 and editor.document.dungeon.links.is_empty(), "Node deletion also removes incident links")
	editor._undo()
	_expect(editor.document.dungeon.links.size() == 1 and editor.selected_node == id, "Undo restores node and incident connections together")
	editor._set_selection("node", "start")
	editor._delete_selection()
	_expect(editor.document.dungeon.nodes.size() == 2, "Starting node deletion is rejected")
	editor._set_selection("link", "passage")
	editor._delete_selection()
	_expect(editor.document.dungeon.links.is_empty(), "Travel links can be deleted directly")
	editor._undo()
	var dependent: Dictionary = editor.store.new_node("dependent", "empty")
	dependent.requires_all = [id]
	editor.document.dungeon.nodes.append(dependent)
	editor._refresh()
	editor._set_selection("node", id)
	editor._delete_selection()
	_expect(editor.document.dungeon.nodes.size() == 3 and editor.feedback.text.begins_with("Delete blocked"), "Referenced prerequisite is not silently removed")
	editor._set_mode("room")
	editor.document.rooms[0].objects.append({"id": "last_enemy", "kind": "enemy", "position": [300, 300], "properties": {}})
	editor.document.rooms[0].clear = {"conditions": [{"kind": "all_enemies_defeated"}], "effects": []}
	editor._refresh()
	editor._select_element("object", "last_enemy")
	editor._delete_selection()
	_expect(editor.document.rooms[0].objects.size() == 1, "Deleting the last clear-condition target is rejected")

func _test_doors() -> void:
	_fresh()
	editor._add_node()
	var id: String = editor.selected_node
	editor.document.dungeon.links.append({"id": "door", "a": "start", "b": id, "activate_from": ["start"]})
	editor._refresh()
	editor._edit_doors()
	var panel = editor.active_door_editor
	var count: int = editor.history.undo_stack.size()
	panel.begin_edit()
	panel._drag("door_b", Vector2(300, 70))
	panel._drag("door_b", Vector2(450, 70))
	panel.finish_edit()
	_expect(editor.history.undo_stack.size() == count + 1, "Door drag is one history entry")
	_expect(editor.document.dungeon.links[0].b_door.wall == "north", "Door drag writes manual override")
	editor._undo()
	_expect(not editor.document.dungeon.links[0].has("b_door") and panel.resolved[0].automatic, "Undo door edit updates open selector and document together")
	editor._redo()
	_expect(panel.resolved[0].wall == "north" and not panel.resolved[0].automatic, "Redo refreshes open selector")
	panel._reset()
	editor._undo()
	_expect(editor.document.dungeon.links[0].has("b_door"), "Reset-to-automatic is independently undoable")
	panel.queue_free()

func _click(world: Vector2, alt: bool = false) -> void:
	var screen: Vector2 = editor.preview.pan + world * editor.preview.zoom
	_mouse(screen, MOUSE_BUTTON_LEFT, true, alt)
	_mouse(screen, MOUSE_BUTTON_LEFT, false, alt)

func _mouse(point: Vector2, button: MouseButton, pressed: bool, alt: bool = false) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = button
	event.pressed = pressed
	event.alt_pressed = alt
	editor.preview._gui_input(event)

func _motion(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	editor.preview._gui_input(event)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
