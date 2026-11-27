extends "res://tests/suite_reporter.gd"

# Icon specification: known semantic IDs resolve to distinct drawable symbols;
# unknown IDs resolve to a neutral symbol. Callers cannot mutate shared assets.
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var icons = load("res://presentation/icons.gd")
	var review = load("res://presentation/icon_review.gd")
	_expect(review != null, "Standalone visual review script loads")
	if review != null:
		var canvas = review.get_script_constant_map()["ReviewCanvas"].new()
		root.add_child(canvas)
		await process_frame
		canvas.queue_free()
	if icons == null:
		_expect(false, "Icon presentation registry loads")
		_finish()
		return
	var ids := ["sword", "boots", "health", "gold", "capacity", "token", "neutral"]
	_expect(icons.IDS == ids, "Picker registry covers every standard icon")
	var symbols: Array = []
	for id in ids:
		_expect(icons.resolve_id(id) == id, "Known icon resolves without substitution: " + id)
		var strokes: Array = icons.strokes(id)
		_expect(not strokes.is_empty(), id + " has a drawable symbol")
		_expect(not symbols.has(strokes), id + " has a distinct symbol")
		symbols.append(strokes)
		for stroke in strokes:
			_expect(stroke.size() >= 2, id + " stroke has at least two points")
			for point in stroke:
				_expect(point.x >= 0.0 and point.x <= 1.0 and point.y >= 0.0 and point.y <= 1.0, id + " stays within its viewbox")
	_expect(icons.strokes("unknown") == icons.strokes("neutral"), "Unknown ID uses neutral fallback")
	for value in [null, 1, {}, [], "unknown", ""]:
		_expect(icons.resolve_id(value) == "neutral", "Nonstandard icon values resolve safely")
	_expect(icons.strokes("") == icons.strokes("neutral"), "Empty ID uses neutral fallback")
	var changed: Array = icons.strokes("sword")
	changed[0].clear()
	_expect(not icons.strokes("sword")[0].is_empty(), "Consumers cannot mutate nested strokes")
	changed.clear()
	_expect(not icons.strokes("sword").is_empty(), "Consumers cannot mutate registry assets")
	_finish()

func _finish() -> void:
	for failure in failures:
		printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
