## YearEndingManager.gd
## 年份結局故事系統 AutoLoad Singleton
## 負責：在每年結束時顯示對應年份的故事對話，打字機效果，點擊翻頁。
## 在 project.godot 的 [autoload] 區塊新增：
##   YearEndingManager="*res://scripts/systems/YearEndingManager.gd"

extends Node


# ============================================================
# 信號定義
# ============================================================

## 結局故事播放完畢後發出，讓遊戲繼續推進。
signal year_ending_finished(year: int)


# ============================================================
# 年份結局故事資料
# ============================================================

## 每個年份對應一個對話陣列，每個元素為 [說話者, 台詞]。
## 佔位文字——後續由 year-endings.md 填入完整內容。
const YEAR_ENDINGS: Dictionary = {
	1: [
		["旁白", "第一年，就這樣過去了。"],
		["阿龍師傅", "（關爐火，擦手，停了很久）...差不多了。"],
		["老闆娘", "什麼差不多了？"],
		["阿龍師傅", "妳——有那個樣子了。"],
	],
	2: [
		["旁白", "第二年，有人在臉書說我們是「台北巷弄祕密景點」。"],
		["阿龍師傅", "（瞄了一眼手機，沒說話，但嘴角動了一下）"],
		["老闆娘", "師傅，你在偷笑。"],
		["阿龍師傅", "哪有。"],
	],
	3: [
		["旁白", "第三年，對手阿義嫂收攤了。"],
		["阿弟", "老闆，阿義嫂昨天來道謝耶。"],
		["老闆娘", "我知道。"],
		["阿弟", "你們握手了嗎？"],
		["老闆娘", "她說她要去台南跟女兒住。（頓了頓）我請她吃了頓飯。"],
	],
	4: [
		["旁白", "第四年，有人來談開分店。"],
		["老闆娘", "（坐在空蕩的店裡，想起接手第一天的樣子）"],
		["阿嬤", "（電話裡）我聽說你做得不錯哦。"],
		["老闆娘", "還好而已，阿嬤。"],
		["阿嬤", "不要說還好，妳阿爸知道了很開心。"],
	],
	5: [
		["旁白", "第五年，台灣熱炒王的牌子掛上去了。"],
		["阿龍師傅", "這招牌太大了。"],
		["老闆娘", "師傅，謝謝你這五年。"],
		["阿龍師傅", "（沉默，把鍋鏟放到爐台上）我明天還是要來的。"],
		["老闆娘", "我知道。"],
		["旁白", "故事，還沒有結束。"],
	],
}

## 頭像色塊顏色對應（依說話者名稱）
const SPEAKER_COLORS: Dictionary = {
	"旁白":     Color(0.8, 0.4, 0.1),
	"阿龍師傅": Color(0.2, 0.4, 0.6),
	"老闆娘":   Color(0.7, 0.2, 0.3),
	"阿弟":     Color(0.2, 0.6, 0.5),
	"阿嬤":     Color(0.8, 0.5, 0.1),
}

## 預設頭像色塊顏色（未定義的說話者使用）
const DEFAULT_SPEAKER_COLOR: Color = Color(0.4, 0.4, 0.4)

## 打字機每字間隔（秒）
const TYPING_SPEED: float = 0.03


# ============================================================
# 內部節點引用
# ============================================================

var _canvas_layer: CanvasLayer = null
var _bg_rect: ColorRect = null
var _title_label: Label = null
var _avatar_rect: ColorRect = null
var _speaker_label: Label = null
var _dialog_label: Label = null
var _progress_label: Label = null
var _hint_label: Label = null


# ============================================================
# 內部狀態
# ============================================================

## 當前顯示的年份
var _current_year: int = 0

## 當前對話陣列
var _current_dialogs: Array = []

## 當前對話索引
var _dialog_index: int = 0

## 打字機計時累積
var _typing_timer: float = 0.0

## 當前完整台詞（打字機目標）
var _full_text: String = ""

## 目前已顯示的字元數
var _shown_chars: int = 0

## 是否正在打字機顯示中
var _is_typing: bool = false

## 是否正在顯示年份結局
var _is_showing: bool = false


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	call_deferred("_connect_signals")


func _connect_signals() -> void:
	if GameManager.year_ended.is_connected(_on_year_ended):
		return
	GameManager.year_ended.connect(_on_year_ended)
	print("[YearEndingManager] 已連接 GameManager.year_ended 信號")


