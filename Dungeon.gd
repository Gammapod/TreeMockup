extends Node2D

const PLAYER_RADIUS: float = 13.0
const PLAYER_SPEED: float = 230.0
const DOOR_HALF_WIDTH: float = 42.0
const BASELINE_SCENARIO_SCRIPT: Script = preload("res://scenarios/baseline_scenario.gd")
const DUNGEON_MODEL_SCRIPT: Script = preload("res://scripts/dungeon_model.gd")

var scenario
var model
var player_position: Vector2 = Vector2(595, 585)
var font: Font
var status_message: String = "Open doors to build a loop-free network."
var flash_time: float = 0.0

func _ready() -> void:
	font = ThemeDB.fallback_font
	scenario = BASELINE_SCENARIO_SCRIPT.new().create()
	model = DUNGEON_MODEL_SCRIPT.new(scenario)
	queue_redraw()

func _process(delta: float) -> void:
	if flash_time > 0.0:
		flash_time = maxf(0.0, flash_time - delta)
		queue_redraw()
	var direction: Vector2 = Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	).normalized()
	if direction != Vector2.ZERO:
		_move_player(direction * PLAYER_SPEED * model.capabilities.movement_multiplier * delta)
		queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		if model.capabilities.has_action("blue_flash"):
			flash_time = 0.22
			status_message = "Room B ability: blue flash!"
		else:
			status_message = "Blue flash requires Room B to be connected to the root."
		queue_redraw()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		for door in scenario.doors.values():
			if Rect2(door.position - Vector2(30, 30), Vector2(60, 60)).has_point(event.position):
				status_message = _toggle_message(door.id, model.try_toggle_door(door.id))
				queue_redraw()
				return

func _move_player(amount: Vector2) -> void:
	for door in scenario.doors.values():
		var state = model.door_state(door.id)
		if not state.open or door.other_room(model.player_room) == "":
			continue
		var destination: String = door.other_room(model.player_room)
		var source_room = scenario.rooms[model.player_room]
		var destination_room = scenario.rooms[destination]
		var travel_direction: Vector2 = (destination_room.bounds.get_center() - source_room.bounds.get_center()).normalized()
		var aligned: bool = abs(player_position.x - door.position.x) < DOOR_HALF_WIDTH if abs(travel_direction.y) > 0.5 else abs(player_position.y - door.position.y) < DOOR_HALF_WIDTH
		if aligned and player_position.distance_to(door.position) < 48.0 and amount.dot(travel_direction) > 0.0:
			if model.try_traverse_door(door.id):
				player_position = _entry_position(destination_room.bounds, travel_direction)
			return
	var room = scenario.rooms[model.player_room]
	var next: Vector2 = player_position + amount
	next.x = clampf(next.x, room.bounds.position.x + PLAYER_RADIUS, room.bounds.end.x - PLAYER_RADIUS)
	next.y = clampf(next.y, room.bounds.position.y + PLAYER_RADIUS, room.bounds.end.y - PLAYER_RADIUS)
	player_position = next

func _entry_position(destination: Rect2, direction: Vector2) -> Vector2:
	var position: Vector2 = destination.get_center()
	if abs(direction.x) > 0.5:
		position.x = destination.position.x + PLAYER_RADIUS + 1 if direction.x > 0.0 else destination.end.x - PLAYER_RADIUS - 1
	else:
		position.y = destination.position.y + PLAYER_RADIUS + 1 if direction.y > 0.0 else destination.end.y - PLAYER_RADIUS - 1
	return position

func _toggle_message(door_id: String, result: String) -> String:
	match result:
		"opened": return "%s opened." % door_id
		"closed": return "%s closed." % door_id
		"propped": return "%s is propped open to keep the player connected to Starting Room." % door_id
		"remote": return "%s is remote. Move into one of its rooms to operate it." % door_id
		"capacity": return "%s is sealed: the %d-door limit is reached." % [door_id, model.capabilities.max_open_doors]
		"loop": return "%s is sealed because opening it would create a loop." % door_id
		_: return "%s is sealed because it would not extend the root-connected tree." % door_id

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1200, 800), Color("10141d"))
	_draw_header()
	_draw_open_door_graph()
	for room in scenario.rooms.values():
		_draw_room(room)
	for door in scenario.doors.values():
		_draw_door(door)
	_draw_player()
	_draw_help()

