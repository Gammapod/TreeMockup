class_name EnemyRuntimeState
extends RefCounted

var alive: bool = true
var position: Vector2

func _init(home_position: Vector2) -> void:
	position = home_position
