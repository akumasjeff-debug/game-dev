extends CanvasLayer

signal gallery_closed

var _cards_json: Dictionary = {}
var _scroll: ScrollContainer
var _grid: GridContainer
var _selected_squad: Array = []  # 永遠 4 張 card_id
var _info_label: Label
var _pending_swap_card: String = ""  # 橙色選中、等待指定槽位的卡片

func _ready() -> void:
	layer = 11
	_load_cards_data()
	_build_ui()
	_refresh_grid()

func _load_cards_data() -> void:
	var f = FileAccess.open("res://resources/data/cards.json", FileAccess.READ)
	if f == null:
		return
	var raw = JSON.parse_string(f.get_as_text())
	f.close()
	if raw is Array:
		for c in raw:
			if c is Dictionary and c.has("id"):
				_cards_json[c["id"]] = c
	elif raw is Dictionary and raw.has("cards"):
		for c in raw["cards"]:
			if c is Dictionary and c.has("id"):
				_cards_json[c["id"]] = c

func _build_ui() -> void:
	# 黑底
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.09)
	bg.size = Vector2(1080, 1920)
	add_child(bg)

	# 頂欄
	var top_bar = ColorRect.new()
	top_bar.color = Color(0.1, 0.1, 0.16)
	top_bar.size = Vector2(1080, 120)
	add_child(top_bar)

	var title = Label.new()
	title.text = "我的卡牌"
	title.add_theme_font_size_override("font_size", 44)
	title.modulate = Color(1.0, 0.85, 0.3)
	title.position = Vector2(40, 30)
	add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.size = Vector2(80, 80)
	close_btn.position = Vector2(980, 20)
	close_btn.add_theme_font_size_override("font_size", 36)
	close_btn.pressed.connect(_on_close)
	add_child(close_btn)

	# 陣容狀態提示
	_info_label = Label.new()
	_info_label.text = "點擊卡片選擇，再點陣容中的卡替換"
	_info_label.add_theme_font_size_override("font_size", 24)
	_info_label.modulate = Color(0.7, 0.9, 0.7)
	_info_label.position = Vector2(40, 130)
	_info_label.size = Vector2(1000, 40)
	add_child(_info_label)

	# 確認選隊按鈕
	var confirm_btn = Button.new()
	confirm_btn.text = "確認陣容 (0/4)"
	confirm_btn.name = "ConfirmBtn"
	confirm_btn.size = Vector2(900, 80)
	confirm_btn.position = Vector2(90, 1820)
	confirm_btn.add_theme_font_size_override("font_size", 30)
	confirm_btn.modulate = Color(0.4, 1.0, 0.5)
	confirm_btn.pressed.connect(_on_confirm_squad)
	add_child(confirm_btn)

	# ScrollContainer（填滿中間區域）
	_scroll = ScrollContainer.new()
	_scroll.size = Vector2(1080, 1640)
	_scroll.position = Vector2(0, 175)
	add_child(_scroll)

	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_grid)

func _refresh_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()

	var save_mgr = get_node_or_null("/root/SaveManager")

	# 只在首次載入（_selected_squad 還是空的）才從 SaveManager 讀取
	# 換人操作後 _refresh_grid 不覆蓋記憶體中的狀態
	if _selected_squad.is_empty():
		if save_mgr:
			var squad_val = save_mgr.get("selected_squad")
			if squad_val != null and squad_val is Array:
				_selected_squad = squad_val.duplicate()

	# 確保陣容永遠 4 張
	while _selected_squad.size() < 4:
		_selected_squad.append("assault_r")

	# 建立每張擁有的卡
	for card_id in _cards_json:
		if save_mgr == null or not save_mgr.has_method("has_card"):
			continue
		if not save_mgr.has_card(card_id):
			continue
		_grid.add_child(_build_card_slot(card_id, save_mgr))

	# 更新確認按鈕文字
	_update_confirm_btn()

func _update_confirm_btn() -> void:
	var confirm_btn = get_node_or_null("ConfirmBtn")
	if confirm_btn:
		confirm_btn.text = "確認陣容（4/4）"

