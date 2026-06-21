extends CanvasLayer

# 任務完成後的故事片段顯示
# 由 hud.gd 的 _on_game_won() 呼叫

var _panel: ColorRect
var _label: Label
var on_complete: Callable = Callable()

func _ready() -> void:
	layer = 15  # 在 HUD 之上
	_build_visual()

func _build_visual() -> void:
	_panel = ColorRect.new()
	_panel.color = Color(0, 0, 0, 0)  # 初始透明
	_panel.size = Vector2(1080, 1920)
	add_child(_panel)

	_label = Label.new()
	_label.size = Vector2(800, 200)
	_label.position = Vector2(140, 800)
	_label.add_theme_font_size_override("font_size", 28)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.modulate = Color(1, 1, 1, 0)  # 初始透明
	_panel.add_child(_label)

func show_story(mission_id: String, callback: Callable = Callable()) -> void:
	on_complete = callback

	# 載入故事文字
	var text = _get_story_text(mission_id)
	_label.text = text

	# 淡入黑底
	var tw = create_tween()
	tw.tween_property(_panel, "color:a", 0.85, 0.5)
	tw.parallel().tween_property(_label, "modulate:a", 1.0, 0.6)
	# 顯示 2.5 秒後淡出
	tw.tween_interval(2.5)
	tw.tween_property(_panel, "color:a", 0.0, 0.5)
	tw.parallel().tween_property(_label, "modulate:a", 0.0, 0.5)
	tw.tween_callback(_on_story_done)

func _get_story_text(mission_id: String) -> String:
	var path = "res://resources/data/mission_stories.json"
	if not ResourceLoader.exists(path):
		return ""
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null or not data.has(mission_id):
		return ""
	var stories: Array = data[mission_id]
	if stories.is_empty():
		return ""
	return stories[randi() % stories.size()]

func _on_story_done() -> void:
	if on_complete.is_valid():
		on_complete.call()
	queue_free()
