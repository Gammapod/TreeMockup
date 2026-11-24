extends RefCounted

const UNIFIED_BUILD = preload("res://runtime/unified_build.gd")

var definition: Dictionary
var active: Dictionary = {}
var cleared: Dictionary = {}
var roots: Dictionary = {}
var objective_progress: Dictionary = {}
var capacity: int
var collected: Dictionary = {}
var gold: int = 0

func _init(data: Dictionary) -> void:
	definition = data
	capacity = data.initial_capacity
	for id in definition.nodes:
		if _clear_rule(id).get("conditions", []).is_empty():
			_complete_clear(id)

func _template(id: String) -> Dictionary:
	return definition.templates[definition.nodes[id].template]

func _clear_rule(id: String) -> Dictionary:
	return _template(id).get("clear", {})

func _complete_clear(id: String) -> void:
	if cleared.has(id):
		return
	cleared[id] = true
	for effect in _clear_rule(id).get("effects", []):
		if effect.kind == "become_root":
			roots[id] = true
			active[id] = true

func prevents_respawn(id: String) -> bool:
	if cleared.has(id):
		for effect in _clear_rule(id).get("effects", []):
			if effect.kind == "prevent_enemy_respawn":
				return true
	return false

func pickup_visible(id: String, object_id: String) -> bool:
	for effect in _clear_rule(id).get("effects", []):
		if effect.kind == "reveal_pickup" and effect.object == object_id:
			return cleared.has(id)
	return true

func record_objective(id: String, event: String, object_id: String) -> bool:
	if not active.has(id) or cleared.has(id):
		return false
	var template := _template(id)
	var candidates: Array = []
	match event:
		"enemy_defeated": candidates = template.get("enemies", [])
		"switch_hit": candidates = template.get("objects", []).filter(func(item): return item.kind == "switch")
		"token_collected": candidates = template.get("tokens", [])
		_: return false
	if not candidates.any(func(item): return item is Dictionary and item.id == object_id):
		return false
	if not objective_progress.has(id):
		objective_progress[id] = {}
	if not objective_progress[id].has(event):
		objective_progress[id][event] = {}
	objective_progress[id][event][object_id] = true
	for condition in _clear_rule(id).get("conditions", []):
		match condition.kind:
			"all_enemies_defeated":
				if not _all_recorded(id, "enemy_defeated", template.enemies): return false
			"switch_hit":
				if not objective_progress[id].get("switch_hit", {}).has(condition.object): return false
			"all_tokens_collected":
				if not _all_recorded(id, "token_collected", template.tokens): return false
			_: return false
	_complete_clear(id)
	return true

func _all_recorded(id: String, event: String, objects: Array) -> bool:
	var recorded: Dictionary = objective_progress[id].get(event, {})
	return not objects.is_empty() and objects.all(func(item): return recorded.has(item.id))

func leave_room(id: String) -> void:
	if objective_progress.has(id):
		objective_progress[id].erase("token_collected")

func available_points() -> int:
	var spent := 0
	for id in active:
		if not roots.has(id):
			spent += definition.nodes[id].cost
	return capacity - spent

func neighbors(id: String) -> Array:
	var result: Array = []
	for link in definition.links:
		if link.a == id:
			result.append(link.b)
		elif link.b == id:
			result.append(link.a)
	return result

func supported(id: String, selected: Dictionary) -> bool:
	var node: Dictionary = definition.nodes[id]
	for prerequisite in node.get("requires_all", []):
		if not selected.has(prerequisite):
			return false
	var any_of: Array = node.get("requires_any", [])
	if not any_of.is_empty():
		for prerequisite in any_of:
			if selected.has(prerequisite):
				return true
		return false
	return true

func connected(selected: Dictionary) -> Dictionary:
	var found: Dictionary = {}
	var pending: Array = []
	for id in roots:
		if selected.has(id):
			pending.append(id)
			found[id] = true
	while not pending.is_empty():
		for neighbor in neighbors(pending.pop_front()):
			if selected.has(neighbor) and not found.has(neighbor):
				found[neighbor] = true
				pending.append(neighbor)
	return found

