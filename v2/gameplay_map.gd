extends Control

const Icons = preload("res://presentation/icons.gd")

signal node_selected(id: String)

var definition: Dictionary = {}
var occupied := ""
var selected := ""
var zoom := 1.0
var offset := Vector2.ZERO
var needs_fit := true
var node_states: Dictionary = {}
var framing_node := ""
var removal_preview: Array = []
var removal_blocked := false
var cleared: Dictionary = {}
var roots: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	tooltip_text = "Map: use arrow keys to inspect nodes. Selection does not activate or travel."
	clip_contents = true
	resized.connect(_on_resized)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func set_definition(data: Dictionary) -> void:
	definition = data
	selected = ""
	node_states = {}
	cleared = {}
	roots = {}
	removal_preview = []
	framing_node = ""
	needs_fit = true
	queue_redraw()

func set_occupied(id: String) -> void:
	occupied = id
	queue_redraw()

func set_node_states(states: Dictionary) -> void:
	node_states = states
	queue_redraw()

func set_removal_preview(affected: Array, blocked: bool) -> void:
	removal_preview = affected.duplicate()
	removal_blocked = blocked
	queue_redraw()

func fit_graph() -> void:
	framing_node = ""
	if definition.is_empty() or size.x <= 0 or size.y <= 0:
		return
	var bounds := Rect2()
	var first := true
	for id in definition.nodes:
		var point := _position(id)
		if first:
			bounds = Rect2(point, Vector2.ZERO)
			first = false
		else:
			bounds = bounds.expand(point)
	if first:
		return
	var available := (size - Vector2(150, 120)).max(Vector2(30, 30))
	zoom = minf(minf(available.x / maxf(bounds.size.x, 1), available.y / maxf(bounds.size.y, 1)), 3.0)
	offset = size * 0.5 - bounds.get_center() * zoom
	needs_fit = false
	queue_redraw()

