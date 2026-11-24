extends "res://tests/suite_reporter.gd"

# UAB6: Player executes captured unified actions and exposes copied intents.
const BUILD = preload("res://runtime/unified_build.gd")
const PLAYER = preload("res://player.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _build(phase: bool) -> Dictionary:
	var contributions := [
		{"id":"dash", "kind":"quality", "quality":"dash"},
		{"id":"sword", "kind":"quality", "quality":"sword"},
		{"id":"root", "kind":"quality", "quality":"dash_root"}
	]
	if phase:
		contributions.append({"id":"phase", "kind":"quality", "quality":"phase_teleport"})
	return BUILD.compose({"nodes":{"root":{"contributions":contributions}}}, {"root":true})

func _run() -> void:
	var player = PLAYER.new()
	root.add_child(player)
	player.set_physics_process(false)
	if not player.has_method("advance_unified"):
		_expect(false, "Player exposes unified action integration")
	else:
		var caps := _build(false)
		player.hp = 2
		player.set_capabilities(caps)
		_expect(player.max_hp == 5 and player.hp == 2, "unified HP update does not heal")
		player.position = Vector2(100, 100)
		player.facing = Vector2.RIGHT
		_expect(player.start_dash(), "normal unified dash starts")
		player.set_physics_process(true)
		for tick in range(30):
			await physics_frame
			if player.dash_time <= 0.0:
				break
		player.set_physics_process(false)
		_expect(is_equal_approx(player.position.x, 204), "normal dash moves captured distance in fixed duration")
		_expect(not player.start_dash(), "dash recharge prevents repeat")
		player.queue_free()
		await process_frame
		player = PLAYER.new()
		root.add_child(player)
		player.set_physics_process(false)
		var arrivals: Array = []
		var restrictions: Array = []
		player.phase_arrival_requested.connect(func(attempt): arrivals.append(attempt))
		player.unified_restriction_changed.connect(func(state): restrictions.append(state))
		player.set_capabilities(_build(true))
		player.position = Vector2(200, 200)
		player.facing = Vector2.RIGHT
		_expect(player.start_dash(), "phase dash starts")
		_expect(not player.hurt(false), "player absent from spatial damage during transit")
		player.advance_unified(0.16, Vector2.ZERO)
		_expect(arrivals.size() == 1 and arrivals[0].destination == Vector2(304, 200), "phase emits captured arrival request")
		_expect(player.position == Vector2(200, 200), "player does not move before room resolves arrival")
		_expect(not restrictions.is_empty() and restrictions[-1].blocked, "player forwards movement restriction")
	player.queue_free()
	await process_frame
	for failure in failures:
		printerr("ASSERTION FAILED: " + failure)
	_complete(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(message)
