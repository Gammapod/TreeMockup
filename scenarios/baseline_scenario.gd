class_name BaselineScenario
extends RefCounted

const ROOM_DEFINITION_SCRIPT: Script = preload("res://scripts/room_definition.gd")
const DOOR_DEFINITION_SCRIPT: Script = preload("res://scripts/door_definition.gd")
const RULE_CONFIG_SCRIPT: Script = preload("res://scripts/rule_config.gd")
const SCENARIO_DEFINITION_SCRIPT: Script = preload("res://scripts/scenario_definition.gd")

func create():
	var rooms: Dictionary = {
		"Room A": ROOM_DEFINITION_SCRIPT.new("Room A", Rect2(150, 480, 270, 210), Color("765a99"), 2.0),
		"Starting Room": ROOM_DEFINITION_SCRIPT.new("Starting Room", Rect2(460, 480, 270, 210), Color("3f7799")),
		"Room B": ROOM_DEFINITION_SCRIPT.new("Room B", Rect2(460, 210, 270, 210), Color("427f6e"), 1.0, 0, ["blue_flash"]),
		"Room C": ROOM_DEFINITION_SCRIPT.new("Room C", Rect2(770, 480, 270, 210), Color("a06b46"), 1.0, 1),
		"Room D": ROOM_DEFINITION_SCRIPT.new("Room D", Rect2(770, 210, 270, 210), Color("7c668c"), 1.0, 2),
	}
	var doors: Dictionary = {
		"A—Start": DOOR_DEFINITION_SCRIPT.new("A—Start", "Room A", "Starting Room", Vector2(440, 585)),
		"B—Start": DOOR_DEFINITION_SCRIPT.new("B—Start", "Room B", "Starting Room", Vector2(595, 450)),
		"Start—C": DOOR_DEFINITION_SCRIPT.new("Start—C", "Starting Room", "Room C", Vector2(750, 585)),
		"B—D": DOOR_DEFINITION_SCRIPT.new("B—D", "Room B", "Room D", Vector2(750, 315)),
		"D—C": DOOR_DEFINITION_SCRIPT.new("D—C", "Room D", "Room C", Vector2(905, 450)),
	}
	return SCENARIO_DEFINITION_SCRIPT.new("Baseline", rooms, doors, RULE_CONFIG_SCRIPT.new("Starting Room", 1))
