extends Node2D

# Presentation only. The coordinator owns timing, outcomes, damage and room
# generation; this component never resolves actions or geometry.
var message: Label
var attempted: Variant = null
var restricted := false
var avatar_position := Vector2.ZERO
var avatar_present := false
var _message_lifetime := 0.0
var _coordinator: Object

func _ready() -> void:
	z_as_relative = false
	z_index = 100
	message = _make_label(Vector2(12, 12))
	set_process(true)

func _make_label(pos: Vector2) -> Label:
	var label := Label.new()
	label.position = pos
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
	return label

func bind_coordinator(source: Object) -> void:
	if is_instance_valid(_coordinator):
		for binding in _bindings():
			if _coordinator.is_connected(binding[0], binding[1]):
				_coordinator.disconnect(binding[0], binding[1])
	_coordinator = source
	if is_instance_valid(source):
		for binding in _bindings():
			if not source.is_connected(binding[0], binding[1]):
				source.connect(binding[0], binding[1])

func _bindings() -> Array:
	return [["phase_started", _on_phase_started], ["restriction_changed", _on_restriction_changed], ["phase_outcome", _on_phase_outcome]]

func _on_phase_started(attempt: Dictionary) -> void:
	if not attempt.get("phase", false):
		return
	attempted = null
	_message_lifetime = 0.0
	message.text = ""
	queue_redraw()

func _on_restriction_changed(state: Dictionary) -> void:
	restricted = state.get("blocked", false)
	queue_redraw()

func _on_phase_outcome(outcome: Dictionary) -> void:
	attempted = null
	var status: String = outcome.get("status", "")
	match status:
		"landed":
			message.text = ""
		"returned":
			message.text = ""
			attempted = outcome.get("attempted")
		"blocked_return":
			message.text = "Return blocked"
			attempted = outcome.get("attempted")
		_:
			message.text = ""
	for damage in [["contact_damage", "Contact damage"], ["wave_damage", "Wave damage"]]:
		var value: Variant = outcome.get(damage[0], 0)
		if (value is bool and value) or ((value is int or value is float) and value > 0):
			message.text += ("\n" if not message.text.is_empty() else "") + damage[1]
			if not value is bool:
				message.text += ": " + str(value)
	_message_lifetime = 2.0
	queue_redraw()

func _process(delta: float) -> void:
	if is_instance_valid(_coordinator) and _coordinator.has_method("action_presentation_frame"):
		var frame: Dictionary = _coordinator.action_presentation_frame()
		avatar_present = frame.get("present", false) and frame.get("position") is Vector2
		if avatar_present:
			avatar_position = frame.position
		queue_redraw()
	# The short display lifetime is visual only; no gameplay state is inferred.
	if _message_lifetime > 0.0:
		_message_lifetime -= delta
		if _message_lifetime <= 0.0:
			message.text = ""
			attempted = null
			queue_redraw()

func _draw() -> void:
	if restricted and avatar_present:
		# Inside the readiness arcs: a short tether and small ground anchor.
		var foot := avatar_position + Vector2(0, 12)
		draw_line(foot, foot + Vector2(0, 5), Color.BLACK, 4.0, true)
		draw_line(foot, foot + Vector2(0, 5), Color.WHITE, 2.0, true)
		draw_line(foot + Vector2(-5, 6), foot + Vector2(5, 6), Color.BLACK, 4.0, true)
		draw_line(foot + Vector2(-5, 6), foot + Vector2(5, 6), Color.WHITE, 2.0, true)
	if attempted is Vector2:
		draw_arc(attempted, 13.0, 0.0, TAU, 32, Color.WHITE, 3.0)
		draw_line(attempted + Vector2(-8, -8), attempted + Vector2(8, 8), Color.WHITE, 3.0)
		draw_line(attempted + Vector2(-8, 8), attempted + Vector2(8, -8), Color.WHITE, 3.0)

func reset_feedback() -> void:
	attempted = null
	_message_lifetime = 0.0
	message.text = ""
	restricted = false
	avatar_present = false
	queue_redraw()
