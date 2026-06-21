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

# 顏色常數
const COLOR_NORMAL_BORDER := Color(0.25, 0.25, 0.30, 1.0)    # 普通邊框灰
const COLOR_READY_BORDER  := Color(0.13, 0.80, 0.27, 1.0)    # 就緒綠 #22CC44
const COLOR_DEAD_OVERLAY  := Color(0.60, 0.04, 0.04, 0.72)   # 死亡暗紅遮罩
const COLOR_CD_OVERLAY    := Color(0.0,  0.0,  0.0,  0.62)   # CD 黑色遮罩
const COLOR_HP_HIGH       := Color(0.13, 0.80, 0.13, 1.0)    # HP 高 #22CC22
const COLOR_HP_MID        := Color(0.91, 0.63, 0.04, 1.0)    # HP 中 #E8A00A
const COLOR_HP_LOW        := Color(0.80, 0.13, 0.13, 1.0)    # HP 低 #CC2222
const COLOR_HP_BG         := Color(0.10, 0.10, 0.12, 0.85)   # HP 背景
const COLOR_TEXT_MAIN     := Color(0.95, 0.95, 0.95, 1.0)    # 主文字白
const COLOR_DEAD_TEXT     := Color(1.00, 0.30, 0.30, 1.0)    # 死亡紅
const COLOR_ORANGE        := Color(0.91, 0.38, 0.04, 1.0)    # 橙色 #E8600A
const COLOR_NAMEPLATE_BG  := Color(0.0,  0.0,  0.0,  0.65)  # 名牌半透明黑

# 卡片尺寸（TCG 卡牌風格：portrait 填滿，外框變色）
const CARD_W: float = 236.0
const CARD_H: float = 178.0
# PORTRAIT_H：角色圖佔據上方 60% 高度，底部留給技能狀態區
const PORTRAIT_H: float = 110.0
const NAMEPLATE_H: float = 28.0
const HP_BAR_H: float = 10.0

# 角色卡片
var card_nodes: Array = []
var squad_ref: Array = []

# 偵察手預警 Toast
var _recon_toast: Label = null
var _recon_toast_timer: float = 0.0
const TOAST_DURATION: float = 5.0

# 脈衝動畫計時器
var _pulse_timer: float = 0.0

# 頂部任務狀態欄
var _mission_name_label: Label = null
var _room_progress_label: Label = null
var _total_rooms: int = 4

func _ready() -> void:
	game_result_panel.hide()
	GameManager.game_won.connect(_on_game_won)
	GameManager.game_lost.connect(_on_game_lost)
	_build_recon_toast()
	_add_top_bar()
	# 連接重試 / 返回按鈕
	if retry_btn:
		retry_btn.pressed.connect(_on_retry_pressed)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)

func _add_top_bar() -> void:
	# 任務名稱（左側，x=20-360，y=10，避開中央進度條與右側房間進度）
	_mission_name_label = Label.new()
	_mission_name_label.name = "MissionNameLabel"
	_mission_name_label.position = Vector2(20, 10)
	_mission_name_label.size = Vector2(340, 40)
	_mission_name_label.add_theme_font_size_override("font_size", 24)
	_mission_name_label.modulate = Color(1.0, 0.85, 0.3)
	_mission_name_label.text = GameManager.current_mission_data.get("name", "任務")
	add_child(_mission_name_label)

	# 房間進度（右側，x=730-1060，y=10，右對齊）
	_room_progress_label = Label.new()
	_room_progress_label.name = "RoomProgressLabel"
	_room_progress_label.size = Vector2(330, 40)
	_room_progress_label.position = Vector2(730, 10)
	_room_progress_label.add_theme_font_size_override("font_size", 24)
	_room_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_room_progress_label.modulate = Color(0.85, 0.95, 1.0)
	_room_progress_label.text = "房間 1 / " + str(_total_rooms)
	add_child(_room_progress_label)

	# 連接 room_advanced 信號
	if GameManager.has_signal("room_advanced"):
		GameManager.room_advanced.connect(_on_room_advanced)

