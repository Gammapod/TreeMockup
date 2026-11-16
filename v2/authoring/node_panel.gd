extends ScrollContainer

# Presentation owns copied source and emits edits addressed by stable node ID.
signal field_requested(node_id: String, field: String, value: Variant)
signal template_edit_requested(node_id: String)
signal template_duplicate_requested(node_id: String)
signal doors_requested
signal door_requested(node_id: String, door_id: String, point: Vector2)
signal door_gesture_started
signal door_gesture_finished

const PREVIEW = preload("res://authoring/preview.gd")
const DOORS = preload("res://authoring/door_layout.gd")
const ABILITIES := ["sword", "dash", "flippers"]
const NUMERIC := {
	"max_hp_bonus": "Max HP +", "sword_damage_bonus": "Sword damage +",
	"move_speed_multiplier": "Move speed ×", "sword_range_multiplier": "Sword reach ×",
	"sword_arc_multiplier": "Sword arc ×", "sword_damage_multiplier": "Sword damage ×",
	"sword_cooldown_multiplier": "Sword interval ×", "dash_speed_multiplier": "Dash speed ×",
	"dash_distance_multiplier": "Dash distance ×", "dash_cooldown_multiplier": "Dash recharge ×"
}
const STYLES := {"sword_style": ["big", "fast"], "dash_style": ["phase", "run"]}
var node_id := ""
var node: Dictionary = {}
var updating := false
var heading: Label
var form: VBoxContainer
var name_input: LineEdit
var cost: SpinBox
var abilities: MenuButton
var ability_ids: Array = []
var templates: OptionButton
var usage: Label
var modifiers_box: VBoxContainer
var modifier_toggle: Button
var numeric_controls: Dictionary = {}
var style_controls: Dictionary = {}
var unknown_modifiers: Label
var canvas
var summary: Label
var diagnostics: Label
var bindings: Label
var name_focus_id := ""
var preview_key := ""

func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(column)
	heading = _label(column, "Select a tree node to edit its properties.")
	form = VBoxContainer.new()
	column.add_child(form)
	_label(form, "Name")
	name_input = LineEdit.new()
	form.add_child(name_input)
	name_input.focus_entered.connect(func(): name_focus_id = node_id)
	name_input.text_submitted.connect(func(_text): _commit_name())
	name_input.focus_exited.connect(_commit_name)
	_label(form, "Capacity cost")
	cost = SpinBox.new()
	cost.max_value = 1000000
	cost.allow_greater = true
	cost.value_changed.connect(func(value): _field("cost", int(value)))
	form.add_child(cost)
	_label(form, "Abilities")
	abilities = MenuButton.new()
	abilities.clip_text = true
	abilities.text = "Choose abilities…"
	abilities.get_popup().hide_on_checkable_item_selection = false
	abilities.get_popup().id_pressed.connect(_toggle_ability)
	form.add_child(abilities)
	_label(form, "Room template")
	templates = OptionButton.new()
	templates.fit_to_longest_item = false
	templates.item_selected.connect(func(index): _field("template", templates.get_item_metadata(index)))
	form.add_child(templates)
	usage = _label(form, "")
	var actions := HFlowContainer.new()
	form.add_child(actions)
	_button(actions, "Edit template", func(): template_edit_requested.emit(node_id))
	_button(actions, "Duplicate & assign", func(): template_duplicate_requested.emit(node_id))
	_label(form, "Instance preview — drag doors; wheel to zoom")
	canvas = PREVIEW.new()
	canvas.custom_minimum_size = Vector2(240, 230)
	canvas.instance_view = true
	canvas.door_moved.connect(func(id, point): door_requested.emit(node_id, id, point))
	canvas.gesture_started.connect(func(): door_gesture_started.emit())
	canvas.gesture_finished.connect(func(): door_gesture_finished.emit())
	form.add_child(canvas)
	var door_actions := HBoxContainer.new()
	form.add_child(door_actions)
	_button(door_actions, "Door selector / reset…", func(): doors_requested.emit())
	_button(door_actions, "Fit", func(): canvas.fit_content())
	diagnostics = _label(form, "")
	modifier_toggle = _button(form, "Modifiers", func(): modifiers_box.visible = not modifiers_box.visible)
	modifiers_box = VBoxContainer.new()
	form.add_child(modifiers_box)
	modifiers_box.hide()
	_label(modifiers_box, "Enable a modifier to author it. × values multiply; lower interval/recharge is faster.")
	for key in NUMERIC:
		var row := HBoxContainer.new()
		modifiers_box.add_child(row)
		var enabled := CheckBox.new()
		enabled.text = NUMERIC[key]
		enabled.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(enabled)
		var number := SpinBox.new()
		number.custom_minimum_size.x = 100
		var multiplier: bool = key.ends_with("_multiplier")
		number.min_value = 0.001 if multiplier else 0
		number.max_value = 1000000
		number.allow_greater = true
		number.step = 0.001 if multiplier else 1
		number.value = 1 if multiplier else 0
		row.add_child(number)
		numeric_controls[key] = {"enabled": enabled, "value": number}
		enabled.toggled.connect(func(on): _modifier(key, number.value if on else null))
		number.value_changed.connect(func(value):
			if enabled.button_pressed: _modifier(key, value if multiplier else int(value)))
	for key in STYLES:
		_label(modifiers_box, key.replace("_", " ").capitalize())
		var choice := OptionButton.new()
		choice.add_item("Default / no override")
		for value in STYLES[key]:
			choice.add_item(value.capitalize())
		choice.item_selected.connect(func(index):
			if index <= STYLES[key].size():
				_modifier(key, null if index == 0 else STYLES[key][index - 1]))
		modifiers_box.add_child(choice)
		style_controls[key] = choice
	unknown_modifiers = _label(modifiers_box, "")
	# Keep both kinds of grants together, above the template/geometry section.
	form.move_child(modifier_toggle, form.get_children().find(abilities) + 1)
	form.move_child(modifiers_box, form.get_children().find(modifier_toggle) + 1)
	_label(form, "Template information (read-only)")
	summary = _label(form, "")
	bindings = _label(form, "")
	form.hide()

