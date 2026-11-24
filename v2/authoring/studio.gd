extends Control

signal play_requested(data: Dictionary)
signal close_requested

const STORE = preload("res://authoring/content_store.gd")
const ADAPTER = preload("res://authoring/runtime_adapter.gd")
const PREVIEW = preload("res://authoring/preview.gd")
const DOOR_EDITOR = preload("res://authoring/door_editor.gd")
const HISTORY = preload("res://authoring/edit_history.gd")
const NODE_PANEL = preload("res://authoring/node_panel.gd")
const DOOR_LAYOUT = preload("res://authoring/door_layout.gd")
const ROOM_PANEL = preload("res://authoring/room_panel.gd")
const BINDING_EDITOR = preload("res://authoring/binding_editor.gd")
var store = STORE.new()
var document: Dictionary
var path := ""
var dirty := false
var mode := "room"
var room_index := 0
var inspector: CodeEdit
var preview
var picker: OptionButton
var brush: OptionButton
var feedback: Label
var title: Label
var dialog: FileDialog
var file_action := ""
var inspector_original := ""
var selected_node := ""
var selected_link := ""
var room_selections: Dictionary = {}
var history = HISTORY.new()
var saved_document: Dictionary = {}
var gesture_before: Dictionary = {}
var views: Dictionary = {}
var view_key := ""
var split: HSplitContainer
var selection_label: Label
var undo_button: Button
var redo_button: Button
var duplicate_button: Button
var delete_button: Button
var door_button: Button
var active_door_editor
var door_before: Dictionary = {}
var node_panel
var inspector_tabs: TabContainer
var panel_mode := ""
var changing_tabs := false
var return_node := ""
var return_button: Button
var inline_door_before: Dictionary = {}
var room_panel
var binding_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("101925")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var layout := VBoxContainer.new()
	margin.add_child(layout)
	var toolbar := HFlowContainer.new()
	layout.add_child(toolbar)
	_button(toolbar, "New", _new_project)
	_button(toolbar, "Open…", func(): _file("open"))
	_button(toolbar, "Save", _save)
	_button(toolbar, "Save as…", func(): _file("save"))
	_button(toolbar, "Import room…", func(): _file("import"))
	_button(toolbar, "Export room…", func(): _file("export"))
	_button(toolbar, "Validate", _validate)
	_button(toolbar, "Playtest", _play)
	_button(toolbar, "Resume run", func(): close_requested.emit())
	var tools := HFlowContainer.new()
	layout.add_child(tools)
	_button(tools, "Room editor", func(): _set_mode("room"))
	_button(tools, "Tree editor", func(): _set_mode("tree"))
	_button(tools, "Bundle JSON", func(): _set_mode("bundle"))
	picker = OptionButton.new()
	picker.custom_minimum_size.x = 160
	picker.item_selected.connect(_select_room)
	tools.add_child(picker)
	_button(tools, "+ Room", _add_room)
	_button(tools, "+ Node", _add_node)
	_button(tools, "+ Link", _add_link)
	door_button = _button(tools, "Instance doors…", _edit_doors)
	brush = OptionButton.new()
	for kind in ["select", "enemy", "pickup", "chest", "token", "obstacle", "water", "switch", "wall"]:
		brush.add_item(kind)
	brush.item_selected.connect(func(index): preview.brush = brush.get_item_text(index))
	tools.add_child(brush)
	_button(tools, "Clear rules…", _edit_clear)
	binding_button = _button(tools, "Bindings…", _edit_bindings)
	return_button = _button(tools, "Back to node", _return_to_node)
	return_button.hide()
	var actions := HFlowContainer.new()
	layout.add_child(actions)
	undo_button = _button(actions, "Undo", _undo)
	redo_button = _button(actions, "Redo", _redo)
	duplicate_button = _button(actions, "Duplicate", _duplicate_selection)
	delete_button = _button(actions, "Delete", _delete_selection)
	_button(actions, "Deselect", _deselect)
	_button(actions, "Fit view", func(): preview.fit_content())
	var snap := CheckBox.new()
	snap.text = "Snap 10"
	snap.button_pressed = true
	snap.toggled.connect(func(enabled): preview.snap_enabled = enabled)
	actions.add_child(snap)
	title = Label.new()
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	layout.add_child(title)
	selection_label = Label.new()
	selection_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	layout.add_child(selection_label)
	split = HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(split)
	preview = PREVIEW.new()
	preview.custom_minimum_size = Vector2(300, 200)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.placed.connect(_place)
	preview.moved.connect(_move)
	preview.selected.connect(_select_element)
	preview.gesture_started.connect(_begin_gesture)
	preview.gesture_finished.connect(_end_gesture)
	preview.object_resized.connect(_resize_object)
	split.add_child(preview)
	inspector_tabs = TabContainer.new()
	inspector_tabs.custom_minimum_size.x = 320
	inspector_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(inspector_tabs)
	node_panel = NODE_PANEL.new()
	node_panel.name = "NodeProperties"
	inspector_tabs.add_child(node_panel)
	inspector_tabs.set_tab_title(0, "Properties")
	node_panel.field_requested.connect(_edit_node_field)
	node_panel.model_requested.connect(_set_capability_model)
	node_panel.contribution_requested.connect(_edit_contribution)
	node_panel.template_edit_requested.connect(_edit_node_template)
	node_panel.template_duplicate_requested.connect(_duplicate_node_template)
	node_panel.doors_requested.connect(_edit_doors)
	node_panel.door_requested.connect(_move_inline_door)
	node_panel.door_gesture_started.connect(_begin_inline_door)
	node_panel.door_gesture_finished.connect(_end_inline_door)
	room_panel = ROOM_PANEL.new()
	room_panel.name = "RoomProperties"
	inspector_tabs.add_child(room_panel)
	inspector_tabs.set_tab_title(1, "Properties")
	room_panel.object_requested.connect(_edit_room_object)
	room_panel.template_requested.connect(_edit_template)
	room_panel.clear_rules_requested.connect(_edit_clear_for_room)
	room_panel.bindings_requested.connect(_edit_bindings)
	var source_panel := VBoxContainer.new()
	source_panel.name = "JSON"
	source_panel.custom_minimum_size.x = 280
	source_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_tabs.add_child(source_panel)
	_button(source_panel, "Apply JSON edits", func():
		if _apply():
			_refresh()
			_message("Applied. Save writes the whole bundle; playtest starts a fresh run."))
	inspector = CodeEdit.new()
	inspector.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspector.custom_minimum_size = Vector2(280, 180)
	inspector.gutters_draw_line_numbers = true
	source_panel.add_child(inspector)
	inspector_tabs.tab_changed.connect(func(index):
		if index in [0, 1] and not changing_tabs:
			if _apply(): _refresh()
			else: inspector_tabs.current_tab = 2)
	feedback = Label.new()
	feedback.custom_minimum_size.y = 40
	feedback.max_lines_visible = 2
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(feedback)
	dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json ; Portable content JSON"])
	dialog.file_selected.connect(_file_selected)
	add_child(dialog)
	var initial: Dictionary = store.load_document("res://examples/branching.json")
	document = store.migrate(initial.document if initial.ok else store.new_project())
	saved_document = document.duplicate(true)
	visibility_changed.connect(func():
		if not visible:
			preview.finish_gesture()
			node_panel.canvas.finish_gesture()
			preview.resizing = ""
			preview.panning = false)
	_refresh()
	_message("Click to select; drag to move. Alt-click cycles overlaps. Wheel zooms; right/middle-drag pans. Ctrl+D duplicates; Delete removes; Ctrl+Z / Ctrl+Shift+Z undo/redo.")

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _apply() -> bool:
	if inspector.text == inspector_original:
		return true
	var json := JSON.new()
	if json.parse(inspector.text) != OK or not json.data is Dictionary:
		_message("Invalid inspector JSON: " + json.get_error_message())
		return false
	var candidate := document.duplicate(true)
	match mode:
		"room": candidate.rooms[room_index] = json.data
		"tree": candidate.dungeon = json.data
		"bundle": candidate = json.data
	var errors: Array[String] = store.validate(candidate)
	if not errors.is_empty():
		_message("Not applied: " + "; ".join(errors))
		return false
	var before := _snapshot()
	document = store.migrate(candidate)
	inspector_original = inspector.text
	_record("JSON edits", before)
	return true

