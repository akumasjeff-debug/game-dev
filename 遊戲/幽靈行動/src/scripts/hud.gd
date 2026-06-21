extends CanvasLayer

# HUD 更新邏輯
# - 頂部進度條
# - 底部 4 張角色卡（6 選 4 陣容）依 HUD_SPEC.md v1.0 規格
# - 偵察手預警 Toast
# - 勝負畫面

@onready var progress_bar: ProgressBar = $TopBar/ProgressBar
@onready var progress_label: Label = $TopBar/ProgressLabel
@onready var cards_container: HBoxContainer = $BottomBar/CardsContainer
@onready var game_result_panel: Panel = $GameResultPanel
@onready var result_label: Label = $GameResultPanel/VBox/ResultLabel
@onready var result_desc: Label = $GameResultPanel/VBox/DescLabel
@onready var retry_btn: Button = $GameResultPanel/VBox/RetryBtn
@onready var restart_btn: Button = $GameResultPanel/VBox/RestartBtn

# 顏色常數（對應 HUD_SPEC 職業顏色）
const COLOR_NORMAL_BG     := Color(0.102, 0.169, 0.102, 1.0)   # #1A2B1A
const COLOR_NORMAL_BORDER := Color(0.227, 0.290, 0.227, 1.0)   # #3A4A3A
const COLOR_READY_BORDER  := Color(0.910, 0.376, 0.039, 1.0)   # #E8600A
const COLOR_DEAD_OVERLAY  := Color(0.800, 0.133, 0.133, 0.30)  # #CC2222 30%
const COLOR_CD_OVERLAY    := Color(0.0,   0.0,   0.0,   0.55)  # #000000 55%
const COLOR_HP_HIGH       := Color(0.267, 0.800, 0.267, 1.0)   # #44CC44
const COLOR_HP_MID        := Color(0.910, 0.627, 0.039, 1.0)   # #E8A00A
const COLOR_HP_LOW        := Color(0.800, 0.133, 0.133, 1.0)   # #CC2222
const COLOR_HP_BG         := Color(0.227, 0.227, 0.227, 1.0)   # #3A3A3A
const COLOR_CARD_BOTTOM   := Color(0.133, 0.200, 0.133, 1.0)   # #223322
const COLOR_CD_LABEL      := Color(0.533, 0.533, 0.533, 1.0)   # #888888
const COLOR_TEXT_MAIN     := Color(0.941, 0.941, 0.941, 1.0)   # #F0F0F0
const COLOR_READY_TEXT    := Color(0.267, 0.800, 0.267, 1.0)   # #44CC44
const COLOR_DEAD_TEXT     := Color(0.800, 0.133, 0.133, 1.0)   # #CC2222
const COLOR_ORANGE        := Color(0.910, 0.376, 0.039, 1.0)   # #E8600A

# 卡片尺寸（HUD_SPEC: 236×178px，觸控區 240×190px）
const CARD_W: float = 236.0
const CARD_H: float = 178.0
const CIRCLE_SIZE: float = 44.0  # 職業圓圈直徑 44px

# 角色卡片
var card_nodes: Array = []
var squad_ref: Array = []

# 偵察手預警 Toast
var _recon_toast: Label = null
var _recon_toast_timer: float = 0.0
const TOAST_DURATION: float = 5.0

# 脈衝動畫計時器
var _pulse_timer: float = 0.0

func _ready() -> void:
	game_result_panel.hide()
	GameManager.game_won.connect(_on_game_won)
	GameManager.game_lost.connect(_on_game_lost)
	_build_recon_toast()
	# 連接重試按鈕
	if retry_btn:
		retry_btn.pressed.connect(_on_retry_pressed)

func _build_recon_toast() -> void:
	# 偵察手預警 Toast：固定顯示在頂部進度條下方
	_recon_toast = Label.new()
	_recon_toast.name = "ReconToast"
	_recon_toast.add_theme_font_size_override("font_size", 16)
	_recon_toast.modulate = COLOR_ORANGE
	_recon_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_recon_toast.anchor_left   = 0.0
	_recon_toast.anchor_top    = 0.0
	_recon_toast.anchor_right  = 1.0
	_recon_toast.anchor_bottom = 0.0
	_recon_toast.offset_top    = 90.0
	_recon_toast.offset_bottom = 120.0
	_recon_toast.visible = false
	add_child(_recon_toast)

func show_recon_warning(next_type: String) -> void:
	# 由 decision_trigger 呼叫，顯示偵察手預警文字 5 秒
	if _recon_toast == null:
		return
	_recon_toast.text = "偵察手預警：前方有" + next_type
	_recon_toast.visible = true
	_recon_toast_timer = TOAST_DURATION

