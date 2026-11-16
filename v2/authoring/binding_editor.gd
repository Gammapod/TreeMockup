extends AcceptDialog

signal binding_added(binding: Dictionary)
signal binding_removed(id: String)

var document: Dictionary
var preferred: Dictionary = {}
var source_node: OptionButton
var source_object: OptionButton
var target_node: OptionButton
var target_object: OptionButton
var existing: VBoxContainer
var feedback: Label

func setup(source: Dictionary, focus: Dictionary = {}) -> void:
	document = source
	preferred = focus
	title = "Switch → wall bindings"
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(540, 430)
	add_child(root)
	var help := Label.new()
	help.text = "A switch toggle sets a wall open/closed, even if the target room is unloaded."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(help)
	_label(root, "Source switch")
	source_node = OptionButton.new()
	source_node.item_selected.connect(func(_i): _fill_objects(source_object, source_node, "switch", preferred.get("source_object", "")))
	root.add_child(source_node)
	source_object = OptionButton.new()
	root.add_child(source_object)
	_label(root, "Target wall")
	target_node = OptionButton.new()
	target_node.item_selected.connect(func(_i): _fill_objects(target_object, target_node, "wall", preferred.get("target_object", "")))
	root.add_child(target_node)
	target_object = OptionButton.new()
	root.add_child(target_object)
	feedback = Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(feedback)
	var add := Button.new()
	add.text = "Add binding"
	add.pressed.connect(_add)
	root.add_child(add)
	_label(root, "Existing bindings")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 130
	root.add_child(scroll)
	existing = VBoxContainer.new()
	existing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(existing)
	_fill_nodes(source_node, "switch", preferred.get("source_node", ""))
	_fill_nodes(target_node, "wall", preferred.get("target_node", ""))
	_refresh_existing()

func _label(parent: Node, text: String) -> void:
	var label := Label.new()
	label.text = text
	parent.add_child(label)

func _room(node_id: String) -> Dictionary:
	for node in document.dungeon.nodes:
		if node.id == node_id:
			for room in document.rooms:
				if room.id == node.template:
					return room
	return {}

func _fill_nodes(control: OptionButton, kind: String, selected: String) -> void:
	control.clear()
	control.disabled = false
	for node in document.dungeon.nodes:
		var room := _room(node.id)
		if room.objects.any(func(object): return object.kind == kind):
			control.add_item(node.name + " [" + node.id + "]")
			control.set_item_metadata(control.item_count - 1, node.id)
			if node.id == selected:
				control.select(control.item_count - 1)
	if control.item_count > 0:
		var objects := source_object if control == source_node else target_object
		_fill_objects(objects, control, kind, preferred.get("source_object" if kind == "switch" else "target_object", ""))
	else:
		control.add_item("No instantiated " + kind + "s in tree")
		control.disabled = true
		var objects := source_object if control == source_node else target_object
		objects.clear()
		objects.add_item("Add a node using a template with a " + kind)
		objects.disabled = true
		feedback.text = "Bindings address node instances. Add nodes using templates containing both a switch and a wall."

func _fill_objects(control: OptionButton, node_control: OptionButton, kind: String, selected: String) -> void:
	control.clear()
	control.disabled = false
	if node_control.item_count == 0 or node_control.disabled:
		return
	for object in _room(node_control.get_item_metadata(node_control.selected)).objects:
		if object.kind == kind:
			control.add_item(object.id)
			control.set_item_metadata(control.item_count - 1, object.id)
			if object.id == selected:
				control.select(control.item_count - 1)

func _add() -> void:
	if source_node.disabled or source_object.disabled or target_node.disabled or target_object.disabled:
		feedback.text = "Place at least one switch and one wall in room instances first."
		return
	var binding := {"id": _unique("binding_"), "source": {"node": source_node.get_item_metadata(source_node.selected), "object": source_object.get_item_metadata(source_object.selected), "event": "toggled"}, "target": {"node": target_node.get_item_metadata(target_node.selected), "object": target_object.get_item_metadata(target_object.selected), "action": "set_open"}}
	if document.dungeon.interactions.any(func(entry): return entry.source == binding.source and entry.target == binding.target):
		feedback.text = "That binding already exists."
		return
	binding_added.emit(binding)

func _unique(prefix: String) -> String:
	var n := 1
	while document.dungeon.interactions.any(func(entry): return entry.id == prefix + str(n)):
		n += 1
	return prefix + str(n)

func _refresh_existing() -> void:
	for child in existing.get_children():
		child.queue_free()
	for binding in document.dungeon.interactions:
		var row := HBoxContainer.new()
		existing.add_child(row)
		var label := Label.new()
		label.text = "%s.%s  →  %s.%s" % [binding.source.node, binding.source.object, binding.target.node, binding.target.object]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var remove := Button.new()
		remove.text = "Remove"
		remove.pressed.connect(func(): binding_removed.emit(binding.id))
		row.add_child(remove)
