extends CanvasLayer

# 升級管理面板 — 新 TCG 卡牌系統（v0.4.0）
# 顯示所有持有卡片，支援金幣升等，廢除舊稀有度提升系統

const MAX_LEVEL = 20

const GRADE_COLORS = {
	"R":   Color(0.27, 0.53, 0.80),
	"SR":  Color(0.60, 0.40, 0.80),
	"SSR": Color(0.85, 0.70, 0.10),
	"QR":  Color(0.85, 0.20, 0.20),
}

const GRADE_ORDER = {"R": 0, "SR": 1, "SSR": 2, "QR": 3}

var _cards_data: Array = []
var _list_container: VBoxContainer
var _font: Font

func _ready() -> void:
	layer = 16
	_font = load("res://resources/fonts/chinese_font.ttf")
	_cards_data = _load_cards_json()
	_build_ui()

func _load_cards_json() -> Array:
	var path = "res://resources/data/cards.json"
	if not ResourceLoader.exists(path):
		return []
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return []
	var data = json.get_data()
	if data is Dictionary and data.has("cards"):
		return data["cards"]
	if data is Array:
		return data
	return []

func _get_card_data(card_id: String) -> Dictionary:
	for cd in _cards_data:
		if cd.get("id", "") == card_id:
			return cd
	return {}

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.0, 0.0, 0.0, 0.92)
	add_child(bg)

	var panel = ColorRect.new()
	panel.position = Vector2(30, 60)
	panel.size = Vector2(1020, 1800)
	panel.color = Color(0.04, 0.06, 0.09, 0.97)
	add_child(panel)

	var title = Label.new()
	title.text = "升級管理"
	title.position = Vector2(380, 80)
	if _font:
		title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 38)
	title.modulate = Color(1.0, 0.88, 0.25)
	add_child(title)

	var sep = ColorRect.new()
	sep.position = Vector2(50, 140)
	sep.size = Vector2(980, 2)
	sep.color = Color(0.5, 0.4, 0.1, 0.7)
	add_child(sep)

	var coins_lbl = Label.new()
	coins_lbl.name = "CoinsLabel"
	coins_lbl.position = Vector2(60, 155)
	if _font:
		coins_lbl.add_theme_font_override("font", _font)
	coins_lbl.add_theme_font_size_override("font_size", 24)
	coins_lbl.modulate = Color(1.0, 0.88, 0.25)
	add_child(coins_lbl)

	var hint_lbl = Label.new()
	hint_lbl.position = Vector2(400, 160)
	hint_lbl.text = "升等費用 = 目前等級 × 50 金"
	if _font:
		hint_lbl.add_theme_font_override("font", _font)
	hint_lbl.add_theme_font_size_override("font_size", 18)
	hint_lbl.modulate = Color(0.6, 0.7, 0.6)
	add_child(hint_lbl)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(50, 200)
	scroll.size = Vector2(980, 1500)
	add_child(scroll)

	_list_container = VBoxContainer.new()
	_list_container.custom_minimum_size = Vector2(960, 0)
	_list_container.add_theme_constant_override("separation", 10)
	scroll.add_child(_list_container)

	var close_btn = Button.new()
	close_btn.text = "關閉"
	close_btn.position = Vector2(340, 1725)
	close_btn.custom_minimum_size = Vector2(400, 75)
	if _font:
		close_btn.add_theme_font_override("font", _font)
	close_btn.add_theme_font_size_override("font_size", 28)
	_style_button(close_btn, Color(0.28, 0.08, 0.08))
	close_btn.pressed.connect(_on_close)
	add_child(close_btn)

	_rebuild_list()

func _rebuild_list() -> void:
	var coins_lbl = find_child("CoinsLabel", true, false)
	if coins_lbl:
		coins_lbl.text = "目前金幣：" + str(SaveManager.coins)

	for child in _list_container.get_children():
		child.queue_free()

	# 收集並排序：QR > SSR > SR > R，同等級按 class 字母排
	var owned_ids: Array = SaveManager.owned_cards.keys()
	owned_ids.sort_custom(func(a, b):
		var cd_a = _get_card_data(a)
		var cd_b = _get_card_data(b)
		var ga = GRADE_ORDER.get(cd_a.get("grade", "R"), 0)
		var gb = GRADE_ORDER.get(cd_b.get("grade", "R"), 0)
		if ga != gb:
			return ga > gb
		return a < b
	)

	for card_id in owned_ids:
		var row = _build_card_row(card_id)
		_list_container.add_child(row)

