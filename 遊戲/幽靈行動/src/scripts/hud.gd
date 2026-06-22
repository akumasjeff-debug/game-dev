extends CanvasLayer

# ═══════════════════════════════════════════════════════════════════
# hud.gd — 幽靈行動 戰鬥 HUD（商業手遊質感強化版）
#
# 對外公開介面（簽名不變，供其他腳本呼叫）：
#   setup_cards(squad: Array)         建立底部 4 張角色技能卡
#   update_progress(ratio: float)     更新頂部任務進度條
#   show_recon_warning(next_type)     偵察手預警訊息
#   show_message(text, important)     中央訊息（新增，向後相容）
#
# 設計語言：軍事戰術深藍灰底 + 橘/紅點綴。
#   - 統一 StyleBoxFlat 圓角邊框質感
#   - 技能卡：職業色邊框 + radial CD 環 + 就緒脈動 + 按下回饋
#   - HP% 三段色（綠/黃/紅）
#   - 中央訊息佇列（淡入淡出，重要訊息獨立樣式）
#   - 速度(x1/x2/x3)/暫停 大觸控按鈕
#   - 底部 home indicator 安全邊距
# ═══════════════════════════════════════════════════════════════════

@onready var progress_bar: ProgressBar = $TopBar/ProgressBar
@onready var progress_label: Label = $TopBar/ProgressLabel
@onready var cards_container: HBoxContainer = $BottomBar/CardsContainer
@onready var game_result_panel: Panel = $GameResultPanel
@onready var result_label: Label = $GameResultPanel/VBox/ResultLabel
@onready var result_desc: Label = $GameResultPanel/VBox/DescLabel
@onready var retry_btn: Button = $GameResultPanel/VBox/RetryBtn
@onready var restart_btn: Button = $GameResultPanel/VBox/RestartBtn

const RadialScript = preload("res://scripts/hud_radial.gd")

# ── 統一配色（軍事戰術）────────────────────────────────────────────
const COL_BG_DEEP      := Color(0.055, 0.067, 0.094, 1.0)   # 最深底 #0E1118
const COL_PANEL        := Color(0.094, 0.110, 0.145, 0.96)  # 面板深藍灰 #181C25
const COL_PANEL_HI     := Color(0.145, 0.169, 0.216, 1.0)   # 面板亮邊
const COL_LINE         := Color(0.22, 0.26, 0.33, 1.0)      # 分隔線/邊框灰
const COL_ORANGE       := Color(0.93, 0.45, 0.12, 1.0)      # 戰術橘 #ED730F
const COL_RED          := Color(0.86, 0.20, 0.18, 1.0)      # 警示紅
const COL_GREEN        := Color(0.20, 0.82, 0.36, 1.0)      # 就緒綠 #34D15C
const COL_TEXT         := Color(0.93, 0.95, 0.97, 1.0)      # 主文字
const COL_TEXT_DIM     := Color(0.62, 0.68, 0.74, 1.0)      # 次文字
const COL_GOLD         := Color(1.0, 0.84, 0.32, 1.0)       # 任務名金

# HP 三段色
const COL_HP_HI  := Color(0.20, 0.82, 0.36, 1.0)
const COL_HP_MID := Color(0.96, 0.70, 0.10, 1.0)
const COL_HP_LOW := Color(0.90, 0.22, 0.18, 1.0)

# 職業色（依 char_id；用於卡片邊框點綴）
const CLASS_COLORS := {
	"assault": Color(0.93, 0.45, 0.12, 1.0),   # 突擊手 橘
	"sniper":  Color(0.55, 0.38, 0.92, 1.0),   # 狙擊手 紫
	"medic":   Color(0.25, 0.78, 0.55, 1.0),   # 醫療兵 翠綠
	"shield":  Color(0.30, 0.58, 0.92, 1.0),   # 盾兵 藍
	"demo":    Color(0.90, 0.30, 0.22, 1.0),   # 爆破手 紅
	"recon":   Color(0.95, 0.80, 0.25, 1.0),   # 偵察手 黃
}

# ── 卡片尺寸 ────────────────────────────────────────────────────────
const CARD_W: float = 248.0
const CARD_H: float = 186.0
const HP_BAR_H: float = 8.0
const NAMEPLATE_H: float = 30.0
const PORTRAIT_H: float = 110.0
const SKILL_BAR_H: float = 38.0

# 底部 home indicator 安全邊距（直屏 iPhone 約 34 邏輯px，這裡用較寬鬆值）
const SAFE_BOTTOM: float = 28.0

# ── 狀態 ────────────────────────────────────────────────────────────
var card_nodes: Array = []
var squad_ref: Array = []
var _card_meta: Array = []   # 每張卡的子節點快取 { radial, border, hp_bar, ... }

var _pulse_timer: float = 0.0

