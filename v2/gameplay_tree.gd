extends VBoxContainer

# Presentation only: receives model snapshots, emits commands for the coordinator.
signal action_requested(id: String)
signal root_travel_requested(id: String)

var data: Dictionary = {}
var snapshot: Dictionary = {}
var gameplay_map
var selection: Label
var node_action: Button
var root_travel: Button
var edit_permission: Label
var current_build_label: Label
var selection_scroll: ScrollContainer
var inspected_node := ""

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var fit_button := Button.new()
	fit_button.text = "Fit graph"
	fit_button.focus_mode = Control.FOCUS_NONE
	add_child(fit_button)
	var help := Label.new()
	help.text = "Click: select • Wheel: zoom • Right/middle drag: pan\nSolid: travel • Dashed arrow: prerequisite\n✓ Active • + Available • × Blocked • C Cleared • R Root"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 13)
	add_child(help)
	edit_permission = Label.new()
	edit_permission.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	edit_permission.add_theme_color_override("font_color", Color("ffd569"))
	gameplay_map = preload("res://gameplay_map.gd").new()
	gameplay_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(gameplay_map)
	fit_button.pressed.connect(gameplay_map.fit_graph)
	gameplay_map.node_selected.connect(select_node)
	selection = Label.new()
	selection.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selection_scroll = ScrollContainer.new()
	selection_scroll.custom_minimum_size.y = 120
	selection_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(selection_scroll)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selection_scroll.add_child(details)
	details.add_child(edit_permission)
	details.add_child(selection)
	current_build_label = Label.new()
	current_build_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	current_build_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_build_label.hide()
	details.add_child(current_build_label)
	resized.connect(func():
		selection_scroll.custom_minimum_size.y = 120 if size.y >= 560 else 80)
	node_action = Button.new()
	node_action.focus_mode = Control.FOCUS_NONE
	node_action.pressed.connect(request_selected_action)
	var actions := HBoxContainer.new()
	add_child(actions)
	node_action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(node_action)
	root_travel = Button.new()
	root_travel.text = "Travel to root"
	root_travel.focus_mode = Control.FOCUS_NONE
	root_travel.pressed.connect(func():
		if not gameplay_map.selected.is_empty():
			root_travel_requested.emit(gameplay_map.selected))
	actions.add_child(root_travel)
	var controls := Label.new()
	controls.text = "WASD: move • E: chest • Space: sword\nShift: dash / run • F2: editors"
	controls.add_theme_font_size_override("font_size", 13)
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(controls)
	select_node("")

func configure(definition: Dictionary) -> void:
	# Definitions are validated immutable content for the duration of a run.
	data = definition
	snapshot = {}
	current_build_label.text = ""
	current_build_label.hide()
	edit_permission.text = ""
	edit_permission.hide()
	gameplay_map.set_definition(data)
	select_node("")

func refresh(state: Dictionary) -> void:
	# Keep a coherent presentation while the mutable run advances.
	snapshot = state.duplicate(true)
	var current_build: Dictionary = snapshot.get("current_build", {})
	if current_build.get("model", "") == "unified_1":
		current_build_label.text = "Current build:" + _unified_build_text(current_build)
		current_build_label.show()
	else:
		current_build_label.text = ""
		current_build_label.hide()
	edit_permission.text = "" if snapshot.get("can_edit_tree", true) else "Tree editing disabled while this room is uncleared."
	edit_permission.visible = not edit_permission.text.is_empty()
	gameplay_map.set_occupied(snapshot.current)
	var states: Dictionary = {}
	for id in data.nodes:
		states[id] = "active" if snapshot.active.has(id) else ("available" if snapshot.previews[id].ok else "blocked")
	gameplay_map.set_node_states(states)
	gameplay_map.cleared = snapshot.get("cleared", {})
	gameplay_map.roots = snapshot.get("roots", {})
	select_node(gameplay_map.selected)

func frame_current_room() -> void:
	if not snapshot.is_empty():
		gameplay_map.frame_neighborhood(snapshot.current)