func _build_card_row(card_id: String) -> Control:
	var cd = _get_card_data(card_id)
	var grade = cd.get("grade", "R")
	var grade_color = GRADE_COLORS.get(grade, Color.WHITE)
	var card_name = cd.get("name", card_id)
	var base_hp  = float(cd.get("base_hp",  100))
	var base_atk = float(cd.get("base_atk", 30))
	var base_def = float(cd.get("base_def", 10))

	var lv   = SaveManager.get_card_level(card_id)
	var plus = SaveManager.get_card_plus(card_id)
	var cost = lv * 50
	var can_upgrade = lv < MAX_LEVEL and SaveManager.coins >= cost

	# 計算當前數值
	var lv_mult   = 1.0 + (lv - 1) * 0.05
	var plus_mult = 1.0 + plus * 0.03
	var real_hp  = int(base_hp  * lv_mult * plus_mult)
	var real_atk = int(base_atk * lv_mult * plus_mult)
	var real_def = int(base_def * lv_mult * plus_mult)

	var row = ColorRect.new()
	row.custom_minimum_size = Vector2(950, 184)
	row.color = Color(0.07, 0.09, 0.12, 0.95)

	# 細邊框（稀有度色）
	var row_frame = Panel.new()
	row_frame.size = Vector2(950, 184)
	row_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rf_style = StyleBoxFlat.new()
	rf_style.bg_color = Color(0, 0, 0, 0)
	rf_style.border_color = Color(grade_color.r, grade_color.g, grade_color.b, 0.35)
	rf_style.set_border_width_all(1)
	rf_style.set_corner_radius_all(8)
	row_frame.add_theme_stylebox_override("panel", rf_style)
	row.add_child(row_frame)

	# 等級色條
	var bar = ColorRect.new()
	bar.size = Vector2(6, 184)
	bar.color = grade_color
	row.add_child(bar)

	# 等級 badge
	var grade_bg = ColorRect.new()
	grade_bg.position = Vector2(14, 10)
	grade_bg.size = Vector2(64, 32)
	grade_bg.color = Color(grade_color.r * 0.3, grade_color.g * 0.3, grade_color.b * 0.3, 0.9)
	row.add_child(grade_bg)
	var grade_lbl = Label.new()
	grade_lbl.text = grade
	grade_lbl.position = Vector2(14, 11)
	grade_lbl.size = Vector2(64, 30)
	grade_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font:
		grade_lbl.add_theme_font_override("font", _font)
	grade_lbl.add_theme_font_size_override("font_size", 18)
	grade_lbl.modulate = grade_color
	row.add_child(grade_lbl)

	# 卡名
	var name_lbl = Label.new()
	name_lbl.text = card_name
	name_lbl.position = Vector2(86, 10)
	if _font:
		name_lbl.add_theme_font_override("font", _font)
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.modulate = grade_color
	row.add_child(name_lbl)

	# Lv 與 + 值
	var lv_lbl = Label.new()
	lv_lbl.text = "Lv.%d / %d" % [lv, MAX_LEVEL]
	lv_lbl.position = Vector2(86, 48)
	if _font:
		lv_lbl.add_theme_font_override("font", _font)
	lv_lbl.add_theme_font_size_override("font_size", 20)
	lv_lbl.modulate = Color(0.6, 1.0, 0.6)
	row.add_child(lv_lbl)

	var plus_lbl = Label.new()
	plus_lbl.text = "+%d" % plus if plus > 0 else ""
	plus_lbl.position = Vector2(220, 48)
	if _font:
		plus_lbl.add_theme_font_override("font", _font)
	plus_lbl.add_theme_font_size_override("font_size", 20)
	plus_lbl.modulate = Color(1.0, 0.85, 0.2)
	row.add_child(plus_lbl)

	# 等級進度條（視覺化成長度）
	var bar_bg = ColorRect.new()
	bar_bg.position = Vector2(86, 80)
	bar_bg.size = Vector2(500, 10)
	bar_bg.color = Color(0.04, 0.05, 0.07, 0.9)
	row.add_child(bar_bg)
	var fill_ratio = float(lv) / float(MAX_LEVEL)
	var bar_fill = ColorRect.new()
	bar_fill.position = Vector2(86, 80)
	bar_fill.size = Vector2(500 * fill_ratio, 10)
	bar_fill.color = grade_color
	row.add_child(bar_fill)
	# 進度條外框
	var bar_frame = Panel.new()
	bar_frame.position = Vector2(86, 80)
	bar_frame.size = Vector2(500, 10)
	bar_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bfs = StyleBoxFlat.new()
	bfs.bg_color = Color(0, 0, 0, 0)
	bfs.border_color = Color(grade_color.r, grade_color.g, grade_color.b, 0.5)
	bfs.set_border_width_all(1)
	bfs.set_corner_radius_all(5)
	bar_frame.add_theme_stylebox_override("panel", bfs)
	row.add_child(bar_frame)

	# 目前數值（含圖示色塊）
	_add_stat_chip(row, Vector2(86, 102), "HP", real_hp, Color(0.45, 1.0, 0.55))
	_add_stat_chip(row, Vector2(266, 102), "ATK", real_atk, Color(1.0, 0.55, 0.45))
	_add_stat_chip(row, Vector2(446, 102), "DEF", real_def, Color(0.55, 0.78, 1.0))

	# 升等後預覽（顯示增量 +N，綠色）
	if lv < MAX_LEVEL:
		var next_lv_mult   = 1.0 + lv * 0.05
		var next_hp  = int(base_hp  * next_lv_mult * plus_mult)
		var next_atk = int(base_atk * next_lv_mult * plus_mult)
		var next_def = int(base_def * next_lv_mult * plus_mult)
		var arrow = Label.new()
		arrow.text = "升級後"
		arrow.position = Vector2(86, 142)
		if _font:
			arrow.add_theme_font_override("font", _font)
		arrow.add_theme_font_size_override("font_size", 16)
		arrow.modulate = Color(0.55, 0.70, 0.55)
		row.add_child(arrow)
		_add_delta_chip(row, Vector2(180, 140), "HP", next_hp - real_hp, Color(0.45, 1.0, 0.55))
		_add_delta_chip(row, Vector2(330, 140), "ATK", next_atk - real_atk, Color(1.0, 0.6, 0.5))
		_add_delta_chip(row, Vector2(460, 140), "DEF", next_def - real_def, Color(0.55, 0.78, 1.0))

	# 升等按鈕
	var btn = Button.new()
	if lv >= MAX_LEVEL:
		btn.text = "等級已滿"
		btn.disabled = true
		_style_button(btn, Color(0.2, 0.2, 0.1))
	elif SaveManager.coins < cost:
		btn.text = "升等 %d金（不足）" % cost
		btn.disabled = true
		_style_button(btn, Color(0.15, 0.12, 0.08))
	else:
		btn.text = "升等 %d金" % cost
		btn.disabled = false
		_style_button(btn, Color(0.35, 0.25, 0.0))
	btn.position = Vector2(640, 56)
	btn.custom_minimum_size = Vector2(290, 80)
	btn.size = Vector2(290, 80)
	if _font:
		btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(_on_upgrade.bind(card_id, cost))
	row.add_child(btn)

	return row

