extends RefCounted

# Shared by authoring and compilation. Fixed-room geometry matches room.gd.
const SIDES := ["north", "south", "west", "east"]
const GAP := 80.0

static func side_at(point: Vector2) -> String:
	var distances := [absf(point.y - 70), absf(point.y - 570), absf(point.x - 50), absf(point.x - 750)]
	return SIDES[distances.find(distances.min())]

static func limits(side: String) -> Vector2:
	return Vector2(100, 700) if side in ["north", "south"] else Vector2(120, 520)

static func placement(point: Vector2) -> Dictionary:
	var side := side_at(point)
	var bounds := limits(side)
	var axis := point.x if side in ["north", "south"] else point.y
	return {"wall": side, "offset": clampf((axis - bounds.x) / (bounds.y - bounds.x), 0, 1)}

static func position(door: Dictionary) -> Vector2:
	# Legacy arrivals remain exact until explicitly adjusted/reset.
	if door.has("legacy_position"):
		return Vector2(door.legacy_position[0], door.legacy_position[1])
	var bounds := limits(door.wall)
	var axis := lerpf(bounds.x, bounds.y, door.offset)
	match door.wall:
		"north": return Vector2(axis, 85)
		"south": return Vector2(axis, 555)
		"west": return Vector2(65, axis)
		_: return Vector2(735, axis)

static func resolve(document: Dictionary) -> Dictionary:
	var nodes := {}
	var rooms := {}
	var result := {"nodes": {}, "errors": [], "warnings": []}
	for room in document.rooms:
		rooms[room.id] = room
	for node in document.dungeon.nodes:
		nodes[node.id] = node
		result.nodes[node.id] = []
	for link in document.dungeon.links:
		for end in ["a", "b"]:
			var other := "b" if end == "a" else "a"
			var origin: Array = nodes[link[end]].map_position
			var target: Array = nodes[link[other]].map_position
			var delta := Vector2(target[0] - origin[0], target[1] - origin[1])
			if delta == Vector2.ZERO:
				delta = Vector2.RIGHT if end == "a" else Vector2.LEFT
			var wall: String
			if absf(delta.x) > absf(delta.y):
				wall = "east" if delta.x > 0 else "west"
			else:
				wall = "south" if delta.y > 0 else "north"
			var order := delta.x / absf(delta.y) if wall in ["north", "south"] else delta.y / absf(delta.x)
			var override: Dictionary = link.get(end + "_door", {})
			var door := {"id": link.id + "_" + end, "link": link.id, "end": end, "neighbor": link[other], "wall": override.get("wall", wall), "automatic": override.is_empty(), "order": order}
			if not override.is_empty():
				door.offset = override.offset
				if override.has("legacy_position"):
					door.legacy_position = override.legacy_position
			result.nodes[link[end]].append(door)
	for node_id in result.nodes:
		var doors: Array = result.nodes[node_id]
		for wall in SIDES:
			var group: Array = doors.filter(func(d): return d.wall == wall)
			var automatic: Array = group.filter(func(d): return d.automatic)
			automatic.sort_custom(func(a, b): return a.order < b.order if a.order != b.order else a.id < b.id)
			var occupied: Array = []
			for door in group:
				if not door.automatic:
					var p := position(door)
					occupied.append(p.x if wall in ["north", "south"] else p.y)
			var bounds := limits(wall)
			var previous := bounds.x - GAP
			for i in range(automatic.size()):
				var ideal := lerpf(bounds.x, bounds.y, float(i + 1) / (automatic.size() + 1))
				var chosen := -1.0
				var distance := INF
				# Prefer an angle-ordered, evenly spaced layout; fixed overrides reserve space.
				for axis in range(int(bounds.x), int(bounds.y) + 1):
					if axis < previous + GAP:
						continue
					if occupied.any(func(value): return absf(value - axis) < GAP):
						continue
					# Leave room for remaining automatic doors.
					var available := 0
					var next := float(axis) + GAP
					while next <= bounds.y:
						if not occupied.any(func(value): return absf(value - next) < GAP):
							available += 1
							next += GAP
						else:
							next += 1
					if available < automatic.size() - i - 1:
						continue
					if absf(axis - ideal) < distance:
						chosen = axis
						distance = absf(axis - ideal)
				if chosen < 0:
					result.errors.append("%s: too many doors on %s; move a node or override a door wall." % [node_id, wall])
					chosen = ideal
				automatic[i].offset = (chosen - bounds.x) / (bounds.y - bounds.x)
				previous = chosen
			for i in range(group.size()):
				var p := position(group[i])
				for j in range(i):
					if p.distance_to(position(group[j])) < 64:
						result.warnings.append("%s: overlapping doors %s and %s." % [node_id, group[i].link, group[j].link])
		for door in doors:
			door.position = position(door)
			for object in rooms[nodes[node_id].template].objects:
				if object.kind in ["obstacle", "wall", "water"]:
					var rect := Rect2(Vector2(object.position[0], object.position[1]), Vector2(object.size[0], object.size[1])).grow(13)
					if rect.has_point(door.position):
						result.warnings.append("%s / %s: arrival overlaps %s." % [node_id, door.link, object.id])
	return result
