extends CanvasLayer

# 招募中心面板 — 聚光燈揭示抽卡動畫
# 掛在 GachaPanel.tscn (CanvasLayer layer=15)

signal panel_closed

var _cards_json: Dictionary = {}
var _gacha_config: Dictionary = {}

func _ready() -> void:
	layer = 15
	_load_data()
	_build_ui()

# ─────────────────────────────────────────
#  資料載入
# ─────────────────────────────────────────

func _load_data() -> void:
	var cf = FileAccess.open("res://resources/data/cards.json", FileAccess.READ)
	if cf:
		var raw = JSON.parse_string(cf.get_as_text())
		cf.close()
		if raw is Dictionary and raw.has("cards"):
			for c in raw["cards"]:
				if c is Dictionary and c.has("id"):
					_cards_json[c["id"]] = c
		elif raw is Array:
			for c in raw:
				if c is Dictionary and c.has("id"):
					_cards_json[c["id"]] = c

	var gc = FileAccess.open("res://resources/data/gacha_config.json", FileAccess.READ)
	if gc:
		var raw = JSON.parse_string(gc.get_as_text())
		gc.close()
		if raw is Dictionary:
			_gacha_config = raw

# ─────────────────────────────────────────
#  UI 建構
# ─────────────────────────────────────────

