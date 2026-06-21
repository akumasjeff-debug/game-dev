extends CanvasLayer

signal gallery_closed

const MAX_LEVEL := 20
const GRADE_BG := {
	"R":   Color(0.08, 0.16, 0.28),
	"SR":  Color(0.18, 0.08, 0.30),
	"SSR": Color(0.28, 0.22, 0.02),
	"QR":  Color(0.35, 0.04, 0.02)
}
const GRADE_BORDER := {
	"R":   Color(0.27, 0.53, 0.80),
	"SR":  Color(0.60, 0.40, 0.90),
	"SSR": Color(0.90, 0.72, 0.10),
	"QR":  Color(0.90, 0.20, 0.10)
}

var _cards: Dictionary = {}          # card_id -> card data
var _owned_list: Array = []          # sorted list of owned card_ids
var _current_squad: Array = []       # 4 card_ids
var _selected_slot: int = 0          # 0~3, -1 = none
var _font: Font = null

# UI references rebuilt on each refresh
var _squad_panel: Control
var _card_list_container: Control
var _scroll: ScrollContainer

func _ready() -> void:
	layer = 11
	_try_load_font()
	_load_cards_json()
	_init_squad()
	_build_ui()

# ──────────────────────────────────────────────
# 初始化
# ──────────────────────────────────────────────
func _try_load_font() -> void:
	var path := "res://resources/fonts/chinese_font.ttf"
	if ResourceLoader.exists(path):
		_font = load(path)

func _load_cards_json() -> void:
	var f := FileAccess.open("res://resources/data/cards.json", FileAccess.READ)
	if f == null:
		return
	var raw = JSON.parse_string(f.get_as_text())
	f.close()
	var arr: Array = []
	if raw is Array:
		arr = raw
	elif raw is Dictionary and raw.has("cards"):
		arr = raw["cards"]
	for c in arr:
		if c is Dictionary and c.has("id"):
			_cards[c["id"]] = c

func _init_squad() -> void:
	var sm := _save_mgr()
	if sm:
		var sq = sm.get("selected_squad")
		if sq is Array:
			_current_squad = sq.duplicate()
	while _current_squad.size() < 4:
		_current_squad.append("")

func _save_mgr() -> Node:
	return get_node_or_null("/root/SaveManager")

# ──────────────────────────────────────────────
# 排序擁有的卡
# ──────────────────────────────────────────────
func _rebuild_owned_list() -> void:
	_owned_list.clear()
	var sm := _save_mgr()
	if sm == null:
		return
	for card_id in _cards:
		if sm.has_method("has_card") and sm.has_card(card_id):
			_owned_list.append(card_id)

	# 過濾：已在陣容的卡不出現在下方可選清單
	_owned_list = _owned_list.filter(func(cid): return not (cid in _current_squad))

	_owned_list.sort_custom(func(a: String, b: String) -> bool:
		var ca: String = _cards[a].get("class_id", _cards[a].get("char_class", ""))
		var cb: String = _cards[b].get("class_id", _cards[b].get("char_class", ""))
		if ca != cb:
			return ca < cb
		var la: int = _get_level(a)
		var lb: int = _get_level(b)
		return la > lb
	)

func _get_level(card_id: String) -> int:
	var sm := _save_mgr()
	if sm and sm.has_method("get_card_level"):
		return sm.get_card_level(card_id)
	return 1

func _get_plus(card_id: String) -> int:
	var sm := _save_mgr()
	if sm and sm.has_method("get_card_plus"):
		return sm.get_card_plus(card_id)
	return 0

