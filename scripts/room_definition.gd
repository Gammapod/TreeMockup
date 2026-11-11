class_name RoomDefinition
extends RefCounted

var id: String
var bounds: Rect2
var color: Color
var movement_multiplier: float
var max_open_doors_bonus: int
var active_actions: Array = []
var health_bonus: int
var grants_water_walking: bool
var water_hazards: Array = []
var wall_hazards: Array = []

func _init(p_id: String, p_bounds: Rect2, p_color: Color, p_movement_multiplier: float = 1.0, p_max_open_doors_bonus: int = 0, p_active_actions: Array = [], p_health_bonus: int = 1, p_grants_water_walking: bool = false, p_water_hazards: Array = [], p_wall_hazards: Array = []) -> void:
	id = p_id
	bounds = p_bounds
	color = p_color
	movement_multiplier = p_movement_multiplier
	max_open_doors_bonus = p_max_open_doors_bonus
	active_actions = p_active_actions
	health_bonus = p_health_bonus
	grants_water_walking = p_grants_water_walking
	water_hazards = p_water_hazards
	wall_hazards = p_wall_hazards
