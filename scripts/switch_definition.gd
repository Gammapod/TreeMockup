class_name SwitchDefinition
extends RefCounted

var id: String
var room_id: String
var position: Vector2
var initial_state: bool

func _init(p_id: String, p_room_id: String, p_position: Vector2, p_initial_state: bool = false) -> void:
	id = p_id
	room_id = p_room_id
	position = p_position
	initial_state = p_initial_state
