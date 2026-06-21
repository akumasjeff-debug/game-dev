extends Node2D

# 基地場景腳本
# 功能：任務板、陣容選擇、出發、離線金幣彈窗

# ─── 節點引用（在 _ready 中取得）───
var coins_label: Label
var stamina_label: Label
var squad_slots: Array = []        # 4 個 Button，代表已選陣容
var class_buttons: Array = []      # 6 個職業選擇按鈕
var offline_popup: Panel
var offline_msg_label: Label
var offline_confirm_btn: Button
var mission_buttons: Array = []    # 任務板按鈕
var _mission_cards: Array = []     # 任務卡片節點（Panel 容器）
var ticket_label: Label

# 放置橫帶
var _idle_banner_node: Control = null
var _idle_chars: Array = []      # 4 個角色的小圖示節點
var _idle_enemies: Array = []    # 當前波次的敵人節點
var _idle_bullets: Array = []    # 飛行中的子彈
var _idle_wave_timer: float = 0.0
var _idle_wave_interval: float = 6.0
var _idle_bg_offset: float = 0.0  # 背景捲動偏移

# 放置橫帶 SVG 路徑
const IDLE_CHAR_SPRITES: Array[String] = [
	"res://resources/art/sprites/side/side_shield.svg",
	"res://resources/art/sprites/side/side_assault.svg",
	"res://resources/art/sprites/side/side_demo.svg",
	"res://resources/art/sprites/side/side_medic.svg",
]
const IDLE_ENEMY_SPRITES: Array[String] = [
	"res://resources/art/sprites/side/side_grunt.svg",
	"res://resources/art/sprites/side/side_elite.svg",
]

# 職業清單（6 個，對應 characters.json id）
const ALL_CLASSES: Array = [
	{"id": "shield",  "name": "盾兵",  "color": Color(1.0, 0.55, 0.0)},
	{"id": "medic",   "name": "醫療兵","color": Color(1.0, 1.0, 1.0)},
	{"id": "assault", "name": "突擊手","color": Color(1.0, 0.13, 0.13)},
	{"id": "sniper",  "name": "狙擊手","color": Color(0.27, 1.0, 0.27)},
	{"id": "demo",    "name": "爆破手","color": Color(1.0, 0.87, 0.0)},
	{"id": "recon",   "name": "偵察手","color": Color(0.0, 0.8, 1.0)},
]

# 預設任務（GameManager 尚未載入時的後備）
const FALLBACK_MISSION: Dictionary = {
	"id": "demo_01",
	"name": "辦公大樓清查",
	"difficulty": 2,
	"reward_coins": 200,
	"reward_gold_tickets": 1,
	"reward_blue_tickets": 0,
	"description": "情報顯示敵軍盤踞於廢棄辦公大樓，小隊需逐層清查並消滅指揮官。",
	"tags": ["DEMO"],
}

# 選中的任務 ID（預設為第一個）
var selected_mission_id: String = "demo_01"

# 待執行的任務資料（在 _on_launch_pressed 存入，_start_mission 讀取）
var _pending_mission: Dictionary = {}

func _ready() -> void:
	_build_ui()
	_load_state()
	_show_offline_reward()

func _process(delta: float) -> void:
	_update_idle_banner(delta)

func _build_ui() -> void:
	# 背景
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.06, 0.08, 0.06)
	add_child(bg)

	# ── 頂部標題列 ──
	_add_top_bar()

	# ── 任務板 ──
	_add_mission_board()

	# ── 陣容選擇區 ──
	_add_squad_panel()

	# ── 出發按鈕 ──
	_add_launch_button()

	# ── 招募中心按鈕 ──
	_add_gacha_button()

	# ── 升級管理按鈕 ──
	_add_upgrade_button()

	# ── 出擊陣容展示（只讀卡片，底部）──
	_add_squad_card_display()

	# ── 放置橫帶（任務板與陣容選擇之間）──
	_create_idle_banner()

	# ── 離線金幣彈窗（預設隱藏）──
	_add_offline_popup()

func _add_top_bar() -> void:
	var top = Control.new()
	top.anchor_right = 1.0
	top.custom_minimum_size = Vector2(0, 100)
	add_child(top)

	var top_bg = ColorRect.new()
	top_bg.anchor_right = 1.0
	top_bg.anchor_bottom = 1.0
	top_bg.color = Color(0.05, 0.06, 0.05, 0.95)
	top.add_child(top_bg)

	var title = Label.new()
	title.text = "幽靈行動 — 基地"
	title.position = Vector2(30, 20)
	title.add_theme_font_size_override("font_size", 36)
	title.modulate = Color(0.9, 0.9, 0.7)
	top.add_child(title)

	coins_label = Label.new()
	coins_label.position = Vector2(580, 10)
	coins_label.add_theme_font_size_override("font_size", 28)
	coins_label.modulate = Color(1.0, 0.9, 0.3)
	coins_label.name = "CoinsLabel"
	top.add_child(coins_label)

	ticket_label = Label.new()
	ticket_label.position = Vector2(580, 48)
	ticket_label.add_theme_font_size_override("font_size", 24)
	ticket_label.modulate = Color(0.6, 0.8, 1.0)
	ticket_label.name = "TicketLabel"
	top.add_child(ticket_label)

	stamina_label = Label.new()
	stamina_label.position = Vector2(580, 80)
	stamina_label.add_theme_font_size_override("font_size", 22)
	stamina_label.modulate = Color(0.4, 1.0, 0.6)
	stamina_label.name = "StaminaLabel"
	top.add_child(stamina_label)

func _add_mission_board() -> void:
	# 區塊標題
	var section_lbl = Label.new()
	section_lbl.text = "任務板"
	section_lbl.position = Vector2(30, 116)
	section_lbl.add_theme_font_size_override("font_size", 30)
	section_lbl.modulate = Color(0.8, 1.0, 0.8)
	add_child(section_lbl)

	# 分隔線
	var sep = ColorRect.new()
	sep.position = Vector2(30, 158)
	sep.size = Vector2(1020, 2)
	sep.color = Color(0.3, 0.5, 0.3, 0.7)
	add_child(sep)

	# 取得任務資料（從 GameManager，否則用預設值）
	var missions: Array = _get_missions_list()

	# 最多顯示 3 個任務卡片，高度 175px，間距 16px
	var y_offset: float = 168.0
	var show_count: int = mini(missions.size(), 3)
	for i in range(show_count):
		var card = _create_mission_card(missions[i], y_offset)
		card.name = "MissionCard_" + missions[i].get("id", str(i))
		add_child(card)
		_mission_cards.append(card)
		y_offset += 191.0

	# 預設選中第一個任務並更新視覺
	if missions.size() > 0:
		selected_mission_id = missions[0].get("id", "demo_01")
		_update_mission_selection_visual(selected_mission_id)

