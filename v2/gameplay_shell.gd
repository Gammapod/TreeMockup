extends Control

# Owns screen space; gameplay continues in an independent 800x600 world.
var room_viewport: SubViewport
var room_display: TextureRect
var split: HSplitContainer
var map_region: VBoxContainer
var hud: Label
var status: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_window().min_size = Vector2i(960, 640)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	hud = Label.new()
	hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(hud)
	var fullscreen := Button.new()
	fullscreen.text = "Fullscreen / window (F11)"
	fullscreen.focus_mode = Control.FOCUS_NONE
	fullscreen.pressed.connect(toggle_fullscreen)
	header.add_child(fullscreen)
	split = HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 12)
	layout.add_child(split)
	var room_region := PanelContainer.new()
	room_region.custom_minimum_size = Vector2(320, 240)
	room_region.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(room_region)
	room_display = TextureRect.new()
	room_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	room_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_region.add_child(room_display)
	room_viewport = SubViewport.new()
	room_viewport.size = Vector2i(800, 600)
	room_viewport.world_2d = World2D.new()
	room_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	room_display.add_child(room_viewport)
	room_display.texture = room_viewport.get_texture()
	map_region = VBoxContainer.new()
	map_region.custom_minimum_size = Vector2(320, 240)
	map_region.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(map_region)
	var hint := Label.new()
	hint.text = "Drag the divider to resize room / map"
	hint.add_theme_font_size_override("font_size", 13)
	map_region.add_child(hint)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 64
	layout.add_child(status)

func toggle_fullscreen() -> void:
	var window := get_window()
	window.mode = Window.MODE_WINDOWED if window.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN] else Window.MODE_FULLSCREEN

func forward_gameplay_key(event: InputEvent) -> void:
	# TextureRect deliberately handles presentation only. Forward unhandled keys,
	# including when the pointer is over the map; GUI/editor input stays upstream.
	if is_visible_in_tree():
		room_viewport.push_input(event, true)
