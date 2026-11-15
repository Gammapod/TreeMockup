extends Node2D

signal portal_requested(destination: String, entry_port: String)
signal reward_collected(object_id: String)
signal player_defeated
signal switch_toggled(object_id: String)
signal objective_event(event: String, object_id: String)

const PLAYER = preload("res://player.gd")
const PORTS := {"north": Vector2(400, 85), "south": Vector2(400, 555), "west": Vector2(65, 320), "east": Vector2(735, 320)}
const ROOM_BOUNDS := Rect2(35, 55, 730, 530)
const WALL_THICKNESS := 15.0
const DOOR_HALF_WIDTH := 32.0
const DOOR_ARM_DISTANCE := 80.0
var player
var template: Dictionary
var portals: Array = []
var pickups: Array = []
var enemies: Array = []
var defeated: Dictionary = {}
var obstacles: Array = []
var ports: Dictionary = PORTS.duplicate()
var objects: Array = []
var object_states: Dictionary = {}
var barriers: Dictionary = {}
var tokens: Array = []
var boundary_walls: Array = []
var portal_armed: Dictionary = {}

func configure(data: Dictionary, links: Array, collected: Dictionary, dead: Dictionary, entry: String, caps: Dictionary, hp: int, cleared: bool = false) -> void:
	template = data
	ports = data.get("ports", PORTS)
	objects = data.get("objects", [])
	tokens = [] if cleared else data.get("tokens", []).duplicate(true)
	defeated = dead.duplicate()
	obstacles = data.obstacles
	for pickup in data.pickups:
		if not collected.has(pickup.id):
			pickups.append(pickup.duplicate())
	player = PLAYER.new()
	player.position = ports.get(entry, data.get("spawn", Vector2(400, 400)))
	player.set_capabilities(caps, false)
	player.hp = mini(hp, player.max_hp)
	player.attack.connect(_attack)
	add_child(player)
	set_portals(links)
	for rect in obstacles:
		_wall(rect)
	for object in objects:
		if object.kind in ["water", "wall"]:
			barriers[object.id] = _wall(object.bounds)
	for i in range(data.enemies.size()):
		var enemy: Variant = data.enemies[i]
		var id: String = enemy.id if enemy is Dictionary else str(i)
		if defeated.has(id):
			continue
		var body := CharacterBody2D.new()
		body.position = enemy.position if enemy is Dictionary else enemy
		body.collision_layer = 4
		body.collision_mask = 1
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = enemy.get("radius", 14.0) if enemy is Dictionary else 14.0
		shape.shape = circle
		body.add_child(shape)
		add_child(body)
		enemies.append({"id": id, "body": body, "hp": enemy.get("hp", 2) if enemy is Dictionary else 2, "speed": enemy.get("speed", 95.0) if enemy is Dictionary else 95.0, "radius": circle.radius})
	apply_object_states({})

func set_portals(links: Array) -> void:
	portals = links
	for wall in boundary_walls:
		wall.queue_free()
	boundary_walls.clear()
	var openings := {"north": [], "south": [], "west": [], "east": []}
	for portal in portals:
		var side: String = _portal_side(ports[portal.port])
		if portal.enabled:
			openings[side].append(_portal_axis(ports[portal.port], side))
		var key := _portal_key(portal)
		if not portal_armed.has(key):
			portal_armed[key] = player != null and player.position.distance_to(ports[portal.port]) >= DOOR_ARM_DISTANCE
	_add_edge_walls("north", openings.north)
	_add_edge_walls("south", openings.south)
	_add_edge_walls("west", openings.west)
	_add_edge_walls("east", openings.east)

func _add_edge_walls(side: String, opening_axes: Array) -> void:
	var start: float = ROOM_BOUNDS.position.x if side in ["north", "south"] else ROOM_BOUNDS.position.y
	var end: float = ROOM_BOUNDS.end.x if side in ["north", "south"] else ROOM_BOUNDS.end.y
	var cursor := start
	var axes: Array = opening_axes.duplicate()
	axes.sort()
	for axis_value in axes:
		var axis: float = axis_value
		var opening_start := clampf(axis - DOOR_HALF_WIDTH, start, end)
		var opening_end := clampf(axis + DOOR_HALF_WIDTH, start, end)
		_add_edge_segment(side, cursor, opening_start)
		cursor = maxf(cursor, opening_end)
	_add_edge_segment(side, cursor, end)

