extends Control

const ICONS = preload("res://presentation/icons.gd")

signal placed(point: Vector2)
signal moved(id: String, point: Vector2)
signal object_resized(id: String, bounds: Rect2)
signal selected(kind: String, id: String)
signal door_moved(id: String, point: Vector2)
signal gesture_started
signal gesture_finished

var mode := "room"
var content: Dictionary = {}
var brush := "select"
var dragging := ""
var zoom := 0.9
var selection := ""
var instance_doors: Array = []
var door_drag := ""
var instance_view := false
var selection_kind := ""
var pan := Vector2.ZERO
var panning := false
var snap_enabled := true
var drag_origin := Vector2.ZERO
var drag_pointer := Vector2.ZERO
var resizing := ""
var resize_edges := Vector2.ZERO
var resize_origin := Rect2()
var gesture := false
var fitting := false
var previous_size := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	clip_contents = true
	resized.connect(_resized)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		finish_gesture()
		panning = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		grab_focus()
		if event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			if event.pressed:
				finish_gesture()
			panning = event.pressed
			accept_event()
			return
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			finish_gesture()
			var anchor := to_world(event.position)
			zoom = clampf(zoom * (1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1 / 1.15), 0.001, 5)
			pan = event.position - anchor * zoom
			fitting = false
			queue_redraw()
			accept_event()
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			finish_gesture()
			return
		var point := to_world(event.position)
		for door in instance_doors:
			var door_size := Vector2(64, 18) if door.wall in ["north", "south"] else Vector2(18, 64)
			if Rect2(_door_point(door) - door_size / 2, door_size).grow(5 / zoom).has_point(point):
				door_drag = door.id
				gesture = true
				gesture_started.emit()
				return
		if instance_view:
			return
		if mode == "room" and brush != "select":
			placed.emit(_snap(point))
			return
		var hits := hit_items(point)
		var hit: Dictionary = {}
		if not hits.is_empty():
			hit = hits[0]
			if event.alt_pressed:
				for i in range(hits.size()):
					if hits[i].id == selection and hits[i].kind == selection_kind:
						hit = hits[(i + 1) % hits.size()]
						break
		selection = hit.get("id", "")
		selection_kind = hit.get("kind", "")
		selected.emit(selection_kind, selection)
		queue_redraw()
		# The owner may reject selection while invalid JSON is pending.
		if selection != hit.get("id", ""):
			return
		if not hit.is_empty() and hit.kind != "link":
			var resize := _resize_edges(hit, point)
			if resize != Vector2.ZERO:
				resizing = selection
				resize_edges = resize
				resize_origin = Rect2(hit.position, hit.size)
				drag_pointer = point
				gesture = true
				gesture_started.emit()
				return
			dragging = selection
			drag_origin = hit.position
			drag_pointer = point
			gesture = true
			gesture_started.emit()
	elif event is InputEventMouseMotion:
		if panning:
			pan += event.relative
			fitting = false
			queue_redraw()
		elif event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if door_drag != "":
				door_moved.emit(door_drag, to_world(event.position))
			elif dragging != "":
				var delta := to_world(event.position) - drag_pointer
				moved.emit(dragging, drag_origin + _snap(delta))
			elif resizing != "":
				var delta := _snap(to_world(event.position) - drag_pointer)
				var bounds := resize_origin
				if resize_edges.x < 0:
					bounds.position.x += delta.x
					bounds.size.x -= delta.x
				elif resize_edges.x > 0:
					bounds.size.x += delta.x
				if resize_edges.y < 0:
					bounds.position.y += delta.y
					bounds.size.y -= delta.y
				elif resize_edges.y > 0:
					bounds.size.y += delta.y
				if bounds.size.x < 10:
					bounds.position.x = resize_origin.end.x - 10 if resize_edges.x < 0 else resize_origin.position.x
					bounds.size.x = 10
				if bounds.size.y < 10:
					bounds.position.y = resize_origin.end.y - 10 if resize_edges.y < 0 else resize_origin.position.y
					bounds.size.y = 10
				object_resized.emit(resizing, bounds)

func to_world(point: Vector2) -> Vector2:
	return (point - pan) / zoom

func _snap(point: Vector2) -> Vector2:
	return point.snapped(Vector2(10, 10)) if snap_enabled else point

func finish_gesture() -> void:
	dragging = ""
	resizing = ""
	door_drag = ""
	if gesture:
		gesture = false
		gesture_finished.emit()

func cancel_gesture() -> void:
	dragging = ""
	resizing = ""
	door_drag = ""
	gesture = false