func _build_card_slot(card_id: String, save_mgr: Node) -> Control:
	var card_info = _cards_json.get(card_id, {})
	var grade = card_info.get("grade", "R")

	var slot = Control.new()
	slot.custom_minimum_size = Vector2(320, 520)
	slot.size = Vector2(320, 520)

	var is_selected = card_id in _selected_squad
	var is_pending = (card_id == _pending_swap_card)
	var lv = 1
	var plus = 0
	if save_mgr.has_method("get_card_level"):
		lv = save_mgr.get_card_level(card_id)
	if save_mgr.has_method("get_card_plus"):
		plus = save_mgr.get_card_plus(card_id)

	# 卡框（按稀有度嘗試 SVG，失敗則色塊）
	var frame_path = "res://resources/art/cards/card_frame_%s.svg" % grade.to_lower()
	if ResourceLoader.exists(frame_path):
		var frame = TextureRect.new()
		frame.texture = load(frame_path)
		frame.size = Vector2(310, 460)
		frame.position = Vector2(5, 5)
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		slot.add_child(frame)
	else:
		var grade_colors = {
			"R":   Color(0.08, 0.16, 0.28),
			"SR":  Color(0.18, 0.08, 0.30),
			"SSR": Color(0.28, 0.22, 0.02),
			"QR":  Color(0.35, 0.04, 0.02)
		}
		var card_bg = ColorRect.new()
		card_bg.size = Vector2(310, 460)
		card_bg.position = Vector2(5, 5)
		card_bg.color = grade_colors.get(grade, Color(0.10, 0.10, 0.15))
		slot.add_child(card_bg)

		# 稀有度邊框
		var grade_border_colors = {
			"R":   Color(0.27, 0.53, 0.80),
			"SR":  Color(0.60, 0.40, 0.90),
			"SSR": Color(0.90, 0.72, 0.10),
			"QR":  Color(0.90, 0.20, 0.10)
		}
		var border_panel = Panel.new()
		border_panel.size = Vector2(310, 460)
		border_panel.position = Vector2(5, 5)
		border_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bp_style = StyleBoxFlat.new()
		bp_style.bg_color = Color(0, 0, 0, 0)
		bp_style.border_color = grade_border_colors.get(grade, Color(0.3, 0.3, 0.35))
		bp_style.set_border_width_all(3)
		bp_style.set_corner_radius_all(4)
		border_panel.add_theme_stylebox_override("panel", bp_style)
		slot.add_child(border_panel)

	# 肖像
	var portrait_path = card_info.get("portrait_path", "")
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		var portrait = TextureRect.new()
		portrait.texture = load(portrait_path)
		portrait.size = Vector2(290, 330)
		portrait.position = Vector2(15, 15)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.add_child(portrait)

	# 名稱
	var name_lbl = Label.new()
	name_lbl.text = card_info.get("name", card_id)
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.position = Vector2(10, 355)
	name_lbl.size = Vector2(300, 30)
	slot.add_child(name_lbl)

	# Lv 標籤
	var lv_lbl = Label.new()
	lv_lbl.text = "Lv.%d" % lv
	lv_lbl.add_theme_font_size_override("font_size", 18)
	lv_lbl.modulate = Color(0.7, 1.0, 0.7)
	lv_lbl.position = Vector2(10, 382)
	slot.add_child(lv_lbl)

	# +N badge（只在 plus > 0 時顯示，且顯眼）
	if plus > 0:
		var plus_bg = ColorRect.new()
		plus_bg.size = Vector2(64, 38)
		plus_bg.position = Vector2(242, 374)
		plus_bg.color = Color(0.55, 0.35, 0.0, 0.92)
		plus_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(plus_bg)
		var plus_lbl = Label.new()
		plus_lbl.text = "+%d" % plus
		plus_lbl.size = Vector2(64, 38)
		plus_lbl.position = Vector2(242, 374)
		plus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus_lbl.add_theme_font_size_override("font_size", 28)
		plus_lbl.modulate = Color(1.0, 0.92, 0.1)
		plus_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(plus_lbl)

	# 升級按鈕
	var upgrade_cost = lv * 50
	var upgrade_btn = Button.new()
	upgrade_btn.text = "升Lv（%d金）" % upgrade_cost
	upgrade_btn.size = Vector2(300, 50)
	upgrade_btn.position = Vector2(5, 410)
	upgrade_btn.add_theme_font_size_override("font_size", 18)
	# 捕捉變數避免 closure 陷阱
	var captured_card_id = card_id
	var captured_cost = upgrade_cost
	upgrade_btn.pressed.connect(func():
		var sm = get_node_or_null("/root/SaveManager")
		if sm and sm.has_method("upgrade_card"):
			if sm.upgrade_card(captured_card_id, captured_cost):
				_refresh_grid()
	)
	slot.add_child(upgrade_btn)

	# 邊框：橙色（待換）優先，綠色（出戰）次之
	var border_bd_positions = [
		[Vector2(0, 0),   Vector2(320, 5)],
		[Vector2(0, 515), Vector2(320, 5)],
		[Vector2(0, 0),   Vector2(5, 520)],
		[Vector2(315, 0), Vector2(5, 520)]
	]
	if is_pending:
		for bd_data in border_bd_positions:
			var bd = ColorRect.new()
			bd.position = bd_data[0]
			bd.size = bd_data[1]
			bd.color = Color(1.0, 0.55, 0.1, 0.95)  # 橙色
			bd.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(bd)

		var swap_lbl = Label.new()
		swap_lbl.text = "⟳ 待換"
		swap_lbl.add_theme_font_size_override("font_size", 22)
		swap_lbl.modulate = Color(1.0, 0.55, 0.1)
		swap_lbl.position = Vector2(195, 355)
		swap_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(swap_lbl)
	elif is_selected:
		for bd_data in border_bd_positions:
			var bd = ColorRect.new()
			bd.position = bd_data[0]
			bd.size = bd_data[1]
			bd.color = Color(0.2, 1.0, 0.3, 0.9)  # 綠色
			bd.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(bd)

		var check = Label.new()
		check.text = "√ 出戰"
		check.add_theme_font_size_override("font_size", 22)
		check.modulate = Color(0.2, 1.0, 0.3)
		check.position = Vector2(200, 355)
		check.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(check)

	# 透明點擊層（覆蓋整張卡，不含升級按鈕）
	var hit_btn = Button.new()
	hit_btn.size = Vector2(320, 405)
	hit_btn.position = Vector2(0, 0)
	hit_btn.flat = true
	hit_btn.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var captured_id = card_id
	hit_btn.pressed.connect(func(): _on_card_tapped(captured_id))
	slot.add_child(hit_btn)

	return slot