# ──────────────────────────────────────────────
# 全介面建立（只呼叫一次）
# ──────────────────────────────────────────────
func _build_ui() -> void:
	# 全黑背景
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.09)
	bg.size = Vector2(1080, 1920)
	bg.position = Vector2.ZERO
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# ── 頂部欄 y=0~120 ──
	var top_bar := ColorRect.new()
	top_bar.color = Color(0.10, 0.10, 0.16)
	top_bar.size = Vector2(1080, 120)
	top_bar.position = Vector2.ZERO
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_bar)

	var title := _make_label("我的卡牌", 44, Color(1.0, 0.85, 0.3))
	title.position = Vector2(40, 32)
	add_child(title)

	var close_btn := _make_button("X", 36)
	close_btn.size = Vector2(80, 80)
	close_btn.position = Vector2(980, 20)
	close_btn.pressed.connect(_on_close)
	add_child(close_btn)

	# ── 陣容區 y=120~440 ──
	_squad_panel = Control.new()
	_squad_panel.size = Vector2(1080, 320)
	_squad_panel.position = Vector2(0, 120)
	add_child(_squad_panel)
	_refresh_squad_panel()

	# ── 分隔線 + 提示 y=440~490 ──
	var sep := ColorRect.new()
	sep.color = Color(0.30, 0.30, 0.40)
	sep.size = Vector2(1080, 2)
	sep.position = Vector2(0, 440)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep)

	var hint := _make_label("點擊下方卡片替換選中槽位", 24, Color(0.70, 0.90, 0.70))
	hint.position = Vector2(40, 448)
	hint.size = Vector2(1000, 40)
	add_child(hint)

	# ── 卡片列表 ScrollContainer y=490~1830 ──
	_scroll = ScrollContainer.new()
	_scroll.size = Vector2(1080, 1340)
	_scroll.position = Vector2(0, 490)
	add_child(_scroll)

	_card_list_container = Control.new()
	_card_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_card_list_container)
	_refresh_card_list()

	# ── 確認陣容按鈕 y=1850 ──
	var confirm_btn := _make_button("確認陣容", 32)
	confirm_btn.name = "ConfirmBtn"
	confirm_btn.size = Vector2(900, 80)
	confirm_btn.position = Vector2(90, 1830)
	confirm_btn.modulate = Color(0.4, 1.0, 0.5)
	confirm_btn.pressed.connect(_on_confirm_squad)
	add_child(confirm_btn)

# ──────────────────────────────────────────────
# 陣容區刷新
# ──────────────────────────────────────────────
func _refresh_squad_panel() -> void:
	for child in _squad_panel.get_children():
		child.queue_free()

	var labels := ["盾兵", "突擊", "醫療", "狙擊"]
	for i in 4:
		var x := 20 + i * 260
		var slot_card_id: String = _current_squad[i] if i < _current_squad.size() else ""
		var card_info: Dictionary = _cards.get(slot_card_id, {})

		# 槽位底色
		var slot_bg := ColorRect.new()
		slot_bg.size = Vector2(240, 290)
		slot_bg.position = Vector2(x, 10)
		var grade: String = card_info.get("grade", "")
		slot_bg.color = GRADE_BG.get(grade, Color(0.12, 0.14, 0.20))
		slot_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_squad_panel.add_child(slot_bg)

		# 肖像（若有）
		var portrait_path: String = card_info.get("portrait_path", "")
		if portrait_path != "" and ResourceLoader.exists(portrait_path):
			var portrait := TextureRect.new()
			portrait.texture = load(portrait_path)
			portrait.size = Vector2(220, 200)
			portrait.position = Vector2(x + 10, 20)
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_squad_panel.add_child(portrait)

		# 槽位名稱（兵種）
		var slot_lbl := _make_label(labels[i], 20, Color(0.80, 0.80, 0.85))
		slot_lbl.position = Vector2(x + 10, 225)
		slot_lbl.size = Vector2(220, 30)
		_squad_panel.add_child(slot_lbl)

		# 卡牌名稱（若已填）
		if slot_card_id != "":
			var name_lbl := _make_label(card_info.get("name", slot_card_id), 18, Color(1.0, 1.0, 1.0))
			name_lbl.position = Vector2(x + 10, 252)
			name_lbl.size = Vector2(220, 28)
			_squad_panel.add_child(name_lbl)
		else:
			var empty_lbl := _make_label("(空)", 18, Color(0.5, 0.5, 0.55))
			empty_lbl.position = Vector2(x + 10, 252)
			_squad_panel.add_child(empty_lbl)

		# 橘色高亮邊框（選中槽位）
		if i == _selected_slot:
			_draw_border(_squad_panel, Vector2(x, 10), Vector2(240, 290), Color(1.0, 0.55, 0.10), 5)

		# 點擊按鈕（覆蓋整個槽位）
		var slot_btn := Button.new()
		slot_btn.flat = true
		slot_btn.size = Vector2(240, 290)
		slot_btn.position = Vector2(x, 10)
		slot_btn.modulate = Color(1, 1, 1, 0)
		var captured_i := i
		slot_btn.pressed.connect(func(): _on_slot_tapped(captured_i))
		_squad_panel.add_child(slot_btn)