# 速度控制
var _speed_levels := [1.0, 2.0, 3.0]
var _speed_idx: int = 0
var _speed_btn: Button = null
var _pause_btn: Button = null
var _is_user_paused: bool = false

# 中央訊息佇列
var _msg_label: Label = null
var _msg_panel: Panel = null
var _msg_queue: Array = []          # [{text, important, dur}]
var _msg_active: bool = false

# 頂部
var _mission_name_label: Label = null
var _room_progress_label: Label = null
var _room_pips: Array = []          # 進度條分段刻度
var _total_rooms: int = 4
var _progress_target: float = 0.0   # 進度條平滑填充目標(0~100)

# 偵察手預警（沿用舊介面，內部改走訊息系統樣式）
var _recon_toast: Label = null
var _recon_toast_timer: float = 0.0
const TOAST_DURATION: float = 5.0


# ═══════════════════════════════════════════════════════════════════
# 生命週期
# ═══════════════════════════════════════════════════════════════════
func _ready() -> void:
	game_result_panel.hide()
	_style_result_panel()
	GameManager.game_won.connect(_on_game_won)
	GameManager.game_lost.connect(_on_game_lost)
	_style_top_bar()
	_add_top_bar()
	_build_message_system()
	_build_recon_toast()
	_build_speed_pause_controls()
	if retry_btn:
		retry_btn.pressed.connect(_on_retry_pressed)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)
	_apply_safe_bottom_margin()


func _apply_safe_bottom_margin() -> void:
	# 把卡片容器底部往上抬，避開 home indicator
	if cards_container:
		cards_container.offset_bottom = -(SAFE_BOTTOM + 6.0)


# ═══════════════════════════════════════════════════════════════════
# 共用樣式工廠
# ═══════════════════════════════════════════════════════════════════
func _panel_style(bg: Color, border_col: Color, border_w: int, radius: int) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border_col
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	return s

func _border_only_style(border_col: Color, width: int, radius: int = 8) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.border_color = border_col
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.draw_center = false
	return s

func _apply_button_skin(btn: Button, base: Color, accent: Color) -> void:
	var normal = _panel_style(base, accent.darkened(0.2), 2, 10)
	var hover = _panel_style(base.lightened(0.10), accent, 2, 10)
	var pressed = _panel_style(accent.darkened(0.25), accent, 2, 10)
	var disabled = _panel_style(base.darkened(0.3), COL_LINE, 1, 10)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_stylebox_override("focus", _border_only_style(accent, 2, 10))
	btn.add_theme_color_override("font_color", COL_TEXT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)


# ═══════════════════════════════════════════════════════════════════
# 頂部任務列
# ═══════════════════════════════════════════════════════════════════
func _style_top_bar() -> void:
	var top = get_node_or_null("TopBar")
	if top == null:
		return
	# 背板換成有質感的 Panel 樣式（疊在原 ColorRect 之上）
	var bgp = Panel.new()
	bgp.name = "TopBarSkin"
	bgp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bgp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st = _panel_style(COL_PANEL, COL_LINE, 0, 0)
	st.border_width_bottom = 2
	st.border_color = COL_ORANGE.darkened(0.2)
	bgp.add_theme_stylebox_override("panel", st)
	top.add_child(bgp)
	top.move_child(bgp, 1)  # 在原 ProgressBG 之後、其他元素之前

	# 進度條樣式
	if progress_bar:
		var fill = _panel_style(COL_ORANGE, Color(0,0,0,0), 0, 5)
		var bg = _panel_style(Color(0.04, 0.05, 0.07, 1.0), COL_LINE, 1, 5)
		progress_bar.add_theme_stylebox_override("fill", fill)
		progress_bar.add_theme_stylebox_override("background", bg)
	if progress_label:
		progress_label.add_theme_color_override("font_color", COL_TEXT)
		progress_label.add_theme_font_size_override("font_size", 20)

func _add_top_bar() -> void:
	# 任務名稱（左側）
	_mission_name_label = Label.new()
	_mission_name_label.name = "MissionNameLabel"
	_mission_name_label.position = Vector2(20, 12)
	_mission_name_label.size = Vector2(340, 40)
	_mission_name_label.add_theme_font_size_override("font_size", 26)
	_mission_name_label.add_theme_color_override("font_color", COL_GOLD)
	_mission_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mission_name_label.text = GameManager.current_mission_data.get("name", "任務")
	add_child(_mission_name_label)

	# 房間進度文字（右側，避開速度/暫停按鈕，往左留空間）
	_room_progress_label = Label.new()
	_room_progress_label.name = "RoomProgressLabel"
	_room_progress_label.size = Vector2(280, 40)
	_room_progress_label.position = Vector2(560, 12)
	_room_progress_label.add_theme_font_size_override("font_size", 22)
	_room_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_room_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_room_progress_label.add_theme_color_override("font_color", COL_TEXT)
	_room_progress_label.text = "房間 1 / " + str(_total_rooms)
	add_child(_room_progress_label)

	_build_room_pips()

	if GameManager.has_signal("room_advanced"):
		GameManager.room_advanced.connect(_on_room_advanced)

