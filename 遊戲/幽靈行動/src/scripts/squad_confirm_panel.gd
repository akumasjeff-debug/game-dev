extends CanvasLayer

# 陣容確認面板 — 龍躐式（每個槽位上下切換角色）
# CanvasLayer layer=8

# 6 個角色完整資料（與 main.gd CHAR_DATA 同步）
const CHAR_DATA = [
	{"id": "shield",  "name": "盾兵",   "color": Color(0.2, 0.5, 1.0),   "max_hp": 200.0, "attack": 40.0,  "defense": 25.0, "ult_name": "防禦護盾", "ult_desc": "全隊受傷害降低 50%，持續 5 秒"},
	{"id": "medic",   "name": "醫療兵", "color": Color(0.3, 0.9, 0.3),   "max_hp": 160.0, "attack": 25.0,  "defense": 20.0, "ult_name": "緊急治療", "ult_desc": "全隊立即恢復 30% 最大 HP"},
	{"id": "assault", "name": "突擊手", "color": Color(0.91, 0.38, 0.04),"max_hp": 155.0, "attack": 60.0,  "defense": 15.0, "ult_name": "火力全開", "ult_desc": "全隊攻擊力提升 60%，持續 8 秒"},
	{"id": "sniper",  "name": "狙擊手", "color": Color(0.67, 0.27, 1.0), "max_hp": 110.0, "attack": 120.0, "defense": 10.0, "ult_name": "精準鎖定", "ult_desc": "目標 HP < 25% 瞬殺，否則 300% ATK 傷害"},
	{"id": "demo",    "name": "爆破手", "color": Color(0.8, 0.13, 0.13), "max_hp": 135.0, "attack": 80.0,  "defense": 18.0, "ult_name": "引爆炸彈", "ult_desc": "房間內所有敵人扣 70% HP"},
	{"id": "recon",   "name": "偵察手", "color": Color(0.0, 0.8, 1.0),   "max_hp": 140.0, "attack": 35.0,  "defense": 17.0, "ult_name": "煙霧封鎖", "ult_desc": "所有敵人攻擊失效 5 秒"},
]

# 每個槽位目前指向 CHAR_DATA 的哪個 index（只顯示 owned 角色）
var _slot_indices: Array = [0, 0, 0, 0]   # 4 個槽位的 owned_list index
var _owned_list: Array = []   # owned char_id 的有序列表
var _slot_panels: Array = []  # 4 個槽位的 Control 節點

func _ready() -> void:
	# 建立 owned list（順序依 CHAR_DATA 定義）
	for char in CHAR_DATA:
		if char["id"] in SaveManager.owned_characters:
			_owned_list.append(char["id"])

	# 從 SaveManager.selected_squad 推算初始 index
	var selected = SaveManager.selected_squad
	for i in range(4):
		if i < selected.size():
			var idx = _owned_list.find(selected[i])
			_slot_indices[i] = max(0, idx)
		else:
			_slot_indices[i] = i % _owned_list.size()

	_build_ui()

