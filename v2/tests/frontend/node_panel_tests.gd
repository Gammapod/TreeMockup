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
	var store = editor.store
	editor.document = store.migrate(store.new_project())
	var room: Dictionary = store.new_room("trial")
	room.objects = [
		{"id": "lever", "kind": "switch", "position": [300, 150], "properties": {}},
		{"id": "barrier", "kind": "wall", "position": [300, 300], "size": [20, 100], "properties": {}},
		{"id": "reward", "kind": "chest", "position": [600, 200], "properties": {"kind": "capacity", "value": 3}},
		{"id": "key", "kind": "pickup", "position": [600, 300], "properties": {"kind": "capacity", "value": 2}}
	]
	room.clear = {"conditions": [{"kind": "switch_hit", "object": "lever"}], "effects": [{"kind": "reveal_pickup", "object": "reward"}]}
	room.extension = {"preserve": "template"}
	editor.document.rooms.append(room)
	editor.document.rooms.append(store.new_room("blank"))
	for id in ["one", "two"]:
		var node: Dictionary = store.new_node(id, "trial")
		node.map_position = [100 if id == "one" else 300, 200]
		node.extension = {"preserve": "node"}
		editor.document.dungeon.nodes.append(node)
	editor.document.dungeon.links = [{"id": "travel", "a": "one", "b": "two", "activate_from": ["one", "two"]}]
	editor.document.dungeon.interactions = [{"id": "binding", "source": {"node": "one", "object": "lever", "event": "toggled"}, "target": {"node": "two", "object": "barrier", "action": "set_open"}}]
	editor._reset_history()
	editor._set_mode("tree")
	editor._select_element("node", "one")
	await process_frame
	var panel = editor.node_panel
	_expect(editor.mode_buttons.tree.button_pressed and not editor.mode_buttons.room.button_pressed, "Ribbon identifies the current editor mode")
	editor.inspector.text = "{invalid"
	editor.mode_buttons.room.pressed.emit()
	_expect(editor.mode == "tree" and editor.mode_buttons.tree.button_pressed and not editor.mode_buttons.room.button_pressed and editor.inspector.text == "{invalid", "Rejected mode change retains ribbon state and pending JSON")
	editor.inspector.text = editor.inspector_original
	_expect(editor.inspector_tabs.current_tab == 0 and panel.node_id == "one", "Selecting a tree node populates Properties")
	_expect(panel.usage.text.begins_with("Used by 2"), "Template usage counts instances")
	_expect(panel.summary.text.contains("Potential capacity upgrades: +5") and panel.summary.text.contains("reward: +3 (chest, revealed on clear)"), "Capacity summary includes chest values and clear-hidden rewards")
	_expect(panel.summary.text.contains("Hit switch — lever") and panel.summary.text.contains("Reveal collectible — reward"), "Clear conditions/effects are named read-only summaries")
	var pristine: Dictionary = editor.document.duplicate(true)
	panel.configure(editor.document, "one")
	_expect(editor.document == pristine and editor.history.undo_stack.is_empty(), "Displaying Properties cannot author defaults or dirty source")
	panel.cost.value = 3
	_expect(_node("one").cost == 3 and _node("two").cost == 1, "Numeric cost only edits selected node")
	editor._undo()
	_expect(panel.cost.value == 1 and _node("one").cost == 1, "Undo synchronizes property controls")
	editor._redo()
	_expect(panel.cost.value == 3, "Redo restores property control")
	panel.abilities.get_popup().id_pressed.emit(0)
	panel.abilities.get_popup().id_pressed.emit(1)
	_expect(_node("one").abilities == ["sword", "dash"], "Ability picker supports multiple grants")
	_node("one").abilities.append("future_ability")
	_node("one").modifiers = {"future_modifier": {"keep": true}, "sword_range_multiplier": 1.3}
	editor._refresh()
	panel.abilities.get_popup().id_pressed.emit(0)
	_expect(_node("one").abilities == ["dash", "future_ability"], "Known ability edits retain unsupported grants")
	panel.numeric_controls.sword_arc_multiplier.enabled.button_pressed = true
	panel.numeric_controls.sword_arc_multiplier.value.value = 1.5
	panel.style_controls.dash_style.select(1)
	panel.style_controls.dash_style.item_selected.emit(1)
	_expect(_node("one").modifiers.sword_arc_multiplier == 1.5 and _node("one").modifiers.dash_style == "phase", "Numeric and behavior modifiers are authored")
	_expect(_node("one").modifiers.future_modifier.keep and _node("one").modifiers.sword_range_multiplier == 1.3, "Modifier editing retains unrelated and unknown fields")
	panel.numeric_controls.sword_arc_multiplier.enabled.button_pressed = false
	_expect(not _node("one").modifiers.has("sword_arc_multiplier"), "Disabling a modifier removes only that key")
	# Switching templates must reject missing references and wrong-kind objects.
	panel.templates.select(2)
	panel.templates.item_selected.emit(2)
	_expect(_node("one").template == "trial" and panel.templates.get_item_metadata(panel.templates.selected) == "trial", "Invalid template switch is rejected and picker restored")
	var wrong: Dictionary = room.duplicate(true)
	wrong.id = "wrong"
	wrong.objects[0].kind = "pickup"
	wrong.clear = {"conditions": [], "effects": []}
	editor.document.rooms.append(wrong)
	editor._refresh()
	editor._edit_node_field("one", "template", "wrong")
	_expect(_node("one").template == "trial" and editor.feedback.text.contains("Unsupported interaction"), "Template switch cannot silently retarget a switch binding to a pickup")
	var before_duplicate: Dictionary = editor.document.duplicate(true)
	var history_count: int = editor.history.undo_stack.size()
	panel.template_duplicate_requested.emit("one")
	var copy_id: String = _node("one").template
	_expect(copy_id != "trial" and _node("two").template == "trial", "Duplicate-and-assign isolates only the selected instance")
	var copy: Dictionary = editor.document.rooms.back()
	_expect(copy.extension.preserve == "template" and copy.objects[0].id == "lever", "Template clone preserves unknown fields and local object IDs")
	_expect(editor.document.dungeon.interactions == before_duplicate.dungeon.interactions, "Template clone retains stable instance bindings")
	_expect(editor.history.undo_stack.size() == history_count + 1, "Template duplication and assignment form one transaction")
	editor._undo()
	_expect(editor.document == before_duplicate, "Undo atomically removes template copy and restores assignment")
	editor._redo()
	_expect(_node("one").template == copy_id, "Redo restores the same stable template ID")
	editor.preview.pan = Vector2(41, 75)
	editor.preview.zoom = 0.7
	editor.preview.fitting = false
	panel.template_edit_requested.emit("one")
	_expect(editor.mode == "room" and editor.document.rooms[editor.room_index].id == copy_id and editor.return_button.visible, "Edit-template navigates to the assigned copy")
	editor._return_to_node()
	_expect(editor.mode == "tree" and editor.selected_node == "one" and editor.preview.pan == Vector2(41, 75) and editor.preview.zoom == 0.7, "Back-to-node preserves graph view and selection")
	# Inline preview and the accepted selector share endpoint placement/history.
	var expected: Dictionary = load("res://authoring/door_layout.gd").resolve(editor.document)
	_expect(panel.canvas.instance_doors == expected.nodes.one, "Inline preview uses the common resolver")
	history_count = editor.history.undo_stack.size()
	panel.canvas.gesture_started.emit()
	panel.canvas.door_moved.emit("travel_a", Vector2(200, 70))
	panel.canvas.door_moved.emit("travel_a", Vector2(500, 70))
	panel.canvas.gesture_finished.emit()
	_expect(editor.history.undo_stack.size() == history_count + 1 and editor.document.dungeon.links[0].a_door.wall == "north", "Inline door drag is one reversible instance edit")
	editor._undo()
	_expect(not editor.document.dungeon.links[0].has("a_door") and panel.canvas.instance_doors[0].automatic, "Undo restores automatic placement in preview")
	# Pending invalid JSON cannot be overwritten by the form or hidden by tab changes.
	var before_invalid: Dictionary = editor.document.duplicate(true)
	editor.inspector_tabs.current_tab = 2
	editor.inspector.text = "{invalid"
	editor.inspector_tabs.current_tab = 0
	_expect(editor.inspector_tabs.current_tab == 2 and editor.inspector.text == "{invalid", "Invalid JSON keeps its source tab and text")
	editor._edit_node_field("one", "cost", 7)
	_expect(editor.document == before_invalid and editor.inspector.text == "{invalid", "Invalid pending source blocks property edits")
	editor._refresh()
	editor._select_element("node", "two")
	_expect(panel.node_id == "two" and panel.cost.value == 1, "Selection changes do not show stale node data")
	editor._edit_node_field("one", "cost", 99)
	_expect(_node("one").cost != 99, "Stale node intent cannot edit previously selected node")
	var save_path := "user://node_panel_test.json"
	editor._save_to(save_path)
	var loaded: Dictionary = store.load_document(save_path)
	_expect(loaded.ok and loaded.document.dungeon.nodes[1].template == copy_id, "Property edits round-trip in portable content")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	# Both tabs fit at the minimum window size, including expanded modifiers.
	root.size = Vector2i(960, 640)
	editor.inspector_tabs.current_tab = 0
	panel.modifiers_box.show()
	await process_frame
	await process_frame
	_expect(editor.inspector_tabs.get_global_rect().end.x <= 960 and editor.feedback.get_global_rect().end.y <= 640, "Expanded properties fit minimum window")
	_expect(panel.get_v_scroll_bar().visible, "Long contextual form scrolls instead of displacing canvas")
	_test_icons()
	_test_unified_editor()
	_test_unified_table()
	editor.queue_free()
	await process_frame
	if failures.is_empty():
		print("All node contextual panel tests passed.")
	else:
		for failure in failures:
			printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _test_icons() -> void:
	editor.document = editor.store.migrate(editor.store.new_project())
	editor._reset_history()
	editor._set_mode("tree")
	var id: String = editor.document.dungeon.nodes[0].id
	editor._select_element("node", id)
	var panel = editor.node_panel
	var before: Dictionary = editor.document.duplicate(true)
	panel.configure(editor.document, id)
	_expect(editor.document == before and editor.history.undo_stack.is_empty(), "Opening icon picker never authors a default")
	var sword_index := -1
	for i in range(panel.icon_choice.item_count):
		if panel.icon_choice.get_item_metadata(i) == "sword":
			sword_index = i
	_expect(sword_index >= 0, "Sword is available as an explicit icon choice")
	if sword_index < 0:
		return
	panel.icon_choice.select(sword_index)
	panel.icon_choice.item_selected.emit(sword_index)
	_expect(_node(id).get("icon_id") == "sword", "Choosing an icon commits the explicit ID")
	var typed_before: Dictionary = editor.document.duplicate(true)
	for invalid in [12, {}, "", "res://icon.svg"]:
		editor._edit_node_field(id, "icon_id", invalid)
		_expect(editor.document == typed_before, "Typed icon edits reject malformed new IDs without changing source")
	editor._undo()
	_expect(not _node(id).has("icon_id"), "Undo restores absent icon field")
	editor._redo()
	_expect(_node(id).get("icon_id") == "sword", "Redo restores explicit icon")
	var path := "user://node_icon_roundtrip.json"
	editor._save_to(path)
	var loaded: Dictionary = editor.store.load_document(path)
	_expect(loaded.ok and loaded.document.dungeon.nodes[0].get("icon_id") == "sword", "Icon choice survives save and load")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	panel.icon_choice.select(0)
	panel.icon_choice.item_selected.emit(0)
	_expect(not _node(id).has("icon_id"), "Clear removes the field rather than inventing a value")
	editor._undo()
	_expect(_node(id).get("icon_id") == "sword", "Undo restores an explicitly cleared icon")
	_node(id).icon_id = "future_icon"
	editor._refresh()
	_expect(panel.icon_choice.get_item_text(panel.icon_choice.selected).contains("future_icon") and _node(id).icon_id == "future_icon", "Unknown icon remains visible and unchanged")
	editor._save_to(path)
	loaded = editor.store.load_document(path)
	_expect(loaded.ok and loaded.document.dungeon.nodes[0].icon_id == "future_icon", "Unknown well-formed ID survives save and load")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	panel.icon_choice.select(sword_index)
	panel.icon_choice.item_selected.emit(sword_index)
	_expect(_node(id).icon_id == "sword", "Unknown icon can be deliberately replaced with a known choice")
	editor._undo()
	_expect(_node(id).icon_id == "future_icon", "Undo restores a replaced unknown ID")
	before = editor.document.duplicate(true)
	editor.inspector.text = "{invalid"
	panel.icon_choice.select(sword_index)
	panel.icon_choice.item_selected.emit(sword_index)
	_expect(editor.document == before and editor.inspector.text == "{invalid" and panel.icon_choice.get_item_text(panel.icon_choice.selected).contains("future_icon"), "Invalid pending JSON blocks icon edit, restores picker and preserves draft")
	editor.inspector.text = editor.inspector_original
	panel.icon_choice.select(0)
	panel.icon_choice.item_selected.emit(0)
	_expect(not _node(id).has("icon_id"), "Unknown icon can be deliberately cleared")
	editor._undo()
	_expect(_node(id).get("icon_id") == "future_icon", "Undo restores an unknown icon unchanged")
	for value in [null, 5, {}, ["sword"], ""]:
		_node(id).icon_id = value
		editor._refresh()
		before = editor.document.duplicate(true)
		panel.configure(editor.document, id)
		_expect(editor.document == before and panel.icon_choice.get_item_text(panel.icon_choice.selected).contains("preserved"), "Malformed icon is safely shown and never overwritten by opening")
		panel.icon_choice.select(0)
		panel.icon_choice.item_selected.emit(0)
		_expect(not _node(id).has("icon_id"), "Explicit clear removes a malformed legacy icon")
		editor._undo()
		_expect(_node(id).has("icon_id") and _node(id).icon_id == value, "Undo preserves the original malformed legacy value")
		panel.icon_choice.select(sword_index)
		panel.icon_choice.item_selected.emit(sword_index)
		_expect(_node(id).get("icon_id") == "sword", "A known choice can replace a malformed legacy icon")
		editor._undo()
		_expect(_node(id).has("icon_id") and _node(id).icon_id == value, "Undo restores a replaced malformed icon")

