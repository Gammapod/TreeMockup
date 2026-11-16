extends AcceptDialog

signal changed
signal edit_started
signal edit_finished
signal undo_requested
signal redo_requested
const LAYOUT = preload("res://authoring/door_layout.gd")
const PREVIEW = preload("res://authoring/preview.gd")
var document: Dictionary
var node_id := ""
var canvas
var endpoints: OptionButton
var walls: OptionButton
var offset: SpinBox
var status: Label
var resolved: Array = []
var updating := false
var editing := false

func setup(source: Dictionary, selected_node: String) -> void:
	document = source
	node_id = selected_node
	title = "Instance doors — " + node_id
	var row := HBoxContainer.new()
	add_child(row)
	canvas = PREVIEW.new()
	canvas.custom_minimum_size = Vector2(640, 480)
	canvas.zoom = 0.8
	canvas.instance_view = true
	canvas.door_moved.connect(_drag)
	canvas.gesture_started.connect(begin_edit)
	canvas.gesture_finished.connect(finish_edit)
	row.add_child(canvas)
	var panel := VBoxContainer.new()
	panel.custom_minimum_size.x = 260
	row.add_child(panel)
	var hint := Label.new()
	hint.text = "Drag a door to any wall.\nGreen: automatic • Yellow: manual"
	panel.add_child(hint)
	endpoints = OptionButton.new()
	endpoints.item_selected.connect(func(_i): _fields())
	panel.add_child(endpoints)
	walls = OptionButton.new()
	for wall in LAYOUT.SIDES:
		walls.add_item(wall.capitalize())
	walls.item_selected.connect(func(_i): _manual())
	panel.add_child(walls)
	var label := Label.new()
	label.text = "Position along wall (%)"
	panel.add_child(label)
	offset = SpinBox.new()
	offset.max_value = 100
	offset.step = 1
	offset.value_changed.connect(func(_value): _manual())
	panel.add_child(offset)
	var reset := Button.new()
	reset.text = "Reset to automatic"
	reset.pressed.connect(_reset)
	panel.add_child(reset)
	var history_row := HBoxContainer.new()
	panel.add_child(history_row)
	for action in ["Undo", "Redo"]:
		var button := Button.new()
		button.text = action
		button.pressed.connect(func():
			finish_edit()
			if action == "Undo": undo_requested.emit()
			else: redo_requested.emit())
		history_row.add_child(button)
	status = Label.new()
	status.custom_minimum_size.x = 260
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(status)
	refresh()

func refresh() -> void:
	var layout := LAYOUT.resolve(document)
	resolved = layout.nodes.get(node_id, [])
	for node in document.dungeon.nodes:
		if node.id == node_id:
			for room in document.rooms:
				if room.id == node.template:
					canvas.content = room.duplicate(true)
					canvas.content.erase("ports")
	canvas.instance_doors = resolved
	canvas.queue_redraw()
	var index := maxi(endpoints.selected, 0)
	endpoints.clear()
	for door in resolved:
		endpoints.add_item(door.link + " → " + door.neighbor)
	if not resolved.is_empty():
		endpoints.select(mini(index, resolved.size() - 1))
	_fields()
	var diagnostics: Array = (layout.errors + layout.warnings).filter(func(message): return message.begins_with(node_id + ":") or message.begins_with(node_id + " /"))
	status.text = "\n".join(diagnostics)
	if status.text.is_empty():
		status.text = "Automatic doors follow graph layout.\nManual doors stay fixed until reset."

func _fields() -> void:
	updating = true
	walls.disabled = resolved.is_empty()
	offset.editable = not resolved.is_empty()
	if not resolved.is_empty():
		var door: Dictionary = resolved[endpoints.selected]
		walls.select(LAYOUT.SIDES.find(door.wall))
		offset.value = door.offset * 100
	updating = false

func _write(door: Dictionary, value: Dictionary) -> void:
	var single_edit := not editing
	if single_edit:
		begin_edit()
	for link in document.dungeon.links:
		if link.id == door.link:
			if value.is_empty():
				link.erase(door.end + "_door")
			else:
				link[door.end + "_door"] = value
	changed.emit()
	refresh()
	if single_edit:
		finish_edit()

func begin_edit() -> void:
	if not editing:
		editing = true
		edit_started.emit()

func finish_edit() -> void:
	if editing:
		editing = false
		edit_finished.emit()

func _manual() -> void:
	if updating or resolved.is_empty():
		return
	_write(resolved[endpoints.selected], {"wall": LAYOUT.SIDES[walls.selected], "offset": offset.value / 100})

func _reset() -> void:
	if not resolved.is_empty():
		_write(resolved[endpoints.selected], {})

func _drag(id: String, point: Vector2) -> void:
	for i in range(resolved.size()):
		if resolved[i].id == id:
			endpoints.select(i)
			_write(resolved[i], LAYOUT.placement(point))
			return