func _build_ui() -> void:
	# 黑色底層遮罩
	var overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0.0, 0.0, 0.0, 0.92)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)

	# 標題
	var title = Label.new()
	title.name = "Title"
	title.text = "招募中心"
	title.add_theme_font_size_override("font_size", 48)
	title.modulate = Color(1.0, 0.85, 0.3)
	title.position = Vector2(0, 60)
	title.size = Vector2(1080, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# 關閉按鈕（右上角）
	var close_btn = Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(80, 80)
	close_btn.position = Vector2(970, 30)
	close_btn.add_theme_font_size_override("font_size", 32)
	_style_button(close_btn, Color(0.35, 0.08, 0.08))
	close_btn.pressed.connect(_on_close)
	add_child(close_btn)

	# 金幣顯示
	var coins_lbl = Label.new()
	coins_lbl.name = "CoinsLabel"
	coins_lbl.text = "金幣：%d" % SaveManager.coins
	coins_lbl.add_theme_font_size_override("font_size", 30)
	coins_lbl.modulate = Color(1.0, 0.85, 0.3)
	coins_lbl.position = Vector2(40, 160)
	add_child(coins_lbl)

	# 機率說明
	_build_pool_info()

	# 抽卡按鈕
	var btn_single = Button.new()
	btn_single.name = "BtnSingle"
	btn_single.text = "單抽（100 金幣）"
	btn_single.custom_minimum_size = Vector2(430, 90)
	btn_single.position = Vector2(40, 1790)
	btn_single.add_theme_font_size_override("font_size", 28)
	_style_button(btn_single, Color(0.12, 0.18, 0.38))
	btn_single.pressed.connect(func(): _do_pull(1))
	add_child(btn_single)

	var btn_ten = Button.new()
	btn_ten.name = "BtnTen"
	btn_ten.text = "十連（900 金幣）"
	btn_ten.custom_minimum_size = Vector2(430, 90)
	btn_ten.position = Vector2(610, 1790)
	btn_ten.add_theme_font_size_override("font_size", 28)
	_style_button(btn_ten, Color(0.30, 0.20, 0.0))
	btn_ten.pressed.connect(func(): _do_pull(10))
	add_child(btn_ten)

	# 新手10連按鈕（未領取時顯示）
	if not SaveManager.starter_claimed:
		var btn_starter = Button.new()
		btn_starter.name = "StarterBtn"
		btn_starter.text = "新手 10 連（免費）"
		btn_starter.custom_minimum_size = Vector2(900, 90)
		btn_starter.position = Vector2(90, 1690)
		btn_starter.add_theme_font_size_override("font_size", 30)
		_style_button(btn_starter, Color(0.08, 0.35, 0.10))
		btn_starter.modulate = Color(0.4, 1.0, 0.55)
		btn_starter.pressed.connect(_do_starter_pull)
		add_child(btn_starter)

func _build_pool_info() -> void:
	var rates = _gacha_config.get("rates", {"R": 0.75, "SR": 0.18, "SSR": 0.06, "QR": 0.01})
	var rate_lbl = Label.new()
	rate_lbl.name = "RateInfo"
	rate_lbl.text = "機率：R %.0f%%  SR %.0f%%  SSR %.0f%%  QR %.0f%%" % [
		rates.get("R", 0.75) * 100,
		rates.get("SR", 0.18) * 100,
		rates.get("SSR", 0.06) * 100,
		rates.get("QR", 0.01) * 100
	]
	rate_lbl.add_theme_font_size_override("font_size", 24)
	rate_lbl.modulate = Color(0.75, 0.75, 0.75)
	rate_lbl.position = Vector2(40, 210)
	rate_lbl.size = Vector2(1000, 40)
	add_child(rate_lbl)

	var pity_lbl = Label.new()
	pity_lbl.name = "PityInfo"
	pity_lbl.text = "保底：10 抽 SR ／ 50 抽 SSR ／ 100 抽 QR"
	pity_lbl.add_theme_font_size_override("font_size", 22)
	pity_lbl.modulate = Color(0.6, 0.6, 0.85)
	pity_lbl.position = Vector2(40, 248)
	pity_lbl.size = Vector2(1000, 36)
	add_child(pity_lbl)

# ─────────────────────────────────────────
#  抽卡邏輯
# ─────────────────────────────────────────

func _do_starter_pull() -> void:
	if SaveManager.starter_claimed:
		return
	var results = SaveManager.claim_starter_pulls()
	var starter_btn = get_node_or_null("StarterBtn")
	if starter_btn:
		starter_btn.queue_free()
	_show_pull_results(results)

func _do_pull(count: int) -> void:
	var cost = 100 if count == 1 else 900
	if SaveManager.coins < cost:
		_show_no_coins()
		return

	SaveManager.coins -= cost
	SaveManager.save_game()
	_refresh_coins_label()

	# 執行抽卡並立刻 add_card（記錄結果供顯示用）
	var card_ids: Array = []
	for i in range(count):
		var force_sr = (i == count - 1 and count == 10)
		var card_id = SaveManager._do_single_pull(force_sr)
		card_ids.append(card_id)
		var max_plus = _get_max_plus(card_id)
		SaveManager.add_card(card_id, max_plus)

	SaveManager.save_game()
	_show_pull_results(card_ids)

func _get_max_plus(card_id: String) -> int:
	if _cards_json.has(card_id):
		return _cards_json[card_id].get("max_plus", 3)
	return SaveManager._get_max_plus(card_id)

func _refresh_coins_label() -> void:
	var lbl = get_node_or_null("CoinsLabel")
	if lbl:
		lbl.text = "金幣：%d" % SaveManager.coins

# ─────────────────────────────────────────
#  揭示動畫主入口
# ─────────────────────────────────────────

func _show_pull_results(card_ids: Array) -> void:
	# 移除前一輪結果節點
	_clear_result_nodes()

	if card_ids.is_empty():
		return

	if card_ids.size() == 1:
		_show_single_spotlight(card_ids[0])
	else:
		_show_multi_result(card_ids)

func _clear_result_nodes() -> void:
	for child in get_children():
		if child.name.begins_with("RC_"):
			child.queue_free()

# ─────────────────────────────────────────
#  單抽：聚光燈揭示
# ─────────────────────────────────────────

func _show_single_spotlight(card_id: String) -> void:
	var card_info = _cards_json.get(card_id, {})
	var grade = card_info.get("grade", "R")

	# 聚光燈光束（梯形近似 — 全高寬帶漸層）
	var light_colors = {
		"R":   Color(0.27, 0.53, 0.80, 0.28),
		"SR":  Color(0.60, 0.20, 0.90, 0.32),
		"SSR": Color(0.90, 0.75, 0.00, 0.38),
		"QR":  Color(0.90, 0.20, 0.00, 0.44)
	}
	var light = ColorRect.new()
	light.name = "RC_Light"
	light.color = light_colors.get(grade, Color(0.5, 0.5, 0.5, 0.22))
	light.size = Vector2(420, 1100)
	light.position = Vector2(330, 0)
	light.modulate.a = 0.0
	add_child(light)

	# 輻射暈光（圓形柔邊 — 用較大 ColorRect 模擬）
	var glow = ColorRect.new()
	glow.name = "RC_Glow"
	glow.color = light_colors.get(grade, Color(0.5, 0.5, 0.5, 0.10))
	glow.color.a = 0.12
	glow.size = Vector2(700, 700)
	glow.position = Vector2(190, 550)
	glow.modulate.a = 0.0
	add_child(glow)

	# 卡片容器：從畫面下方滑入
	var card_container = Control.new()
	card_container.name = "RC_Main"
	card_container.size = Vector2(320, 480)
	card_container.position = Vector2(380, 1920)
	card_container.pivot_offset = Vector2(160, 240)
	add_child(card_container)
	_build_result_card(card_container, card_id, card_info, grade, 320, 480)

	# 動畫序列
	var tw = create_tween()
	tw.set_parallel(false)

	# 1. 光束淡入
	tw.tween_property(light, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(glow, "modulate:a", 1.0, 0.35)

	# 2. 卡片從下方滑入（Back Ease 彈跳）
	tw.tween_property(card_container, "position:y", 680.0, 0.40) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# 3. 輕微縮放彈動
	tw.tween_property(card_container, "scale", Vector2(1.06, 1.06), 0.10)
	tw.tween_property(card_container, "scale", Vector2(1.0, 1.0), 0.10)

	# SSR / QR 額外閃光
	if grade == "SSR" or grade == "QR":
		tw.tween_callback(func(): _play_grade_flash(card_container, grade))

# ─────────────────────────────────────────
#  十連：3×3 + 1 逐一淡入
# ─────────────────────────────────────────

func _show_multi_result(card_ids: Array) -> void:
	var count = card_ids.size()

	# 佈局：3 欄，每欄 3 張，最後一張（第 10 張）置中在最後一列
	var cols = 3
	var card_w = 230
	var card_h = 345
	var spacing_x = 45
	var spacing_y = 28
	var total_w = cols * card_w + (cols - 1) * spacing_x
	var start_x = (1080 - total_w) / 2
	var start_y = 285

	for i in range(count):
		var card_id = card_ids[i]
		var card_info = _cards_json.get(card_id, {})
		var grade = card_info.get("grade", "R")

		var col: int
		var row: int

		if i < 9:
			col = i % cols
			row = i / cols
		else:
			# 第 10 張置中
			col = 0
			row = 3
			# 水平置中計算
			var single_start_x = (1080 - card_w) / 2
			var slot = Control.new()
			slot.name = "RC_%d" % i
			slot.size = Vector2(card_w, card_h)
			slot.position = Vector2(single_start_x, start_y + row * (card_h + spacing_y))
			slot.modulate.a = 0.0
			slot.pivot_offset = Vector2(card_w / 2.0, card_h / 2.0)
			add_child(slot)
			_build_result_card(slot, card_id, card_info, grade, card_w, card_h)
			_tween_card_in(slot, i)
			continue

		var slot = Control.new()
		slot.name = "RC_%d" % i
		slot.size = Vector2(card_w, card_h)
		slot.position = Vector2(start_x + col * (card_w + spacing_x), start_y + row * (card_h + spacing_y))
		slot.modulate.a = 0.0
		slot.pivot_offset = Vector2(card_w / 2.0, card_h / 2.0)
		add_child(slot)
		_build_result_card(slot, card_id, card_info, grade, card_w, card_h)
		_tween_card_in(slot, i)

func _tween_card_in(slot: Control, index: int) -> void:
	var tw = create_tween()
	tw.tween_interval(index * 0.07)
	tw.tween_property(slot, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(slot, "scale", Vector2(1.0, 1.0), 0.18).from(Vector2(0.85, 0.85))

# ─────────────────────────────────────────
#  卡片節點建構
# ─────────────────────────────────────────

func _build_result_card(container: Control, card_id: String, card_info: Dictionary, grade: String, w: int, h: int) -> void:
	# 稀有度背景色（無圖框 SVG 時回退）
	var grade_colors = {
		"R":   Color(0.08, 0.16, 0.30),
		"SR":  Color(0.20, 0.08, 0.35),
		"SSR": Color(0.32, 0.25, 0.00),
		"QR":  Color(0.38, 0.06, 0.02)
	}
	var grade_border_colors = {
		"R":   Color(0.27, 0.53, 0.80),
		"SR":  Color(0.70, 0.40, 1.00),
		"SSR": Color(1.00, 0.85, 0.10),
		"QR":  Color(1.00, 0.35, 0.05)
	}

	# 嘗試載入卡框 SVG；否則用 ColorRect
	var frame_path = "res://resources/art/cards/card_frame_%s.svg" % grade.to_lower()
	if ResourceLoader.exists(frame_path):
		var frame = TextureRect.new()
		frame.texture = load(frame_path)
		frame.size = Vector2(w, h)
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		container.add_child(frame)
	else:
		var bg = ColorRect.new()
		bg.size = Vector2(w, h)
		bg.color = grade_colors.get(grade, Color(0.10, 0.10, 0.15))
		container.add_child(bg)

		# 稀有度色邊框
		var border = Panel.new()
		border.size = Vector2(w, h)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bp = StyleBoxFlat.new()
		bp.bg_color = Color(0, 0, 0, 0)
		bp.border_color = grade_border_colors.get(grade, Color(0.3, 0.3, 0.4))
		bp.set_border_width_all(3)
		bp.set_corner_radius_all(6)
		border.add_theme_stylebox_override("panel", bp)
		container.add_child(border)

	# 角色肖像
	var portrait_path = card_info.get("portrait_path", "")
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		var portrait = TextureRect.new()
		portrait.texture = load(portrait_path)
		portrait.size = Vector2(w, h - 90)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		container.add_child(portrait)

	# 稀有度標籤（左下）
	var grade_text_colors = {
		"R":   Color(0.45, 0.72, 1.00),
		"SR":  Color(0.82, 0.45, 1.00),
		"SSR": Color(1.00, 0.88, 0.22),
		"QR":  Color(1.00, 0.42, 0.05)
	}
	var grade_lbl = Label.new()
	grade_lbl.text = grade
	grade_lbl.modulate = grade_text_colors.get(grade, Color.WHITE)
	grade_lbl.add_theme_font_size_override("font_size", maxi(14, w / 12))
	grade_lbl.position = Vector2(8, h - 82)
	container.add_child(grade_lbl)

	# 名稱（左下第二行）
	var name_lbl = Label.new()
	name_lbl.text = card_info.get("name", card_id)
	name_lbl.add_theme_font_size_override("font_size", maxi(14, w / 14))
	name_lbl.position = Vector2(8, h - 56)
	name_lbl.size = Vector2(w - 16, 32)
	name_lbl.clip_text = true
	container.add_child(name_lbl)

	# 強化 / 溢出狀態（左下第三行）
	var plus = SaveManager.get_card_plus(card_id)
	var max_plus = card_info.get("max_plus", 3)
	var status_lbl = Label.new()
	if plus > max_plus:
		status_lbl.text = "→ 50 金幣"
		status_lbl.modulate = Color(1.00, 0.85, 0.20)
	elif plus >= max_plus:
		status_lbl.text = "→ 50 金幣"
		status_lbl.modulate = Color(1.00, 0.85, 0.20)
	elif plus > 0:
		status_lbl.text = "+%d" % plus
		status_lbl.modulate = Color(0.40, 1.00, 0.55)
	else:
		status_lbl.text = "NEW"
		status_lbl.modulate = Color(0.40, 1.00, 0.55)
	status_lbl.add_theme_font_size_override("font_size", maxi(12, w / 16))
	status_lbl.position = Vector2(8, h - 26)
	container.add_child(status_lbl)

# ─────────────────────────────────────────
#  SSR / QR 邊框閃光
# ─────────────────────────────────────────

func _play_grade_flash(container: Control, grade: String) -> void:
	var flash_color = Color(1.0, 0.85, 0.10) if grade == "SSR" else Color(1.0, 0.42, 0.05)
	var tw = create_tween()
	tw.set_loops(3)
	tw.tween_property(container, "modulate", Color(flash_color.r, flash_color.g, flash_color.b, 1.2), 0.12)
	tw.tween_property(container, "modulate", Color.WHITE, 0.12)

# ─────────────────────────────────────────
#  金幣不足提示
# ─────────────────────────────────────────

func _show_no_coins() -> void:
	var old = get_node_or_null("RC_NoCoins")
	if old:
		old.queue_free()

	var lbl = Label.new()
	lbl.name = "RC_NoCoins"
	lbl.text = "金幣不足！"
	lbl.add_theme_font_size_override("font_size", 44)
	lbl.modulate = Color(1.0, 0.28, 0.28)
	lbl.position = Vector2(0, 880)
	lbl.size = Vector2(1080, 80)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(lbl)

	var tw = create_tween()
	tw.tween_interval(1.8)
	tw.tween_callback(lbl.queue_free)

# ─────────────────────────────────────────
#  關閉
# ─────────────────────────────────────────

func _on_close() -> void:
	emit_signal("panel_closed")
	queue_free()

# ─────────────────────────────────────────
#  輔助：按鈕樣式
# ─────────────────────────────────────────

func _style_button(btn: Button, bg_color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = Color(
		minf(bg_color.r + 0.25, 1.0),
		minf(bg_color.g + 0.25, 1.0),
		minf(bg_color.b + 0.25, 1.0),
		0.85
	)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", style)

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(
		minf(bg_color.r + 0.12, 1.0),
		minf(bg_color.g + 0.12, 1.0),
		minf(bg_color.b + 0.12, 1.0)
	)
	hover.border_color = style.border_color
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("hover", hover)
