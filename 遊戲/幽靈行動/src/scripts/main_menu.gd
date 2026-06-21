extends Node2D

# 主選單畫面 — 進遊戲後最先出現，淡入後顯示開始按鈕

const CHINESE_FONT_PATH := "res://resources/fonts/chinese_font.ttf"
const BG_SVG_PATH := "res://resources/art/ui/main_menu_bg.svg"
const BASE_SCENE_PATH := "res://scenes/Base.tscn"

var _font: FontFile
var _ui_layer: CanvasLayer
var _fade_overlay: ColorRect


func _ready() -> void:
	_load_font()
	_build_ui()
	_play_intro_fade()


# ─── 字體載入 ───────────────────────────────────────────────

func _load_font() -> void:
	if ResourceLoader.exists(CHINESE_FONT_PATH):
		_font = load(CHINESE_FONT_PATH)


# ─── UI 建構 ────────────────────────────────────────────────

func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 0
	add_child(_ui_layer)

	_build_background()
	_build_title()
	_build_subtitle()
	_build_divider()
	_build_start_button()
	_build_version_label()
	_build_fade_overlay()

	# 入場前先全黑（透過黑色蓋板），等 _play_intro_fade 淡入
	_fade_overlay.color = Color(0, 0, 0, 1.0)


func _build_background() -> void:
	if ResourceLoader.exists(BG_SVG_PATH):
		var tex: Texture2D = load(BG_SVG_PATH)
		var bg := TextureRect.new()
		bg.texture = tex
		bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.size = Vector2(1080, 1920)
		bg.position = Vector2.ZERO
		_ui_layer.add_child(bg)
	else:
		var fallback := ColorRect.new()
		fallback.size = Vector2(1080, 1920)
		fallback.position = Vector2.ZERO
		fallback.color = Color("#050A14")
		_ui_layer.add_child(fallback)


func _build_title() -> void:
	var label := Label.new()
	label.text = "幽靈行動"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(1080, 120)
	label.position = Vector2(0, 320)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 96)
	if _font:
		label.add_theme_font_override("font", _font)
	# 字體陰影
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	_ui_layer.add_child(label)


func _build_subtitle() -> void:
	var label := Label.new()
	label.text = "GHOST MISSION"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(1080, 50)
	label.position = Vector2(0, 460)
	label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 1.0))
	label.add_theme_font_size_override("font_size", 28)
	if _font:
		label.add_theme_font_override("font", _font)
	_ui_layer.add_child(label)

	# 中文副標題
	var sub2 := Label.new()
	sub2.text = "戰術潛入 · 傭兵養成"
	sub2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub2.size = Vector2(1080, 44)
	sub2.position = Vector2(0, 508)
	sub2.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9, 0.85))
	sub2.add_theme_font_size_override("font_size", 22)
	if _font:
		sub2.add_theme_font_override("font", _font)
	_ui_layer.add_child(sub2)


func _build_divider() -> void:
	var line := ColorRect.new()
	line.size = Vector2(200, 2)
	line.position = Vector2((1080 - 200) / 2.0, 562)
	line.color = Color(0.3, 0.5, 0.8, 1.0)
	_ui_layer.add_child(line)


func _build_start_button() -> void:
	var btn := Button.new()
	btn.text = "開始遊戲"
	btn.size = Vector2(460, 110)
	btn.position = Vector2((1080 - 460) / 2.0, 700)
	btn.add_theme_font_size_override("font_size", 40)
	btn.add_theme_color_override("font_color", Color("#FF8C00"))
	btn.add_theme_color_override("font_hover_color", Color("#FFA040"))
	btn.add_theme_color_override("font_pressed_color", Color("#CC6600"))
	if _font:
		btn.add_theme_font_override("font", _font)

	# 深藍背景樣式
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color("#1A3060")
	normal_style.border_width_left   = 2
	normal_style.border_width_right  = 2
	normal_style.border_width_top    = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.3, 0.5, 0.8, 0.6)
	normal_style.corner_radius_top_left     = 8
	normal_style.corner_radius_top_right    = 8
	normal_style.corner_radius_bottom_left  = 8
	normal_style.corner_radius_bottom_right = 8

	var hover_style := normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color("#22408A")
	hover_style.border_color = Color(0.4, 0.6, 1.0, 0.8)

	var pressed_style := normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color("#101E40")

	btn.add_theme_stylebox_override("normal",  normal_style)
	btn.add_theme_stylebox_override("hover",   hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.pressed.connect(_on_start_pressed)
	_ui_layer.add_child(btn)


func _build_version_label() -> void:
	var label := Label.new()
	label.text = "v0.4.0 DEMO"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.size = Vector2(200, 30)
	label.position = Vector2(1080 - 210, 1870)
	label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4, 1.0))
	label.add_theme_font_size_override("font_size", 18)
	if _font:
		label.add_theme_font_override("font", _font)
	_ui_layer.add_child(label)


func _build_fade_overlay() -> void:
	# 黑色蓋板，用於離開時淡出
	_fade_overlay = ColorRect.new()
	_fade_overlay.size = Vector2(1080, 1920)
	_fade_overlay.position = Vector2.ZERO
	_fade_overlay.color = Color(0, 0, 0, 0)
	_fade_overlay.z_index = 10
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_fade_overlay)


# ─── 入場淡入 ────────────────────────────────────────────────

func _play_intro_fade() -> void:
	# 黑色蓋板從不透明漸變成透明，模擬淡入效果
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "color:a", 0.0, 0.8)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_SINE)


# ─── 按鈕事件 ────────────────────────────────────────────────

func _on_start_pressed() -> void:
	# 先淡出再切換場景
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "color:a", 1.0, 0.5)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_goto_base)


func _goto_base() -> void:
	get_tree().change_scene_to_file(BASE_SCENE_PATH)
