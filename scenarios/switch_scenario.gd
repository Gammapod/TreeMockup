class_name SwitchScenario
extends RefCounted

const ROOM_DEFINITION_SCRIPT: Script = preload("res://scripts/room_definition.gd")
const DOOR_DEFINITION_SCRIPT: Script = preload("res://scripts/door_definition.gd")
const RULE_CONFIG_SCRIPT: Script = preload("res://scripts/rule_config.gd")
const SCENARIO_DEFINITION_SCRIPT: Script = preload("res://scripts/scenario_definition.gd")
const COLLECTABLE_DEFINITION_SCRIPT: Script = preload("res://scripts/collectable_definition.gd")
const SWITCH_DEFINITION_SCRIPT: Script = preload("res://scripts/switch_definition.gd")
const WALL_HAZARD_DEFINITION_SCRIPT: Script = preload("res://scripts/wall_hazard_definition.gd")

func create():
	var wall = WALL_HAZARD_DEFINITION_SCRIPT.new("wall_1", Rect2(350, 450, 30, 210), "switch_1")
	var rooms: Dictionary = {
		"Prize": ROOM_DEFINITION_SCRIPT.new("Prize", Rect2(20, 450, 150, 210), Color("a06b46")),
		"Wall": ROOM_DEFINITION_SCRIPT.new("Wall", Rect2(210, 450, 280, 210), Color("786a55"), 1.0, 0, [], 1, false, [], [wall]),
		"Fork": ROOM_DEFINITION_SCRIPT.new("Fork", Rect2(530, 450, 240, 210), Color("597b94")),
		"Starting Room": ROOM_DEFINITION_SCRIPT.new("Starting Room", Rect2(810, 450, 260, 210), Color("3f7799")),
		"Sword": ROOM_DEFINITION_SCRIPT.new("Sword", Rect2(530, 210, 240, 210), Color("8b5b5b"), 1.0, 0, ["sword"]),
		"Switch": ROOM_DEFINITION_SCRIPT.new("Switch", Rect2(810, 210, 260, 210), Color("606b8e")),
	}
	var doors: Dictionary = {
		"Wall—Prize": DOOR_DEFINITION_SCRIPT.new("Wall—Prize", "Wall", "Prize", Vector2(190, 555)),
		"Fork—Wall": DOOR_DEFINITION_SCRIPT.new("Fork—Wall", "Fork", "Wall", Vector2(510, 555)),
		"Start—Fork": DOOR_DEFINITION_SCRIPT.new("Start—Fork", "Starting Room", "Fork", Vector2(790, 555)),
		"Fork—Sword": DOOR_DEFINITION_SCRIPT.new("Fork—Sword", "Fork", "Sword", Vector2(650, 430)),
		"Sword—Switch": DOOR_DEFINITION_SCRIPT.new("Sword—Switch", "Sword", "Switch", Vector2(790, 315)),
	}
	var collectables: Dictionary = {
		"fork_key": COLLECTABLE_DEFINITION_SCRIPT.new("fork_key", "Fork", Vector2(700, 555), 1, "key"),
		"wall_key": COLLECTABLE_DEFINITION_SCRIPT.new("wall_key", "Wall", Vector2(430, 555), 1, "key"),
		"prize_coin": COLLECTABLE_DEFINITION_SCRIPT.new("prize_coin", "Prize", Vector2(95, 555)),
	}
	var switches: Dictionary = {
		"switch_1": SWITCH_DEFINITION_SCRIPT.new("switch_1", "Switch", Vector2(940, 315)),
	}
	return SCENARIO_DEFINITION_SCRIPT.new("Switch & Wall", rooms, doors, RULE_CONFIG_SCRIPT.new("Starting Room", 1), collectables, switches)
