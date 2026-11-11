class_name DungeonModel
extends RefCounted

const CAPABILITIES_SCRIPT: Script = preload("res://scripts/player_capabilities.gd")
const DOOR_STATE_SCRIPT: Script = preload("res://scripts/door_runtime_state.gd")
const ENEMY_STATE_SCRIPT: Script = preload("res://scripts/enemy_runtime_state.gd")

var scenario
var player_room: String
var reachable_rooms: Dictionary = {}
var door_states: Dictionary = {}
var capabilities
var current_hp: int = 0
var gold_collected: int = 0
var collected_ids: Dictionary = {}
var permanent_door_capacity_bonus: int = 0
var switch_states: Dictionary = {}
var enemy_states: Dictionary = {}
var damage_cooldown: float = 0.0

func _init(p_scenario) -> void:
	scenario = p_scenario
	player_room = scenario.rules.root_room
	capabilities = CAPABILITIES_SCRIPT.new()
	for door in scenario.doors.values():
		door_states[door.id] = DOOR_STATE_SCRIPT.new()
	for switch_definition in scenario.switches.values():
		switch_states[switch_definition.id] = switch_definition.initial_state
	for enemy_definition in scenario.enemies.values():
		enemy_states[enemy_definition.id] = ENEMY_STATE_SCRIPT.new(enemy_definition.home_position)
	_recalculate()

func is_room_reachable(room_id: String) -> bool:
	return reachable_rooms.has(room_id)

func door_state(door_id: String):
	return door_states[door_id]

func try_toggle_door(door_id: String) -> String:
	var door = scenario.doors[door_id]
	var state = door_state(door_id)
	if scenario.rules.require_adjacent_interaction and door.other_room(player_room) == "":
		return "remote"
	if state.open:
		if state.propped:
			return "propped"
		state.open = false
		_recalculate()
		return "closed"
	if state.is_sealed():
		return state.sealed_reason
	state.open = true
	_recalculate()
	return "opened"

func try_traverse_door(door_id: String) -> bool:
	var door = scenario.doors[door_id]
	var state = door_state(door_id)
	var destination: String = door.other_room(player_room)
	if not state.open or destination == "":
		return false
	var departed_room: String = player_room
	player_room = destination
	_reset_surviving_enemies_in_room(departed_room)
	_recalculate()
	return true

func try_collect(collectable_id: String) -> bool:
	if not scenario.collectables.has(collectable_id) or collected_ids.has(collectable_id):
		return false
	var collectable = scenario.collectables[collectable_id]
	if collectable.room_id != player_room:
		return false
	collected_ids[collectable_id] = true
	if collectable.kind == "key":
		permanent_door_capacity_bonus += collectable.gold_value
		_recalculate()
	else:
		gold_collected += collectable.gold_value
	return true

func try_toggle_switch(switch_id: String) -> String:
	if not scenario.switches.has(switch_id):
		return "missing"
	var switch_definition = scenario.switches[switch_id]
	if switch_definition.room_id != player_room:
		return "remote"
	if not capabilities.has_action("sword"):
		return "ability"
	switch_states[switch_id] = not switch_states[switch_id]
	return "toggled"

func is_switch_active(switch_id: String) -> bool:
	return switch_states.get(switch_id, false)

func is_wall_passable(wall_id: String) -> bool:
	for room in scenario.rooms.values():
		for wall in room.wall_hazards:
			if wall.id == wall_id:
				return is_switch_active(wall.switch_id)
	return false

func is_enemy_alive(enemy_id: String) -> bool:
	return enemy_states[enemy_id].alive

func enemy_state(enemy_id: String):
	return enemy_states[enemy_id]

func try_attack_near(player_position: Vector2, range: float) -> int:
	if not capabilities.has_action("sword"):
		return 0
	var defeated: int = 0
	for enemy_definition in scenario.enemies.values():
		var state = enemy_state(enemy_definition.id)
		if state.alive and enemy_definition.room_id == player_room and state.position.distance_to(player_position) <= range:
			state.alive = false
			defeated += 1
	return defeated

func update_enemies(delta: float, player_position: Vector2) -> bool:
	damage_cooldown = maxf(0.0, damage_cooldown - delta)
	var damaged_player: bool = false
	for enemy_definition in scenario.enemies.values():
		var state = enemy_state(enemy_definition.id)
		if not state.alive or enemy_definition.room_id != player_room:
			continue
		state.position = state.position.move_toward(player_position, enemy_definition.speed * delta)
		if damage_cooldown <= 0.0 and state.position.distance_to(player_position) < 24.0:
			current_hp = maxi(0, current_hp - 1)
			damage_cooldown = 0.6
			damaged_player = true
	return damaged_player