func _test_unified_editor() -> void:
	# EDITOR-UNIFIED: model switches and ID-addressed contribution edits are
	# validated whole-document transactions, preserving incompatible source.
	if not editor.has_method("_set_capability_model") or not editor.has_method("_edit_contribution"):
		_expect(false, "Unified model and contribution transactions are available")
		return
	editor.document = editor.store.migrate(editor.store.new_project())
	editor._reset_history()
	editor._set_mode("tree")
	var id: String = editor.document.dungeon.nodes[0].id
	editor._select_element("node", id)
	var original: Dictionary = editor.document.duplicate(true)
	editor._set_capability_model("unified_1")
	_expect(editor.document.dungeon.get("capability_model", "") == "unified_1", "Compatible model switch commits")
	editor._undo()
	_expect(editor.document == original, "Undo restores exact absent model field")
	editor._redo()
	var panel = editor.node_panel
	_expect(panel.unified_box.visible and not panel.abilities.visible and not panel.modifier_toggle.visible, "Unified model shows contributions instead of legacy controls")
	_expect(not panel.individual_contents.visible and panel.individual_toggle.focus_mode == Control.FOCUS_ALL, "Individual editor starts collapsed and has a keyboard-focusable control")
	var before_view: Dictionary = editor.document.duplicate(true)
	var history_view: int = editor.history.undo_stack.size()
	panel.individual_toggle.button_pressed = true
	panel.contribution_value.text = "draft"
	panel.individual_toggle.button_pressed = false
	panel.individual_toggle.button_pressed = true
	_expect(panel.individual_contents.visible and panel.contribution_value.text == "draft", "Individual editor collapse preserves its draft")
	_expect(editor.document == before_view and editor.history.undo_stack.size() == history_view, "Individual editor visibility does not edit source or history")
	var stat_index := -1
	for i in range(panel.contribution_type.item_count):
		var item: Dictionary = panel.contribution_type.get_item_metadata(i)
		if item.kind == "stat" and item.key == "dash_distance":
			stat_index = i
	panel.contribution_type.select(stat_index)
	panel.contribution_type.item_selected.emit(stat_index)
	_expect("Requires Dash" in panel.contribution_help.text and "not operand limits" in panel.contribution_help.text, "Metadata explains action dependency and composed bounds")
	panel.contribution_id.text = "ui_boost"
	panel.contribution_operation.select(1)
	panel.contribution_value.text = "1.4"
	panel.contribution_save.pressed.emit()
	_expect(_node(id).get("contributions", []).size() == 1 and _node(id).contributions[0].id == "ui_boost", "Metadata-driven controls add a selected contribution")
	panel.contribution_choice.select(1)
	panel.contribution_choice.item_selected.emit(1)
	panel.contribution_value.text = "-1"
	var before_bad_value: Dictionary = editor.document.duplicate(true)
	panel.contribution_save.pressed.emit()
	_expect(editor.document == before_bad_value and panel.contribution_value.text == "-1", "Rejected multiplier retains editable draft and committed source")
	panel.contribution_remove.pressed.emit()
	_expect(_node(id).contributions.is_empty(), "Remove control targets the selected contribution")
	var contribution := {"id": "boost", "kind": "stat", "stat": "dash_distance", "op": "multiply", "value": 1.2, "extension": {"keep": true}}
	editor._edit_contribution(id, "boost", contribution)
	_expect(_node(id).get("contributions", []).size() == 1, "Contribution add commits")
	var changed: Dictionary = contribution.duplicate(true)
	changed.value = 1.5
	editor._edit_contribution(id, "boost", changed)
	_expect(_node(id).contributions[0].value == 1.5 and _node(id).contributions[0].extension.keep, "Edit retains stable ID and unknown fields")
	var before_conflict: Dictionary = editor.document.duplicate(true)
	editor._set_capability_model("legacy")
	_expect(editor.document == before_conflict and not editor.feedback.text.is_empty(), "Incompatible switch preserves source and reports conflict")
	editor._edit_contribution(id, "boost", null)
	_expect(_node(id).get("contributions", []).is_empty(), "Contribution remove commits")
	var empty_contributions: Dictionary = editor.document.duplicate(true)
	editor._set_capability_model("legacy")
	_expect(editor.document == empty_contributions, "Legacy switch rejects even an empty contributions field without removing it")
	editor._undo()
	_expect(_node(id).contributions[0] == changed, "Undo restores exact contribution")
	editor._redo()
	editor._undo()
	var save_path := "user://unified_node_panel_test.json"
	editor._save_to(save_path)
	var loaded: Dictionary = editor.store.load_document(save_path)
	_expect(loaded.ok and loaded.document.dungeon.nodes[0].contributions[0] == changed, "Contribution IDs and unknown data round-trip")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	editor._edit_contribution(id, "boost", changed, false)
	_expect(_node(id).contributions[0] == changed and "changed since selection" in editor.feedback.text, "Stale add cannot overwrite an existing ID")
	editor.inspector.text = "{invalid"
	var before_invalid: Dictionary = editor.document.duplicate(true)
	editor._edit_contribution(id, "boost", null)
	_expect(editor.document == before_invalid and editor.inspector.text == "{invalid", "Invalid pending JSON blocks contribution edits")