func setup_cards(squad: Array) -> void:
	squad_ref = squad
	for child in cards_container.get_children():
		child.queue_free()
	card_nodes.clear()

	# 最多顯示 4 張卡（6 選 4 陣容）
	var display_count = mini(squad.size(), 4)
	for i in range(display_count):
		var card = _create_character_card(squad[i])
		cards_container.add_child(card)
		card_nodes.append(card)

func _create_character_card(member) -> Control:
	# 外層容器（觸控區保證 >= 120×120px）
	var card = Control.new()
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# --- 卡片背景 Panel ---
	var bg = Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_NORMAL_BG
	style.border_color = COLOR_NORMAL_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	bg.add_theme_stylebox_override("panel", style)
	bg.name = "BG"
	card.add_child(bg)

	# --- 死亡遮罩（紅色半透明）---
	var dead_overlay = ColorRect.new()
	dead_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dead_overlay.color = COLOR_DEAD_OVERLAY
	dead_overlay.visible = false
	dead_overlay.name = "DeadOverlay"
	card.add_child(dead_overlay)

	# --- CD 遮罩（黑色漸層）---
	var cd_overlay = ColorRect.new()
	cd_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cd_overlay.color = COLOR_CD_OVERLAY
	cd_overlay.visible = false
	cd_overlay.name = "CDOverlay"
	card.add_child(cd_overlay)

	# ===== 上區（高 56px）：職業圓圈 + 角色名 =====
	# 職業顏色圓圈（44px 正方形，代表職業色）
	var circle = ColorRect.new()
	circle.size = Vector2(CIRCLE_SIZE, CIRCLE_SIZE)
	circle.position = Vector2(10, 6)
	circle.color = member.body_color
	circle.name = "ClassCircle"
	card.add_child(circle)

	# 角色名（最多 4 字）
	var name_lbl = Label.new()
	var display_name = member.char_name
	if display_name.length() > 4:
		display_name = display_name.substr(0, 4) + "…"
	name_lbl.text = display_name
	name_lbl.position = Vector2(10 + CIRCLE_SIZE + 8, 16)
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.modulate = COLOR_TEXT_MAIN
	name_lbl.name = "NameLabel"
	card.add_child(name_lbl)

	# ===== 中區（y=58~78）：HP 血條 =====
	# 血條背景
	var hp_bg = ColorRect.new()
	hp_bg.size = Vector2(CARD_W - 20, 10)
	hp_bg.position = Vector2(10, 58)
	hp_bg.color = COLOR_HP_BG
	card.add_child(hp_bg)

	# 血條前景
	var hp_bar = ProgressBar.new()
	hp_bar.size = Vector2(CARD_W - 20, 10)
	hp_bar.position = Vector2(10, 58)
	hp_bar.min_value = 0.0
	hp_bar.max_value = member.max_hp
	hp_bar.value = member.current_hp
	hp_bar.show_percentage = false
	hp_bar.name = "HPBar"
	var hp_fill = StyleBoxFlat.new()
	hp_fill.bg_color = COLOR_HP_HIGH
	hp_fill.set_corner_radius_all(5)
	var hp_bg_style = StyleBoxFlat.new()
	hp_bg_style.bg_color = Color(0, 0, 0, 0)  # 透明，讓背景 ColorRect 顯示
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	hp_bar.add_theme_stylebox_override("background", hp_bg_style)
	card.add_child(hp_bar)

	# HP 百分比數字（血條右上方）
	var hp_lbl = Label.new()
	var hp_pct = int(member.current_hp * 100.0 / member.max_hp) if member.max_hp > 0 else 0
	hp_lbl.text = str(hp_pct) + "%"
	hp_lbl.position = Vector2(CARD_W - 46, 44)
	hp_lbl.add_theme_font_size_override("font_size", 11)
	hp_lbl.modulate = COLOR_TEXT_MAIN
	hp_lbl.name = "HPLabel"
	card.add_child(hp_lbl)

	# ===== 下區（y=88~178）：大招狀態區 =====
	var ult_bg = ColorRect.new()
	ult_bg.size = Vector2(CARD_W, CARD_H - 88)
	ult_bg.position = Vector2(0, 88)
	ult_bg.color = COLOR_CARD_BOTTOM
	ult_bg.name = "UltBG"
	card.add_child(ult_bg)

	# CD 標籤（小字，預設隱藏）
	var cd_tag = Label.new()
	cd_tag.text = "CD"
	cd_tag.position = Vector2(CARD_W * 0.5 - 8, 92)
	cd_tag.add_theme_font_size_override("font_size", 10)
	cd_tag.modulate = COLOR_CD_LABEL
	cd_tag.name = "CDTag"
	cd_tag.visible = false
	card.add_child(cd_tag)

	# 大招狀態主標籤（就緒 / CD 倒數 / 倒下）
	var ult_lbl = Label.new()
	ult_lbl.text = "大招就緒"
	ult_lbl.position = Vector2(0, 108)
	ult_lbl.size = Vector2(CARD_W, 50)
	ult_lbl.add_theme_font_size_override("font_size", 13)
	ult_lbl.modulate = COLOR_READY_TEXT
	ult_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ult_lbl.name = "UltLabel"
	card.add_child(ult_lbl)

	# 隱形按鈕覆蓋下區，捕捉點擊（觸控區 >= 120px）
	var ult_btn = Button.new()
	ult_btn.position = Vector2(0, 88)
	ult_btn.custom_minimum_size = Vector2(CARD_W, CARD_H - 88)
	ult_btn.flat = true
	var btn_empty = StyleBoxEmpty.new()
	ult_btn.add_theme_stylebox_override("normal", btn_empty)
	ult_btn.add_theme_stylebox_override("hover", btn_empty)
	ult_btn.add_theme_stylebox_override("pressed", btn_empty)
	ult_btn.add_theme_stylebox_override("focus", btn_empty)
	ult_btn.name = "UltBtn"
	ult_btn.pressed.connect(_on_ultimate_pressed.bind(member, card))
	card.add_child(ult_btn)

	# 連接信號
	member.hp_changed.connect(_on_hp_changed.bind(hp_bar, hp_lbl, card))
	member.ultimate_ready.connect(_on_ultimate_ready.bind(card))
	member.ultimate_used.connect(_on_ultimate_used.bind(card))
	member.character_died.connect(_on_character_died.bind(card))

	return card