func _recalculate() -> void:
	reachable_rooms = _calculate_reachable_rooms()
	if scenario.rules.collapse_disconnected_branches:
		for door in scenario.doors.values():
			var state = door_state(door.id)
			if state.open and (not reachable_rooms.has(door.room_a) or not reachable_rooms.has(door.room_b)):
				state.open = false
	reachable_rooms = _calculate_reachable_rooms()
	var previous_max_hp: int = capabilities.max_hp
	capabilities = _derive_capabilities()
	if capabilities.max_hp > previous_max_hp:
		current_hp += capabilities.max_hp - previous_max_hp
	else:
		current_hp = mini(current_hp, capabilities.max_hp)
	var open_count: int = open_door_count()
	for door in scenario.doors.values():
		var state = door_state(door.id)
		state.propped = state.open and scenario.rules.prop_player_path and _would_disconnect_player(door)
		state.sealed_reason = "" if state.open else _seal_reason(door, open_count)
	_respawn_defeated_enemies_in_disconnected_rooms()

func _derive_capabilities():
	var result = CAPABILITIES_SCRIPT.new()
	result.max_open_doors = scenario.rules.base_max_open_doors + permanent_door_capacity_bonus
	for room_id: String in reachable_rooms:
		var room = scenario.rooms[room_id]
		result.movement_multiplier *= room.movement_multiplier
		result.max_open_doors += room.max_open_doors_bonus
		result.max_hp += room.health_bonus
		result.can_cross_water = result.can_cross_water or room.grants_water_walking
		for action_id: String in room.active_actions:
			if not result.active_actions.has(action_id):
				result.active_actions.append(action_id)
	return result

func _seal_reason(door, open_count: int) -> String:
	var reaches_a: bool = reachable_rooms.has(door.room_a)
	var reaches_b: bool = reachable_rooms.has(door.room_b)
	if scenario.rules.require_root_connection and reaches_a == reaches_b:
		return "root"
	if scenario.rules.prevent_loops and _would_form_loop(door):
		return "loop"
	if open_count >= capabilities.max_open_doors:
		return "capacity"
	return ""

func open_door_count() -> int:
	var count: int = 0
	for state in door_states.values():
		if state.open:
			count += 1
	return count

func _calculate_reachable_rooms() -> Dictionary:
	var reachable: Dictionary = {scenario.rules.root_room: true}
	var frontier: Array[String] = [scenario.rules.root_room]
	while not frontier.is_empty():
		var current: String = frontier.pop_front()
		for door in scenario.doors.values():
			if not door_state(door.id).open:
				continue
			var neighbor: String = door.other_room(current)
			if neighbor != "" and not reachable.has(neighbor):
				reachable[neighbor] = true
				frontier.append(neighbor)
	return reachable

func _would_form_loop(candidate) -> bool:
	var visited: Dictionary = {candidate.room_a: true}
	var frontier: Array[String] = [candidate.room_a]
	while not frontier.is_empty():
		var current: String = frontier.pop_front()
		if current == candidate.room_b:
			return true
		for door in scenario.doors.values():
			if not door_state(door.id).open:
				continue
			var neighbor: String = door.other_room(current)
			if neighbor != "" and not visited.has(neighbor):
				visited[neighbor] = true
				frontier.append(neighbor)
	return false

func _would_disconnect_player(candidate) -> bool:
	var visited: Dictionary = {scenario.rules.root_room: true}
	var frontier: Array[String] = [scenario.rules.root_room]
	while not frontier.is_empty():
		var current: String = frontier.pop_front()
		for door in scenario.doors.values():
			if not door_state(door.id).open or door.id == candidate.id:
				continue
			var neighbor: String = door.other_room(current)
			if neighbor != "" and not visited.has(neighbor):
				visited[neighbor] = true
				frontier.append(neighbor)
	return not visited.has(player_room)

func _reset_surviving_enemies_in_room(room_id: String) -> void:
	for enemy_definition in scenario.enemies.values():
		var state = enemy_state(enemy_definition.id)
		if enemy_definition.room_id == room_id and state.alive:
			state.position = enemy_definition.home_position

func _respawn_defeated_enemies_in_disconnected_rooms() -> void:
	for enemy_definition in scenario.enemies.values():
		var state = enemy_state(enemy_definition.id)
		if not state.alive and not reachable_rooms.has(enemy_definition.room_id):
			state.alive = true
			state.position = enemy_definition.home_position
