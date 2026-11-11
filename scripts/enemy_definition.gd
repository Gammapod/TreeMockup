class_name EnemyDefinition
extends RefCounted

var id: String
var room_id: String
var home_position: Vector2
var speed: float

func _init(p_id: String, p_room_id: String, p_home_position: Vector2, p_speed: float = 115.0) -> void:
	id = p_id
	room_id = p_room_id
	home_position = p_home_position
	speed = p_speed