func _refresh() -> void:
	dirty = document != saved_document
	room_index = clampi(room_index, 0, maxi(0, document.rooms.size() - 1))
	picker.clear()
	for room in document.rooms:
		picker.add_item(room.id)
	if not document.rooms.is_empty():
		picker.select(room_index)
	var value: Dictionary = document
	if mode == "room" and not document.rooms.is_empty():
		value = document.rooms[room_index]
	elif mode == "tree":
		value = document.dungeon
	preview.mode = "tree" if mode != "room" else "room"
	preview.content = document.dungeon if mode != "room" else value
	if mode == "room" and document.version == 2:
		preview.content = value.duplicate(true)
		preview.content.erase("ports")
	var next_key: String = "room:" + str(value.get("id", "")) if mode == "room" else "tree"
	if view_key != next_key:
		if not view_key.is_empty():
			views[view_key] = {"pan": preview.pan, "zoom": preview.zoom, "fitting": preview.fitting, "size": preview.size}
		view_key = next_key
		if views.has(view_key):
			preview.pan = views[view_key].pan + (preview.size - views[view_key].size) / 2
			preview.zoom = views[view_key].zoom
			preview.fitting = views[view_key].fitting
		else:
			preview.fit_content.call_deferred()
	_sync_selection()
	preview.queue_redraw()
	inspector.text = JSON.stringify(value, "\t", false)
	inspector_original = inspector.text
	title.text = "%s%s — %s" % [document.name, " *" if dirty else "", path if path != "" else "unsaved bundle"]
	_update_actions()
	_update_context()

