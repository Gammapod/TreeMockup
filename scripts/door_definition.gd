class_name DoorDefinition
extends RefCounted

var id: String
var room_a: String
var room_b: String
var position: Vector2
var directional_source_room: String
var fork_group: String
var required_connected_rooms: Array
var gate_id: String
var approach_radius: float

func _init(p_id: String, p_room_a: String, p_room_b: String, p_position: Vector2, p_directional_source_room: String = "", p_fork_group: String = "", p_required_connected_rooms: Array = [], p_gate_id: String = "", p_approach_radius: float = 48.0) -> void:
	id = p_id
	room_a = p_room_a
	room_b = p_room_b
	position = p_position
	directional_source_room = p_directional_source_room
	fork_group = p_fork_group
	required_connected_rooms = p_required_connected_rooms
	gate_id = p_gate_id
	approach_radius = p_approach_radius

func other_room(room_id: String) -> String:
	if room_id == room_a:
		return room_b
	if room_id == room_b:
		return room_a
	return ""