func _get_missions_list() -> Array:
	var gm = get_node_or_null("/root/GameManager")
	if gm != null and gm.missions_data.size() > 0:
		return gm.missions_data
	return [FALLBACK_MISSION]

func _create_mission_card(mission: Dictionary, y: float) -> Control:
	var card = Control.new()
	card.position = Vector2(30, y)
	card.custom_minimum_size = Vector2(1020, 175)

	# 可點擊的整體按鈕區（覆蓋整張卡片）
	var hit_btn = Button.new()
	hit_btn.size = Vector2(1020, 175)
	hit_btn.flat = true
	hit_btn.name = "HitBtn"
	var mission_id = mission.get("id", "demo_01")
	hit_btn.pressed.connect(_select_mission.bind(mission_id))
	card.add_child(hit_btn)

	# 卡片背景
	var bg = ColorRect.new()
	bg.size = Vector2(1020, 175)
	bg.color = Color(0.08, 0.12, 0.08)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(bg)

	# 邊框（StyleBoxFlat 套在 Panel 上，初始灰色）
	var frame = Panel.new()
	frame.size = Vector2(1020, 175)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.name = "Frame"
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	frame_style.border_color = Color(0.35, 0.35, 0.35, 0.8)
	frame_style.set_border_width_all(3)
	frame_style.set_corner_radius_all(4)
	frame.add_theme_stylebox_override("panel", frame_style)
	card.add_child(frame)

	# 左側色條（難度色）
	var diff_val: int = mission.get("difficulty", 1)
	var bar_color = _difficulty_color(diff_val)
	var border_bar = ColorRect.new()
	border_bar.position = Vector2(0, 0)
	border_bar.size = Vector2(8, 175)
	border_bar.color = bar_color
	border_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(border_bar)

	# 標籤：任務類型
	var tags: Array = mission.get("tags", [])
	var tag_text: String = "[主線]" if "MAIN" in tags or tags.is_empty() else "[" + tags[0] + "]"
	if "DEMO" in tags:
		tag_text = "[DEMO]"
	var type_lbl = Label.new()
	type_lbl.text = tag_text
	type_lbl.position = Vector2(22, 8)
	type_lbl.add_theme_font_size_override("font_size", 20)
	type_lbl.modulate = Color(0.9, 0.7, 0.3)
	type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(type_lbl)

	# 任務名稱（大字）
	var title_lbl = Label.new()
	title_lbl.text = mission.get("name", "未知任務")
	title_lbl.position = Vector2(22, 36)
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.modulate = Color.WHITE
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title_lbl)

	# 難度星號
	var diff_lbl = Label.new()
	diff_lbl.text = "難度：" + "★".repeat(diff_val) + "☆".repeat(maxi(0, 5 - diff_val))
	diff_lbl.position = Vector2(22, 78)
	diff_lbl.add_theme_font_size_override("font_size", 22)
	diff_lbl.modulate = bar_color
	diff_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(diff_lbl)

	# 任務說明（截斷）
	var desc_lbl = Label.new()
	desc_lbl.text = mission.get("description", "")
	desc_lbl.position = Vector2(22, 110)
	desc_lbl.add_theme_font_size_override("font_size", 18)
	desc_lbl.modulate = Color(0.7, 0.7, 0.7)
	desc_lbl.custom_minimum_size = Vector2(650, 0)
	desc_lbl.clip_text = true
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(desc_lbl)

	# 右側獎勵區塊
	var reward_coins = mission.get("reward_coins", 0)
	var reward_gold = mission.get("reward_gold_tickets", 0)
	var reward_blue = mission.get("reward_blue_tickets", 0)

	var coins_lbl = Label.new()
	coins_lbl.text = str(reward_coins) + " 金幣"
	coins_lbl.position = Vector2(720, 28)
	coins_lbl.add_theme_font_size_override("font_size", 24)
	coins_lbl.modulate = Color(1.0, 0.9, 0.3)
	coins_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(coins_lbl)

	var tickets_lbl = Label.new()
	var ticket_parts: Array = []
	if reward_gold > 0:
		ticket_parts.append("金票 x" + str(reward_gold))
	if reward_blue > 0:
		ticket_parts.append("藍票 x" + str(reward_blue))
	tickets_lbl.text = " / ".join(ticket_parts) if ticket_parts.size() > 0 else "—"
	tickets_lbl.position = Vector2(720, 64)
	tickets_lbl.add_theme_font_size_override("font_size", 20)
	tickets_lbl.modulate = Color(0.6, 0.85, 1.0)
	tickets_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(tickets_lbl)

	return card

func _difficulty_color(diff: int) -> Color:
	match diff:
		1: return Color(0.4, 0.9, 0.4)   # 綠：簡單
		2: return Color(0.9, 0.7, 0.1)   # 橙：普通
		3: return Color(1.0, 0.4, 0.1)   # 橙紅：困難
		4: return Color(0.9, 0.1, 0.1)   # 紅：極難
		_: return Color(0.7, 0.2, 0.9)   # 紫：BOSS

func _select_mission(mission_id: String) -> void:
	AudioManager.play_sfx("btn_click")
	selected_mission_id = mission_id
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.set_mission(mission_id)
	_update_mission_selection_visual(mission_id)

func _update_mission_selection_visual(selected_id: String) -> void:
	for card in _mission_cards:
		if not is_instance_valid(card):
			continue
		var frame = card.get_node_or_null("Frame")
		if frame == null:
			continue
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		style.set_corner_radius_all(4)
		# 判斷是否為選中卡片（卡片 name = "MissionCard_" + id）
		var card_id = card.name.replace("MissionCard_", "")
		if card_id == selected_id:
			style.border_color = Color(1.0, 0.6, 0.1, 1.0)  # 橙色選中
			style.set_border_width_all(4)
		else:
			style.border_color = Color(0.35, 0.35, 0.35, 0.8)  # 灰色未選
			style.set_border_width_all(2)
		frame.add_theme_stylebox_override("panel", style)

