extends VBoxContainer

# Presentation only: receives model snapshots, emits commands for the coordinator.
signal action_requested(id: String)

var data: Dictionary = {}
var snapshot: Dictionary = {}
var gameplay_map
var selection: Label
var node_action: Button
var selection_scroll: ScrollContainer
var inspected_node := ""

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var fit_button := Button.new()
	fit_button.text = "Fit graph"
	fit_button.focus_mode = Control.FOCUS_NONE
	add_child(fit_button)
	var help := Label.new()
	help.text = "Click: select • Wheel: zoom • Right/middle drag: pan\nSolid: travel • Dashed arrow: prerequisite\n✓ Active • + Available • × Blocked"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_size_override("font_size", 13)
	add_child(help)
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
	selection_scroll.add_child(selection)
	resized.connect(func():
		selection_scroll.custom_minimum_size.y = 120 if size.y >= 560 else 80)
	node_action = Button.new()
	node_action.focus_mode = Control.FOCUS_NONE
	node_action.pressed.connect(request_selected_action)
	add_child(node_action)
	var controls := Label.new()
	controls.text = "WASD: move • E: door / chest • Space: sword\nShift: dash / run • F2: editors"
	controls.add_theme_font_size_override("font_size", 13)
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(controls)
	select_node("")

func configure(definition: Dictionary) -> void:
	# Definitions are validated immutable content for the duration of a run.
	data = definition
	snapshot = {}
	gameplay_map.set_definition(data)
	select_node("")

func refresh(state: Dictionary) -> void:
	# Keep a coherent presentation while the mutable run advances.
	snapshot = state.duplicate(true)
	gameplay_map.set_occupied(snapshot.current)
	var states: Dictionary = {}
	for id in data.nodes:
		states[id] = "active" if snapshot.active.has(id) else ("available" if snapshot.previews[id].ok else "blocked")
	gameplay_map.set_node_states(states)
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
	if id == snapshot.current and id != data.root and not preview.ok:
		reason_text = "You cannot deactivate the room you occupy."
	selection.text = "%s • Cost: %d\n%s%s" % [node.name, node.cost, state_text, " • You are here" if id == snapshot.current else ""]
	if not preview.ok:
		selection.text += "\n" + reason_text
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
	selection.text += _requirement_details(node)
	node_action.tooltip_text = selection.text

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
	}.get(reason, reason.replace("_", " ").capitalize())
