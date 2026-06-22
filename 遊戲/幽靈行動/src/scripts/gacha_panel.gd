extends CanvasLayer

# 招募中心面板 — 聚光燈揭示抽卡動畫
# 掛在 GachaPanel.tscn (CanvasLayer layer=15)

signal panel_closed

# ── 統一設計配色 ──
const COL_GOLD   := Color(1.0, 0.78, 0.25)
const COL_ORANGE := Color(1.0, 0.55, 0.12)
const COL_STEEL  := Color(0.30, 0.45, 0.65)
const SAFE_BOTTOM := 60.0

var _cards_json: Dictionary = {}
var _gacha_config: Dictionary = {}
var _busy: bool = false   # 動畫播放中鎖定抽卡按鈕
var _results_dismissable: bool = false  # 抽卡結果可關閉狀態（多重保險：dim點擊/_input/自動關閉）

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
	# 黑色底層遮罩（深藍黑）
	var overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0.03, 0.04, 0.07, 0.96)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)

	# 頂欄背景
	var top_bg = ColorRect.new()
	top_bg.size = Vector2(1080, 130)
	top_bg.color = Color(0.05, 0.07, 0.11, 0.98)
	add_child(top_bg)
	var top_line = ColorRect.new()
	top_line.position = Vector2(0, 128)
	top_line.size = Vector2(1080, 3)
	top_line.color = Color(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, 0.55)
	add_child(top_line)

	# 標題
	var title = Label.new()
	title.name = "Title"
	title.text = "招募中心"
	title.add_theme_font_size_override("font_size", 48)
	title.modulate = COL_GOLD
	title.position = Vector2(40, 38)
	title.size = Vector2(700, 70)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(title)

	# 關閉按鈕（右上角）
	var close_btn = Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(80, 80)
	close_btn.position = Vector2(970, 28)
	close_btn.add_theme_font_size_override("font_size", 36)
	_style_button(close_btn, Color(0.30, 0.08, 0.08))
	close_btn.pressed.connect(_on_close)
	add_child(close_btn)

	# 金幣顯示（膠囊）
	var coin_pill = Panel.new()
	coin_pill.position = Vector2(40, 150)
	coin_pill.size = Vector2(320, 46)
	var cps = StyleBoxFlat.new()
	cps.bg_color = Color(0.10, 0.13, 0.18, 0.95)
	cps.border_color = Color(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, 0.55)
	cps.set_border_width_all(2)
	cps.set_corner_radius_all(23)
	coin_pill.add_theme_stylebox_override("panel", cps)
	add_child(coin_pill)
	var coins_lbl = Label.new()
	coins_lbl.name = "CoinsLabel"
	coins_lbl.text = "金幣 %d" % SaveManager.coins
	coins_lbl.add_theme_font_size_override("font_size", 28)
	coins_lbl.modulate = COL_GOLD
	coins_lbl.position = Vector2(58, 152)
	coins_lbl.size = Vector2(290, 42)
	coins_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(coins_lbl)

	# 機率說明
	_build_pool_info()

	# ── 底部抽卡按鈕區（尊重安全邊距）──
	var pull_y = 1920.0 - SAFE_BOTTOM - 100.0

	# 新手10連按鈕（未領取時顯示，置於單/十連上方，醒目綠框 + 呼吸動畫）
	if not SaveManager.starter_claimed:
		var btn_starter = Button.new()
		btn_starter.name = "StarterBtn"
		btn_starter.text = "★ 新手 10 連　免費領取 ★"
		btn_starter.custom_minimum_size = Vector2(1000, 96)
		btn_starter.size = Vector2(1000, 96)
		btn_starter.position = Vector2(40, pull_y - 116.0)
		btn_starter.add_theme_font_size_override("font_size", 34)
		_style_button(btn_starter, Color(0.08, 0.35, 0.10))
		btn_starter.modulate = Color(0.5, 1.0, 0.6)
		btn_starter.pivot_offset = Vector2(500, 48)
		btn_starter.pressed.connect(_do_starter_pull)
		add_child(btn_starter)
		_pulse_button(btn_starter)

	# 單抽 + 十連（並排）
	var btn_single = Button.new()
	btn_single.name = "BtnSingle"
	btn_single.text = "單抽\n100 金"
	btn_single.custom_minimum_size = Vector2(480, 100)
	btn_single.size = Vector2(480, 100)
	btn_single.position = Vector2(40, pull_y)
	btn_single.add_theme_font_size_override("font_size", 28)
	_style_button(btn_single, Color(0.12, 0.18, 0.38))
	btn_single.pressed.connect(func(): _do_pull(1))
	add_child(btn_single)

	var btn_ten = Button.new()
	btn_ten.name = "BtnTen"
	btn_ten.text = "十連\n900 金"
	btn_ten.custom_minimum_size = Vector2(480, 100)
	btn_ten.size = Vector2(480, 100)
	btn_ten.position = Vector2(560, pull_y)
	btn_ten.add_theme_font_size_override("font_size", 28)
	btn_ten.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	_style_button(btn_ten, Color(0.42, 0.28, 0.0))
	btn_ten.pressed.connect(func(): _do_pull(10))
	add_child(btn_ten)
	# 十連優惠標籤
	var save_tag = Label.new()
	save_tag.text = "省 100"
	save_tag.position = Vector2(900, pull_y + 6.0)
	save_tag.add_theme_font_size_override("font_size", 18)
	save_tag.modulate = Color(0.5, 1.0, 0.6)
	add_child(save_tag)

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
	if _busy:
		return
	if SaveManager.starter_claimed:
		return
	var results = SaveManager.claim_starter_pulls()
	var starter_btn = get_node_or_null("StarterBtn")
	if starter_btn:
		starter_btn.queue_free()
	_show_pull_results(results)