func preview_activation(id: String, current: String) -> Dictionary:
	if not definition.nodes.has(id):
		return _failure("missing")
	if active.has(id):
		return _failure("already_active")
	if not active.has(current):
		return _failure("invalid_location")
	if not can_edit_tree(current):
		return _failure("tree_editing_locked")
	var local := false
	for link in definition.links:
		if ((link.a == current and link.b == id) or (link.b == current and link.a == id)) and current in link.activate_from:
			local = true
	if not local:
		return _failure("not_local_or_wrong_direction")
	if not supported(id, active):
		return _failure("prerequisites")
	var group: String = definition.nodes[id].get("exclusive_group", "")
	if group != "":
		for other in active:
			if definition.nodes[other].get("exclusive_group", "") == group:
				return _failure("exclusive_choice")
	if available_points() < definition.nodes[id].cost:
		return _failure("capacity")
	var result := {"ok": true, "reason": "", "affected": [id]}
	if definition.get("capability_model", "legacy") == "unified_1":
		var selected := active.duplicate()
		selected[id] = true
		result.build_before = UNIFIED_BUILD.compose(definition, active)
		result.build_after = UNIFIED_BUILD.compose(definition, selected)
	return result

func activate(id: String, current: String) -> Dictionary:
	var result := preview_activation(id, current)
	if result.ok:
		active[id] = true
	return result

func preview_deactivation(id: String, current: String) -> Dictionary:
	if active.has(current) and not can_edit_tree(current):
		return _failure("tree_editing_locked")
	if roots.has(id):
		return _failure("root")
	if not active.has(id):
		return _failure("inactive")
	if not active.has(current) or id not in neighbors(current):
		return _failure("not_local")
	var remaining := active.duplicate()
	remaining.erase(id)
	# Fixed point: an ALL/ANY dependency or physical disconnection can cascade.
	while true:
		var remove: Array = []
		var reachable := connected(remaining)
		for candidate in remaining:
			if not roots.has(candidate) and (not supported(candidate, remaining) or not reachable.has(candidate)):
				remove.append(candidate)
		if remove.is_empty():
			break
		for candidate in remove:
			remaining.erase(candidate)
	var affected: Array = []
	for candidate in active:
		if not remaining.has(candidate):
			affected.append(candidate)
	if not remaining.has(current):
		return {"ok": false, "reason": "would_strand_player", "affected": affected}
	var result := {"ok": true, "reason": "", "affected": affected}
	if definition.get("capability_model", "legacy") == "unified_1":
		result.build_before = UNIFIED_BUILD.compose(definition, active)
		result.build_after = UNIFIED_BUILD.compose(definition, remaining)
	return result

func deactivate(id: String, current: String) -> Dictionary:
	var result := preview_deactivation(id, current)
	if result.ok:
		for candidate in result.affected:
			active.erase(candidate)
			if objective_progress.has(candidate):
				objective_progress[candidate].erase("enemy_defeated")
				objective_progress[candidate].erase("token_collected")
	return result

func can_travel(source: String, destination: String) -> bool:
	return active.has(source) and active.has(destination) and destination in neighbors(source)

func can_edit_tree(current: String) -> bool:
	return active.has(current) and (cleared.has(current) or not _clear_rule(current).get("block_tree_editing_until_cleared", false))

func preview_root_travel(destination: String, current: String) -> Dictionary:
	if not definition.nodes.has(destination):
		return _failure("missing")
	if not active.has(current) or not definition.nodes.has(current):
		return _failure("invalid_location")
	if destination == current:
		return _failure("already_here")
	if not roots.has(destination) or not cleared.has(destination) or not active.has(destination):
		return _failure("not_cleared_active_root")
	return {"ok": true, "reason": "", "affected": []}

