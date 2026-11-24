extends "res://tests/suite_reporter.gd"

# UAB4: Room resolves Phase geometry without crossing boundaries; resolution
# observes current wall/water state and does not mutate player or run state.
# UAB5: coordinator supplies a copied current build independently of previews.
const ROOM = preload("res://room.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var room = ROOM.new()
	root.add_child(room)
	room.set_physics_process(false)
	var template := {
		"obstacles": [Rect2(440, 250, 20, 100)],
		"objects": [
			{"id":"gate", "kind":"wall", "bounds":Rect2(480,250,10,100)},
			{"id":"water", "kind":"water", "bounds":Rect2(550,250,100,100)}
		],
		"pickups": [], "enemies": []
	}
	room.configure(template, [], {}, {}, "", {"abilities": {}, "max_hp": 5}, 5)
	room.player.set_physics_process(false)
	if not room.has_method("resolve_phase_geometry"):
		_expect(false, "Room exposes authoritative Phase geometry resolution")
	else:
		var start := Vector2(400, 300)
		var result: Dictionary = room.resolve_phase_geometry(start, Vector2(510, 300))
		_expect(result.status == "landed" and result.position == Vector2(510,300), "crosses multiple interior obstacles")
		_expect(room.player.position != result.position, "geometry resolution is informational and does not move player")
		result = room.resolve_phase_geometry(start, Vector2(450,300))
		_expect(result.status == "returned" and result.position == start, "blocked destination returns to origin")
		_expect(room.resolve_phase_geometry(start, Vector2(426.98,300)).status == "landed", "outside collision margin is valid")
		_expect(room.resolve_phase_geometry(start, Vector2(426.995,300)).status == "returned", "near tangency within margin is invalid")
		room.player.get_child(0).shape.radius = 20.0
		_expect(room.resolve_phase_geometry(start, Vector2(421,300)).status == "returned", "destination uses actual player collision shape")
		room.player.get_child(0).shape.radius = 13.0
		result = room.resolve_phase_geometry(start, Vector2(800,300))
		_expect(result.status == "returned" and result.reason == "boundary", "room boundary blocks Phase")
		room.set_portals([{"destination":"other", "port":"north", "entry":"south", "enabled":true}])
		result = room.resolve_phase_geometry(Vector2(400,100), Vector2(400,40))
		_expect(result.status == "returned" and result.reason == "boundary", "open door never permits Phase to cross boundary")
		result = room.resolve_phase_geometry(start, Vector2(565,300))
		_expect(result.status == "returned", "water landing requires passage")
		room.player.capabilities.abilities["flippers"] = true
		result = room.resolve_phase_geometry(start, Vector2(565,300))
		_expect(result.status == "landed", "water landing works with current passage")
		room.player.capabilities = {"model":"unified_1", "qualities":{"water_pass":{"effective":false}}}
		_expect(room.resolve_phase_geometry(start, Vector2(565,300)).status == "returned", "unified water passage is checked at resolution")
		room.player.capabilities.qualities.water_pass.effective = true
		_expect(room.resolve_phase_geometry(start, Vector2(565,300)).status == "landed", "unified effective passage permits landing")
		room.player.capabilities = {"abilities":{"flippers":true}}
		room.apply_object_states({"gate":true})
		result = room.resolve_phase_geometry(start, Vector2(485,300))
		_expect(result.status == "landed", "current open wall is passable")
		room.apply_object_states({"gate":false})
		result = room.resolve_phase_geometry(start, Vector2(485,300))
		_expect(result.status == "returned", "closed wall is impassable")
		room.obstacles.append(Rect2(390, 290, 20, 20))
		result = room.resolve_phase_geometry(start, Vector2(450,300))
		_expect(result.status == "blocked_return", "invalid destination and origin distinguish defeat outcome")
	room.queue_free()
	await process_frame
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_expect(game.tree_ui.snapshot.has("current_build"), "coordinator supplies current build independent of preview")
	if game.tree_ui.snapshot.has("current_build"):
		_expect(game.tree_ui.snapshot.current_build == game.progression.capabilities(), "current build matches progression")
		game.tree_ui.snapshot.current_build["injected"] = true
		_expect(not game.progression.capabilities().has("injected"), "presentation copy cannot mutate progression build")
	game.queue_free()
	await process_frame
	for failure in failures:
		printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