func _update_context() -> void:
	changing_tabs = true
	inspector_tabs.set_tab_hidden(0, mode != "tree")
	inspector_tabs.set_tab_hidden(1, mode != "room")
	if mode != panel_mode:
		inspector_tabs.current_tab = 0 if mode == "tree" else (1 if mode == "room" else 2)
		panel_mode = mode
	changing_tabs = false
	node_panel.metadata = store.capability_metadata()
	node_panel.configure(document, selected_node if mode == "tree" else "")
	var room_id: String = document.rooms[room_index].id if mode == "room" and not document.rooms.is_empty() else ""
	room_panel.configure(document, room_id, room_selections.get(room_id, ""))
	return_button.visible = mode == "room" and not return_node.is_empty()
	binding_button.disabled = not _has_binding_endpoints()

func _has_binding_endpoints() -> bool:
	var switches := false
	var walls := false
	for room in document.rooms:
		for object in room.objects:
			switches = switches or object.kind == "switch"
			walls = walls or object.kind == "wall"
	return switches and walls

func _edit_bindings(focus: Dictionary = {}) -> void:
	if not _apply():
		return
	var window = BINDING_EDITOR.new()
	add_child(window)
	window.setup(document, focus)
	window.binding_added.connect(func(binding):
		var candidate := document.duplicate(true)
		candidate.dungeon.interactions.append(binding)
		var errors: Array[String] = store.validate(candidate)
		if errors.is_empty():
			var before := _snapshot()
			document = candidate
			_record("Add switch binding", before)
			window.document = document
			window._refresh_existing()
			_refresh()
			_message("Binding added: %s.%s → %s.%s" % [binding.source.node, binding.source.object, binding.target.node, binding.target.object])
		else:
			window.feedback.text = "Rejected: " + "; ".join(errors))
	window.binding_removed.connect(func(id):
		var candidate := document.duplicate(true)
		candidate.dungeon.interactions = candidate.dungeon.interactions.filter(func(entry): return entry.id != id)
		var before := _snapshot()
		document = candidate
		_record("Remove switch binding", before)
		window.document = document
		window._refresh_existing()
		_refresh()
		_message("Binding removed. Undo restores it."))
	window.confirmed.connect(window.queue_free)
	window.canceled.connect(window.queue_free)
	window.popup_centered(Vector2i(580, 520))

func _edit_room_object(room_id: String, id: String, patch: Dictionary) -> void:
	if not _apply() or mode != "room" or document.rooms[room_index].id != room_id:
		return
	var candidate := document.duplicate(true)
	for object in candidate.rooms[room_index].objects:
		if object.id != id:
			continue
		for key in patch:
			object[key] = patch[key]
		var errors: Array[String] = store.validate(candidate)
		if not errors.is_empty():
			_message("Object edit rejected: " + "; ".join(errors))
			_refresh()
			return
		var before := _snapshot()
		document = candidate
		if patch.has("id"):
			_set_selection("object", patch.id)
		_record("Edit " + id, before)
		_refresh()
		return

func _edit_template(id: String, patch: Dictionary) -> void:
	if not _apply() or mode != "room" or document.rooms[room_index].id != id:
		return
	var candidate := document.duplicate(true)
	for key in patch:
		candidate.rooms[room_index][key] = patch[key]
	var errors: Array[String] = store.validate(candidate)
	if not errors.is_empty():
		_message("Template edit rejected: " + "; ".join(errors))
		_refresh()
		return
	var before := _snapshot()
	document = candidate
	_record("Edit template", before)
	_refresh()

func _edit_clear_for_room(id: String) -> void:
	if mode == "room" and document.rooms[room_index].id == id:
		_edit_clear()

func _resize_object(id: String, bounds: Rect2) -> void:
	if mode != "room":
		return
	var candidate := document.duplicate(true)
	for object in candidate.rooms[room_index].objects:
		if object.id != id:
			continue
		object.position = [bounds.position.x, bounds.position.y]
		object.size = [bounds.size.x, bounds.size.y]
		var errors: Array[String] = store.validate(candidate)
		if not errors.is_empty():
			_message("Resize rejected: " + "; ".join(errors))
			return
		document = candidate
		_refresh()
		return

func _edit_node_field(id: String, field: String, value: Variant) -> void:
	if not _apply():
		_update_context()
		return
	if mode != "tree" or selected_node != id or field not in ["name", "cost", "abilities", "modifiers", "template"]:
		return
	var candidate := document.duplicate(true)
	for node in candidate.dungeon.nodes:
		if node.id != id:
			continue
		if node.get(field) == value:
			return
		node[field] = value
		var errors: Array[String] = store.validate(candidate)
		if errors.is_empty() and field == "template":
			# Reject new runtime conflicts (including wrong-kind binding targets)
			# without making unrelated, pre-existing unsupported content uneditable.
			var existing: Array = ADAPTER.new().compile(document).errors
			for error in ADAPTER.new().compile(candidate).errors:
				if error not in existing:
					errors.append(error)
		if not errors.is_empty():
			_message("Edit rejected: " + "; ".join(errors))
			_update_context()
			return
		var before := _snapshot()
		document = candidate
		_record("Edit node " + field, before)
		_refresh()
		return