func _add_squad_panel() -> void:
	var y_base: float = 950.0

	var section_lbl = Label.new()
	section_lbl.text = "陣容選擇（選 4 人）"
	section_lbl.position = Vector2(30, y_base)
	section_lbl.add_theme_font_size_override("font_size", 28)
	section_lbl.modulate = Color(0.8, 1.0, 0.8)
	add_child(section_lbl)

	var sep = ColorRect.new()
	sep.position = Vector2(30, y_base + 42)
	sep.size = Vector2(1020, 2)
	sep.color = Color(0.3, 0.5, 0.3, 0.7)
	add_child(sep)

	# ── 職業選擇按鈕（6 個）──
	var class_title = Label.new()
	class_title.text = "可用職業："
	class_title.position = Vector2(30, y_base + 54)
	class_title.add_theme_font_size_override("font_size", 22)
	class_title.modulate = Color(0.7, 0.7, 0.7)
	add_child(class_title)

	var btn_x: float = 30.0
	for i in range(ALL_CLASSES.size()):
		var cls = ALL_CLASSES[i]
		var btn = Button.new()
		btn.text = cls["name"]
		btn.position = Vector2(btn_x, y_base + 86)
		btn.custom_minimum_size = Vector2(163, 70)
		btn.add_theme_font_size_override("font_size", 22)
		btn.name = "ClassBtn_" + cls["id"]
		_style_button(btn, Color(0.12, 0.20, 0.28))
		btn.pressed.connect(_on_class_toggled.bind(cls["id"]))
		add_child(btn)
		class_buttons.append(btn)
		btn_x += 170.0

	# ── 已選陣容（4 個槽）──
	var slot_title = Label.new()
	slot_title.text = "出戰陣容："
	slot_title.position = Vector2(30, y_base + 172)
	slot_title.add_theme_font_size_override("font_size", 22)
	slot_title.modulate = Color(0.7, 0.7, 0.7)
	add_child(slot_title)

	for i in range(4):
		var slot_btn = Button.new()
		slot_btn.position = Vector2(30.0 + i * 260.0, y_base + 204)
		slot_btn.custom_minimum_size = Vector2(245, 80)
		slot_btn.add_theme_font_size_override("font_size", 24)
		slot_btn.name = "SlotBtn_" + str(i)
		_style_button(slot_btn, Color(0.10, 0.10, 0.15))
		slot_btn.pressed.connect(_on_slot_pressed.bind(i))
		add_child(slot_btn)
		squad_slots.append(slot_btn)

func _add_launch_button() -> void:
	var btn = Button.new()
	btn.text = "出發"
	btn.position = Vector2(90, 1460)
	btn.custom_minimum_size = Vector2(900, 120)
	btn.add_theme_font_size_override("font_size", 40)
	btn.name = "LaunchBtn"
	_style_button(btn, Color(0.6, 0.25, 0.0))
	btn.pressed.connect(_on_launch_pressed)
	add_child(btn)

func _add_gacha_button() -> void:
	var btn = Button.new()
	btn.text = "招募中心"
	btn.position = Vector2(90, 1600)
	btn.custom_minimum_size = Vector2(900, 110)
	btn.add_theme_font_size_override("font_size", 34)
	btn.name = "GachaBtn"
	_style_button(btn, Color(0.15, 0.10, 0.35))
	btn.pressed.connect(_open_gacha)
	add_child(btn)

func _add_upgrade_button() -> void:
	var btn = Button.new()
	btn.text = "升級管理"
	btn.position = Vector2(90, 1730)
	btn.custom_minimum_size = Vector2(900, 110)
	btn.add_theme_font_size_override("font_size", 34)
	btn.name = "UpgradeBtn"
	_style_button(btn, Color(0.10, 0.25, 0.15))
	btn.pressed.connect(_open_upgrade_panel)
	add_child(btn)

	# DEMO 重置按鈕（最底部，小型紅色）
	var reset_btn = Button.new()
	reset_btn.text = "[ DEMO ] 清空所有紀錄，重新開始"
	reset_btn.position = Vector2(90, 1855)
	reset_btn.custom_minimum_size = Vector2(900, 58)
	reset_btn.add_theme_font_size_override("font_size", 20)
	reset_btn.name = "DemoResetBtn"
	var rs = StyleBoxFlat.new()
	rs.bg_color = Color(0.20, 0.04, 0.04, 0.85)
	rs.border_color = Color(0.55, 0.15, 0.15, 0.8)
	rs.set_border_width_all(2)
	rs.set_corner_radius_all(5)
	reset_btn.add_theme_stylebox_override("normal", rs)
	var rh = StyleBoxFlat.new()
	rh.bg_color = Color(0.38, 0.08, 0.08)
	rh.border_color = Color(0.70, 0.25, 0.25)
	rh.set_border_width_all(2)
	rh.set_corner_radius_all(5)
	reset_btn.add_theme_stylebox_override("hover", rh)
	reset_btn.modulate = Color(1.0, 0.5, 0.5)
	reset_btn.pressed.connect(_on_demo_reset)
	add_child(reset_btn)

func _on_demo_reset() -> void:
	AudioManager.play_sfx("btn_click")
	# 確認對話框
	var dialog = AcceptDialog.new()
	dialog.title = "DEMO 重置"
	dialog.dialog_text = "確定要清空所有紀錄並重新開始？\n（此操作不可復原）"
	dialog.add_button("取消", true, "cancel")
	dialog.confirmed.connect(_do_demo_reset)
	get_tree().root.add_child(dialog)
	dialog.popup_centered()

func _do_demo_reset() -> void:
	SaveManager.reset_all()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _open_upgrade_panel() -> void:
	AudioManager.play_sfx("btn_click")
	var panel = load("res://scenes/UpgradePanel.tscn").instantiate()
	get_tree().root.add_child(panel)

func _add_squad_card_display() -> void:
	_build_squad_display()

