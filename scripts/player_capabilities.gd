class_name PlayerCapabilities
extends RefCounted

var movement_multiplier: float = 1.0
var max_open_doors: int = 1
var active_actions: Array[String] = []
var max_hp: int = 0
var can_cross_water: bool = false

func has_action(action_id: String) -> bool:
	return active_actions.has(action_id)