func _set_capability_model(model: String) -> void:
	if not _apply():
		_update_context()
		return
	if mode != "tree" or model not in store.capability_metadata().models:
		return
	if document.dungeon.get("capability_model", "legacy") == model:
		_update_context()
		return
	var candidate := document.duplicate(true)
	candidate.dungeon.capability_model = model
	var errors: Array[String] = store.validate(candidate)
	if not errors.is_empty():
		_message("Model change rejected; source unchanged: " + "; ".join(errors))
		_update_context()
		return
	var before := _snapshot()
	document = candidate
	_record("Change capability model", before)
	_refresh()

func _edit_contribution(id: String, contribution_id: String, entry: Variant, expected_existing: Variant = null, expected_entry: Variant = null, expected_slot: Variant = null) -> void:
	if not _apply() or mode != "tree" or selected_node != id or document.dungeon.get("capability_model", "legacy") != "unified_1":
		return
	var candidate := document.duplicate(true)
	for node in candidate.dungeon.nodes:
		if node.id != id:
			continue
		var entries: Array = node.get("contributions", []).duplicate(true)
		if expected_slot != null:
			var actual: Array = entries.filter(func(item):
				return item.get("kind", "") == expected_slot.kind and item.get(expected_slot.kind, "") == expected_slot.key and (expected_slot.kind != "stat" or item.get("op", "") == expected_slot.op))
			if actual != expected_slot.entries:
				_message("Contribution changed since selection; source unchanged.")
				if is_instance_valid(node_panel.table_feedback):
					node_panel.table_feedback.text = "Contribution changed since selection; source unchanged."
				return
		var index := -1
		for i in range(entries.size()):
			if entries[i].get("id", "") == contribution_id:
				index = i
				break
		if expected_existing != null and bool(expected_existing) != (index >= 0):
			_message("Contribution changed since selection; source unchanged.")
			if is_instance_valid(node_panel.table_feedback):
				node_panel.table_feedback.text = "Contribution changed since selection; source unchanged."
			return
		if index >= 0 and expected_entry != null and entries[index] != expected_entry:
			_message("Contribution changed since selection; source unchanged.")
			if is_instance_valid(node_panel.table_feedback):
				node_panel.table_feedback.text = "Contribution changed since selection; source unchanged."
			return
		if entry == null:
			if index < 0:
				return
			entries.remove_at(index)
		else:
			if not entry is Dictionary or entry.get("id", "") != contribution_id:
				return
			if index < 0:
				entries.append(entry.duplicate(true))
			else:
				var existing: Dictionary = entries[index]
				if entry.get("kind") != existing.get("kind") or entry.get(existing.get("kind", "")) != existing.get(existing.get("kind", "")):
					_message("Contribution type changed since selection; source unchanged.")
					return
				if existing.get("kind") == "stat":
					existing.op = entry.get("op")
					existing.value = entry.get("value")
		node.contributions = entries
		var errors: Array[String] = store.validate(candidate)
		if not errors.is_empty():
			_message("Contribution %s rejected; source unchanged: %s" % [contribution_id, "; ".join(errors)])
			if is_instance_valid(node_panel.table_feedback):
				node_panel.table_feedback.text = "Contribution %s: %s" % [contribution_id, "; ".join(errors)]
			return
		var before := _snapshot()
		document = candidate
		_record("Edit contribution " + contribution_id, before)
		_refresh()
		return

func _edit_node_template(id: String) -> void:
	if not _apply():
		return
	for node in document.dungeon.nodes:
		if node.id == id:
			for index in range(document.rooms.size()):
				if document.rooms[index].id == node.template:
					return_node = id
					room_index = index
					mode = "room"
					_refresh()
					_message("Editing shared template " + node.template + ". Back to node returns to your tree selection and view.")
					return

func _return_to_node() -> void:
	if not _apply():
		return
	if document.dungeon.nodes.any(func(node): return node.id == return_node):
		mode = "tree"
		_set_selection("node", return_node)
	return_node = ""
	_refresh()

func _duplicate_node_template(id: String) -> void:
	if not _apply():
		return
	var candidate := document.duplicate(true)
	for node in candidate.dungeon.nodes:
		if node.id != id:
			continue
		for room in candidate.rooms:
			if room.id != node.template:
				continue
			var copy: Dictionary = room.duplicate(true)
			copy.id = _unique(room.id + "_copy_", candidate.rooms)
			copy.name += " copy"
			candidate.rooms.append(copy)
			node.template = copy.id
			var errors: Array[String] = store.validate(candidate)
			if not errors.is_empty():
				_message("Duplicate rejected: " + "; ".join(errors))
				return
			var before := _snapshot()
			document = candidate
			_record("Duplicate template and assign", before)
			_refresh()
			_message("Created " + copy.id + " for " + id + ". Other nodes keep their existing template; object IDs and bindings are preserved.")
			return

func _begin_inline_door() -> void:
	if not _apply():
		node_panel.canvas.cancel_gesture()
		return
	inline_door_before = _snapshot()

