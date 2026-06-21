## main_menu.gd — 主選單（純 CanvasLayer+Control，最大 HTML5 相容性）
extends Node2D

const BUTTON_RECT := Rect2(160, 148, 160, 22)
const CONTINUE_BUTTON_RECT := Rect2(160, 178, 160, 22)

# ── 開場故事 ──────────────────────────────────────────────────────────
## 首次遊玩才播放，之後跳過
const OPENING_SEEN_PATH := "user://opening_seen.flag"

## 開場對話資料（[說話者, 台詞]）
const OPENING_DIALOG: Array = [
	["阿嬤", "妳來了哦。路上沒積水吧？颱風剛走，巷子底那段...唉，不管啦。"],
	["老闆娘", "嗯，來了。阿嬤，這裡...比我想像的小一點。"],
	["阿嬤", "小？以前也是這樣啊，做了三十年，不也好好的。就是阿嬤腳傷了，撐不住。"],
	["老闆娘", "您放心，我會顧好的。"],
	["阿嬤", "嘿，顧好的意思是——不要讓阿龍師傅跑掉。他在這裡做二十幾年，手藝是真的好。（壓低聲音）你對他好一點，他自然會認真。"],
	["阿龍師傅", "（從廚房方向走出來，擦著手，打量玩家）就妳哦。"],
	["老闆娘", "...嗯，就我。"],
	["阿龍師傅", "做過外場嗎？"],
	["老闆娘", "沒有。"],
	["阿龍師傅", "那妳為什麼要接？"],
	["老闆娘", "因為阿嬤說，這裡的客人是真的來吃飯的，不是來喝氣氛的。我覺得這種店值得繼續開。"],
	["阿龍師傅", "（哼了一聲，轉身走回廚房）我去備料了。"],
	["阿嬤", "（把一串鑰匙塞進玩家手裡）這個給妳。招牌那個開關在門裡面右手邊，記得開。裡面的事，妳跟阿龍師傅一起想辦法。"],
	["老闆娘", "好。（看著手裡的鑰匙）我知道了。"],
	["阿嬤", "那阿嬤先走哦。（停在門口，回頭）加油啦，妳可以的。"],
	["老闆娘", "（把招牌開關打開——霓虹燈管亮起來，一半，還差一半，但夠了。）好。第一天，開始。"],
]

## 目前顯示到第幾頁對話
var _dialog_index: int = 0

## 開場故事 UI 節點
var _opening_layer: CanvasLayer = null
var _opening_speaker_lbl: Label = null
var _opening_text_lbl: Label = null
var _opening_hint_lbl: Label = null
var _opening_progress_lbl: Label = null

## 開場故事播放中旗標
var _showing_opening: bool = false

# ── 視覺改善新增 member variables ────────────────────────────────────

## 打字機效果
var _typing: bool = false
var _full_text: String = ""
var _type_index: int = 0

## 頁面過渡保護
var _is_transitioning: bool = false

## 背景氛圍色 ColorRect 參考
var _opening_bg: ColorRect = null

## 角色頭像色塊 ColorRect 參考（內框彩色塊）
var _avatar_rect: ColorRect = null

## 霓虹招牌 Label 參考
var _neon_label: Label = null


