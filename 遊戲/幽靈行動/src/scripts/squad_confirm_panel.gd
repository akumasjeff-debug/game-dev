extends CanvasLayer

# 陣容確認面板 v2 — 點選槽位換人式
# 上方：任務名稱 + 難度
# 中間：4 張選定卡片（橫排），點擊任一張 → 高亮（橙框）
# 下方：彈出一排可選卡片（全部擁有的卡），點擊換入選中的槽位
# 確認按鈕 → 儲存陣容 → 開始任務

signal confirmed(squad: Array)
signal cancelled

var _mission_data: Dictionary = {}
var _current_squad: Array = []    # 目前選定的 card_id Array（最多 4）
var _all_owned_cards: Array = []  # 全部擁有的 card_id（排序後）
var _selected_slot: int = -1      # 目前高亮的槽位 index（0–3）
var _cards_json: Dictionary = {}  # {card_id: Dictionary}

# UI 節點引用
var _slot_container: Control
var _slot_nodes: Array = []   # 4 個槽位 Control
var _swap_panel: Control      # 底部換人列（初始在畫面外）
var _swap_scroll: ScrollContainer

# ─────────────────────────────────────────
#  初始化
# ─────────────────────────────────────────

func _ready() -> void:
	layer = 13
	_load_data()
	_build_ui()

func setup(mission: Dictionary, squad: Array) -> void:
	_mission_data = mission
	_current_squad = squad.duplicate()

func _load_data() -> void:
	# 讀 cards.json（頂層是 {"cards": [...]}）
	var f = FileAccess.open("res://resources/data/cards.json", FileAccess.READ)
	if f:
		var raw = JSON.parse_string(f.get_as_text())
		f.close()
		var cards_array: Array = []
		if raw is Dictionary and raw.has("cards") and raw["cards"] is Array:
			cards_array = raw["cards"]
		elif raw is Array:
			cards_array = raw
		for c in cards_array:
			if c is Dictionary and c.has("id"):
				_cards_json[c["id"]] = c

	# 從 SaveManager 讀取當前陣容（如果 setup() 還沒呼叫過）
	if _current_squad.is_empty():
		_current_squad = SaveManager.selected_squad.duplicate()

	# 建立擁有卡片清單（按 grade 優先度排序：QR→SSR→SR→R）
	var grade_order = {"QR": 0, "SSR": 1, "SR": 2, "R": 3}
	for card_id in SaveManager.owned_cards.keys():
		_all_owned_cards.append(card_id)
	_all_owned_cards.sort_custom(func(a, b):
		var ga = _cards_json.get(a, {}).get("grade", "R")
		var gb = _cards_json.get(b, {}).get("grade", "R")
		var oa = grade_order.get(ga, 3)
		var ob = grade_order.get(gb, 3)
		if oa != ob:
			return oa < ob
		return a < b
	)

# ─────────────────────────────────────────
#  建立 UI
# ─────────────────────────────────────────

