## dialog_ui.gd
## 教學對話框 UI — 掛在 UI.tscn 的 dialog_layer（CanvasLayer layer=2）節點
## 監聽 TutorialManager 信號，以程式碼建立對話框節點，不依賴 .tscn 子節點

extends CanvasLayer

# ── 常數 ─────────────────────────────────────────────────────────────
const DIALOG_W: float  = 460.0
const DIALOG_H: float  = 56.0
const DIALOG_X: float  = 10.0
const DIALOG_Y: float  = 200.0
const SCREEN_W: float  = 480.0
const SCREEN_H: float  = 270.0

const COLOR_BG      := Color(0.102, 0.102, 0.180, 0.9)  # #1A1A2E alpha=0.9
const COLOR_GOLD    := Color(1.0, 0.843, 0.0, 1.0)       # #FFD700
const COLOR_WHITE   := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_BLOCKER := Color(0.0, 0.0, 0.0, 0.35)

# ── 節點引用 ─────────────────────────────────────────────────────────
var _dialog_bg:      ColorRect  = null
var _speaker_lbl:    Label      = null
var _text_lbl:       Label      = null
var _arrow_lbl:      Label      = null
var _input_blocker:  ColorRect  = null   # lock_input 時蓋住全螢幕

# ── 閃爍計時 ─────────────────────────────────────────────────────────
var _blink_timer: float = 0.0
const BLINK_INTERVAL: float = 0.5

# ── 字體 ─────────────────────────────────────────────────────────────
var _font: Font = null


# ============================================================
# 生命週期
# ============================================================

func _ready() -> void:
	# 嘗試載入像素字體
	var font_path := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf"
	if ResourceLoader.exists(font_path):
		_font = load(font_path)
	else:
		push_warning("[dialog_ui.gd] 找不到 Fusion Pixel 字體，使用預設字體")

	_build_dialog()
	_connect_tutorial_signals()

	# 預設隱藏（等待 TutorialManager 觸發）
	visible = false


func _process(delta: float) -> void:
	if not visible or _arrow_lbl == null:
		return
	_blink_timer += delta
	if _blink_timer >= BLINK_INTERVAL:
		_blink_timer = 0.0
		_arrow_lbl.visible = not _arrow_lbl.visible


# ============================================================
# 建立節點樹
# ============================================================

func _build_dialog() -> void:
	# 全螢幕輸入攔截層（lock_input 用），預設隱藏
	_input_blocker = ColorRect.new()
	_input_blocker.color = COLOR_BLOCKER
	_input_blocker.size = Vector2(SCREEN_W, SCREEN_H)
	_input_blocker.position = Vector2.ZERO
	_input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_input_blocker.visible = false
	add_child(_input_blocker)

	# 對話框背景
	_dialog_bg = ColorRect.new()
	_dialog_bg.color = COLOR_BG
	_dialog_bg.size = Vector2(DIALOG_W, DIALOG_H)
	_dialog_bg.position = Vector2(DIALOG_X, DIALOG_Y)
	_dialog_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dialog_bg)
	# 連接 gui_input：對話框背景接收到點擊即推進教學
	_dialog_bg.gui_input.connect(_on_dialog_bg_gui_input)

	# 說話者 Label（框內左上，距左 8px，距上 6px）
	_speaker_lbl = Label.new()
	_speaker_lbl.position = Vector2(DIALOG_X + 8, DIALOG_Y + 6)
	_speaker_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	_apply_font(_speaker_lbl, 10)
	add_child(_speaker_lbl)

	# 對話文字 Label（說話者下方，距左 8px）
	_text_lbl = Label.new()
	_text_lbl.position = Vector2(DIALOG_X + 8, DIALOG_Y + 20)
	_text_lbl.size = Vector2(DIALOG_W - 24, DIALOG_H - 24)
	_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_lbl.add_theme_color_override("font_color", COLOR_WHITE)
	_apply_font(_text_lbl, 9)
	add_child(_text_lbl)

	# 繼續提示箭頭（右下角），初始可見，後續由 _process 閃爍
	_arrow_lbl = Label.new()
	_arrow_lbl.text = ">>"
	_arrow_lbl.position = Vector2(DIALOG_X + DIALOG_W - 14, DIALOG_Y + DIALOG_H - 14)
	_arrow_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	_apply_font(_arrow_lbl, 9)
	add_child(_arrow_lbl)

	# 跳過按鈕（對話框右下角附近）
	var skip_btn := Button.new()
	skip_btn.text = "跳過"
	skip_btn.size = Vector2(36, 14)
	skip_btn.position = Vector2(DIALOG_X + DIALOG_W - 40, DIALOG_Y - 16)
	skip_btn.flat = false
	skip_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_apply_font(skip_btn, 8)
	skip_btn.pressed.connect(_on_skip_btn_pressed)
	add_child(skip_btn)


