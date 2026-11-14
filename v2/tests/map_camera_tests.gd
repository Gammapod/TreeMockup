extends SceneTree

# UI-CAMERA: authored coordinate range must not reverse wheel zoom or defeat fit.
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var map = load("res://gameplay_map.gd").new()
	root.add_child(map)
	map.size = Vector2(500, 400)
	map.set_definition({
		"nodes": {
			"a": {"name": "A", "cost": 0, "map_position": Vector2(-100000, -100000)},
			"b": {"name": "B", "cost": 1, "map_position": Vector2(100000, 100000)}
		},
		"links": [{"a": "a", "b": "b"}]
	})
	map.fit_graph()
	var bounds := Rect2(Vector2.ZERO, map.size).grow(-25)
	_expect(bounds.has_point(map._screen("a")) and bounds.has_point(map._screen("b")), "Fit graph includes widely spaced authored positions")
	map.frame_neighborhood("a")
	var before: float = map.zoom
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	wheel.position = Vector2(170, 100)
	var anchor: Vector2 = (wheel.position - map.offset) / map.zoom
	map._gui_input(wheel)
	_expect(map.zoom < before, "Zoom out never zooms in after neighborhood framing")
	_expect((anchor * map.zoom + map.offset).is_equal_approx(wheel.position), "Wheel zoom preserves the world point under the cursor")
	map.queue_free()
	await process_frame
	if failures.is_empty():
		print("All map camera boundary tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