func _build_ui() -> void:
	# 全螢幕暗底
	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.90)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.size = Vector2(1080, 1920)
	add_child(bg)

	# 任務標題列
	var mission_name = _mission_data.get("name", "任務確認")
	var diff_val: int = _mission_data.get("difficulty", 1)
	var star_text = "★".repeat(clampi(diff_val, 0, 5)) + "☆".repeat(maxi(0, 5 - diff_val))

	var title_lbl = Label.new()
	title_lbl.text = "出擊確認：%s" % mission_name
	title_lbl.add_theme_font_size_override("font_size", 42)
	title_lbl.modulate = Color(1.0, 0.85, 0.3)
	title_lbl.position = Vector2(40, 55)
	title_lbl.size = Vector2(1000, 60)
	add_child(title_lbl)

	var diff_lbl = Label.new()
	diff_lbl.text = "難度：%s" % star_text
	diff_lbl.add_theme_font_size_override("font_size", 28)
	diff_lbl.modulate = _difficulty_color(diff_val)
	diff_lbl.position = Vector2(40, 120)
	add_child(diff_lbl)

	var hint_lbl = Label.new()
	hint_lbl.text = "點擊下方卡片可替換隊員"
	hint_lbl.add_theme_font_size_override("font_size", 24)
	hint_lbl.modulate = Color(0.6, 0.75, 0.6)
	hint_lbl.position = Vector2(40, 158)
	add_child(hint_lbl)

	# 4 個槽位容器
	_slot_container = Control.new()
	_slot_container.name = "SlotContainer"
	_slot_container.size = Vector2(1080, 380)
	_slot_container.position = Vector2(0, 200)
	add_child(_slot_container)
	_build_squad_slots()

	# 底部換人列（初始在畫面外下方）
	_build_swap_panel()

	# 按鈕列：取消 + 出擊
	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.size = Vector2(400, 110)
	cancel_btn.position = Vector2(40, 1790)
	cancel_btn.add_theme_font_size_override("font_size", 32)
	_style_btn(cancel_btn, Color(0.22, 0.08, 0.08))
	cancel_btn.pressed.connect(_on_cancel)
	add_child(cancel_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "出擊！"
	confirm_btn.size = Vector2(560, 110)
	confirm_btn.position = Vector2(480, 1790)
	confirm_btn.add_theme_font_size_override("font_size", 38)
	_style_btn(confirm_btn, Color(0.50, 0.22, 0.0))
	confirm_btn.modulate = Color(1.0, 0.9, 0.5)
	confirm_btn.pressed.connect(_on_confirm)
	add_child(confirm_btn)

# ─────────────────────────────────────────
#  槽位建立
# ─────────────────────────────────────────

func _build_squad_slots() -> void:
	# 移除舊槽位
	for slot in _slot_nodes:
		if is_instance_valid(slot):
			slot.queue_free()
	_slot_nodes.clear()

	var card_w = 230
	var card_h = 350
	var spacing = 18
	var total_w = card_w * 4 + spacing * 3
	var start_x = (1080 - total_w) / 2

	for i in range(4):
		var card_id = _current_squad[i] if i < _current_squad.size() else ""
		var slot = _build_slot_card(i, card_id, card_w, card_h)
		slot.position = Vector2(start_x + i * (card_w + spacing), 0)
		_slot_container.add_child(slot)
		_slot_nodes.append(slot)

func _build_slot_card(slot_idx: int, card_id: String, w: int, h: int) -> Control:
	var container = Control.new()
	container.size = Vector2(w, h)
	container.name = "Slot_%d" % slot_idx

	var card_info = _cards_json.get(card_id, {})
	var grade = card_info.get("grade", "")

	# 卡框背景
	var frame_path = "res://resources/art/cards/card_frame_%s.svg" % grade.to_lower() if grade != "" else ""
	if frame_path != "" and ResourceLoader.exists(frame_path):
		var frame_tex = TextureRect.new()
		frame_tex.texture = load(frame_path)
		frame_tex.size = Vector2(w, h - 36)
		frame_tex.stretch_mode = TextureRect.STRETCH_SCALE
		container.add_child(frame_tex)
	else:
		var grade_colors: Dictionary = {
			"R": Color(0.08, 0.16, 0.28), "SR": Color(0.18, 0.08, 0.30),
			"SSR": Color(0.28, 0.22, 0.02), "QR": Color(0.35, 0.04, 0.02)
		}
		var card_bg = ColorRect.new()
		card_bg.size = Vector2(w, h - 36)
		card_bg.color = grade_colors.get(grade, Color(0.08, 0.10, 0.14)) if not card_id.is_empty() else Color(0.06, 0.07, 0.10)
		container.add_child(card_bg)

		# 稀有度邊框色
		if not card_id.is_empty() and grade != "":
			var grade_border: Dictionary = {
				"R": Color(0.27, 0.53, 0.80), "SR": Color(0.60, 0.40, 0.90),
				"SSR": Color(0.90, 0.72, 0.10), "QR": Color(0.90, 0.20, 0.10)
			}
			var bp = Panel.new()
			bp.size = Vector2(w, h - 36)
			bp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var bp_style = StyleBoxFlat.new()
			bp_style.bg_color = Color(0, 0, 0, 0)
			bp_style.border_color = grade_border.get(grade, Color(0.3, 0.3, 0.35))
			bp_style.set_border_width_all(3)
			bp_style.set_corner_radius_all(4)
			bp.add_theme_stylebox_override("panel", bp_style)
			container.add_child(bp)

	if card_id.is_empty():
		# 空槽
		var empty_lbl = Label.new()
		empty_lbl.text = "空槽"
		empty_lbl.add_theme_font_size_override("font_size", 26)
		empty_lbl.modulate = Color(0.35, 0.35, 0.35)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.size = Vector2(w, 50)
		empty_lbl.position = Vector2(0, (h - 36) / 2 - 25)
		container.add_child(empty_lbl)
	else:
		# 角色肖像
		var portrait_path = card_info.get("portrait_path", "")
		if portrait_path != "" and ResourceLoader.exists(portrait_path):
			var portrait = TextureRect.new()
			portrait.texture = load(portrait_path)
			portrait.size = Vector2(w - 10, h - 100)
			portrait.position = Vector2(5, 5)
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			container.add_child(portrait)

		# 名稱
		var name_lbl = Label.new()
		name_lbl.text = card_info.get("name", card_id)
		name_lbl.add_theme_font_size_override("font_size", 17)
		name_lbl.position = Vector2(4, h - 92)
		name_lbl.size = Vector2(w - 8, 24)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(name_lbl)

		# 等級
		var lv = SaveManager.get_card_level(card_id) if SaveManager.has_method("get_card_level") else 1
		var lv_lbl = Label.new()
		lv_lbl.text = "Lv.%d" % lv
		lv_lbl.add_theme_font_size_override("font_size", 15)
		lv_lbl.modulate = Color(1.0, 0.85, 0.3)
		lv_lbl.position = Vector2(4, h - 68)
		lv_lbl.size = Vector2(w / 2, 22)
		container.add_child(lv_lbl)

		# 強化值
		var plus = SaveManager.get_card_plus(card_id) if SaveManager.has_method("get_card_plus") else 0
		if plus > 0:
			var plus_lbl = Label.new()
			plus_lbl.text = "+%d" % plus
			plus_lbl.add_theme_font_size_override("font_size", 15)
			plus_lbl.modulate = Color(1.0, 0.75, 0.2)
			plus_lbl.position = Vector2(w / 2, h - 68)
			plus_lbl.size = Vector2(w / 2 - 4, 22)
			plus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			container.add_child(plus_lbl)

	# 橙色高亮框（4 條細邊，預設透明）
	var hl_colors = [Color(1.0, 0.6, 0.1, 0.0)] * 4  # 存放各邊預設透明
	var borders: Array = []
	var bd_defs = [
		[Vector2(0, 0), Vector2(w, 5)],
		[Vector2(0, h - 41), Vector2(w, 5)],
		[Vector2(0, 0), Vector2(5, h - 36)],
		[Vector2(w - 5, 0), Vector2(5, h - 36)],
	]
	for bd_def in bd_defs:
		var bd = ColorRect.new()
		bd.position = bd_def[0]
		bd.size = bd_def[1]
		bd.color = Color(1.0, 0.6, 0.1, 0.0)
		bd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bd.name = "Border"
		container.add_child(bd)
		borders.append(bd)
	container.set_meta("borders", borders)

	# 槽位標籤（下方）
	var idx_lbl = Label.new()
	idx_lbl.text = "隊員 %d" % (slot_idx + 1)
	idx_lbl.add_theme_font_size_override("font_size", 18)
	idx_lbl.modulate = Color(0.55, 0.55, 0.55)
	idx_lbl.position = Vector2(0, h - 32)
	idx_lbl.size = Vector2(w, 28)
	idx_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(idx_lbl)

	# 透明點擊按鈕（蓋在整個卡片上）
	var btn = Button.new()
	btn.size = Vector2(w, h - 36)
	btn.flat = true
	var flat_style = StyleBoxFlat.new()
	flat_style.bg_color = Color(0, 0, 0, 0)
	flat_style.set_border_width_all(0)
	btn.add_theme_stylebox_override("normal", flat_style)
	btn.add_theme_stylebox_override("hover", flat_style)
	btn.add_theme_stylebox_override("pressed", flat_style)
	btn.add_theme_stylebox_override("focus", flat_style)
	btn.pressed.connect(func(): _on_slot_pressed(slot_idx))
	container.add_child(btn)

	return container

# ─────────────────────────────────────────
#  槽位點擊與高亮
# ─────────────────────────────────────────

func _on_slot_pressed(slot_idx: int) -> void:
	if _selected_slot == slot_idx:
		# 再點一次同槽位 → 取消選中，收起換人列
		_selected_slot = -1
		_hide_swap_panel()
		_update_slot_highlights()
		return

	_selected_slot = slot_idx
	_update_slot_highlights()
	_show_swap_panel()

func _update_slot_highlights() -> void:
	for i in range(_slot_nodes.size()):
		var slot = _slot_nodes[i]
		if not is_instance_valid(slot):
			continue
		var borders = slot.get_meta("borders", [])
		var alpha = 1.0 if i == _selected_slot else 0.0
		for bd in borders:
			if is_instance_valid(bd):
				bd.color = Color(1.0, 0.6, 0.1, alpha)

# ─────────────────────────────────────────
#  底部換人列
# ─────────────────────────────────────────

func _build_swap_panel() -> void:
	_swap_panel = Control.new()
	_swap_panel.name = "SwapPanel"
	_swap_panel.size = Vector2(1080, 420)
	_swap_panel.position = Vector2(0, 1920.0)  # 初始在畫面外
	add_child(_swap_panel)

	# 深色背景
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.10, 0.97)
	bg.size = Vector2(1080, 420)
	_swap_panel.add_child(bg)

	# 頂部分隔線
	var sep = ColorRect.new()
	sep.size = Vector2(1080, 3)
	sep.color = Color(0.4, 0.5, 0.4, 0.7)
	_swap_panel.add_child(sep)

	# 標題
	var lbl = Label.new()
	lbl.text = "選擇替換的卡片（橫滑可查看全部）"
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.modulate = Color(0.75, 0.9, 0.75)
	lbl.position = Vector2(24, 12)
	_swap_panel.add_child(lbl)

	# 可橫向捲動的容器
	_swap_scroll = ScrollContainer.new()
	_swap_scroll.size = Vector2(1080, 360)
	_swap_scroll.position = Vector2(0, 55)
	_swap_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_swap_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_swap_panel.add_child(_swap_scroll)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_swap_scroll.add_child(hbox)

	# 填入全部擁有的卡
	var card_w = 190
	var card_h = 300
	for card_id in _all_owned_cards:
		var swap_card = _build_swap_card(card_id, card_w, card_h)
		hbox.add_child(swap_card)

