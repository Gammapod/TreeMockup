extends "res://tests/suite_reporter.gd"

# AP1 frontend boundary: supplied strike and copied clock snapshots are
# displayed without determining hits, ability legality, or action timings.
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var script = load("res://presentation/action_feedback.gd")
	if script == null:
		_expect(false, "Action feedback loads")
		_finish()
		return
	var view = script.new()
	root.add_child(view)
	var clocks := {
		"sword": {"available": true, "ready": false, "remaining": 0.5, "total": 2.0},
		"dash": {"available": true, "ready": true, "remaining": 0.0, "total": 0.0}
	}
	view.present_frame(Vector2(120, 80), true, clocks)
	clocks.sword.remaining = 0.0
	_expect(view.anchor == Vector2(120, 80) and view.avatar_present, "Frame uses the supplied room-local anchor and presence")
	_expect(view.clocks.sword.remaining == 0.5, "Frame copies supplied clocks")
	_expect(is_equal_approx(view.readiness_fraction("sword"), 0.75), "Ring fraction uses supplied action clock")
	_expect(view.readiness_fraction("dash") == 1.0, "Supplied ready status fills ring even before any clock")
	var arcs: Array = view.readiness_arcs()
	_expect(arcs.size() == 2 and arcs[0].radius == arcs[1].radius and arcs[0].end < 0 and arcs[1].start > 0, "Available sword and dash share a radius while occupying upper and lower arcs")
	view.present_frame(Vector2.ZERO, true, {"sword": {"available": false}, "dash": {"available": true, "ready": true}})
	arcs = view.readiness_arcs()
	_expect(arcs.size() == 1 and arcs[0].action == "dash", "Unavailable abilities have no readiness arc")
	view.present_frame(Vector2(5, 6), false, {"sword": {"available": false, "ready": false, "remaining": 0.0, "total": 0.0}})
	_expect(not view.avatar_present and view.readiness_fraction("sword") == 0.0 and view.readiness_fraction("dash") == 0.0, "Absent player and unavailable or missing clocks do not invent readiness")
	var strike := {"origin": Vector2(10, 20), "facing": Vector2.RIGHT, "reach": 80.0, "arc": PI / 2}
	view.present_strike(strike)
	view.present_strike(strike)
	strike.reach = 3.0
	_expect(view.strikes.size() == 2 and view.strikes[0].strike.reach == 80.0, "Separate emitted strikes are retained and supplied geometry is copied")
	view.advance(0.05)
	_expect(view.strikes.size() == 2, "Brief visual persists while presentation advances")
	view.advance(0.0)
	_expect(view.strikes[0].age == 0.05, "Zero elapsed presentation time freezes the visual")
	view.reset_room()
	_expect(view.strikes.is_empty() and not view.avatar_present, "Room change clears transients and anchor visibility")
	view.present_strike({"origin": Vector2.ZERO, "facing": Vector2.RIGHT, "reach": 20.0, "arc": 1.0})
	view.advance(1.0)
	_expect(view.strikes.is_empty(), "Presentation-only strike effect expires")
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
