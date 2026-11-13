extends RefCounted

var definition: Dictionary
var active: Dictionary = {}
var capacity: int
var collected: Dictionary = {}
var gold: int = 0

func _init(data: Dictionary) -> void:
	definition = data
	capacity = data.initial_capacity
	active[data.root] = true

func available_points() -> int:
	var spent := 0
	for id in active:
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
	if not selected.has(definition.root):
		return found
	var pending: Array = [definition.root]
	found[definition.root] = true
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
	return {"ok": true, "reason": "", "affected": [id]}

func activate(id: String, current: String) -> Dictionary:
	var result := preview_activation(id, current)
	if result.ok:
		active[id] = true
	return result

func preview_deactivation(id: String, current: String) -> Dictionary:
	if id == definition.root:
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
			if candidate != definition.root and (not supported(candidate, remaining) or not reachable.has(candidate)):
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
	return {"ok": true, "reason": "", "affected": affected}

func deactivate(id: String, current: String) -> Dictionary:
	var result := preview_deactivation(id, current)
	if result.ok:
		for candidate in result.affected:
			active.erase(candidate)
	return result

func can_travel(source: String, destination: String) -> bool:
	return active.has(source) and active.has(destination) and destination in neighbors(source)

func capabilities() -> Dictionary:
	var abilities: Dictionary = {}
	for id in active:
		for ability in definition.nodes[id].get("abilities", []):
			abilities[ability] = true
	return {"abilities": abilities, "move_speed": 220.0, "sword_range": 92.0, "sword_damage": 1, "dash_speed": 650.0}

func collect(node_id: String, object_id: String) -> bool:
	if not active.has(node_id):
		return false
	var key := node_id + "/" + object_id
	if collected.has(key):
		return false
	var template: Dictionary = definition.templates[definition.nodes[node_id].template]
	for pickup in template.pickups:
		if pickup.id == object_id:
			collected[key] = true
			if pickup.kind == "capacity":
				capacity += 1
			else:
				gold += 1
			return true
	return false

func _failure(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "affected": []}
