extends ScrollContainer

# Presentation owns copied source and emits edits addressed by stable node ID.
signal field_requested(node_id: String, field: String, value: Variant)
signal model_requested(model: String)
signal contribution_requested(node_id: String, contribution_id: String, entry: Variant, expected_existing: bool, expected_entry: Variant, expected_slot: Variant)
signal template_edit_requested(node_id: String)
signal template_duplicate_requested(node_id: String)
signal doors_requested
signal door_requested(node_id: String, door_id: String, point: Vector2)
signal door_gesture_started
signal door_gesture_finished

const PREVIEW = preload("res://authoring/preview.gd")
const DOORS = preload("res://authoring/door_layout.gd")
const ICONS = preload("res://presentation/icons.gd")
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
var icon_choice: OptionButton
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
var metadata: Dictionary = {}
var model_choice: OptionButton
var ability_label: Label
var unified_box: VBoxContainer
var contribution_choice: OptionButton
var contribution_type: OptionButton
var contribution_id: LineEdit
var contribution_operation: OptionButton
var contribution_value: LineEdit
var contribution_help: Label
var contribution_remove: Button
var contribution_save: Button
var contribution_entries: Array = []
var contribution_table: VBoxContainer
var individual_toggle: Button
var individual_contents: VBoxContainer
var table_controls: Dictionary = {}
var table_feedback: Label
var table_drafts: Dictionary = {}
var table_drafts_by_node: Dictionary = {}
# Expansion is editor view state shared across node selection and refresh.
var section_expanded := {"Player": true, "Sword": true, "Dash": true}
var section_buttons: Dictionary = {}
var section_contents: Dictionary = {}

func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(column)
	heading = _label(column, "Select a tree node to edit its properties.")
	_label(column, "Dungeon capability model")
	model_choice = OptionButton.new()
	model_choice.add_item("Legacy")
	model_choice.add_item("Unified")
	model_choice.item_selected.connect(func(index):
		if not updating: model_requested.emit("legacy" if index == 0 else "unified_1"))
	column.add_child(model_choice)
	_label(column, "Switching validates the dungeon; source is not converted. Legacy requires removing contributions in JSON, even if empty.")
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
	_label(form, "Map icon")
	icon_choice = OptionButton.new()
	icon_choice.fit_to_longest_item = false
	icon_choice.tooltip_text = "Explicit map symbol only; it does not grant an ability. Unknown values are preserved until changed."
	icon_choice.item_selected.connect(func(index):
		var value: Variant = icon_choice.get_item_metadata(index)
		if value == null or value is String:
			_field("icon_id", value))
	form.add_child(icon_choice)
	ability_label = _label(form, "Abilities")
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
	unified_box = VBoxContainer.new()
	form.add_child(unified_box)
	form.move_child(unified_box, form.get_children().find(modifiers_box) + 1)
	contribution_table = VBoxContainer.new()
	unified_box.add_child(contribution_table)
	individual_toggle = Button.new()
	individual_toggle.toggle_mode = true
	individual_toggle.text = "Individual contributions — collapsed"
	individual_toggle.tooltip_text = "Open the individual editor for repeated or unsupported table entries. Requirements do not grant the action."
	unified_box.add_child(individual_toggle)
	individual_contents = VBoxContainer.new()
	unified_box.add_child(individual_contents)
	individual_contents.hide()
	individual_toggle.toggled.connect(func(expanded):
		individual_contents.visible = expanded
		individual_toggle.text = "Individual contributions — expanded" if expanded else "Individual contributions — collapsed")
	_label(individual_contents, "Individual contributions / JSON escape — requirements do not grant the action")
	contribution_choice = OptionButton.new()
	contribution_choice.item_selected.connect(_select_contribution)
	individual_contents.add_child(contribution_choice)
	_label(individual_contents, "Stable ID (node-local)")
	contribution_id = LineEdit.new()
	individual_contents.add_child(contribution_id)
	_label(individual_contents, "Contribution")
	contribution_type = OptionButton.new()
	contribution_type.item_selected.connect(func(_index): _update_contribution_help())
	individual_contents.add_child(contribution_type)
	contribution_operation = OptionButton.new()
	contribution_operation.add_item("Add")
	contribution_operation.set_item_metadata(0, "add")
	contribution_operation.add_item("Multiply")
	contribution_operation.set_item_metadata(1, "multiply")
	individual_contents.add_child(contribution_operation)
	contribution_value = LineEdit.new()
	contribution_value.placeholder_text = "Operand (not a final stat)"
	individual_contents.add_child(contribution_value)
	contribution_help = _label(individual_contents, "")
	contribution_save = _button(individual_contents, "Save contribution", _save_contribution)
	contribution_remove = _button(individual_contents, "Remove contribution", _remove_contribution)
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