func _do_pull(count: int) -> void:
	if _busy:
		return
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
		lbl.text = "金幣 %d" % SaveManager.coins

# ─────────────────────────────────────────
#  揭示動畫主入口
# ─────────────────────────────────────────

func _show_pull_results(card_ids: Array) -> void:
	# 移除前一輪結果節點
	_clear_result_nodes()

	if card_ids.is_empty():
		return

	_busy = true

	# 暗化抽卡背景的點擊遮罩（兼作「點擊任意處關閉」）
	var dim = ColorRect.new()
	dim.name = "RC_Dim"
	dim.color = Color(0.0, 0.0, 0.0, 0.0)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var dim_tw = create_tween()
	dim_tw.tween_property(dim, "color:a", 0.80, 0.25)

	if card_ids.size() == 1:
		_show_single_spotlight(card_ids[0])
	else:
		_show_multi_result(card_ids)

	# 最高稀有度判定 → 提示文字
	var best = _best_grade(card_ids)
	_show_dismiss_hint(best)

	# 點擊任意處關閉結果（延遲 0.4 秒避免誤觸）—— 多重保險：dim 點擊 + _input + 自動關閉
	var gate = get_tree().create_timer(0.45)
	gate.timeout.connect(func():
		_results_dismissable = true
		if is_instance_valid(dim):
			dim.gui_input.connect(func(ev):
				if (ev is InputEventScreenTouch and ev.pressed) or (ev is InputEventMouseButton and ev.pressed):
					_dismiss_results()
			)
		# 安全自動關閉：6 秒內若觸控都沒被偵測，自動關閉，永不卡死
		var auto = get_tree().create_timer(6.0, true, false, true)
		auto.timeout.connect(_dismiss_results)
	)

func _best_grade(card_ids: Array) -> String:
	var order = {"R": 0, "SR": 1, "SSR": 2, "QR": 3}
	var best = "R"
	for cid in card_ids:
		var g = _cards_json.get(cid, {}).get("grade", "R")
		if order.get(g, 0) > order.get(best, 0):
			best = g
	return best

