extends "res://tests/suite_reporter.gd"

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	for dimensions in [Vector2i(960, 640), Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(960, 1000)]:
		root.size = dimensions
		for frame in range(5):
			await process_frame
		var shell = game.shell
		_expect(shell.size.is_equal_approx(Vector2(dimensions)), "Shell fills window at %s" % dimensions)
		var bounds := Rect2(Vector2.ZERO, Vector2(dimensions))
		_expect(bounds.encloses(shell.hud.get_global_rect()), "HUD fits at %s" % dimensions)
		_expect(bounds.encloses(shell.status.get_global_rect()), "Status fits at %s" % dimensions)
		_expect(bounds.encloses(game.tree_ui.get_global_rect()), "Map fits at %s" % dimensions)
		_expect(not shell.room_display.get_global_rect().intersects(game.tree_ui.get_global_rect()), "Room and map regions do not overlap at %s" % dimensions)
		_expect(game.tree_ui.gameplay_map.size.x > 250 and game.tree_ui.gameplay_map.size.y > 200, "Map retains usable area at %s" % dimensions)
		_expect(shell.room_viewport.size == Vector2i(800, 600), "Room coordinates stay fixed at %s" % dimensions)
	var old_width: float = game.tree_ui.size.x
	game.shell.split.split_offset += 100
	for frame in range(5):
		await process_frame
	_expect(game.tree_ui.size.x < old_width - 50, "Divider changes map allocation")
	# Real root input must reach the room even with the map tab selected.
	game._toggle("sword")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	root.push_input(key)
	_expect(game.room.player.attack_time > 0, "Unhandled attack input reaches room viewport")
	game.room.player.attack_time = 0
	game.room.player.attack_cooldown = 0
	game._open_studio()
	root.push_input(key)
	_expect(game.room.player.attack_time == 0, "Editor blocks gameplay input")
	game._close_studio()
	# Crossing a linked boundary uses the same coordinator path; E remains for
	# deliberate object interactions.
	for portal in game.room.portals:
		if portal.destination == "sword":
			game.room.player.position = game.room.ports[portal.port] + Vector2.LEFT * 40
	game.room._physics_process(0.0)
	await process_frame
	await process_frame
	_expect(game.current == "sword", "Walking through an enabled doorway transitions rooms")
	_expect(game.room.get_viewport() == game.shell.room_viewport, "Transitions retain the room viewport")
	game.room._physics_process(0.0)
	_expect(game.current == "sword", "Arrival inside a paired doorway does not immediately bounce back")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("All responsive shell and input boundary tests passed.")
		_complete(0)
	else:
		for failure in failures:
			printerr("ASSERTION FAILED: " + failure)
		_complete(1)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