func _on_room_advanced(room_index: int) -> void:
	# room_index 是 advance_room() 遞增後的值（從 0 開始），加 1 顯示給玩家看
	if _room_progress_label and is_instance_valid(_room_progress_label):
		var display_idx = mini(room_index + 1, _total_rooms)
		_room_progress_label.text = "房間 " + str(display_idx) + " / " + str(_total_rooms)

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
	_recon_toast.offset_top    = 110.0
	_recon_toast.offset_bottom = 140.0
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
	# ── 外層容器 ──────────────────────────────────────────────
	var card = Control.new()
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# ── 卡片底色（深黑，portrait 填滿後幾乎看不見）──────────
	var bg_fill = ColorRect.new()
	bg_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_fill.color = Color(0.06, 0.07, 0.10, 1.0)
	card.add_child(bg_fill)

	# ── ① HP 血條（卡面最上方，全寬 4px 細條）────────────────
	var hp_bg_rect = ColorRect.new()
	hp_bg_rect.size = Vector2(CARD_W, HP_BAR_H)
	hp_bg_rect.position = Vector2(0, 0)
	hp_bg_rect.color = COLOR_HP_BG
	hp_bg_rect.name = "HPBgRect"
	card.add_child(hp_bg_rect)

	var hp_bar = ProgressBar.new()
	hp_bar.size = Vector2(CARD_W, HP_BAR_H)
	hp_bar.position = Vector2(0, 0)
	hp_bar.min_value = 0.0
	hp_bar.max_value = member.max_hp
	hp_bar.value = member.current_hp
	hp_bar.show_percentage = false
	hp_bar.name = "HPBar"
	var hp_fill_style = StyleBoxFlat.new()
	hp_fill_style.bg_color = COLOR_HP_HIGH
	var hp_bg_style = StyleBoxFlat.new()
	hp_bg_style.bg_color = Color(0, 0, 0, 0)
	hp_bar.add_theme_stylebox_override("fill", hp_fill_style)
	hp_bar.add_theme_stylebox_override("background", hp_bg_style)
	card.add_child(hp_bar)

	# ── ② Portrait SVG 填滿卡面（HP條下方到底部技能區上方）──
	var portrait_top = HP_BAR_H
	var portrait_h = CARD_H - HP_BAR_H - clamp(CARD_H - PORTRAIT_H - HP_BAR_H, 0.0, 50.0) - 38
	# 簡化：portrait 佔 HP_BAR_H 到 PORTRAIT_H+HP_BAR_H
	var portrait_path = "res://resources/art/portraits/" + member.char_id + "_portrait.svg"
	if ResourceLoader.exists(portrait_path):
		var tex_rect = TextureRect.new()
		tex_rect.position = Vector2(0, HP_BAR_H)
		tex_rect.size = Vector2(CARD_W, PORTRAIT_H)
		tex_rect.texture = load(portrait_path)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.name = "Portrait"
		card.add_child(tex_rect)
	else:
		# 回退：職業色塊填充 portrait 區
		var color_fill = ColorRect.new()
		color_fill.position = Vector2(0, HP_BAR_H)
		color_fill.size = Vector2(CARD_W, PORTRAIT_H)
		color_fill.color = Color(member.body_color.r, member.body_color.g, member.body_color.b, 0.5)
		color_fill.name = "Portrait"
		card.add_child(color_fill)

	# ── ③ 名牌條（疊在 portrait 頂部，半透明黑底）────────────
	var nameplate = ColorRect.new()
	nameplate.position = Vector2(0, HP_BAR_H)
	nameplate.size = Vector2(CARD_W, NAMEPLATE_H)
	nameplate.color = COLOR_NAMEPLATE_BG
	nameplate.name = "Nameplate"
	card.add_child(nameplate)

	var name_lbl = Label.new()
	var display_name = member.char_name
	if display_name.length() > 4:
		display_name = display_name.substr(0, 4) + "…"
	name_lbl.text = display_name
	name_lbl.position = Vector2(8, HP_BAR_H + 5)
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.modulate = COLOR_TEXT_MAIN
	name_lbl.name = "NameLabel"
	card.add_child(name_lbl)

	# HP% 數字（名牌右側）
	var hp_lbl = Label.new()
	var hp_pct = int(member.current_hp * 100.0 / member.max_hp) if member.max_hp > 0 else 0
	hp_lbl.text = str(hp_pct) + "%"
	hp_lbl.position = Vector2(CARD_W - 44, HP_BAR_H + 5)
	hp_lbl.add_theme_font_size_override("font_size", 13)
	hp_lbl.modulate = COLOR_HP_HIGH
	hp_lbl.name = "HPLabel"
	card.add_child(hp_lbl)

	# ── ④ 技能狀態區（卡片底部 38px）────────────────────────
	var skill_bar_y = HP_BAR_H + PORTRAIT_H
	var skill_bar_h = CARD_H - skill_bar_y

	var skill_bg = ColorRect.new()
	skill_bg.position = Vector2(0, skill_bar_y)
	skill_bg.size = Vector2(CARD_W, skill_bar_h)
	skill_bg.color = Color(0.05, 0.08, 0.05, 0.95)
	skill_bg.name = "SkillBG"
	card.add_child(skill_bg)

	# 技能名稱（左側小字）
	var ult_name_lbl = Label.new()
	ult_name_lbl.text = member.ultimate_name if member.get("ultimate_name") else "大招"
	ult_name_lbl.position = Vector2(6, skill_bar_y + 2)
	ult_name_lbl.add_theme_font_size_override("font_size", 11)
	ult_name_lbl.modulate = Color(0.6, 0.7, 0.6, 1.0)
	ult_name_lbl.name = "UltNameLabel"
	card.add_child(ult_name_lbl)

	# 技能狀態主標籤（右側：就緒 / CD秒數）
	var ult_lbl = Label.new()
	ult_lbl.text = "就緒"
	ult_lbl.position = Vector2(CARD_W - 48, skill_bar_y + 2)
	ult_lbl.size = Vector2(44, skill_bar_h)
	ult_lbl.add_theme_font_size_override("font_size", 13)
	ult_lbl.modulate = COLOR_READY_BORDER
	ult_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ult_lbl.name = "UltLabel"
	card.add_child(ult_lbl)

	# ── ⑤ CD 遮罩（portrait 區半透明黑，顯示大 CD 數字）─────
	var cd_overlay = ColorRect.new()
	cd_overlay.position = Vector2(0, HP_BAR_H)
	cd_overlay.size = Vector2(CARD_W, PORTRAIT_H)
	cd_overlay.color = COLOR_CD_OVERLAY
	cd_overlay.visible = false
	cd_overlay.name = "CDOverlay"
	card.add_child(cd_overlay)

	# CD 大數字（疊在 portrait 中央）
	var cd_num_lbl = Label.new()
	cd_num_lbl.position = Vector2(0, HP_BAR_H + PORTRAIT_H * 0.25)
	cd_num_lbl.size = Vector2(CARD_W, PORTRAIT_H * 0.5)
	cd_num_lbl.add_theme_font_size_override("font_size", 44)
	cd_num_lbl.modulate = Color(0.85, 0.85, 0.95, 1.0)
	cd_num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_num_lbl.visible = false
	cd_num_lbl.name = "CDNumLabel"
	card.add_child(cd_num_lbl)

	# ── ⑥ 死亡遮罩 ───────────────────────────────────────────
	var dead_overlay = ColorRect.new()
	dead_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dead_overlay.color = COLOR_DEAD_OVERLAY
	dead_overlay.visible = false
	dead_overlay.name = "DeadOverlay"
	card.add_child(dead_overlay)

	var dead_lbl = Label.new()
	dead_lbl.text = "✕"
	dead_lbl.position = Vector2(0, HP_BAR_H + PORTRAIT_H * 0.2)
	dead_lbl.size = Vector2(CARD_W, PORTRAIT_H * 0.6)
	dead_lbl.add_theme_font_size_override("font_size", 48)
	dead_lbl.modulate = Color(1.0, 0.25, 0.25, 0.9)
	dead_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dead_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dead_lbl.visible = false
	dead_lbl.name = "DeadLabel"
	card.add_child(dead_lbl)

	# ── ⑦ 外框 Panel（最上層，邊框變色：就緒=綠/CD=灰/死=紅）
	var border = Panel.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var border_style = _make_border_style(COLOR_READY_BORDER, 3)
	border.add_theme_stylebox_override("panel", border_style)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.name = "Border"
	card.add_child(border)

	# ── ⑧ 點擊按鈕（覆蓋全卡，捕捉大招點擊）────────────────
	var ult_btn = Button.new()
	ult_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ult_btn.flat = true
	var btn_empty = StyleBoxEmpty.new()
	for s in ["normal","hover","pressed","focus"]:
		ult_btn.add_theme_stylebox_override(s, btn_empty)
	ult_btn.name = "UltBtn"
	ult_btn.pressed.connect(_on_ultimate_pressed.bind(member, card))
	card.add_child(ult_btn)

	# ── 信號連接 ─────────────────────────────────────────────
	member.hp_changed.connect(_on_hp_changed.bind(hp_bar, hp_lbl, card))
	member.ultimate_ready.connect(_on_ultimate_ready.bind(card, member.char_id))
	member.ultimate_used.connect(_on_ultimate_used.bind(card))
	member.character_died.connect(_on_character_died.bind(card))

	return card