# ──────────────────────────────────────────────
# 卡片列表刷新
# ──────────────────────────────────────────────
func _refresh_card_list() -> void:
	for child in _card_list_container.get_children():
		child.queue_free()

	_rebuild_owned_list()

	var cols := 3
	var card_w := 320
	var card_h := 480
	var pad_x := 40
	var pad_y := 20
	var total_rows := int(ceil(float(_owned_list.size()) / cols))
	var total_height := total_rows * (card_h + pad_y) + pad_y

	_card_list_container.custom_minimum_size = Vector2(1080, max(total_height, 100))

	for idx in _owned_list.size():
		var card_id: String = _owned_list[idx]
		var col := idx % cols
		var row := idx / cols
		var card_x := pad_x / 2 + col * (card_w + (1080 - cols * card_w) / (cols + 1))
		var card_y := pad_y + row * (card_h + pad_y)
		var card_slot := _build_card_slot(card_id, card_x, card_y)
		_card_list_container.add_child(card_slot)

# ──────────────────────────────────────────────
# 完整刷新（陣容 + 卡片列表）
# ──────────────────────────────────────────────
func _full_refresh() -> void:
	_refresh_squad_panel()
	_refresh_card_list()

# ──────────────────────────────────────────────
# 單張卡片建立
# ──────────────────────────────────────────────
func _build_card_slot(card_id: String, pos_x: float, pos_y: float) -> Control:
	var card_info: Dictionary = _cards.get(card_id, {})
	var grade: String = card_info.get("grade", "R")
	var lv: int = _get_level(card_id)
	var plus: int = _get_plus(card_id)
	var is_in_squad: bool = card_id in _current_squad

	var w := 320
	var h := 480

	var slot := Control.new()
	slot.custom_minimum_size = Vector2(w, h)
	slot.position = Vector2(pos_x, pos_y)

	# 稀有度底色
	var card_bg := ColorRect.new()
	card_bg.size = Vector2(w - 10, h - 10)
	card_bg.position = Vector2(5, 5)
	card_bg.color = GRADE_BG.get(grade, Color(0.10, 0.10, 0.15))
	card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(card_bg)

	# 稀有度邊框（細框）
	var border_style := StyleBoxFlat.new()
	border_style.bg_color = Color(0, 0, 0, 0)
	border_style.border_color = GRADE_BORDER.get(grade, Color(0.3, 0.3, 0.35))
	border_style.set_border_width_all(3)
	border_style.set_corner_radius_all(4)
	var border_panel := Panel.new()
	border_panel.size = Vector2(w - 10, h - 10)
	border_panel.position = Vector2(5, 5)
	border_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border_panel.add_theme_stylebox_override("panel", border_style)
	slot.add_child(border_panel)

	# 肖像 SVG（若有）
	var portrait_path: String = card_info.get("portrait_path", "")
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		var portrait := TextureRect.new()
		portrait.texture = load(portrait_path)
		portrait.size = Vector2(w - 20, 290)
		portrait.position = Vector2(10, 10)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(portrait)

	# 兵種名稱 + 等級
	var card_name: String = card_info.get("name", card_id)
	var name_lbl := _make_label(card_name, 22, Color(1.0, 1.0, 1.0))
	name_lbl.position = Vector2(10, 308)
	name_lbl.size = Vector2(w - 20, 30)
	slot.add_child(name_lbl)

	var lv_lbl := _make_label("Lv.%d" % lv, 20, Color(0.70, 1.0, 0.70))
	lv_lbl.position = Vector2(10, 338)
	lv_lbl.size = Vector2(120, 28)
	slot.add_child(lv_lbl)

	# 出戰中：綠色邊框
	if is_in_squad:
		_draw_border(slot, Vector2(0, 0), Vector2(w, h), Color(0.2, 1.0, 0.3, 0.9), 5)

	# +N badge（金色大字，plus > 0 時顯示）
	if plus > 0:
		var plus_bg := ColorRect.new()
		plus_bg.size = Vector2(70, 40)
		plus_bg.position = Vector2(w - 80, 330)
		plus_bg.color = Color(0.55, 0.35, 0.0, 0.92)
		plus_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(plus_bg)

		var plus_lbl := _make_label("+%d" % plus, 30, Color(1.0, 0.92, 0.10))
		plus_lbl.size = Vector2(70, 40)
		plus_lbl.position = Vector2(w - 80, 330)
		plus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(plus_lbl)

	# 升Lv 按鈕
	var upgrade_cost := lv * 50
	var upgrade_btn: Button
	if lv >= MAX_LEVEL:
		upgrade_btn = _make_button("MAX", 18)
		upgrade_btn.disabled = true
	else:
		upgrade_btn = _make_button("升Lv（%d金）" % upgrade_cost, 18)
		var c_id := card_id
		var c_cost := upgrade_cost
		upgrade_btn.pressed.connect(func():
			var sm := _save_mgr()
			if sm and sm.has_method("upgrade_card"):
				if sm.upgrade_card(c_id, c_cost):
					_full_refresh()
		)
	upgrade_btn.size = Vector2(w - 10, 52)
	upgrade_btn.position = Vector2(5, 418)
	slot.add_child(upgrade_btn)

	# 透明點擊層（覆蓋卡面，不含升級按鈕）
	var hit_btn := Button.new()
	hit_btn.flat = true
	hit_btn.size = Vector2(w, 415)
	hit_btn.position = Vector2(0, 0)
	hit_btn.modulate = Color(1, 1, 1, 0)
	var c_id2 := card_id
	hit_btn.pressed.connect(func(): _on_card_tapped(c_id2))
	slot.add_child(hit_btn)

	return slot