func _end_inline_door() -> void:
	if not inline_door_before.is_empty():
		_record("Move instance door", inline_door_before)
		inline_door_before = {}
		_refresh()

func _move_inline_door(id: String, door_id: String, point: Vector2) -> void:
	if not _apply() or mode != "tree" or selected_node != id:
		return
	var standalone := inline_door_before.is_empty()
	if standalone:
		inline_door_before = _snapshot()
	for link in document.dungeon.links:
		for end in ["a", "b"]:
			if link[end] == id and door_id == link.id + "_" + end:
				var placement: Dictionary = link.get(end + "_door", {}).duplicate(true)
				placement.erase("legacy_position")
				placement.merge(DOOR_LAYOUT.placement(point), true)
				link[end + "_door"] = placement
	_refresh()
	if standalone:
		_end_inline_door()

func _snapshot() -> Dictionary:
	return {"document": document.duplicate(true), "mode": mode, "room_index": room_index,
		"selected_node": selected_node, "selected_link": selected_link, "room_selections": room_selections.duplicate()}

func _record(label: String, before: Dictionary) -> void:
	history.record(label, before, _snapshot())
	dirty = document != saved_document
	_update_actions()

func _restore(state: Dictionary) -> void:
	if state.is_empty():
		return
	document = state.document
	mode = state.mode
	room_index = state.room_index
	selected_node = state.selected_node
	selected_link = state.selected_link
	room_selections = state.room_selections
	_refresh()
	if is_instance_valid(active_door_editor):
		if document.dungeon.nodes.any(func(node): return node.id == active_door_editor.node_id):
			active_door_editor.document = document
			active_door_editor.refresh()
		else:
			active_door_editor.queue_free()
			active_door_editor = null

func _undo() -> void:
	if not _apply():
		return
	preview.finish_gesture()
	node_panel.canvas.finish_gesture()
	if is_instance_valid(active_door_editor):
		active_door_editor.finish_edit()
	_restore(history.undo())

func _redo() -> void:
	if not _apply():
		return
	preview.finish_gesture()
	node_panel.canvas.finish_gesture()
	if is_instance_valid(active_door_editor):
		active_door_editor.finish_edit()
	_restore(history.redo())

func _begin_gesture() -> void:
	if not _apply():
		preview.cancel_gesture()
		return
	gesture_before = _snapshot()

func _end_gesture() -> void:
	if gesture_before.is_empty():
		return
	_record("Move " + preview.selection, gesture_before)
	gesture_before = {}
	_refresh()

func _selection() -> Dictionary:
	if mode == "tree":
		if not selected_node.is_empty():
			return {"kind": "node", "id": selected_node}
		if not selected_link.is_empty():
			return {"kind": "link", "id": selected_link}
	elif mode == "room" and not document.rooms.is_empty():
		var id: String = room_selections.get(document.rooms[room_index].id, "")
		if not id.is_empty():
			return {"kind": "object", "id": id}
	return {"kind": "", "id": ""}

func _selection_items(kind: String) -> Array:
	match kind:
		"node": return document.dungeon.nodes
		"link": return document.dungeon.links
		"object": return document.rooms[room_index].objects
	return []

func _sync_selection() -> void:
	var current := _selection()
	if not current.id.is_empty() and not _selection_items(current.kind).any(func(item): return item.id == current.id):
		_set_selection("", "")
		current = _selection()
	preview.selection = current.id
	preview.selection_kind = current.kind
	preview.queue_redraw()
	selection_label.text = "Selected %s: %s" % [current.kind, current.id] if not current.id.is_empty() else "No selection — Alt-click to select behind overlapping elements"

func _set_selection(kind: String, id: String) -> void:
	if mode == "tree":
		selected_node = id if kind == "node" else ""
		selected_link = id if kind == "link" else ""
	elif mode == "room" and not document.rooms.is_empty():
		room_selections[document.rooms[room_index].id] = id

func _select_element(kind: String, id: String) -> void:
	if not _apply():
		_sync_selection()
		preview.cancel_gesture()
		return
	_set_selection(kind, id)
	_refresh()

func _deselect() -> void:
	if not _apply():
		return
	_set_selection("", "")
	_refresh()

func _update_actions() -> void:
	if undo_button == null:
		return
	undo_button.disabled = history.undo_stack.is_empty()
	redo_button.disabled = history.redo_stack.is_empty()
	undo_button.tooltip_text = "Undo " + str(history.undo_stack.back().label) if not history.undo_stack.is_empty() else "Nothing to undo"
	redo_button.tooltip_text = "Redo " + str(history.redo_stack.back().label) if not history.redo_stack.is_empty() else "Nothing to redo"
	var current := _selection()
	duplicate_button.disabled = current.kind not in ["node", "object"]
	delete_button.disabled = current.id.is_empty()
	door_button.disabled = mode != "tree" or selected_node.is_empty()