func _add_edge_segment(side: String, from: float, to: float) -> void:
	if to - from <= 0.01:
		return
	var rect: Rect2
	match side:
		"north": rect = Rect2(from, ROOM_BOUNDS.position.y, to - from, WALL_THICKNESS)
		"south": rect = Rect2(from, ROOM_BOUNDS.end.y - WALL_THICKNESS, to - from, WALL_THICKNESS)
		"west": rect = Rect2(ROOM_BOUNDS.position.x, from, WALL_THICKNESS, to - from)
		"east": rect = Rect2(ROOM_BOUNDS.end.x - WALL_THICKNESS, from, WALL_THICKNESS, to - from)
	boundary_walls.append(_wall(rect))

func _portal_side(point: Vector2) -> String:
	var distances := {
		"north": absf(point.y - (ROOM_BOUNDS.position.y + WALL_THICKNESS)),
		"south": absf(point.y - (ROOM_BOUNDS.end.y - WALL_THICKNESS)),
		"west": absf(point.x - (ROOM_BOUNDS.position.x + WALL_THICKNESS)),
		"east": absf(point.x - (ROOM_BOUNDS.end.x - WALL_THICKNESS))
	}
	var side := "north"
	for candidate in distances:
		if distances[candidate] < distances[side]:
			side = candidate
	return side

func _portal_axis(point: Vector2, side: String) -> float:
	return point.x if side in ["north", "south"] else point.y

func _portal_key(portal: Dictionary) -> String:
	return portal.destination + "/" + portal.port + "/" + portal.entry

func _crossed_portal(portal: Dictionary) -> bool:
	var point: Vector2 = ports[portal.port]
	var side := _portal_side(point)
	var axis := _portal_axis(player.position, side)
	if absf(axis - _portal_axis(point, side)) > DOOR_HALF_WIDTH:
		return false
	match side:
		"north": return player.position.y <= ROOM_BOUNDS.position.y
		"south": return player.position.y >= ROOM_BOUNDS.end.y
		"west": return player.position.x <= ROOM_BOUNDS.position.x
		"east": return player.position.x >= ROOM_BOUNDS.end.x
	return false

func suppress_tokens() -> void:
	tokens.clear()
	queue_redraw()

func sync_pickups(collected: Dictionary, visible: Dictionary) -> void:
	pickups.clear()
	for pickup in template.pickups:
		if visible.get(pickup.id, true) and not collected.has(pickup.id):
			pickups.append(pickup.duplicate())
	queue_redraw()