func _matching_contributions(kind: String, key: String, op: String = "") -> Array:
	return contribution_entries.filter(func(entry):
		return entry.get("kind", "") == kind and entry.get(kind, "") == key and (kind != "stat" or entry.get("op", "") == op))

func _build_contribution_table() -> void:
	for child in contribution_table.get_children():
		contribution_table.remove_child(child)
		child.queue_free()
	table_controls.clear()
	section_buttons.clear()
	section_contents.clear()
	_label(contribution_table, "Node contributions — blank means absent; press Enter to commit. + and × are not final build values.")
	table_feedback = _label(contribution_table, "")
	if not table_drafts.is_empty():
		_button(contribution_table, "Discard uncommitted table drafts", func():
			table_drafts.clear()
			_build_contribution_table())
	_label(contribution_table, "Sword / Dash modifiers require that action; they do not grant it. Rooted cooldown restricts movement, not all actions. Max HP increases do not heal.")
	for group in [
		{"name": "Player", "qualities": [["water_pass", "Water Walking"]], "stats": ["max_hp", "move_speed"]},
		{"name": "Sword", "qualities": [["sword", "Sword Attack Enabled"], ["sword_root", "Sword Rooted Cooldown"]], "stats": ["sword_damage", "sword_range", "sword_arc", "sword_cooldown"]},
		{"name": "Dash", "qualities": [["dash", "Dash Enabled"], ["phase_teleport", "Phase Teleport"], ["dash_root", "Dash Rooted Cooldown"]], "stats": ["dash_distance", "dash_recharge"]}
	]:
		var group_name: String = group.name
		var toggle := Button.new()
		toggle.toggle_mode = true
		toggle.focus_mode = Control.FOCUS_ALL
		toggle.button_pressed = section_expanded[group_name]
		contribution_table.add_child(toggle)
		var content := VBoxContainer.new()
		contribution_table.add_child(content)
		section_buttons[group_name] = toggle
		section_contents[group_name] = content
		_set_section_expanded(group_name, toggle.button_pressed)
		toggle.toggled.connect(func(expanded): _set_section_expanded(group_name, expanded))
		for quality in group.qualities:
			var key: String = quality[0]
			var matches := _matching_contributions("quality", key)
			var check := CheckBox.new()
			check.text = quality[1] + (" — multiple; inspect individual entries" if matches.size() > 1 else "")
			check.button_pressed = not matches.is_empty()
			check.disabled = matches.size() > 1
			content.add_child(check)
			table_controls["quality:" + key] = check
			check.toggled.connect(func(on):
				_table_commit("quality", key, "", on)
				if is_instance_valid(check) and check.is_inside_tree():
					check.set_pressed_no_signal(not matches.is_empty()))
		for stat in group.stats:
			var info: Dictionary = metadata.get("stats", {}).get(stat, {})
			_label(content, "%s (%s)" % [info.get("label", stat), info.get("unit", "")])
			var row := HBoxContainer.new()
			content.add_child(row)
			for op in ["add", "multiply"]:
				var matches := _matching_contributions("stat", stat, op)
				var slot: String = "stat:" + str(stat) + ":" + str(op)
				var column := VBoxContainer.new()
				column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(column)
				_label(column, "+ Base Stat" if op == "add" else "× Multiplier")
				var field := LineEdit.new()
				field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				field.custom_minimum_size.x = 50
				field.placeholder_text = "+ Base Stat" if op == "add" else "× Multiplier"
				field.tooltip_text = ("Additive contribution" if op == "add" else "Multiplicative contribution") + "; blank removes the contribution."
				if matches.size() == 1:
					field.text = str(matches[0].get("value", ""))
				if table_drafts.has(slot):
					field.text = table_drafts[slot].text
				var fractional_hp: bool = stat == "max_hp" and op == "add" and matches.size() == 1 and float(matches[0].get("value", 0)) != floor(float(matches[0].get("value", 0)))
				if matches.size() > 1 or fractional_hp:
					field.editable = false
					field.text = "Multiple — inspect" if matches.size() > 1 else field.text
					field.tooltip_text = "Preserved; edit individual contributions or JSON."
				column.add_child(field)
				table_controls[slot] = field
				field.text_changed.connect(func(text):
					if not table_drafts.has(slot):
						table_drafts[slot] = {"text": text, "entries": matches.duplicate(true)}
					else:
						table_drafts[slot].text = text)
				field.text_submitted.connect(func(text): _table_commit("stat", stat, op, text))
				if matches.size() > 1 or fractional_hp:
					_label(content, "%s %s: %s — inspect individual entries / JSON." % [info.get("label", stat), op, "multiple" if matches.size() > 1 else "fractional HP"])

