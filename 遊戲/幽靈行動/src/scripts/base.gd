extends Node2D

# 基地場景腳本
# 功能：任務板、陣容選擇、出發、離線金幣彈窗

# ─── 節點引用（在 _ready 中取得）───
var coins_label: Label
var squad_slots: Array = []        # 4 個 Button，代表已選陣容
var class_buttons: Array = []      # 6 個職業選擇按鈕
var offline_popup: Panel
var offline_msg_label: Label
var offline_confirm_btn: Button
var mission_buttons: Array = []    # 任務板按鈕

# 職業清單（6 個，對應 characters.json id）
const ALL_CLASSES: Array = [
	{"id": "shield",  "name": "盾兵",  "color": Color(1.0, 0.55, 0.0)},
	{"id": "medic",   "name": "醫療兵","color": Color(1.0, 1.0, 1.0)},
	{"id": "assault", "name": "突擊手","color": Color(1.0, 0.13, 0.13)},
	{"id": "sniper",  "name": "狙擊手","color": Color(0.27, 1.0, 0.27)},
	{"id": "demo",    "name": "爆破手","color": Color(1.0, 0.87, 0.0)},
	{"id": "recon",   "name": "偵察手","color": Color(0.0, 0.8, 1.0)},
]

# 任務資料（Demo 只顯示單一任務）
const MISSIONS: Array = [
	{
		"id": "demo_01",
		"type": "main",
		"title": "辦公大樓清查",
		"difficulty": "★★",
		"reward": "200 金幣",
		"desc": "情報顯示敵軍盤踞於廢棄辦公大樓，小隊需逐層清查並消滅指揮官。",
	},
]

# Demo 固定選中唯一任務
var selected_mission_id: String = "demo_01"

func _ready() -> void:
	_build_ui()
	_load_state()
	_show_offline_reward()

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
	title.add_theme_font_size_override("font_size", 32)
	title.modulate = Color(0.9, 0.9, 0.7)
	top.add_child(title)

	coins_label = Label.new()
	coins_label.position = Vector2(700, 28)
	coins_label.add_theme_font_size_override("font_size", 26)
	coins_label.modulate = Color(1.0, 0.9, 0.3)
	coins_label.name = "CoinsLabel"
	top.add_child(coins_label)

func _add_mission_board() -> void:
	# 區塊標題
	var section_lbl = Label.new()
	section_lbl.text = "任務板"
	section_lbl.position = Vector2(30, 120)
	section_lbl.add_theme_font_size_override("font_size", 26)
	section_lbl.modulate = Color(0.8, 1.0, 0.8)
	add_child(section_lbl)

	# 分隔線
	var sep = ColorRect.new()
	sep.position = Vector2(30, 158)
	sep.size = Vector2(1020, 2)
	sep.color = Color(0.3, 0.5, 0.3, 0.7)
	add_child(sep)

	var y_offset: float = 170.0
	for i in range(MISSIONS.size()):
		var mission = MISSIONS[i]
		var card = _create_mission_card(mission, y_offset)
		add_child(card)
		y_offset += 190.0

func _create_mission_card(mission: Dictionary, y: float) -> Control:
	var card = Control.new()
	card.position = Vector2(30, y)
	card.custom_minimum_size = Vector2(1020, 175)

	# 卡片背景
	var bg = ColorRect.new()
	bg.size = Vector2(1020, 175)
	var is_main = mission["type"] == "main"
	bg.color = Color(0.08, 0.12, 0.08) if is_main else Color(0.08, 0.10, 0.12)
	card.add_child(bg)

	# 邊框色條（左側）
	var border = ColorRect.new()
	border.position = Vector2(0, 0)
	border.size = Vector2(6, 175)
	border.color = Color(0.9, 0.7, 0.1) if is_main else Color(0.3, 0.7, 0.9)
	card.add_child(border)

	# 類型標籤
	var type_lbl = Label.new()
	type_lbl.text = "[主線]" if is_main else "[支線]"
	type_lbl.position = Vector2(18, 10)
	type_lbl.add_theme_font_size_override("font_size", 16)
	type_lbl.modulate = Color(1.0, 0.8, 0.2) if is_main else Color(0.5, 0.9, 1.0)
	card.add_child(type_lbl)

	# 任務名稱
	var title_lbl = Label.new()
	title_lbl.text = mission["title"]
	title_lbl.position = Vector2(18, 34)
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.modulate = Color.WHITE
	card.add_child(title_lbl)

	# 難度
	var diff_lbl = Label.new()
	diff_lbl.text = "難度：" + mission["difficulty"]
	diff_lbl.position = Vector2(18, 70)
	diff_lbl.add_theme_font_size_override("font_size", 18)
	diff_lbl.modulate = Color(1.0, 0.6, 0.2)
	card.add_child(diff_lbl)

	# 說明
	var desc_lbl = Label.new()
	desc_lbl.text = mission["desc"]
	desc_lbl.position = Vector2(18, 96)
	desc_lbl.add_theme_font_size_override("font_size", 15)
	desc_lbl.modulate = Color(0.75, 0.75, 0.75)
	desc_lbl.custom_minimum_size = Vector2(700, 0)
	card.add_child(desc_lbl)

	# 獎勵
	var reward_lbl = Label.new()
	reward_lbl.text = "獎勵：" + mission["reward"]
	reward_lbl.position = Vector2(18, 138)
	reward_lbl.add_theme_font_size_override("font_size", 16)
	reward_lbl.modulate = Color(0.5, 1.0, 0.5)
	card.add_child(reward_lbl)

	# Demo 單一任務：顯示「已選取」標示，不需要選擇按鈕
	var selected_lbl = Label.new()
	selected_lbl.text = "[ DEMO 任務 ]"
	selected_lbl.position = Vector2(830, 70)
	selected_lbl.add_theme_font_size_override("font_size", 18)
	selected_lbl.modulate = Color(0.4, 1.0, 0.4)
	card.add_child(selected_lbl)

	return card