func _wall(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	return body

func apply_object_states(states: Dictionary) -> void:
	object_states = states.duplicate()
	for object in objects:
		if barriers.has(object.id):
			var passable: bool = player.capabilities.abilities.has("flippers") if object.kind == "water" else bool(object_states.get(object.id, false))
			barriers[object.id].collision_layer = 0 if passable else 1
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if player == null:
		return
	for enemy in enemies:
		enemy.body.velocity = enemy.body.position.direction_to(player.position) * enemy.speed
		enemy.body.move_and_slide()
		if enemy.body.position.distance_to(player.position) < enemy.radius + 13 and player.hurt() and player.hp == 0:
			player_defeated.emit()
			return
	for i in range(pickups.size() - 1, -1, -1):
		if not pickups[i].get("chest", false) and player.position.distance_to(pickups[i].position) < 27:
			var id: String = pickups[i].id
			pickups.remove_at(i)
			reward_collected.emit(id)
	for i in range(tokens.size() - 1, -1, -1):
		if player.position.distance_to(tokens[i].position) < 27:
			var id: String = tokens[i].id
			tokens.remove_at(i)
			objective_event.emit("token_collected", id)
	for portal in portals:
		var key := _portal_key(portal)
		if not portal_armed.get(key, false) and player.position.distance_to(ports[portal.port]) >= DOOR_ARM_DISTANCE:
			portal_armed[key] = true
		if portal.enabled and portal_armed.get(key, false) and _crossed_portal(portal):
			portal_armed[key] = false
			portal_requested.emit(portal.destination, portal.entry)
			return
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo() and event.physical_keycode == KEY_E:
		for i in range(pickups.size() - 1, -1, -1):
			if pickups[i].get("chest", false) and player.position.distance_to(pickups[i].position) < 50:
				var id: String = pickups[i].id
				pickups.remove_at(i)
				reward_collected.emit(id)
				return

func _attack(origin: Vector2, facing: Vector2, reach: float, damage: int) -> void:
	for object in objects:
		if object.kind == "switch" and _in_attack(origin, facing, object.position, reach):
			switch_toggled.emit(object.id)
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		var offset: Vector2 = enemy.body.position - origin
		if offset.length() > reach + enemy.radius or (offset.length() > 1 and facing.dot(offset.normalized()) < cos(0.9)):
			continue
		var ray := PhysicsRayQueryParameters2D.create(to_global(origin), enemy.body.global_position, 1)
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		enemy.hp -= damage
		if enemy.hp <= 0:
			defeated[enemy.id] = true
			enemy.body.queue_free()
			enemies.remove_at(i)
			objective_event.emit("enemy_defeated", enemy.id)

func _in_attack(origin: Vector2, facing: Vector2, target: Vector2, reach: float) -> bool:
	var offset := target - origin
	if offset.length() > reach or (offset.length() > 1 and facing.dot(offset.normalized()) < cos(0.9)):
		return false
	var ray := PhysicsRayQueryParameters2D.create(to_global(origin), to_global(target), 1)
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func _draw() -> void:
	draw_rect(Rect2(35, 55, 730, 530), Color("283646"))
	for rect in obstacles:
		draw_rect(rect, Color("61758a"))
	for object in objects:
		match object.kind:
			"water": draw_rect(object.bounds, Color("3479b5"))
			"wall":
				if not object_states.get(object.id, false):
					draw_rect(object.bounds, Color("ae9b7e"))
			"switch": draw_circle(object.position, 16, Color("7ef1a6") if object_states.get(object.id, false) else Color("e5935d"))
	for portal in portals:
		var point: Vector2 = ports[portal.port]
		var side := _portal_side(point)
		var boundary := point
		match side:
			"north": boundary.y = ROOM_BOUNDS.position.y + WALL_THICKNESS * 0.5
			"south": boundary.y = ROOM_BOUNDS.end.y - WALL_THICKNESS * 0.5
			"west": boundary.x = ROOM_BOUNDS.position.x + WALL_THICKNESS * 0.5
			"east": boundary.x = ROOM_BOUNDS.end.x - WALL_THICKNESS * 0.5
		var size := Vector2(DOOR_HALF_WIDTH * 2, WALL_THICKNESS) if side in ["north", "south"] else Vector2(WALL_THICKNESS, DOOR_HALF_WIDTH * 2)
		draw_rect(Rect2(boundary - size * 0.5, size), Color("65cbb1") if portal.enabled else Color("77505c"))
		draw_string(ThemeDB.fallback_font, boundary + Vector2(-25, -20), portal.destination, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	for pickup in pickups:
		if pickup.get("chest", false):
			draw_rect(Rect2(pickup.position - Vector2(15, 12), Vector2(30, 24)), Color("ffd569"))
		else:
			draw_circle(pickup.position, 10, Color("88cbff") if pickup.kind == "capacity" else Color("ffd569"))
	for enemy in enemies:
		draw_circle(enemy.body.position, enemy.radius, Color("c580df"))
		draw_string(ThemeDB.fallback_font, enemy.body.position + Vector2(-4, 5), str(enemy.hp), HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	for token in tokens:
		var p: Vector2 = token.position
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -12), p + Vector2(9, 0), p + Vector2(0, 12), p + Vector2(-9, 0)]), Color("ff95df"))