func _build_room_pips() -> void:
	# 在進度條上方疊出 N 段刻度（分段感）
	if progress_bar == null:
		return
	var pips_holder = Control.new()
	pips_holder.name = "RoomPips"
	pips_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pips_holder.anchor_right = 1.0
	pips_holder.offset_left = 380.0
	pips_holder.offset_top = 50.0
	pips_holder.offset_right = -20.0
	pips_holder.offset_bottom = 80.0
	var top = get_node_or_null("TopBar")
	if top == null:
		return
	top.add_child(pips_holder)
	_room_pips.clear()
	for i in range(_total_rooms):
		var pip = ColorRect.new()
		pip.color = COL_LINE
		pip.name = "Pip%d" % i
		pip.anchor_left = float(i) / float(_total_rooms)
		pip.anchor_right = float(i + 1) / float(_total_rooms)
		pip.anchor_top = 0.0
		pip.anchor_bottom = 1.0
		pip.offset_left = 2.0
		pip.offset_right = -2.0
		pips_holder.add_child(pip)
		_room_pips.append(pip)

func _refresh_room_pips(cleared: int) -> void:
	for i in range(_room_pips.size()):
		var pip = _room_pips[i]
		if pip == null or not is_instance_valid(pip):
			continue
		pip.color = COL_ORANGE if i < cleared else COL_LINE

func _on_room_advanced(room_index: int) -> void:
	if _room_progress_label and is_instance_valid(_room_progress_label):
		var display_idx = mini(room_index + 1, _total_rooms)
		_room_progress_label.text = "房間 " + str(display_idx) + " / " + str(_total_rooms)
	var ratio := float(room_index) / float(_total_rooms)
	update_progress(ratio)
	_refresh_room_pips(room_index)
	if room_index > 0:
		show_message("房間清空", true)


# ═══════════════════════════════════════════════════════════════════
# 中央訊息佇列系統
# ═══════════════════════════════════════════════════════════════════
func _build_message_system() -> void:
	_msg_panel = Panel.new()
	_msg_panel.name = "MessagePanel"
	_msg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_msg_panel.anchor_left = 0.5
	_msg_panel.anchor_right = 0.5
	_msg_panel.anchor_top = 0.32
	_msg_panel.anchor_bottom = 0.32
	_msg_panel.offset_left = -300
	_msg_panel.offset_right = 300
	_msg_panel.offset_top = -44
	_msg_panel.offset_bottom = 44
	_msg_panel.add_theme_stylebox_override("panel", _panel_style(COL_PANEL, COL_ORANGE, 2, 12))
	_msg_panel.modulate = Color(1, 1, 1, 0)
	add_child(_msg_panel)

	_msg_label = Label.new()
	_msg_label.name = "MessageLabel"
	_msg_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_msg_label.add_theme_font_size_override("font_size", 30)
	_msg_label.add_theme_color_override("font_color", COL_TEXT)
	_msg_panel.add_child(_msg_label)

func show_message(text: String, important: bool = false) -> void:
	# 中央訊息（公開）。important=true 用紅框警示樣式。
	_msg_queue.append({"text": text, "important": important})
	if not _msg_active:
		_play_next_message()

