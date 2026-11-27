extends CharacterBody2D

signal attack(origin: Vector2, facing: Vector2, reach: float, damage: float, arc: float)
signal phase_arrival_requested(attempt: Dictionary)
signal unified_restriction_changed(state: Dictionary)
signal unified_dash_started(attempt: Dictionary)

const UNIFIED_ACTIONS = preload("res://runtime/unified_actions.gd")

var capabilities: Dictionary = {"abilities": {}, "move_speed": 220.0, "dash_speed": 650.0}
var facing := Vector2.RIGHT
var dash_direction := Vector2.RIGHT
var dash_time := 0.0
var dash_cooldown := 0.0
var attack_time := 0.0
var attack_snapshot: Dictionary = {}
var invulnerability := 0.0
var hp := 5
var max_hp := 5
var attack_cooldown := 0.0
var attack_elapsed := 0.0
var strikes_emitted := 0
var dash_phase := false
var dash_speed := 650.0
var unified_actions
var _attack_total := 0.0
var _dash_total := 0.0

func set_capabilities(snapshot: Dictionary) -> void:
	var unified: bool = snapshot.get("model") == "unified_1"
	var next_max: int = int(snapshot.stats.max_hp.effective) if unified else snapshot.get("max_hp", 5)
	max_hp = next_max
	hp = mini(hp, max_hp)
	capabilities = snapshot
	if unified and unified_actions == null:
		unified_actions = UNIFIED_ACTIONS.new()
		unified_actions.attack_due.connect(_unified_attack_due)
		unified_actions.dash_started.connect(_unified_dash_started)
		unified_actions.phase_arrival_requested.connect(func(attempt): phase_arrival_requested.emit(attempt.duplicate(true)))
		unified_actions.restriction_changed.connect(func(state): unified_restriction_changed.emit(state.duplicate(true)))

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 13.0
	shape.shape = circle
	add_child(shape)

func _physics_process(delta: float) -> void:
	if capabilities.get("model") == "unified_1":
		var input_direction := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))).normalized()
		advance_unified(delta, input_direction)
		return
	invulnerability = maxf(0.0, invulnerability - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	advance_attack(delta)
	var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))).normalized()
	if direction != Vector2.ZERO and dash_time <= 0.0:
		facing = direction
	# Account for the partial last tick so authored distance matches movement.
	velocity = dash_direction * dash_speed * minf(delta, dash_time) / delta if dash_time > 0.0 else direction * movement_speed(Input.is_physical_key_pressed(KEY_SHIFT))
	move_and_slide()
	dash_time = maxf(0.0, dash_time - delta)
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.physical_keycode == KEY_SPACE:
		start_attack()
	if event.physical_keycode == KEY_SHIFT:
		start_dash()

func start_attack() -> bool:
	if capabilities.get("model") == "unified_1":
		return unified_actions.start_sword(capabilities, facing)
	if not capabilities.abilities.has("sword") or attack_cooldown > 0.00001 or attack_time > 0.00001:
		return false
	attack_snapshot = {"facing": facing, "reach": capabilities.sword_range, "arc": capabilities.get("sword_arc", 1.8), "damage": capabilities.sword_damage, "strikes": capabilities.get("sword_strikes", 1)}
	attack_time = 0.16 + 0.08 * (attack_snapshot.strikes - 1)
	attack_cooldown = maxf(attack_time, capabilities.get("sword_cooldown", 0.32))
	_attack_total = attack_cooldown
	attack_elapsed = 0.0
	strikes_emitted = 0
	return true