func _build_swap_card(card_id: String, w: int, h: int) -> Control:
	var card_info = _cards_json.get(card_id, {})
	var grade = card_info.get("grade", "R")

	var container = Control.new()
	container.custom_minimum_size = Vector2(w + 12, h + 8)

	# 背景（框或色塊）
	var frame_path = "res://resources/art/cards/card_frame_%s.svg" % grade.to_lower()
	if ResourceLoader.exists(frame_path):
		var frame_tex = TextureRect.new()
		frame_tex.texture = load(frame_path)
		frame_tex.size = Vector2(w, h)
		frame_tex.position = Vector2(6, 4)
		frame_tex.stretch_mode = TextureRect.STRETCH_SCALE
		container.add_child(frame_tex)
	else:
		var grade_colors: Dictionary = {
			"R": Color(0.08, 0.16, 0.28), "SR": Color(0.18, 0.08, 0.30),
			"SSR": Color(0.28, 0.22, 0.02), "QR": Color(0.35, 0.04, 0.02)
		}
		var card_bg = ColorRect.new()
		card_bg.size = Vector2(w, h)
		card_bg.position = Vector2(6, 4)
		card_bg.color = grade_colors.get(grade, Color(0.1, 0.1, 0.15))
		container.add_child(card_bg)

	# 肖像
	var portrait_path = card_info.get("portrait_path", "")
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		var portrait = TextureRect.new()
		portrait.texture = load(portrait_path)
		portrait.size = Vector2(w - 10, h - 50)
		portrait.position = Vector2(11, 8)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		container.add_child(portrait)

	# 名稱
	var name_lbl = Label.new()
	name_lbl.text = card_info.get("name", card_id)
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.position = Vector2(6, h - 42 + 4)
	name_lbl.size = Vector2(w, 20)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(name_lbl)

	# 等級
	var lv = SaveManager.get_card_level(card_id) if SaveManager.has_method("get_card_level") else 1
	var lv_lbl = Label.new()
	lv_lbl.text = "Lv.%d" % lv
	lv_lbl.add_theme_font_size_override("font_size", 13)
	lv_lbl.modulate = Color(1.0, 0.85, 0.3)
	lv_lbl.position = Vector2(6, h - 22 + 4)
	lv_lbl.size = Vector2(w / 2, 18)
	container.add_child(lv_lbl)

	# 強化值
	var plus = SaveManager.get_card_plus(card_id) if SaveManager.has_method("get_card_plus") else 0
	if plus > 0:
		var plus_lbl = Label.new()
		plus_lbl.text = "+%d" % plus
		plus_lbl.add_theme_font_size_override("font_size", 13)
		plus_lbl.modulate = Color(1.0, 0.75, 0.2)
		plus_lbl.position = Vector2(6 + w / 2, h - 22 + 4)
		plus_lbl.size = Vector2(w / 2, 18)
		plus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		container.add_child(plus_lbl)

	# 透明點擊按鈕
	var btn = Button.new()
	btn.size = Vector2(w, h + 8)
	btn.position = Vector2(6, 4)
	btn.flat = true
	var flat_style = StyleBoxFlat.new()
	flat_style.bg_color = Color(0, 0, 0, 0)
	flat_style.set_border_width_all(0)
	btn.add_theme_stylebox_override("normal", flat_style)
	btn.add_theme_stylebox_override("hover", flat_style)
	btn.add_theme_stylebox_override("pressed", flat_style)
	btn.add_theme_stylebox_override("focus", flat_style)
	btn.pressed.connect(func(): _swap_card_into_slot(card_id))
	container.add_child(btn)

	return container

