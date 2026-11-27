extends "res://tests/suite_reporter.gd"

class Coordinator:
	extends Node
	signal phase_started(attempt)
	signal restriction_changed(state)
	signal phase_outcome(outcome)
	var frame := {"position": Vector2(40, 50), "present": true, "paused": false}
	func action_presentation_frame() -> Dictionary:
		return frame.duplicate(true)

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	# PHASE-FEEDBACK: display supplied events without deriving gameplay results.
	if not FileAccess.file_exists("res://presentation/phase_feedback.gd"):
		_expect(false, "Phase feedback presentation component exists")
		_complete(1)
		return
	var source := Coordinator.new()
	root.add_child(source)
	var feedback = load("res://presentation/phase_feedback.gd").new()
	root.add_child(feedback)
	feedback.bind_coordinator(source)
	feedback.bind_coordinator(source)
	_expect(feedback.message.text.is_empty(), "No events show no feedback")
	source.phase_started.emit({"phase": false})
	_expect(feedback.message.text.is_empty(), "Ordinary dash does not present phase transit")
	for state in [{"sword": 0.4, "dash": 0.0, "blocked": true}, {"sword": 0.0, "dash": 0.7, "blocked": true}, {"sword": 0.4, "dash": 0.7, "blocked": true}]:
		source.restriction_changed.emit(state)
		feedback._process(0.0)
		_expect(feedback.restricted and feedback.avatar_present and feedback.avatar_position == Vector2(40, 50), "Each supplied restriction uses the same avatar tether")
	source.frame.paused = true
	feedback._process(0.0)
	_expect(feedback.restricted and feedback.avatar_present, "Pause retains restriction and avatar cue")
	source.frame.present = false
	feedback._process(0.0)
	_expect(feedback.restricted and not feedback.avatar_present, "Absent avatar hides tether without changing restriction")
	source.frame.present = true
	source.phase_started.emit({"origin": Vector2(10, 20), "destination": Vector2(50, 20), "phase": true})
	feedback._process(10.0)
	_expect(feedback.message.text.is_empty(), "Phase transit adds no wordy message")
	source.phase_outcome.emit({"status": "returned", "reason": "blocked", "origin": Vector2(10, 20), "attempted": Vector2(50, 20), "position": Vector2(10, 20), "contact_damage": 2, "wave_damage": 0})
	_expect(feedback.attempted == Vector2(50, 20) and "returned" not in feedback.message.text.to_lower(), "Return marks the supplied attempted destination without coordinates")
	_expect("Contact damage" in feedback.message.text, "Reported contact damage is distinct from the failure")
	source.phase_outcome.emit({"status": "blocked_return", "reason": "blocked", "origin": Vector2(10, 20), "attempted": Vector2(50, 20), "position": null, "contact_damage": 0, "wave_damage": 0})
	_expect("Return blocked" in feedback.message.text and "damage" not in feedback.message.text.to_lower(), "Blocked return cue appears immediately without invented damage")
	source.phase_outcome.emit({"status": "landed", "attempted": Vector2(70, 20), "contact_damage": 0, "wave_damage": 3})
	_expect("Phase landed" not in feedback.message.text and "Wave damage" in feedback.message.text and feedback.attempted == null, "Successful landing reports supplied wave damage without a failure marker")
	source.restriction_changed.emit({"sword": 0.0, "dash": 0.0, "blocked": false})
	_expect(not feedback.restricted, "Authoritative restriction end clears cue")
	source.restriction_changed.emit({"blocked": true})
	feedback.reset_feedback()
	_expect(feedback.message.text.is_empty() and feedback.attempted == null and not feedback.restricted and not feedback.avatar_present, "Transition reset clears world-space feedback")
	feedback.queue_free()
	source.queue_free()
	await process_frame
	if failures.is_empty():
		_complete(0)
	else:
		for failure in failures:
			printerr("ASSERTION FAILED: " + failure)
		_complete(1)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