func _set_section_expanded(group: String, expanded: bool) -> void:
	section_expanded[group] = expanded
	var button: Button = section_buttons[group]
	button.text = ("%s — expanded ▾" if expanded else "%s — collapsed ▸") % group
	button.tooltip_text = ("Collapse " if expanded else "Expand ") + group + " contributions"
	section_contents[group].visible = expanded

func _table_commit(kind: String, key: String, op: String, value: Variant) -> void:
	var matches := _matching_contributions(kind, key, op)
	var slot := "stat:" + key + ":" + op
	if kind == "stat" and table_drafts.has(slot) and table_drafts[slot].entries != matches:
		table_feedback.text = "Contribution changed since editing began; source unchanged. Clear this draft before editing again."
		return
	if matches.size() > 1:
		return
	var existing := not matches.is_empty()
	var original: Variant = matches[0].duplicate(true) if existing else null
	if kind == "stat" and key == "max_hp" and op == "add" and existing and float(original.value) != floor(float(original.value)):
		return
	var remove := (kind == "quality" and not bool(value)) or (kind == "stat" and str(value).strip_edges().is_empty())
	if remove and not existing:
		return
	var id := str(original.id) if existing else key + ("_" + op if kind == "stat" else "")
	if not existing:
		var base := id
		var suffix := 1
		while contribution_entries.any(func(item): return item.get("id", "") == id):
			id = base + "_" + str(suffix)
			suffix += 1
	var entry: Variant = null
	if not remove:
		entry = original.duplicate(true) if existing else {"id": id, "kind": kind}
		entry[kind] = key
		if kind == "stat":
			var text := str(value).strip_edges()
			if not text.is_valid_float() or (key == "max_hp" and op == "add" and not text.is_valid_int()):
				table_feedback.text = "%s %s: enter %s" % [key.replace("_", " ").capitalize(), op, "an integer for HP addition." if key == "max_hp" and op == "add" else "a numeric operand."]
				return
			entry.op = op
			entry.value = int(text) if key == "max_hp" and op == "add" else float(text)
	contribution_requested.emit(node_id, id, entry, existing, original, {"kind": kind, "key": key, "op": op, "entries": matches.duplicate(true)})
	if kind == "stat" and table_drafts.has(slot):
		var updated := _matching_contributions(kind, key, op)
		if (entry == null and updated.is_empty()) or (entry != null and updated.size() == 1 and updated[0] == entry):
			table_drafts.erase(slot)