func _show_dismiss_hint(best_grade: String) -> void:
	var hint = Label.new()
	hint.name = "RC_Hint"
	var msg = "點擊任意處繼續"
	if best_grade == "QR":
		msg = "★ QR 傳說幹員！點擊繼續 ★"
	elif best_grade == "SSR":
		msg = "★ SSR 獲得！點擊繼續 ★"
	hint.text = msg
	hint.add_theme_font_size_override("font_size", 26)
	hint.modulate = Color(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, 0.0)
	hint.position = Vector2(0, 1920.0 - SAFE_BOTTOM - 70.0)
	hint.size = Vector2(1080, 50)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)
	var tw = create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(hint, "modulate:a", 1.0, 0.4)
	# 持續閃爍
	var blink = create_tween()
	blink.set_loops()
	blink.tween_interval(1.1)
	blink.tween_property(hint, "modulate:a", 0.4, 0.5)
	blink.tween_property(hint, "modulate:a", 1.0, 0.5)

# 備援：抽卡結果可關閉時，偵測任意觸控/點擊 → 關閉（與 dim.gui_input 互為備援）
func _input(event: InputEvent) -> void:
	if not _results_dismissable:
		return
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		_dismiss_results()
		get_viewport().set_input_as_handled()

func _dismiss_results() -> void:
	if not _results_dismissable:
		return
	_results_dismissable = false
	_clear_result_nodes()
	_busy = false

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
	light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(light)

	# 輻射暈光（圓形柔邊 — 用較大 ColorRect 模擬）
	var glow = ColorRect.new()
	glow.name = "RC_Glow"
	glow.color = light_colors.get(grade, Color(0.5, 0.5, 0.5, 0.10))
	glow.color.a = 0.12
	glow.size = Vector2(700, 700)
	glow.position = Vector2(190, 550)
	glow.modulate.a = 0.0
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	# 卡片容器：從畫面下方滑入
	var card_container = Control.new()
	card_container.name = "RC_Main"
	card_container.size = Vector2(320, 480)
	card_container.position = Vector2(380, 1920)
	card_container.pivot_offset = Vector2(160, 240)
	card_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

	# 1. 全螢幕白閃（瞬間）
	var burst = ColorRect.new()
	burst.name = "RC_Burst"
	burst.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.0)
	burst.anchor_right = 1.0
	burst.anchor_bottom = 1.0
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(burst)
	var bt = create_tween()
	bt.tween_property(burst, "color:a", 0.55, 0.08)
	bt.tween_property(burst, "color:a", 0.0, 0.35)
	bt.tween_callback(burst.queue_free)

	# 2. 卡片中心放射光線（8 道，旋轉擴散）
	var center = container.position + container.size / 2.0
	var rays_root = Control.new()
	rays_root.name = "RC_Rays"
	rays_root.position = center
	rays_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rays_root)
	move_child(rays_root, container.get_index())  # 置於卡片下方
	for i in range(8):
		var ray = ColorRect.new()
		ray.size = Vector2(8, 460)
		ray.position = Vector2(-4, 0)
		ray.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.0)
		ray.pivot_offset = Vector2(4, 0)
		ray.rotation = deg_to_rad(i * 45.0)
		ray.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rays_root.add_child(ray)
		var rt = create_tween()
		rt.tween_property(ray, "color:a", 0.5, 0.2)
		rt.tween_property(ray, "color:a", 0.0, 0.6)
	var spin = create_tween()
	spin.tween_property(rays_root, "rotation", deg_to_rad(30.0), 1.0)
	spin.tween_callback(rays_root.queue_free)

	# 3. 卡片邊框閃爍
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

	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color(maxf(bg_color.r - 0.05, 0.0), maxf(bg_color.g - 0.05, 0.0), maxf(bg_color.b - 0.05, 0.0))
	pressed.border_color = style.border_color
	pressed.set_border_width_all(2)
	pressed.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.focus_mode = Control.FOCUS_NONE

# 呼吸放大動畫（吸引點擊，例：免費新手十連）
func _pulse_button(btn: Control) -> void:
	if btn.pivot_offset == Vector2.ZERO:
		btn.pivot_offset = btn.size / 2.0
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
