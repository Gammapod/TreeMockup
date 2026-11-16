extends ScrollContainer

signal object_requested(room_id: String, object_id: String, patch: Dictionary)
signal template_requested(room_id: String, patch: Dictionary)
signal clear_rules_requested(room_id: String)
signal bindings_requested(focus: Dictionary)

var room_id := ""
var room: Dictionary = {}
var object_id := ""
var object: Dictionary = {}
var updating := false
var heading: Label
var object_form: VBoxContainer
var template_form: VBoxContainer
var id_input: LineEdit
var position_x: SpinBox
var position_y: SpinBox
var width: SpinBox
var height: SpinBox
var rectangle_box: VBoxContainer
var enemy_box: VBoxContainer
var enemy_hp: SpinBox
var enemy_speed: SpinBox
var enemy_radius: SpinBox
var pickup_box: VBoxContainer
var pickup_kind: OptionButton
var pickup_value: SpinBox
var properties_label: Label
var room_name: LineEdit
var dimensions: Label
var usage: Label
var id_focus := ""
var room_name_focus := ""
var binding_box: VBoxContainer
var binding_summary: Label

func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(column)
	heading = _label(column, "Select a room object or empty canvas.")
	object_form = VBoxContainer.new()
	column.add_child(object_form)
	_label(object_form, "Object ID")
	id_input = LineEdit.new()
	object_form.add_child(id_input)
	id_input.focus_entered.connect(func(): id_focus = object_id)
	id_input.text_submitted.connect(func(_text): _commit_id())
	id_input.focus_exited.connect(_commit_id)
	var position := VBoxContainer.new()
	object_form.add_child(position)
	_label(position, "Position")
	var position_row := HBoxContainer.new()
	position.add_child(position_row)
	position_x = _number(position_row, "X")
	position_y = _number(position_row, "Y")
	position_x.value_changed.connect(func(value): _patch({"position": [value, position_y.value]}))
	position_y.value_changed.connect(func(value): _patch({"position": [position_x.value, value]}))
	rectangle_box = VBoxContainer.new()
	object_form.add_child(rectangle_box)
	_label(rectangle_box, "Rectangle bounds — drag white edges/corners on canvas")
	var dimensions_row := HBoxContainer.new()
	rectangle_box.add_child(dimensions_row)
	width = _number(dimensions_row, "Width")
	height = _number(dimensions_row, "Height")
	width.min_value = 1
	height.min_value = 1
	width.value_changed.connect(func(value): _patch({"size": [value, height.value]}))
	height.value_changed.connect(func(value): _patch({"size": [width.value, value]}))
	enemy_box = VBoxContainer.new()
	object_form.add_child(enemy_box)
	_label(enemy_box, "Enemy stats")
	var enemy_row := HBoxContainer.new()
	enemy_box.add_child(enemy_row)
	enemy_hp = _number(enemy_row, "HP")
	enemy_hp.min_value = 1
	enemy_hp.step = 1
	enemy_speed = _number(enemy_row, "Speed")
	enemy_speed.min_value = 0
	enemy_radius = _number(enemy_row, "Radius")
	enemy_radius.min_value = 0.001
	enemy_radius.step = 0.001
	enemy_hp.value_changed.connect(func(value): _property("hp", int(value)))
	enemy_speed.value_changed.connect(func(value): _property("speed", value))
	enemy_radius.value_changed.connect(func(value): _property("radius", value))
	pickup_box = VBoxContainer.new()
	object_form.add_child(pickup_box)
	_label(pickup_box, "Collectible reward")
	var pickup_row := HBoxContainer.new()
	pickup_box.add_child(pickup_row)
	pickup_kind = OptionButton.new()
	pickup_kind.add_item("Gold")
	pickup_kind.add_item("Capacity")
	pickup_kind.item_selected.connect(func(index): _property("kind", "gold" if index == 0 else "capacity"))
	pickup_row.add_child(pickup_kind)
	pickup_value = _number(pickup_row, "Value")
	pickup_value.min_value = 1
	pickup_value.step = 1
	pickup_value.value_changed.connect(func(value): _property("value", int(value)))
	properties_label = _label(object_form, "")
	binding_box = VBoxContainer.new()
	object_form.add_child(binding_box)
	binding_summary = _label(binding_box, "")
	var bindings := Button.new()
	bindings.text = "Edit switch/wall bindings…"
	bindings.pressed.connect(func():
		bindings_requested.emit({"source_node": room_id, "source_object": object_id} if object.get("kind") == "switch" else {"target_node": room_id, "target_object": object_id}))
	binding_box.add_child(bindings)
	template_form = VBoxContainer.new()
	column.add_child(template_form)
	_label(template_form, "Template properties")
	_label(template_form, "Name")
	room_name = LineEdit.new()
	template_form.add_child(room_name)
	room_name.focus_entered.connect(func(): room_name_focus = room_id)
	room_name.text_submitted.connect(func(_text): _commit_room_name())
	room_name.focus_exited.connect(_commit_room_name)
	dimensions = _label(template_form, "Dimensions: 800 × 600")
	dimensions.tooltip_text = "Playable V2 rooms currently require 800 × 600. Resizing is deferred."
	var rules := Button.new()
	rules.text = "Clear rules…"
	rules.pressed.connect(func(): clear_rules_requested.emit(room_id))
	template_form.add_child(rules)
	usage = _label(template_form, "")
	object_form.hide()
	template_form.hide()

