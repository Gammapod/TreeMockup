extends SceneTree

# Standalone review only: Godot --path v2 --script res://presentation/icon_review.gd
const Icons = preload("res://presentation/icons.gd")

class ReviewCanvas extends Control:
	const IDS := ["sword", "boots", "health", "gold", "capacity", "token", "neutral"]
	const LABELS := ["Sword", "Boots", "Health cross", "Gold", "Capacity key", "Token", "Neutral fallback"]
	const SIZES := [16.0, 20.0, 24.0]
	const COLORS := [Color("d35645"), Color("4385c3"), Color("d35645"), Color("b57b00"), Color("7963ba"), Color("168272"), Color("687282")]
	const GRAYS := [Color("777777"), Color("777777"), Color("777777"), Color("777777"), Color("777777"), Color("777777"), Color("777777")]

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("e4e8ed"))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(20, 30), "Standalone icons — colored and grayscale", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("14202c"))
		draw_string(font, Vector2(20, 53), "Each group: 16 / 20 / 24 px • Symbols are placeholders; text remains the accessible label.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("263646"))
		_panel(150, Color("192638"), Color("ffffff"), "Dark background")
		_panel(570, Color("ffffff"), Color("172332"), "Light background")
		for i in IDS.size():
			var y := 127.0 + i * 45.0
			draw_string(font, Vector2(20, y + 5), LABELS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("14202c"))
			for panel_x in [150.0, 570.0]:
				for group in 2:
					for j in 3:
						var side: float = SIZES[j]
						var center := Vector2(panel_x + 30 + group * 190 + j * 48, y)
						Icons.draw_icon(self, IDS[i], Rect2(center - Vector2.ONE * side / 2.0, Vector2.ONE * side), COLORS[i] if group == 0 else GRAYS[i])
		draw_string(font, Vector2(20, 464), "Close this window to exit. Grayscale samples deliberately share one tone; shape must carry meaning.", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("263646"))

	func _panel(x: float, background: Color, foreground: Color, title: String) -> void:
		draw_rect(Rect2(x, 65, 410, 365), background)
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(x + 12, 87), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, foreground)
		draw_string(font, Vector2(x + 12, 106), "Color   16   20   24", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, foreground)
		draw_string(font, Vector2(x + 202, 106), "Gray   16   20   24", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, foreground)

func _initialize() -> void:
	root.title = "V2 icon visual review"
	root.size = Vector2i(1000, 490)
	var canvas := ReviewCanvas.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(canvas)