func _build_squad_display() -> void:
	# 移除舊的陣容卡片區（如有）
	var old = get_node_or_null("SquadDisplay")
	if old:
		old.queue_free()

	# 讀取 cards.json
	var cards_data = _load_cards_json()

	# 讀取 selected_squad（統一 card_id 格式，如 "shield_r", "assault_sr"）
	var squad: Array = SaveManager.selected_squad
	if squad.is_empty():
		squad = ["shield_r", "assault_r", "medic_r", "sniper_r"]

	# 建立容器（陣容選擇下方）
	var container = Control.new()
	container.name = "SquadDisplay"
	container.position = Vector2(0, 1248)
	container.size = Vector2(1080, 195)
	add_child(container)

	# 深色底色
	var bg = ColorRect.new()
	bg.size = Vector2(1080, 195)
	bg.color = Color(0.05, 0.06, 0.08, 0.92)
	container.add_child(bg)

	# 頂部分隔線
	var sep = ColorRect.new()
	sep.size = Vector2(1080, 2)
	sep.color = Color(0.3, 0.4, 0.5, 0.7)
	container.add_child(sep)

	# 標題
	var title = Label.new()
	title.text = "出擊陣容"
	title.position = Vector2(20, 6)
	title.add_theme_font_size_override("font_size", 24)
	title.modulate = Color(0.9, 0.8, 0.4)
	container.add_child(title)

	# 陣容管理按鈕（右側）
	var mgr_btn = Button.new()
	mgr_btn.text = "陣容管理"
	mgr_btn.size = Vector2(160, 60)
	mgr_btn.position = Vector2(900, -8)
	mgr_btn.add_theme_font_size_override("font_size", 22)
	_style_button(mgr_btn, Color(0.15, 0.20, 0.30))
	mgr_btn.pressed.connect(_open_card_gallery)
	container.add_child(mgr_btn)

	# 4 張卡片
	var card_width: int = 100
	var card_height: int = 150
	var spacing: int = 16
	var total_width: int = card_width * 4 + spacing * 3
	var start_x: int = (1080 - total_width) / 2

	for i in range(4):
		# selected_squad 統一 card_id 格式，直接使用
		var card_id: String = squad[i] if i < squad.size() else ""
		var card_info: Dictionary = cards_data.get(card_id, {})

		var slot = _build_squad_card_slot(card_id, card_info, card_width, card_height)
		slot.position = Vector2(start_x + i * (card_width + spacing), 32)
		container.add_child(slot)

func _build_squad_card_slot(card_id: String, card_info: Dictionary, w: int, h: int) -> Control:
	var slot = Control.new()
	slot.size = Vector2(w, h)

	if card_id.is_empty() or card_info.is_empty():
		# 空槽
		var empty = ColorRect.new()
		empty.size = Vector2(w, h)
		empty.color = Color(0.1, 0.1, 0.15, 0.8)
		slot.add_child(empty)
		var empty_border = Panel.new()
		empty_border.size = Vector2(w, h)
		empty_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var eb_style = StyleBoxFlat.new()
		eb_style.bg_color = Color(0, 0, 0, 0)
		eb_style.border_color = Color(0.3, 0.3, 0.35, 0.6)
		eb_style.set_border_width_all(2)
		eb_style.set_corner_radius_all(4)
		empty_border.add_theme_stylebox_override("panel", eb_style)
		slot.add_child(empty_border)
		var plus_lbl = Label.new()
		plus_lbl.text = "空"
		plus_lbl.position = Vector2(w / 2 - 10, h / 2 - 10)
		plus_lbl.modulate = Color(0.4, 0.4, 0.4)
		slot.add_child(plus_lbl)
		return slot

	var grade: String = card_info.get("grade", "R")

	# 卡框背景（按稀有度嘗試載入 SVG，失敗則用色塊）
	var frame_path: String = "res://resources/art/cards/card_frame_%s.svg" % grade.to_lower()
	if ResourceLoader.exists(frame_path):
		var frame = TextureRect.new()
		frame.texture = load(frame_path)
		frame.size = Vector2(w, h)
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		slot.add_child(frame)
	else:
		var grade_colors: Dictionary = {
			"R": Color(0.08, 0.16, 0.28),
			"SR": Color(0.18, 0.08, 0.30),
			"SSR": Color(0.28, 0.22, 0.02),
			"QR": Color(0.35, 0.04, 0.02)
		}
		var bg_card = ColorRect.new()
		bg_card.size = Vector2(w, h)
		bg_card.color = grade_colors.get(grade, Color(0.1, 0.1, 0.15))
		slot.add_child(bg_card)
		# 稀有度色邊框
		var grade_border_colors: Dictionary = {
			"R": Color(0.27, 0.53, 0.80),
			"SR": Color(0.60, 0.40, 0.90),
			"SSR": Color(0.90, 0.72, 0.10),
			"QR": Color(0.90, 0.20, 0.10)
		}
		var border_panel = Panel.new()
		border_panel.size = Vector2(w, h)
		border_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bp_style = StyleBoxFlat.new()
		bp_style.bg_color = Color(0, 0, 0, 0)
		bp_style.border_color = grade_border_colors.get(grade, Color(0.3, 0.3, 0.35))
		bp_style.set_border_width_all(3)
		bp_style.set_corner_radius_all(4)
		border_panel.add_theme_stylebox_override("panel", bp_style)
		slot.add_child(border_panel)

	# 角色肖像
	var portrait_path: String = card_info.get("portrait_path", "")
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		var portrait = TextureRect.new()
		portrait.texture = load(portrait_path)
		portrait.size = Vector2(w, h - 30)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.add_child(portrait)

	# 卡片名稱（上方小字）
	var name_lbl = Label.new()
	name_lbl.text = card_info.get("name", "")
	name_lbl.position = Vector2(2, 2)
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.modulate = Color(1.0, 1.0, 0.9)
	slot.add_child(name_lbl)

	# 等級標籤（從 SaveManager 讀，若無 get_card_level 方法則顯示 Lv.1）
	var lv: int = 1
	if SaveManager.has_method("get_card_level"):
		lv = SaveManager.get_card_level(card_id)
	var lv_label = Label.new()
	lv_label.text = "Lv.%d" % lv
	lv_label.position = Vector2(4, h - 28)
	lv_label.add_theme_font_size_override("font_size", 14)
	lv_label.modulate = Color.WHITE
	slot.add_child(lv_label)

	# 強化值（右下角）
	var plus: int = 0
	if SaveManager.has_method("get_card_plus"):
		plus = SaveManager.get_card_plus(card_id)
	if plus > 0:
		var plus_lbl = Label.new()
		plus_lbl.text = "+%d" % plus
		plus_lbl.position = Vector2(w - 28, h - 28)
		plus_lbl.add_theme_font_size_override("font_size", 14)
		plus_lbl.modulate = Color(1.0, 0.8, 0.2)
		slot.add_child(plus_lbl)

	return slot

