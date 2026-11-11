extends SceneTree

const BASELINE_SCENARIO_SCRIPT: Script = preload("res://scenarios/baseline_scenario.gd")
const DUNGEON_MODEL_SCRIPT: Script = preload("res://scripts/dungeon_model.gd")
const WATER_FLIPPERS_SCENARIO_SCRIPT: Script = preload("res://scenarios/water_flippers_scenario.gd")
const SWITCH_SCENARIO_SCRIPT: Script = preload("res://scenarios/switch_scenario.gd")
const COMBAT_SCENARIO_SCRIPT: Script = preload("res://scenarios/combat_scenario.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_initial_root_and_capabilities()
	_test_root_only_opening_rule()
	_test_capacity_from_room_c()
	_test_propped_path_and_branch_collapse()
	_test_health_flippers_and_gold()
	_test_switch_wall_and_key_progression()
	_test_combat_enemy_rules()
	if failures.is_empty():
		print("All dungeon model tests passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _model():
	var scenario_factory = BASELINE_SCENARIO_SCRIPT.new()
	return DUNGEON_MODEL_SCRIPT.new(scenario_factory.create())

func _water_model():
	var scenario_factory = WATER_FLIPPERS_SCENARIO_SCRIPT.new()
	return DUNGEON_MODEL_SCRIPT.new(scenario_factory.create())

func _switch_model():
	var scenario_factory = SWITCH_SCENARIO_SCRIPT.new()
	return DUNGEON_MODEL_SCRIPT.new(scenario_factory.create())

func _combat_model():
	var scenario_factory = COMBAT_SCENARIO_SCRIPT.new()
	return DUNGEON_MODEL_SCRIPT.new(scenario_factory.create())

func _test_initial_root_and_capabilities() -> void:
	var model = _model()
	_expect(model.is_room_reachable("Starting Room"), "Starting Room is reachable initially")
	_expect(not model.is_room_reachable("Room A"), "Room A is disconnected initially")
	_expect_equal(model.capabilities.max_open_doors, 1, "Starting Room grants one open door")
	_expect_equal(model.capabilities.movement_multiplier, 1.0, "Base movement multiplier is one")

func _test_root_only_opening_rule() -> void:
	var model = _model()
	_expect_equal(model.door_state("B—D").sealed_reason, "root", "B—D is sealed when neither endpoint reaches root")
	_expect_equal(model.try_toggle_door("A—Start"), "opened", "Root-adjacent door opens")
	_expect_equal(model.try_toggle_door("Start—C"), "capacity", "Second root door is blocked by capacity")

func _test_capacity_from_room_c() -> void:
	var model = _model()
	_expect_equal(model.try_toggle_door("Start—C"), "opened", "Starting-C opens")
	_expect_equal(model.try_traverse_door("Start—C"), true, "Player traverses to Room C")
	_expect_equal(model.capabilities.max_open_doors, 2, "Room C raises capacity by one")
	_expect_equal(model.try_toggle_door("D—C"), "opened", "C-D opens with Room C capacity")
	_expect_equal(model.try_traverse_door("D—C"), true, "Player traverses to Room D")
	_expect_equal(model.capabilities.max_open_doors, 4, "Room D raises capacity by two")

func _test_propped_path_and_branch_collapse() -> void:
	var model = _model()
	model.try_toggle_door("Start—C")
	model.try_traverse_door("Start—C")
	_expect(model.door_state("Start—C").propped, "Starting-C props while player is in Room C")
	model.try_toggle_door("D—C")
	model.try_traverse_door("D—C")
	_expect(model.door_state("D—C").propped, "C-D props while player is in Room D")
	model.try_traverse_door("D—C")
	_expect(not model.door_state("D—C").propped, "C-D unprops when player returns to Room C")
	model.try_traverse_door("Start—C")
	_expect_equal(model.try_toggle_door("Start—C"), "closed", "Root-side door closes with player at root")
	_expect(not model.door_state("D—C").open, "Detached C-D branch closes automatically")
	_expect_equal(model.door_state("D—C").sealed_reason, "root", "Detached C-D is sealed")

func _test_health_flippers_and_gold() -> void:
	var model = _water_model()
	_expect_equal(model.current_hp, 1, "Starting Room grants one current HP")
	_expect_equal(model.capabilities.max_hp, 1, "Starting Room grants one max HP")
	_expect(not model.capabilities.can_cross_water, "Water cannot be crossed before Flippers Room connects")
	_expect_equal(model.try_toggle_door("Start—Water"), "opened", "Water Room connects")
	_expect_equal(model.current_hp, 2, "Water Room grants one current HP")
	_expect_equal(model.try_toggle_door("Start—Flippers"), "opened", "Flippers Room connects")
	_expect(model.capabilities.can_cross_water, "Flippers Room enables water crossing")
	_expect_equal(model.current_hp, 3, "Flippers Room grants one current HP")
	_expect_equal(model.try_traverse_door("Start—Water"), true, "Player enters Water Room")
	_expect_equal(model.try_toggle_door("Water—Prize"), "opened", "Player opens Prize Room door")
	_expect_equal(model.try_traverse_door("Water—Prize"), true, "Player enters Prize Room")
	_expect_equal(model.current_hp, 4, "Prize Room grants one current HP")
	_expect_equal(model.try_collect("prize_gold"), true, "Gold is collected in Prize Room")
	_expect_equal(model.gold_collected, 1, "Collected gold is counted once")
	_expect_equal(model.try_collect("prize_gold"), false, "Gold cannot be collected twice")

func _test_switch_wall_and_key_progression() -> void:
	var model = _switch_model()
	_expect_equal(model.try_toggle_door("Start—Fork"), "opened", "Fork path opens")
	_expect_equal(model.try_traverse_door("Start—Fork"), true, "Player enters Fork")
	_expect_equal(model.try_collect("fork_key"), true, "Fork key is collected")
	_expect_equal(model.capabilities.max_open_doors, 2, "First key permanently adds one door capacity")
	_expect_equal(model.try_toggle_door("Fork—Wall"), "opened", "Wall branch opens")
	_expect_equal(model.try_traverse_door("Fork—Wall"), true, "Player enters Wall Room")
	_expect_equal(model.try_collect("wall_key"), true, "Wall-side key is collected")
	_expect_equal(model.capabilities.max_open_doors, 3, "Second key permanently adds one door capacity")
	_expect_equal(model.try_traverse_door("Fork—Wall"), true, "Player returns to Fork")
	_expect_equal(model.try_toggle_door("Fork—Wall"), "closed", "Wall branch can close after returning")
	_expect_equal(model.try_toggle_door("Fork—Sword"), "opened", "Sword branch opens")
	_expect_equal(model.try_traverse_door("Fork—Sword"), true, "Player enters Sword Room")
	_expect(model.capabilities.has_action("sword"), "Sword Room activates sword")
	_expect_equal(model.try_toggle_door("Sword—Switch"), "opened", "Switch branch opens")
	_expect_equal(model.try_traverse_door("Sword—Switch"), true, "Player enters Switch Room")
	_expect_equal(model.try_toggle_switch("switch_1"), "toggled", "Sword toggles switch")
	_expect(model.is_switch_active("switch_1"), "Switch stays active")
	_expect(model.is_wall_passable("wall_1"), "Associated wall becomes passable")

func _test_combat_enemy_rules() -> void:
	var model = _combat_model()
	_expect_equal(model.try_toggle_door("Start—West"), "opened", "West key branch opens")
	_expect_equal(model.try_traverse_door("Start—West"), true, "Player enters West Room")
	_expect_equal(model.try_collect("west_key"), true, "West key is collected")
	_expect_equal(model.capabilities.max_open_doors, 2, "West key raises permanent capacity")
	_expect_equal(model.try_traverse_door("Start—West"), true, "Player returns to Starting Room")
	_expect_equal(model.try_toggle_door("Start—West"), "closed", "West branch closes")
	_expect_equal(model.try_toggle_door("Start—Sword"), "opened", "Sword branch opens")
	_expect_equal(model.try_toggle_door("Start—Danger"), "opened", "Danger branch opens alongside Sword")
	_expect_equal(model.try_traverse_door("Start—Danger"), true, "Player enters Danger")
	_expect(model.capabilities.has_action("sword"), "Sword remains active from the connected branch")
	_expect_equal(model.try_attack_near(Vector2(820, 405), 100.0), 3, "Sword defeats all nearby bats in one hit")
	_expect(not model.is_enemy_alive("danger_bat_1"), "Defeated bat remains defeated while connected")
	_expect_equal(model.try_traverse_door("Start—Danger"), true, "Player returns to Starting Room")
	_expect_equal(model.try_toggle_door("Start—Danger"), "closed", "Danger branch closes")
	_expect(model.is_enemy_alive("danger_bat_1"), "Defeated bat respawns when its room disconnects")

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures.append("FAILED: %s" % description)

func _expect_equal(actual, expected, description: String) -> void:
	if actual != expected:
		failures.append("FAILED: %s (expected %s, got %s)" % [description, expected, actual])
