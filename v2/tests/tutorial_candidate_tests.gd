extends "res://tests/suite_reporter.gd"

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var loaded: Dictionary = load("res://authoring/content_store.gd").new().load_document("res://examples/tutorial_candidate.json")
	_expect(loaded.ok, "Candidate validates: " + str(loaded.get("errors", [])))
	if not loaded.ok:
		_finish()
		return
	var result: Dictionary = load("res://authoring/runtime_adapter.gd").new().compile(loaded.document)
	_expect(result.ok, "Candidate compiles: " + str(result.errors))
	if not result.ok:
		_finish()
		return
	var game = load("res://main.tscn").instantiate()
	game.data_override = result.data
	root.add_child(game)
	await process_frame
	_expect(game.room.player.hp == 1 and game.progression.available_points() == 1, "Starts at 1 HP and one point")
	game._toggle("key_store")
	_expect(game.room.player.hp == 1 and game.room.player.max_hp == 5 and game.progression.available_points() == 0, "Storage costs one, raises max by four without healing")
	game._enter_room("key_store", "", 1)
	game.room.set_physics_process(false)
	game.room.player.set_physics_process(false)
	_expect(not game.room.player.start_attack(), "Switch cannot be struck before sword allocation")
	game.room.player.position = Vector2(300, 250)
	game.room._physics_process(0.0)
	_expect(game.progression.capacity == 2 and game.progression.available_points() == 1, "Storage pickup funds sword")
	game.room.player.position = Vector2(300, 380)
	game.room._physics_process(0.0)
	_expect(game.room.player.hp == 5 and game.progression.collected.has("key_store/medicine"), "Medicine restores four")
	game._toggle("sword")
	_expect(game.progression.active.has("sword") and game.progression.available_points() == 0, "Sword costs second point")
	await physics_frame
	_expect(not _can_reach_opening(game.room), "Closed storage wall cannot be bypassed through physical room geometry")
	game.room.player.position = Vector2(650, 320)
	var blocked: KinematicCollision2D = game.room.player.move_and_collide(Vector2(120, 0))
	_expect(blocked != null and game.room.player.position.x < 690, "Player collision body is stopped by closed wall")
	game.room.player.position = Vector2(500, 260)
	game.room.player.facing = Vector2.RIGHT
	_expect(game.room.player.start_attack(), "Sword starts at switch")
	game.room.player.advance_attack(0.15)
	_expect(game.room.object_states.get("wall_1", false), "Actual sword attack toggles switch and opens gate")
	await physics_frame
	_expect(_can_reach_opening(game.room), "Open storage gate permits physical route to doorway")
	var approach: KinematicCollision2D = game.room.player.move_and_collide(Vector2(140, 60))
	var crossing: KinematicCollision2D = game.room.player.move_and_collide(Vector2(130, 0))
	_expect(approach == null and crossing == null and game.room.player.position.x >= 765, "Player collision body physically crosses opened doorway")
	game.room._physics_process(0.0)
	await process_frame
	await process_frame
	_expect(game.current == "sword", "Crossing opened doorway enters sword encounter")
	if game.current != "sword":
		game.queue_free()
		await process_frame
		_finish()
		return
	_expect(game.room.enemies.size() == 2 and game.room.pickups.is_empty(), "Two bats guard hidden capacity")
	for enemy in game.room.enemies.duplicate():
		game.room._attack(enemy.body.position - Vector2(50, 0), Vector2.RIGHT, 92, 1, 1.8)
	_expect(game.progression.cleared.has("sword") and game.room.pickups.size() == 1, "Defeating both reveals reward")
	game.room.player.position = Vector2(400, 300)
	game.room._physics_process(0.0)
	_expect(game.progression.capacity == 3 and game.progression.available_points() == 1, "Trial reward funds one branch")
	game._toggle("dash")
	_expect(game.progression.active.has("dash") and not game.progression.preview_activation("flippers", "sword").ok, "Budget allows one branch at a time")
	game._toggle("dash")
	game._toggle("flippers")
	_expect(game.progression.active.has("flippers") and not game.progression.active.has("dash"), "Refund allows alternate branch")
	game._enter_room("key_store", "", 1)
	game._toggle("sword")
	_expect(not game.progression.active.has("sword") and not game.progression.active.has("flippers") and game.progression.available_points() == 2, "Sword refund cascades and returns both points")
	game.room.player.hp = 1
	game.room.player.invulnerability = 0
	if game.room.player.hurt() and game.room.player.hp == 0:
		game._defeat()
	await process_frame
	await process_frame
	_expect(game.current == "start" and game.room.player.hp == 5 and game.progression.collected.has("key_store/medicine"), "Defeat returns to root with full active-build HP and collected medicine remains spent")
	game._enter_room("key_store", "", game.room.player.hp)
	_expect(game.room.object_states.get("wall_1", false) and not game.room.pickups.any(func(item): return item.id == "medicine"), "Opened gate and spent medicine persist after defeat")
	game._enter_room("start", "", game.room.player.hp)
	game._toggle("key_store")
	_expect(game.room.player.hp == 1 and game.room.player.max_hp == 1, "Refund clamps HP")
	game._toggle("key_store")
	_expect(game.room.player.hp == 1 and game.room.player.max_hp == 5, "Reallocation does not heal after medicine is spent")
	game.queue_free()
	await process_frame
	_finish()

# Sample actual physics colliders using the player radius, then flood-fill
# traversable positions on a five-unit grid. The gate's smallest claimed
# bypass would have to fit a 26-unit-wide player, not merely a point.
func _can_reach_opening(room) -> bool:
	var shape := CircleShape2D.new()
	shape.radius = 13.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 1
	var state: PhysicsDirectSpaceState2D = room.get_world_2d().direct_space_state
	var free: Dictionary = {}
	for x in range(50, 791, 5):
		for y in range(70, 571, 5):
			var p := Vector2i(x, y)
			query.transform = Transform2D(0, Vector2(p))
			if state.intersect_shape(query, 1).is_empty():
				free[p] = true
	var queue: Array[Vector2i] = [Vector2i(400, 400)]
	var seen := {Vector2i(400, 400): true}
	var index := 0
	while index < queue.size():
		var p: Vector2i = queue[index]
		index += 1
		if p.x >= 765 and p.y >= 295 and p.y <= 345:
			return true
		for d in [Vector2i(5, 0), Vector2i(-5, 0), Vector2i(0, 5), Vector2i(0, -5)]:
			var next: Vector2i = p + d
			if free.has(next) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	return false

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("Tutorial candidate checks passed.")
		_complete(0)
	else:
		for failure in failures:
			printerr("ASSERTION FAILED: " + failure)
		_complete(1)