func select_node(id: String) -> void:
	if not data.get("nodes", {}).has(id) or snapshot.is_empty():
		id = ""
	if inspected_node != id:
		selection_scroll.scroll_vertical = 0
		inspected_node = id
	gameplay_map.selected = id
	gameplay_map.set_removal_preview([], false)
	gameplay_map.queue_redraw()
	var travel: Dictionary = snapshot.get("travel_previews", {}).get(id, {"ok": false, "reason": "not_cleared_active_root"})
	root_travel.disabled = not travel.ok
	root_travel.tooltip_text = "Travel to this root's spawn without changing HP or build." if travel.ok else _action_reason(travel.reason)
	if id.is_empty():
		selection.text = "Select a node to inspect or change its activation.\nActivation and deactivation are local."
		node_action.text = "Select a node"
		node_action.disabled = true
		node_action.tooltip_text = ""
		return
	var node: Dictionary = data.nodes[id]
	var is_active: bool = snapshot.active.has(id)
	var preview: Dictionary = snapshot.previews[id]
	var state_text := "Active" if is_active else ("Available to activate" if preview.ok else "Inactive — blocked")
	var reason_text := _action_reason(preview.reason)
	if id == snapshot.current and preview.reason not in ["root", "tree_editing_locked"] and not preview.ok:
		reason_text = "You cannot deactivate the room you occupy."
	selection.text = "%s • Cost: %d\n%s%s" % [node.name, node.cost, state_text, " • You are here" if id == snapshot.current else ""]
	for ability in node.get("abilities", []):
		selection.text += "\nGrants: " + ability.capitalize()
	var modifier_names := {
		"sword_range_multiplier": "Reach", "sword_arc_multiplier": "Arc",
		"sword_damage_multiplier": "Damage", "sword_cooldown_multiplier": "Attack interval",
		"dash_distance_multiplier": "Dash distance", "dash_cooldown_multiplier": "Dash recharge",
		"move_speed_multiplier": "Move speed", "dash_speed_multiplier": "Dash speed"
	}
	for key in node.get("modifiers", {}):
		var value: Variant = node.modifiers[key]
		if modifier_names.has(key):
			selection.text += "\n%s ×%.2f (%+.0f%%)" % [modifier_names[key], value, (float(value) - 1.0) * 100]
		elif key == "max_hp_bonus":
			selection.text += "\nMax HP +%d (does not heal)" % value
		elif key == "sword_damage_bonus":
			selection.text += "\nBase damage +%d" % value
		elif key == "dash_style" and value == "phase":
			selection.text += "\nEnemy-contact immunity during dash; distance ×0.65"
		else:
			selection.text += "\n%s: %s" % [key.replace("_", " ").capitalize(), str(value)]
	selection.text += "\n" + ("Cleared" if snapshot.get("cleared", {}).has(id) else "Uncleared")
	var is_root: bool = snapshot.get("roots", {}).has(id)
	if is_root:
		selection.text += " • Root — permanently active, allocation 0"
	if not preview.ok:
		selection.text += "\n" + reason_text
	if preview.get("build_before", {}).get("model", "") == "unified_1":
		selection.text += "\n\nCurrent build (Before):" + _unified_build_text(preview.build_before)
		if preview.ok and preview.get("build_after", {}).get("model", "") == "unified_1":
			selection.text += "\n\nIf action succeeds (After):" + _unified_build_text(preview.build_after)
	node_action.text = "Deactivate / refund" if is_active else "Activate (%d %s)" % [node.cost, "point" if node.cost == 1 else "points"]
	node_action.disabled = not preview.ok
	var refund := 0
	for affected in preview.affected:
		refund += int(data.nodes[affected].cost)
	if is_active and not preview.affected.is_empty():
		gameplay_map.set_removal_preview(preview.affected, not preview.ok)
		var cascaded: PackedStringArray = []
		for affected in preview.affected:
			if affected != id:
				cascaded.append(data.nodes[affected].name)
		selection.text += "\n" + ("Removal preview — orange boxes" if preview.ok else "BLOCKED PREVIEW — red boxes; no changes")
		selection.text += "\nRemove: " + node.name + " • Cascade: " + (", ".join(cascaded) if not cascaded.is_empty() else "None")
		if preview.ok:
			selection.text += "\nRefund: %d points total • Available afterward: %d" % [refund, snapshot.available_points + refund]
			node_action.text = "Deactivate / refund %d points" % refund
		else:
			selection.text += "\nWould refund %d points, but this action is blocked. No refund." % refund
	selection.text += "\nUpstream prerequisites waived for this root." if is_root else _requirement_details(node)
	var rule: Dictionary = data.get("templates", {}).get(node.template, {}).get("clear", {})
	if not rule.get("conditions", []).is_empty():
		selection.text += "\nClear objectives (ALL):"
		for condition in rule.conditions:
			selection.text += "\n  " + condition.kind.replace("_", " ").capitalize() + (" — " + condition.object if condition.has("object") else "")
	if not rule.get("effects", []).is_empty():
		selection.text += "\nClear effects:"
		for effect in rule.effects:
			selection.text += "\n  " + effect.kind.replace("_", " ").capitalize() + (" — " + effect.object if effect.has("object") else "")
	node_action.tooltip_text = selection.text