func _label(parent: Node, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _number(parent: Node, title: String) -> SpinBox:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	_label(box, title)
	var number := SpinBox.new()
	number.min_value = -1000000
	number.max_value = 1000000
	number.allow_greater = true
	number.allow_lesser = true
	number.step = 1
	box.add_child(number)
	return number

func _commit_id() -> void:
	if not updating and id_focus == object_id and id_input.text != object.get("id", ""):
		_patch({"id": id_input.text})

func _commit_room_name() -> void:
	if not updating and room_name_focus == room_id and room_name.text != room.get("name", ""):
		template_requested.emit(room_id, {"name": room_name.text})

func _patch(values: Dictionary) -> void:
	if not updating and not object_id.is_empty():
		object_requested.emit(room_id, object_id, values)

func _property(key: String, value: Variant) -> void:
	if updating:
		return
	var values: Dictionary = object.get("properties", {}).duplicate(true)
	values[key] = value
	_patch({"properties": values})

func configure(document: Dictionary, selected_room: String, selected_object: String) -> void:
	updating = true
	var changed_room := room_id != selected_room
	var changed_object := object_id != selected_object
	room_id = selected_room
	object_id = selected_object
	room = {}
	object = {}
	for candidate in document.rooms:
		if candidate.id == room_id:
			room = candidate.duplicate(true)
			break
	for candidate in room.get("objects", []):
		if candidate.id == object_id:
			object = candidate.duplicate(true)
			break
	template_form.visible = not room.is_empty()
	object_form.visible = not object.is_empty()
	if room.is_empty():
		heading.text = "Select a room template."
		updating = false
		return
	if changed_room:
		scroll_vertical = 0
	heading.text = "Object: " + object_id if not object.is_empty() else "Template: " + room.id
	if changed_room or not room_name.has_focus():
		room_name.text = room.name
	dimensions.text = "Dimensions: %s × %s (fixed for playtest)" % [room.size[0], room.size[1]]
	var count: int = document.dungeon.nodes.filter(func(node): return node.template == room_id).size()
	usage.text = "Used by %d node(s). Changes affect every instance." % count
	if object.is_empty():
		updating = false
		return
	if changed_object or not id_input.has_focus():
		id_input.text = object.id
	_set_number(position_x, object.position[0])
	_set_number(position_y, object.position[1])
	var rectangular: bool = object.has("size") and object.size is Array and object.size.size() == 2
	rectangle_box.visible = rectangular
	if rectangular:
		_set_number(width, object.size[0])
		_set_number(height, object.size[1])
	enemy_box.visible = object.kind == "enemy"
	if object.kind == "enemy":
		_set_number(enemy_hp, object.properties.get("hp", 2))
		_set_number(enemy_speed, object.properties.get("speed", 95))
		_set_number(enemy_radius, object.properties.get("radius", 14))
	pickup_box.visible = object.kind in ["pickup", "chest"]
	if object.kind in ["pickup", "chest"]:
		pickup_kind.select(1 if object.properties.get("kind", "gold") == "capacity" else 0)
		_set_number(pickup_value, object.properties.get("value", 1))
	var extra: Array[String] = []
	for key in object.properties:
		if key not in ["hp", "speed", "radius", "kind", "value"]:
			extra.append(key + ": " + str(object.properties[key]))
	properties_label.text = "Other properties preserved in JSON: " + ", ".join(extra) if not extra.is_empty() else ""
	binding_box.visible = object.kind in ["switch", "wall"]
	if binding_box.visible:
		var found: Array[String] = []
		for binding in document.dungeon.interactions:
			if object.kind == "switch" and binding.source.object == object_id and _node_uses(document, binding.source.node, room_id):
				found.append("%s opens: %s.%s" % [binding.source.node, binding.target.node, binding.target.object])
			elif object.kind == "wall" and binding.target.object == object_id and _node_uses(document, binding.target.node, room_id):
				found.append("%s opened by: %s.%s" % [binding.target.node, binding.source.node, binding.source.object])
		binding_summary.text = "\n".join(found) if not found.is_empty() else "No switch/wall bindings."
	updating = false

func _set_number(control: SpinBox, value: Variant) -> void:
	if value is int or value is float:
		if control.value != float(value):
			control.set_value_no_signal(value)

func _node_uses(document: Dictionary, node_id: String, template_id: String) -> bool:
	for node in document.dungeon.nodes:
		if node.id == node_id:
			return node.template == template_id
	return false
