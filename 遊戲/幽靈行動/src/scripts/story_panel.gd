extends CanvasLayer

# 任務完成後的故事片段顯示
# 由 hud.gd 的 _on_game_won() 呼叫

const COL_GOLD := Color(1.0, 0.78, 0.25)

var _panel: ColorRect
var _label: Label
var _top_bar: ColorRect
var _bot_bar: ColorRect
var _accent_line: ColorRect
var _skip_hint: Label
var on_complete: Callable = Callable()
var _can_skip: bool = false
var _done: bool = false
var _font: Font = null

func _ready() -> void:
	layer = 15  # 在 HUD 之上
	if ResourceLoader.exists("res://resources/fonts/chinese_font.ttf"):
		_font = load("res://resources/fonts/chinese_font.ttf")
	_build_visual()

func _build_visual() -> void:
	_panel = ColorRect.new()
	_panel.color = Color(0, 0, 0, 0)  # 初始透明
	_panel.size = Vector2(1080, 1920)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.gui_input.connect(_on_tap)
	add_child(_panel)

	# 電影感上下黑邊（letterbox）
	_top_bar = ColorRect.new()
	_top_bar.color = Color(0, 0, 0, 0)
	_top_bar.size = Vector2(1080, 0)
	_top_bar.position = Vector2(0, 0)
	_panel.add_child(_top_bar)
	_bot_bar = ColorRect.new()
	_bot_bar.color = Color(0, 0, 0, 0)
	_bot_bar.size = Vector2(1080, 0)
	_bot_bar.position = Vector2(0, 1920)
	_panel.add_child(_bot_bar)

	# 文字上方金色強調線
	_accent_line = ColorRect.new()
	_accent_line.color = Color(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, 0.0)
	_accent_line.size = Vector2(0, 3)
	_accent_line.position = Vector2(540, 780)
	_panel.add_child(_accent_line)

	_label = Label.new()
	_label.size = Vector2(880, 220)
	_label.position = Vector2(100, 810)
	if _font:
		_label.add_theme_font_override("font", _font)
	_label.add_theme_font_size_override("font_size", 30)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.modulate = Color(1, 1, 1, 0)  # 初始透明
	_panel.add_child(_label)

	# 跳過提示（右下）
	_skip_hint = Label.new()
	_skip_hint.text = "點擊跳過"
	if _font:
		_skip_hint.add_theme_font_override("font", _font)
	_skip_hint.add_theme_font_size_override("font_size", 22)
	_skip_hint.modulate = Color(0.6, 0.65, 0.7, 0.0)
	_skip_hint.position = Vector2(820, 1820)
	_skip_hint.size = Vector2(220, 30)
	_skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_panel.add_child(_skip_hint)

func _on_tap(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and _can_skip and not _done:
		_done = true
		_on_story_done()

func show_story(mission_id: String, callback: Callable = Callable()) -> void:
	on_complete = callback

	# 載入故事文字
	var text = _get_story_text(mission_id)
	# 無故事文字：直接完成，不阻塞流程
	if text.strip_edges() == "":
		if on_complete.is_valid():
			on_complete.call()
		queue_free()
		return
	_label.text = text

	# 淡入黑底 + letterbox 展開 + 強調線拉伸
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "color:a", 0.88, 0.5)
	tw.tween_property(_top_bar, "size:y", 160.0, 0.45).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bot_bar, "size:y", 160.0, 0.45).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bot_bar, "position:y", 1760.0, 0.45).set_ease(Tween.EASE_OUT)
	tw.chain()
	# 強調線從中央向兩側展開
	tw.set_parallel(true)
	tw.tween_property(_accent_line, "size:x", 360.0, 0.4)
	tw.tween_property(_accent_line, "position:x", 360.0, 0.4)
	tw.tween_property(_accent_line, "color:a", 0.7, 0.4)
	tw.tween_property(_label, "modulate:a", 1.0, 0.5)
	tw.tween_property(_skip_hint, "modulate:a", 0.8, 0.5)
	tw.chain()
	tw.tween_callback(func(): _can_skip = true)
	# 顯示 2.8 秒後淡出
	tw.tween_interval(2.8)
	tw.tween_callback(func():
		if not _done:
			_done = true
			_on_story_done()
	)

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
	# 淡出（黑底 + letterbox 收合）後再完成回呼
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "color:a", 0.0, 0.4)
	tw.tween_property(_label, "modulate:a", 0.0, 0.35)
	tw.tween_property(_skip_hint, "modulate:a", 0.0, 0.25)
	tw.tween_property(_accent_line, "color:a", 0.0, 0.25)
	tw.tween_property(_top_bar, "size:y", 0.0, 0.4)
	tw.tween_property(_bot_bar, "size:y", 0.0, 0.4)
	tw.tween_property(_bot_bar, "position:y", 1920.0, 0.4)
	tw.chain()
	tw.tween_callback(func():
		if on_complete.is_valid():
			on_complete.call()
		queue_free()
	)