func _on_card_tapped(card_id: String) -> void:
	var is_in_squad = card_id in _selected_squad

	if _pending_swap_card.is_empty():
		# 第一步：選定一張卡（不論在不在陣容）
		_pending_swap_card = card_id
		_refresh_grid()
		if is_in_squad:
			_info_label.text = "選擇要換入的新卡（點擊其他卡替換）"
		else:
			_info_label.text = "請點擊陣容中的卡片，決定換掉哪一個"
	else:
		# 第二步：決定交換
		if _pending_swap_card == card_id:
			# 點同一張：取消選擇
			_pending_swap_card = ""
			_info_label.text = "點擊卡片選擇，再點陣容中的卡替換"
			_refresh_grid()
			return

		var pending_in_squad = _pending_swap_card in _selected_squad

		if pending_in_squad and not is_in_squad:
			# 情況A：先選陣容卡，再選非陣容卡 → 陣容卡被替換
			var idx = _selected_squad.find(_pending_swap_card)
			if idx >= 0:
				_selected_squad[idx] = card_id
		elif not pending_in_squad and is_in_squad:
			# 情況B：先選非陣容卡，再選陣容卡 → 陣容卡被替換
			var idx = _selected_squad.find(card_id)
			if idx >= 0:
				_selected_squad[idx] = _pending_swap_card
		elif pending_in_squad and is_in_squad:
			# 情況C：兩張都在陣容 → 互換位置
			var idx_a = _selected_squad.find(_pending_swap_card)
			var idx_b = _selected_squad.find(card_id)
			if idx_a >= 0 and idx_b >= 0:
				_selected_squad[idx_a] = card_id
				_selected_squad[idx_b] = _pending_swap_card
		else:
			# 兩張都不在陣容：改選新的待換卡，等使用者點陣容卡
			_pending_swap_card = card_id
			_info_label.text = "請點擊陣容中的卡片，決定換掉哪一個"
			_refresh_grid()
			return

		_pending_swap_card = ""
		_info_label.text = "點擊卡片選擇，再點陣容中的卡替換"
		_refresh_grid()

func _on_confirm_squad() -> void:
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.has_method("set_selected_squad"):
		save_mgr.set_selected_squad(_selected_squad)
	emit_signal("gallery_closed")
	queue_free()

func _on_close() -> void:
	emit_signal("gallery_closed")
	queue_free()