func _duplicate_selection() -> void:
	if not _apply():
		return
	var current := _selection()
	if current.kind not in ["node", "object"]:
		return
	for item in _selection_items(current.kind):
		if item.id != current.id:
			continue
		var before := _snapshot()
		var copy: Dictionary = item.duplicate(true)
		copy.id = _unique(item.id + "_copy_", _selection_items(current.kind))
		var field := "map_position" if current.kind == "node" else "position"
		copy[field] = [item[field][0] + 30, item[field][1] + 30]
		if current.kind == "node":
			copy.name += " copy"
		_selection_items(current.kind).append(copy)
		_set_selection(current.kind, copy.id)
		_record("Duplicate " + current.id, before)
		_refresh()
		_message("Duplicated " + current.id + (" with the same template and prerequisites; links and bindings are not copied." if current.kind == "node" else "."))
		return

func _delete_selection() -> void:
	if not _apply():
		return
	var current := _selection()
	if current.id.is_empty():
		return
	if current.kind == "node" and current.id == document.dungeon.root:
		_message("The starting node cannot be deleted. Choose another starting node in Bundle JSON first.")
		return
	var candidate := document.duplicate(true)
	match current.kind:
		"node":
			candidate.dungeon.nodes = candidate.dungeon.nodes.filter(func(item): return item.id != current.id)
			candidate.dungeon.links = candidate.dungeon.links.filter(func(item): return item.a != current.id and item.b != current.id)
		"link":
			candidate.dungeon.links = candidate.dungeon.links.filter(func(item): return item.id != current.id)
		"object":
			candidate.rooms[room_index].objects = candidate.rooms[room_index].objects.filter(func(item): return item.id != current.id)
	var errors: Array[String] = store.validate(candidate)
	if not errors.is_empty():
		_message("Delete blocked: remove references or clear rules first. " + "; ".join(errors))
		return
	var before := _snapshot()
	document = candidate
	_set_selection("", "")
	_record("Delete " + current.id, before)
	_refresh()
	_message("Deleted " + current.id + (" and its incident travel links." if current.kind == "node" else ".") + " Undo restores the edit.")

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused is TextEdit or focused is LineEdit:
		return
	if event.ctrl_pressed or event.meta_pressed:
		match event.keycode:
			KEY_Z:
				if event.shift_pressed: _redo()
				else: _undo()
			KEY_Y: _redo()
			KEY_D: _duplicate_selection()
			KEY_S: _save()
			_: return
	else:
		match event.keycode:
			KEY_DELETE: _delete_selection()
			KEY_ESCAPE:
				_deselect()
				brush.select(0)
				preview.brush = "select"
			KEY_F: preview.fit_content()
			_: return
	get_viewport().set_input_as_handled()

func _reset_history() -> void:
	history.clear()
	saved_document = document.duplicate(true)
	gesture_before = {}
	selected_node = ""
	selected_link = ""
	room_selections.clear()
	return_node = ""
	inline_door_before = {}
	views.clear()
	view_key = ""

func _set_mode(next: String) -> void:
	if _apply():
		mode = next
		_refresh()

func _select_room(index: int) -> void:
	if _apply():
		room_index = index
		mode = "room"
		_refresh()
	else:
		picker.select(room_index)

func _new_project() -> void:
	_confirm_discard(func():
		document = store.migrate(store.new_project())
		path = ""
		dirty = false
		room_index = 0
		_reset_history()
		_refresh())

func _confirm_discard(action: Callable) -> void:
	if not dirty and inspector.text == inspector_original:
		action.call()
		return
	var confirmation := ConfirmationDialog.new()
	confirmation.dialog_text = "Replace the unsaved editor document? Save first to keep these changes."
	confirmation.confirmed.connect(func():
		action.call()
		confirmation.queue_free())
	confirmation.canceled.connect(confirmation.queue_free)
	add_child(confirmation)
	confirmation.popup_centered()

func _unique(prefix: String, items: Array) -> String:
	var ids: Array = []
	for item in items:
		ids.append(item.id)
	var n := 1
	while (prefix + str(n)) in ids:
		n += 1
	return prefix + str(n)

func _add_room() -> void:
	if not _apply(): return
	var before := _snapshot()
	var room: Dictionary = store.new_room(_unique("room_", document.rooms))
	room.erase("ports")
	document.rooms.append(room)
	room_index = document.rooms.size() - 1
	mode = "room"
	_record("Add room", before)
	_refresh()

func _add_node() -> void:
	if not _apply() or document.rooms.is_empty(): return
	var before := _snapshot()
	var node: Dictionary = store.new_node(_unique("node_", document.dungeon.nodes), document.rooms[room_index].id)
	node.map_position = [100 + 30 * (document.dungeon.nodes.size() % 15), 100]
	document.dungeon.nodes.append(node)
	mode = "tree"
	_set_selection("node", node.id)
	_record("Add node", before)
	_refresh()
	_message("New node uses the selected room template. Edit its name, cost, abilities, modifiers and prerequisites in the tree JSON.")