func _make_border_style(border_color: Color, width: int) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)      # 透明底，只顯示邊框
	s.border_color = border_color
	s.set_border_width_all(width)
	s.set_corner_radius_all(6)
	s.draw_center = false
	return s

# ---- 卡片狀態切換 ----

func _set_card_ready_state(card: Control) -> void:
	# 隱藏 CD 遮罩與大數字
	var cd_ov = card.find_child("CDOverlay", false, false)
	if cd_ov: cd_ov.visible = false
	var cd_num = card.find_child("CDNumLabel", false, false) as Label
	if cd_num: cd_num.visible = false
	# 技能標籤顯示「就緒」綠字
	var ult_lbl = card.find_child("UltLabel", false, false) as Label
	if ult_lbl:
		ult_lbl.text = "就緒"
		ult_lbl.add_theme_font_size_override("font_size", 13)
		ult_lbl.modulate = COLOR_READY_BORDER
	# 邊框改回綠色（_process 脈衝控制）
	var border = card.find_child("Border", false, false) as Panel
	if border:
		border.add_theme_stylebox_override("panel", _make_border_style(COLOR_READY_BORDER, 3))
	var btn = card.find_child("UltBtn", false, false) as Button
	if btn: btn.disabled = false

func _set_card_cd_state(card: Control, remaining: float) -> void:
	var secs = int(remaining) + 1 if remaining > 0.0 else 0
	# 顯示 portrait 上的 CD 遮罩 + 大數字
	var cd_ov = card.find_child("CDOverlay", false, false)
	if cd_ov: cd_ov.visible = true
	var cd_num = card.find_child("CDNumLabel", false, false) as Label
	if cd_num:
		cd_num.text = str(secs)
		cd_num.visible = true
		cd_num.modulate = COLOR_ORANGE if secs <= 5 else Color(0.85, 0.85, 0.95, 1.0)
	# 技能標籤顯示 CDxs
	var ult_lbl = card.find_child("UltLabel", false, false) as Label
	if ult_lbl:
		ult_lbl.text = str(secs) + "s"
		ult_lbl.add_theme_font_size_override("font_size", 13)
		ult_lbl.modulate = COLOR_ORANGE if secs <= 5 else Color(0.6, 0.6, 0.7, 1.0)
	# 邊框灰色
	var border = card.find_child("Border", false, false) as Panel
	if border:
		border.add_theme_stylebox_override("panel",
			_make_border_style(Color(0.3, 0.3, 0.35, 1.0), 2))
	var btn = card.find_child("UltBtn", false, false) as Button
	if btn: btn.disabled = true

