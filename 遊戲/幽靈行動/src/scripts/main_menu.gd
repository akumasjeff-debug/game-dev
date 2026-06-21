extends Control

const CHINESE_FONT_PATH := "res://resources/fonts/chinese_font.ttf"
const BASE_SCENE_PATH    := "res://scenes/Base.tscn"

var _font: FontFile
var _fade: ColorRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists(CHINESE_FONT_PATH):
		_font = load(CHINESE_FONT_PATH)
	_build_bg()
	_build_title()
	_build_button()
	_build_version()
	_build_fade()
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.85).set_ease(Tween.EASE_OUT)

func _build_bg() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.04, 0.10)
	add_child(bg)

func _build_title() -> void:
	var title := Label.new()
	title.text = "幽靈行動"
	title.set_anchor_and_offset(SIDE_LEFT,   0.0, 0)
	title.set_anchor_and_offset(SIDE_RIGHT,  1.0, 0)
	title.set_anchor_and_offset(SIDE_TOP,    0.0, 280)
	title.set_anchor_and_offset(SIDE_BOTTOM, 0.0, 420)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 88)
	title.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0, 0.1, 0.4, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	if _font:
		title.add_theme_font_override("font", _font)
	add_child(title)

	var sub := Label.new()
	sub.text = "GHOST MISSION"
	sub.set_anchor_and_offset(SIDE_LEFT,   0.0, 0)
	sub.set_anchor_and_offset(SIDE_RIGHT,  1.0, 0)
	sub.set_anchor_and_offset(SIDE_TOP,    0.0, 430)
	sub.set_anchor_and_offset(SIDE_BOTTOM, 0.0, 490)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 26)
	sub.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.85))
	if _font:
		sub.add_theme_font_override("font", _font)
	add_child(sub)

	var sub2 := Label.new()
	sub2.text = "戰術潛入 · 傭兵養成"
	sub2.set_anchor_and_offset(SIDE_LEFT,   0.0, 0)
	sub2.set_anchor_and_offset(SIDE_RIGHT,  1.0, 0)
	sub2.set_anchor_and_offset(SIDE_TOP,    0.0, 490)
	sub2.set_anchor_and_offset(SIDE_BOTTOM, 0.0, 545)
	sub2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub2.add_theme_font_size_override("font_size", 22)
	sub2.add_theme_color_override("font_color", Color(0.45, 0.65, 0.85, 0.75))
	if _font:
		sub2.add_theme_font_override("font", _font)
	add_child(sub2)

	var line := ColorRect.new()
	line.set_anchor_and_offset(SIDE_LEFT,   0.5, -100)
	line.set_anchor_and_offset(SIDE_RIGHT,  0.5,  100)
	line.set_anchor_and_offset(SIDE_TOP,    0.0,  555)
	line.set_anchor_and_offset(SIDE_BOTTOM, 0.0,  558)
	line.color = Color(0.3, 0.5, 0.9, 0.6)
	add_child(line)

func _build_button() -> void:
	var btn := Button.new()
	btn.text = "開始遊戲"
	btn.set_anchor_and_offset(SIDE_LEFT,   0.5, -230)
	btn.set_anchor_and_offset(SIDE_RIGHT,  0.5,  230)
	btn.set_anchor_and_offset(SIDE_TOP,    0.0,  630)
	btn.set_anchor_and_offset(SIDE_BOTTOM, 0.0,  750)
	btn.add_theme_font_size_override("font_size", 40)
	btn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.0))
	if _font:
		btn.add_theme_font_override("font", _font)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.16, 0.38)
	st.border_color = Color(0.3, 0.5, 0.9, 0.7)
	st.set_border_width_all(2)
	st.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", st)
	var sh := st.duplicate() as StyleBoxFlat
	sh.bg_color = Color(0.12, 0.24, 0.52)
	sh.border_color = Color(0.45, 0.65, 1.0)
	btn.add_theme_stylebox_override("hover", sh)
	btn.pressed.connect(_on_start)
	add_child(btn)

func _build_version() -> void:
	var lbl := Label.new()
	lbl.text = "v0.4.3 DEMO"
	lbl.set_anchor_and_offset(SIDE_LEFT,   1.0, -210)
	lbl.set_anchor_and_offset(SIDE_RIGHT,  1.0, -10)
	lbl.set_anchor_and_offset(SIDE_TOP,    1.0, -50)
	lbl.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -10)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
	if _font:
		lbl.add_theme_font_override("font", _font)
	add_child(lbl)

func _build_fade() -> void:
	_fade = ColorRect.new()
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0, 0, 0, 1.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

func _on_start() -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.45).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): get_tree().change_scene_to_file(BASE_SCENE_PATH))