func _load_cards_json() -> Dictionary:
	var path: String = "res://resources/data/cards.json"
	if not ResourceLoader.exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var raw = JSON.parse_string(file.get_as_text())
	file.close()
	if raw == null:
		return {}
	# cards.json 頂層是 {"cards": [...]}
	var cards_array: Array = []
	if raw is Dictionary and raw.has("cards") and raw["cards"] is Array:
		cards_array = raw["cards"]
	elif raw is Array:
		cards_array = raw
	else:
		return {}
	var result: Dictionary = {}
	for card in cards_array:
		if card is Dictionary and card.has("id"):
			result[card["id"]] = card
	return result

func _open_card_gallery() -> void:
	AudioManager.play_sfx("btn_click")
	var gallery = load("res://scripts/card_gallery.gd").new()
	add_child(gallery)
	gallery.gallery_closed.connect(_build_squad_display)

func _add_offline_popup() -> void:
	offline_popup = Panel.new()
	offline_popup.name = "OfflinePopup"
	# 置中在畫面上
	offline_popup.position = Vector2(190, 700)
	offline_popup.size = Vector2(700, 300)
	offline_popup.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.10, 0.05, 0.97)
	style.border_color = Color(0.4, 0.8, 0.4, 0.9)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	offline_popup.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(30, 30)
	vbox.custom_minimum_size = Vector2(640, 240)
	vbox.add_theme_constant_override("separation", 16)
	offline_popup.add_child(vbox)

	var title = Label.new()
	title.text = "離線獎勵"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(0.9, 1.0, 0.5)
	vbox.add_child(title)

	offline_msg_label = Label.new()
	offline_msg_label.name = "OfflineMsg"
	offline_msg_label.text = ""
	offline_msg_label.add_theme_font_size_override("font_size", 22)
	offline_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offline_msg_label.modulate = Color(1.0, 1.0, 0.8)
	offline_msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(offline_msg_label)

	offline_confirm_btn = Button.new()
	offline_confirm_btn.text = "收下，繼續"
	offline_confirm_btn.custom_minimum_size = Vector2(0, 60)
	offline_confirm_btn.add_theme_font_size_override("font_size", 22)
	_style_button(offline_confirm_btn, Color(0.15, 0.40, 0.15))
	offline_confirm_btn.pressed.connect(_on_offline_confirmed)
	vbox.add_child(offline_confirm_btn)

	add_child(offline_popup)

# ─────────────────────────────────────────
#  狀態讀取與 UI 更新
# ─────────────────────────────────────────

func _load_state() -> void:
	_update_coins_display()
	_update_squad_display()
	_update_class_buttons()
	_update_ticket_display()
	_update_stamina_display()

func _update_coins_display() -> void:
	if coins_label:
		coins_label.text = "金幣：" + str(SaveManager.coins)

func _update_squad_display() -> void:
	var selected = SaveManager.selected_squad
	for i in range(4):
		var slot = squad_slots[i]
		if i < selected.size():
			# selected_squad 是 card_id 格式（如 "assault_r"），取底線前的部分得到 char_id
			var card_id = selected[i]
			var char_id = card_id.split("_")[0] if "_" in card_id else card_id
			var cls_data = _get_class_data(char_id)
			if cls_data:
				slot.text = cls_data["name"]
				slot.modulate = cls_data["color"]
			else:
				slot.text = "空"
				slot.modulate = Color(0.4, 0.4, 0.4)
		else:
			slot.text = "空"
			slot.modulate = Color(0.4, 0.4, 0.4)

func _update_class_buttons() -> void:
	var selected = SaveManager.selected_squad
	var owned = SaveManager.owned_characters
	for i in range(ALL_CLASSES.size()):
		var cls = ALL_CLASSES[i]
		var btn = class_buttons[i]
		var char_id = cls["id"]
		var is_owned = char_id in owned
		var rarity = SaveManager.character_rarity.get(char_id, 0)

		# 計算該職業在陣容中的出現次數（selected 是 card_id 格式，需解析 char_id）
		var count_in_squad: int = 0
		for sid in selected:
			var sid_char = sid.split("_")[0] if "_" in sid else sid
			if sid_char == char_id:
				count_in_squad += 1

		# 稀有度後綴
		var rarity_suffix = ""
		if rarity == 1:
			rarity_suffix = " [SR]"
		elif rarity >= 2:
			rarity_suffix = " [SSR]"

		# 計數後綴（×2 以上才顯示）
		var count_suffix = ""
		if count_in_squad >= 2:
			count_suffix = " ×" + str(count_in_squad)
		elif count_in_squad == 1:
			count_suffix = " ✓"

		if not is_owned:
			btn.disabled = true
			btn.modulate = Color(0.3, 0.3, 0.3)
			btn.text = cls["name"] + " [鎖定]"
			# 清除邊框樣式
			_style_button(btn, Color(0.12, 0.20, 0.28))
		elif count_in_squad > 0:
			btn.disabled = false
			btn.modulate = cls["color"]
			btn.text = cls["name"] + rarity_suffix + count_suffix
			# 選中且有稀有度 → 加邊框
			if rarity >= 2:
				_style_button_with_border(btn, Color(0.12, 0.20, 0.28), Color(1.0, 0.85, 0.2), 4)
			elif rarity == 1:
				_style_button_with_border(btn, Color(0.12, 0.20, 0.28), Color(0.82, 0.87, 1.0), 2)
			else:
				_style_button(btn, Color(0.12, 0.20, 0.28))
		else:
			btn.disabled = false
			var alpha = 0.7 if rarity == 0 else 1.0
			btn.modulate = Color(cls["color"].r, cls["color"].g, cls["color"].b, alpha)
			btn.text = cls["name"] + rarity_suffix
			if rarity >= 2:
				_style_button_with_border(btn, Color(0.12, 0.20, 0.28), Color(1.0, 0.85, 0.2), 4)
			elif rarity == 1:
				_style_button_with_border(btn, Color(0.12, 0.20, 0.28), Color(0.82, 0.87, 1.0), 2)
			else:
				_style_button(btn, Color(0.12, 0.20, 0.28))

func _get_class_data(char_id: String) -> Dictionary:
	for cls in ALL_CLASSES:
		if cls["id"] == char_id:
			return cls
	return {}