func hit_items(point: Vector2) -> Array:
	var hits: Array = []
	var items: Array = content.get("nodes", []) if mode == "tree" else content.get("objects", [])
	for i in range(items.size() - 1, -1, -1):
		var item: Dictionary = items[i]
		var location: Array = item.map_position if mode == "tree" else item.position
		var p := Vector2(location[0], location[1])
		var inside: bool
		if mode == "room" and item.has("size"):
			inside = Rect2(p, Vector2(item.size[0], item.size[1])).grow(5 / zoom).has_point(point)
		else:
			var radius: float = 23 if mode == "tree" else _radius(item)
			inside = point.distance_to(p) <= radius + 4 / zoom
		if inside:
			hits.append({"kind": "node" if mode == "tree" else "object", "id": item.id, "position": p, "size": Vector2(item.size[0], item.size[1]) if item.has("size") else Vector2.ZERO})
	if mode == "tree":
		var points := {}
		for node in items:
			points[node.id] = Vector2(node.map_position[0], node.map_position[1])
		for link in content.get("links", []):
			if points.has(link.a) and points.has(link.b) and point.distance_to(Geometry2D.get_closest_point_to_segment(point, points[link.a], points[link.b])) <= 6 / zoom:
				hits.append({"kind": "link", "id": link.id})
	return hits

func _radius(object: Dictionary) -> float:
	return float(object.properties.get("radius", 14)) if object.kind == "enemy" else 13.0

func _object_icon_id(object: Dictionary) -> String:
	var kind: String = object.get("kind", "")
	if kind == "token":
		return "token"
	if kind not in ["pickup", "chest"]:
		return ""
	var properties: Variant = object.get("properties", {})
	if not properties is Dictionary:
		return ""
	var reward: String = str(properties.get("kind", ""))
	return reward if reward in ["health", "gold", "capacity"] else ""

