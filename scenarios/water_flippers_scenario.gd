class_name WaterFlippersScenario
extends RefCounted

const ROOM_DEFINITION_SCRIPT: Script = preload("res://scripts/room_definition.gd")
const DOOR_DEFINITION_SCRIPT: Script = preload("res://scripts/door_definition.gd")
const RULE_CONFIG_SCRIPT: Script = preload("res://scripts/rule_config.gd")
const SCENARIO_DEFINITION_SCRIPT: Script = preload("res://scripts/scenario_definition.gd")
const COLLECTABLE_DEFINITION_SCRIPT: Script = preload("res://scripts/collectable_definition.gd")
const WATER_HAZARD_DEFINITION_SCRIPT: Script = preload("res://scripts/water_hazard_definition.gd")

func create():
	var water_strip = WATER_HAZARD_DEFINITION_SCRIPT.new(Rect2(475, 450, 30, 210))
	var rooms: Dictionary = {
		"Prize Room": ROOM_DEFINITION_SCRIPT.new("Prize Room", Rect2(80, 450, 240, 210), Color("a06b46")),
		"Water Room": ROOM_DEFINITION_SCRIPT.new("Water Room", Rect2(360, 450, 260, 210), Color("3d789c"), 1.0, 0, [], 1, false, [water_strip]),
		"Starting Room": ROOM_DEFINITION_SCRIPT.new("Starting Room", Rect2(660, 450, 260, 210), Color("3f7799")),
		"Flippers Room": ROOM_DEFINITION_SCRIPT.new("Flippers Room", Rect2(960, 450, 240, 210), Color("587e68"), 1.0, 0, [], 1, true),
	}
	var doors: Dictionary = {
		"Water—Prize": DOOR_DEFINITION_SCRIPT.new("Water—Prize", "Water Room", "Prize Room", Vector2(340, 555)),
		"Start—Water": DOOR_DEFINITION_SCRIPT.new("Start—Water", "Starting Room", "Water Room", Vector2(640, 555)),
		"Start—Flippers": DOOR_DEFINITION_SCRIPT.new("Start—Flippers", "Starting Room", "Flippers Room", Vector2(940, 555)),
	}
	var collectables: Dictionary = {
		"prize_gold": COLLECTABLE_DEFINITION_SCRIPT.new("prize_gold", "Prize Room", Vector2(200, 555), 1),
	}
	# Three simultaneous routes are required to keep Water and Flippers connected while opening Prize.
	return SCENARIO_DEFINITION_SCRIPT.new("Water & Flippers", rooms, doors, RULE_CONFIG_SCRIPT.new("Starting Room", 3), collectables)
