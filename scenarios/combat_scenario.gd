class_name CombatScenario
extends RefCounted

const ROOM_DEFINITION_SCRIPT: Script = preload("res://scripts/room_definition.gd")
const DOOR_DEFINITION_SCRIPT: Script = preload("res://scripts/door_definition.gd")
const RULE_CONFIG_SCRIPT: Script = preload("res://scripts/rule_config.gd")
const SCENARIO_DEFINITION_SCRIPT: Script = preload("res://scripts/scenario_definition.gd")
const COLLECTABLE_DEFINITION_SCRIPT: Script = preload("res://scripts/collectable_definition.gd")
const ENEMY_DEFINITION_SCRIPT: Script = preload("res://scripts/enemy_definition.gd")

func create():
	var rooms: Dictionary = {
		"Double Prize": ROOM_DEFINITION_SCRIPT.new("Double Prize", Rect2(120, 320, 240, 170), Color("a06b46")),
		"Danger+Prize": ROOM_DEFINITION_SCRIPT.new("Danger+Prize", Rect2(400, 320, 240, 170), Color("8a594e")),
		"Danger": ROOM_DEFINITION_SCRIPT.new("Danger", Rect2(680, 320, 240, 170), Color("87555a")),
		"West Room": ROOM_DEFINITION_SCRIPT.new("West Room", Rect2(400, 550, 240, 170), Color("527d73")),
		"Starting Room": ROOM_DEFINITION_SCRIPT.new("Starting Room", Rect2(680, 550, 240, 170), Color("3f7799")),
		"Sword Room": ROOM_DEFINITION_SCRIPT.new("Sword Room", Rect2(960, 550, 220, 170), Color("8b5b5b"), 1.0, 0, ["sword"]),
	}
	var doors: Dictionary = {
		"Danger+Prize—Double": DOOR_DEFINITION_SCRIPT.new("Danger+Prize—Double", "Danger+Prize", "Double Prize", Vector2(380, 405)),
		"Danger—Danger+Prize": DOOR_DEFINITION_SCRIPT.new("Danger—Danger+Prize", "Danger", "Danger+Prize", Vector2(660, 405)),
		"Start—Danger": DOOR_DEFINITION_SCRIPT.new("Start—Danger", "Starting Room", "Danger", Vector2(800, 520)),
		"Start—West": DOOR_DEFINITION_SCRIPT.new("Start—West", "Starting Room", "West Room", Vector2(660, 635)),
		"Start—Sword": DOOR_DEFINITION_SCRIPT.new("Start—Sword", "Starting Room", "Sword Room", Vector2(940, 635)),
	}
	var collectables: Dictionary = {
		"west_key": COLLECTABLE_DEFINITION_SCRIPT.new("west_key", "West Room", Vector2(520, 635), 1, "key"),
		"sword_coin": COLLECTABLE_DEFINITION_SCRIPT.new("sword_coin", "Sword Room", Vector2(1070, 635)),
		"danger_key": COLLECTABLE_DEFINITION_SCRIPT.new("danger_key", "Danger", Vector2(850, 405), 1, "key"),
		"danger_prize_coin": COLLECTABLE_DEFINITION_SCRIPT.new("danger_prize_coin", "Danger+Prize", Vector2(525, 405)),
		"double_prize_coin_1": COLLECTABLE_DEFINITION_SCRIPT.new("double_prize_coin_1", "Double Prize", Vector2(200, 375)),
		"double_prize_coin_2": COLLECTABLE_DEFINITION_SCRIPT.new("double_prize_coin_2", "Double Prize", Vector2(280, 435)),
	}
	var enemies: Dictionary = {
		"danger_bat_1": ENEMY_DEFINITION_SCRIPT.new("danger_bat_1", "Danger", Vector2(820, 405)),
		"danger_bat_2": ENEMY_DEFINITION_SCRIPT.new("danger_bat_2", "Danger", Vector2(860, 370)),
		"danger_bat_3": ENEMY_DEFINITION_SCRIPT.new("danger_bat_3", "Danger", Vector2(870, 445)),
		"danger_prize_bat_1": ENEMY_DEFINITION_SCRIPT.new("danger_prize_bat_1", "Danger+Prize", Vector2(480, 370)),
		"danger_prize_bat_2": ENEMY_DEFINITION_SCRIPT.new("danger_prize_bat_2", "Danger+Prize", Vector2(530, 430)),
		"danger_prize_bat_3": ENEMY_DEFINITION_SCRIPT.new("danger_prize_bat_3", "Danger+Prize", Vector2(590, 395)),
	}
	return SCENARIO_DEFINITION_SCRIPT.new("Combat", rooms, doors, RULE_CONFIG_SCRIPT.new("Starting Room", 1), collectables, {}, enemies)
