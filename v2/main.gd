extends Control

const CONTENT = preload("res://content.gd")
const PROGRESSION = preload("res://progression.gd")
const ROOM = preload("res://room.gd")
var data: Dictionary
var progression
var current := "start"
var room
var room_records: Dictionary = {}
var status: Label
var hud: Label
var message := "Activate a neighboring room, then walk to its door and press E."
var transition_pending := false
var room_generation := 0
var data_override: Dictionary = {}
var object_records: Dictionary = {}
var studio
var shell
var tree_ui

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("121b28"))
	data = CONTENT.create() if data_override.is_empty() else data_override
	progression = PROGRESSION.new(data)
	shell = preload("res://gameplay_shell.gd").new()
	add_child(shell)
	hud = shell.hud
	status = shell.status
	tree_ui = preload("res://gameplay_tree.gd").new()
	shell.map_region.add_child(tree_ui)
	tree_ui.configure(data)
	tree_ui.action_requested.connect(_toggle)
	tree_ui.root_travel_requested.connect(_request_root_travel)
	_enter_room(data.root, "", progression.capabilities().max_hp)

func _process(_delta: float) -> void:
	if room != null:
		hud.text = "%s   |   HP %d/%d   |   Points %d/%d   |   Gold %d" % [data.nodes[current].name, room.player.hp, room.player.max_hp, progression.available_points(), progression.capacity, progression.gold]

func _enter_room(destination: String, entry: String, hp: int) -> void:
	# Every replacement invalidates deferred commands from the previous scene/run.
	room_generation += 1
	if room != null:
		progression.leave_room(current)
		room_records[current] = room.defeated.duplicate()
		room.get_parent().remove_child(room)
		room.queue_free()
	current = destination
	room = ROOM.new()
	shell.room_viewport.add_child(room)
	var collected: Dictionary = {}
	var template: Dictionary = data.templates[data.nodes[current].template]
	for pickup in template.pickups:
		if progression.collected.has(current + "/" + pickup.id):
			collected[pickup.id] = true
	var dead: Dictionary = room_records.get(current, {}).duplicate()
	if progression.prevents_respawn(current):
		for enemy in template.enemies:
			dead[enemy.id] = true
	room.configure(template, _portals(), collected, dead, entry, progression.capabilities(), hp, progression.cleared.has(current))
	room.portal_requested.connect(_request_travel)
	room.reward_collected.connect(_collect)
	room.player_defeated.connect(_defeat)
	room.switch_toggled.connect(_switch_toggled)
	room.objective_event.connect(_objective_event)
	transition_pending = false
	_refresh()
	tree_ui.frame_current_room()
	if studio != null and studio.visible:
		room.process_mode = Node.PROCESS_MODE_DISABLED
		room.hide()

func _portals() -> Array:
	var result: Array = []
	for link in data.links:
		if link.a == current:
			result.append({"destination": link.b, "port": link.a_port, "entry": link.b_port, "enabled": progression.can_travel(current, link.b)})
		elif link.b == current:
			result.append({"destination": link.a, "port": link.b_port, "entry": link.a_port, "enabled": progression.can_travel(current, link.a)})
	return result

func _request_travel(destination: String, entry: String) -> void:
	if not transition_pending and progression.can_travel(current, destination):
		_queue_transition("door", destination, entry)

func _queue_transition(kind: String, destination: String, entry: String = "") -> void:
	transition_pending = true
	_finish_transition.call_deferred(room_generation, kind, destination, entry)

func _request_root_travel(destination: String) -> void:
	if transition_pending:
		return
	var preview: Dictionary = progression.preview_root_travel(destination, current)
	if not preview.ok:
		message = "Travel blocked: " + preview.reason
		_refresh()
		return
	_queue_transition("root", destination)

func _finish_transition(generation: int, kind: String, destination: String, entry: String) -> void:
	if generation != room_generation:
		return
	transition_pending = false
	if kind == "defeat":
		_enter_room(data.root, "", progression.capabilities().max_hp)
		return
	if room.player.hp <= 0:
		_defeat()
		return
	var preview: Dictionary = progression.preview_root_travel(destination, current) if kind == "root" else {"ok": progression.can_travel(current, destination), "reason": "door_unavailable"}
	if not preview.ok:
		message = "Travel blocked: " + preview.reason
		_refresh()
		return
	if kind == "root":
		message = "Traveled to root: " + data.nodes[destination].name
	_enter_room(destination, entry, room.player.hp)

