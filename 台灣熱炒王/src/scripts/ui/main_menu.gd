## main_menu.gd
## 主選單腳本 — 全程式碼建構 UI

extends Node

func _ready() -> void:
	_build_ui()
	print("[MainMenu] 主選單就緒")

func _build_ui() -> void:
	# 深褐色背景
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.04, 0.01, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 標題 Label
	var title := Label.new()
	title.text = "台灣熱炒王"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
	title.add_theme_font_size_override("font_size", 32)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	title.position = Vector2(160, 80)
	add_child(title)

	# 開始按鈕
	var btn := Button.new()
	btn.text = "開始遊戲"
	btn.position = Vector2(175, 150)
	btn.size = Vector2(130, 32)
	btn.pressed.connect(_on_start_pressed)
	add_child(btn)

func _on_start_pressed() -> void:
	print("[MainMenu] 切換到遊戲場景")
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
