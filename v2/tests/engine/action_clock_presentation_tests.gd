extends "res://tests/suite_reporter.gd"

# AP1: action presentation follows actual action clocks and emitted strikes.
const PLAYER = preload("res://player.gd")
const BUILD = preload("res://runtime/unified_build.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _caps(phase: bool) -> Dictionary:
	var entries := [{"id":"s", "kind":"quality", "quality":"sword"}, {"id":"d", "kind":"quality", "quality":"dash"}]
	if phase:
		entries.append({"id":"p", "kind":"quality", "quality":"phase_teleport"})
	return BUILD.compose({"nodes":{"root":{"contributions":entries}}}, {"root":true})

func _run() -> void:
	# AP1 architecture: only emitted room-local strikes are drawn by the
	# presenter; Player must not also draw its former avatar-relative sector.
	var player_source := FileAccess.get_file_as_string("res://player.gd")
	var draw_start := player_source.find("func _draw() -> void:")
	var draw_source := player_source.substr(draw_start) if draw_start >= 0 else ""
	_expect(draw_start >= 0 and "draw_circle" in draw_source and "attack_snapshot" not in draw_source and "sword_range" not in draw_source, "Player retains avatar drawing without a duplicate legacy sword sector")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var p = game.room.player
	p.set_physics_process(false)
	_expect(game.get("action_feedback") != null and game.action_feedback.get_parent() == game.shell.room_viewport, "AP1: coordinator mounts frontend action feedback")
	if not game.has_method("mount_action_presentation") or not game.has_method("action_presentation_frame"):
		_expect(false, "AP1: room-aligned mount and frame API exists")
	else:
		var overlay := Node2D.new()
		game.mount_action_presentation(overlay)
		p.position = Vector2(123, 234)
		var frame: Dictionary = game.action_presentation_frame()
		_expect(overlay.get_parent() == game.shell.room_viewport and overlay.transform == Transform2D.IDENTITY and overlay.z_index > 0 and frame.position == p.position and frame.present and not frame.phase_absent and not frame.paused, "overlay and anchor share room coordinates above room")
		frame.actions.sword.total = 12345
		_expect(game.action_presentation_frame().actions.sword.total != 12345, "frame action state detached")
		p.set_capabilities(_caps(true))
		_expect(p.start_dash(), "Phase starts for anchor test")
		frame = game.action_presentation_frame()
		_expect(not frame.present and frame.phase_absent, "Phase suppresses presence")
		var remaining: float = frame.actions.dash.remaining
		game.room.process_mode = Node.PROCESS_MODE_DISABLED
		await process_frame
		_expect(game.action_presentation_frame().paused and game.action_presentation_frame().actions.dash.remaining == remaining, "paused room freezes frame clock")
		game.room.process_mode = Node.PROCESS_MODE_INHERIT
		game._enter_room(game.current, "", p.hp)
		p = game.room.player
		p.set_physics_process(false)
		_expect(overlay.get_parent() == game.shell.room_viewport and game.action_presentation_frame().present, "overlay survives replacement with new anchor")
		var saved = game.room.player
		game.room.player = null
		frame = game.action_presentation_frame()
		_expect(not frame.present and not frame.phase_absent and frame.position == null and not frame.actions.sword.available, "missing player has no anchor or actions")
		game.room.player = saved
		overlay.queue_free()
	if not p.has_method("action_presentation_state") or not game.has_method("action_presentation_state") or not game.has_signal("strike_emitted") or not game.has_signal("action_room_changed"):
		_expect(false, "AP1: Player state and coordinator strike/state hooks exist")
	else:
		var legacy := {"abilities":{"sword":true,"dash":true}, "sword_range":90.0, "sword_arc":1.2, "sword_damage":1.0, "sword_strikes":2, "sword_cooldown":0.5, "dash_speed":650.0, "dash_duration":0.16, "dash_cooldown":0.7}
		p.set_capabilities(legacy)
		var strikes: Array = []
		var rooms: Array = []
		game.strike_emitted.connect(func(s): strikes.append(s))
		game.action_room_changed.connect(func(generation): rooms.append(generation))
		p.position = Vector2(200, 200)
		p.facing = Vector2.RIGHT
		_expect(p.start_attack() and p.start_dash(), "legacy actions start")
		var state: Dictionary = game.action_presentation_state()
		_expect(state.sword.available and not state.sword.ready and is_equal_approx(state.sword.total, 0.5) and is_equal_approx(state.dash.total, 0.7), "legacy captures independent totals")
		state.sword.total = 99
		_expect(is_equal_approx(game.action_presentation_state().sword.total, 0.5), "state detached")
		var changed := legacy.duplicate(true)
		changed.sword_cooldown = 5.0
		changed.sword_range = 300.0
		p.set_capabilities(changed)
		p.position = Vector2(210, 210)
		p.facing = Vector2.UP
		p.advance_attack(0.14)
		p.advance_attack(0.08)
		_expect(strikes.size() == 2 and strikes[0].origin == Vector2(210, 210) and strikes[0].facing == Vector2.RIGHT and strikes[0].reach == 90.0 and strikes[0].arc == 1.2, "each actual legacy strike reports captured geometry and current origin")
		_expect(is_equal_approx(game.action_presentation_state().sword.remaining, 0.28), "legacy countdown advances on action clock")
		_expect(is_equal_approx(game.action_presentation_state().sword.total, 0.5), "build changes do not alter captured cooldown")
		changed.sprint = true
		p.set_capabilities(changed)
		_expect(not game.action_presentation_state().dash.available and not game.action_presentation_state().dash.ready, "sprint replaces dash")
		game._enter_room(game.current, "", p.hp)
		_expect(rooms.size() == 1 and rooms[0] == game.room_generation, "room change explicitly resets frontend cues")
		p = game.room.player
		p.set_physics_process(false)
		_expect(game.action_presentation_state().sword.remaining == 0.0, "room replacement resets action clocks")
		var stale_count := strikes.size()
		game._forward_strike(game.room_generation - 1, {"origin":Vector2.ZERO})
		game.transition_pending = true
		game._forward_strike(game.room_generation, {"origin":Vector2.ZERO})
		game.transition_pending = false
		_expect(strikes.size() == stale_count, "stale and transition-pending strikes are discarded")
		p.set_capabilities(_caps(true))
		_expect(p.start_attack() and p.start_dash(), "unified sword and Phase start")
		var unified: Dictionary = game.action_presentation_state()
		_expect(is_equal_approx(unified.sword.total, 0.32) and is_equal_approx(unified.dash.total, 0.65), "unified includes action and post-action cooldown")
		var altered := _caps(true)
		altered.stats.sword_cooldown.effective = 9.0
		altered.qualities.sword.effective = false
		p.set_capabilities(altered)
		_expect(not game.action_presentation_state().sword.available and is_equal_approx(game.action_presentation_state().sword.total, 0.32), "unified loss preserves captured clock")
		p.set_capabilities(_caps(true))
		var count := strikes.size()
		p.advance_unified(0.14, Vector2.ZERO)
		_expect(strikes.size() == count, "Phase-suppressed sword emits no strike")
		_expect(game.action_presentation_state().sword.remaining > 0.0, "cooldown independent of movement restrictions")
		p.advance_unified(1.0, Vector2.ZERO)
		_expect(game.action_presentation_state().sword.ready and game.action_presentation_state().dash.ready, "unified clocks become ready")
		_expect(p.start_attack(), "unified sword restarts")
		p.advance_unified(0.14, Vector2.ZERO)
		_expect(strikes.size() == count + 1, "unified unsuppressed strike reaches coordinator")
	game.queue_free()
	await process_frame
	for failure in failures:
		printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _expect(value: bool, message: String) -> void:
	assertion_count += 1
	if not value:
		failures.append(message)
