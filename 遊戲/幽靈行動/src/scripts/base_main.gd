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
	{"name": "辦公室殲滅", "scene": "res://scenes/Main.tscn",   "type": "殲滅",    "enemies": 5,  "reward": 500},
	{"name": "倉庫暗殺",   "scene": "res://scenes/Level2.tscn", "type": "暗殺",    "enemies": 8,  "reward": 800},
	{"name": "醫院救援",   "scene": "res://scenes/Level3.tscn", "type": "救援",    "enemies": 8,  "reward": 700},
	{"name": "指揮中心防守","scene": "res://scenes/Level4.tscn", "type": "防守 60s","enemies": 10, "reward": 900},
	{"name": "造船廠最終", "scene": "res://scenes/Level5.tscn", "type": "最終殲滅","enemies": 12, "reward": 1200},
]

func _ready():
	_update_money_display()
	_build_level_cards()
	upgrade_btn.pressed.connect(_on_placeholder_btn)
	roster_btn.pressed.connect(_on_placeholder_btn)
	formation_btn.pressed.connect(_on_placeholder_btn)
	# 點畫面任意處關閉即將推出面板
	if coming_soon_panel:
		coming_soon_panel.gui_input.connect(_on_coming_soon_panel_input)

func _update_money_display():
	if money_label:
		money_label.text = "$" + str(GameData.total_money)

func _build_level_cards():
	# 清除舊卡片（防重複建立）
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

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	# 關卡序號
	var num_lbl = Label.new()
	num_lbl.text = "關卡 %d" % (idx + 1)
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.add_theme_font_size_override("font_size", 16)
	num_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 1))
	vbox.add_child(num_lbl)

	# 關卡名稱
	var name_lbl = Label.new()
	name_lbl.text = data["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)

	# 任務類型
	var type_lbl = Label.new()
	type_lbl.text = "類型：" + data["type"]
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 16)
	type_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7, 1))
	vbox.add_child(type_lbl)

	# 敵人數量
	var enemy_lbl = Label.new()
	enemy_lbl.text = "敵人：%d 名" % data["enemies"]
	enemy_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_lbl.add_theme_font_size_override("font_size", 16)
	enemy_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6, 1))
	vbox.add_child(enemy_lbl)

	# 獎勵
	var reward_lbl = Label.new()
	reward_lbl.text = "獎勵：$%d" % data["reward"]
	reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_lbl.add_theme_font_size_override("font_size", 18)
	reward_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1))
	vbox.add_child(reward_lbl)

	# 彈性空白
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# 出發按鈕
	var btn = Button.new()
	btn.text = "出發"
	btn.custom_minimum_size = Vector2(200, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 20)
	var scene_path = data["scene"]
	var level_name = data["name"]
	var reward_val = data["reward"]
	var enemies_val = data["enemies"]
	btn.pressed.connect(func():
		start_level(scene_path, level_name, reward_val, enemies_val)
	)
	vbox.add_child(btn)

	return card

func start_level(scene_path: String, level_name: String, reward: int, enemies: int):
	# 預先把本關資料寫入 GameData，讓 hud 的勝利也能正確帶過去
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