func _configure_contributions(changed_node: bool) -> void:
	var selected_id := ""
	if not changed_node and contribution_choice.selected > 0:
		selected_id = str(contribution_choice.get_item_metadata(contribution_choice.selected))
	contribution_entries = node.get("contributions", []).duplicate(true)
	_build_contribution_table()
	contribution_choice.clear()
	contribution_choice.add_item("New contribution…")
	contribution_choice.set_item_metadata(0, "")
	var selected := 0
	for entry in contribution_entries:
		contribution_choice.add_item("%s — %s" % [str(entry.get("id", "?")), str(entry.get("quality", entry.get("stat", entry.get("kind", "?"))))])
		contribution_choice.set_item_metadata(contribution_choice.item_count - 1, entry.get("id", ""))
		if entry.get("id", "") == selected_id:
			selected = contribution_choice.item_count - 1
	contribution_choice.select(selected)
	contribution_type.clear()
	for group in ["qualities", "stats"]:
		for key in metadata.get(group, {}):
			var item: Dictionary = metadata[group][key]
			contribution_type.add_item(str(item.get("label", key)))
			contribution_type.set_item_metadata(contribution_type.item_count - 1, {"kind": "quality" if group == "qualities" else "stat", "key": key})
	_select_contribution(selected)

func _select_contribution(index: int) -> void:
	if contribution_type.item_count == 0:
		return
	var entry: Dictionary = contribution_entries[index - 1] if index > 0 and index <= contribution_entries.size() else {}
	if entry.is_empty():
		var suffix := 1
		while contribution_entries.any(func(item): return item.get("id", "") == "contribution_%d" % suffix):
			suffix += 1
		contribution_id.text = "contribution_%d" % suffix
		contribution_type.select(0)
		contribution_operation.select(0)
		contribution_value.text = "0"
	else:
		contribution_id.text = str(entry.get("id", ""))
		var found := -1
		for i in range(contribution_type.item_count):
			var item: Dictionary = contribution_type.get_item_metadata(i)
			if item.kind == entry.get("kind", "") and item.key == entry.get(item.kind, ""):
				found = i
				break
		if found < 0:
			contribution_type.select(-1)
			contribution_help.text = "Unsupported contribution preserved; edit in JSON."
			contribution_save.disabled = true
			contribution_remove.disabled = false
			return
		if entry.get("kind", "") == "stat" and entry.get("op", "") not in metadata.stats[entry.stat].operations:
			contribution_type.select(found)
			contribution_help.text = "Unsupported operation preserved; edit in JSON."
			contribution_save.disabled = true
			contribution_remove.disabled = false
			return
		contribution_type.select(found)
		contribution_operation.select(1 if entry.get("op", "") == "multiply" else 0)
		contribution_value.text = str(entry.get("value", 0))
	contribution_id.editable = entry.is_empty()
	contribution_type.disabled = not entry.is_empty()
	contribution_save.disabled = false
	contribution_remove.disabled = entry.is_empty()
	_update_contribution_help()

func _update_contribution_help() -> void:
	if contribution_type.selected < 0:
		return
	var selected: Dictionary = contribution_type.get_item_metadata(contribution_type.selected)
	var is_stat: bool = selected.kind == "stat"
	contribution_operation.visible = is_stat
	contribution_value.visible = is_stat
	var info: Dictionary = metadata.get("stats" if is_stat else "qualities", {}).get(selected.key, {})
	if is_stat:
		var current_op := ""
		if contribution_operation.selected >= 0:
			current_op = str(contribution_operation.get_item_metadata(contribution_operation.selected))
		contribution_operation.clear()
		for op in info.get("operations", []):
			contribution_operation.add_item(str(op).capitalize())
			contribution_operation.set_item_metadata(contribution_operation.item_count - 1, op)
			if op == current_op:
				contribution_operation.select(contribution_operation.item_count - 1)
	var text := ""
	if not str(info.get("requires", "")).is_empty():
		text = "Requires %s to take effect; does not grant it. " % str(info.requires).capitalize()
	if is_stat:
		text += "Unit: %s. Final composed range: %s–%s; not operand limits." % [info.get("unit", ""), info.get("min", ""), info.get("max", "")]
	if selected.key == "max_hp":
		text += " Increasing max HP does not heal."
	if selected.key in ["sword_root", "dash_root"]:
		text += " Restricts ordinary movement, not a full stun."
	if selected.key == "phase_teleport":
		text += " Teleport is not legacy Phase."
	contribution_help.text = text