func _ready() -> void:
	var font: Font = null
	var font_path := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf"
	if ResourceLoader.exists(font_path):
		font = load(font_path)

	var cl := CanvasLayer.new()
	cl.layer = 0
	add_child(cl)

	_rect(cl, 0, 0, 480, 270, Color(0.05, 0.02, 0.08))
	_rect(cl, 0, 0, 480, 50, Color(0.12, 0.04, 0.02))
	_rect(cl, 0, 220, 480, 50, Color(0.08, 0.03, 0.01))
	_rect(cl, 0, 0, 480, 2, Color(0.9, 0.3, 0.1))
	_rect(cl, 0, 268, 480, 2, Color(0.9, 0.3, 0.1))
	_rect(cl, 0, 0, 2, 270, Color(0.9, 0.3, 0.1))
	_rect(cl, 478, 0, 2, 270, Color(0.9, 0.3, 0.1))
	_rect(cl, 20, 55, 440, 1, Color(0.85, 0.55, 0.1, 0.6))
	_rect(cl, 20, 215, 440, 1, Color(0.85, 0.55, 0.1, 0.6))
	# 窗戶燈光（黃色矩形，模擬深夜建築）
	_rect(cl, 30, 60, 20, 30, Color(0.9, 0.8, 0.1, 0.15))
	_rect(cl, 60, 55, 20, 25, Color(0.9, 0.8, 0.1, 0.12))
	_rect(cl, 380, 65, 22, 28, Color(0.9, 0.8, 0.1, 0.15))
	_rect(cl, 420, 58, 18, 32, Color(0.9, 0.8, 0.1, 0.12))
	# 霓虹招牌效果（左右各一個紅色橫條）
	_rect(cl, 15, 135, 40, 8, Color(0.9, 0.1, 0.1, 0.5))
	_rect(cl, 425, 140, 40, 8, Color(0.9, 0.1, 0.1, 0.5))

	_rect(cl, 160, 148, 160, 22, Color(0.75, 0.1, 0.1))
	_rect(cl, 161, 149, 158, 20, Color(0.9, 0.15, 0.15))

	_label(cl, font, "台灣熱炒王",           0, 83,  480, 30, 24, Color(1, 0.85, 0.1))
	_label(cl, font, "TAIWAN STIR-FRY KING", 0, 112, 480, 16, 10, Color(0.85, 0.55, 0.1, 0.9))
	_label(cl, font, "開始遊戲",             160, 151, 160, 16, 12, Color(1, 1, 1))

	# 繼續遊戲按鈕（僅在存檔存在時顯示）
	if SaveManager.has_save_file():
		_rect(cl, 160, 178, 160, 22, Color(0.1, 0.4, 0.15))
		_rect(cl, 161, 179, 158, 20, Color(0.15, 0.55, 0.2))
		_label(cl, font, "繼續遊戲", 160, 181, 160, 16, 12, Color(0.9, 1.0, 0.9))

	_label(cl, font, "v1.1 DEMO",            0, 250, 475, 12,  8, Color(0.5, 0.5, 0.5, 0.7),
		HORIZONTAL_ALIGNMENT_RIGHT)

	# 路人動畫：兩個黃色小方塊從左右兩側緩慢移動
	_add_pedestrian(cl, Vector2(20, 210), true)   # 從左往右
	_add_pedestrian(cl, Vector2(400, 225), false)  # 從右往左


func _add_pedestrian(parent: Node, start_pos: Vector2, go_right: bool) -> void:
	var ped := ColorRect.new()
	ped.color = Color(0.9, 0.8, 0.2, 0.7)  # 黃色路人色塊
	ped.size = Vector2(5, 10)
	ped.position = start_pos
	parent.add_child(ped)

	# 使用 Tween 讓路人來回移動
	var tw := create_tween()
	tw.set_loops()  # 無限循環
	if go_right:
		tw.tween_property(ped, "position:x", 460.0, 8.0)
		tw.tween_property(ped, "position:x", start_pos.x, 8.0)
	else:
		tw.tween_property(ped, "position:x", 20.0, 8.0)
		tw.tween_property(ped, "position:x", start_pos.x, 8.0)


func _rect(parent: Node, x: float, y: float, w: float, h: float, color: Color) -> void:
	var r := ColorRect.new()
	r.position = Vector2(x, y)
	r.size = Vector2(w, h)
	r.color = color
	parent.add_child(r)

