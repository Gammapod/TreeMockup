class_name ScenarioDefinition
extends RefCounted

var name: String
var rooms: Dictionary
var doors: Dictionary
var rules
var collectables: Dictionary

func _init(p_name: String, p_rooms: Dictionary, p_doors: Dictionary, p_rules, p_collectables: Dictionary = {}) -> void:
	name = p_name
	rooms = p_rooms
	doors = p_doors
	rules = p_rules
	collectables = p_collectables