func _collect(object_id: String) -> void:
	if progression.collect(current, object_id):
		message = "Collected %s. This reward persists through deactivation." % object_id
		_refresh()

func _defeat() -> void:
	if transition_pending:
		return
	message = "Defeated — returned to Sanctuary. Build and collected rewards retained."
	_queue_transition("defeat", data.root)

func _switch_toggled(object_id: String) -> void:
	progression.record_objective(current, "switch_hit", object_id)
	if not object_records.has(current):
		object_records[current] = {}
	var state: bool = not object_records[current].get(object_id, false)
	object_records[current][object_id] = state
	for binding in data.get("interactions", []):
		if binding.source.node == current and binding.source.object == object_id:
			if not object_records.has(binding.target.node):
				object_records[binding.target.node] = {}
			object_records[binding.target.node][binding.target.object] = state
	message = "Switch %s: %s" % [object_id, "on" if state else "off"]
	_refresh()

func _objective_event(event: String, object_id: String) -> void:
	if progression.record_objective(current, event, object_id):
		message = "Room cleared: " + data.nodes[current].name
	_refresh()

func _toggle(id: String) -> void:
	if transition_pending:
		return
	var result: Dictionary
	if progression.active.has(id):
		result = progression.deactivate(id, current)
		if result.ok:
			for removed in result.affected:
				room_records.erase(removed)
	else:
		result = progression.activate(id, current)
	message = ("Changed rooms: " + ", ".join(result.affected)) if result.ok else ("Blocked: " + result.reason)
	_refresh()

func _refresh() -> void:
	room.player.set_capabilities(progression.capabilities())
	room.apply_object_states(object_records.get(current, {}))
	room.portals = _portals()
	var collected: Dictionary = {}
	var visible: Dictionary = {}
	for pickup in data.templates[data.nodes[current].template].pickups:
		if progression.collected.has(current + "/" + pickup.id):
			collected[pickup.id] = true
		visible[pickup.id] = progression.pickup_visible(current, pickup.id)
	room.sync_pickups(collected, visible)
	if progression.cleared.has(current):
		room.suppress_tokens()
	var previews: Dictionary = {}
	var travel_previews: Dictionary = {}
	for id in data.nodes:
		var is_active: bool = progression.active.has(id)
		previews[id] = progression.preview_deactivation(id, current) if is_active else progression.preview_activation(id, current)
		travel_previews[id] = progression.preview_root_travel(id, current)
	tree_ui.refresh({"current": current, "active": progression.active, "cleared": progression.cleared, "roots": progression.roots, "can_edit_tree": progression.can_edit_tree(current), "travel_previews": travel_previews, "available_points": progression.available_points(), "previews": previews})
	status.text = message + "\n\nActive abilities: " + ", ".join(progression.capabilities().abilities.keys())
	room.queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo() and event.physical_keycode == KEY_F11:
		shell.toggle_fullscreen()
		get_viewport().set_input_as_handled()
	elif event.is_pressed() and not event.is_echo() and event.physical_keycode == KEY_F2:
		_open_studio()
		get_viewport().set_input_as_handled()
	else:
		shell.forward_gameplay_key(event)

func _open_studio() -> void:
	if studio == null:
		studio = load("res://authoring/studio.gd").new()
		studio.play_requested.connect(_play_document)
		studio.close_requested.connect(_close_studio)
		add_child(studio)
	studio.show()
	studio.process_mode = Node.PROCESS_MODE_INHERIT
	room.process_mode = Node.PROCESS_MODE_DISABLED
	room.hide()
	shell.hide()

func _close_studio() -> void:
	studio.hide()
	studio.process_mode = Node.PROCESS_MODE_DISABLED
	room.process_mode = Node.PROCESS_MODE_INHERIT
	room.show()
	shell.show()

func _play_document(compiled: Dictionary) -> void:
	# Playtest starts a fresh run, never mutating the editor's source document.
	room.get_parent().remove_child(room)
	room.queue_free()
	room = null
	room_records.clear()
	object_records.clear()
	data = compiled
	tree_ui.configure(data)
	progression = PROGRESSION.new(data)
	message = "Playtesting authored content. F2 returns to the editors."
	_enter_room(data.root, "", progression.capabilities().max_hp)
	_close_studio()
