extends Node2D

# Loose gold/capacity art and supplemental labels; the room renders chests,
# other objects, geometry and telegraphs. No gameplay state is inferred here.
const ICONS = preload("res://presentation/icons.gd")
var _source: Object
var _snapshot: Dictionary = {}
var _expected_generation: Variant = null

func _ready() -> void:
	z_as_relative = false
	z_index = 100

func bind_coordinator(source: Object) -> void:
	if is_instance_valid(_source) and _source.has_signal("action_room_changed") and _source.is_connected("action_room_changed", _on_room_changed):
		_source.disconnect("action_room_changed", _on_room_changed)
	_source = source
	_expected_generation = null
	if is_instance_valid(_source) and _source.has_signal("action_room_changed"):
		_source.connect("action_room_changed", _on_room_changed)
	refresh_snapshot()

func _on_room_changed(generation: int) -> void:
	_expected_generation = generation
	refresh_snapshot()

func _process(_delta: float) -> void:
	refresh_snapshot()

func refresh_snapshot() -> void:
	var current: Dictionary = _source.room_presentation_state() if is_instance_valid(_source) else {}
	# A notification can precede source replacement; polling must not restore
	# the old room while waiting for the matching generation.
	_snapshot = current.duplicate(true) if _expected_generation == null or current.get("generation") == _expected_generation else {}
	if _expected_generation != null and current.get("generation") == _expected_generation:
		_expected_generation = null
	queue_redraw()

func badges() -> Array:
	var result: Array = []
	for pickup in _snapshot.get("pickups", []):
		var kind: String = pickup.get("kind", "")
		if kind in ["gold", "capacity"] and pickup.get("chest") == false and pickup.get("chest") is bool and pickup.get("position") is Vector2:
			result.append({"icon": kind, "position": pickup.position})
	return result

func terrain_labels() -> Array:
	var result: Array = []
	for object in _snapshot.get("objects", []):
		var kind: String = object.get("kind", "")
		if kind in ["water", "wall"] and object.get("bounds") is Rect2:
			var text := "Water" if kind == "water" else ("Wall (open)" if object.get("passable", false) else "Wall")
			if _terrain_fits(text, object.bounds):
				result.append({"text": text, "bounds": object.bounds})
	for rect in _snapshot.get("obstacles", []):
		if rect is Rect2 and _terrain_fits("Obstacle", rect):
			result.append({"text": "Obstacle", "bounds": rect})
	return result

func enemy_markers() -> Array:
	var result: Array = []
	for enemy in _snapshot.get("enemies", []):
		if not enemy.get("position") is Vector2:
			continue
		var danger: Variant = enemy.get("contact_dangerous")
		var color := Color("bec6d2")
		if danger is bool:
			color = Color("ff875b") if danger else Color("7de1d3")
		result.append({"position": enemy.position, "radius": float(enemy.get("radius", 0.0)), "danger": danger, "color": color})
	return result

func labels() -> Array:
	return terrain_labels()

func _draw() -> void:
	for badge in badges():
		var point: Vector2 = badge.position
		ICONS.draw_icon(self, badge.icon, Rect2(point - Vector2(10, 10), Vector2(20, 20)), Color.WHITE)
	for marker in enemy_markers():
		draw_arc(marker.position, marker.radius + 4.0, 0, TAU, 32, marker.color, 2.0)
	for label in labels():
		_draw_geometry_label(label.text, label.bounds)

func _terrain_fits(text: String, bounds: Rect2) -> bool:
	var font := ThemeDB.fallback_font
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	var angle := -PI / 8.0
	var extent := Vector2(absf(cos(angle)) * size.x + absf(sin(angle)) * size.y,
		absf(sin(angle)) * size.x + absf(cos(angle)) * size.y)
	return bounds.size.x >= extent.x + 8.0 and bounds.size.y >= extent.y + 8.0

func _draw_geometry_label(text: String, bounds: Rect2) -> void:
	if not _terrain_fits(text, bounds):
		return
	var font := ThemeDB.fallback_font
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	var angle := -PI / 8.0
	draw_set_transform(bounds.get_center(), angle)
	var origin := Vector2(-size.x / 2.0, size.y * 0.3)
	draw_string(font, origin + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.BLACK)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_set_transform(Vector2.ZERO)
