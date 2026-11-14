extends Control

signal placed(point: Vector2)
signal moved(id: String, point: Vector2)

var mode := "room"
var content: Dictionary = {}
var brush := "select"
var dragging := ""
var zoom := 0.9

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			dragging = ""
			return
		var point: Vector2 = (event.position / zoom).snapped(Vector2(10, 10))
		var items: Array = content.get("nodes", []) if mode == "tree" else content.get("objects", [])
		for item in items:
			var location: Array = item.map_position if mode == "tree" else item.position
			if point.distance_to(Vector2(location[0], location[1])) < 32:
				dragging = item.id
				return
		if mode == "room" and brush != "select":
			placed.emit(point)
	elif event is InputEventMouseMotion and dragging != "" and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		moved.emit(dragging, (event.position / zoom).snapped(Vector2(10, 10)))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("192638"))
	if content.is_empty():
		return
	draw_set_transform(Vector2.ZERO, 0, Vector2(zoom, zoom))
	for x in range(0, 810, 40):
		draw_line(Vector2(x, 0), Vector2(x, 600), Color("24354a"))
	for y in range(0, 610, 40):
		draw_line(Vector2(0, y), Vector2(800, y), Color("24354a"))
	if mode == "room":
		var dimensions: Array = content.get("size", [800, 600])
		draw_rect(Rect2(0, 0, dimensions[0], dimensions[1]), Color("7694af"), false, 2)
		for port in content.get("ports", []):
			var p := Vector2(port.position[0], port.position[1])
			draw_rect(Rect2(p - Vector2(14, 14), Vector2(28, 28)), Color("67c8ab"))
			_text(p + Vector2(16, 5), port.id)
		for object in content.get("objects", []):
			var p := Vector2(object.position[0], object.position[1])
			var color: Color = {"token": Color("ff95df"), "enemy": Color("c580df"), "pickup": Color("88cbff"), "chest": Color("ffd569"), "switch": Color("e5935d"), "water": Color("3479b5")}.get(object.kind, Color("909dad"))
			if object.has("size") and object.size is Array and object.size.size() == 2:
				draw_rect(Rect2(p, Vector2(object.size[0], object.size[1])), color)
			else:
				draw_circle(p, 13, color)
			_text(p + Vector2(18, -8), object.id)
	else:
		var points: Dictionary = {}
		for node in content.get("nodes", []):
			points[node.id] = Vector2(node.map_position[0], node.map_position[1])
		for link in content.get("links", []):
			if points.has(link.a) and points.has(link.b):
				draw_line(points[link.a], points[link.b], Color("6a8baa"), 3)
		for node in content.get("nodes", []):
			for prerequisite in node.requires_all + node.requires_any:
				if points.has(prerequisite):
					draw_dashed_line(points[prerequisite] + Vector2(0, 8), points[node.id] + Vector2(0, 8), Color("e7be6f"), 2, 8)
			draw_circle(points[node.id], 23, Color("438e82") if node.id == content.root else Color("546ea0"))
			_text(points[node.id] + Vector2(-30, -33), node.name)
			_text(points[node.id] + Vector2(-6, 5), str(node.cost))

func _text(point: Vector2, text: String) -> void:
	draw_string(ThemeDB.fallback_font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("edf2fa"))
