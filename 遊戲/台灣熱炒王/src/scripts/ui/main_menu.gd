## main_menu.gd — 主選單（Label 節點取代 draw_string，避免 WebGL canvas 問題）
extends Node2D

const BUTTON_RECT := Rect2(160, 148, 160, 22)

func _ready() -> void:
	var font_path := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf"
	var font: Font = null
	if ResourceLoader.exists(font_path):
		font = load(font_path)

	# 主標題
	var title := Label.new()
	title.text = "台灣熱炒王"
	title.position = Vector2(0, 83)
	title.size = Vector2(480, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.1, 1))
	add_child(title)

	# 副標題
	var sub := Label.new()
	sub.text = "TAIWAN STIR-FRY KING"
	sub.position = Vector2(0, 112)
	sub.size = Vector2(480, 16)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		sub.add_theme_font_override("font", font)
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", Color(0.85, 0.55, 0.1, 0.9))
	add_child(sub)

	# 按鈕文字
	var btn_label := Label.new()
	btn_label.text = "開始遊戲"
	btn_label.position = Vector2(160, 151)
	btn_label.size = Vector2(160, 16)
	btn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		btn_label.add_theme_font_override("font", font)
	btn_label.add_theme_font_size_override("font_size", 12)
	btn_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	add_child(btn_label)

	# 版本
	var ver := Label.new()
	ver.text = "v0.1 DEMO"
	ver.position = Vector2(0, 250)
	ver.size = Vector2(475, 12)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if font:
		ver.add_theme_font_override("font", font)
	ver.add_theme_font_size_override("font_size", 8)
	ver.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
	add_child(ver)

	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if BUTTON_RECT.has_point(get_viewport().get_mouse_position()):
			_start_game()
	if event is InputEventScreenTouch and event.pressed:
		if BUTTON_RECT.has_point(event.position):
			_start_game()

func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _draw() -> void:
	# 背景（純 draw_rect，不用 draw_string）
	draw_rect(Rect2(0, 0, 480, 270), Color(0.05, 0.02, 0.08, 1))
	draw_rect(Rect2(0, 0, 480, 50), Color(0.12, 0.04, 0.02, 1))
	draw_rect(Rect2(0, 220, 480, 50), Color(0.08, 0.03, 0.01, 1))

	# 霓虹框線
	draw_rect(Rect2(0, 0, 480, 2), Color(0.9, 0.3, 0.1, 1))
	draw_rect(Rect2(0, 268, 480, 2), Color(0.9, 0.3, 0.1, 1))
	draw_rect(Rect2(0, 0, 2, 270), Color(0.9, 0.3, 0.1, 1))
	draw_rect(Rect2(478, 0, 2, 270), Color(0.9, 0.3, 0.1, 1))
	draw_rect(Rect2(20, 55, 440, 1), Color(0.85, 0.55, 0.1, 0.6))
	draw_rect(Rect2(20, 215, 440, 1), Color(0.85, 0.55, 0.1, 0.6))

	# 按鈕方塊
	draw_rect(Rect2(160, 148, 160, 22), Color(0.75, 0.1, 0.1, 1))
	draw_rect(Rect2(161, 149, 158, 20), Color(0.9, 0.15, 0.15, 1))
