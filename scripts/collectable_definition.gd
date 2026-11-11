class_name CollectableDefinition
extends RefCounted

var id: String
var room_id: String
var position: Vector2
var gold_value: int

func _init(p_id: String, p_room_id: String, p_position: Vector2, p_gold_value: int = 1) -> void:
	id = p_id
	room_id = p_room_id
	position = p_position
	gold_value = p_gold_value
