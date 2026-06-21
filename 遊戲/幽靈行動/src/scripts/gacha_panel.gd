extends CanvasLayer

# 招募中心面板 — 掛在 GachaPanel.tscn (CanvasLayer layer=15)

var _bg: ColorRect
var _blue_ticket_label: Label
var _gold_ticket_label: Label
var _result_container: VBoxContainer
var _fragment_label: Label

# 翻牌動畫節點
var _anim_card: Panel = null
var _anim_card_content: Label = null
var _pending_results: Array = []

# 角色名稱對照
const CHAR_NAMES = {
	"shield": "盾兵",
	"medic": "醫療兵",
	"assault": "突擊手",
	"sniper": "狙擊手",
	"demo": "爆破手",
	"recon": "偵察手",
}

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# 半透明遮罩背景（全螢幕）
	_bg = ColorRect.new()
	_bg.anchor_right = 1.0
	_bg.anchor_bottom = 1.0
	_bg.color = Color(0.0, 0.0, 0.0, 0.85)
	add_child(_bg)

	# 主面板容器
	var panel = ColorRect.new()
	panel.position = Vector2(40, 80)
	panel.size = Vector2(1000, 1760)
	panel.color = Color(0.05, 0.08, 0.12, 0.97)
	add_child(panel)

	# 邊框
	var border_style = StyleBoxFlat.new()
	border_style.border_color = Color(0.8, 0.7, 0.2, 0.9)
	border_style.set_border_width_all(3)

	# 標題
	var title = Label.new()
	title.text = "招募中心"
	title.position = Vector2(370, 100)
	title.add_theme_font_size_override("font_size", 36)
	title.modulate = Color(1.0, 0.9, 0.3)
	add_child(title)

	# 分隔線
	var sep1 = ColorRect.new()
	sep1.position = Vector2(60, 158)
	sep1.size = Vector2(960, 2)
	sep1.color = Color(0.5, 0.4, 0.1, 0.8)
	add_child(sep1)

	# ── 票券顯示 ──
	_blue_ticket_label = Label.new()
	_blue_ticket_label.position = Vector2(80, 175)
	_blue_ticket_label.add_theme_font_size_override("font_size", 26)
	_blue_ticket_label.modulate = Color(0.4, 0.7, 1.0)
	add_child(_blue_ticket_label)

	_gold_ticket_label = Label.new()
	_gold_ticket_label.position = Vector2(80, 215)
	_gold_ticket_label.add_theme_font_size_override("font_size", 26)
	_gold_ticket_label.modulate = Color(1.0, 0.85, 0.2)
	add_child(_gold_ticket_label)

	# ── 機率說明 ──
	var prob_bg = ColorRect.new()
	prob_bg.position = Vector2(60, 265)
	prob_bg.size = Vector2(960, 120)
	prob_bg.color = Color(0.08, 0.10, 0.15, 0.9)
	add_child(prob_bg)

	var prob_title = Label.new()
	prob_title.text = "卡池機率"
	prob_title.position = Vector2(80, 272)
	prob_title.add_theme_font_size_override("font_size", 20)
	prob_title.modulate = Color(0.8, 0.8, 0.8)
	add_child(prob_title)

	var prob_equal = Label.new()
	prob_equal.text = "各職業出現機率相同（約 16.7%）"
	prob_equal.position = Vector2(80, 300)
	prob_equal.add_theme_font_size_override("font_size", 18)
	prob_equal.modulate = Color(0.9, 0.9, 0.9)
	add_child(prob_equal)

	# 保底說明
	var pity_lbl = Label.new()
	pity_lbl.text = "保底：連續 6 抽無新角色 → 下一抽必得未解鎖職業"
	pity_lbl.position = Vector2(80, 330)
	pity_lbl.add_theme_font_size_override("font_size", 16)
	pity_lbl.modulate = Color(0.6, 0.9, 0.6)
	add_child(pity_lbl)

	# ── 抽卡按鈕 ──
	var btn_y: float = 415.0
	var btn_configs = [
		{"text": "藍票 x1 單抽", "ticket": "blue", "count": 1, "color": Color(0.1, 0.2, 0.5)},
		{"text": "藍票 x10 連抽", "ticket": "blue", "count": 10, "color": Color(0.1, 0.3, 0.6)},
		{"text": "金票 x1 單抽", "ticket": "gold", "count": 1, "color": Color(0.4, 0.3, 0.0)},
		{"text": "金票 x10 連抽", "ticket": "gold", "count": 10, "color": Color(0.5, 0.4, 0.0)},
	]

	for cfg_item in btn_configs:
		var btn = Button.new()
		btn.text = cfg_item["text"]
		btn.position = Vector2(80, btn_y)
		btn.custom_minimum_size = Vector2(920, 70)
		btn.add_theme_font_size_override("font_size", 24)
		btn.name = "PullBtn_" + cfg_item["ticket"] + "_" + str(cfg_item["count"])
		_style_button(btn, cfg_item["color"])
		btn.pressed.connect(_on_pull_pressed.bind(cfg_item["ticket"], cfg_item["count"]))
		add_child(btn)
		btn_y += 80.0

	# ── 結果顯示區 ──
	var result_title = Label.new()
	result_title.text = "抽卡結果："
	result_title.position = Vector2(80, 745)
	result_title.add_theme_font_size_override("font_size", 22)
	result_title.modulate = Color(0.8, 0.8, 0.8)
	add_child(result_title)

	var result_bg = ColorRect.new()
	result_bg.position = Vector2(60, 778)
	result_bg.size = Vector2(960, 500)
	result_bg.color = Color(0.03, 0.05, 0.08, 0.9)
	add_child(result_bg)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(60, 778)
	scroll.size = Vector2(960, 500)
	add_child(scroll)

	_result_container = VBoxContainer.new()
	_result_container.custom_minimum_size = Vector2(940, 0)
	_result_container.add_theme_constant_override("separation", 6)
	scroll.add_child(_result_container)

	# ── 稀有度總覽 ──
	var rarity_sep = ColorRect.new()
	rarity_sep.position = Vector2(60, 1295)
	rarity_sep.size = Vector2(960, 2)
	rarity_sep.color = Color(0.3, 0.3, 0.3, 0.7)
	add_child(rarity_sep)

	var rarity_title = Label.new()
	rarity_title.text = "角色稀有度總覽："
	rarity_title.position = Vector2(80, 1305)
	rarity_title.add_theme_font_size_override("font_size", 22)
	rarity_title.modulate = Color(0.8, 0.8, 0.8)
	add_child(rarity_title)

	_fragment_label = Label.new()
	_fragment_label.position = Vector2(80, 1335)
	_fragment_label.add_theme_font_size_override("font_size", 18)
	_fragment_label.modulate = Color(0.9, 0.9, 0.9)
	_fragment_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_fragment_label.custom_minimum_size = Vector2(920, 0)
	add_child(_fragment_label)

	# ── 關閉按鈕 ──
	var close_btn = Button.new()
	close_btn.text = "關閉"
	close_btn.position = Vector2(340, 1700)
	close_btn.custom_minimum_size = Vector2(400, 70)
	close_btn.add_theme_font_size_override("font_size", 26)
	_style_button(close_btn, Color(0.3, 0.1, 0.1))
	close_btn.pressed.connect(_on_close_pressed)
	add_child(close_btn)

	_update_ticket_display()
	_update_fragment_display()

	# 翻牌動畫卡片（疊在最上層）
	_build_anim_card()