func advance_attack(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if attack_time <= 0.0:
		return
	attack_time = maxf(0.0, attack_time - delta)
	attack_elapsed += delta
	while strikes_emitted < attack_snapshot.strikes and attack_elapsed >= 0.14 + 0.08 * strikes_emitted:
		strikes_emitted += 1
		attack.emit(position, attack_snapshot.facing, attack_snapshot.reach, attack_snapshot.damage, attack_snapshot.arc)

func start_dash() -> bool:
	if capabilities.get("model") == "unified_1":
		return unified_actions.start_dash(capabilities, facing, position)
	if not capabilities.abilities.has("dash") or capabilities.get("sprint", false) or dash_cooldown > 0.0 or dash_time > 0.0:
		return false
	dash_direction = facing
	dash_time = capabilities.get("dash_duration", 0.16)
	dash_speed = capabilities.dash_speed
	dash_phase = capabilities.get("dash_phase", false)
	dash_cooldown = capabilities.get("dash_cooldown", 0.65)
	_dash_total = maxf(dash_time, dash_cooldown)
	return true

func action_presentation_state() -> Dictionary:
	var unified: bool = capabilities.get("model") == "unified_1"
	var sword_available: bool
	var dash_available: bool
	var clocks: Dictionary
	if unified:
		sword_available = capabilities.qualities.sword.effective
		dash_available = capabilities.qualities.dash.effective
		clocks = unified_actions.presentation_clocks()
	else:
		sword_available = capabilities.abilities.has("sword")
		dash_available = capabilities.abilities.has("dash") and not capabilities.get("sprint", false)
		clocks = {
			"sword": {"remaining": maxf(attack_cooldown, attack_time), "total": _attack_total},
			"dash": {"remaining": maxf(dash_cooldown, dash_time), "total": _dash_total}
		}
	var sword_remaining: float = clocks.sword.remaining
	var dash_remaining: float = clocks.dash.remaining
	clocks.sword["available"] = sword_available
	clocks.sword["ready"] = sword_available and (sword_remaining <= 0.0 if unified else sword_remaining <= 0.00001)
	clocks.dash["available"] = dash_available
	clocks.dash["ready"] = dash_available and dash_remaining <= 0.0
	return clocks

func movement_speed(sprint_held: bool) -> float:
	if capabilities.get("model") == "unified_1":
		return capabilities.stats.move_speed.effective
	return capabilities.get("move_speed", 220.0) * (2.0 if sprint_held and capabilities.get("sprint", false) else 1.0)

func hurt(contact: bool = true) -> bool:
	if capabilities.get("model") == "unified_1" and unified_actions.phase_absent():
		return false
	if capabilities.get("model") == "unified_1":
		if invulnerability > 0.0:
			return false
		hp = maxi(0, hp - 1)
		invulnerability = 0.8
		return true
	if invulnerability > 0.0 or (contact and dash_time > 0.0 and dash_phase):
		return false
	hp = maxi(0, hp - 1)
	invulnerability = 0.8
	return true

func _unified_attack_due(snapshot: Dictionary) -> void:
	if hp > 0 and is_inside_tree():
		attack.emit(position, snapshot.facing, snapshot.reach, snapshot.damage, snapshot.arc)

func _unified_dash_started(attempt: Dictionary) -> void:
	dash_direction = attempt.direction
	dash_time = attempt.duration
	dash_speed = attempt.distance / attempt.duration
	dash_phase = attempt.phase
	unified_dash_started.emit(attempt.duplicate(true))

func cancel_pending_phase() -> void:
	if unified_actions != null and unified_actions.cancel_phase():
		dash_time = 0.0
		dash_phase = false
		queue_redraw()

func advance_unified(delta: float, direction: Vector2) -> void:
	if delta <= 0.0:
		return
	invulnerability = maxf(0.0, invulnerability - delta)
	if direction != Vector2.ZERO and dash_time <= 0.0:
		facing = direction.normalized()
	if dash_time > 0.0:
		velocity = Vector2.ZERO if dash_phase else dash_direction * dash_speed * minf(delta, dash_time) / delta
	else:
		velocity = Vector2.ZERO if unified_actions.restrictions().blocked else direction * movement_speed(false)
	move_and_slide()
	dash_time = maxf(0.0, dash_time - delta)
	unified_actions.advance(delta)
	queue_redraw()

func _draw() -> void:
	var unified: bool = capabilities.get("model") == "unified_1"
	if unified and unified_actions.phase_absent():
		return
	draw_circle(Vector2.ZERO, 13, Color("ffffff") if invulnerability > 0 else Color("f6d365"))
	draw_line(Vector2.ZERO, facing * 23, Color.WHITE, 3)
