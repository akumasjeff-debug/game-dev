extends Node

# TutorialManager — Autoload as "TutorialManager"
# 新手教學系統，對應 docs/TUTORIAL_DESIGN.md v1.0
#
# 職責：
#   - 追蹤教學步驟 0–7
#   - 管理教學覆蓋 UI（CanvasLayer layer=20）
#   - 監聽 GameManager / decision_panel 信號，自動推進步驟
#   - 讀寫 SaveManager 教學完成狀態

# ─────────────────────────────────────────
#  狀態
# ─────────────────────────────────────────

var is_tutorial_active: bool = false
var tutorial_step: int = 0
var tutorial_completed: bool = false

# 教學 UI 根節點（CanvasLayer layer=20）
var _tutorial_layer: CanvasLayer = null

# 全螢幕遮罩
var _overlay: ColorRect = null

# 提示文字標籤
var _hint_label: Label = null

# 箭頭圖示（ColorRect 模擬）
var _arrow: Control = null

# 步驟 3 確認標籤（「選擇執行了！」）
var _feedback_label: Label = null

# 步驟 6 計時器（10 秒無操作才顯示淡色提示）
var _step6_timer: float = 0.0
var _step6_hint_shown: bool = false
var _step6_active: bool = false

# 步驟 7 中央卡片
var _end_card: Control = null
var _end_card_visible: bool = false

# 各自動消失計時器
var _auto_hide_timer: float = 0.0
var _auto_hide_active: bool = false

# 決策面板已開啟計數（區分第一個 vs 第二個決策點）
var _decision_count: int = 0

# 第一個房間交戰計時器（步驟 4 用）
var _combat_timer: float = 0.0
var _combat_timer_active: bool = false

# 步驟 4 已觸發
var _step4_triggered: bool = false

# 大招已觸發（步驟 5 用）
var _ult_used_in_step4: bool = false

const STEP6_NO_INPUT_TIMEOUT: float = 10.0

# ─────────────────────────────────────────
#  初始化
# ─────────────────────────────────────────

func _ready() -> void:
	# 從 SaveManager 讀取教學完成狀態
	tutorial_completed = SaveManager.tutorial_completed

	if tutorial_completed:
		return

	# 連接 GameManager 信號
	GameManager.decision_triggered.connect(_on_decision_triggered)
	GameManager.game_won.connect(_on_mission_complete)
	GameManager.game_lost.connect(_on_mission_complete)

# ─────────────────────────────────────────
#  公開 API
# ─────────────────────────────────────────

func start_tutorial() -> void:
	# 由 base.gd 或隊伍選擇畫面在首次進入時呼叫
	if tutorial_completed:
		return
	is_tutorial_active = true
	tutorial_step = 0
	_build_tutorial_layer()
	_show_step(0)

func mission_started() -> void:
	# 由 main.gd 在任務開始後呼叫（進入戰場場景後）
	if not is_tutorial_active:
		return
	if tutorial_step == 0:
		# 步驟 0 若還在（組隊畫面未完成），跳過直接到 1
		advance_step()

func notify_squad_moving() -> void:
	# 由 squad_controller 或 main.gd 在小隊開始移動時呼叫
	if not is_tutorial_active:
		return
	if tutorial_step == 1:
		_show_step(1)

func notify_decision_opened() -> void:
	# 由 decision_panel._ready / _on_decision_triggered 呼叫
	if not is_tutorial_active:
		return
	_decision_count += 1
	if tutorial_step == 2 and _decision_count == 1:
		_show_step(2)
	elif tutorial_step == 6 and _decision_count >= 2:
		# 第二個決策點：步驟 6，移除所有提示，讓面板正常顯示
		_hide_all_overlays()
		_step6_active = true
		_step6_timer = 0.0
		_step6_hint_shown = false

func notify_decision_selected() -> void:
	# 由 decision_panel._on_option_pressed 呼叫
	if not is_tutorial_active:
		return
	if tutorial_step == 2:
		advance_step()  # → 步驟 3
	elif tutorial_step == 6 and _step6_active:
		_step6_active = false
		advance_step()  # → 步驟 7