func _build_ui() -> void:
	# 全螢幕暗色遮罩
	var overlay = ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0.0, 0.0, 0.0, 0.88)
	add_child(overlay)

	# 標題
	var title = Label.new()
	title.text = "陣容確認"
	title.position = Vector2(0, 60)
	title.size = Vector2(1080, 60)
	title.add_theme_font_size_override("font_size", 38)
	title.modulate = Color(0.9, 0.9, 0.6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# 4 個角色槽（水平排列，每個 250×520px，間距 10px，整體 y=150 開始）
	var slot_w = 250.0
	var slot_h = 520.0
	var slot_spacing = 10.0
	var total_w = slot_w * 4 + slot_spacing * 3
	var start_x = (1080.0 - total_w) / 2.0
	var start_y = 140.0

	for i in range(4):
		var slot_panel = _create_slot_panel(i)
		slot_panel.position = Vector2(start_x + i * (slot_w + slot_spacing), start_y)
		add_child(slot_panel)
		_slot_panels.append(slot_panel)

	# 確認出發按鈕
	var confirm_btn = Button.new()
	confirm_btn.text = "確認出發"
	confirm_btn.position = Vector2(290, 780)
	confirm_btn.custom_minimum_size = Vector2(500, 90)
	confirm_btn.add_theme_font_size_override("font_size", 32)
	_style_btn(confirm_btn, Color(0.55, 0.22, 0.0))
	confirm_btn.pressed.connect(_on_confirm_pressed)
	add_child(confirm_btn)

	# 返回按鈕
	var back_btn = Button.new()
	back_btn.text = "返回"
	back_btn.position = Vector2(290, 890)
	back_btn.custom_minimum_size = Vector2(500, 60)
	back_btn.add_theme_font_size_override("font_size", 24)
	_style_btn(back_btn, Color(0.15, 0.15, 0.15))
	back_btn.pressed.connect(_on_back_pressed)
	add_child(back_btn)

func _create_slot_panel(slot_idx: int) -> Control:
	var panel = Control.new()
	panel.custom_minimum_size = Vector2(250, 520)
	panel.name = "SlotPanel_" + str(slot_idx)

	# 背景
	var bg = ColorRect.new()
	bg.size = Vector2(250, 520)
	bg.color = Color(0.07, 0.09, 0.12, 0.95)
	panel.add_child(bg)

	# 向上箭頭按鈕
	var up_btn = Button.new()
	up_btn.text = "▲"
	up_btn.position = Vector2(75, 5)
	up_btn.custom_minimum_size = Vector2(100, 44)
	up_btn.add_theme_font_size_override("font_size", 22)
	_style_btn(up_btn, Color(0.15, 0.25, 0.40))
	up_btn.pressed.connect(_cycle_slot.bind(slot_idx, -1))
	panel.add_child(up_btn)

	# Portrait 區（120×160，帶職業色背景）
	var portrait_bg = ColorRect.new()
	portrait_bg.position = Vector2(15, 60)
	portrait_bg.size = Vector2(220, 180)
	portrait_bg.name = "PortraitBG"
	panel.add_child(portrait_bg)

	var portrait_rect = TextureRect.new()
	portrait_rect.position = Vector2(15, 60)
	portrait_rect.size = Vector2(220, 180)
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.name = "PortraitRect"
	panel.add_child(portrait_rect)

	# 角色名（portrait 下方）
	var name_lbl = Label.new()
	name_lbl.position = Vector2(0, 248)
	name_lbl.size = Vector2(250, 40)
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.modulate = Color.WHITE
	name_lbl.name = "NameLabel"
	panel.add_child(name_lbl)

	# HP / ATK / DEF
	var stats_lbl = Label.new()
	stats_lbl.position = Vector2(10, 295)
	stats_lbl.size = Vector2(230, 80)
	stats_lbl.add_theme_font_size_override("font_size", 16)
	stats_lbl.modulate = Color(0.8, 0.9, 0.8)
	stats_lbl.name = "StatsLabel"
	panel.add_child(stats_lbl)

	# 大招名稱 + 說明
	var ult_lbl = Label.new()
	ult_lbl.position = Vector2(10, 385)
	ult_lbl.size = Vector2(230, 100)
	ult_lbl.add_theme_font_size_override("font_size", 14)
	ult_lbl.modulate = Color(0.5, 0.8, 1.0)
	ult_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	ult_lbl.name = "UltLabel"
	panel.add_child(ult_lbl)

	# 向下箭頭按鈕
	var down_btn = Button.new()
	down_btn.text = "▼"
	down_btn.position = Vector2(75, 473)
	down_btn.custom_minimum_size = Vector2(100, 44)
	down_btn.add_theme_font_size_override("font_size", 22)
	_style_btn(down_btn, Color(0.15, 0.25, 0.40))
	down_btn.pressed.connect(_cycle_slot.bind(slot_idx, 1))
	panel.add_child(down_btn)

	_refresh_slot_display(panel, slot_idx)
	return panel

func _cycle_slot(slot_idx: int, direction: int) -> void:
	if _owned_list.is_empty():
		return
	_slot_indices[slot_idx] = (_slot_indices[slot_idx] + direction) % _owned_list.size()
	if _slot_indices[slot_idx] < 0:
		_slot_indices[slot_idx] = _owned_list.size() - 1
	_refresh_slot_display(_slot_panels[slot_idx], slot_idx)

func _refresh_slot_display(panel: Control, slot_idx: int) -> void:
	if _owned_list.is_empty():
		return
	var char_id = _owned_list[_slot_indices[slot_idx]]
	var char_data = _get_char_data(char_id)
	if char_data.is_empty():
		return

	# 更新 portrait 背景色
	var portrait_bg = panel.find_child("PortraitBG", false, false) as ColorRect
	if portrait_bg:
		portrait_bg.color = Color(char_data["color"].r * 0.3, char_data["color"].g * 0.3, char_data["color"].b * 0.3, 1.0)

	# 更新 portrait 圖
	var portrait_rect = panel.find_child("PortraitRect", false, false) as TextureRect
	if portrait_rect:
		var path = "res://resources/art/portraits/" + char_id + "_portrait.svg"
		if ResourceLoader.exists(path):
			portrait_rect.texture = load(path)
		else:
			portrait_rect.texture = null

	# 稀有度等級乘率計算
	var rarity_mult = SaveManager.get_rarity_multiplier(char_id)
	var level_mult = SaveManager.get_level_multiplier(char_id)
	var total_mult = rarity_mult * level_mult
	var lv = SaveManager.character_levels.get(char_id, 1)

	# 名稱標籤
	var name_lbl = panel.find_child("NameLabel", false, false) as Label
	if name_lbl:
		var rarity = SaveManager.character_rarity.get(char_id, 0)
		var rarity_str = ["", " [SR]", " [SSR]"][rarity]
		name_lbl.text = char_data["name"] + rarity_str + "  Lv." + str(lv)
		name_lbl.modulate = char_data["color"]

	# 數值標籤
	var stats_lbl = panel.find_child("StatsLabel", false, false) as Label
	if stats_lbl:
		var hp = int(char_data["max_hp"] * total_mult)
		var atk = int(char_data["attack"] * total_mult)
		var def_val = int(char_data["defense"] * total_mult)
		stats_lbl.text = "HP  " + str(hp) + "\nATK " + str(atk) + "\nDEF " + str(def_val)

	# 大招標籤
	var ult_lbl = panel.find_child("UltLabel", false, false) as Label
	if ult_lbl:
		ult_lbl.text = "【" + char_data["ult_name"] + "】\n" + char_data["ult_desc"]

func _get_char_data(char_id: String) -> Dictionary:
	for ch in CHAR_DATA:
		if ch["id"] == char_id:
			return ch
	return {}

func _on_confirm_pressed() -> void:
	# 從 4 個槽位收集選擇（允許重複，但遊戲設計上應唯一）
	var new_squad: Array = []
	for i in range(4):
		if not _owned_list.is_empty():
			new_squad.append(_owned_list[_slot_indices[i]])
	SaveManager.selected_squad = new_squad
	SaveManager.save_game()

	# 播放任務開場動廊後進場
	_play_mission_intro()

func _play_mission_intro() -> void:
	# 任務開場：fade in 暗幕 + 任務標題，1.5 秒後換場景
	var intro_overlay = ColorRect.new()
	intro_overlay.size = Vector2(1080, 1920)  # CanvasLayer child 不支援 anchor preset，手動設尺寸
	intro_overlay.color = Color(0, 0, 0, 0)
	intro_overlay.z_index = 100
	add_child(intro_overlay)

	var mission_title_lbl = Label.new()
	mission_title_lbl.text = "任務：辦公大樓清查"
	mission_title_lbl.position = Vector2(0, 820)
	mission_title_lbl.size = Vector2(1080, 80)
	mission_title_lbl.add_theme_font_size_override("font_size", 36)
	mission_title_lbl.modulate = Color(0.9, 0.8, 0.3, 0)
	mission_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(mission_title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "小隊出發"
	sub_lbl.position = Vector2(0, 910)
	sub_lbl.size = Vector2(1080, 60)
	sub_lbl.add_theme_font_size_override("font_size", 24)
	sub_lbl.modulate = Color(0.7, 0.7, 0.7, 0)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub_lbl)

	# Tween 動畫
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(intro_overlay, "color", Color(0, 0, 0, 0.92), 0.6)
	tween.tween_property(mission_title_lbl, "modulate", Color(0.9, 0.8, 0.3, 1.0), 0.6)
	tween.tween_property(sub_lbl, "modulate", Color(0.7, 0.7, 0.7, 1.0), 0.8)
	tween.set_parallel(false)
	tween.tween_interval(0.9)
	tween.tween_callback(_launch_mission)

func _launch_mission() -> void:
	queue_free()  # 必須先移除自己，否則 root child 不隨場景切換消失
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_back_pressed() -> void:
	queue_free()

func _style_btn(btn: Button, bg: Color) -> void:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = Color(bg.r + 0.2, bg.g + 0.2, bg.b + 0.2, 0.8)
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", s)
	var h = StyleBoxFlat.new()
	h.bg_color = Color(bg.r + 0.12, bg.g + 0.12, bg.b + 0.12)
	h.border_color = Color(bg.r + 0.3, bg.g + 0.3, bg.b + 0.3)
	h.set_border_width_all(2)
	h.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("hover", h)
