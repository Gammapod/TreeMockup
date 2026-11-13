extends CharacterBody2D

signal attack(origin: Vector2, facing: Vector2, reach: float, damage: int)

var capabilities: Dictionary = {"abilities": {}, "move_speed": 220.0, "dash_speed": 650.0}
var facing := Vector2.RIGHT
var dash_direction := Vector2.RIGHT
var dash_time := 0.0
var dash_cooldown := 0.0
var attack_time := 0.0
var attack_pending := false
var attack_snapshot: Dictionary = {}
var invulnerability := 0.0
var hp := 5

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
	dash_time = maxf(0.0, dash_time - delta)
	if attack_time > 0.0:
		attack_time = maxf(0.0, attack_time - delta)
		if attack_pending and attack_time <= 0.18:
			attack_pending = false
			attack.emit(position, attack_snapshot.facing, attack_snapshot.reach, attack_snapshot.damage)
	var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))).normalized()
	if direction != Vector2.ZERO and dash_time <= 0.0:
		facing = direction
	velocity = dash_direction * capabilities.dash_speed if dash_time > 0.0 else direction * capabilities.move_speed
	move_and_slide()
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.physical_keycode == KEY_SPACE and capabilities.abilities.has("sword") and attack_time <= 0.0:
		attack_time = 0.32
		attack_pending = true
		attack_snapshot = {"facing": facing, "reach": capabilities.sword_range, "damage": capabilities.sword_damage}
	if event.physical_keycode == KEY_SHIFT and capabilities.abilities.has("dash") and dash_cooldown <= 0.0:
		dash_direction = facing
		dash_time = 0.16
		dash_cooldown = 0.65

func hurt() -> bool:
	if invulnerability > 0.0:
		return false
	hp = maxi(0, hp - 1)
	invulnerability = 0.8
	return true

func _draw() -> void:
	draw_circle(Vector2.ZERO, 13, Color("ffffff") if invulnerability > 0 else Color("f6d365"))
	draw_line(Vector2.ZERO, facing * 23, Color.WHITE, 3)
	if attack_time > 0.0:
		var angle: float = attack_snapshot.facing.angle()
		draw_arc(Vector2.ZERO, attack_snapshot.reach, angle - 0.9, angle + 0.9, 20, Color("9cebd5"), 4)
