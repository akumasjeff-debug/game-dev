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
	row.custom_minimum_size = Vector2(950, 160)
	row.color = Color(0.07, 0.09, 0.12, 0.95)

	# 等級色條
	var bar = ColorRect.new()
	bar.size = Vector2(6, 160)
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
	lv_lbl.position = Vector2(86, 50)
	if _font:
		lv_lbl.add_theme_font_override("font", _font)
	lv_lbl.add_theme_font_size_override("font_size", 20)
	lv_lbl.modulate = Color(0.6, 1.0, 0.6)
	row.add_child(lv_lbl)

	var plus_lbl = Label.new()
	plus_lbl.text = "+%d" % plus if plus > 0 else ""
	plus_lbl.position = Vector2(220, 50)
	if _font:
		plus_lbl.add_theme_font_override("font", _font)
	plus_lbl.add_theme_font_size_override("font_size", 20)
	plus_lbl.modulate = Color(1.0, 0.85, 0.2)
	row.add_child(plus_lbl)

	# 數值
	var stats_lbl = Label.new()
	stats_lbl.text = "HP %d　ATK %d　DEF %d" % [real_hp, real_atk, real_def]
	stats_lbl.position = Vector2(86, 80)
	if _font:
		stats_lbl.add_theme_font_override("font", _font)
	stats_lbl.add_theme_font_size_override("font_size", 18)
	stats_lbl.modulate = Color(0.75, 0.95, 0.75)
	row.add_child(stats_lbl)

	# 升等後預覽
	if lv < MAX_LEVEL:
		var next_lv_mult   = 1.0 + lv * 0.05
		var next_hp  = int(base_hp  * next_lv_mult * plus_mult)
		var next_atk = int(base_atk * next_lv_mult * plus_mult)
		var next_def = int(base_def * next_lv_mult * plus_mult)
		var preview_lbl = Label.new()
		preview_lbl.text = "→ HP %d　ATK %d　DEF %d" % [next_hp, next_atk, next_def]
		preview_lbl.position = Vector2(86, 108)
		if _font:
			preview_lbl.add_theme_font_override("font", _font)
		preview_lbl.add_theme_font_size_override("font_size", 16)
		preview_lbl.modulate = Color(0.5, 0.75, 1.0, 0.8)
		row.add_child(preview_lbl)

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
	btn.position = Vector2(640, 30)
	btn.custom_minimum_size = Vector2(290, 70)
	if _font:
		btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(_on_upgrade.bind(card_id, cost))
	row.add_child(btn)

	return row

func _on_upgrade(card_id: String, cost: int) -> void:
	AudioManager.play_sfx("btn_click")
	if SaveManager.upgrade_card(card_id, cost):
		_rebuild_list()

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