func notify_ult_used(char_id: String) -> void:
	# 由 hud.gd 的 _on_ultimate_pressed 在使用大招後呼叫
	if not is_tutorial_active:
		return
	if tutorial_step == 4 and char_id == "assault":
		_ult_used_in_step4 = true
		advance_step()  # → 步驟 5

func notify_ult_ready(char_id: String) -> void:
	# 由 hud.gd 的 _on_ultimate_ready 呼叫
	# 教學步驟 4：第一個房間交戰中敵人出現後 3 秒才觸發
	# 這裡不直接推進——改為啟動戰鬥計時器
	if not is_tutorial_active:
		return
	if tutorial_step == 3 and char_id == "assault" and not _step4_triggered:
		# 步驟 3 完成後，突擊手大招就緒 → 啟動 3 秒計時器後顯示步驟 4
		_combat_timer_active = true
		_combat_timer = 0.0

func notify_combat_started() -> void:
	# 由 main.gd 決策選項選完、小隊進入房間戰鬥時呼叫
	if not is_tutorial_active:
		return
	if tutorial_step == 3:
		# 步驟 3 結束後進入戰鬥，啟動計時器等待 3 秒再顯示步驟 4
		_combat_timer_active = true
		_combat_timer = 0.0

func advance_step() -> void:
	if not is_tutorial_active:
		return
	tutorial_step += 1
	_show_step(tutorial_step)

func skip_tutorial() -> void:
	is_tutorial_active = false
	tutorial_step = 7
	tutorial_completed = true
	SaveManager.tutorial_completed = true
	SaveManager.save_game()
	_destroy_tutorial_layer()

# ─────────────────────────────────────────
#  步驟顯示邏輯
# ─────────────────────────────────────────

func _show_step(step: int) -> void:
	_hide_all_overlays()

	match step:
		0:
			# 組隊畫面：遮罩 + 提示文字「選 4 人出發」
			# 組隊畫面由 base.gd 管理，此處只設旗標
			# 遮罩在組隊畫面場景內由 base.gd 負責
			pass

		1:
			# 任務開始：「小隊自動前進，你不用操控移動」4 秒後消失
			_show_hint_text("小隊自動前進，你不用操控移動",
				Vector2(540, 1600), 36, Color.WHITE)
			_show_sweep_animation()
			_start_auto_hide(4.0)

		2:
			# 決策點1：遮住面板以外所有區域 + 提示 + 箭頭
			_show_overlay(Color(0, 0, 0, 0.6))
			_show_hint_text("輪到你了，選一個進入方式",
				Vector2(540, 350), 36, Color.WHITE)
			_show_arrow(Vector2(540, 450), Vector2(0, 80))

		3:
			# 選擇執行後：「選擇執行了！小隊繼續前進」2 秒後淡出
			_show_feedback_text("選擇執行了！小隊繼續前進",
				Vector2(540, 960), 32)
			_start_auto_hide(2.0)

		4:
			# 大招教學：70% 遮罩 + 高亮突擊手卡片提示
			_step4_triggered = true
			_show_overlay(Color(0, 0, 0, 0.7))
			_show_hint_text("點擊角色卡片，立刻發動大招！",
				Vector2(540, 1550), 36, Color.WHITE)
			_show_arrow(Vector2(540, 1620), Vector2(0, 80))

		5:
			# CD 說明：3 秒後消失
			_show_hint_text("冷卻中，稍後可再次使用",
				Vector2(540, 1550), 32, Color(0.91, 0.376, 0.039))
			_start_auto_hide(3.0)

		6:
			# 第二個決策點：無提示，等待玩家自己操作
			# 計時器在 notify_decision_opened 中啟動
			_hide_all_overlays()

		7:
			# 教學結束：中央卡片 3 秒後消失（或點擊跳過）
			_show_end_card("你已掌握核心指揮技巧，繼續完成任務！")
			_start_auto_hide(3.0)
			_end_card_visible = true

		_:
			# 步驟超出範圍，標記教學完成
			_complete_tutorial()

# ─────────────────────────────────────────
#  建立教學 UI 層
# ─────────────────────────────────────────

