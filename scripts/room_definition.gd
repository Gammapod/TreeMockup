class_name RoomDefinition
extends RefCounted

var id: String
var bounds: Rect2
var color: Color
var movement_multiplier: float
var max_open_doors_bonus: int
var active_actions: Array = []

func _init(p_id: String, p_bounds: Rect2, p_color: Color, p_movement_multiplier: float = 1.0, p_max_open_doors_bonus: int = 0, p_active_actions: Array = []) -> void:
	id = p_id
	bounds = p_bounds
	color = p_color
	movement_multiplier = p_movement_multiplier
	max_open_doors_bonus = p_max_open_doors_bonus
	active_actions = p_active_actions