func _add_link() -> void:
	if not _apply(): return
	# A small form is preferable to guessing endpoints or silently reusing ports.
	var window := ConfirmationDialog.new()
	window.title = "Connect two nodes"
	var fields := VBoxContainer.new()
	var inputs: Array[LineEdit] = []
	for placeholder in ["Source node ID", "Destination node ID"]:
		var input := LineEdit.new()
		input.placeholder_text = placeholder
		input.custom_minimum_size.x = 360
		fields.add_child(input)
		inputs.append(input)
	window.add_child(fields)
	window.confirmed.connect(func():
		var candidate := document.duplicate(true)
		candidate.dungeon.links.append({"id": _unique("link_", candidate.dungeon.links), "a": inputs[0].text, "b": inputs[1].text, "activate_from": [inputs[0].text, inputs[1].text]})
		var errors: Array[String] = store.validate(candidate)
		if errors.is_empty():
			var before := _snapshot()
			document = candidate
			mode = "tree"
			_set_selection("link", candidate.dungeon.links.back().id)
			_record("Add link", before)
			_refresh()
		else:
			_message("Link rejected: " + "; ".join(errors))
		window.queue_free())
	window.canceled.connect(window.queue_free)
	add_child(window)
	window.popup_centered(Vector2i(400, 200))

func _edit_doors() -> void:
	if not _apply():
		return
	if mode != "tree" or not document.dungeon.nodes.any(func(node): return node.id == selected_node):
		_message("Select a tree node, then choose Instance doors.")
		return
	var window = DOOR_EDITOR.new()
	add_child(window)
	active_door_editor = window
	window.setup(document, selected_node)
	window.edit_started.connect(func(): door_before = _snapshot())
	window.edit_finished.connect(func():
		if not door_before.is_empty():
			_record("Edit instance door", door_before)
			door_before = {}
			_refresh())
	window.changed.connect(_refresh)
	window.undo_requested.connect(_undo)
	window.redo_requested.connect(_redo)
	window.confirmed.connect(func():
		window.finish_edit()
		window.queue_free())
	window.canceled.connect(func():
		window.finish_edit()
		window.queue_free())
	window.popup_centered(Vector2i(940, 550))

func _place(point: Vector2) -> void:
	if not _apply() or mode != "room": return
	var before := _snapshot()
	var kind: String = preview.brush
	var objects: Array = document.rooms[room_index].objects
	var object := {"id": _unique(kind + "_", objects), "kind": kind, "position": [point.x, point.y], "properties": {}}
	if kind in ["obstacle", "water", "wall"]:
		object.size = [80, 80]
	if kind in ["pickup", "chest"]:
		object.properties = {"kind": "gold", "value": 1}
	if kind == "enemy":
		object.properties = {"hp": 2, "speed": 95}
	objects.append(object)
	_set_selection("object", object.id)
	_record("Place " + kind, before)
	_refresh()

func _edit_clear() -> void:
	if not _apply() or document.rooms.is_empty(): return
	var index := room_index
	var room: Dictionary = document.rooms[index]
	var rule: Dictionary = room.get("clear", {})
	var window := ConfirmationDialog.new()
	window.title = "Clear rules — " + room.id
	window.dialog_hide_on_ok = false
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 400)
	var fields := VBoxContainer.new()
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(fields)
	window.add_child(scroll)
	var help := Label.new()
	help.text = "ALL checked conditions are required.\nNo conditions = cleared immediately; effects apply at run start.\nTokens reset on exit while uncleared; cleared rooms have none.\nSwitch hits persist for the run.\nRoot effects waive cost/support and keep the node active."
	fields.add_child(help)
	var editing_lock := CheckBox.new()
	editing_lock.text = "Disable tree editing while inside this uncleared room"
	editing_lock.button_pressed = rule.get("block_tree_editing_until_cleared", false)
	fields.add_child(editing_lock)
	var choices: Array = []
	_clear_choice(fields, choices, rule, "conditions", {"kind": "all_enemies_defeated"}, "Defeat all enemies", room.objects.any(func(item): return item.kind == "enemy"))
	_clear_choice(fields, choices, rule, "conditions", {"kind": "all_tokens_collected"}, "Collect all tokens in one visit", room.objects.any(func(item): return item.kind == "token"))
	for object in room.objects:
		if object.kind == "switch":
			_clear_choice(fields, choices, rule, "conditions", {"kind": "switch_hit", "object": object.id}, "Hit switch: " + object.id)
	var label := Label.new()
	label.text = "\nEffects (all checked effects apply):"
	fields.add_child(label)
	for object in room.objects:
		if object.kind in ["pickup", "chest"]:
			_clear_choice(fields, choices, rule, "effects", {"kind": "reveal_pickup", "object": object.id}, "Reveal collectible: " + object.id)
	_clear_choice(fields, choices, rule, "effects", {"kind": "prevent_enemy_respawn"}, "Enemies never respawn after clearing")
	_clear_choice(fields, choices, rule, "effects", {"kind": "become_root"}, "Become a permanent root")
	window.confirmed.connect(func():
		var next: Dictionary = rule.duplicate(true)
		next.block_tree_editing_until_cleared = editing_lock.button_pressed
		for field in ["conditions", "effects"]:
			var entries: Array = next.get(field, []).duplicate(true)
			for choice in choices:
				if choice.field != field: continue
				var matching := -1
				for i in range(entries.size()):
					if entries[i].kind == choice.entry.kind and entries[i].get("object", "") == choice.entry.get("object", ""):
						matching = i
						break
				if choice.check.button_pressed and matching == -1:
					entries.append(choice.entry)
				elif not choice.check.button_pressed and matching != -1:
					entries.remove_at(matching)
			next[field] = entries
		if set_clear_rule(index, next):
			window.queue_free())
	window.canceled.connect(window.queue_free)
	add_child(window)
	window.popup_centered(Vector2i(540, 450))

