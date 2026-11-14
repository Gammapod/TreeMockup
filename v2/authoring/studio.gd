extends Control

signal play_requested(data: Dictionary)
signal close_requested

const STORE = preload("res://authoring/content_store.gd")
const ADAPTER = preload("res://authoring/runtime_adapter.gd")
const PREVIEW = preload("res://authoring/preview.gd")
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

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("101925")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var toolbar := HBoxContainer.new()
	toolbar.position = Vector2(15, 12)
	add_child(toolbar)
	_button(toolbar, "New", _new_project)
	_button(toolbar, "Open…", func(): _file("open"))
	_button(toolbar, "Save", _save)
	_button(toolbar, "Save as…", func(): _file("save"))
	_button(toolbar, "Import room…", func(): _file("import"))
	_button(toolbar, "Export room…", func(): _file("export"))
	_button(toolbar, "Validate", _validate)
	_button(toolbar, "Playtest", _play)
	_button(toolbar, "Resume run", func(): close_requested.emit())
	var tools := HBoxContainer.new()
	tools.position = Vector2(15, 53)
	add_child(tools)
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
	brush = OptionButton.new()
	for kind in ["select", "enemy", "pickup", "chest", "token", "obstacle", "water", "switch", "wall"]:
		brush.add_item(kind)
	brush.item_selected.connect(func(index): preview.brush = brush.get_item_text(index))
	tools.add_child(brush)
	_button(tools, "Clear rules…", _edit_clear)
	title = Label.new()
	title.position = Vector2(15, 92)
	add_child(title)
	preview = PREVIEW.new()
	preview.position = Vector2(15, 125)
	preview.size = Vector2(735, 540)
	preview.placed.connect(_place)
	preview.moved.connect(_move)
	add_child(preview)
	inspector = CodeEdit.new()
	inspector.position = Vector2(765, 125)
	inspector.size = Vector2(420, 540)
	inspector.gutters_draw_line_numbers = true
	add_child(inspector)
	var apply := Button.new()
	apply.text = "Apply JSON edits"
	apply.position = Vector2(980, 88)
	apply.pressed.connect(func():
		if _apply():
			_refresh()
			_message("Applied. Save writes the whole bundle; playtest starts a fresh run."))
	add_child(apply)
	feedback = Label.new()
	feedback.position = Vector2(15, 675)
	feedback.size = Vector2(1170, 75)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(feedback)
	dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json ; Portable content JSON"])
	dialog.file_selected.connect(_file_selected)
	add_child(dialog)
	var initial: Dictionary = store.load_document("res://examples/branching.json")
	document = initial.document if initial.ok else store.new_project()
	_refresh()
	_message("Choose a brush and click to place objects; drag objects/nodes to move. Edit IDs, requirements, links and bindings in JSON. Open examples/ for scenarios.")

func _button(parent: Node, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)

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
	document = candidate
	dirty = true
	inspector_original = inspector.text
	return true

func _refresh() -> void:
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
	preview.queue_redraw()
	inspector.text = JSON.stringify(value, "\t", false)
	inspector_original = inspector.text
	title.text = "%s%s — %s" % [document.name, " *" if dirty else "", path if path != "" else "unsaved bundle"]

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
		document = store.new_project()
		path = ""
		dirty = false
		room_index = 0
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
	document.rooms.append(store.new_room(_unique("room_", document.rooms)))
	room_index = document.rooms.size() - 1
	mode = "room"
	dirty = true
	_refresh()

func _add_node() -> void:
	if not _apply() or document.rooms.is_empty(): return
	var node: Dictionary = store.new_node(_unique("node_", document.dungeon.nodes), document.rooms[room_index].id)
	node.map_position = [100 + 30 * (document.dungeon.nodes.size() % 15), 100]
	document.dungeon.nodes.append(node)
	mode = "tree"
	dirty = true
	_refresh()
	_message("New node uses the selected room template. Edit its name, cost, abilities, modifiers and prerequisites in the tree JSON.")

func _add_link() -> void:
	if not _apply(): return
	# A small form is preferable to guessing endpoints or silently reusing ports.
	var window := ConfirmationDialog.new()
	window.title = "Connect two nodes"
	var fields := VBoxContainer.new()
	var inputs: Array[LineEdit] = []
	for placeholder in ["Source node ID", "Source port ID", "Destination node ID", "Destination port ID"]:
		var input := LineEdit.new()
		input.placeholder_text = placeholder
		input.custom_minimum_size.x = 360
		fields.add_child(input)
		inputs.append(input)
	window.add_child(fields)
	window.confirmed.connect(func():
		var candidate := document.duplicate(true)
		candidate.dungeon.links.append({"id": _unique("link_", candidate.dungeon.links), "a": inputs[0].text, "a_port": inputs[1].text, "b": inputs[2].text, "b_port": inputs[3].text, "activate_from": [inputs[0].text, inputs[2].text]})
		var errors: Array[String] = store.validate(candidate)
		if errors.is_empty():
			document = candidate
			dirty = true
			mode = "tree"
			_refresh()
		else:
			_message("Link rejected: " + "; ".join(errors))
		window.queue_free())
	window.canceled.connect(window.queue_free)
	add_child(window)
	window.popup_centered(Vector2i(400, 200))

func _place(point: Vector2) -> void:
	if not _apply() or mode != "room": return
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
	dirty = true
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
	document = candidate
	dirty = true
	mode = "room"
	room_index = index
	_refresh()
	_message("Clear rules applied. Validate or Playtest checks runtime compatibility.")
	return true

func _move(id: String, point: Vector2) -> void:
	if not _apply(): return
	var items: Array = document.dungeon.nodes if mode != "room" else document.rooms[room_index].objects
	for item in items:
		if item.id == id:
			item["map_position" if mode != "room" else "position"] = [point.x, point.y]
	dirty = true
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
				document = result.document
				path = selected
				dirty = false
				room_index = 0
				_refresh())
		"save": _save_to(selected)
		"export":
			var result: Dictionary = store.write_json(selected, {"format": "room-template", "version": 1, "room": document.rooms[room_index]})
			_message("Room exported." if result.ok else "; ".join(result.errors))
		"import":
			var json := JSON.new()
			if json.parse(FileAccess.get_file_as_string(selected)) != OK or not json.data is Dictionary or json.data.get("format") != "room-template" or json.data.get("version") != 1:
				_message("Expected room-template JSON version 1.")
				return
			var candidate := document.duplicate(true)
			candidate.rooms.append(json.data.get("room"))
			var errors: Array[String] = store.validate(candidate)
			if not errors.is_empty():
				_message("Import rejected: " + "; ".join(errors))
				return
			document = candidate
			room_index = document.rooms.size() - 1
			dirty = true
			mode = "room"
			_refresh()

func _save() -> void:
	if not _apply(): return
	if path == "": _file("save")
	else: _save_to(path)

func _save_to(selected: String) -> void:
	var result: Dictionary = store.save_document(selected, document)
	if result.ok:
		path = selected
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