func _test_unified_table() -> void:
	# EDITOR-UNIFIED-TABLE: cells preserve exact source identity, reject stale
	# changes and never aggregate repeated contributions.
	if not editor.node_panel.has_method("_table_commit"):
		_expect(false, "Unified grouped contribution table exists")
		return
	editor.document = editor.store.migrate(editor.store.new_project())
	editor._reset_history()
	editor._refresh()
	editor._set_mode("tree")
	var id: String = editor.document.dungeon.nodes[0].id
	editor._select_element("node", id)
	editor._set_capability_model("unified_1")
	var panel = editor.node_panel
	var before: Dictionary = editor.document.duplicate(true)
	panel.configure(editor.document, id)
	_expect(editor.document == before, "Displaying neutral cells never authors defaults")
	# EDITOR-SECTION-VIEW: expansion is independent presentation state, not
	# authored history, and must retain drafts through rebuilds and selection.
	if not panel.has_method("_set_section_expanded"):
		_expect(false, "Unified groups have collapsible controls")
	else:
		var history_before: int = editor.history.undo_stack.size()
		_expect(panel.section_contents.Player.visible and panel.section_contents.Sword.visible and panel.section_contents.Dash.visible, "All sections initially expanded")
		var draft_field: LineEdit = panel.table_controls["stat:move_speed:add"]
		draft_field.text = "13"
		draft_field.text_changed.emit("13")
		var button: Button = panel.section_buttons.Player
		_expect(button.focus_mode == Control.FOCUS_ALL and "Player" in button.text, "Group control is named and keyboard-focusable")
		button.grab_focus()
		var accept := InputEventAction.new()
		accept.action = "ui_accept"
		accept.pressed = true
		root.push_input(accept)
		accept = InputEventAction.new()
		accept.action = "ui_accept"
		accept.pressed = false
		root.push_input(accept)
		_expect(not panel.section_contents.Player.visible and panel.section_contents.Sword.visible and panel.section_contents.Dash.visible, "Collapsing one section leaves others expanded")
		_expect("collapsed" in button.text.to_lower() and editor.document == before and editor.history.undo_stack.size() == history_before, "Collapse announces state without a source transaction")
		panel.configure(editor.document, "")
		panel.configure(editor.document, id)
		_expect(not panel.section_contents.Player.visible and panel.table_controls["stat:move_speed:add"].text == "13", "Section state and draft survive changing selection")
		panel.section_buttons.Player.button_pressed = true
		_expect(panel.section_contents.Player.visible and panel.table_controls["stat:move_speed:add"].text == "13", "Reopening restores the uncommitted draft")
		panel.section_buttons.Sword.button_pressed = false
		panel.section_buttons.Dash.button_pressed = false
		_expect(panel.section_contents.Player.visible and not panel.section_contents.Sword.visible and not panel.section_contents.Dash.visible, "Sword and Dash collapse independently")
		editor.inspector.text = "{invalid"
		panel.section_buttons.Sword.button_pressed = true
		_expect(editor.inspector.text == "{invalid" and editor.document == before, "View changes preserve pending invalid JSON")
		editor.inspector.text = editor.inspector_original
		panel.section_buttons.Dash.button_pressed = true
		panel.table_drafts.clear()
		panel.configure(editor.document, id)
	panel._table_commit("stat", "dash_distance", "add", "2")
	_expect(_node(id).contributions.size() == 1, "Table adds a single contribution")
	var entry: Dictionary = _node(id).contributions[0].duplicate(true)
	entry.extension = {"preserve": true}
	_node(id).contributions[0] = entry.duplicate(true)
	editor._refresh()
	if panel.has_method("_set_section_expanded"):
		panel.section_buttons.Dash.button_pressed = false
	panel._table_commit("stat", "dash_distance", "add", "3")
	_expect(_node(id).contributions[0].id == entry.id and _node(id).contributions[0].extension.preserve, "Cell edit preserves ID and unknown fields")
	editor._undo()
	_expect(_node(id).contributions[0] == entry, "Undo restores original contribution")
	editor._redo()
	if panel.has_method("_set_section_expanded"):
		_expect(not panel.section_contents.Dash.visible, "Source edit, undo and redo retain section view state")
		panel.section_buttons.Dash.button_pressed = true
	var duplicate: Dictionary = _node(id).contributions[0].duplicate(true)
	duplicate.id = "other"
	_node(id).contributions.append(duplicate)
	editor._refresh()
	before = editor.document.duplicate(true)
	panel._table_commit("stat", "dash_distance", "add", "8")
	_expect(editor.document == before, "Ambiguous table slot cannot alter duplicate entries")
	_node(id).contributions.append({"id": "fraction", "kind": "stat", "stat": "max_hp", "op": "add", "value": 0.5})
	editor._refresh()
	before = editor.document.duplicate(true)
	panel._table_commit("stat", "max_hp", "add", "1")
	_expect(editor.document == before, "Fractional HP contribution cannot be silently rounded by table")
	_expect(not panel.table_controls["stat:dash_distance:add"].editable and not panel.table_controls["stat:max_hp:add"].editable, "Ambiguous and fractional HP cells expose read-only escape")
	var check: CheckBox = panel.table_controls["quality:dash"]
	check.button_pressed = true
	_expect(_node(id).contributions.any(func(item): return item.get("quality") == "dash"), "Checkbox commits the requested quality")
	check = panel.table_controls["quality:dash"]
	check.button_pressed = false
	_expect(not _node(id).contributions.any(func(item): return item.get("quality") == "dash"), "Checkbox removes its single matching quality")
	_node(id).contributions.append({"id": "q1", "kind": "quality", "quality": "dash"})
	_node(id).contributions.append({"id": "q2", "kind": "quality", "quality": "dash"})
	editor._refresh()
	before = editor.document.duplicate(true)
	_expect(panel.table_controls["quality:dash"].disabled, "Repeated quality grants are explicitly ambiguous")
	panel._table_commit("quality", "dash", "", false)
	_expect(editor.document == before, "Ambiguous checkbox cannot delete duplicate grants")
	panel._table_commit("stat", "move_speed", "multiply", "1")
	_expect(_node(id).contributions.any(func(item): return item.get("stat") == "move_speed" and item.get("value") == 1), "Explicit neutral value remains an authored contribution")
	var pending: LineEdit = panel.table_controls["stat:move_speed:add"]
	pending.text = "7"
	pending.text_changed.emit("7")
	panel._table_commit("stat", "max_hp", "multiply", "2.5")
	_expect(panel.table_controls["stat:move_speed:add"].text == "7", "Uncommitted cell draft survives another valid edit")
	var no_fraction: Dictionary = editor.document.duplicate(true)
	panel._table_commit("stat", "max_hp", "multiply", "3.5")
	_expect(editor.document != no_fraction, "Fractional HP multiplier remains supported")
	var draft: Dictionary = editor.document.dungeon.duplicate(true)
	draft.nodes[0].contributions[0].value = 17
	editor.inspector.text = JSON.stringify(draft)
	panel._table_commit("stat", "dash_distance", "add", "8")
	# Ambiguity prevents editing before applying pending JSON; use an
	# unambiguous slot to exercise stale full-entry detection separately below.
	editor.inspector.text = editor.inspector_original
	_node(id).contributions.remove_at(1)
	editor._refresh()
	draft = editor.document.dungeon.duplicate(true)
	draft.nodes[0].contributions[0].value = 17
	draft.nodes[0].contributions[0].extension = {"changed": true}
	editor.inspector.text = JSON.stringify(draft)
	panel._table_commit("stat", "dash_distance", "add", "8")
	_expect(_node(id).contributions[0].value == 17 and _node(id).contributions[0].extension.changed and "changed since selection" in editor.feedback.text, "Pending JSON applies before rejecting stale full-entry table edit")
	editor._refresh()
	draft = editor.document.dungeon.duplicate(true)
	var inserted: Dictionary = draft.nodes[0].contributions[0].duplicate(true)
	inserted.id = "json_duplicate"
	draft.nodes[0].contributions.append(inserted)
	editor.inspector.text = JSON.stringify(draft)
	panel._table_commit("stat", "dash_distance", "add", "9")
	_expect(_node(id).contributions[0].value == 17 and "changed since selection" in editor.feedback.text, "Pending JSON adding a duplicate rejects a now-ambiguous cell edit")
	before = editor.document.duplicate(true)
	editor.inspector.text = "{invalid"
	panel._table_commit("quality", "dash", "", true)
	_expect(editor.document == before and editor.inspector.text == "{invalid", "Pending invalid JSON blocks table edits")

func _node(id: String) -> Dictionary:
	for node in editor.document.dungeon.nodes:
		if node.id == id:
			return node
	return {}

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