func _clear_choice(parent: Node, choices: Array, rule: Dictionary, field: String, entry: Dictionary, text: String, enabled: bool = true) -> void:
	var check := CheckBox.new()
	check.text = text
	check.button_pressed = rule.get(field, []).any(func(item): return item.kind == entry.kind and item.get("object", "") == entry.get("object", ""))
	check.disabled = not enabled
	if not enabled:
		check.tooltip_text = "Place matching objects in the room first."
	parent.add_child(check)
	choices.append({"field": field, "entry": entry, "check": check})

func set_clear_rule(index: int, rule: Dictionary) -> bool:
	if not _apply(): return false
	var candidate := document.duplicate(true)
	candidate.rooms[index].clear = rule.duplicate(true)
	var errors: Array[String] = store.validate(candidate)
	if not errors.is_empty():
		_message("Clear rules rejected: " + "; ".join(errors))
		return false
	var before := _snapshot()
	document = candidate
	mode = "room"
	room_index = index
	_record("Clear rules", before)
	_refresh()
	_message("Clear rules applied. Validate or Playtest checks runtime compatibility.")
	return true

func _move(id: String, point: Vector2) -> void:
	if not _apply(): return
	var before := _snapshot() if gesture_before.is_empty() else {}
	var items: Array = document.dungeon.nodes if mode != "room" else document.rooms[room_index].objects
	for item in items:
		if item.id == id:
			var field := "map_position" if mode != "room" else "position"
			if Vector2(item[field][0], item[field][1]) == point:
				return
			item[field] = [point.x, point.y]
	if not before.is_empty():
		_record("Move " + id, before)
	_refresh()

func _file(action: String) -> void:
	if action != "open" and not _apply(): return
	file_action = action
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE if action in ["open", "import"] else FileDialog.FILE_MODE_SAVE_FILE
	dialog.current_dir = ProjectSettings.globalize_path("res://examples") if path == "" else path.get_base_dir()
	dialog.current_file = "room.json" if action == "export" else "scenario.json"
	dialog.popup_centered(Vector2i(950, 620))

func _file_selected(selected: String) -> void:
	match file_action:
		"open":
			var result: Dictionary = store.load_document(selected)
			if not result.ok:
				_message("Open rejected: " + "; ".join(result.errors))
				return
			_confirm_discard(func():
				document = store.migrate(result.document)
				path = selected
				dirty = false
				room_index = 0
				_reset_history()
				_refresh())
		"save": _save_to(selected)
		"export":
			var result: Dictionary = store.write_json(selected, {"format": "room-template", "version": 2, "room": document.rooms[room_index]})
			_message("Room exported." if result.ok else "; ".join(result.errors))
		"import":
			var json := JSON.new()
			if json.parse(FileAccess.get_file_as_string(selected)) != OK or not json.data is Dictionary or json.data.get("format") != "room-template" or (json.data.get("version") != 1 and json.data.get("version") != 2):
				_message("Expected room-template JSON version 1 or 2.")
				return
			var candidate := document.duplicate(true)
			candidate.rooms.append(json.data.get("room"))
			var errors: Array[String] = store.validate(candidate)
			if not errors.is_empty():
				_message("Import rejected: " + "; ".join(errors))
				return
			var before := _snapshot()
			document = candidate
			room_index = document.rooms.size() - 1
			mode = "room"
			_record("Import room", before)
			_refresh()

func _save() -> void:
	if not _apply(): return
	if path == "": _file("save")
	else: _save_to(path)

func _save_to(selected: String) -> void:
	var result: Dictionary = store.save_document(selected, document)
	if result.ok:
		path = selected
		saved_document = document.duplicate(true)
		dirty = false
		_refresh()
	_message("Saved " + selected if result.ok else "; ".join(result.errors))

func _validate() -> void:
	if not _apply(): return
	var result: Dictionary = ADAPTER.new().compile(document)
	_message("Valid portable content; all mechanics supported for playtest." if result.ok else "Saved format is valid. Playtest blockers: " + "; ".join(result.errors))

func _play() -> void:
	if not _apply(): return
	var result: Dictionary = ADAPTER.new().compile(document)
	if result.ok:
		play_requested.emit(result.data)
	else:
		_message("Cannot playtest: " + "; ".join(result.errors))

func _message(text: String) -> void:
	feedback.text = text
	feedback.tooltip_text = text