func _play_next_message() -> void:
	if _msg_queue.is_empty():
		_msg_active = false
		return
	_msg_active = true
	var item = _msg_queue.pop_front()
	var important: bool = item.get("important", false)
	_msg_label.text = item.get("text", "")
	if important:
		_msg_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.18, 0.06, 0.06, 0.96), COL_RED, 3, 12))
		_msg_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
		_msg_label.add_theme_font_size_override("font_size", 34)
	else:
		_msg_panel.add_theme_stylebox_override("panel", _panel_style(COL_PANEL, COL_ORANGE, 2, 12))
		_msg_label.add_theme_color_override("font_color", COL_TEXT)
		_msg_label.add_theme_font_size_override("font_size", 30)

	_msg_panel.scale = Vector2(0.85, 0.85)
	_msg_panel.pivot_offset = _msg_panel.size * 0.5
	var hold := 1.4 if important else 1.0
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_msg_panel, "modulate:a", 1.0, 0.18)
	tw.tween_property(_msg_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	tw.tween_interval(hold)
	tw.tween_property(_msg_panel, "modulate:a", 0.0, 0.30)
	tw.tween_callback(_play_next_message)


# ═══════════════════════════════════════════════════════════════════
# 偵察手預警（沿用舊介面）
# ═══════════════════════════════════════════════════════════════════
func _build_recon_toast() -> void:
	_recon_toast = Label.new()
	_recon_toast.name = "ReconToast"
	_recon_toast.add_theme_font_size_override("font_size", 18)
	_recon_toast.add_theme_color_override("font_color", COL_ORANGE)
	_recon_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_recon_toast.anchor_left = 0.0
	_recon_toast.anchor_top = 0.0
	_recon_toast.anchor_right = 1.0
	_recon_toast.anchor_bottom = 0.0
	_recon_toast.offset_top = 92.0
	_recon_toast.offset_bottom = 122.0
	_recon_toast.visible = false
	add_child(_recon_toast)

func show_recon_warning(next_type: String) -> void:
	if _recon_toast == null:
		return
	_recon_toast.text = "偵察手預警：前方有 " + next_type
	_recon_toast.visible = true
	_recon_toast.modulate = Color(1, 1, 1, 0)
	var tw = create_tween()
	tw.tween_property(_recon_toast, "modulate:a", 1.0, 0.2)
	_recon_toast_timer = TOAST_DURATION


# ═══════════════════════════════════════════════════════════════════
# 速度 / 暫停 控制（動態建立，大觸控區）
# ═══════════════════════════════════════════════════════════════════
func _build_speed_pause_controls() -> void:
	# 容器靠頂部右上角，按鈕 64x64（>48 邏輯px 觸控建議）
	var holder = Control.new()
	holder.name = "SpeedPauseControls"
	holder.anchor_left = 1.0
	holder.anchor_right = 1.0
	holder.anchor_top = 0.0
	holder.offset_left = -156.0
	holder.offset_top = 14.0
	holder.offset_right = -12.0
	holder.offset_bottom = 78.0
	add_child(holder)

	_speed_btn = Button.new()
	_speed_btn.name = "SpeedBtn"
	_speed_btn.custom_minimum_size = Vector2(64, 64)
	_speed_btn.position = Vector2(0, 0)
	_speed_btn.size = Vector2(64, 64)
	_speed_btn.text = "x1"
	_speed_btn.add_theme_font_size_override("font_size", 24)
	_apply_button_skin(_speed_btn, COL_PANEL_HI, COL_ORANGE)
	_speed_btn.pressed.connect(_on_speed_pressed)
	holder.add_child(_speed_btn)

	_pause_btn = Button.new()
	_pause_btn.name = "PauseBtn"
	_pause_btn.custom_minimum_size = Vector2(64, 64)
	_pause_btn.position = Vector2(76, 0)
	_pause_btn.size = Vector2(64, 64)
	_pause_btn.text = "暫停"
	_pause_btn.add_theme_font_size_override("font_size", 20)
	_apply_button_skin(_pause_btn, COL_PANEL_HI, COL_GREEN)
	_pause_btn.pressed.connect(_on_pause_pressed)
	holder.add_child(_pause_btn)

func _on_speed_pressed() -> void:
	_speed_idx = (_speed_idx + 1) % _speed_levels.size()
	var spd = _speed_levels[_speed_idx]
	# 不改 GameManager：直接調整引擎時間倍率
	if not _is_user_paused:
		Engine.time_scale = spd
	_speed_btn.text = "x%d" % int(spd)
	_press_feedback(_speed_btn)
	_safe_click_sfx()

func _on_pause_pressed() -> void:
	_is_user_paused = not _is_user_paused
	if _is_user_paused:
		# 用 GameManager 的暫停（凍結小隊邏輯）；不把 time_scale 設 0，
		# 否則 HUD 的 create_tween（process-time）也會凍結，訊息淡入會卡住。
		if GameManager.has_method("pause_squad"):
			GameManager.pause_squad()
		_pause_btn.text = "繼續"
		_pause_btn.add_theme_color_override("font_color", COL_GREEN)
		show_message("已暫停", false)
	else:
		if GameManager.has_method("resume_squad"):
			GameManager.resume_squad()
		_pause_btn.text = "暫停"
		_pause_btn.add_theme_color_override("font_color", COL_TEXT)
	_press_feedback(_pause_btn)
	_safe_click_sfx()

func _safe_click_sfx() -> void:
	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("btn_click")

func _press_feedback(node: Control) -> void:
	if node == null or not is_instance_valid(node):
		return
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2(0.88, 0.88)
	var tw = create_tween()
	tw.tween_property(node, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ═══════════════════════════════════════════════════════════════════
# 角色技能卡
# ═══════════════════════════════════════════════════════════════════
func setup_cards(squad: Array) -> void:
	squad_ref = squad
	for child in cards_container.get_children():
		child.queue_free()
	card_nodes.clear()
	_card_meta.clear()

	var display_count = mini(squad.size(), 4)
	for i in range(display_count):
		var card = _create_character_card(squad[i])
		cards_container.add_child(card)
		card_nodes.append(card)

func _class_color(member) -> Color:
	var cid = ""
	if member and member.get("char_id") != null:
		cid = str(member.char_id)
	return CLASS_COLORS.get(cid, COL_ORANGE)

func _create_character_card(member) -> Control:
	var accent: Color = _class_color(member)

	# ── 外層容器 ──
	var card = Control.new()
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.pivot_offset = Vector2(CARD_W * 0.5, CARD_H * 0.5)

	# ── 底板（圓角深色 + 職業色微光底邊）──
	var bg = Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_theme_stylebox_override("panel", _panel_style(COL_BG_DEEP, accent.darkened(0.4), 1, 12))
	card.add_child(bg)

	# ── 立繪區（HP 條下方）──
	var portrait_holder = Control.new()
	portrait_holder.position = Vector2(0, HP_BAR_H)
	portrait_holder.size = Vector2(CARD_W, PORTRAIT_H)
	portrait_holder.clip_contents = true
	portrait_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_holder.name = "PortraitHolder"
	card.add_child(portrait_holder)

	var portrait_path = "res://resources/art/portraits/" + str(member.char_id) + "_portrait.svg"
	if ResourceLoader.exists(portrait_path):
		var tex_rect = TextureRect.new()
		tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex_rect.texture = load(portrait_path)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.name = "Portrait"
		portrait_holder.add_child(tex_rect)
	else:
		var color_fill = ColorRect.new()
		color_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var bc: Color = member.body_color if member.get("body_color") != null else accent
		color_fill.color = Color(bc.r, bc.g, bc.b, 0.5)
		color_fill.name = "Portrait"
		portrait_holder.add_child(color_fill)

	# 立繪底部漸層壓暗（讓技能列文字更清楚）— 用半透明色塊近似
	var grad = ColorRect.new()
	grad.position = Vector2(0, PORTRAIT_H - 36)
	grad.size = Vector2(CARD_W, 36)
	grad.color = Color(0.0, 0.0, 0.0, 0.45)
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_holder.add_child(grad)

	# ── HP 細條（卡頂全寬）──
	var hp_bar = ProgressBar.new()
	hp_bar.size = Vector2(CARD_W, HP_BAR_H)
	hp_bar.position = Vector2(0, 0)
	hp_bar.min_value = 0.0
	hp_bar.max_value = member.max_hp
	hp_bar.value = member.current_hp
	hp_bar.show_percentage = false
	hp_bar.name = "HPBar"
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar.add_theme_stylebox_override("fill", _panel_style(COL_HP_HI, Color(0,0,0,0), 0, 0))
	hp_bar.add_theme_stylebox_override("background", _panel_style(Color(0.10,0.10,0.12,0.9), Color(0,0,0,0), 0, 0))
	card.add_child(hp_bar)

	# ── 名牌條 ──
	var nameplate = ColorRect.new()
	nameplate.position = Vector2(0, HP_BAR_H)
	nameplate.size = Vector2(CARD_W, NAMEPLATE_H)
	nameplate.color = Color(0.0, 0.0, 0.0, 0.62)
	nameplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nameplate.name = "Nameplate"
	card.add_child(nameplate)

	# 職業色標籤條（名牌左側豎條）
	var class_tab = ColorRect.new()
	class_tab.position = Vector2(0, HP_BAR_H)
	class_tab.size = Vector2(5, NAMEPLATE_H)
	class_tab.color = accent
	class_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(class_tab)

	var name_lbl = Label.new()
	var display_name = str(member.char_name)
	if display_name.length() > 4:
		display_name = display_name.substr(0, 4) + "…"
	name_lbl.text = display_name
	name_lbl.position = Vector2(12, HP_BAR_H + 4)
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", COL_TEXT)
	name_lbl.name = "NameLabel"
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	var hp_lbl = Label.new()
	var hp_pct = int(member.current_hp * 100.0 / member.max_hp) if member.max_hp > 0 else 0
	hp_lbl.text = str(hp_pct) + "%"
	hp_lbl.position = Vector2(CARD_W - 56, HP_BAR_H + 5)
	hp_lbl.size = Vector2(50, NAMEPLATE_H - 6)
	hp_lbl.add_theme_font_size_override("font_size", 14)
	hp_lbl.add_theme_color_override("font_color", COL_HP_HI)
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_lbl.name = "HPLabel"
	hp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(hp_lbl)

	# ── CD radial 環（疊在立繪中央）──
	var radial = Control.new()
	radial.set_script(RadialScript)
	radial.position = Vector2(CARD_W * 0.5 - 44, HP_BAR_H + PORTRAIT_H * 0.5 - 44)
	radial.size = Vector2(88, 88)
	radial.set_ring_color(COL_ORANGE)
	radial.name = "Radial"
	card.add_child(radial)

	# CD 大數字（環中央）
	var cd_num = Label.new()
	cd_num.position = Vector2(0, HP_BAR_H + PORTRAIT_H * 0.5 - 28)
	cd_num.size = Vector2(CARD_W, 56)
	cd_num.add_theme_font_size_override("font_size", 42)
	cd_num.add_theme_color_override("font_color", Color(0.96, 0.96, 1.0))
	cd_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_num.visible = false
	cd_num.name = "CDNumLabel"
	cd_num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(cd_num)

	# ── 技能列（底部）──
	var skill_y = HP_BAR_H + PORTRAIT_H
	var skill_bg = ColorRect.new()
	skill_bg.position = Vector2(0, skill_y)
	skill_bg.size = Vector2(CARD_W, CARD_H - skill_y)
	skill_bg.color = Color(0.07, 0.09, 0.12, 0.96)
	skill_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_bg.name = "SkillBG"
	card.add_child(skill_bg)

	var ult_name_lbl = Label.new()
	ult_name_lbl.text = str(member.ultimate_name) if member.get("ultimate_name") else "大招"
	ult_name_lbl.position = Vector2(10, skill_y + 8)
	ult_name_lbl.size = Vector2(CARD_W - 90, SKILL_BAR_H)
	ult_name_lbl.add_theme_font_size_override("font_size", 14)
	ult_name_lbl.add_theme_color_override("font_color", COL_TEXT_DIM)
	ult_name_lbl.name = "UltNameLabel"
	ult_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(ult_name_lbl)

	var ult_lbl = Label.new()
	ult_lbl.text = "就緒"
	ult_lbl.position = Vector2(CARD_W - 76, skill_y + 8)
	ult_lbl.size = Vector2(68, SKILL_BAR_H - 14)
	ult_lbl.add_theme_font_size_override("font_size", 16)
	ult_lbl.add_theme_color_override("font_color", COL_GREEN)
	ult_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ult_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ult_lbl.name = "UltLabel"
	ult_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(ult_lbl)

	# ── 死亡遮罩 ──
	var dead_overlay = ColorRect.new()
	dead_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dead_overlay.color = Color(0.10, 0.10, 0.12, 0.78)
	dead_overlay.visible = false
	dead_overlay.name = "DeadOverlay"
	dead_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(dead_overlay)

	var dead_lbl = Label.new()
	dead_lbl.text = "陣亡"
	dead_lbl.position = Vector2(0, HP_BAR_H + PORTRAIT_H * 0.2)
	dead_lbl.size = Vector2(CARD_W, PORTRAIT_H * 0.6)
	dead_lbl.add_theme_font_size_override("font_size", 40)
	dead_lbl.add_theme_color_override("font_color", Color(1.0, 0.28, 0.28))
	dead_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dead_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dead_lbl.visible = false
	dead_lbl.name = "DeadLabel"
	dead_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(dead_lbl)

	# ── 外框（變色：就緒=綠脈動 / CD=職業色暗 / 死=紅）──
	var border = Panel.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.add_theme_stylebox_override("panel", _border_only_style(accent, 2, 12))
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.name = "Border"
	card.add_child(border)

	# ── 點擊按鈕（全卡）──
	var ult_btn = Button.new()
	ult_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ult_btn.flat = true
	var empty = StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		ult_btn.add_theme_stylebox_override(s, empty)
	ult_btn.name = "UltBtn"
	ult_btn.pressed.connect(_on_ultimate_pressed.bind(member, card))
	card.add_child(ult_btn)

	# 快取
	_card_meta.append({
		"card": card, "radial": radial, "border": border, "accent": accent,
		"cd_num": cd_num, "ult_lbl": ult_lbl, "hp_bar": hp_bar, "hp_lbl": hp_lbl,
		"name_lbl": name_lbl, "dead_overlay": dead_overlay, "dead_lbl": dead_lbl,
		"ult_btn": ult_btn, "member": member,
	})

	# 信號
	member.hp_changed.connect(_on_hp_changed.bind(hp_bar, hp_lbl, card))
	member.ultimate_ready.connect(_on_ultimate_ready.bind(card, str(member.char_id)))
	member.ultimate_used.connect(_on_ultimate_used.bind(card))
	member.character_died.connect(_on_character_died.bind(card))

	return card

func _meta_for(card) -> Dictionary:
	for m in _card_meta:
		if m.get("card") == card:
			return m
	return {}


# ═══════════════════════════════════════════════════════════════════
# 卡片狀態切換
# ═══════════════════════════════════════════════════════════════════
func _set_card_ready_state(card: Control) -> void:
	var m = _meta_for(card)
	if m.is_empty():
		return
	if m.radial: m.radial.set_cd_ratio(0.0)
	if m.cd_num: m.cd_num.visible = false
	if m.ult_lbl:
		m.ult_lbl.text = "就緒"
		m.ult_lbl.add_theme_color_override("font_color", COL_GREEN)
	if m.ult_btn: m.ult_btn.disabled = false

func _set_card_cd_state(card: Control, remaining: float) -> void:
	var m = _meta_for(card)
	if m.is_empty():
		return
	var member = m.get("member")
	var total_cd: float = 30.0
	if member and member.get("ultimate_cd") != null and member.ultimate_cd > 0.0:
		total_cd = float(member.ultimate_cd)
	var ratio: float = clampf(remaining / total_cd, 0.0, 1.0)
	var secs = int(remaining) + 1 if remaining > 0.0 else 0

	if m.radial:
		m.radial.set_ring_color(COL_ORANGE if secs <= 5 else m.get("accent", COL_ORANGE))
		m.radial.set_cd_ratio(ratio)
	if m.cd_num:
		m.cd_num.text = str(secs)
		m.cd_num.visible = secs > 0
		m.cd_num.add_theme_color_override("font_color", COL_ORANGE if secs <= 5 else Color(0.92,0.92,1.0))
	if m.ult_lbl:
		m.ult_lbl.text = str(secs) + "s"
		m.ult_lbl.add_theme_color_override("font_color", COL_ORANGE if secs <= 5 else COL_TEXT_DIM)
	if m.ult_btn: m.ult_btn.disabled = true

func _set_card_dead_state(card: Control) -> void:
	var m = _meta_for(card)
	if m.is_empty():
		return
	if m.dead_overlay: m.dead_overlay.visible = true
	if m.dead_lbl: m.dead_lbl.visible = true
	if m.radial: m.radial.set_cd_ratio(0.0)
	if m.cd_num: m.cd_num.visible = false
	if m.name_lbl: m.name_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	if m.hp_lbl: m.hp_lbl.text = "0%"
	if m.ult_lbl: m.ult_lbl.text = ""
	if m.border: m.border.add_theme_stylebox_override("panel", _border_only_style(Color(0.7, 0.12, 0.12, 1.0), 3, 12))
	if m.ult_btn: m.ult_btn.disabled = true
	# 立繪灰階近似：壓暗 + 去飽和
	var ph = card.find_child("PortraitHolder", true, false)
	if ph: ph.modulate = Color(0.45, 0.45, 0.48, 1.0)


# ═══════════════════════════════════════════════════════════════════
# 信號回調
# ═══════════════════════════════════════════════════════════════════
func _on_ultimate_pressed(member, card: Control) -> void:
	if GameManager.is_paused or GameManager.is_game_over:
		return
	if member.use_ultimate():
		AudioManager.play_ult(str(member.char_id))
		_set_card_cd_state(card, member.get_cd_remaining())
		_ult_cast_feedback(card)
		var tm = get_node_or_null("/root/TutorialManager")
		if tm: tm.notify_ult_used(str(member.char_id))

func _ult_cast_feedback(card: Control) -> void:
	# 施放回饋：卡片縮放彈一下 + 邊框白閃
	if card == null or not is_instance_valid(card):
		return
	card.scale = Vector2(1.12, 1.12)
	var tw = create_tween()
	tw.tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var m = _meta_for(card)
	if not m.is_empty() and m.border:
		m.border.add_theme_stylebox_override("panel", _border_only_style(Color.WHITE, 4, 12))

func _on_hp_changed(current: float, max_val: float, hp_bar: ProgressBar, hp_lbl: Label, card: Control) -> void:
	if hp_bar and is_instance_valid(hp_bar):
		var ratio = current / max_val if max_val > 0.0 else 0.0
		var col: Color
		if ratio > 0.5:
			col = COL_HP_HI
		elif ratio > 0.25:
			col = COL_HP_MID
		else:
			col = COL_HP_LOW
		# 血條平滑下降
		var tw = create_tween()
		tw.tween_property(hp_bar, "value", current, 0.25)
		hp_bar.add_theme_stylebox_override("fill", _panel_style(col, Color(0,0,0,0), 0, 0))
		if hp_lbl and is_instance_valid(hp_lbl):
			var pct = int(current * 100.0 / max_val) if max_val > 0.0 else 0
			hp_lbl.text = str(pct) + "%"
			hp_lbl.add_theme_color_override("font_color", col)

func _on_ultimate_ready(card: Control, char_id: String = "") -> void:
	if card and is_instance_valid(card):
		_set_card_ready_state(card)
		if AudioManager and AudioManager.has_method("play_sfx"):
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


# ═══════════════════════════════════════════════════════════════════
# 進度條
# ═══════════════════════════════════════════════════════════════════
func update_progress(ratio: float) -> void:
	_progress_target = clampf(ratio, 0.0, 1.0) * 100.0
	if progress_label:
		progress_label.text = "進度 " + str(int(ratio * 100)) + "%"


# ═══════════════════════════════════════════════════════════════════
# 每幀
# ═══════════════════════════════════════════════════════════════════
func _process(delta: float) -> void:
	_pulse_timer += delta

	# 進度條平滑填充
	if progress_bar and is_instance_valid(progress_bar):
		var v = progress_bar.value
		if absf(v - _progress_target) > 0.5:
			progress_bar.value = lerpf(v, _progress_target, clampf(delta * 6.0, 0.0, 1.0))
		else:
			progress_bar.value = _progress_target

	# 每卡 CD / 就緒脈動
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
		var m = _meta_for(card)
		if m.is_empty():
			continue

		if not member.is_ultimate_ready:
			_set_card_cd_state(card, member.get_cd_remaining())
		else:
			# 就緒：邊框綠色脈動（1.2s 週期）
			var pulse = (sin(_pulse_timer * TAU / 1.2) + 1.0) * 0.5
			if m.border:
				var gr = 0.15 + pulse * 0.12
				var gg = 0.78 + pulse * 0.18
				var gb = 0.32 + pulse * 0.06
				var bw = 2 + int(round(pulse * 2.0))
				m.border.add_theme_stylebox_override("panel", _border_only_style(Color(gr, gg, gb, 1.0), bw, 12))

	# 預警 Toast 倒計時
	if _recon_toast and _recon_toast.visible:
		_recon_toast_timer -= delta
		if _recon_toast_timer <= 0.0:
			var tw = create_tween()
			tw.tween_property(_recon_toast, "modulate:a", 0.0, 0.3)
			tw.tween_callback(func():
				if is_instance_valid(_recon_toast):
					_recon_toast.visible = false
			)
			_recon_toast_timer = 999.0  # 防止重複觸發


# ═══════════════════════════════════════════════════════════════════
# 結算面板
# ═══════════════════════════════════════════════════════════════════
func _style_result_panel() -> void:
	if game_result_panel:
		game_result_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.08, 0.11, 0.98), COL_ORANGE, 3, 18))
	if result_label:
		result_label.add_theme_color_override("font_color", COL_TEXT)
	if result_desc:
		result_desc.add_theme_color_override("font_color", COL_TEXT_DIM)
	if retry_btn:
		retry_btn.add_theme_font_size_override("font_size", 26)
		_apply_button_skin(retry_btn, COL_PANEL_HI, COL_ORANGE)
	if restart_btn:
		restart_btn.add_theme_font_size_override("font_size", 26)
		_apply_button_skin(restart_btn, COL_PANEL_HI, COL_GREEN)

