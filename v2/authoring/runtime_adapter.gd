extends RefCounted

const STORE = preload("res://authoring/content_store.gd")
const PROGRESSION = preload("res://progression.gd")

func compile(document: Dictionary) -> Dictionary:
	var errors: Array[String] = STORE.new().validate(document)
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	var data: Dictionary = document.dungeon.duplicate(true)
	data.scenario_id = document.id
	var base_hp: Variant = data.get("base_hp", 5)
	if not _number(base_hp) or base_hp < 0 or floor(base_hp) != base_hp:
		errors.append("base_hp must be a nonnegative integer")
	data.templates = {}
	data.nodes = {}
	for room in document.rooms:
		if _vector(room.size) != Vector2(800, 600):
			errors.append("Runtime requires 800x600 rooms: " + room.id)
		var template := {"obstacles": [], "enemies": [], "pickups": [], "tokens": [], "objects": [], "ports": {}, "spawn": _vector(room.get("spawn", [400, 400]))}
		if room.has("clear"):
			template.clear = room.clear.duplicate(true)
			for condition in room.clear.get("conditions", []):
				if condition.kind not in ["all_enemies_defeated", "switch_hit", "all_tokens_collected"]:
					errors.append("Unsupported clear condition: " + condition.kind)
			for effect in room.clear.get("effects", []):
				if effect.kind not in ["reveal_pickup", "prevent_enemy_respawn", "become_root"]:
					errors.append("Unsupported clear effect: " + effect.kind)
		for port in room.ports:
			template.ports[port.id] = _vector(port.position)
		for object in room.objects:
			var position := _vector(object.position)
			match object.kind:
				"token":
					template.tokens.append({"id": object.id, "position": position})
				"obstacle":
					template.obstacles.append(Rect2(position, _vector(object.size)))
				"enemy":
					var hp: Variant = object.properties.get("hp", 2)
					var speed: Variant = object.properties.get("speed", 95.0)
					var radius: Variant = object.properties.get("radius", 14.0)
					var behavior: Variant = object.properties.get("behavior", "chase")
					if behavior not in ["chase", "roost_guardian"]:
						errors.append("Unsupported enemy behavior: " + str(behavior))
					if not _number(hp) or hp <= 0 or floor(hp) != hp or not _number(speed) or speed < 0 or not _number(radius) or radius <= 0:
						errors.append("Invalid enemy hp/speed: " + object.id)
					elif behavior == "roost_guardian" and radius >= 560:
						errors.append("Guardian radius must be smaller than the 560-unit shockwave extent: " + object.id)
					else:
						template.enemies.append({"id": object.id, "position": position, "hp": int(hp), "speed": float(speed), "radius": float(radius), "behavior": behavior})
				"pickup", "chest":
					var kind: String = str(object.properties.get("kind", "gold"))
					if kind not in ["capacity", "gold"]:
						errors.append("Unsupported pickup kind: " + kind)
					var value: Variant = object.properties.get("value", 1)
					if not _number(value) or value <= 0 or floor(value) != value:
						errors.append("Pickup value must be a positive integer: " + object.id)
					else:
						template.pickups.append({"id": object.id, "position": position, "kind": kind, "value": int(value), "chest": object.kind == "chest"})
				"switch", "water", "wall":
					var item: Dictionary = object.duplicate(true)
					item.position = position
					if object.has("size"):
						item.bounds = Rect2(position, _vector(object.size))
					template.objects.append(item)
				_:
					errors.append("Unsupported object kind: " + object.kind)
		data.templates[room.id] = template
	for node in document.dungeon.nodes:
		var result: Dictionary = node.duplicate(true)
		result.cost = int(node.cost)
		result.map_position = _vector(node.map_position)
		for ability in node.abilities:
			if ability not in ["sword", "dash", "flippers"]:
				errors.append("Unsupported ability: " + ability)
		for modifier in node.get("modifiers", {}):
			if modifier in ["sword_style", "dash_style"]:
				var allowed: Array = ["big", "fast"] if modifier == "sword_style" else ["phase", "run"]
				if node.modifiers[modifier] not in allowed:
					errors.append("Unsupported %s: %s" % [modifier, node.modifiers[modifier]])
			elif modifier not in ["move_speed_multiplier", "sword_range_multiplier", "sword_arc_multiplier", "sword_damage_multiplier", "sword_cooldown_multiplier", "sword_damage_bonus", "dash_speed_multiplier", "dash_distance_multiplier", "dash_cooldown_multiplier", "max_hp_bonus"]:
				errors.append("Unsupported modifier: " + modifier)
			elif not _number(node.modifiers[modifier]) or node.modifiers[modifier] < 0:
				errors.append("Modifier must be a nonnegative number: " + modifier)
			elif modifier in ["max_hp_bonus", "sword_damage_bonus"] and floor(node.modifiers[modifier]) != node.modifiers[modifier]:
				errors.append("Modifier must be an integer: " + modifier)
			elif modifier.ends_with("_multiplier") and node.modifiers[modifier] <= 0:
				errors.append("Multiplier must be positive: " + modifier)
		data.nodes[node.id] = result
	# Compatibility for pre-clear V1 bundles: translate the old implicit start
	# root into the same effect used by authored rooms, isolated from reused templates.
	var start_template: Dictionary = data.templates[data.nodes[data.root].template]
	if not start_template.has("clear"):
		var legacy_id: String = "__legacy_start"
		while data.templates.has(legacy_id):
			legacy_id += "_"
		var legacy: Dictionary = start_template.duplicate(true)
		legacy.clear = {"conditions": [], "effects": [{"kind": "become_root"}]}
		data.templates[legacy_id] = legacy
		data.nodes[data.root].template = legacy_id
	for id in data.nodes:
		var rule: Dictionary = data.templates[data.nodes[id].template].get("clear", {})
		var becomes_root: bool = rule.get("effects", []).any(func(effect): return effect.kind == "become_root")
		if becomes_root and not data.nodes[id].get("exclusive_group", "").is_empty():
			errors.append("Permanent root cannot belong to an exclusive group: " + id)
		if id == data.root and (not becomes_root or not rule.get("conditions", []).is_empty()):
			errors.append("Starting room must be default-cleared with a become_root effect")
	if errors.is_empty() and PROGRESSION.new(data).capabilities().max_hp < 1:
		errors.append("Initial active roots and base_hp must grant at least one HP")
	for interaction in data.interactions:
		var source := _object(document, interaction.source)
		var target := _object(document, interaction.target)
		if source.kind != "switch" or target.kind != "wall" or interaction.source.event != "toggled" or interaction.target.action != "set_open":
			errors.append("Unsupported interaction: " + interaction.id)
	return {"ok": errors.is_empty(), "errors": errors, "data": data}

func _object(document: Dictionary, address: Dictionary) -> Dictionary:
	for node in document.dungeon.nodes:
		if node.id == address.node:
			for room in document.rooms:
				if room.id == node.template:
					for object in room.objects:
						if object.id == address.object:
							return object
	return {}

func _vector(value: Array) -> Vector2:
	return Vector2(value[0], value[1])

func _number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(value)
