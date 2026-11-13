extends Node2D

const CONTENT = preload("res://content.gd")
const PROGRESSION = preload("res://progression.gd")
const ROOM = preload("res://room.gd")
var data: Dictionary
var progression
var current := "start"
var room
var room_records: Dictionary = {}
var panel: VBoxContainer
var status: Label
var hud: Label
var message := "Activate a neighboring room, then walk to its door and press E."
var transition_pending := false

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("121b28"))
	data = CONTENT.create()
	progression = PROGRESSION.new(data)
	panel = VBoxContainer.new()
	panel.position = Vector2(810, 40)
	panel.size = Vector2(370, 650)
	add_child(panel)
	hud = Label.new()
	hud.position = Vector2(45, 15)
	add_child(hud)
	status = Label.new()
	status.position = Vector2(45, 620)
	status.size = Vector2(730, 110)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status)
	_enter_room("start", "", 5)

func _process(_delta: float) -> void:
	if room != null:
		hud.text = "%s   |   HP %d/5   |   Points %d/%d   |   Gold %d" % [data.nodes[current].name, room.player.hp, progression.available_points(), progression.capacity, progression.gold]

func _enter_room(destination: String, entry: String, hp: int) -> void:
	if room != null:
		room_records[current] = room.defeated.duplicate()
		remove_child(room)
		room.queue_free()
	current = destination
	room = ROOM.new()
	add_child(room)
	var collected: Dictionary = {}
	var template: Dictionary = data.templates[data.nodes[current].template]
	for pickup in template.pickups:
		if progression.collected.has(current + "/" + pickup.id):
			collected[pickup.id] = true
	room.configure(template, _portals(), collected, room_records.get(current, {}), entry, progression.capabilities(), hp)
	room.portal_requested.connect(_request_travel)
	room.reward_collected.connect(_collect)
	room.player_defeated.connect(_defeat)
	transition_pending = false
	_refresh()

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
		transition_pending = true
		_enter_room.call_deferred(destination, entry, room.player.hp)

func _collect(object_id: String) -> void:
	if progression.collect(current, object_id):
		message = "Collected %s. This reward persists through deactivation." % object_id
		_refresh()

func _defeat() -> void:
	if transition_pending:
		return
	transition_pending = true
	message = "Defeated — returned to Sanctuary. Build and collected rewards retained."
	_enter_room.call_deferred("start", "", 5)

func _toggle(id: String) -> void:
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
	room.player.capabilities = progression.capabilities()
	room.portals = _portals()
	for child in panel.get_children():
		panel.remove_child(child)
		child.queue_free()
	_label("ROOM SKILL TREE", 24)
	_label("Green doors connect active rooms.\nActivation and refunds are local.\nBlue pickups permanently add capacity.", 16)
	for id in data.nodes:
		var node: Dictionary = data.nodes[id]
		var is_active: bool = progression.active.has(id)
		_label(("● " if is_active else "○ ") + node.name + ("  ← you" if id == current else ""), 18)
		if id in progression.neighbors(current):
			var preview: Dictionary = progression.preview_deactivation(id, current) if is_active else progression.preview_activation(id, current)
			var button := Button.new()
			button.focus_mode = Control.FOCUS_NONE
			button.text = ("Deactivate / refund" if is_active else "Activate (%d point)" % node.cost)
			button.disabled = not preview.ok
			if not preview.ok:
				button.text += " — " + preview.reason.replace("_", " ")
			button.tooltip_text = "Affected: " + ", ".join(preview.affected)
			button.pressed.connect(_toggle.bind(id))
			panel.add_child(button)
	_label("\nPrize needs BOTH landings.\nRemoving either also removes Prize.\n\nWASD: move     E: use nearby door\nSpace: sword     Shift: dash", 16)
	status.text = message + "\n\nActive abilities: " + ", ".join(progression.capabilities().abilities.keys())
	room.queue_redraw()

func _label(text: String, size: int) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	panel.add_child(label)