func _build_tutorial_layer() -> void:
	if _tutorial_layer != null:
		return

	_tutorial_layer = CanvasLayer.new()
	_tutorial_layer.name = "TutorialLayer"
	_tutorial_layer.layer = 20
	get_tree().root.add_child(_tutorial_layer)

	# 全螢幕遮罩（預設隱藏）
	_overlay = ColorRect.new()
	_overlay.name = "TutorialOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_layer.add_child(_overlay)

	# 提示文字
	_hint_label = Label.new()
	_hint_label.name = "HintLabel"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.visible = false
	_hint_label.z_index = 10
	_tutorial_layer.add_child(_hint_label)

	# 回饋文字（步驟 3 使用）
	_feedback_label = Label.new()
	_feedback_label.name = "FeedbackLabel"
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.visible = false
	_feedback_label.z_index = 10
	_tutorial_layer.add_child(_feedback_label)

	# 箭頭（用 Label 模擬 ▼）
	_arrow = Label.new()
	_arrow.name = "Arrow"
	_arrow.text = "▼"
	_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_arrow.add_theme_font_size_override("font_size", 40)
	_arrow.modulate = Color(0.91, 0.376, 0.039)
	_arrow.visible = false
	_arrow.z_index = 10
	_tutorial_layer.add_child(_arrow)

func _destroy_tutorial_layer() -> void:
	if _tutorial_layer != null:
		_tutorial_layer.queue_free()
		_tutorial_layer = null
		_overlay = null
		_hint_label = null
		_feedback_label = null
		_arrow = null
		_end_card = null

# ─────────────────────────────────────────
#  UI 輔助方法
# ─────────────────────────────────────────

func _show_overlay(color: Color) -> void:
	if _overlay == null:
		return
	_overlay.color = color
	_overlay.visible = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

func _show_hint_text(text: String, center_pos: Vector2, font_size: int, color: Color) -> void:
	if _hint_label == null:
		return
	_hint_label.text = text
	_hint_label.add_theme_font_size_override("font_size", font_size)
	_hint_label.modulate = color

	# 橙色底框（Panel 背景模擬）
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.91, 0.376, 0.039, 0.85)
	bg_style.set_corner_radius_all(8)
	bg_style.content_margin_left = 20
	bg_style.content_margin_right = 20
	bg_style.content_margin_top = 10
	bg_style.content_margin_bottom = 10
	_hint_label.add_theme_stylebox_override("normal", bg_style)

	_hint_label.size = Vector2(800, 60)
	_hint_label.position = center_pos - Vector2(400, 30)
	_hint_label.visible = true

func _show_feedback_text(text: String, center_pos: Vector2, font_size: int) -> void:
	if _feedback_label == null:
		return
	_feedback_label.text = text
	_feedback_label.add_theme_font_size_override("font_size", font_size)
	_feedback_label.modulate = Color.WHITE
	_feedback_label.size = Vector2(800, 60)
	_feedback_label.position = center_pos - Vector2(400, 30)
	_feedback_label.visible = true

func _show_arrow(tip_pos: Vector2, _offset: Vector2) -> void:
	if _arrow == null:
		return
	_arrow.size = Vector2(60, 60)
	_arrow.position = tip_pos - Vector2(30, 0)
	_arrow.visible = true

func _show_sweep_animation() -> void:
	# 橙色橫線從左掃到右（Tween 動畫，約 1 秒）
	if _tutorial_layer == null:
		return
	var sweep = ColorRect.new()
	sweep.name = "SweepLine"
	sweep.size = Vector2(200, 8)
	sweep.color = Color(0.91, 0.376, 0.039, 0.9)
	sweep.position = Vector2(-200, 1650)
	_tutorial_layer.add_child(sweep)

	var tween = sweep.create_tween()
	tween.tween_property(sweep, "position", Vector2(1080, 1650), 1.0)
	tween.tween_callback(sweep.queue_free)

