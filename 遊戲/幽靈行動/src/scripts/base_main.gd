extends Control

# Base.tscn 主腳本 — 幽靈行動指揮中心（HQ）
# 改版：選關卡 → 出發 → 結算 → 回基地

@onready var money_label: Label = $Header/MoneyLabel
@onready var level_card_row: HBoxContainer = $LevelScrollContainer/LevelCardRow
@onready var upgrade_btn: Button = $BottomBar/UpgradeBtn
@onready var roster_btn: Button = $BottomBar/RosterBtn
@onready var formation_btn: Button = $BottomBar/FormationBtn
@onready var coming_soon_panel: Panel = $ComingSoonPanel

const LEVELS = [
	{"name": "辦公室殲滅", "scene": "res://scenes/Main.tscn",   "type": "[殲滅]",    "enemies": 5,  "reward": 500},
	{"name": "倉庫暗殺",   "scene": "res://scenes/Level2.tscn", "type": "[暗殺]",    "enemies": 8,  "reward": 800},
	{"name": "醫院救援",   "scene": "res://scenes/Level3.tscn", "type": "[救援]",    "enemies": 8,  "reward": 700},
	{"name": "指揮中心防守","scene": "res://scenes/Level4.tscn", "type": "[防守 60s]","enemies": 10, "reward": 900},
	{"name": "造船廠最終", "scene": "res://scenes/Level5.tscn", "type": "[最終殲滅]","enemies": 12, "reward": 1200},
]

# 軍事 HQ 色彩常數
const COL_BG         = Color(0.039, 0.059, 0.078, 1)   # #0a0f14
const COL_CARD_BG    = Color(0.075, 0.110, 0.145, 1)   # #131c25
const COL_ORANGE     = Color(1.0, 0.584, 0.0, 1)       # #ff9500
const COL_ORANGE_BTN = Color(1.0, 0.467, 0.0, 1)       # #ff7700
const COL_ORANGE_HOV = Color(0.8, 0.333, 0.0, 1)       # #cc5500
const COL_ORANGE_DIM = Color(1.0, 0.584, 0.0, 0.3)     # #ff9500 30%
const COL_GRAY_BORDER= Color(0.333, 0.376, 0.439, 1)   # #556070
const COL_PANEL_BG   = Color(0.102, 0.145, 0.208, 1)   # #1a2535
const COL_GREEN_LED  = Color(0.0, 1.0, 0.255, 1)       # #00ff41
const COL_WHITE      = Color(0.95, 0.95, 0.95, 1)
const COL_GRAY_SUB   = Color(0.55, 0.60, 0.60, 1)
const COL_SKULL      = Color(1.0, 0.37, 0.37, 1)
const COL_GOLD       = Color(1.0, 0.85, 0.2, 1)
const COL_TYPE_GREEN = Color(0.50, 0.75, 0.50, 1)

func _ready():
	_apply_military_style()
	_update_money_display()
	_build_level_cards()
	_style_bottom_buttons()
	_add_divider()
	upgrade_btn.pressed.connect(_on_placeholder_btn)
	roster_btn.pressed.connect(_on_placeholder_btn)
	formation_btn.pressed.connect(_on_placeholder_btn)
	if coming_soon_panel:
		coming_soon_panel.gui_input.connect(_on_coming_soon_panel_input)

# ─── 軍事 HQ 全域樣式 ────────────────────────────────────────────
func _apply_military_style():
	# 1. 背景改更深色
	var bg = $Background
	if bg:
		bg.color = COL_BG

	# 2. 標題區重建：加 LED 指示燈 + 主標題 + 副標題
	var header: Control = $Header
	if header:
		# 清掉現有的 TitleLabel，改用自製 HBox
		var old_title = header.get_node_or_null("TitleLabel")
		if old_title:
			old_title.queue_free()

		# 標題橫排容器（靠左對齊）
		var title_hbox = HBoxContainer.new()
		title_hbox.name = "TitleHBox"
		title_hbox.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		title_hbox.anchor_right = 0.5
		title_hbox.offset_left = 40
		title_hbox.add_theme_constant_override("separation", 10)
		header.add_child(title_hbox)

		# 綠色 LED 指示燈
		var led = ColorRect.new()
		led.custom_minimum_size = Vector2(8, 8)
		led.color = COL_GREEN_LED
		led.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		title_hbox.add_child(led)

		# VBox：主標 + 副標
		var title_vbox = VBoxContainer.new()
		title_vbox.add_theme_constant_override("separation", 2)
		title_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		title_hbox.add_child(title_vbox)

		var main_title = Label.new()
		main_title.text = "幽靈行動"
		main_title.add_theme_font_size_override("font_size", 36)
		main_title.add_theme_color_override("font_color", COL_WHITE)
		title_vbox.add_child(main_title)

		var sub_title = Label.new()
		sub_title.text = "指揮中心 // GHOST OPS HQ"
		sub_title.add_theme_font_size_override("font_size", 13)
		sub_title.add_theme_color_override("font_color", COL_GRAY_SUB)
		title_vbox.add_child(sub_title)

	# 3. 金錢 Label 改樣式
	if money_label:
		money_label.add_theme_font_size_override("font_size", 22)
		money_label.add_theme_color_override("font_color", COL_ORANGE)
		# 文字在 _update_money_display 更新