func _label(parent: Node, font: Font, text: String,
		x: float, y: float, w: float, h: float,
		size: int, color: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.position = Vector2(x, y)
	lb.size = Vector2(w, h)
	lb.horizontal_alignment = align
	if font: lb.add_theme_font_override("font", font)
	lb.add_theme_font_size_override("font_size", size)
	lb.add_theme_color_override("font_color", color)
	parent.add_child(lb)
	return lb

func _input(event: InputEvent) -> void:
	if _showing_opening:
		# 開場故事中：點擊推進對話
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_opening_click()
		elif event is InputEventScreenTouch and event.pressed:
			_handle_opening_click()
		return

	# 主選單正常輸入
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mp := get_viewport().get_mouse_position()
		if BUTTON_RECT.has_point(mp):
			_start_game()
		elif CONTINUE_BUTTON_RECT.has_point(mp) and SaveManager.has_save_file():
			_continue_game()
	if event is InputEventScreenTouch and event.pressed:
		if BUTTON_RECT.has_point(event.position):
			_start_game()
		elif CONTINUE_BUTTON_RECT.has_point(event.position) and SaveManager.has_save_file():
			_continue_game()

## 處理開場故事的點擊邏輯
func _handle_opening_click() -> void:
	# 正在換頁過渡期間，忽略點擊
	if _is_transitioning:
		return

	if _typing:
		# 打字進行中：立即顯示完整文字
		_typing = false
		if _opening_text_lbl:
			_opening_text_lbl.text = _full_text
	else:
		# 打字已完成：推進到下一頁
		_advance_opening_dialog()

func _start_game() -> void:
	# 首次遊玩先播開場故事
	if not FileAccess.file_exists(OPENING_SEEN_PATH):
		_show_opening_story()
	else:
		get_tree().change_scene_to_file("res://scenes/main/Main.tscn")


func _continue_game() -> void:
	# 驗證存檔可讀，損壞時刪除並開始新遊戲
	var save_data: Dictionary = SaveManager.load_game()
	if save_data.is_empty() or not save_data.has("game_data"):
		# 存檔損壞，刪除並以新遊戲模式進入
		SaveManager.delete_save()
		get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main/Main.tscn")


# ============================================================
# 開場故事
# ============================================================

func _show_opening_story() -> void:
	_showing_opening = true
	_dialog_index = 0

	# 開場故事播放期間暫停 GameManager 時間推進，避免客人提早進場
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("pause_time"):
		gm.pause_time()

	var font: Font = null
	var font_path := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf"
	if ResourceLoader.exists(font_path):
		font = load(font_path)

	# 建立 CanvasLayer（layer=10，蓋在主選單上方）
	_opening_layer = CanvasLayer.new()
	_opening_layer.layer = 10
	add_child(_opening_layer)

	# ── 1. 全螢幕氛圍背景（可動態變色）────────────────────────────
	_opening_bg = ColorRect.new()
	_opening_bg.color = Color(0.04, 0.02, 0.06, 0.97)
	_opening_bg.size = Vector2(480, 270)
	_opening_bg.position = Vector2.ZERO
	_opening_layer.add_child(_opening_bg)

	# 場景說明（頂部）
	var scene_lbl := Label.new()
	scene_lbl.text = "台北某個巷弄轉角，颱風剛走的夏天傍晚"
	scene_lbl.position = Vector2(0, 12)
	scene_lbl.size = Vector2(480, 14)
	scene_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene_lbl.add_theme_color_override("font_color", Color(0.6, 0.5, 0.3, 0.8))
	if font:
		scene_lbl.add_theme_font_override("font", font)
	scene_lbl.add_theme_font_size_override("font_size", 8)
	_opening_layer.add_child(scene_lbl)

	# 分隔線
	var sep := ColorRect.new()
	sep.color = Color(0.85, 0.55, 0.1, 0.4)
	sep.size = Vector2(440, 1)
	sep.position = Vector2(20, 30)
	_opening_layer.add_child(sep)

	# ── 4. 霓虹招牌 Label（畫面中間）───────────────────────────────
	_neon_label = Label.new()
	_neon_label.text = ""
	_neon_label.position = Vector2(0, 100)
	_neon_label.size = Vector2(480, 20)
	_neon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		_neon_label.add_theme_font_override("font", font)
	_neon_label.add_theme_font_size_override("font_size", 8)
	_neon_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.1, 0.4))
	_opening_layer.add_child(_neon_label)

	# 對話框背景
	var dialog_bg := ColorRect.new()
	dialog_bg.color = Color(0.102, 0.102, 0.180, 0.92)
	dialog_bg.size = Vector2(460, 80)
	dialog_bg.position = Vector2(10, 168)
	_opening_layer.add_child(dialog_bg)

	# ── 2. 角色頭像色塊（對話框左側）──────────────────────────────
	# 外框（白色底 34x34）
	var avatar_border := ColorRect.new()
	avatar_border.color = Color(1.0, 1.0, 1.0, 0.9)
	avatar_border.size = Vector2(34, 34)
	avatar_border.position = Vector2(14, 172)
	_opening_layer.add_child(avatar_border)

	# 內塊（彩色 30x30，依說話者變色）
	_avatar_rect = ColorRect.new()
	_avatar_rect.color = Color(0.3, 0.3, 0.4)
	_avatar_rect.size = Vector2(30, 30)
	_avatar_rect.position = Vector2(16, 174)
	_opening_layer.add_child(_avatar_rect)

	# 說話者 Label（從 x=60 開始，為頭像留空間）
	_opening_speaker_lbl = Label.new()
	_opening_speaker_lbl.position = Vector2(60, 174)
	_opening_speaker_lbl.size = Vector2(200, 14)
	_opening_speaker_lbl.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0))
	if font:
		_opening_speaker_lbl.add_theme_font_override("font", font)
	_opening_speaker_lbl.add_theme_font_size_override("font_size", 10)
	_opening_layer.add_child(_opening_speaker_lbl)

	# 對話文字 Label（從 x=60 開始，為頭像留空間）
	_opening_text_lbl = Label.new()
	_opening_text_lbl.position = Vector2(60, 190)
	_opening_text_lbl.size = Vector2(400, 52)
	_opening_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_opening_text_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	if font:
		_opening_text_lbl.add_theme_font_override("font", font)
	_opening_text_lbl.add_theme_font_size_override("font_size", 9)
	_opening_layer.add_child(_opening_text_lbl)

	# 繼續提示
	_opening_hint_lbl = Label.new()
	_opening_hint_lbl.text = "點擊繼續 ▶"
	_opening_hint_lbl.position = Vector2(0, 248)
	_opening_hint_lbl.size = Vector2(475, 12)
	_opening_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_opening_hint_lbl.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4, 0.8))
	if font:
		_opening_hint_lbl.add_theme_font_override("font", font)
	_opening_hint_lbl.add_theme_font_size_override("font_size", 8)
	_opening_layer.add_child(_opening_hint_lbl)

	# 進度指示
	_opening_progress_lbl = Label.new()
	_opening_progress_lbl.position = Vector2(0, 248)
	_opening_progress_lbl.size = Vector2(200, 12)
	_opening_progress_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
	if font:
		_opening_progress_lbl.add_theme_font_override("font", font)
	_opening_progress_lbl.add_theme_font_size_override("font_size", 8)
	_opening_layer.add_child(_opening_progress_lbl)

	_update_opening_dialog_content()


