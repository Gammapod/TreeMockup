class_name DoorDefinition
extends RefCounted

var id: String
var room_a: String
var room_b: String
var position: Vector2

func _init(p_id: String, p_room_a: String, p_room_b: String, p_position: Vector2) -> void:
	id = p_id
	room_a = p_room_a
	room_b = p_room_b
	position = p_position

func other_room(room_id: String) -> String:
	if room_id == room_a:
		return room_b
	if room_id == room_b:
		return room_a
	return ""
