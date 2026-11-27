extends RefCounted

const IDS := ["sword", "boots", "health", "gold", "capacity", "token", "neutral"]

static func resolve_id(value: Variant) -> String:
	return value if value is String and value in IDS else "neutral"

# Frontend-only, normalized line art. IDs describe symbols, not node benefits.
# Call draw_icon from a CanvasItem's _draw(); retain a textual label alongside it.
static func strokes(id: String) -> Array:
	var art := {
		"sword": [
			[Vector2(.18, .82), Vector2(.4, .6), Vector2(.32, .52), Vector2(.48, .68)],
			[Vector2(.4, .6), Vector2(.74, .16), Vector2(.86, .12), Vector2(.82, .26), Vector2(.48, .68)]
		],
		"boots": [
			[Vector2(.22, .15), Vector2(.57, .15), Vector2(.57, .48), Vector2(.69, .61), Vector2(.83, .65), Vector2(.83, .82), Vector2(.16, .82), Vector2(.16, .67), Vector2(.22, .6), Vector2(.22, .15)],
			[Vector2(.18, .72), Vector2(.82, .72)]
		],
		"health": [
			[Vector2(.39, .15), Vector2(.61, .15), Vector2(.61, .39), Vector2(.85, .39), Vector2(.85, .61), Vector2(.61, .61), Vector2(.61, .85), Vector2(.39, .85), Vector2(.39, .61), Vector2(.15, .61), Vector2(.15, .39), Vector2(.39, .39), Vector2(.39, .15)]
		],
		"gold": [
			[Vector2(.76, .25), Vector2(.65, .17), Vector2(.35, .17), Vector2(.23, .28), Vector2(.23, .4), Vector2(.35, .5), Vector2(.65, .5), Vector2(.77, .6), Vector2(.77, .72), Vector2(.65, .83), Vector2(.35, .83), Vector2(.24, .75)],
			[Vector2(.5, .09), Vector2(.5, .91)]
		],
		"capacity": [
			[Vector2(.18, .3), Vector2(.22, .19), Vector2(.33, .15), Vector2(.44, .19), Vector2(.48, .3), Vector2(.44, .41), Vector2(.33, .45), Vector2(.22, .41), Vector2(.18, .3)],
			[Vector2(.43, .4), Vector2(.81, .78), Vector2(.72, .87), Vector2(.62, .77), Vector2(.69, .7)],
			[Vector2(.55, .52), Vector2(.47, .6)]
		],
		"token": [
			[Vector2(.5, .12), Vector2(.76, .24), Vector2(.88, .5), Vector2(.76, .76), Vector2(.5, .88), Vector2(.24, .76), Vector2(.12, .5), Vector2(.24, .24), Vector2(.5, .12)],
			[Vector2(.5, .29), Vector2(.67, .5), Vector2(.5, .71), Vector2(.33, .5), Vector2(.5, .29)]
		],
		"neutral": [
			[Vector2(.5, .12), Vector2(.85, .5), Vector2(.5, .88), Vector2(.15, .5), Vector2(.5, .12)],
			[Vector2(.5, .33), Vector2(.5, .54)],
			[Vector2(.5, .67), Vector2(.5, .69)]
		]
	}
	return art.get(id, art["neutral"]).duplicate(true)

static func draw_icon(canvas: CanvasItem, id: String, rect: Rect2, color: Color = Color.WHITE) -> void:
	var side := minf(rect.size.x, rect.size.y)
	if side <= 0.0:
		return
	var origin := rect.position + (rect.size - Vector2.ONE * side) * 0.5
	for stroke in strokes(id):
		var points := PackedVector2Array()
		for point in stroke:
			points.append(origin + point * side)
		canvas.draw_polyline(points, color, maxf(1.0, side * 0.07), true)