## 取得說話者對應的頭像顏色
func _get_speaker_color(speaker: String) -> Color:
	match speaker:
		"阿嬤":
			return Color(0.8, 0.5, 0.1)
		"老闆娘":
			return Color(0.7, 0.2, 0.3)
		"阿龍師傅":
			return Color(0.2, 0.4, 0.6)
		_:
			return Color(0.3, 0.3, 0.4)


## 取得當前頁面對應的背景氛圍色
func _get_bg_color_for_index(idx: int) -> Color:
	if idx <= 3:
		return Color(0.04, 0.02, 0.06)
	elif idx <= 10:
		return Color(0.08, 0.04, 0.01)
	else:
		return Color(0.02, 0.04, 0.08)


## 純粹更新對話框內容（不含過渡動畫）
func _update_opening_dialog_content() -> void:
	if _dialog_index >= OPENING_DIALOG.size():
		_finish_opening_story()
		return

	var entry: Array = OPENING_DIALOG[_dialog_index]
	var speaker: String = entry[0]
	var text: String = entry[1]

	# 更新說話者
	if _opening_speaker_lbl:
		_opening_speaker_lbl.text = "【%s】" % speaker

	# 更新頭像顏色
	if _avatar_rect:
		_avatar_rect.color = _get_speaker_color(speaker)

	# 更新進度
	if _opening_progress_lbl:
		_opening_progress_lbl.text = "%d / %d" % [_dialog_index + 1, OPENING_DIALOG.size()]

	# 更新背景氛圍色（Tween 淡入）
	if _opening_bg:
		var target_bg := _get_bg_color_for_index(_dialog_index)
		var tw_bg := create_tween()
		tw_bg.tween_property(_opening_bg, "color", target_bg, 0.3)

	# 更新霓虹招牌
	if _neon_label:
		if _dialog_index <= 4:
			_neon_label.text = ""
		elif _dialog_index <= 12:
			_neon_label.text = "熱炒 · 串燒 · 冷飲"
			_neon_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.1, 0.4))
			_neon_label.add_theme_font_size_override("font_size", 8)
		else:
			_neon_label.text = "阿嬤熱炒"
			_neon_label.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0, 0.7))
			_neon_label.add_theme_font_size_override("font_size", 12)

	# 啟動打字機效果
	_full_text = text
	_type_index = 0
	_typing = true
	if _opening_text_lbl:
		_opening_text_lbl.text = ""
	_type_next_char()


