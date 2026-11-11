extends SceneTree

const BASELINE_SCENARIO_SCRIPT: Script = preload("res://scenarios/baseline_scenario.gd")
const DUNGEON_MODEL_SCRIPT: Script = preload("res://scripts/dungeon_model.gd")
const WATER_FLIPPERS_SCENARIO_SCRIPT: Script = preload("res://scenarios/water_flippers_scenario.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_initial_root_and_capabilities()
	_test_root_only_opening_rule()
	_test_capacity_from_room_c()
	_test_propped_path_and_branch_collapse()
	_test_health_flippers_and_gold()
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

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures.append("FAILED: %s" % description)

func _expect_equal(actual, expected, description: String) -> void:
	if actual != expected:
		failures.append("FAILED: %s (expected %s, got %s)" % [description, expected, actual])
