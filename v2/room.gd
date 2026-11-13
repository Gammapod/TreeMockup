extends Node2D

signal portal_requested(destination: String, entry_port: String)
signal reward_collected(object_id: String)
signal player_defeated

const PLAYER = preload("res://player.gd")
const PORTS := {"north": Vector2(400, 85), "south": Vector2(400, 555), "west": Vector2(65, 320), "east": Vector2(735, 320)}
var player
var template: Dictionary
var portals: Array = []
var pickups: Array = []
var enemies: Array = []
var defeated: Dictionary = {}
var obstacles: Array = []

func configure(data: Dictionary, links: Array, collected: Dictionary, dead: Dictionary, entry: String, caps: Dictionary, hp: int) -> void:
	template = data
	portals = links
	defeated = dead.duplicate()
	obstacles = data.obstacles
	for pickup in data.pickups:
		if not collected.has(pickup.id):
			pickups.append(pickup.duplicate())
	player = PLAYER.new()
	player.position = PORTS.get(entry, Vector2(400, 400))
	player.capabilities = caps
	player.hp = hp
	player.attack.connect(_attack)
	add_child(player)
	for rect in [Rect2(35, 55, 730, 15), Rect2(35, 570, 730, 15), Rect2(35, 55, 15, 530), Rect2(750, 55, 15, 530)]:
		_wall(rect)
	for rect in obstacles:
		_wall(rect)
	for i in range(data.enemies.size()):
		if defeated.has(str(i)):
			continue
		var body := CharacterBody2D.new()
		body.position = data.enemies[i]
		body.collision_layer = 4
		body.collision_mask = 1
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 14
		shape.shape = circle
		body.add_child(shape)
		add_child(body)
		enemies.append({"id": str(i), "body": body, "hp": 2})

func _wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	add_child(body)

func _physics_process(_delta: float) -> void:
	if player == null:
		return
	for enemy in enemies:
		enemy.body.velocity = enemy.body.position.direction_to(player.position) * 95.0
		enemy.body.move_and_slide()
		if enemy.body.position.distance_to(player.position) < 29 and player.hurt() and player.hp == 0:
			player_defeated.emit()
			return
	for i in range(pickups.size() - 1, -1, -1):
		if player.position.distance_to(pickups[i].position) < 27:
			var id: String = pickups[i].id
			pickups.remove_at(i)
			reward_collected.emit(id)
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo() and event.physical_keycode == KEY_E:
		for portal in portals:
			if portal.enabled and player.position.distance_to(PORTS[portal.port]) < 55:
				portal_requested.emit(portal.destination, portal.entry)
				return

func _attack(origin: Vector2, facing: Vector2, reach: float, damage: int) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		var offset: Vector2 = enemy.body.position - origin
		if offset.length() > reach or (offset.length() > 1 and facing.dot(offset.normalized()) < cos(0.9)):
			continue
		var ray := PhysicsRayQueryParameters2D.create(to_global(origin), enemy.body.global_position, 1)
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		enemy.hp -= damage
		if enemy.hp <= 0:
			defeated[enemy.id] = true
			enemy.body.queue_free()
			enemies.remove_at(i)

func _draw() -> void:
	draw_rect(Rect2(35, 55, 730, 530), Color("283646"))
	for rect in obstacles:
		draw_rect(rect, Color("61758a"))
	for portal in portals:
		var point: Vector2 = PORTS[portal.port]
		draw_rect(Rect2(point - Vector2(22, 22), Vector2(44, 44)), Color("65cbb1") if portal.enabled else Color("77505c"))
		draw_string(ThemeDB.fallback_font, point + Vector2(-25, -28), portal.destination, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	for pickup in pickups:
		draw_circle(pickup.position, 10, Color("88cbff") if pickup.kind == "capacity" else Color("ffd569"))
	for enemy in enemies:
		draw_circle(enemy.body.position, 14, Color("c580df"))
		draw_string(ThemeDB.fallback_font, enemy.body.position + Vector2(-4, 5), str(enemy.hp), HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