func _update_money_display():
	if money_label:
		money_label.text = "◈ FUNDS: " + str(GameData.total_money)

# ─── 關卡卡片 ────────────────────────────────────────────────────
func _build_level_cards():
	for child in level_card_row.get_children():
		child.queue_free()

	for i in LEVELS.size():
		var data = LEVELS[i]
		var card = _make_level_card(i, data)
		level_card_row.add_child(card)

func _make_level_card(idx: int, data: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(320, 400)
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# 卡片背景 + 橘色邊框
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = COL_CARD_BG
	card_style.border_color = Color(1.0, 0.58, 0.0, 0.6)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(4)
	card.add_theme_stylebox_override("panel", card_style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	# 關卡編號（橘黃大字，雙位數補零）
	var num_lbl = Label.new()
	num_lbl.text = "%02d" % (idx + 1)
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.add_theme_font_size_override("font_size", 42)
	num_lbl.add_theme_color_override("font_color", COL_ORANGE)
	vbox.add_child(num_lbl)

	# 關卡名稱
	var name_lbl = Label.new()
	name_lbl.text = data["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", COL_WHITE)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)

	# 任務類型（角括號包裹）
	var type_lbl = Label.new()
	type_lbl.text = data["type"]
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 15)
	type_lbl.add_theme_color_override("font_color", COL_TYPE_GREEN)
	vbox.add_child(type_lbl)

	# 敵人數量（骷髏圖示）
	var enemy_lbl = Label.new()
	enemy_lbl.text = "☠  %d" % data["enemies"]
	enemy_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_lbl.add_theme_font_size_override("font_size", 18)
	enemy_lbl.add_theme_color_override("font_color", COL_SKULL)
	vbox.add_child(enemy_lbl)

	# 獎勵（貨幣符號）
	var reward_lbl = Label.new()
	reward_lbl.text = "◈  %d" % data["reward"]
	reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_lbl.add_theme_font_size_override("font_size", 18)
	reward_lbl.add_theme_color_override("font_color", COL_GOLD)
	vbox.add_child(reward_lbl)

	# 彈性空白
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# 出發按鈕：橘色背景 + 懸停效果
	var btn = Button.new()
	btn.text = "▶  出發"
	btn.custom_minimum_size = Vector2(200, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", COL_WHITE)

	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = COL_ORANGE_BTN
	btn_normal.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", btn_normal)

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = COL_ORANGE_HOV
	btn_hover.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", btn_hover)

	var btn_pressed = StyleBoxFlat.new()
	btn_pressed.bg_color = COL_ORANGE_HOV
	btn_pressed.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("pressed", btn_pressed)

	var scene_path = data["scene"]
	var level_name = data["name"]
	var reward_val = data["reward"]
	var enemies_val = data["enemies"]
	btn.pressed.connect(func():
		start_level(scene_path, level_name, reward_val, enemies_val)
	)
	vbox.add_child(btn)

	return card

# ─── 底部按鈕 ─────────────────────────────────────────────────────
func _style_bottom_buttons():
	var buttons = [
		[upgrade_btn,  "⚙  升級裝備"],
		[roster_btn,   "👤 調整陣容"],
		[formation_btn,"⬡  選擇陣型"],
	]
	for pair in buttons:
		var b: Button = pair[0]
		var label: String = pair[1]
		if not b:
			continue
		b.text = label
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_color_override("font_color", COL_WHITE)

		var s_normal = StyleBoxFlat.new()
		s_normal.bg_color = COL_PANEL_BG
		s_normal.border_color = COL_GRAY_BORDER
		s_normal.set_border_width_all(2)
		s_normal.set_corner_radius_all(4)
		b.add_theme_stylebox_override("normal", s_normal)

		var s_hover = StyleBoxFlat.new()
		s_hover.bg_color = Color(0.15, 0.22, 0.32, 1)
		s_hover.border_color = COL_ORANGE
		s_hover.set_border_width_all(2)
		s_hover.set_corner_radius_all(4)
		b.add_theme_stylebox_override("hover", s_hover)

		var s_pressed = StyleBoxFlat.new()
		s_pressed.bg_color = COL_PANEL_BG
		s_pressed.border_color = COL_ORANGE
		s_pressed.set_border_width_all(2)
		s_pressed.set_corner_radius_all(4)
		b.add_theme_stylebox_override("pressed", s_pressed)

# ─── 分隔線（卡片區與底部按鈕之間）─────────────────────────────────
func _add_divider():
	var divider = ColorRect.new()
	divider.name = "Divider"
	divider.custom_minimum_size = Vector2(1920, 1)
	divider.color = Color(1.0, 0.584, 0.0, 0.3)   # #ff9500 alpha 30%

	# 插入在 LevelScrollContainer 之後（BottomBar 之前）
	add_child(divider)
	# 定位在底部按鈕上方
	divider.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	divider.offset_top = -111
	divider.offset_bottom = -110

# ─── 遊戲流程 ─────────────────────────────────────────────────────
func start_level(scene_path: String, level_name: String, reward: int, enemies: int):
	GameData.last_level_name = level_name
	GameData.last_level_reward = reward
	GameData.last_enemies_killed = enemies
	get_tree().change_scene_to_file(scene_path)

func _on_placeholder_btn():
	if coming_soon_panel:
		coming_soon_panel.visible = true

func _on_coming_soon_panel_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		coming_soon_panel.visible = false