# ============================================================
# 主循環：打字機效果
# ============================================================

func _process(delta: float) -> void:
	if not _is_typing:
		return

	_typing_timer += delta
	while _typing_timer >= TYPING_SPEED:
		_typing_timer -= TYPING_SPEED
		_shown_chars += 1
		if _shown_chars >= _full_text.length():
			_shown_chars = _full_text.length()
			_is_typing = false
			_update_hint_label(true)
			break

	if _dialog_label != null:
		_dialog_label.text = _full_text.substr(0, _shown_chars)


# ============================================================
# 信號回調
# ============================================================

func _on_year_ended(year: int) -> void:
	if _is_showing:
		push_warning("[YearEndingManager] 已有結局在播放，忽略 year_ended(%d)" % year)
		return

	if not YEAR_ENDINGS.has(year):
		print("[YearEndingManager] 第 %d 年無對應結局故事，跳過" % year)
		return

	_current_year = year
	_current_dialogs = YEAR_ENDINGS[year]
	_dialog_index = 0
	_is_showing = true

	# 暫停遊戲時間
	if GameManager.has_method("pause_time"):
		GameManager.pause_time()
	else:
		get_tree().paused = true

	_build_ui()
	_show_dialog(_dialog_index)


# ============================================================
# UI 建立
# ============================================================

func _build_ui() -> void:
	# 建立 CanvasLayer（layer=20，蓋在所有 UI 之上）
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 20
	get_tree().root.add_child(_canvas_layer)

	# 全螢幕半透明背景
	_bg_rect = ColorRect.new()
	_bg_rect.color = Color(0.03, 0.04, 0.08, 0.95)
	_bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_rect.size = Vector2(480, 270)
	_bg_rect.position = Vector2(0, 0)
	_canvas_layer.add_child(_bg_rect)

	# 接收點擊事件的透明按鈕（全螢幕）
	var click_area := Button.new()
	click_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	click_area.size = Vector2(480, 270)
	click_area.position = Vector2(0, 0)
	click_area.flat = true
	click_area.self_modulate = Color(0, 0, 0, 0)
	click_area.pressed.connect(_on_screen_clicked)
	_canvas_layer.add_child(click_area)

	# 頂部標題：「第 N 年，打烊了」
	_title_label = Label.new()
	_title_label.position = Vector2(0, 12)
	_title_label.size = Vector2(480, 20)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.text = "第 %d 年，打烊了" % _current_year
	_title_label.add_theme_color_override("font_color", Color(1, 0.843, 0))  # 金色
	_canvas_layer.add_child(_title_label)

	# 裝飾橫線（標題下方）
	var separator := ColorRect.new()
	separator.color = Color(1, 0.843, 0, 0.4)
	separator.size = Vector2(380, 1)
	separator.position = Vector2(50, 34)
	_canvas_layer.add_child(separator)

	# 說話者頭像色塊
	_avatar_rect = ColorRect.new()
	_avatar_rect.size = Vector2(32, 32)
	_avatar_rect.position = Vector2(24, 100)
	_avatar_rect.color = DEFAULT_SPEAKER_COLOR
	_canvas_layer.add_child(_avatar_rect)

	# 說話者名稱
	_speaker_label = Label.new()
	_speaker_label.position = Vector2(64, 98)
	_speaker_label.size = Vector2(200, 16)
	_speaker_label.text = ""
	_speaker_label.add_theme_color_override("font_color", Color(1, 0.843, 0))  # 金色
	_canvas_layer.add_child(_speaker_label)

	# 對話文字區域（對話框背景）
	var dialog_bg := ColorRect.new()
	dialog_bg.color = Color(0.08, 0.08, 0.14, 0.9)
	dialog_bg.size = Vector2(432, 90)
	dialog_bg.position = Vector2(24, 118)
	_canvas_layer.add_child(dialog_bg)

	# 對話框邊框（左側金色線）
	var border_left := ColorRect.new()
	border_left.color = Color(1, 0.843, 0, 0.6)
	border_left.size = Vector2(2, 90)
	border_left.position = Vector2(24, 118)
	_canvas_layer.add_child(border_left)

	# 對話文字
	_dialog_label = Label.new()
	_dialog_label.position = Vector2(34, 124)
	_dialog_label.size = Vector2(414, 78)
	_dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_label.text = ""
	_dialog_label.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))  # 接近白色
	_canvas_layer.add_child(_dialog_label)

	# 左下角進度顯示「N / Total」
	_progress_label = Label.new()
	_progress_label.position = Vector2(24, 228)
	_progress_label.size = Vector2(80, 12)
	_progress_label.text = "1 / %d" % _current_dialogs.size()
	_progress_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_canvas_layer.add_child(_progress_label)

	# 點擊提示（右下角）
	_hint_label = Label.new()
	_hint_label.position = Vector2(350, 228)
	_hint_label.size = Vector2(110, 12)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.text = ""
	_hint_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
	_canvas_layer.add_child(_hint_label)

	# 套用字體
	_apply_fonts()

	# 淡入效果
	_canvas_layer.modulate = Color(1, 1, 1, 0)
	var tween := get_tree().create_tween()
	tween.tween_property(_canvas_layer, "modulate", Color(1, 1, 1, 1), 0.5)