func frame_neighborhood(id: String) -> void:
	framing_node = id
	needs_fit = true
	if not definition.get("nodes", {}).has(id) or size.x <= 0 or size.y <= 0:
		return
	var neighborhood: Array = [id]
	for link in definition.links:
		if link.a == id:
			neighborhood.append(link.b)
		elif link.b == id:
			neighborhood.append(link.a)
	var center := _position(id)
	# Symmetric bounds keep the occupied node centered even on one-sided branches.
	# Labels remain screen-sized, so reserve their actual width before fitting.
	zoom = 1.5
	for neighbor in neighborhood:
		var distance := (_position(neighbor) - center).abs()
		var label_width := ThemeDB.fallback_font.get_string_size(definition.nodes[neighbor].name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var available := (size * 0.5 - Vector2(maxf(30, label_width * 0.5) + 12, 55)).max(Vector2.ONE)
		if distance.x > 0:
			zoom = minf(zoom, available.x / distance.x)
		if distance.y > 0:
			zoom = minf(zoom, available.y / distance.y)
	offset = size * 0.5 - center * zoom
	needs_fit = false
	queue_redraw()

func _on_resized() -> void:
	needs_fit = true
	queue_redraw()

func _position(id: String) -> Vector2:
	return definition.nodes[id].get("map_position", Vector2.ZERO)

func _screen(id: String) -> Vector2:
	return _position(id) * zoom + offset

func _icon_for_node(node: Dictionary) -> String:
	return Icons.resolve_id(node.get("icon_id"))

func _shows_label(id: String) -> bool:
	if occupied.is_empty() or id == occupied or id == selected:
		return true
	for link in definition.get("links", []):
		if (link.a == occupied and link.b == id) or (link.b == occupied and link.a == id):
			return true
	return false

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		_cycle_selection(-1)
		accept_event()
		return
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		_cycle_selection(1)
		accept_event()
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			framing_node = ""
			var old_zoom := zoom
			# Automatic fitting may require less than the usual manual zoom floor.
			# Preserve wheel direction at those scales rather than jumping inward.
			var minimum := minf(0.05, old_zoom / 1.15)
			zoom = clampf(zoom * (1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15), minimum, 3.0)
			offset = event.position - (event.position - offset) * zoom / old_zoom
			accept_event()
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			grab_focus()
			var closest := ""
			var distance := 24.0
			for id in definition.get("nodes", {}):
				var candidate: float = event.position.distance_to(_screen(id))
				if candidate < distance:
					closest = id
					distance = candidate
			selected = closest
			node_selected.emit(selected)
			accept_event()
			queue_redraw()
	elif event is InputEventMouseMotion and event.button_mask & (MOUSE_BUTTON_MASK_MIDDLE | MOUSE_BUTTON_MASK_RIGHT):
		framing_node = ""
		offset += event.relative
		accept_event()
		queue_redraw()

func _cycle_selection(direction: int) -> void:
	var ids: Array = definition.get("nodes", {}).keys()
	if ids.is_empty():
		return
	var index := ids.find(selected)
	if index < 0:
		index = 0 if direction > 0 else ids.size() - 1
	else:
		index = posmod(index + direction, ids.size())
	selected = str(ids[index])
	node_selected.emit(selected)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("192638"))
	if has_focus():
		draw_rect(Rect2(Vector2(2, 2), (size - Vector2(4, 4)).max(Vector2.ZERO)), Color.WHITE, false, 2)
	if definition.is_empty():
		return
	if needs_fit:
		if framing_node.is_empty():
			fit_graph()
		else:
			frame_neighborhood(framing_node)
	for link in definition.links:
		draw_line(_screen(link.a), _screen(link.b), Color("6a8baa"), 2, true)
	for id in definition.nodes:
		var node: Dictionary = definition.nodes[id]
		for prerequisite in node.get("requires_all", []) + node.get("requires_any", []):
			var start := _screen(prerequisite) + Vector2(0, 7)
			var end := _screen(id) + Vector2(0, 7)
			var direction := (end - start).normalized()
			end -= direction * 22
			draw_dashed_line(start, end, Color("e7be6f"), 1.5, 6)
			draw_line(end, end - direction.rotated(0.5) * 9, Color("e7be6f"), 1.5, true)
			draw_line(end, end - direction.rotated(-0.5) * 9, Color("e7be6f"), 1.5, true)
	for id in definition.nodes:
		var point := _screen(id)
		if id in removal_preview:
			var warning := Color("f18181") if removal_blocked else Color("ffb45c")
			draw_rect(Rect2(point - Vector2(29, 29), Vector2(58, 58)), warning, false, 2)
			_text(point + Vector2(27, 31), "−", warning)
		if id == selected:
			draw_arc(point, 25, 0, TAU, 40, Color.WHITE, 2, true)
		var state: String = node_states.get(id, "blocked")
		var color: Color = {"active": Color("287d75"), "available": Color("477d39"), "blocked": Color("465366")}[state]
		draw_circle(point, 18, color)
		# Icon IDs are explicit presentation data, never derived from benefits.
		Icons.draw_icon(self, _icon_for_node(definition.nodes[id]), Rect2(point - Vector2(9, 10), Vector2(18, 18)), Color.WHITE)
		var cost_badge := point + Vector2(-17, 15)
		draw_circle(cost_badge, 9, Color("121b28"))
		_text(cost_badge + Vector2(0, 5), "0" if roots.has(id) else str(definition.nodes[id].cost), Color.WHITE)
		if cleared.has(id):
			_text(point + Vector2(-18, -15), "R" if roots.has(id) else "C", Color("a7f0cd"))
		var badge := point + Vector2(17, -15)
		draw_circle(badge, 9, Color("121b28"))
		_text(badge + Vector2(0, 5), {"active": "✓", "available": "+", "blocked": "×"}[state], Color.WHITE)
		if _shows_label(id):
			_text(point + Vector2(0, -30), definition.nodes[id].name, Color("edf2fa"))
		if id == occupied:
			draw_colored_polygon(PackedVector2Array([point + Vector2(-6, 23), point + Vector2(6, 23), point + Vector2(0, 16)]), Color("ffd569"))
			_text(point + Vector2(0, 40), "YOU", Color("ffd569"))

func _text(point: Vector2, text: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(font, point - Vector2(width * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