# ── 翻牌動畫卡片 ──
func _build_anim_card() -> void:
	_anim_card = Panel.new()
	_anim_card.position = Vector2(240, 950)
	_anim_card.size = Vector2(600, 300)
	_anim_card.pivot_offset = Vector2(300, 150)
	_anim_card.visible = false

	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.10, 0.18, 0.98)
	card_style.border_color = Color(0.8, 0.7, 0.2, 0.9)
	card_style.set_border_width_all(3)
	card_style.set_corner_radius_all(12)
	_anim_card.add_theme_stylebox_override("panel", card_style)

	_anim_card_content = Label.new()
	_anim_card_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_anim_card_content.add_theme_font_size_override("font_size", 28)
	_anim_card_content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anim_card_content.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_anim_card_content.autowrap_mode = TextServer.AUTOWRAP_WORD
	_anim_card.add_child(_anim_card_content)

	add_child(_anim_card)

# 翻牌動畫：scale.x 1→0→1，中間呼叫 on_flip_mid 換內容
func _play_card_flip_animation(on_flip_mid: Callable, on_complete: Callable) -> void:
	_anim_card.scale = Vector2(1.0, 1.0)
	_anim_card.visible = true

	var tween = create_tween()
	# Phase 1：正面翻到邊緣
	tween.tween_property(_anim_card, "scale", Vector2(0.0, 1.0), 0.25).set_ease(Tween.EASE_IN)
	tween.tween_callback(on_flip_mid)
	# Phase 2：邊緣翻到背面（現在是結果面）
	tween.tween_property(_anim_card, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_callback(on_complete)

# SSR 首次解鎖的金色邊框閃光效果
func _play_ssr_flash() -> void:
	var flash_tween = create_tween()
	flash_tween.set_loops(3)
	var ssr_style = StyleBoxFlat.new()
	ssr_style.bg_color = Color(0.08, 0.10, 0.18, 0.98)
	ssr_style.border_color = Color(1.0, 0.9, 0.1, 1.0)
	ssr_style.set_border_width_all(6)
	ssr_style.set_corner_radius_all(12)
	flash_tween.tween_callback(func():
		_anim_card.add_theme_stylebox_override("panel", ssr_style)
	)
	flash_tween.tween_interval(0.15)
	var dim_style = StyleBoxFlat.new()
	dim_style.bg_color = Color(0.08, 0.10, 0.18, 0.98)
	dim_style.border_color = Color(0.8, 0.7, 0.2, 0.9)
	dim_style.set_border_width_all(3)
	dim_style.set_corner_radius_all(12)
	flash_tween.tween_callback(func():
		_anim_card.add_theme_stylebox_override("panel", dim_style)
	)
	flash_tween.tween_interval(0.15)

# 設定動畫卡片顯示卡背（神秘狀態）
func _set_card_back() -> void:
	_anim_card_content.text = "？？？"
	_anim_card_content.modulate = Color(0.5, 0.5, 0.6)
	var back_style = StyleBoxFlat.new()
	back_style.bg_color = Color(0.05, 0.06, 0.12, 0.98)
	back_style.border_color = Color(0.4, 0.35, 0.1, 0.9)
	back_style.set_border_width_all(3)
	back_style.set_corner_radius_all(12)
	_anim_card.add_theme_stylebox_override("panel", back_style)

# 設定動畫卡片顯示結果內容（單抽用，從 pending_results 第一筆）
func _set_card_result_single(result: Dictionary) -> void:
	var char_id = result.get("char_id", "")
	var is_new = result.get("is_new", false)
	var copies_gained = result.get("copies_gained", 0)
	var current_copies = result.get("current_copies", 0)
	var char_name = CHAR_NAMES.get(char_id, char_id)

	if is_new:
		_anim_card_content.text = "✨ " + char_name + "\n加入！"
		_anim_card_content.modulate = Color(1.0, 0.65, 0.1)
		var new_style = StyleBoxFlat.new()
		new_style.bg_color = Color(0.15, 0.10, 0.02, 0.98)
		new_style.border_color = Color(1.0, 0.85, 0.2, 1.0)
		new_style.set_border_width_all(4)
		new_style.set_corner_radius_all(12)
		_anim_card.add_theme_stylebox_override("panel", new_style)
	elif copies_gained == 0:
		_anim_card_content.text = char_name + "\n已達 SSR！\n+1 藍票"
		_anim_card_content.modulate = Color(1.0, 0.85, 0.1)
		var ssr_style = StyleBoxFlat.new()
		ssr_style.bg_color = Color(0.12, 0.10, 0.02, 0.98)
		ssr_style.border_color = Color(1.0, 0.9, 0.1, 0.9)
		ssr_style.set_border_width_all(4)
		ssr_style.set_corner_radius_all(12)
		_anim_card.add_theme_stylebox_override("panel", ssr_style)
	else:
		_anim_card_content.text = char_name + "\n備份 +1（已 " + str(current_copies) + " 張）"
		_anim_card_content.modulate = Color(0.5, 0.8, 1.0)
		var dup_style = StyleBoxFlat.new()
		dup_style.bg_color = Color(0.04, 0.08, 0.16, 0.98)
		dup_style.border_color = Color(0.3, 0.5, 0.9, 0.9)
		dup_style.set_border_width_all(3)
		dup_style.set_corner_radius_all(12)
		_anim_card.add_theme_stylebox_override("panel", dup_style)

func _update_ticket_display() -> void:
	if _blue_ticket_label:
		_blue_ticket_label.text = "藍色票：" + str(SaveManager.blue_tickets) + " 張"
	if _gold_ticket_label:
		_gold_ticket_label.text = "金色票：" + str(SaveManager.gold_tickets) + " 張"

func _update_fragment_display() -> void:
	if not _fragment_label:
		return
	const RARITY_NAMES_DISP = ["灰", "銀SR", "金SSR"]
	const RARITY_COLORS_DISP = [Color(0.6, 0.6, 0.65), Color(0.82, 0.87, 1.0), Color(1.0, 0.85, 0.2)]
	var parts: Array = []
	for char_id in ["shield", "medic", "assault", "sniper", "demo", "recon"]:
		var name = CHAR_NAMES.get(char_id, char_id)
		if char_id in SaveManager.owned_characters:
			var r = SaveManager.character_rarity.get(char_id, 0)
			var c = SaveManager.character_copies.get(char_id, 0)
			var suffix = " 備份:" + str(c)
			if r >= 2:
				suffix = " SSR"
			parts.append(name + "(" + RARITY_NAMES_DISP[r] + ")" + suffix)
		else:
			parts.append(name + "(未解鎖)")
	_fragment_label.text = "  ".join(parts)

func _on_pull_pressed(ticket_type: String, count: int) -> void:
	var results: Array = []
	if count == 1:
		var r = GachaManager.pull(ticket_type)
		if not r.is_empty():
			results.append(r)
	else:
		results = GachaManager.pull_10(ticket_type)

	if results.is_empty():
		_show_error("票券不足！")
		return

	_pending_results = results
	_update_ticket_display()
	_update_fragment_display()

	if count == 1:
		# 單抽：翻牌動畫後顯示結果
		_set_card_back()
		var result = results[0]
		_play_card_flip_animation(
			func(): _set_card_result_single(result),
			func():
				# 若首次解鎖，翻完後加 SSR 閃光
				if result.get("is_new", false):
					_play_ssr_flash()
				# 動畫結束後把結果填入下方列表
				_display_results(_pending_results)
				# 延遲隱藏動畫卡（讓玩家看到效果後再消失）
				get_tree().create_timer(1.2).timeout.connect(func():
					if is_instance_valid(_anim_card):
						_anim_card.visible = false
				)
		)
	else:
		# 十連抽：快速翻牌動畫後一次顯示所有結果
		_set_card_back()
		_play_card_flip_animation(
			func():
				_anim_card_content.text = "x" + str(results.size()) + " 抽完成！"
				_anim_card_content.modulate = Color(1.0, 0.9, 0.5)
				var multi_style = StyleBoxFlat.new()
				multi_style.bg_color = Color(0.10, 0.10, 0.05, 0.98)
				multi_style.border_color = Color(0.9, 0.8, 0.2, 0.9)
				multi_style.set_border_width_all(3)
				multi_style.set_corner_radius_all(12)
				_anim_card.add_theme_stylebox_override("panel", multi_style),
			func():
				_display_results(_pending_results)
				get_tree().create_timer(0.8).timeout.connect(func():
					if is_instance_valid(_anim_card):
						_anim_card.visible = false
				)
		)

func _display_results(results: Array) -> void:
	# 清除舊結果
	for child in _result_container.get_children():
		child.queue_free()

	for result in results:
		var char_id = result.get("char_id", "")
		var is_new = result.get("is_new", false)
		var copies_gained = result.get("copies_gained", 0)
		var current_copies = result.get("current_copies", 0)
		var current_rarity = result.get("current_rarity", 0)
		var char_name = CHAR_NAMES.get(char_id, char_id)

		var row = Label.new()
		row.add_theme_font_size_override("font_size", 22)

		const RARITY_NAMES_LOCAL = ["灰色", "SR銀", "SSR金"]

		if is_new:
			# 首次解鎖：橙色，強調感
			row.text = "  ✨ [首次解鎖] " + char_name + " 加入！"
			row.modulate = Color(1.0, 0.65, 0.1)
		elif copies_gained == 0:
			# SSR 補償（備份轉藍票）：金色
			row.text = "  " + char_name + "  已達 SSR！+1 藍票"
			row.modulate = Color(1.0, 0.85, 0.1)
		else:
			# 重複（備份 +1）：藍色
			var copies_needed = SaveManager.copies_needed_for_rarity_up(char_id)
			var needed_str = ""
			if copies_needed > 0:
				needed_str = "  距升稀有度還需 " + str(copies_needed) + " 張"
			else:
				needed_str = "  可提升稀有度！"
			row.text = "  " + char_name + "  備份 +1（已 " + str(current_copies) + " 張）" + needed_str
			row.modulate = Color(0.5, 0.75, 1.0)

		_result_container.add_child(row)

func _show_error(msg: String) -> void:
	var err = Label.new()
	err.text = msg
	err.add_theme_font_size_override("font_size", 22)
	err.modulate = Color(1.0, 0.3, 0.3)
	_result_container.add_child(err)
	get_tree().create_timer(2.0).timeout.connect(func(): if is_instance_valid(err): err.queue_free())

func _on_close_pressed() -> void:
	queue_free()

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