# ---- 卡片狀態切換 ----

func _set_card_ready_state(card: Control) -> void:
	var cd_overlay = card.find_child("CDOverlay", false, false)
	if cd_overlay:
		cd_overlay.visible = false
	var ult_lbl = card.find_child("UltLabel", false, false) as Label
	if ult_lbl:
		ult_lbl.text = "大招就緒"
		ult_lbl.add_theme_font_size_override("font_size", 13)
		ult_lbl.modulate = COLOR_READY_TEXT
	var cd_tag = card.find_child("CDTag", false, false)
	if cd_tag:
		cd_tag.visible = false
	var btn = card.find_child("UltBtn", false, false) as Button
	if btn:
		btn.disabled = false

func _set_card_cd_state(card: Control, remaining: float) -> void:
	var cd_overlay = card.find_child("CDOverlay", false, false)
	if cd_overlay:
		cd_overlay.visible = true
	var secs = int(remaining) + 1 if remaining > 0.0 else 0
	var ult_lbl = card.find_child("UltLabel", false, false) as Label
	if ult_lbl:
		ult_lbl.text = str(secs)
		if secs <= 5:
			ult_lbl.add_theme_font_size_override("font_size", 40)
			ult_lbl.modulate = COLOR_ORANGE
		else:
			ult_lbl.add_theme_font_size_override("font_size", 36)
			ult_lbl.modulate = COLOR_TEXT_MAIN
	var cd_tag = card.find_child("CDTag", false, false)
	if cd_tag:
		cd_tag.visible = true
	var btn = card.find_child("UltBtn", false, false) as Button
	if btn:
		btn.disabled = true

func _set_card_dead_state(card: Control) -> void:
	var dead_overlay = card.find_child("DeadOverlay", false, false)
	if dead_overlay:
		dead_overlay.visible = true
	var circle = card.find_child("ClassCircle", false, false) as ColorRect
	if circle:
		circle.color = Color(0.8, 0.1, 0.1)
	var name_lbl = card.find_child("NameLabel", false, false) as Label
	if name_lbl:
		name_lbl.modulate = COLOR_DEAD_TEXT
	var ult_lbl = card.find_child("UltLabel", false, false) as Label
	if ult_lbl:
		ult_lbl.text = "X"
		ult_lbl.add_theme_font_size_override("font_size", 36)
		ult_lbl.modulate = COLOR_DEAD_TEXT
	var cd_tag = card.find_child("CDTag", false, false)
	if cd_tag:
		cd_tag.visible = false
	var btn = card.find_child("UltBtn", false, false) as Button
	if btn:
		btn.disabled = true

# ---- 信號回調 ----

func _on_ultimate_pressed(member, card: Control) -> void:
	if GameManager.is_paused or GameManager.is_game_over:
		return
	if member.use_ultimate():
		AudioManager.play_ult(member.char_id)
		_set_card_cd_state(card, member.get_cd_remaining())