func _save_contribution() -> void:
	if contribution_type.selected < 0:
		return
	var selected: Dictionary = contribution_type.get_item_metadata(contribution_type.selected)
	var existing: bool = contribution_choice.selected > 0
	var id := contribution_id.text.strip_edges()
	if id.is_empty() or (not existing and contribution_entries.any(func(item): return item.get("id", "") == id)):
		contribution_help.text = "Choose a unique, nonempty contribution ID."
		return
	var entry: Dictionary = contribution_entries[contribution_choice.selected - 1].duplicate(true) if existing else {"id": id, "kind": selected.kind}
	entry[selected.kind] = selected.key
	if selected.kind == "stat":
		if contribution_operation.selected < 0:
			contribution_help.text = "No supported operation is available."
			return
		if not contribution_value.text.is_valid_float():
			contribution_help.text = "Enter a numeric operand."
			return
		entry.op = contribution_operation.get_item_metadata(contribution_operation.selected)
		entry.value = float(contribution_value.text)
	contribution_requested.emit(node_id, id, entry, existing, contribution_entries[contribution_choice.selected - 1].duplicate(true) if existing else null, null)

func _remove_contribution() -> void:
	if contribution_choice.selected > 0:
		contribution_requested.emit(node_id, str(contribution_choice.get_item_metadata(contribution_choice.selected)), null, true, contribution_entries[contribution_choice.selected - 1].duplicate(true), null)

func _configure_icon() -> void:
	icon_choice.clear()
	icon_choice.tooltip_text = "Explicit map symbol only; it does not grant an ability. Unknown values are preserved until changed."
	icon_choice.add_item("None — neutral fallback")
	icon_choice.set_item_metadata(0, null)
	for icon_id in ICONS.IDS:
		icon_choice.add_item(str(icon_id).capitalize())
		icon_choice.set_item_metadata(icon_choice.item_count - 1, icon_id)
	if not node.has("icon_id"):
		icon_choice.select(0)
		return
	var value: Variant = node["icon_id"]
	if value is String and value in ICONS.IDS:
		icon_choice.select(ICONS.IDS.find(value) + 1)
		return
	var display := JSON.stringify(value)
	icon_choice.tooltip_text += "\nPreserved value: " + display
	if display.length() > 80:
		display = display.substr(0, 77) + "..."
	icon_choice.add_item("%s — preserved (neutral fallback)" % display)
	var index := icon_choice.item_count - 1
	icon_choice.set_item_metadata(index, {"preserved": true})
	icon_choice.set_item_disabled(index, true)
	icon_choice.select(index)

func configure(document: Dictionary, id: String) -> void:
	updating = true
	var unified: bool = document.dungeon.get("capability_model", "legacy") == "unified_1"
	model_choice.select(1 if unified else 0)
	ability_label.visible = not unified
	abilities.visible = not unified
	modifier_toggle.visible = not unified
	if unified:
		modifiers_box.hide()
	unified_box.visible = unified
	var changed_node := node_id != id
	if changed_node:
		if not node_id.is_empty():
			table_drafts_by_node[node_id] = table_drafts.duplicate(true)
		table_drafts = table_drafts_by_node.get(id, {}).duplicate(true)
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
	if unified:
		_configure_contributions(changed_node)
	if changed_node or not name_input.has_focus():
		name_input.text = node.name
	if cost.value != float(node.cost):
		cost.set_value_no_signal(node.cost)
	_configure_icon()
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