func _set_card_dead_state(card: Control) -> void:
	# 顯示死亡遮罩 + ✕
	var dead_ov = card.find_child("DeadOverlay", false, false)
	if dead_ov: dead_ov.visible = true
	var dead_lbl = card.find_child("DeadLabel", false, false) as Label
	if dead_lbl: dead_lbl.visible = true
	# 隱藏 CD 相關
	var cd_ov = card.find_child("CDOverlay", false, false)
	if cd_ov: cd_ov.visible = false
	var cd_num = card.find_child("CDNumLabel", false, false)
	if cd_num: cd_num.visible = false
	# 名稱變暗紅
	var name_lbl = card.find_child("NameLabel", false, false) as Label
	if name_lbl: name_lbl.modulate = COLOR_DEAD_TEXT
	# HP% 清零
	var hp_lbl = card.find_child("HPLabel", false, false) as Label
	if hp_lbl: hp_lbl.text = "0%"
	# 技能標籤隱藏
	var ult_lbl = card.find_child("UltLabel", false, false) as Label
	if ult_lbl: ult_lbl.text = ""
	# 邊框改紅
	var border = card.find_child("Border", false, false) as Panel
	if border:
		border.add_theme_stylebox_override("panel",
			_make_border_style(Color(0.7, 0.1, 0.1, 1.0), 3))
	var btn = card.find_child("UltBtn", false, false) as Button
	if btn: btn.disabled = true

# ---- 信號回調 ----

func _on_ultimate_pressed(member, card: Control) -> void:
	if GameManager.is_paused or GameManager.is_game_over:
		return
	if member.use_ultimate():
		AudioManager.play_ult(member.char_id)
		_set_card_cd_state(card, member.get_cd_remaining())
		var tm = get_node_or_null("/root/TutorialManager")
		if tm: tm.notify_ult_used(member.char_id)

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