func _terrain_label_fits(kind: String, dimensions: Vector2, scale: float) -> bool:
	if kind not in ["water", "wall", "obstacle"] or scale <= 0:
		return false
	var width := ThemeDB.fallback_font.get_string_size(kind.capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var rotated := Vector2(width * cos(PI / 6) + 14 * sin(PI / 6), width * sin(PI / 6) + 14 * cos(PI / 6))
	return dimensions.x * scale >= rotated.x + 20 and dimensions.y * scale >= rotated.y + 20

func _draw_terrain_label(kind: String, bounds: Rect2) -> void:
	if not _terrain_label_fits(kind, bounds.size, zoom):
		return
	var text := kind.capitalize()
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_set_transform(pan + bounds.get_center() * zoom, -PI / 6)
	draw_string(font, Vector2(-width / 2, 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_set_transform(pan, 0, Vector2(zoom, zoom))

func _resize_edges(hit: Dictionary, point: Vector2) -> Vector2:
	if mode != "room" or not hit.has("size") or hit.size == Vector2.ZERO or hit.id != selection:
		return Vector2.ZERO
	var bounds := Rect2(hit.position, hit.size)
	var margin := 9 / zoom
	var edges := Vector2.ZERO
	if absf(point.x - bounds.position.x) <= margin: edges.x = -1
	elif absf(point.x - bounds.end.x) <= margin: edges.x = 1
	if absf(point.y - bounds.position.y) <= margin: edges.y = -1
	elif absf(point.y - bounds.end.y) <= margin: edges.y = 1
	return edges

func fit_content() -> void:
	var bounds := Rect2(0, 0, 800, 600)
	if mode == "room":
		var dimensions: Array = content.get("size", [800, 600])
		bounds.size = Vector2(dimensions[0], dimensions[1])
	else:
		var nodes: Array = content.get("nodes", [])
		if not nodes.is_empty():
			bounds = Rect2(Vector2(nodes[0].map_position[0], nodes[0].map_position[1]), Vector2.ZERO)
			for node in nodes:
				bounds = bounds.expand(Vector2(node.map_position[0], node.map_position[1]))
			bounds = bounds.grow(65)
	var available := (size - Vector2(50, 50)).max(Vector2(1, 1))
	zoom = minf(available.x / maxf(bounds.size.x, 1), available.y / maxf(bounds.size.y, 1))
	zoom = minf(zoom, 2)
	pan = size / 2 - bounds.get_center() * zoom
	fitting = true
	queue_redraw()

func _resized() -> void:
	if fitting:
		fit_content()
	elif previous_size != Vector2.ZERO:
		pan += (size - previous_size) / 2
	previous_size = size
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("192638"))
	if content.is_empty():
		return
	draw_set_transform(pan, 0, Vector2(zoom, zoom))
	var start := to_world(Vector2.ZERO)
	var end := to_world(size)
	var grid := maxf(40, pow(10, ceil(log(20 / zoom) / log(10))))
	for i in range(int(floor(start.x / grid)), int(ceil(end.x / grid)) + 1):
		draw_line(Vector2(i * grid, start.y), Vector2(i * grid, end.y), Color("24354a"), 1 / zoom)
	for i in range(int(floor(start.y / grid)), int(ceil(end.y / grid)) + 1):
		draw_line(Vector2(start.x, i * grid), Vector2(end.x, i * grid), Color("24354a"), 1 / zoom)
	if mode == "room":
		var dimensions: Array = content.get("size", [800, 600])
		draw_rect(Rect2(0, 0, dimensions[0], dimensions[1]), Color("7694af"), false, 2)
		if instance_view:
			draw_rect(Rect2(42.5, 62.5, 715, 515), Color("909dad"), false, 15)
		for port in content.get("ports", []):
			var p := Vector2(port.position[0], port.position[1])
			draw_rect(Rect2(p - Vector2(14, 14), Vector2(28, 28)), Color("67c8ab"))
			_text(p + Vector2(16, 5), port.id)
		for object in content.get("objects", []):
			var p := Vector2(object.position[0], object.position[1])
			var color: Color = {"token": Color("ff95df"), "enemy": Color("c580df"), "pickup": Color("88cbff"), "chest": Color("ffd569"), "switch": Color("e5935d"), "water": Color("3479b5"), "wall": Color("626d79"), "obstacle": Color("80664c")}.get(object.kind, Color("909dad"))
			if object.has("size") and object.size is Array and object.size.size() == 2:
				var bounds := Rect2(p, Vector2(object.size[0], object.size[1]))
				draw_rect(bounds, color)
				_draw_terrain_label(object.kind, bounds)
				if selection == object.id:
					draw_rect(Rect2(p, Vector2(object.size[0], object.size[1])).grow(3 / zoom), Color.WHITE, false, 2 / zoom)
					for corner in [p, p + Vector2(object.size[0], 0), p + Vector2(0, object.size[1]), p + Vector2(object.size[0], object.size[1])]:
						draw_rect(Rect2(corner - Vector2(4, 4) / zoom, Vector2(8, 8) / zoom), Color.WHITE)
			else:
				draw_circle(p, _radius(object), color)
				var icon := _object_icon_id(object)
				var side := minf(_radius(object) * 1.3, 22.0 / zoom)
				if not icon.is_empty() and side * zoom >= 14:
					ICONS.draw_icon(self, icon, Rect2(p - Vector2.ONE * side / 2, Vector2.ONE * side), Color("172332"))
				if selection == object.id:
					draw_arc(p, _radius(object) + 4 / zoom, 0, TAU, 32, Color.WHITE, 2 / zoom)
			_text(p + Vector2(18, -8), object.id)
		for door in instance_doors:
			var p := _door_point(door)
			var door_size := Vector2(64, 18) if door.wall in ["north", "south"] else Vector2(18, 64)
			draw_rect(Rect2(p - door_size / 2, door_size), Color("67c8ab") if door.automatic else Color("ffd569"))
			var label_offset: Vector2 = {"north": Vector2(-25, 30), "south": Vector2(-25, -20), "west": Vector2(22, 5), "east": Vector2(-110, 5)}[door.wall]
			_text(p + label_offset, door.neighbor)
	else:
		var points: Dictionary = {}
		for node in content.get("nodes", []):
			points[node.id] = Vector2(node.map_position[0], node.map_position[1])
		for link in content.get("links", []):
			if points.has(link.a) and points.has(link.b):
				draw_line(points[link.a], points[link.b], Color.WHITE if selection_kind == "link" and selection == link.id else Color("6a8baa"), (4 if selection_kind == "link" and selection == link.id else 2) / zoom)
		for node in content.get("nodes", []):
			for prerequisite in node.requires_all + node.requires_any:
				if points.has(prerequisite):
					draw_dashed_line(points[prerequisite] + Vector2(0, 8), points[node.id] + Vector2(0, 8), Color("e7be6f"), 2, 8)
			draw_circle(points[node.id], 23, Color("438e82") if node.id == content.root else Color("546ea0"))
			if selection_kind == "node" and selection == node.id:
				draw_arc(points[node.id], 23 + 4 / zoom, 0, TAU, 32, Color.WHITE, 2 / zoom)
			_text(points[node.id] + Vector2(-30, -33), node.name)
			_text(points[node.id] + Vector2(-6, 5), str(node.cost))

func _text(point: Vector2, text: String) -> void:
	draw_string(ThemeDB.fallback_font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("edf2fa"))

func _door_point(door: Dictionary) -> Vector2:
	match door.wall:
		"north": return Vector2(door.position.x, 62.5)
		"south": return Vector2(door.position.x, 577.5)
		"west": return Vector2(42.5, door.position.y)
		_: return Vector2(757.5, door.position.y)