func _update_ticket_display() -> void:
	if ticket_label:
		ticket_label.text = "藍票：" + str(SaveManager.blue_tickets) + "  金票：" + str(SaveManager.gold_tickets)

func _update_stamina_display() -> void:
	if stamina_label:
		stamina_label.text = "體力：" + str(SaveManager.stamina) + "/" + str(SaveManager.max_stamina)

func _open_gacha() -> void:
	AudioManager.play_sfx("btn_click")
	var gacha_panel = load("res://scripts/gacha_panel.gd").new()
	get_tree().root.add_child(gacha_panel)
	gacha_panel.panel_closed.connect(_build_squad_display)

# ─────────────────────────────────────────
#  離線金幣
# ─────────────────────────────────────────

func _show_offline_reward() -> void:
	var result = SaveManager.calculate_offline_reward()
	if result["coins"] <= 0:
		return

	# 加入金幣（但不存檔，等玩家確認後一起存）
	var offline_coins: int = result["coins"]
	var elapsed_min: int = result["minutes"]

	var hours: int = elapsed_min / 60
	var mins: int = elapsed_min % 60
	var time_str: String
	if hours > 0:
		time_str = str(hours) + " 小時 " + str(mins) + " 分鐘"
	else:
		time_str = str(mins) + " 分鐘"

	offline_msg_label.text = "你離開了 " + time_str + "\n獲得 " + str(offline_coins) + " 金幣！"

	# 暫存，等確認後才加
	offline_popup.set_meta("pending_coins", offline_coins)
	offline_popup.visible = true

func _on_offline_confirmed() -> void:
	AudioManager.play_sfx("btn_click")
	var pending = offline_popup.get_meta("pending_coins", 0)
	if pending > 0:
		SaveManager.add_coins(pending)
		SaveManager.save_game()
		_update_coins_display()
	offline_popup.visible = false

# ─────────────────────────────────────────
#  任務選擇
# ─────────────────────────────────────────

func _on_mission_selected(mission_id: String, pressed_btn: Button) -> void:
	AudioManager.play_sfx("btn_click")
	selected_mission_id = mission_id
	# 重設所有任務按鈕樣式
	for btn in mission_buttons:
		_style_button(btn, Color(0.15, 0.35, 0.15))
		btn.text = "選擇任務"
	# 標記已選
	_style_button(pressed_btn, Color(0.4, 0.6, 0.1))
	pressed_btn.text = "已選取"

# ─────────────────────────────────────────
#  陣容操作
# ─────────────────────────────────────────

func _on_class_toggled(char_id: String) -> void:
	AudioManager.play_sfx("btn_click")
	var selected = SaveManager.selected_squad
	# 同職業可選多次：每次點擊都新增一個，達到上限（4人）則不新增
	# 若想移除，點擊下方陣容槽位即可
	if selected.size() >= 4:
		# 已滿 4 人：替換最後一個
		selected.pop_back()
	# 寫入 card_id 格式：依照 SaveManager 的 character_rarity 決定後綴
	var rarity: int = SaveManager.character_rarity.get(char_id, 0)
	var grade_suffix: String
	match rarity:
		0: grade_suffix = "r"
		1: grade_suffix = "sr"
		2: grade_suffix = "ssr"
		3: grade_suffix = "qr"
		_: grade_suffix = "r"
	selected.append(char_id + "_" + grade_suffix)
	SaveManager.selected_squad = selected
	_update_class_buttons()
	_update_squad_display()

func _on_slot_pressed(slot_index: int) -> void:
	AudioManager.play_sfx("btn_click")
	# 點擊槽位移除該角色
	var selected = SaveManager.selected_squad
	if slot_index < selected.size():
		selected.remove_at(slot_index)
		SaveManager.selected_squad = selected
		_update_class_buttons()
		_update_squad_display()

# ─────────────────────────────────────────
#  出發
# ─────────────────────────────────────────

func _on_launch_pressed() -> void:
	AudioManager.play_sfx("btn_click")
	if SaveManager.selected_squad.size() < 4:
		_show_error("請先選滿 4 名隊員！")
		return

	# 取得當前任務資料，存入實例變數供後續使用
	var gm = get_node_or_null("/root/GameManager")
	if gm != null and not gm.current_mission_data.is_empty():
		_pending_mission = gm.current_mission_data
	else:
		_pending_mission = FALLBACK_MISSION
	_show_mission_confirm_panel(_pending_mission)

