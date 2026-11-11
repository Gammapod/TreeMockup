class_name WallHazardDefinition
extends RefCounted

var id: String
var bounds: Rect2
var switch_id: String

func _init(p_id: String, p_bounds: Rect2, p_switch_id: String) -> void:
	id = p_id
	bounds = p_bounds
	switch_id = p_switch_id
