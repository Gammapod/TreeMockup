extends RefCounted

# This boundary operates only on JSON values. Never convert the editor's source
# document to engine objects or reconstruct it from runtime state when saving.
func new_room(id: String = "room") -> Dictionary:
	return {"id": id, "name": id.capitalize(), "size": [800, 600], "ports": [
		{"id": "north", "position": [400, 85]}, {"id": "south", "position": [400, 555]},
		{"id": "west", "position": [65, 320]}, {"id": "east", "position": [735, 320]}
	], "objects": []}

func new_node(id: String, template: String) -> Dictionary:
	return {"id": id, "name": id.capitalize(), "template": template, "cost": 1, "requires_all": [], "requires_any": [], "abilities": [], "map_position": [0, 0]}

func new_project() -> Dictionary:
	var node := new_node("start", "empty")
	node.cost = 0
	var room := new_room("empty")
	room.clear = {"conditions": [], "effects": [{"kind": "become_root"}]}
	return {"format": "room-tree", "version": 1, "id": "new_project", "name": "New project", "rooms": [room], "dungeon": {"root": "start", "initial_capacity": 4, "nodes": [node], "links": [], "interactions": []}, "extensions": {}}

func parse_document(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK:
		return _result(["JSON line %d: %s" % [json.get_error_line() + 1, json.get_error_message()]])
	var errors := validate(json.data)
	return {"ok": errors.is_empty(), "errors": errors, "document": json.data if errors.is_empty() else {}}

func load_document(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _result(["Cannot open %s (error %d)" % [path, FileAccess.get_open_error()]])
	return parse_document(file.get_as_text())

func save_document(path: String, document: Dictionary) -> Dictionary:
	var errors := validate(document)
	if not errors.is_empty():
		return _result(errors)
	return write_json(path, document)

func write_json(path: String, document: Dictionary) -> Dictionary:
	var temporary := path + ".writing"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _result(["Cannot write %s (error %d)" % [temporary, FileAccess.get_open_error()]])
	file.store_string(JSON.stringify(document, "\t", false) + "\n")
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return _result(["Write failed; original file retained: %s" % path])
	error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
	if error != OK:
		return _result(["Replace failed (%d); original retained, pending file at %s" % [error, temporary]])
	return _result([])

func validate(document: Variant) -> Array[String]:
	var errors: Array[String] = []
	if not document is Dictionary:
		return ["Document must be an object"]
	if document.get("format") != "room-tree" or document.get("version") != 1:
		return ["Expected room-tree format version 1; unsupported or missing version"]
	if not _id(document.get("id")) or not document.get("name") is String:
		errors.append("Project needs a stable id and name")
	var rooms := _index(document.get("rooms"), "rooms", errors)
	for id in rooms:
		_validate_room(rooms[id], errors)
	if not document.get("dungeon") is Dictionary:
		errors.append("dungeon must be an object")
		return errors
	var dungeon: Dictionary = document.dungeon
	var nodes := _index(dungeon.get("nodes"), "nodes", errors)
	var links := _index(dungeon.get("links"), "links", errors)
	var interactions := _index(dungeon.get("interactions"), "interactions", errors)
	if not _integer(dungeon.get("initial_capacity")):
		errors.append("initial_capacity must be a nonnegative integer")
	if dungeon.has("base_hp") and not _integer(dungeon.base_hp):
		errors.append("base_hp must be a nonnegative integer")
	if not dungeon.get("root") is String or not nodes.has(dungeon.get("root")):
		errors.append("root must reference a node")
	for id in nodes:
		var node: Dictionary = nodes[id]
		if not node.get("name") is String or not node.get("template") is String or not rooms.has(node.get("template")):
			errors.append("Node %s needs a name and valid template" % id)
		if not _integer(node.get("cost")) or not _point(node.get("map_position")):
			errors.append("Node %s needs nonnegative integer cost and numeric map_position" % id)
		for field in ["requires_all", "requires_any", "abilities"]:
			if not _strings(node.get(field)):
				errors.append("Node %s: %s must be a string array" % [id, field])
			elif field != "abilities":
				for ref in node[field]:
					if not nodes.has(ref) or ref == id:
						errors.append("Node %s: invalid prerequisite %s" % [id, ref])
		if node.has("exclusive_group") and not node.exclusive_group is String:
			errors.append("Node %s exclusive_group must be a string" % id)
		if node.has("modifiers") and not node.modifiers is Dictionary:
			errors.append("Node %s modifiers must be an object" % id)
	var used_ports: Dictionary = {}
	for id in links:
		var link: Dictionary = links[id]
		if not link.get("a") is String or not link.get("b") is String or not nodes.has(link.get("a")) or not nodes.has(link.get("b")) or link.a == link.b:
			errors.append("Link %s needs two distinct existing nodes" % id)
			continue
		for end in ["a", "b"]:
			var room: Dictionary = rooms.get(nodes[link[end]].get("template"), {})
			var port: Variant = link.get(end + "_port")
			if not port is String or not _has_id(room.get("ports", []), port):
				errors.append("Link %s has invalid %s_port" % [id, end])
			else:
				var key: String = link[end] + "/" + port
				if used_ports.has(key):
					errors.append("Port already connected: " + key)
				used_ports[key] = true
		if not _strings(link.get("activate_from")):
			errors.append("Link %s activate_from must be a string array" % id)
		else:
			for source in link.activate_from:
				if source != link.a and source != link.b:
					errors.append("Link %s activation source is not an endpoint" % id)
	for id in interactions:
		var binding: Dictionary = interactions[id]
		for end in ["source", "target"]:
			var address: Variant = binding.get(end)
			if not address is Dictionary or not address.get("node") is String or not nodes.has(address.get("node")):
				errors.append("Interaction %s has invalid %s node" % [id, end])
				continue
			var room: Dictionary = rooms.get(nodes[address.node].get("template"), {})
			if not address.get("object") is String or not _has_id(room.get("objects", []), address.get("object")):
				errors.append("Interaction %s has invalid %s object" % [id, end])
			var verb := "event" if end == "source" else "action"
			if not address.get(verb) is String or address.get(verb, "") == "":
				errors.append("Interaction %s needs %s" % [id, verb])
	if errors.is_empty():
		var visiting: Dictionary = {}
		var visited: Dictionary = {}
		for id in nodes:
			if _cycle(id, nodes, visiting, visited):
				errors.append("Prerequisite cycle detected at " + id)
				break
	return errors

func _validate_room(room: Dictionary, errors: Array[String]) -> void:
	var label: String = room.get("id", "room")
	if not room.get("name") is String or not _positive_size(room.get("size")):
		errors.append("Room %s needs name and positive size" % label)
	if room.has("spawn") and not _point(room.spawn):
		errors.append("Room %s spawn must be a numeric point" % label)
	var ports := _index(room.get("ports"), label + " ports", errors)
	var objects := _index(room.get("objects"), label + " objects", errors)
	for port in ports.values():
		if not _point(port.get("position")):
			errors.append("Room %s port %s needs numeric position" % [label, port.id])
	for object in objects.values():
		if not object.get("kind") is String or not _point(object.get("position")) or not object.get("properties") is Dictionary:
			errors.append("Room %s object %s needs kind, position and properties" % [label, object.id])
		if object.get("kind") in ["obstacle", "wall", "water"] and not _positive_size(object.get("size")):
			errors.append("Room %s object %s needs positive size" % [label, object.id])
		elif object.has("size") and not _positive_size(object.size):
			errors.append("Room %s object %s has invalid size" % [label, object.id])
	if room.has("clear"):
		if not room.clear is Dictionary:
			errors.append("Room %s clear must be an object" % label)
			return
		if room.clear.has("block_tree_editing_until_cleared") and not room.clear.block_tree_editing_until_cleared is bool:
			errors.append("Room %s clear.block_tree_editing_until_cleared must be a boolean" % label)
		for field in ["conditions", "effects"]:
			if not room.clear.get(field, []) is Array:
				errors.append("Room %s clear.%s must be an array" % [label, field])
				continue
			for entry in room.clear.get(field, []):
				if not entry is Dictionary or not entry.get("kind") is String:
					errors.append("Room %s clear entries need a kind" % label)
					continue
				var kinds: Array = []
				match entry.kind:
					"switch_hit": kinds = ["switch"]
					"reveal_pickup": kinds = ["pickup", "chest"]
				if not kinds.is_empty():
					if not entry.get("object") is String or not objects.has(entry.get("object")) or objects[entry.object].get("kind") not in kinds:
						errors.append("Room %s %s needs a valid %s object" % [label, entry.kind, "/".join(kinds)])
				if entry.kind in ["all_enemies_defeated", "all_tokens_collected"]:
					var kind := "enemy" if entry.kind == "all_enemies_defeated" else "token"
					if not objects.values().any(func(item): return item.get("kind") == kind):
						errors.append("Room %s %s needs at least one %s" % [label, entry.kind, kind])

func _index(items: Variant, label: String, errors: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	if not items is Array:
		errors.append(label + " must be an array")
		return result
	for item in items:
		if not item is Dictionary or not _id(item.get("id")):
			errors.append(label + " contains an invalid/missing id")
		elif result.has(item.id):
			errors.append(label + " contains duplicate id " + item.id)
		else:
			result[item.id] = item
	return result

func _id(value: Variant) -> bool:
	if not value is String or value.is_empty():
		return false
	for c in value:
		if not c in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-":
			return false
	return true

func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(value) and value >= 0 and floor(value) == value

func _point(value: Variant) -> bool:
	return value is Array and value.size() == 2 and (value[0] is float or value[0] is int) and (value[1] is float or value[1] is int) and is_finite(value[0]) and is_finite(value[1])

func _positive_size(value: Variant) -> bool:
	return _point(value) and value[0] > 0 and value[1] > 0

func _strings(value: Variant) -> bool:
	if not value is Array:
		return false
	for entry in value:
		if not entry is String:
			return false
	return true

func _has_id(items: Variant, id: String) -> bool:
	if items is Array:
		for item in items:
			if item is Dictionary and item.get("id") == id:
				return true
	return false

func _cycle(id: String, nodes: Dictionary, visiting: Dictionary, visited: Dictionary) -> bool:
	if visiting.has(id):
		return true
	if visited.has(id):
		return false
	visiting[id] = true
	for ref in nodes[id].requires_all + nodes[id].requires_any:
		if _cycle(ref, nodes, visiting, visited):
			return true
	visiting.erase(id)
	visited[id] = true
	return false

func _result(errors: Array) -> Dictionary:
	return {"ok": errors.is_empty(), "errors": errors}