# ============================================================
# 信號連接
# ============================================================

func _connect_tutorial_signals() -> void:
	var tm := get_node_or_null("/root/TutorialManager")
	if tm == null:
		push_warning("[dialog_ui.gd] 找不到 TutorialManager，對話框不會顯示")
		return

	if not tm.step_changed.is_connected(_on_step_changed):
		tm.step_changed.connect(_on_step_changed)

	if not tm.tutorial_day1_complete.is_connected(_on_tutorial_complete):
		tm.tutorial_day1_complete.connect(_on_tutorial_complete)

	print("[dialog_ui.gd] TutorialManager 信號連接完成")


# ============================================================
# 信號回調
# ============================================================

func _on_step_changed(step_number: int, step_data: Dictionary) -> void:
	visible = true
	_blink_timer = 0.0
	if _arrow_lbl:
		_arrow_lbl.visible = true

	var speaker: String = step_data.get("dialog_speaker", "")
	var text: String    = step_data.get("dialog_text", "")
	var lock_input: bool = step_data.get("lock_input", false)

	if _speaker_lbl:
		_speaker_lbl.text = speaker
	if _text_lbl:
		_text_lbl.text = text

	# lock_input 時顯示全螢幕攔截層（玩家無法點擊背景遊戲，但對話框本身仍可點擊）
	if _input_blocker:
		_input_blocker.visible = lock_input

	print("[dialog_ui.gd] 步驟 %d：%s — %s（lock=%s）" % [step_number, speaker, text, lock_input])


func _on_tutorial_complete() -> void:
	visible = false
	if _input_blocker:
		_input_blocker.visible = false
	# 清除對話框背景節點，避免殘留 UI 繼續佔用輸入事件
	if _dialog_bg != null:
		_dialog_bg.queue_free()
		_dialog_bg = null
	print("[dialog_ui.gd] 教學完成，對話框已移除")


# ============================================================
# 點擊推進教學
# ============================================================

## gui_input 回調：對話框背景本身接收到的點擊（MOUSE_FILTER_STOP 確保事件不往下穿透）
func _on_dialog_bg_gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_advance_tutorial()
	elif event is InputEventScreenTouch and event.pressed:
		_advance_tutorial()


## _unhandled_input 備用：捕捉對話框外但未被其他 Control 吞掉的點擊
## 例如 lock_input=false 且玩家點到對話框外的遊戲區域時仍可推進
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_advance_tutorial()
	elif event is InputEventScreenTouch and event.pressed:
		_advance_tutorial()


func _advance_tutorial() -> void:
	var tm := get_node_or_null("/root/TutorialManager")
	if tm == null:
		return
	if not tm.has_method("get_current_step"):
		return
	var step_data: Dictionary = tm.get_current_step()
	if step_data.is_empty():
		return
	var condition: String = step_data.get("complete_condition", "on_screen_tapped")
	# 點擊對話框即可推進所有步驟（自動條件由遊戲系統觸發，但也允許玩家手動點擊跳過）
	if tm.has_method("complete_current_step"):
		tm.complete_current_step(condition)
		print("[dialog_ui.gd] 推進步驟，condition=%s" % condition)


# ============================================================
# 跳過教學
# ============================================================

func _on_skip_btn_pressed() -> void:
	var tm := get_node_or_null("/root/TutorialManager")
	if tm != null:
		# 直接呼叫教學完成流程（GDScript 下底線前綴為慣例，仍可外部呼叫）
		if tm.has_method("_on_day1_complete"):
			tm._on_day1_complete()
		else:
			# 備用：隱藏對話框本身
			visible = false
			if _input_blocker:
				_input_blocker.visible = false
	else:
		# 找不到 TutorialManager，直接隱藏
		visible = false
		if _input_blocker:
			_input_blocker.visible = false
	print("[dialog_ui.gd] 玩家點擊跳過教學")


# ============================================================
# 工具
# ============================================================

func _apply_font(node: Control, size: int) -> void:
	if _font != null:
		node.add_theme_font_override("font", _font)
	node.add_theme_font_size_override("font_size", size)
