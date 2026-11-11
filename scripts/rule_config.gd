class_name RuleConfig
extends RefCounted

var root_room: String
var base_max_open_doors: int
var require_root_connection: bool = true
var prevent_loops: bool = true
var collapse_disconnected_branches: bool = true
var prop_player_path: bool = true
var require_adjacent_interaction: bool = true

func _init(p_root_room: String, p_base_max_open_doors: int = 1) -> void:
	root_room = p_root_room
	base_max_open_doors = p_base_max_open_doors
