extends CharacterBody2D

signal attack(origin: Vector2, facing: Vector2, reach: float, damage: float, arc: float)

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

func set_capabilities(snapshot: Dictionary) -> void:
	var next_max: int = snapshot.get("max_hp", 5)
	max_hp = next_max
	hp = mini(hp, max_hp)
	capabilities = snapshot

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 13.0
	shape.shape = circle
	add_child(shape)

func _physics_process(delta: float) -> void:
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
	if not capabilities.abilities.has("sword") or attack_cooldown > 0.00001 or attack_time > 0.00001:
		return false
	attack_snapshot = {"facing": facing, "reach": capabilities.sword_range, "arc": capabilities.get("sword_arc", 1.8), "damage": capabilities.sword_damage, "strikes": capabilities.get("sword_strikes", 1)}
	attack_time = 0.16 + 0.08 * (attack_snapshot.strikes - 1)
	attack_cooldown = maxf(attack_time, capabilities.get("sword_cooldown", 0.32))
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
	if not capabilities.abilities.has("dash") or capabilities.get("sprint", false) or dash_cooldown > 0.0 or dash_time > 0.0:
		return false
	dash_direction = facing
	dash_time = capabilities.get("dash_duration", 0.16)
	dash_speed = capabilities.dash_speed
	dash_phase = capabilities.get("dash_phase", false)
	dash_cooldown = capabilities.get("dash_cooldown", 0.65)
	return true

func movement_speed(sprint_held: bool) -> float:
	return capabilities.get("move_speed", 220.0) * (2.0 if sprint_held and capabilities.get("sprint", false) else 1.0)

func hurt(contact: bool = true) -> bool:
	if invulnerability > 0.0 or (contact and dash_time > 0.0 and dash_phase):
		return false
	hp = maxi(0, hp - 1)
	invulnerability = 0.8
	return true

func _draw() -> void:
	if capabilities.abilities.has("sword"):
		var active := attack_time > 0.0
		var angle: float = attack_snapshot.facing.angle() if active else facing.angle()
		var reach: float = attack_snapshot.reach if active else capabilities.get("sword_range", 92.0)
		var arc: float = attack_snapshot.arc if active else capabilities.get("sword_arc", 1.8)
		var footprint := PackedVector2Array([Vector2.ZERO])
		for i in range(49):
			footprint.append(Vector2.from_angle(angle - arc * 0.5 + arc * i / 48.0) * reach)
		draw_colored_polygon(footprint, Color(0.61, 0.92, 0.84, 0.22 if active else 0.07))
		draw_arc(Vector2.ZERO, reach, angle - arc * 0.5, angle + arc * 0.5, 49, Color(0.61, 0.92, 0.84, 1.0 if active else 0.35), 3 if active else 1)
		draw_line(Vector2.ZERO, footprint[1], Color(0.61, 0.92, 0.84, 0.35))
		draw_line(Vector2.ZERO, footprint[-1], Color(0.61, 0.92, 0.84, 0.35))
	draw_circle(Vector2.ZERO, 13, Color("ffffff") if invulnerability > 0 else Color("f6d365"))
	draw_line(Vector2.ZERO, facing * 23, Color.WHITE, 3)