## 打字機：逐字顯示
func _type_next_char() -> void:
	if not _typing:
		return
	if _type_index < _full_text.length():
		if _opening_text_lbl:
			_opening_text_lbl.text = _full_text.substr(0, _type_index + 1)
		_type_index += 1
		get_tree().create_timer(0.04).timeout.connect(_type_next_char, CONNECT_ONE_SHOT)
	else:
		_typing = false


## 換頁（含淡出→更新內容→淡入）
func _advance_opening_dialog() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_dialog_index += 1

	# 淡出（modulate.a 1.0 → 0.0，0.15 秒）
	if _opening_speaker_lbl and _opening_text_lbl:
		var tw_out := create_tween()
		tw_out.set_parallel(true)
		tw_out.tween_property(_opening_speaker_lbl, "modulate:a", 0.0, 0.15)
		tw_out.tween_property(_opening_text_lbl, "modulate:a", 0.0, 0.15)
		if _avatar_rect:
			tw_out.tween_property(_avatar_rect, "modulate:a", 0.0, 0.15)
		await tw_out.finished

	# 更新內容
	_update_opening_dialog_content()

	# 淡入（modulate.a 0.0 → 1.0，0.15 秒）
	if _opening_speaker_lbl and _opening_text_lbl:
		var tw_in := create_tween()
		tw_in.set_parallel(true)
		tw_in.tween_property(_opening_speaker_lbl, "modulate:a", 1.0, 0.15)
		tw_in.tween_property(_opening_text_lbl, "modulate:a", 1.0, 0.15)
		if _avatar_rect:
			tw_in.tween_property(_avatar_rect, "modulate:a", 1.0, 0.15)
		await tw_in.finished

	_is_transitioning = false


func _finish_opening_story() -> void:
	# 記錄已看過開場故事
	var file := FileAccess.open(OPENING_SEEN_PATH, FileAccess.WRITE)
	if file:
		file.store_string("seen")
		file.close()

	# 移除開場故事 UI
	if _opening_layer:
		_opening_layer.queue_free()
		_opening_layer = null

	_showing_opening = false
	_typing = false
	_is_transitioning = false

	# 開場故事結束，恢復 GameManager 時間推進
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("resume_time"):
		gm.resume_time()

	# 進入遊戲
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
