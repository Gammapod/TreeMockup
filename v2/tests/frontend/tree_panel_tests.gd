extends "res://tests/suite_reporter.gd"

# UI-BOUNDARY: panel consumes snapshots and emits intent without mutating run state.
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	if not FileAccess.file_exists("res://gameplay_tree.gd"):
		push_error("UI-BOUNDARY: standalone snapshot-driven tree panel is missing")
		_complete(1)
		return
	var panel = load("res://gameplay_tree.gd").new()
	root.add_child(panel)
	var data: Dictionary = load("res://tests/fixtures/activation_fixture.gd").create()
	panel.configure(data)
	var snapshot := {"current": "start", "active": {"start": true}, "available_points": 4, "previews": {}}
	for id in data.nodes:
		snapshot.previews[id] = {"ok": id == "sword", "reason": "" if id == "sword" else "not_local", "affected": [id] if id == "sword" else []}
	var before: Dictionary = snapshot.duplicate(true)
	panel.refresh(snapshot)
	panel.select_node("sword")
	var requests: Array = []
	panel.action_requested.connect(func(id): requests.append(id))
	panel.node_action.pressed.emit()
	_expect(requests == ["sword"], "Panel emits the selected node's action intent")
	_expect(snapshot == before and not snapshot.active.has("sword"), "Panel never applies transactions")
	snapshot.active.sword = true
	snapshot.previews.sword.ok = false
	panel.select_node("sword")
	_expect(not panel.node_action.disabled and panel.gameplay_map.node_states.sword == "available", "Presentation snapshot does not alias mutable run dictionaries")
	# UNIFIED-PREVIEW: render authoritative before/after, including dormancy,
	# without composing effects or presenting rejected actions as outcomes.
	var before_build := {"model": "unified_1", "stats": {"dash_distance": {"effective": null, "requires": "dash", "value": 12, "clamped": false, "sources": []}}, "qualities": {"dash": {"granted": false, "effective": false, "requires": "", "sources": []}, "phase": {"granted": true, "effective": false, "requires": "dash", "sources": []}}}
	var after_build: Dictionary = before_build.duplicate(true)
	after_build.stats.dash_distance.effective = 12
	after_build.qualities.dash.granted = true
	after_build.qualities.dash.effective = true
	after_build.qualities.phase.effective = true
	var unified: Dictionary = before.duplicate(true)
	unified.previews.sword.build_before = before_build
	unified.previews.sword.build_after = after_build
	# UI-CURRENT-BUILD: the copied current snapshot is visible without a node
	# and is independent of selected or rejected action previews.
	unified.current_build = before_build.duplicate(true)
	panel.refresh(unified)
	panel.select_node("")
	_expect("Current build" in panel.current_build_label.text and "Dormant" in panel.current_build_label.text, "Current unified build is shown with no selection")
	panel.select_node("sword")
	_expect("Dormant" in panel.selection.text and "Dash" in panel.selection.text and "12" in panel.selection.text, "Unified preview shows dormant and effective effects")
	_expect("Before" in panel.selection.text and "After" in panel.selection.text and "Granted" in panel.selection.text, "Unified preview identifies before/after and granted qualities")
	_expect("12" not in panel.current_build_label.text, "Current build is not replaced by the hypothetical after build")
	unified.current_build.qualities.phase.effective = true
	_expect(not panel.snapshot.current_build.qualities.phase.effective and "Granted • Dormant" in panel.current_build_label.text, "Current build does not alias the supplied snapshot")
	panel.select_node("")
	_expect("Granted • Dormant" in panel.current_build_label.text, "Changing selection leaves current build intact")
	panel.select_node("sword")
	after_build.stats.dash_distance.effective = 99
	panel.select_node("sword")
	_expect("99" not in panel.selection.text, "Unified build results are copied with the presentation snapshot")
	unified.active.sword = true
	unified.previews.sword.build_before = unified.previews.sword.build_after
	unified.previews.sword.build_after = before_build
	panel.refresh(unified)
	_expect("If action succeeds (After)" in panel.selection.text and "Dormant" in panel.selection.text, "Refund preview also shows supplied dormant outcomes")
	unified.previews.sword.ok = false
	unified.previews.sword.erase("build_after")
	panel.refresh(unified)
	_expect("After" not in panel.selection.text, "Rejected action does not promise an after build")
	_expect("Current build" in panel.current_build_label.text and "Granted • Effective" in panel.current_build_label.text, "Rejected preview leaves current build available and refreshes it")
	panel.configure(data)
	_expect(not panel.current_build_label.visible and panel.current_build_label.text.is_empty(), "Document replacement clears the current build")
	panel.refresh(before)
	panel.select_node("sword")
	_expect("Current build (Before)" not in panel.selection.text, "Legacy snapshots retain their existing presentation")
	# UI-BOUNDARY: occupied-room wording only refines the supplied not_local
	# rejection; unrelated and future reasons remain authoritative.
	var occupied: Dictionary = before.duplicate(true)
	occupied.previews.start.reason = "not_local"
	panel.refresh(occupied)
	panel.select_node("start")
	_expect("You cannot deactivate the room you occupy." in panel.selection.text, "Occupied not_local rejection has specific wording")
	occupied.previews.start.reason = "capacity"
	panel.refresh(occupied)
	_expect("Not enough available points." in panel.selection.text and "You cannot deactivate the room you occupy." not in panel.selection.text, "Occupied node retains a distinct supplied rejection")
	occupied.previews.start.reason = "future_rejection"
	panel.refresh(occupied)
	_expect("Future Rejection" in panel.selection.text and "You cannot deactivate the room you occupy." not in panel.selection.text, "Occupied node retains an unknown supplied rejection")
	var legacy: Dictionary = before.duplicate(true)
	legacy.current_build = {"sword_damage": 10}
	panel.refresh(legacy)
	_expect(not panel.current_build_label.visible, "Legacy current build does not display unified UI")
	panel.configure(data)
	_expect(panel.gameplay_map.selected.is_empty() and panel.node_action.disabled and panel.gameplay_map.removal_preview.is_empty(), "Document replacement atomically clears panel state")
	panel.queue_free()
	await process_frame
	if failures.is_empty():
		print("All tree panel boundary tests passed.")
		_complete(0)
	else:
		for failure in failures:
			printerr("ASSERTION FAILED: " + failure)
		_complete(1)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