func _restore_time_scale() -> void:
	Engine.time_scale = 1.0

func _on_game_won() -> void:
	var story_script = load("res://scripts/story_panel.gd")
	if story_script:
		var story = CanvasLayer.new()
		story.set_script(story_script)
		get_tree().root.add_child(story)
		story.show_story(
			GameManager.current_mission_id,
			func(): _show_victory_panel()
		)
	else:
		_show_victory_panel()

func _show_victory_panel() -> void:
	_restore_time_scale()
	if AudioManager:
		AudioManager.play_sfx("victory_sting")
	game_result_panel.show()
	var mission_name: String = GameManager.current_mission_data.get("name", "任務完成")
	result_label.text = mission_name + " 完成！"
	result_label.modulate = Color(0.3, 1.0, 0.4)
	AudioManager.play_sfx("victory")
	var mission_data = GameManager.current_mission_data
	var reward_coins: int = mission_data.get("reward_coins", 200)
	var reward_gold: int = mission_data.get("reward_gold_tickets", 0)
	var reward_blue: int = mission_data.get("reward_blue_tickets", 0)
	SaveManager.add_coins(reward_coins)
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
	if retry_btn:
		retry_btn.visible = false
	if restart_btn:
		restart_btn.text = "返回基地"
		restart_btn.visible = true
	var tween = create_tween()
	tween.tween_method(_update_coin_display, 0, reward_coins, 1.5)
	var final_ticket_text = ticket_text
	var final_coins = reward_coins
	tween.tween_callback(func():
		if result_desc and is_instance_valid(result_desc):
			result_desc.text = "小隊成功完成任務！\n獲得 " + str(final_coins) + " 金幣" + final_ticket_text + "！"
	)

func _on_game_lost() -> void:
	_restore_time_scale()
	AudioManager.play_sfx("defeat")
	SaveManager.add_coins(30)
	SaveManager.save_game()
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(game_result_panel):
		return
	game_result_panel.show()
	result_label.text = "任務失敗"
	result_label.modulate = Color(0.8, 0.1, 0.1)
	result_desc.text = "小隊無法完成任務。\n獲得安慰獎勵 30 金幣，繼續努力！"
	if retry_btn:
		retry_btn.text = "重試任務"
		retry_btn.visible = true
	if restart_btn:
		restart_btn.text = "返回基地"
		restart_btn.visible = true

func _on_retry_pressed() -> void:
	_restore_time_scale()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_restart_pressed() -> void:
	_restore_time_scale()
	get_tree().change_scene_to_file("res://scenes/Base.tscn")

func _update_coin_display(coins_shown: int) -> void:
	if result_desc and is_instance_valid(result_desc):
		result_desc.text = "小隊成功完成任務！\n獲得金幣：" + str(coins_shown)