func capabilities() -> Dictionary:
	if definition.get("capability_model", "legacy") == "unified_1":
		return UNIFIED_BUILD.compose(definition, active)
	var abilities: Dictionary = {}
	var stats := {"move_speed": 220.0, "sword_range": 92.0, "sword_arc": 1.8, "sword_damage": 1.0, "dash_speed": 650.0, "max_hp": int(definition.get("base_hp", 5)), "sword_strikes": 1, "sword_cooldown": 0.32, "dash_duration": 0.16, "dash_cooldown": 0.65, "dash_phase": false, "sprint": false}
	var damage_multiplier := 1.0
	var attack_interval_multiplier := 1.0
	var dash_distance_multiplier := 1.0
	var sword_style := ""
	var dash_style := ""
	# Authored node order makes conflicting experimental styles deterministic.
	for id in definition.nodes:
		if not active.has(id):
			continue
		for ability in definition.nodes[id].get("abilities", []):
			abilities[ability] = true
		var modifiers: Dictionary = definition.nodes[id].get("modifiers", {})
		stats.move_speed *= modifiers.get("move_speed_multiplier", 1.0)
		stats.sword_range *= modifiers.get("sword_range_multiplier", 1.0)
		stats.sword_arc *= modifiers.get("sword_arc_multiplier", 1.0)
		stats.sword_damage += int(modifiers.get("sword_damage_bonus", 0))
		damage_multiplier *= modifiers.get("sword_damage_multiplier", 1.0)
		attack_interval_multiplier *= modifiers.get("sword_cooldown_multiplier", 1.0)
		stats.dash_speed *= modifiers.get("dash_speed_multiplier", 1.0)
		dash_distance_multiplier *= modifiers.get("dash_distance_multiplier", 1.0)
		stats.dash_cooldown *= modifiers.get("dash_cooldown_multiplier", 1.0)
		stats.max_hp += int(modifiers.get("max_hp_bonus", 0))
		sword_style = modifiers.get("sword_style", sword_style)
		dash_style = modifiers.get("dash_style", dash_style)
	if abilities.has("sword"):
		if sword_style == "big":
			stats.sword_range *= 1.5
			stats.sword_cooldown = 2.0
		elif sword_style == "fast":
			stats.sword_range *= 0.5
			stats.sword_strikes = 3
			stats.sword_cooldown = 0.48
	if abilities.has("dash"):
		if dash_style == "phase":
			stats.dash_duration *= 0.65
			stats.dash_phase = true
		elif dash_style == "run":
			stats.sprint = true
	stats.sword_damage *= damage_multiplier
	stats.sword_arc = minf(TAU, stats.sword_arc)
	# Startup/hit window stays fixed; intervals cannot undercut an action.
	stats.sword_cooldown = maxf(0.16 + 0.08 * (stats.sword_strikes - 1), stats.sword_cooldown * attack_interval_multiplier)
	stats.dash_duration *= dash_distance_multiplier
	stats.dash_distance = stats.dash_speed * stats.dash_duration
	stats.dash_cooldown = maxf(stats.dash_duration, stats.dash_cooldown)
	stats.abilities = abilities
	return stats

func collect(node_id: String, object_id: String, hp: int = -1, max_hp: int = -1) -> bool:
	if not active.has(node_id) or not pickup_visible(node_id, object_id):
		return false
	var key := node_id + "/" + object_id
	if collected.has(key):
		return false
	var template: Dictionary = definition.templates[definition.nodes[node_id].template]
	for pickup in template.pickups:
		if pickup.id == object_id:
			if pickup.kind == "health" and (hp <= 0 or hp >= max_hp):
				return false
			collected[key] = true
			if pickup.kind == "capacity":
				capacity += pickup.get("value", 1)
			elif pickup.kind == "gold":
				gold += pickup.get("value", 1)
			return true
	return false

func _failure(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "affected": []}
