class_name GateDefinition
extends RefCounted

var id: String
var interaction_rooms: Array
var required_connected_rooms: Array
var capacity_cost: int

func _init(p_id: String, p_interaction_rooms: Array, p_required_connected_rooms: Array, p_capacity_cost: int = 1) -> void:
	id = p_id
	interaction_rooms = p_interaction_rooms
	required_connected_rooms = p_required_connected_rooms
	capacity_cost = p_capacity_cost
