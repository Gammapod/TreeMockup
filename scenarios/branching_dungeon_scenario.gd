class_name BranchingDungeonScenario
extends RefCounted

const ROOM_DEFINITION_SCRIPT: Script = preload("res://scripts/room_definition.gd")
const DOOR_DEFINITION_SCRIPT: Script = preload("res://scripts/door_definition.gd")
const RULE_CONFIG_SCRIPT: Script = preload("res://scripts/rule_config.gd")
const SCENARIO_DEFINITION_SCRIPT: Script = preload("res://scripts/scenario_definition.gd")
const COLLECTABLE_DEFINITION_SCRIPT: Script = preload("res://scripts/collectable_definition.gd")
const GATE_DEFINITION_SCRIPT: Script = preload("res://scripts/gate_definition.gd")

func create():
	var rooms: Dictionary = {
		"Big Swing": ROOM_DEFINITION_SCRIPT.new("Big Swing", Rect2(20, 350, 160, 100), Color("8b5b5b")),
		"Fast Swing": ROOM_DEFINITION_SCRIPT.new("Fast Swing", Rect2(210, 350, 160, 100), Color("8b5b5b")),
		"Neutral Swing": ROOM_DEFINITION_SCRIPT.new("Neutral Swing", Rect2(400, 350, 160, 100), Color("8b5b5b"), 1.0, 0, [], 5),
		"Sword Landing": ROOM_DEFINITION_SCRIPT.new("Sword Landing", Rect2(210, 200, 180, 100), Color("976a64"), 1.0, 0, [], 0),
		"Sword Practice": ROOM_DEFINITION_SCRIPT.new("Sword Practice", Rect2(280, 500, 180, 100), Color("6d566e")),
		"Sword": ROOM_DEFINITION_SCRIPT.new("Sword", Rect2(280, 650, 180, 100), Color("8b5b5b"), 1.0, 0, ["sword"]),
		"Starting Room": ROOM_DEFINITION_SCRIPT.new("Starting Room", Rect2(500, 650, 180, 100), Color("3f7799")),
		"Boots": ROOM_DEFINITION_SCRIPT.new("Boots", Rect2(720, 650, 180, 100), Color("527d73"), 1.0, 0, ["boots"]),
		"Boots Practice": ROOM_DEFINITION_SCRIPT.new("Boots Practice", Rect2(720, 500, 180, 100), Color("527d73")),
		"Hit Dash": ROOM_DEFINITION_SCRIPT.new("Hit Dash", Rect2(640, 350, 160, 100), Color("527d73")),
		"Run": ROOM_DEFINITION_SCRIPT.new("Run", Rect2(830, 350, 160, 100), Color("527d73")),
		"Neutral Dash": ROOM_DEFINITION_SCRIPT.new("Neutral Dash", Rect2(1020, 350, 160, 100), Color("527d73"), 1.0, 0, [], 5),
		"Boots Landing": ROOM_DEFINITION_SCRIPT.new("Boots Landing", Rect2(830, 200, 180, 100), Color("527d73"), 1.0, 0, [], 0),
		"Prize": ROOM_DEFINITION_SCRIPT.new("Prize", Rect2(510, 200, 180, 100), Color("a06b46")),
	}
	var doors: Dictionary = {
		"Start—Sword": DOOR_DEFINITION_SCRIPT.new("Start—Sword", "Starting Room", "Sword", Vector2(480, 700)),
		"Start—Boots": DOOR_DEFINITION_SCRIPT.new("Start—Boots", "Starting Room", "Boots", Vector2(700, 700)),
		"Sword—Practice": DOOR_DEFINITION_SCRIPT.new("Sword—Practice", "Sword", "Sword Practice", Vector2(370, 625)),
		"Sword—Big Swing": DOOR_DEFINITION_SCRIPT.new("Sword—Big Swing", "Sword", "Big Swing", Vector2(240, 500), "Sword", "sword_style", [], "", 220.0),
		"Sword—Fast Swing": DOOR_DEFINITION_SCRIPT.new("Sword—Fast Swing", "Sword", "Fast Swing", Vector2(320, 500), "Sword", "sword_style", [], "", 180.0),
		"Sword—Neutral Swing": DOOR_DEFINITION_SCRIPT.new("Sword—Neutral Swing", "Sword", "Neutral Swing", Vector2(400, 500), "Sword", "sword_style", [], "", 180.0),
		"Big Swing—Landing": DOOR_DEFINITION_SCRIPT.new("Big Swing—Landing", "Big Swing", "Sword Landing", Vector2(195, 325), "Big Swing", "", [], "", 180.0),
		"Fast Swing—Landing": DOOR_DEFINITION_SCRIPT.new("Fast Swing—Landing", "Fast Swing", "Sword Landing", Vector2(290, 325), "Fast Swing", "", [], "", 120.0),
		"Neutral Swing—Landing": DOOR_DEFINITION_SCRIPT.new("Neutral Swing—Landing", "Neutral Swing", "Sword Landing", Vector2(430, 325), "Neutral Swing", "", [], "", 120.0),
		"Boots—Practice": DOOR_DEFINITION_SCRIPT.new("Boots—Practice", "Boots", "Boots Practice", Vector2(810, 625)),
		"Boots—Hit Dash": DOOR_DEFINITION_SCRIPT.new("Boots—Hit Dash", "Boots", "Hit Dash", Vector2(760, 500), "Boots", "boots_style", [], "", 180.0),
		"Boots—Run": DOOR_DEFINITION_SCRIPT.new("Boots—Run", "Boots", "Run", Vector2(850, 500), "Boots", "boots_style", [], "", 180.0),
		"Boots—Neutral Dash": DOOR_DEFINITION_SCRIPT.new("Boots—Neutral Dash", "Boots", "Neutral Dash", Vector2(940, 500), "Boots", "boots_style", [], "", 180.0),
		"Hit Dash—Landing": DOOR_DEFINITION_SCRIPT.new("Hit Dash—Landing", "Hit Dash", "Boots Landing", Vector2(790, 325), "Hit Dash", "", [], "", 120.0),
		"Run—Landing": DOOR_DEFINITION_SCRIPT.new("Run—Landing", "Run", "Boots Landing", Vector2(910, 325), "Run", "", [], "", 120.0),
		"Neutral Dash—Landing": DOOR_DEFINITION_SCRIPT.new("Neutral Dash—Landing", "Neutral Dash", "Boots Landing", Vector2(1010, 325), "Neutral Dash", "", [], "", 120.0),
		"Sword Landing—Prize": DOOR_DEFINITION_SCRIPT.new("Sword Landing—Prize", "Sword Landing", "Prize", Vector2(450, 250), "", "", [], "prize_gate", 120.0),
		"Boots Landing—Prize": DOOR_DEFINITION_SCRIPT.new("Boots Landing—Prize", "Boots Landing", "Prize", Vector2(750, 250), "", "", [], "prize_gate", 120.0),
	}
	var collectables: Dictionary = {
		"sword_key_1": COLLECTABLE_DEFINITION_SCRIPT.new("sword_key_1", "Sword", Vector2(340, 690), 1, "key"),
		"sword_key_2": COLLECTABLE_DEFINITION_SCRIPT.new("sword_key_2", "Sword", Vector2(410, 710), 1, "key"),
		"boots_key_1": COLLECTABLE_DEFINITION_SCRIPT.new("boots_key_1", "Boots", Vector2(780, 690), 1, "key"),
		"boots_key_2": COLLECTABLE_DEFINITION_SCRIPT.new("boots_key_2", "Boots", Vector2(850, 710), 1, "key"),
		"sword_landing_key": COLLECTABLE_DEFINITION_SCRIPT.new("sword_landing_key", "Sword Landing", Vector2(300, 250), 1, "key"),
		"boots_landing_key": COLLECTABLE_DEFINITION_SCRIPT.new("boots_landing_key", "Boots Landing", Vector2(920, 250), 1, "key"),
		"prize_coin": COLLECTABLE_DEFINITION_SCRIPT.new("prize_coin", "Prize", Vector2(600, 250)),
	}
	var gates: Dictionary = {
		"prize_gate": GATE_DEFINITION_SCRIPT.new("prize_gate", ["Sword Landing", "Boots Landing"], ["Sword Landing", "Boots Landing"], 1),
	}
	var rules = RULE_CONFIG_SCRIPT.new("Starting Room", 1)
	rules.prevent_loops = false
	return SCENARIO_DEFINITION_SCRIPT.new("Branching Dungeon", rooms, doors, rules, collectables, {}, {}, gates)
