extends "res://tests/suite_reporter.gd"

# B1: Mermaid topology/content and a funded route to Prize.
# B2: ongoing ANY/ALL requirements, exclusive styles, and refunds.
# B3: legacy combat variants; BUILD-01 HP allocations never heal.
const CONTENT = preload("res://content.gd")
const MODEL = preload("res://progression.gd")
const PLAYER = preload("res://player.gd")
var failures: Array[String] = []
var hits: Array = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var data := CONTENT.create()
	_expect(data.nodes.size() == 14 and data.links.size() == 18, "B1: 14 rooms and 18 connections from Mermaid")
	_expect(data.initial_capacity == 1, "B1: one starting allocation point")
	if data.nodes.size() != 14:
		_finish()
		return
	var model = MODEL.new(data)
	_expect(model.capabilities().max_hp == 1, "B3: Start grants one initial HP")
	for branch in ["sword", "boots"]:
		_expect(model.activate(branch, "start").ok, "B1: affordable branch " + branch)
		_expect(model.collect(branch, "capacity") and model.collect(branch, "capacity_2"), "B1: two keys in " + branch)
		var style := "big_swing" if branch == "sword" else "hit_dash"
		_expect(model.activate(style, branch).ok, "B1: affordable style " + style)
		var landing: String = branch + "_landing"
		_expect(model.activate(landing, style).ok, "B2: ANY style supports landing")
		_expect(model.collect(landing, "capacity"), "B1: landing grants key")
	_expect(model.activate("prize", "sword_landing").ok and model.available_points() == 0, "B1: six keys fund seven active non-root nodes")
	_expect(model.preview_deactivation("sword_landing", "prize").reason == "would_strand_player", "B2: Prize occupancy protects both prerequisites")
	var result: Dictionary = model.deactivate("big_swing", "sword")
	_expect(result.ok and "sword_landing" in result.affected and "prize" in result.affected, "B2: style removal cascades through landing and Prize")
	_expect(model.available_points() == 3, "B2: cascade refunds all three rooms")
	model.activate("fast_swing", "sword")
	_expect(model.preview_activation("neutral_swing", "sword").reason == "exclusive_choice", "B2: styles are mutually exclusive")
	model.activate("sword_landing", "fast_swing")
	_expect(model.activate("prize", "sword_landing").ok, "B2: alternate style restores landing and Prize")
	for pair in [["sword_practice", 1], ["boots_practice", 1], ["big_swing", 10], ["hit_dash", 10], ["neutral_swing", 3], ["neutral_dash", 3]]:
		_expect(data.templates[data.nodes[pair[0]].template].enemies.size() == pair[1], "B1: enemy count in " + pair[0])
	var giant: Dictionary = data.templates[data.nodes.fast_swing.template].enemies[0]
	_expect(giant.hp == 3 and giant.radius == 28, "B3: big bat is double-sized with three HP")
	var player = PLAYER.new()
	player.set_capabilities({"max_hp": 1, "abilities": {}})
	player.hp = 1
	player.set_capabilities({"max_hp": 6, "abilities": {}})
	_expect(player.hp == 1 and player.max_hp == 6, "BUILD-01: activation raises maximum HP without healing")
	player.hp = 4
	player.set_capabilities({"max_hp": 6, "abilities": {}})
	_expect(player.hp == 4, "B3: refresh does not heal")
	player.set_capabilities({"max_hp": 1, "abilities": {}})
	_expect(player.hp == 1, "B3: removal clamps current HP")
	player.attack.connect(func(_origin, _facing, reach, _damage, _arc): hits.append(reach))
	player.set_capabilities(model.capabilities())
	_expect(player.start_attack(), "B3: fast sword starts")
	# Action keeps its captured parameters after the build changes.
	player.set_capabilities({"abilities": {}, "max_hp": 1})
	player.advance_attack(0.5)
	_expect(hits.size() == 3 and is_equal_approx(hits[0], 46.0), "B3: fast sword makes three half-range strikes")
	model.deactivate("fast_swing", "sword")
	model.activate("big_swing", "sword")
	player.set_capabilities(model.capabilities())
	player.attack_cooldown = 0
	hits.clear()
	player.start_attack()
	player.advance_attack(0.4)
	_expect(hits.size() == 1 and is_equal_approx(hits[0], 138.0) and not player.start_attack(), "B3: big sword has 1.5x range and cooldown")
	player.advance_attack(1.6)
	_expect(player.start_attack(), "B3: big sword becomes available after two seconds")
	_expect(player.start_dash() and is_equal_approx(player.dash_time, 0.104), "BUILD-01: phase dash retains 65% distance at fixed speed")
	player.invulnerability = 0
	_expect(not player.hurt(), "B3: phase dash bypasses enemy contact damage")
	player.dash_time = 0
	_expect(player.hurt(), "B3: phase protection ends with dash")
	model.deactivate("hit_dash", "boots")
	model.activate("run", "boots")
	player.set_capabilities(model.capabilities())
	player.dash_cooldown = 0
	_expect(not player.start_dash(), "B3: sprint replaces dash")
	_expect(is_equal_approx(player.movement_speed(true), 440.0) and is_equal_approx(player.movement_speed(false), 220.0), "B3: held sprint doubles speed")
	player.free()
	# Health changes must be applied once by the coordinator, not on room loads.
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_expect(game.room.player.hp == 1 and game.room.player.max_hp == 1, "B3: authored initial health reaches gameplay")
	game._toggle("sword")
	game._enter_room("sword", "east", 1)
	game._collect("capacity")
	game._collect("capacity_2")
	game._toggle("sword_practice")
	_expect(game.room.player.hp == 1 and game.room.player.max_hp == 2, "BUILD-01: loaded-room HP allocation does not heal")
	game.room.player.hp = 1
	game._enter_room("start", "west", 1)
	game._enter_room("sword", "east", 1)
	_expect(game.room.player.hp == 1 and game.room.player.max_hp == 2, "B3: room transitions preserve damage")
	game._toggle("fast_swing")
	game._enter_room("fast_swing", "south", 1)
	_expect(game.room.enemies[0].body.get_child(0).shape.radius == 28 and game.room.enemies[0].hp == 3, "B3: big bat size and HP reach runtime physics")
	game.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition: failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("All branching design tests passed.")
		_complete(0)
	else:
		for failure in failures: printerr("ASSERTION FAILED: " + failure)
		_complete(1)
