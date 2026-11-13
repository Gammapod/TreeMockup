extends RefCounted

const STORE = preload("res://authoring/content_store.gd")

func compile(document: Dictionary) -> Dictionary:
	var errors: Array[String] = STORE.new().validate(document)
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	var data: Dictionary = document.dungeon.duplicate(true)
	data.templates = {}
	data.nodes = {}
	for room in document.rooms:
		if _vector(room.size) != Vector2(800, 600):
			errors.append("Runtime requires 800x600 rooms: " + room.id)
		var template := {"obstacles": [], "enemies": [], "pickups": [], "objects": [], "ports": {}, "spawn": _vector(room.get("spawn", [400, 400]))}
		for port in room.ports:
			template.ports[port.id] = _vector(port.position)
		for object in room.objects:
			var position := _vector(object.position)
			match object.kind:
				"obstacle":
					template.obstacles.append(Rect2(position, _vector(object.size)))
				"enemy":
					var hp: Variant = object.properties.get("hp", 2)
					var speed: Variant = object.properties.get("speed", 95.0)
					if not _number(hp) or hp <= 0 or floor(hp) != hp or not _number(speed) or speed < 0:
						errors.append("Invalid enemy hp/speed: " + object.id)
					else:
						template.enemies.append({"id": object.id, "position": position, "hp": int(hp), "speed": float(speed)})
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
			if modifier not in ["move_speed_multiplier", "sword_range_multiplier", "sword_damage_bonus", "dash_speed_multiplier"]:
				errors.append("Unsupported modifier: " + modifier)
			elif not _number(node.modifiers[modifier]) or node.modifiers[modifier] < 0:
				errors.append("Modifier must be a nonnegative number: " + modifier)
		data.nodes[node.id] = result
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