func _show_end_card(text: String) -> void:
	if _tutorial_layer == null:
		return

	# 半透明背景卡片
	_end_card = Panel.new()
	_end_card.name = "EndCard"
	_end_card.custom_minimum_size = Vector2(700, 160)
	_end_card.size = Vector2(700, 160)
	_end_card.position = Vector2(190, 880)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.75)
	style.set_corner_radius_all(12)
	_end_card.add_theme_stylebox_override("panel", style)
	_tutorial_layer.add_child(_end_card)

	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.modulate = Color.WHITE
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.offset_left = 20
	lbl.offset_right = -20
	_end_card.add_child(lbl)

	# 點任意位置跳過
	_end_card.gui_input.connect(_on_end_card_input)

func _on_end_card_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		_complete_tutorial()

func _show_step6_faint_hint() -> void:
	# 步驟 6：10 秒無操作，淡色提示（無遮罩）
	if _tutorial_layer == null or _step6_hint_shown:
		return
	_step6_hint_shown = true

	var lbl = Label.new()
	lbl.name = "Step6FaintHint"
	lbl.text = "選一條路繼續前進"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.modulate = Color(1, 1, 1, 0.4)
	lbl.size = Vector2(600, 50)
	lbl.position = Vector2(240, 300)
	_tutorial_layer.add_child(lbl)

	# 5 秒後自動消失
	var t = get_tree().create_timer(5.0)
	t.timeout.connect(lbl.queue_free)

func _hide_all_overlays() -> void:
	_auto_hide_active = false
	_auto_hide_timer = 0.0

	if _overlay != null:
		_overlay.visible = false
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if _hint_label != null:
		_hint_label.visible = false

	if _feedback_label != null:
		_feedback_label.visible = false

	if _arrow != null:
		_arrow.visible = false

	if _end_card != null and is_instance_valid(_end_card):
		_end_card.queue_free()
		_end_card = null
		_end_card_visible = false

	# 清除步驟 6 淡色提示
	if _tutorial_layer != null:
		var faint = _tutorial_layer.find_child("Step6FaintHint", false, false)
		if faint != null:
			faint.queue_free()

func _start_auto_hide(duration: float) -> void:
	_auto_hide_active = true
	_auto_hide_timer = duration

# ─────────────────────────────────────────
#  信號回調
# ─────────────────────────────────────────

func _on_decision_triggered(_decision_data: Dictionary) -> void:
	notify_decision_opened()

func _on_mission_complete() -> void:
	if is_tutorial_active and tutorial_step >= 6:
		_complete_tutorial()

# ─────────────────────────────────────────
#  教學完成
# ─────────────────────────────────────────

func _complete_tutorial() -> void:
	if tutorial_completed:
		return
	is_tutorial_active = false
	tutorial_completed = true
	tutorial_step = 8
	SaveManager.tutorial_completed = true
	SaveManager.save_game()
	_destroy_tutorial_layer()

# ─────────────────────────────────────────
#  _process：自動消失計時器 + 步驟 6 計時器 + 步驟 4 計時器
# ─────────────────────────────────────────

func _process(delta: float) -> void:
	if not is_tutorial_active:
		return

	# 自動消失計時器
	if _auto_hide_active:
		_auto_hide_timer -= delta
		if _auto_hide_timer <= 0.0:
			_auto_hide_active = false
			match tutorial_step:
				1:
					advance_step()  # 1 → 2（等待決策點觸發）
				3:
					advance_step()  # 3 → 4（等待突擊手大招就緒）
					# 步驟 3 結束後啟動戰鬥計時器（等 3 秒顯示步驟 4）
					_combat_timer_active = true
					_combat_timer = 0.0
				5:
					advance_step()  # 5 → 6
				7:
					if _end_card_visible:
						_complete_tutorial()
				_:
					_hide_all_overlays()

	# 步驟 4 戰鬥計時器（敵人出現後 3 秒）
	if _combat_timer_active and tutorial_step == 4:
		_combat_timer += delta
		if _combat_timer >= 3.0:
			_combat_timer_active = false
			if not _step4_triggered:
				_show_step(4)

	# 步驟 6：10 秒無操作計時
	if _step6_active and tutorial_step == 6:
		_step6_timer += delta
		if _step6_timer >= STEP6_NO_INPUT_TIMEOUT and not _step6_hint_shown:
			_show_step6_faint_hint()