# ──────────────────────────────────────────────
# 互動處理
# ──────────────────────────────────────────────
func _on_slot_tapped(slot_idx: int) -> void:
	if _selected_slot == slot_idx:
		_selected_slot = -1  # 取消選中
	else:
		_selected_slot = slot_idx
	_refresh_squad_panel()

func _on_card_tapped(card_id: String) -> void:
	if _selected_slot < 0:
		# 無選中槽位：自動選第一個
		_selected_slot = 0
	# 換入選中槽位
	if _selected_slot < _current_squad.size():
		_current_squad[_selected_slot] = card_id
	# 自動移到下一個槽位
	_selected_slot = (_selected_slot + 1) % 4
	_full_refresh()

func _on_confirm_squad() -> void:
	var sm := _save_mgr()
	if sm and sm.has_method("set_selected_squad"):
		sm.set_selected_squad(_current_squad)
	emit_signal("gallery_closed")
	queue_free()

func _on_close() -> void:
	emit_signal("gallery_closed")
	queue_free()

# ──────────────────────────────────────────────
# 輔助函式
# ──────────────────────────────────────────────
func _make_label(text_str: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var lbl := Label.new()
	lbl.text = text_str
	lbl.modulate = color
	lbl.add_theme_font_size_override("font_size", font_size)
	if _font:
		lbl.add_theme_font_override("font", _font)
	return lbl

func _make_button(text_str: String, font_size: int) -> Button:
	var btn := Button.new()
	btn.text = text_str
	btn.add_theme_font_size_override("font_size", font_size)
	if _font:
		btn.add_theme_font_override("font", _font)
	return btn

func _draw_border(parent: Control, pos: Vector2, size: Vector2, color: Color, thickness: int) -> void:
	var borders := [
		[pos,                              Vector2(size.x, thickness)],
		[pos + Vector2(0, size.y - thickness), Vector2(size.x, thickness)],
		[pos,                              Vector2(thickness, size.y)],
		[pos + Vector2(size.x - thickness, 0), Vector2(thickness, size.y)]
	]
	for bd in borders:
		var cr := ColorRect.new()
		cr.position = bd[0]
		cr.size = bd[1]
		cr.color = color
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(cr)