# ─────────────────────────────────────────
#  換人列動畫
# ─────────────────────────────────────────

func _show_swap_panel() -> void:
	# 換人列出現在「槽位底部 + 少許間距」的位置（約 y=630）
	# 但為了手機全螢幕體驗，固定在下方 1920-420=1500
	var target_y = 1920.0 - 420.0
	var tw = create_tween()
	tw.tween_property(_swap_panel, "position:y", target_y, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)

func _hide_swap_panel() -> void:
	var tw = create_tween()
	tw.tween_property(_swap_panel, "position:y", 1920.0, 0.18).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)

# ─────────────────────────────────────────
#  換入卡片
# ─────────────────────────────────────────

func _swap_card_into_slot(card_id: String) -> void:
	if _selected_slot < 0:
		return

	# 補足陣容陣列長度
	while _current_squad.size() <= _selected_slot:
		_current_squad.append("")
	_current_squad[_selected_slot] = card_id

	# 重建槽位顯示
	_build_squad_slots()

	# 取消選中並收起換人列
	_selected_slot = -1
	_hide_swap_panel()

# ─────────────────────────────────────────
#  按鈕事件
# ─────────────────────────────────────────

func _on_confirm() -> void:
	# 儲存陣容到 SaveManager
	SaveManager.set_selected_squad(_current_squad)
	emit_signal("confirmed", _current_squad)
	# 播放任務開場動廊後進場
	_play_mission_intro()