func _unified_build_text(build: Dictionary) -> String:
	# Display only supplied results; in particular, never calculate dormant values
	# or infer a successful action from an unavailable/rejected preview.
	var text := ""
	for id in build.get("qualities", {}):
		var quality: Dictionary = build.qualities[id]
		var status := "Not granted"
		if quality.get("granted", false):
			status = "Granted • Effective" if quality.get("effective", false) else "Granted • Dormant"
		if quality.get("granted", false) and not quality.get("effective", false) and not str(quality.get("requires", "")).is_empty():
			status += " (requires %s)" % str(quality.requires).replace("_", " ").capitalize()
		status += _unified_sources_text(quality.get("sources", []))
		text += "\n  %s: %s" % [str(id).replace("_", " ").capitalize(), status]
	for id in build.get("stats", {}):
		var stat: Dictionary = build.stats[id]
		var status: String
		if stat.get("effective") == null:
			status = "Dormant"
			if not str(stat.get("requires", "")).is_empty():
				status += " (requires %s)" % str(stat.requires).replace("_", " ").capitalize()
		else:
			status = str(stat.effective)
			if stat.get("clamped", false):
				status += " (capped)"
		status += _unified_sources_text(stat.get("sources", []))
		text += "\n  %s: %s" % [str(id).replace("_", " ").capitalize(), status]
	return text

func _unified_sources_text(sources: Array) -> String:
	var names: PackedStringArray = []
	for source in sources:
		var id := str(source.get("node_id", ""))
		if not id.is_empty():
			var node: Dictionary = data.get("nodes", {}).get(id, {})
			var label := str(node.get("name", id))
			if not names.has(label):
				names.append(label)
	return " • Sources: " + ", ".join(names) if not names.is_empty() else ""

func _requirement_details(node: Dictionary) -> String:
	var text := "\n\nOngoing prerequisites:"
	var all_of: Array = node.get("requires_all", [])
	var any_of: Array = node.get("requires_any", [])
	if all_of.is_empty() and any_of.is_empty():
		text += " None"
	for group in [{"label": "ALL — every listed room must be active", "ids": all_of}, {"label": "ANY — at least one must be active", "ids": any_of}]:
		if group.ids.is_empty():
			continue
		text += "\n" + group.label
		for prerequisite in group.ids:
			text += "\n  %s %s (%s)" % ["✓" if snapshot.active.has(prerequisite) else "×", data.nodes[prerequisite].name, "active" if snapshot.active.has(prerequisite) else "inactive"]
	var exclusive: String = node.get("exclusive_group", "")
	if not exclusive.is_empty():
		var other_active: PackedStringArray = []
		for other in snapshot.active:
			if other != node.id and data.nodes[other].get("exclusive_group", "") == exclusive:
				other_active.append(data.nodes[other].name)
		text += "\nExclusive group: %s • Other active choices: %s" % [exclusive, ", ".join(other_active) if not other_active.is_empty() else "None"]
	return text

func request_selected_action() -> void:
	if not gameplay_map.selected.is_empty():
		# This is intent, not authorization. The coordinator/model must revalidate.
		action_requested.emit(gameplay_map.selected)

func _action_reason(reason: String) -> String:
	return {
		"root": "The root room is permanently active.",
		"not_local": "Deactivation requires an adjacent room.",
		"not_local_or_wrong_direction": "Activation requires an adjacent room with an allowed activation direction.",
		"prerequisites": "Required rooms are not active.",
		"exclusive_choice": "Another room in this exclusive group is active.",
		"capacity": "Not enough available points.",
		"would_strand_player": "This would deactivate the room you occupy.",
		"invalid_location": "Your current room must be active.",
		"missing": "This room no longer exists.",
		"already_active": "This room is already active.",
		"inactive": "This room is already inactive.",
		"tree_editing_locked": "Clear the room you occupy before editing the tree.",
		"not_cleared_active_root": "Travel requires a cleared, active root.",
		"already_here": "You are already in this room.",
	}.get(reason, reason.replace("_", " ").capitalize())