# 數值小標籤：名稱（小、灰）+ 數值（大、彩）
func _add_stat_chip(row: Control, pos: Vector2, name_txt: String, value: int, col: Color) -> void:
	var n = Label.new()
	n.text = name_txt
	n.position = pos
	if _font:
		n.add_theme_font_override("font", _font)
	n.add_theme_font_size_override("font_size", 15)
	n.modulate = Color(0.55, 0.6, 0.65)
	row.add_child(n)
	var v = Label.new()
	v.text = str(value)
	v.position = Vector2(pos.x + 44, pos.y - 2)
	if _font:
		v.add_theme_font_override("font", _font)
	v.add_theme_font_size_override("font_size", 20)
	v.modulate = col
	row.add_child(v)

# 增量標籤：+N（綠正/灰零）
func _add_delta_chip(row: Control, pos: Vector2, name_txt: String, delta: int, col: Color) -> void:
	var lbl = Label.new()
	if delta > 0:
		lbl.text = "%s +%d" % [name_txt, delta]
		lbl.modulate = Color(0.4, 1.0, 0.5)
	else:
		lbl.text = "%s +0" % name_txt
		lbl.modulate = Color(0.5, 0.5, 0.5)
	lbl.position = pos
	if _font:
		lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 16)
	row.add_child(lbl)

func _on_upgrade(card_id: String, cost: int) -> void:
	AudioManager.play_sfx("btn_click")
	if SaveManager.upgrade_card(card_id, cost):
		_show_upgrade_feedback(cost)
		_rebuild_list()

# 升級成功回饋：中央飄出「升級！」+ 金幣扣除飄字
func _show_upgrade_feedback(cost: int) -> void:
	var lbl = Label.new()
	lbl.text = "升級成功！"
	lbl.add_theme_font_size_override("font_size", 44)
	if _font:
		lbl.add_theme_font_override("font", _font)
	lbl.modulate = Color(0.5, 1.0, 0.6, 0.0)
	lbl.position = Vector2(0, 860)
	lbl.size = Vector2(1080, 70)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(lbl)
	var tw = create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(lbl, "position:y", 800.0, 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.3)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.35)
	tw.tween_callback(lbl.queue_free)

	# 金幣消耗飄字（靠近金幣標籤）
	var cost_lbl = Label.new()
	cost_lbl.text = "-%d" % cost
	cost_lbl.add_theme_font_size_override("font_size", 26)
	if _font:
		cost_lbl.add_theme_font_override("font", _font)
	cost_lbl.modulate = Color(1.0, 0.5, 0.3, 1.0)
	cost_lbl.position = Vector2(250, 155)
	add_child(cost_lbl)
	var ct = create_tween()
	ct.tween_property(cost_lbl, "position:y", 120.0, 0.6).set_ease(Tween.EASE_OUT)
	ct.parallel().tween_property(cost_lbl, "modulate:a", 0.0, 0.6)
	ct.tween_callback(cost_lbl.queue_free)

func _on_close() -> void:
	AudioManager.play_sfx("btn_click")
	queue_free()

func _style_button(btn: Button, bg: Color) -> void:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = Color(bg.r + 0.2, bg.g + 0.2, bg.b + 0.2, 0.8)
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", s)
	var h = StyleBoxFlat.new()
	h.bg_color = Color(bg.r + 0.12, bg.g + 0.12, bg.b + 0.12)
	h.border_color = Color(bg.r + 0.3, bg.g + 0.3, bg.b + 0.3, 0.9)
	h.set_border_width_all(2)
	h.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", h)