func _show_mission_confirm_panel(mission: Dictionary) -> void:
	# 半透明遮罩（直接掛在場景根節點，確保在最上層）
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.size = Vector2(1080, 1920)
	overlay.position = Vector2.ZERO
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	# 面板容器
	var panel = PanelContainer.new()
	panel.size = Vector2(700, 520)
	panel.position = Vector2(190, 620)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.09, 0.06, 0.98)
	panel_style.border_color = Color(0.5, 0.75, 0.3, 0.9)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", panel_style)
	overlay.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 22)
	panel.add_child(vbox)

	# 標題
	var header = Label.new()
	header.text = "出擊確認"
	header.add_theme_font_size_override("font_size", 24)
	header.modulate = Color(0.7, 1.0, 0.7)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	# 分隔線
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 2)
	sep.color = Color(0.3, 0.5, 0.3, 0.6)
	vbox.add_child(sep)

	# 任務名稱
	var title = Label.new()
	title.text = mission.get("name", "任務")
	title.add_theme_font_size_override("font_size", 32)
	title.modulate = Color(1.0, 0.85, 0.3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# 難度星級（最多 5 星，與任務卡一致）
	var diff: int = mission.get("difficulty", 1)
	var filled: int = clampi(diff, 0, 5)
	var star_text: String = "★".repeat(filled) + "☆".repeat(maxi(0, 5 - filled))
	var diff_label = Label.new()
	diff_label.text = "難度：" + star_text
	diff_label.add_theme_font_size_override("font_size", 26)
	diff_label.modulate = _difficulty_color(diff)
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(diff_label)

	# 獎勵預覽
	var coins: int = mission.get("reward_coins", 0)
	var gold_t: int = mission.get("reward_gold_tickets", 0)
	var blue_t: int = mission.get("reward_blue_tickets", 0)
	var reward_str: String = "完成獎勵：" + str(coins) + " 金幣"
	if gold_t > 0:
		reward_str += "　金票 ×" + str(gold_t)
	if blue_t > 0:
		reward_str += "　藍票 ×" + str(blue_t)
	var reward_label = Label.new()
	reward_label.text = reward_str
	reward_label.add_theme_font_size_override("font_size", 22)
	reward_label.modulate = Color(1.0, 0.95, 0.6)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(reward_label)

	# 體力提示
	var stamina_hint = Label.new()
	stamina_hint.text = "消耗體力：1"
	stamina_hint.add_theme_font_size_override("font_size", 18)
	stamina_hint.modulate = Color(0.5, 0.9, 0.5)
	stamina_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stamina_hint)

	# 按鈕列
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 50)
	vbox.add_child(hbox)

	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(180, 65)
	cancel_btn.add_theme_font_size_override("font_size", 24)
	_style_button(cancel_btn, Color(0.25, 0.10, 0.10))
	cancel_btn.pressed.connect(overlay.queue_free)
	hbox.add_child(cancel_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "出擊！"
	confirm_btn.custom_minimum_size = Vector2(220, 65)
	confirm_btn.add_theme_font_size_override("font_size", 28)
	_style_button(confirm_btn, Color(0.55, 0.25, 0.0))
	confirm_btn.modulate = Color(1.0, 0.85, 0.5)
	confirm_btn.pressed.connect(func():
		overlay.queue_free()
		_start_mission()
	)
	hbox.add_child(confirm_btn)

func _start_mission() -> void:
	# selected_mission_id 由玩家在任務板點選後設定，此處保留玩家選擇

	# 存檔（包含當前陣容選擇）
	SaveManager.save_game()

	# 重設 GameManager 狀態（避免上一局殘留）
	GameManager.is_paused = false
	GameManager.is_game_over = false
	GameManager.squad_members.clear()
	GameManager.progress = 0.0
	GameManager.shield_buff_active = false
	GameManager.assault_buff_active = false
	GameManager.sniper_marked_target = null
	GameManager.sniper_mark_pending = false
	GameManager.demo_bomb_pending = false

	# Bug3: 存入選擇的任務 ID 供 Main.gd 讀取
	GameManager.current_mission_id = selected_mission_id

	# 消耗體力
	if not SaveManager.spend_stamina():
		_show_error("體力不足！稍後再試。")
		return
	_update_stamina_display()

	# 打開陣容確認面板（setup 必須在 add_child 之前呼叫，確保 _ready() 執行時資料已就緒）
	var confirm_panel = load("res://scenes/SquadConfirmPanel.tscn").instantiate()
	if confirm_panel.has_method("setup"):
		confirm_panel.setup(_pending_mission, SaveManager.selected_squad.duplicate())
	get_tree().root.add_child(confirm_panel)

func _show_error(msg: String) -> void:
	# 短暫顯示錯誤訊息（複用 offline_msg_label 邏輯，用獨立 label）
	var err_lbl = get_node_or_null("ErrorLabel")
	if err_lbl == null:
		err_lbl = Label.new()
		err_lbl.name = "ErrorLabel"
		err_lbl.position = Vector2(90, 1410)
		err_lbl.add_theme_font_size_override("font_size", 22)
		err_lbl.modulate = Color(1.0, 0.3, 0.3)
		add_child(err_lbl)
	err_lbl.text = msg
	# 2 秒後自動清空
	get_tree().create_timer(2.0).timeout.connect(func(): if is_instance_valid(err_lbl): err_lbl.text = "")

# ─────────────────────────────────────────
#  放置橫帶
# ─────────────────────────────────────────

func _create_idle_banner() -> void:
	_idle_banner_node = Control.new()
	_idle_banner_node.position = Vector2(0, 742)
	_idle_banner_node.size = Vector2(1080, 200)
	_idle_banner_node.clip_children = 1  # CLIP_CHILDREN_ENABLED
	add_child(_idle_banner_node)

	# 深色背景（室內走廊）
	var bg = ColorRect.new()
	bg.size = Vector2(1080, 200)
	bg.color = Color(0.06, 0.07, 0.10)
	_idle_banner_node.add_child(bg)

	# 地板線（側視角地板）
	var floor_line = ColorRect.new()
	floor_line.position = Vector2(0, 158)
	floor_line.size = Vector2(1080, 5)
	floor_line.color = Color(0.18, 0.20, 0.24)
	_idle_banner_node.add_child(floor_line)

	# 天花板線
	var ceil_line = ColorRect.new()
	ceil_line.position = Vector2(0, 18)
	ceil_line.size = Vector2(1080, 4)
	ceil_line.color = Color(0.12, 0.14, 0.18)
	_idle_banner_node.add_child(ceil_line)

	# 捲動背景柱子（裝飾）
	for i in range(6):
		var pillar = ColorRect.new()
		pillar.position = Vector2(i * 180, 22)
		pillar.size = Vector2(10, 136)
		pillar.color = Color(0.10, 0.12, 0.16)
		pillar.name = "Pillar_" + str(i)
		_idle_banner_node.add_child(pillar)

	# 右上角文字：累積速率
	var rate_lbl = Label.new()
	rate_lbl.position = Vector2(580, 4)
	rate_lbl.size = Vector2(494, 34)
	rate_lbl.text = "前線累積中：100 金幣/小時"
	rate_lbl.add_theme_font_size_override("font_size", 22)
	rate_lbl.modulate = Color(0.7, 0.8, 0.5)
	rate_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rate_lbl.name = "RateLabel"
	_idle_banner_node.add_child(rate_lbl)

	# 建立 4 個角色圖示（側視角）—— 優先使用 SVG，回退用 ColorRect
	var char_colors = [
		Color(0.2, 0.5, 1.0),    # 盾兵 藍
		Color(0.91, 0.38, 0.04), # 突擊手 橙
		Color(0.8, 0.13, 0.13),  # 爆破手 紅
		Color(0.3, 0.9, 0.3),    # 醫療兵 綠
	]
	for i in range(4):
		var char_node = Control.new()
		char_node.position = Vector2(80 + i * 70, 108)
		char_node.name = "IdleChar_" + str(i)

		if ResourceLoader.exists(IDLE_CHAR_SPRITES[i]):
			var tr = TextureRect.new()
			tr.texture = load(IDLE_CHAR_SPRITES[i])
			tr.size = Vector2(32, 48)
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			tr.name = "Body"
			char_node.add_child(tr)
		else:
			var body = ColorRect.new()
			body.size = Vector2(24, 36)
			body.color = char_colors[i]
			body.name = "Body"
			char_node.add_child(body)
			var head = ColorRect.new()
			head.size = Vector2(18, 18)
			head.position = Vector2(3, -18)
			head.color = Color(
				clamp(char_colors[i].r + 0.1, 0.0, 1.0),
				clamp(char_colors[i].g + 0.1, 0.0, 1.0),
				clamp(char_colors[i].b + 0.1, 0.0, 1.0)
			)
			char_node.add_child(head)

		_idle_banner_node.add_child(char_node)
		_idle_chars.append(char_node)

	# 木箱掩體裝飾（純視覺）
	var crate_path = "res://resources/art/sprites/side/side_cover_crate.svg"
	if ResourceLoader.exists(crate_path):
		for ci in range(2):
			var crate = TextureRect.new()
			crate.texture = load(crate_path)
			crate.size = Vector2(44, 34)
			crate.stretch_mode = TextureRect.STRETCH_SCALE
			crate.position = Vector2(280 + ci * 170, 124)
			_idle_banner_node.add_child(crate)

	# 開始第一波（1 秒後）
	_idle_wave_timer = 1.0

func _update_idle_banner(delta: float) -> void:
	if not _idle_banner_node or not is_instance_valid(_idle_banner_node):
		return

	# 捲動背景柱子（向左）
	_idle_bg_offset -= delta * 40.0
	if _idle_bg_offset < -180.0:
		_idle_bg_offset += 180.0
	for i in range(6):
		var pillar = _idle_banner_node.find_child("Pillar_" + str(i), false, false)
		if pillar:
			pillar.position.x = i * 180 + _idle_bg_offset

	# 角色走路動畫（上下輕微彈跳）
	for i in range(_idle_chars.size()):
		var ch = _idle_chars[i]
		if ch and is_instance_valid(ch):
			var bob = sin(Time.get_ticks_msec() * 0.005 + i * 1.0) * 2.0
			ch.position.y = 110 + bob

	# 子彈移動
	var bullets_to_remove: Array = []
	for b in _idle_bullets:
		if not b or not is_instance_valid(b):
			bullets_to_remove.append(b)
			continue
		b.position.x += delta * 350.0
		if b.position.x > 1100:
			bullets_to_remove.append(b)
	for b in bullets_to_remove:
		_idle_bullets.erase(b)
		if b and is_instance_valid(b):
			b.queue_free()

	# 敵人移動（向左走）
	var enemies_dead: Array = []
	for e in _idle_enemies:
		if not e or not is_instance_valid(e):
			enemies_dead.append(e)
			continue
		e.position.x -= delta * 60.0
		# 敵人抵達角色陣線（x < 330）→ 消滅並飄出金幣
		if e.position.x < 330:
			_spawn_coin_pop(e.position)
			enemies_dead.append(e)
	for e in enemies_dead:
		_idle_enemies.erase(e)
		if e and is_instance_valid(e):
			e.queue_free()

	# 波次計時器
	_idle_wave_timer -= delta
	if _idle_wave_timer <= 0.0:
		_idle_wave_timer = _idle_wave_interval
		_spawn_enemy_wave()
		_fire_idle_bullets()

func _spawn_enemy_wave() -> void:
	if not _idle_banner_node or not is_instance_valid(_idle_banner_node):
		return
	var count = randi_range(1, 3)
	for i in range(count):
		var enemy_node = Control.new()
		enemy_node.position = Vector2(1020 + i * 50, 110)

		var sprite_path = IDLE_ENEMY_SPRITES[randi_range(0, 1)]
		if ResourceLoader.exists(sprite_path):
			var tr = TextureRect.new()
			tr.texture = load(sprite_path)
			tr.size = Vector2(22, 32)
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			enemy_node.add_child(tr)
		else:
			var body = ColorRect.new()
			body.size = Vector2(22, 28)
			body.color = Color(0.75, 0.15, 0.15)
			enemy_node.add_child(body)
			var head = ColorRect.new()
			head.size = Vector2(16, 14)
			head.position = Vector2(3, -14)
			head.color = Color(0.55, 0.10, 0.10)
			enemy_node.add_child(head)

		_idle_banner_node.add_child(enemy_node)
		_idle_enemies.append(enemy_node)

func _fire_idle_bullets() -> void:
	if not _idle_banner_node or not is_instance_valid(_idle_banner_node):
		return
	for i in range(_idle_chars.size()):
		var ch = _idle_chars[i]
		if not ch or not is_instance_valid(ch):
			continue
		var bullet = ColorRect.new()
		bullet.size = Vector2(10, 5)
		bullet.position = Vector2(ch.position.x + 26, ch.position.y + 16)
		bullet.color = Color(1.0, 0.95, 0.3)
		_idle_banner_node.add_child(bullet)
		_idle_bullets.append(bullet)

func _spawn_coin_pop(pos: Vector2) -> void:
	var coin_lbl = Label.new()
	coin_lbl.text = "+金"
	coin_lbl.position = pos + Vector2(-10, -10)
	coin_lbl.add_theme_font_size_override("font_size", 20)
	coin_lbl.modulate = Color(1.0, 0.85, 0.0)
	_idle_banner_node.add_child(coin_lbl)
	var tween = create_tween()
	tween.tween_property(coin_lbl, "position:y", pos.y - 50, 0.8)
	tween.parallel().tween_property(coin_lbl, "modulate:a", 0.0, 0.8)
	tween.tween_callback(coin_lbl.queue_free)

# ─────────────────────────────────────────
#  通知 tree 退出（記錄退出時間）
# ─────────────────────────────────────────

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveManager.record_exit_time()

# ─────────────────────────────────────────
#  輔助：按鈕樣式
# ─────────────────────────────────────────

func _style_button(btn: Button, bg_color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = Color(bg_color.r + 0.2, bg_color.g + 0.2, bg_color.b + 0.2, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(bg_color.r + 0.1, bg_color.g + 0.1, bg_color.b + 0.1)
	hover_style.border_color = Color(bg_color.r + 0.3, bg_color.g + 0.3, bg_color.b + 0.3, 0.9)
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", hover_style)

func _style_button_with_border(btn: Button, bg_color: Color, border_color: Color, border_width: int) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(bg_color.r + 0.1, bg_color.g + 0.1, bg_color.b + 0.1)
	hover_style.border_color = border_color
	hover_style.set_border_width_all(border_width)
	hover_style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", hover_style)