func _add_squad_panel() -> void:
	var y_base: float = 560.0

	var section_lbl = Label.new()
	section_lbl.text = "陣容選擇（選 4 人）"
	section_lbl.position = Vector2(30, y_base)
	section_lbl.add_theme_font_size_override("font_size", 26)
	section_lbl.modulate = Color(0.8, 1.0, 0.8)
	add_child(section_lbl)

	var sep = ColorRect.new()
	sep.position = Vector2(30, y_base + 38)
	sep.size = Vector2(1020, 2)
	sep.color = Color(0.3, 0.5, 0.3, 0.7)
	add_child(sep)

	# ── 職業選擇按鈕（6 個）──
	var class_title = Label.new()
	class_title.text = "可用職業："
	class_title.position = Vector2(30, y_base + 50)
	class_title.add_theme_font_size_override("font_size", 18)
	class_title.modulate = Color(0.7, 0.7, 0.7)
	add_child(class_title)

	var btn_x: float = 30.0
	for i in range(ALL_CLASSES.size()):
		var cls = ALL_CLASSES[i]
		var btn = Button.new()
		btn.text = cls["name"]
		btn.position = Vector2(btn_x, y_base + 80)
		btn.custom_minimum_size = Vector2(155, 60)
		btn.add_theme_font_size_override("font_size", 18)
		btn.name = "ClassBtn_" + cls["id"]
		_style_button(btn, Color(0.12, 0.20, 0.28))
		btn.pressed.connect(_on_class_toggled.bind(cls["id"]))
		add_child(btn)
		class_buttons.append(btn)
		btn_x += 165.0

	# ── 已選陣容（4 個槽）──
	var slot_title = Label.new()
	slot_title.text = "出戰陣容："
	slot_title.position = Vector2(30, y_base + 160)
	slot_title.add_theme_font_size_override("font_size", 18)
	slot_title.modulate = Color(0.7, 0.7, 0.7)
	add_child(slot_title)

	for i in range(4):
		var slot_btn = Button.new()
		slot_btn.position = Vector2(30.0 + i * 255.0, y_base + 190)
		slot_btn.custom_minimum_size = Vector2(240, 70)
		slot_btn.add_theme_font_size_override("font_size", 20)
		slot_btn.name = "SlotBtn_" + str(i)
		_style_button(slot_btn, Color(0.10, 0.10, 0.15))
		slot_btn.pressed.connect(_on_slot_pressed.bind(i))
		add_child(slot_btn)
		squad_slots.append(slot_btn)

func _add_launch_button() -> void:
	var btn = Button.new()
	btn.text = "出發"
	btn.position = Vector2(290, 900)
	btn.custom_minimum_size = Vector2(500, 90)
	btn.add_theme_font_size_override("font_size", 30)
	btn.name = "LaunchBtn"
	_style_button(btn, Color(0.6, 0.25, 0.0))
	btn.pressed.connect(_on_launch_pressed)
	add_child(btn)

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

func _update_coins_display() -> void:
	if coins_label:
		coins_label.text = "金幣：" + str(SaveManager.coins)

func _update_squad_display() -> void:
	var selected = SaveManager.selected_squad
	for i in range(4):
		var slot = squad_slots[i]
		if i < selected.size():
			var char_id = selected[i]
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
	for i in range(ALL_CLASSES.size()):
		var cls = ALL_CLASSES[i]
		var btn = class_buttons[i]
		if cls["id"] in selected:
			btn.modulate = cls["color"]
			btn.text = cls["name"] + " ✓"
		else:
			btn.modulate = Color(0.75, 0.75, 0.75)
			btn.text = cls["name"]

func _get_class_data(char_id: String) -> Dictionary:
	for cls in ALL_CLASSES:
		if cls["id"] == char_id:
			return cls
	return {}

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
	if char_id in selected:
		# 已在陣容中，移除
		selected.erase(char_id)
	else:
		# 不在陣容中，若槽位已滿則替換最後一個
		if selected.size() >= 4:
			selected.pop_back()
		selected.append(char_id)
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
	# Demo 固定任務，無需選擇
	selected_mission_id = "demo_01"

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

	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _show_error(msg: String) -> void:
	# 短暫顯示錯誤訊息（複用 offline_msg_label 邏輯，用獨立 label）
	var err_lbl = get_node_or_null("ErrorLabel")
	if err_lbl == null:
		err_lbl = Label.new()
		err_lbl.name = "ErrorLabel"
		err_lbl.position = Vector2(290, 1000)
		err_lbl.add_theme_font_size_override("font_size", 22)
		err_lbl.modulate = Color(1.0, 0.3, 0.3)
		add_child(err_lbl)
	err_lbl.text = msg
	# 2 秒後自動清空
	get_tree().create_timer(2.0).timeout.connect(func(): if is_instance_valid(err_lbl): err_lbl.text = "")

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