func _label(parent: Node, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _commit_name() -> void:
	if not updating and name_focus_id == node_id and name_input.text != node.get("name", ""):
		_field("name", name_input.text)

func _field(field: String, value: Variant) -> void:
	if not updating and not node_id.is_empty():
		field_requested.emit(node_id, field, value)

func _toggle_ability(index: int) -> void:
	var values: Array = node.get("abilities", []).duplicate()
	var id: String = ability_ids[index]
	if id in values: values.erase(id)
	else: values.append(id)
	_field("abilities", values)

func _modifier(key: String, value: Variant) -> void:
	if updating:
		return
	var values: Dictionary = node.get("modifiers", {}).duplicate(true)
	if value == null: values.erase(key)
	else: values[key] = value
	_field("modifiers", values)

func configure(document: Dictionary, id: String) -> void:
	updating = true
	var changed_node := node_id != id
	node_id = id
	node = {}
	for candidate in document.dungeon.nodes:
		if candidate.id == id:
			node = candidate.duplicate(true)
			break
	form.visible = not node.is_empty()
	if node.is_empty():
		heading.text = "Select a tree node to edit its properties.\nLinks and other rules remain available in JSON."
		updating = false
		return
	if changed_node:
		scroll_vertical = 0
	heading.text = "Node: " + node.id
	if changed_node or not name_input.has_focus():
		name_input.text = node.name
	if cost.value != float(node.cost):
		cost.set_value_no_signal(node.cost)
	var available: Array = ABILITIES.duplicate()
	for ability in node.abilities:
		if ability not in available:
			available.append(ability)
	var popup := abilities.get_popup()
	if available != ability_ids:
		ability_ids = available
		popup.clear()
		for ability in ability_ids:
			popup.add_check_item(ability.capitalize() + (" (unsupported)" if ability not in ABILITIES else ""))
	for i in range(ability_ids.size()):
		popup.set_item_checked(i, ability_ids[i] in node.abilities)
	abilities.text = "None — choose abilities…" if node.abilities.is_empty() else ", ".join(node.abilities)
	abilities.tooltip_text = "Multiple abilities can be selected.\n" + ", ".join(node.abilities)
	templates.clear()
	var room: Dictionary = {}
	for candidate in document.rooms:
		templates.add_item(candidate.name + " [" + candidate.id + "]")
		templates.set_item_metadata(templates.item_count - 1, candidate.id)
		if candidate.id == node.template:
			templates.select(templates.item_count - 1)
			room = candidate
	var count: int = document.dungeon.nodes.filter(func(item): return item.template == node.template).size()
	usage.text = "Used by %d node(s). Editing this template affects all of them." % count
	var modifiers: Dictionary = node.get("modifiers", {})
	var unsupported: Array[String] = []
	for key in numeric_controls:
		var controls: Dictionary = numeric_controls[key]
		controls.enabled.set_pressed_no_signal(modifiers.has(key))
		controls.value.editable = modifiers.has(key)
		var value: Variant = modifiers.get(key, 1 if key.ends_with("_multiplier") else 0)
		if value is float or value is int:
			if controls.value.value != float(value):
				controls.value.set_value_no_signal(value)
		else:
			unsupported.append(key + ": " + str(value))
	for key in style_controls:
		var choice: OptionButton = style_controls[key]
		while choice.item_count > STYLES[key].size() + 1:
			choice.remove_item(choice.item_count - 1)
		var index: int = STYLES[key].find(modifiers.get(key)) + 1
		if modifiers.has(key) and index == 0:
			choice.add_item(str(modifiers[key]) + " (unsupported)")
			index = choice.item_count - 1
		choice.select(index)
	for key in modifiers:
		if not NUMERIC.has(key) and not STYLES.has(key):
			unsupported.append(key + ": " + str(modifiers[key]))
	modifier_toggle.text = "Modifiers (%d) — expand / collapse" % modifiers.size()
	unknown_modifiers.text = "" if unsupported.is_empty() else "Preserved; edit in JSON:\n" + "\n".join(unsupported)
	if not room.is_empty():
		canvas.content = room.duplicate(true)
		canvas.content.erase("ports")
		var layout := DOORS.resolve(document)
		canvas.instance_doors = layout.nodes.get(node.id, [])
		var messages: Array = (layout.errors + layout.warnings).filter(func(message): return message.begins_with(node.id + ":") or message.begins_with(node.id + " /"))
		diagnostics.text = "\n".join(messages)
		diagnostics.visible = not messages.is_empty()
		var key: String = node.id + "/" + room.id
		if key != preview_key:
			preview_key = key
			canvas.fit_content.call_deferred()
		canvas.queue_redraw()
		summary.text = template_summary(room)
		var entries: Array[String] = []
		for binding in document.dungeon.interactions:
			if binding.source.node == node.id:
				entries.append("Switch binding out: %s → %s.%s" % [binding.source.object, binding.target.node, binding.target.object])
			elif binding.target.node == node.id:
				entries.append("Switch binding in: %s.%s → %s" % [binding.source.node, binding.source.object, binding.target.object])
		bindings.text = "\n".join(entries) if not entries.is_empty() else ""
	updating = false

static func template_summary(room: Dictionary) -> String:
	var clear: Dictionary = room.get("clear", {})
	var lines: Array[String] = ["Dimensions: %s × %s" % [room.size[0], room.size[1]], "Clear conditions (ALL):"]
	var names := {"all_enemies_defeated": "Defeat all enemies", "switch_hit": "Hit switch", "all_tokens_collected": "Collect all tokens",
		"reveal_pickup": "Reveal collectible", "prevent_enemy_respawn": "Prevent enemy respawn", "become_root": "Become permanent root (zero allocation)"}
	for condition in clear.get("conditions", []):
		lines.append("• " + str(names.get(condition.kind, condition.kind)) + (" — " + condition.object if condition.has("object") else ""))
	if clear.get("conditions", []).is_empty():
		lines.append("• None — immediately cleared")
	lines.append("Clear effects:")
	var revealed: Array = []
	for effect in clear.get("effects", []):
		lines.append("• " + str(names.get(effect.kind, effect.kind)) + (" — " + effect.object if effect.has("object") else ""))
		if effect.kind == "reveal_pickup":
			revealed.append(effect.object)
	if clear.get("effects", []).is_empty():
		lines.append("• None")
	if clear.get("block_tree_editing_until_cleared", false):
		lines.append("Build editing locked while inside and uncleared.")
	var total := 0
	var rewards: Array[String] = []
	for object in room.objects:
		if object.kind in ["pickup", "chest"] and object.properties.get("kind") == "capacity":
			var value: Variant = object.properties.get("value", 1)
			if value is float or value is int:
				total += int(value)
			rewards.append("• %s: +%s (%s%s)" % [object.id, str(value), object.kind, ", revealed on clear" if object.id in revealed else ""])
	lines.append("Potential capacity upgrades: +%d" % total)
	lines.append("\n".join(rewards) if not rewards.is_empty() else "• None")
	return "\n".join(lines)