func _draw_header() -> void:
	draw_string(font, Vector2(48, 55), "DOOR NETWORK — %s" % scenario.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("eef4ff"))
	draw_string(font, Vector2(48, 82), "Open doors form a loop-free tree rooted at Starting Room. Operate doors from an adjacent room.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("9ba8ba"))
	draw_string(font, Vector2(48, 108), "Open doors: %d / %d    •    %s" % [model.open_door_count(), model.capabilities.max_open_doors, status_message], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("f6d365"))
	draw_string(font, Vector2(48, 134), _ability_summary(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("c8fff2"))

func _draw_open_door_graph() -> void:
	for door in scenario.doors.values():
		var a_center: Vector2 = scenario.rooms[door.room_a].bounds.get_center()
		var b_center: Vector2 = scenario.rooms[door.room_b].bounds.get_center()
		var graph_color: Color = Color("55e6cd") if model.door_state(door.id).open else Color("596273")
		if model.door_state(door.id).open:
			draw_line(a_center, b_center, graph_color, 5, true)
		else:
			for segment: int in range(18):
				if segment % 2 == 0:
					draw_line(a_center.lerp(b_center, float(segment) / 18.0), a_center.lerp(b_center, float(segment + 1) / 18.0), graph_color, 2, true)
	for room in scenario.rooms.values():
		var point: Vector2 = room.bounds.get_center()
		draw_circle(point, 12, Color("55e6cd") if model.is_room_reachable(room.id) else Color("596273"))
		draw_circle(point, 6, Color("10141d"))
	draw_string(font, Vector2(48, 170), "OPEN-DOOR GRAPH", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("55e6cd"))

func _draw_room(room) -> void:
	var connected: bool = model.is_room_reachable(room.id)
	var fill: Color = room.color.lightened(0.16) if connected else room.color.darkened(0.55)
	fill.a = 0.82
	draw_rect(room.bounds, fill, true)
	draw_rect(room.bounds, Color("a9c6d9") if connected else Color("586576"), false, 3)
	draw_string(font, room.bounds.position + Vector2(18, 34), room.id, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(font, room.bounds.position + Vector2(18, 59), "CONNECTED TO ROOT" if connected else "NOT CONNECTED", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("c8fff2") if connected else Color("aab0bb"))

func _draw_door(door) -> void:
	var state = model.door_state(door.id)
	var door_color: Color = Color("56e5c8") if state.open else Color("ef6f6c")
	if state.is_sealed():
		door_color = Color("f6d365")
	if state.propped:
		door_color = Color("ffb86c")
	var a_center: Vector2 = scenario.rooms[door.room_a].bounds.get_center()
	var b_center: Vector2 = scenario.rooms[door.room_b].bounds.get_center()
	var horizontal_gap: bool = abs(a_center.x - b_center.x) > abs(a_center.y - b_center.y)
	if state.open:
		var bridge_color: Color = door_color
		bridge_color.a = 0.30
		if horizontal_gap:
			draw_rect(Rect2(door.position - Vector2(20, DOOR_HALF_WIDTH), Vector2(40, DOOR_HALF_WIDTH * 2)), bridge_color, true)
		else:
			draw_rect(Rect2(door.position - Vector2(DOOR_HALF_WIDTH, 20), Vector2(DOOR_HALF_WIDTH * 2, 40)), bridge_color, true)
	else:
		if horizontal_gap:
			draw_rect(Rect2(door.position - Vector2(11, DOOR_HALF_WIDTH), Vector2(22, DOOR_HALF_WIDTH * 2)), door_color, true)
		else:
			draw_rect(Rect2(door.position - Vector2(DOOR_HALF_WIDTH, 11), Vector2(DOOR_HALF_WIDTH * 2, 22)), door_color, true)
	draw_circle(door.position, 8, Color("fff4df"))
	var label: String = "PROPPED OPEN" if state.propped else ("SEALED" if state.is_sealed() else ("OPEN" if state.open else "CLOSED"))
	draw_string(font, door.position + Vector2(-31, -DOOR_HALF_WIDTH - 12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, door_color)

func _draw_player() -> void:
	draw_circle(player_position + Vector2(2, 3), PLAYER_RADIUS + 2, Color(0, 0, 0, 0.28))
	var player_color: Color = Color("43b9ff") if flash_time > 0.0 else Color("ffd166")
	if flash_time > 0.0:
		draw_circle(player_position, PLAYER_RADIUS + 13, Color(0.15, 0.65, 1.0, 0.22))
	draw_circle(player_position, PLAYER_RADIUS, player_color)
	draw_circle(player_position, 5, Color("513b12"))
	draw_string(font, player_position + Vector2(-28, -23), "PLAYER", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("fff1c5"))

func _draw_help() -> void:
	draw_rect(Rect2(48, 744, 1104, 34), Color("1c2635"), true)
	draw_string(font, Vector2(64, 767), "WASD  Move    •    SPACE  Room B flash    •    Click adjacent doors    •    Cyan lines are open connections", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("d9e5f4"))

func _ability_summary() -> String:
	var abilities: Array[String] = ["Starting: movement", "Doors: %d" % model.capabilities.max_open_doors]
	for room_id: String in model.reachable_rooms:
		if room_id != "Starting Room":
			abilities.append(room_id)
	return "ABILITIES — " + "   •   ".join(abilities)