func _on_hp_changed(current: float, max_val: float, hp_bar: ProgressBar, hp_lbl: Label, card: Control) -> void:
	if hp_bar and is_instance_valid(hp_bar):
		hp_bar.value = current
		# 動態血條顏色（依 HUD_SPEC 閾值）
		var ratio = current / max_val if max_val > 0.0 else 0.0
		var fill_style = StyleBoxFlat.new()
		fill_style.set_corner_radius_all(5)
		if ratio > 0.5:
			fill_style.bg_color = COLOR_HP_HIGH
		elif ratio > 0.25:
			fill_style.bg_color = COLOR_HP_MID
		else:
			fill_style.bg_color = COLOR_HP_LOW
		hp_bar.add_theme_stylebox_override("fill", fill_style)
	if hp_lbl and is_instance_valid(hp_lbl):
		var pct = int(current * 100.0 / max_val) if max_val > 0.0 else 0
		hp_lbl.text = str(pct) + "%"

func _on_ultimate_ready(card: Control) -> void:
	if card and is_instance_valid(card):
		_set_card_ready_state(card)
		AudioManager.play_sfx("ult_ready")

func _on_ultimate_used(card: Control) -> void:
	if card and is_instance_valid(card):
		_set_card_cd_state(card, 0.0)

func _on_character_died(card: Control) -> void:
	if card and is_instance_valid(card):
		_set_card_dead_state(card)

func update_progress(ratio: float) -> void:
	if progress_bar:
		progress_bar.value = ratio * 100.0
	if progress_label:
		progress_label.text = "進度 " + str(int(ratio * 100)) + "%"

func _process(delta: float) -> void:
	_pulse_timer += delta

	# 每幀更新 CD 倒數 + 大招就緒脈衝
	for i in range(squad_ref.size()):
		if i >= card_nodes.size():
			break
		var member = squad_ref[i]
		if member == null or not is_instance_valid(member):
			continue
		var card = card_nodes[i]
		if card == null or not is_instance_valid(card):
			continue
		if member.is_dead:
			continue

		if not member.is_ultimate_ready:
			_set_card_cd_state(card, member.get_cd_remaining())
		else:
			# 大招就緒：邊框脈衝（1.2 秒週期）
			var pulse = (sin(_pulse_timer * TAU / 1.2) + 1.0) * 0.5
			var bg = card.find_child("BG", false, false) as Panel
			if bg:
				var style = StyleBoxFlat.new()
				style.bg_color = COLOR_NORMAL_BG
				var alpha = lerp(0.5, 1.0, pulse)
				style.border_color = Color(
					COLOR_READY_BORDER.r,
					COLOR_READY_BORDER.g,
					COLOR_READY_BORDER.b,
					alpha
				)
				style.set_border_width_all(2)
				style.set_corner_radius_all(8)
				bg.add_theme_stylebox_override("panel", style)

	# 預警 Toast 倒計時
	if _recon_toast and _recon_toast.visible:
		_recon_toast_timer -= delta
		if _recon_toast_timer <= 0.0:
			_recon_toast.visible = false

func _on_game_won() -> void:
	game_result_panel.show()
	result_label.text = "任務完成！"
	result_label.modulate = Color(0.3, 1.0, 0.4)
	result_desc.text = "小隊成功完成任務，所有目標已達成。\n獲得 200 金幣！"
	AudioManager.play_sfx("victory")
	# 任務成功：給予獎勵並存檔
	SaveManager.add_coins(200)
	SaveManager.save_game()
	# 勝利時：只顯示「返回基地」
	if retry_btn:
		retry_btn.visible = false
	if restart_btn:
		restart_btn.text = "返回基地"
		restart_btn.visible = true

func _on_game_lost() -> void:
	game_result_panel.show()
	result_label.text = "全員倒下"
	result_label.modulate = Color(1.0, 0.3, 0.3)
	result_desc.text = "小隊全員陣亡，任務宣告失敗。\n基地繼續產出金幣，可立即重試。"
	AudioManager.play_sfx("defeat")
	# 存檔（記錄離開時間供離線計算）
	SaveManager.save_game()
	# 失敗時：顯示「重試」和「返回基地」
	if retry_btn:
		retry_btn.visible = true
	if restart_btn:
		restart_btn.text = "返回基地"
		restart_btn.visible = true

func _on_retry_pressed() -> void:
	# 重試：直接重載 Main 場景
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_restart_pressed() -> void:
	# 返回基地
	get_tree().change_scene_to_file("res://scenes/Base.tscn")
