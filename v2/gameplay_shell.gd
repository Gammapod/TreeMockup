extends Control

# Owns screen space; gameplay continues in an independent 800x600 world.
var room_viewport: SubViewport
var room_display: TextureRect
var split: HSplitContainer
var map_region: VBoxContainer
var hud: Label
var status: Label
var arena_button: Button
var retry_button: Button

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
	arena_button = Button.new()
	arena_button.text = "BUILD-01 arena"
	arena_button.focus_mode = Control.FOCUS_NONE
	header.add_child(arena_button)
	retry_button = Button.new()
	retry_button.text = "Restart trial (keep build)"
	retry_button.tooltip_text = "Fresh trial: return to Workshop, restore HP and enemies, retain allocations."
	retry_button.focus_mode = Control.FOCUS_NONE
	retry_button.hide()
	header.add_child(retry_button)
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

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventKey:
		return
	if event.keycode != KEY_SPACE and event.physical_keycode != KEY_SPACE:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused is Button and map_region.is_ancestor_of(focused):
		forward_gameplay_key(event)
		get_viewport().set_input_as_handled()

func forward_gameplay_key(event: InputEvent) -> void:
	# TextureRect deliberately handles presentation only. Forward unhandled keys,
	# including when the pointer is over the map; GUI/editor input stays upstream.
	if is_visible_in_tree():
		room_viewport.push_input(event, true)