func _on_cancel() -> void:
	emit_signal("cancelled")
	queue_free()

func _play_mission_intro() -> void:
	var intro_overlay = ColorRect.new()
	intro_overlay.size = Vector2(1080, 1920)
	intro_overlay.color = Color(0, 0, 0, 0)
	intro_overlay.z_index = 100
	add_child(intro_overlay)

	var mission_title_lbl = Label.new()
	mission_title_lbl.text = "任務：%s" % _mission_data.get("name", "出發")
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

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(intro_overlay, "color", Color(0, 0, 0, 0.92), 0.6)
	tween.tween_property(mission_title_lbl, "modulate", Color(0.9, 0.8, 0.3, 1.0), 0.6)
	tween.tween_property(sub_lbl, "modulate", Color(0.7, 0.7, 0.7, 1.0), 0.8)
	tween.set_parallel(false)
	tween.tween_interval(0.9)
	tween.tween_callback(_launch_mission)

func _launch_mission() -> void:
	queue_free()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

# ─────────────────────────────────────────
#  輔助
# ─────────────────────────────────────────

func _difficulty_color(diff: int) -> Color:
	match diff:
		1: return Color(0.4, 0.9, 0.4)
		2: return Color(0.9, 0.7, 0.1)
		3: return Color(1.0, 0.4, 0.1)
		4: return Color(0.9, 0.1, 0.1)
		_: return Color(0.7, 0.2, 0.9)

func _style_btn(btn: Button, bg: Color) -> void:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = Color(minf(bg.r + 0.2, 1.0), minf(bg.g + 0.2, 1.0), minf(bg.b + 0.2, 1.0), 0.85)
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", s)
	var h_style = StyleBoxFlat.new()
	h_style.bg_color = Color(minf(bg.r + 0.12, 1.0), minf(bg.g + 0.12, 1.0), minf(bg.b + 0.12, 1.0))
	h_style.border_color = Color(minf(bg.r + 0.3, 1.0), minf(bg.g + 0.3, 1.0), minf(bg.b + 0.3, 1.0))
	h_style.set_border_width_all(2)
	h_style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("hover", h_style)