func _apply_fonts() -> void:
	var font_path: String = "res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf"
	var font: Font = null
	if ResourceLoader.exists(font_path):
		font = load(font_path)

	if font == null:
		push_warning("[YearEndingManager] 找不到 Fusion Pixel 字體，使用系統預設字體")
		return

	_title_label.add_theme_font_override("font", font)
	_title_label.add_theme_font_size_override("font_size", 14)

	_speaker_label.add_theme_font_override("font", font)
	_speaker_label.add_theme_font_size_override("font_size", 12)

	_dialog_label.add_theme_font_override("font", font)
	_dialog_label.add_theme_font_size_override("font_size", 12)

	_progress_label.add_theme_font_override("font", font)
	_progress_label.add_theme_font_size_override("font_size", 10)

	_hint_label.add_theme_font_override("font", font)
	_hint_label.add_theme_font_size_override("font_size", 10)


# ============================================================
# 對話流程
# ============================================================

func _show_dialog(index: int) -> void:
	if index >= _current_dialogs.size():
		_finish_story()
		return

	var entry: Array = _current_dialogs[index]
	var speaker: String = entry[0]
	var text: String = entry[1]

	# 更新說話者名稱與頭像色塊
	if _speaker_label != null:
		_speaker_label.text = speaker

	if _avatar_rect != null:
		_avatar_rect.color = SPEAKER_COLORS.get(speaker, DEFAULT_SPEAKER_COLOR)

	# 更新進度
	if _progress_label != null:
		_progress_label.text = "%d / %d" % [index + 1, _current_dialogs.size()]

	# 啟動打字機
	_full_text = text
	_shown_chars = 0
	_typing_timer = 0.0
	_is_typing = true
	_update_hint_label(false)

	if _dialog_label != null:
		_dialog_label.text = ""


func _update_hint_label(typing_done: bool) -> void:
	if _hint_label == null:
		return
	if typing_done:
		var is_last: bool = (_dialog_index >= _current_dialogs.size() - 1)
		_hint_label.text = "點擊結束" if is_last else "點擊繼續"
	else:
		_hint_label.text = "點擊跳過"


# ============================================================
# 點擊事件
# ============================================================

func _on_screen_clicked() -> void:
	if _is_typing:
		# 跳過打字機，直接顯示完整台詞
		_is_typing = false
		_shown_chars = _full_text.length()
		if _dialog_label != null:
			_dialog_label.text = _full_text
		_update_hint_label(true)
	else:
		# 前進到下一條對話
		_dialog_index += 1
		_show_dialog(_dialog_index)


# ============================================================
# 故事結束
# ============================================================

func _finish_story() -> void:
	_is_showing = false
	_is_typing = false

	# 淡出 CanvasLayer，再清除並恢復遊戲
	var tween := get_tree().create_tween()
	tween.tween_property(_canvas_layer, "modulate", Color(1, 1, 1, 0), 0.6)
	tween.tween_callback(_cleanup_ui)

	print("[YearEndingManager] 第 %d 年結局故事播放完畢" % _current_year)
	year_ending_finished.emit(_current_year)


func _cleanup_ui() -> void:
	if _canvas_layer != null:
		_canvas_layer.queue_free()
		_canvas_layer = null
		_bg_rect = null
		_title_label = null
		_avatar_rect = null
		_speaker_label = null
		_dialog_label = null
		_progress_label = null
		_hint_label = null

	# 恢復遊戲時間
	if GameManager.has_method("resume_time"):
		GameManager.resume_time()
	else:
		get_tree().paused = false

	print("[YearEndingManager] UI 清除完成，遊戲繼續")
