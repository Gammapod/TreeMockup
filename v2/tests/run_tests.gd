extends SceneTree

const CONTENT = preload("res://tests/fixtures/activation_fixture.gd")
const MODEL = preload("res://progression.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var data := CONTENT.create()
	var model = MODEL.new(data)
	_expect(not model.activate("sword_landing", "start").ok, "Remote activation is rejected")
	_expect(model.activate("sword", "start").ok, "Local activation succeeds")
	_expect(model.available_points() == 3, "Activation allocates one point")
	_expect(not model.activate("sword", "start").ok and model.available_points() == 3, "Repeated activation cannot charge twice")
	_expect(model.capabilities().abilities.has("sword"), "Capabilities derive from active nodes")
	_expect(not model.deactivate("sword", "sword").ok, "Cannot deactivate occupied room")
	_expect(model.collect("sword", "capacity"), "Room reward collected")
	_expect(not model.collect("sword", "capacity"), "Reward is collected only once")
	_expect(model.deactivate("sword", "start").ok, "Local deactivation succeeds")
	_expect(model.available_points() == 5, "Refund preserves permanently earned capacity")
	_expect(not model.capabilities().abilities.has("sword"), "Deactivation removes capability")
	_expect(model.activate("sword", "start").ok, "Reactivation succeeds")
	_expect(not model.collect("sword", "capacity"), "Reactivation does not duplicate reward")
	model.activate("sword_landing", "sword")
	_expect(not model.activate("prize", "sword_landing").ok, "ALL prerequisite requires both branches")
	model.activate("boots", "start")
	model.activate("boots_landing", "boots")
	_expect(model.activate("prize", "sword_landing").ok, "Prize activates once both landings are active")
	_expect(model.available_points() == 0, "Two Prize entrances charge for one room")
	_expect(model.can_travel("prize", "boots_landing"), "Activation direction does not restrict return travel")
	var before: Dictionary = model.active.duplicate()
	var preview: Dictionary = model.preview_deactivation("sword_landing", "prize")
	_expect(not preview.ok and preview.reason == "would_strand_player", "Cascade cannot remove occupied Prize")
	_expect(model.active == before, "Preview is side-effect free")
	_expect(not model.deactivate("sword_landing", "prize").ok and model.active == before, "Rejected transaction is atomic")
	var result: Dictionary = model.deactivate("sword_landing", "sword")
	_expect(result.ok and "prize" in result.affected, "Removing either landing cascades to Prize")
	_expect(model.available_points() == 2, "Cascade refunds all affected rooms")
	_expect(model.active.has("boots_landing"), "Unrelated branch survives cascade")
	# ANY-parent merge survives losing one support when another travel path remains.
	data = CONTENT.create()
	data.nodes.prize.requires_all = []
	data.nodes.prize.requires_any = ["sword_landing", "boots_landing"]
	model = MODEL.new(data)
	model.capacity = 10
	model.activate("sword", "start")
	model.activate("boots", "start")
	model.activate("sword_landing", "sword")
	model.activate("boots_landing", "boots")
	model.activate("prize", "sword_landing")
	model.deactivate("sword_landing", "sword")
	_expect(model.active.has("prize"), "ANY merge retains alternate support")
	model.deactivate("boots_landing", "boots")
	_expect(not model.active.has("prize"), "ANY merge deactivates when final support disappears")
	data = CONTENT.create()
	data.nodes.sword.exclusive_group = "choice"
	data.nodes.boots.exclusive_group = "choice"
	model = MODEL.new(data)
	model.activate("sword", "start")
	_expect(model.preview_activation("boots", "start").reason == "exclusive_choice", "Exclusive node choices are enforced")
	# Integration smoke: load scenes, transition, propagate capabilities, persist rewards.
	var game = load("res://main.tscn").instantiate()
	game.data_override = CONTENT.create()
	root.add_child(game)
	await process_frame
	game._toggle("sword")
	_expect(game.room.player.capabilities.abilities.has("sword"), "Coordinator supplies capability snapshot")
	game._request_travel("sword", "east")
	await process_frame
	_expect(game.current == "sword" and game.room.enemies.size() == 1, "Door transition instantiates room template")
	game._collect("capacity")
	game._request_travel("start", "west")
	await process_frame
	game._toggle("sword")
	game._toggle("sword")
	game._request_travel("sword", "east")
	await process_frame
	_expect(game.room.pickups.is_empty(), "Template instance filters persistent rewards")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("All V2 progression and room integration tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