func _on_ultimate_ready(card: Control, char_id: String = "") -> void:
	if card and is_instance_valid(card):
		_set_card_ready_state(card)
		AudioManager.play_sfx("ult_ready")
		if char_id != "":
			var tm2 = get_node_or_null("/root/TutorialManager")
			if tm2: tm2.notify_ult_ready(char_id)

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
			# 大招就緒：Border 綠色脈衝（1.2 秒週期，邊框寬度 3~5px）
			var pulse = (sin(_pulse_timer * TAU / 1.2) + 1.0) * 0.5
			var border = card.find_child("Border", false, false) as Panel
			if border:
				var glow_r = 0.13 + pulse * 0.15
				var glow_g = 0.80 + pulse * 0.20
				var glow_b = 0.27 + pulse * 0.05
				var bw = 3 + int(pulse * 2)
				border.add_theme_stylebox_override("panel",
					_make_border_style(Color(glow_r, glow_g, glow_b, 1.0), bw))

	# 預警 Toast 倒計時
	if _recon_toast and _recon_toast.visible:
		_recon_toast_timer -= delta
		if _recon_toast_timer <= 0.0:
			_recon_toast.visible = false

func _on_game_won() -> void:
	# 先顯示故事片段，完成後再顯示結算
	var story_script = load("res://scripts/story_panel.gd")
	if story_script:
		var story = CanvasLayer.new()
		story.set_script(story_script)
		get_tree().root.add_child(story)
		story.show_story(
			GameManager.current_mission_id,
			func(): _show_victory_panel()  # 故事結束後才顯示結算
		)
	else:
		_show_victory_panel()  # 回退：直接顯示結算

func _show_victory_panel() -> void:
	if AudioManager:
		AudioManager.play_sfx("victory_sting")
	game_result_panel.show()
	# 從 GameManager 讀取任務名稱
	var mission_name: String = GameManager.current_mission_data.get("name", "任務完成")
	result_label.text = mission_name + " 完成！"
	result_label.modulate = Color(0.3, 1.0, 0.4)
	AudioManager.play_sfx("victory")
	# 從 GameManager 讀取獎勵配置
	var mission_data = GameManager.current_mission_data
	var reward_coins: int = mission_data.get("reward_coins", 200)
	var reward_gold: int = mission_data.get("reward_gold_tickets", 0)
	var reward_blue: int = mission_data.get("reward_blue_tickets", 0)
	SaveManager.add_coins(reward_coins)
	# 記錄任務完成（防止重複領獎）
	var mission_id: String = mission_data.get("id", "")
	if mission_id != "":
		SaveManager.mark_mission_complete(mission_id)
	var ticket_text = ""
	if reward_gold > 0:
		SaveManager.gold_tickets += reward_gold
		SaveManager.save_game()
		ticket_text = " + %d 金票" % reward_gold
	elif reward_blue > 0:
		SaveManager.add_blue_tickets(reward_blue)
		ticket_text = " + %d 藍票" % reward_blue
	else:
		SaveManager.save_game()
	# 勝利時：只顯示「返回基地」
	if retry_btn:
		retry_btn.visible = false
	if restart_btn:
		restart_btn.text = "返回基地"
		restart_btn.visible = true
	# 金幣數字動畫（count-up 1.5 秒）
	var tween = create_tween()
	tween.tween_method(_update_coin_display, 0, reward_coins, 1.5)
	# 動畫結束後顯示最終文字（含票券資訊）
	var final_ticket_text = ticket_text
	var final_coins = reward_coins
	tween.tween_callback(func():
		if result_desc and is_instance_valid(result_desc):
			result_desc.text = "小隊成功完成任務！\n獲得 " + str(final_coins) + " 金幣" + final_ticket_text + "！"
	)

func _on_game_lost() -> void:
	AudioManager.play_sfx("defeat")
	# 安慰獎勵
	SaveManager.add_coins(30)
	SaveManager.save_game()
	# 短暫延遲後顯示結算面板（電影感停頓）
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(game_result_panel):
		return
	game_result_panel.show()
	result_label.text = "任務失敗"
	result_label.modulate = Color(0.8, 0.1, 0.1)
	result_desc.text = "小隊無法完成任務。\n獲得安慰獎勵 30 金幣，繼續努力！"
	# 失敗時：顯示「重試」和「返回基地」
	if retry_btn:
		retry_btn.text = "重試任務"
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

func _update_coin_display(coins_shown: int) -> void:
	if result_desc and is_instance_valid(result_desc):
		result_desc.text = "小隊成功完成任務！\n獲得金幣：" + str(coins_shown)
