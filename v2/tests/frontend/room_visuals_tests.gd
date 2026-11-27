extends "res://tests/suite_reporter.gd"

# RP1 frontend boundary: badges use only currently supplied visible rewards
# and tokens; refresh replaces rather than accumulating old room contents.
class Source extends RefCounted:
	signal action_room_changed(generation: int)
	var snapshot: Dictionary = {}
	func room_presentation_state() -> Dictionary:
		return snapshot.duplicate(true)

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var script = load("res://presentation/room_feedback.gd")
	if script == null:
		_expect(false, "Room badge presenter loads")
		_finish()
		return
	var view = script.new()
	root.add_child(view)
	var source := Source.new()
	source.snapshot = {"generation": 1, "pickups": [
		{"id": "medicine", "position": Vector2(100, 150), "kind": "health", "value": 3, "chest": false},
		{"id": "treasure", "position": Vector2(200, 250), "kind": "gold", "value": 2, "chest": false},
		{"id": "hidden", "position": Vector2(400, 250), "kind": "capacity", "chest": true},
		{"id": "ambiguous", "position": Vector2(450, 250), "kind": "gold"}
	], "tokens": [{"id": "objective", "position": Vector2(300, 350)}]}
	view.bind_coordinator(source)
	view.refresh_snapshot()
	source.action_room_changed.emit(2)
	_expect(view.badges().is_empty(), "Room change immediately clears old-room presentation before another process tick")
	view.refresh_snapshot()
	_expect(view.badges().is_empty(), "Polling cannot restore a stale generation after room change")
	source.snapshot.generation = 2
	view.refresh_snapshot()
	var badges: Array = view.badges()
	_expect(badges.size() == 1 and badges[0].icon == "gold", "Only explicitly loose gold and capacity receive pickup art; chests and ambiguous objects do not reveal rewards")
	_expect(badges[0].position == Vector2(200, 250), "Pickup art is centered at the supplied room-local position")
	source.snapshot.pickups.clear()
	source.snapshot.tokens.clear()
	_expect(view.badges().size() == 1, "Presentation retains a detached snapshot until refreshed")
	view.refresh_snapshot()
	_expect(view.badges().is_empty(), "Collected or hidden objects disappear on refresh")
	source.snapshot = {"generation": 2, "pickups": [{"id": "key", "position": Vector2(30, 40), "kind": "capacity", "chest": false}], "tokens": []}
	view.refresh_snapshot()
	_expect(view.badges().size() == 1 and view.badges()[0].icon == "capacity", "Room replacement cannot retain prior badges")
	source.snapshot = {
		"generation": 3,
		"objects": [{"kind": "water", "bounds": Rect2(10, 20, 200, 120), "passable": true}, {"kind": "wall", "bounds": Rect2(20, 30, 160, 100), "passable": false}, {"kind": "wall", "bounds": Rect2(30, 40, 200, 100), "passable": true}],
		"obstacles": [Rect2(40, 50, 180, 110), Rect2(20, 10, 10, 10)],
		"enemies": [
			{"id": "guard", "position": Vector2(200, 300), "radius": 20, "behavior": "roost_guardian", "contact_dangerous": false},
			{"id": "chaser", "position": Vector2(100, 150), "radius": 12, "behavior": "chase", "contact_dangerous": true},
			{"id": "unknown", "position": Vector2(20, 30), "radius": 12, "behavior": "other"}
		]
	}
	view.refresh_snapshot()
	var terrain: Array = view.terrain_labels()
	_expect(terrain.size() == 4 and terrain[0].text == "Water" and terrain[1].text == "Wall" and terrain[2].text == "Wall (open)" and terrain[3].text == "Obstacle", "Terrain labels use explicit kinds and distinguish an open wall")
	var enemies: Array = view.enemy_markers()
	_expect(enemies.size() == 3 and enemies[0].danger == false and enemies[1].danger == true and enemies[2].danger == null, "Enemy contact markers preserve supplied danger and unknown state")
	_expect(enemies[0].color != enemies[1].color and enemies[2].color != enemies[0].color and enemies[2].color != enemies[1].color, "Contact danger, non-danger and unknown have distinct colors")
	source.snapshot = {}
	view.refresh_snapshot()
	_expect(view.badges().is_empty(), "No room clears all badges")
	source.snapshot = {"obstacles": [Rect2(10, 10, 200, 120)], "objects": [
		{"kind": "water", "bounds": Rect2(20, 80, 200, 120), "passable": true},
		{"kind": "wall", "bounds": Rect2(20, 150, 200, 120), "passable": false}
	], "enemies": [
		{"behavior": "chase", "position": Vector2(300, 200), "radius": 20, "contact_dangerous": true},
		{"behavior": "roost_guardian", "position": Vector2(500, 200), "radius": 38, "contact_dangerous": false}
	]}
	view.refresh_snapshot()
	var labels: Array = view.labels()
	_expect(labels.size() == 3, "Only supplied geometry has supplemental text labels")
	_expect(labels[0].text == "Water" and labels[1].text == "Wall" and labels[2].text == "Obstacle", "Geometry labels use supplied kinds")
	var replacement := Source.new()
	replacement.snapshot = {"pickups": [{"kind": "capacity", "position": Vector2(1, 2), "chest": false}]}
	view.bind_coordinator(replacement)
	source.action_room_changed.emit(4)
	_expect(view.badges().size() == 1, "A previously bound source cannot clear the current room")
	replacement.action_room_changed.emit(4)
	_expect(view.badges().is_empty(), "The current source clears presentation after rebinding")
	replacement.snapshot.generation = 5
	replacement.action_room_changed.emit(5)
	_expect(view.badges().size() == 1, "A matching new-room snapshot is presented immediately")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	_expect(game.has_signal("action_room_changed"), "Coordinator exposes the room-change notification")
	view.bind_coordinator(game)
	_expect(game.is_connected("action_room_changed", view._on_room_changed), "Presenter subscribes to the coordinator notification")
	game.queue_free()
	view.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	for failure in failures:
		printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
