extends Control

# ─── 色彩常數 ───────────────────────────────────────────────
const COL_BG        := Color(0.039, 0.059, 0.078, 1)   # #0a0f14
const COL_CARD_BG   := Color(0.075, 0.110, 0.145, 1)   # #131c25
const COL_GREEN     := Color(0.000, 1.000, 0.255, 1)   # #00ff41
const COL_ORANGE    := Color(1.000, 0.584, 0.000, 1)   # #ff9500
const COL_WHITE     := Color(1.000, 1.000, 1.000, 1)
const COL_GRAY      := Color(0.502, 0.502, 0.502, 1)   # #808080
const COL_GRAY_DIM  := Color(0.400, 0.400, 0.400, 1)

# ─── 閃爍提示 Label（供 Tween 存取）──────────────────────────
var _press_label: Label

func _ready() -> void:
	# ── 防護：若 GameData 不存在（headless 無 autoload）─────────
	var level_name   := "—"
	var kills        := 0
	var reward       := 0
	var total_funds  := 0

	if Engine.has_singleton("GameData"):
		var gd = Engine.get_singleton("GameData")
		gd.total_money += gd.last_level_reward
		level_name  = gd.last_level_name    if gd.last_level_name != ""  else "UNKNOWN"
		kills       = gd.last_enemies_killed
		reward      = gd.last_level_reward
		total_funds = gd.total_money
	elif ClassDB.class_exists("GameData"):
		# autoload 以節點形式存在時走這裡
		var gd = get_node_or_null("/root/GameData")
		if gd:
			gd.total_money += gd.last_level_reward
			level_name  = gd.last_level_name    if gd.last_level_name != ""  else "UNKNOWN"
			kills       = gd.last_enemies_killed
			reward      = gd.last_level_reward
			total_funds = gd.total_money

	_build_ui(level_name, kills, reward, total_funds)
	_start_blink_tween()

# ─── UI 建構 ────────────────────────────────────────────────
func _build_ui(level_name: String, kills: int, reward: int, total_funds: int) -> void:

	# ── 1. 全螢幕深黑背景 ─────────────────────────────────────
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = COL_BG
	add_child(bg)

	# ── 2. 主佈局（垂直置中）────────────────────────────────────
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var root_vbox := VBoxContainer.new()
	root_vbox.custom_minimum_size = Vector2(680, 0)
	root_vbox.add_theme_constant_override("separation", 0)
	center.add_child(root_vbox)

	# ── 3. 頂部 Banner ───────────────────────────────────────
	_add_banner(root_vbox)

	# 間隔
	var gap1 := Control.new()
	gap1.custom_minimum_size = Vector2(0, 24)
	root_vbox.add_child(gap1)

	# ── 4. 任務報告卡片 ───────────────────────────────────────
	_add_card(root_vbox, level_name, kills, reward, total_funds)

	# 間隔
	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 32)
	root_vbox.add_child(gap2)

	# ── 5. 返回按鈕 ───────────────────────────────────────────
	_add_back_button(root_vbox)

	# 間隔
	var gap3 := Control.new()
	gap3.custom_minimum_size = Vector2(0, 24)
	root_vbox.add_child(gap3)

	# ── 6. 底部閃爍提示 ───────────────────────────────────────
	_press_label = Label.new()
	_press_label.text = "按任意鍵繼續  //  PRESS ANY KEY"
	_press_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_press_label.add_theme_font_size_override("font_size", 14)
	_press_label.add_theme_color_override("font_color", COL_GRAY)
	root_vbox.add_child(_press_label)


func _add_banner(parent: VBoxContainer) -> void:
	# 頂部綠色橫條
	var top_bar := ColorRect.new()
	top_bar.custom_minimum_size = Vector2(0, 4)
	top_bar.color = COL_GREEN
	parent.add_child(top_bar)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	parent.add_child(gap)

	# 主標題
	var title := Label.new()
	title.text = "checkmark 任務完成"
	# Godot 4 Label 支援 UTF-8，直接用符號
	title.text = "✓  任務完成"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", COL_GREEN)
	parent.add_child(title)

	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 6)
	parent.add_child(gap2)

	# 副標題
	var sub := Label.new()
	sub.text = "MISSION ACCOMPLISHED"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", COL_GRAY)
	parent.add_child(sub)

	var gap3 := Control.new()
	gap3.custom_minimum_size = Vector2(0, 16)
	parent.add_child(gap3)


func _add_card(parent: VBoxContainer, level_name: String, kills: int, reward: int, total_funds: int) -> void:
	# 外層 PanelContainer（圓角 + 橘色邊框）
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color             = COL_CARD_BG
	style.border_color         = COL_ORANGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	# 卡片內橫向排列（左橘條 + 右內容）
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	panel.add_child(hbox)

	# 左側橘色豎條
	var side_bar := ColorRect.new()
	side_bar.custom_minimum_size = Vector2(4, 0)
	side_bar.color = COL_ORANGE
	side_bar.size_flags_vertical = Control.SIZE_FILL
	hbox.add_child(side_bar)

	# 右側內容 VBox
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# 內邊距
	var inner_style := StyleBoxEmpty.new()
	inner_style.content_margin_left   = 24
	inner_style.content_margin_right  = 24
	inner_style.content_margin_top    = 20
	inner_style.content_margin_bottom = 20
	vbox.add_theme_stylebox_override("panel", inner_style)
	hbox.add_child(vbox)

	# ── 卡片標題列 ─────────────────────────────────────────────
	var card_title := Label.new()
	card_title.text = "[ MISSION REPORT ]"
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	card_title.add_theme_font_size_override("font_size", 13)
	card_title.add_theme_color_override("font_color", COL_ORANGE)
	vbox.add_child(card_title)

	# 分隔線
	var sep1 := HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(COL_ORANGE, 0.35)
	sep_style.thickness = 1
	sep1.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep1)

	var gap_after_sep := Control.new()
	gap_after_sep.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(gap_after_sep)

	# ── 各行資料 ──────────────────────────────────────────────
	_add_info_row(vbox, "OPERATION",  level_name.to_upper(), COL_WHITE, 20)
	_add_info_row(vbox, "ELIMINATED", str(kills) + "  HOSTILES", COL_WHITE, 20)
	_add_info_row(vbox, "REWARD",     "+ $" + str(reward), COL_ORANGE, 20)

	# 分隔線
	var gap_b := Control.new()
	gap_b.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(gap_b)

	var sep2 := HSeparator.new()
	var sep_style2 := StyleBoxLine.new()
	sep_style2.color = Color(COL_GRAY, 0.5)
	sep_style2.thickness = 1
	sep2.add_theme_stylebox_override("separator", sep_style2)
	vbox.add_child(sep2)

	var gap_c := Control.new()
	gap_c.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(gap_c)

	# TOTAL FUNDS（大字白色）
	_add_info_row(vbox, "TOTAL FUNDS", "$" + str(total_funds), COL_WHITE, 24)


func _add_info_row(parent: VBoxContainer, label_text: String, value_text: String, value_color: Color, font_size: int) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	parent.add_child(hbox)

	# 標籤（固定寬度，右對齊冒號）
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(160, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", COL_GRAY_DIM)
	hbox.add_child(lbl)

	# 冒號間隔
	var colon := Label.new()
	colon.text = " : "
	colon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	colon.add_theme_font_size_override("font_size", font_size)
	colon.add_theme_color_override("font_color", COL_GRAY_DIM)
	hbox.add_child(colon)

	# 數值
	var val := Label.new()
	val.text = value_text
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val.add_theme_font_size_override("font_size", font_size)
	val.add_theme_color_override("font_color", value_color)
	hbox.add_child(val)


func _add_back_button(parent: VBoxContainer) -> void:
	# 水平置中用 HBoxContainer + spacer 包夾
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)

	var spacer_l := Control.new()
	spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer_l)

	var btn := Button.new()
	btn.text = "◀  返回基地"
	btn.custom_minimum_size = Vector2(240, 56)
	btn.add_theme_font_size_override("font_size", 20)

	# 一般狀態：橘色邊框，不填色
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color      = Color(0, 0, 0, 0)
	normal_style.border_color  = COL_ORANGE
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(6)
	normal_style.set_content_margin_all(0)
	btn.add_theme_stylebox_override("normal", normal_style)

	# Hover 狀態：填橘色
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color      = COL_ORANGE
	hover_style.border_color  = COL_ORANGE
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(6)
	hover_style.set_content_margin_all(0)
	btn.add_theme_stylebox_override("hover", hover_style)

	# Pressed 狀態：稍暗橘色
	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color     = Color(0.8, 0.45, 0, 1)
	pressed_style.border_color = COL_ORANGE
	pressed_style.set_border_width_all(2)
	pressed_style.set_corner_radius_all(6)
	pressed_style.set_content_margin_all(0)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.add_theme_color_override("font_color",          COL_ORANGE)
	btn.add_theme_color_override("font_hover_color",    COL_BG)
	btn.add_theme_color_override("font_pressed_color",  COL_WHITE)

	btn.pressed.connect(_on_back_pressed)
	hbox.add_child(btn)

	var spacer_r := Control.new()
	spacer_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer_r)


# ─── 閃爍 Tween ──────────────────────────────────────────────
func _start_blink_tween() -> void:
	if not _press_label:
		return
	var tw := create_tween()
	tw.set_loops()
	tw.tween_method(
		func(alpha: float) -> void:
			if is_instance_valid(_press_label):
				_press_label.modulate.a = alpha,
		1.0, 0.15, 0.9
	)
	tw.tween_method(
		func(alpha: float) -> void:
			if is_instance_valid(_press_label):
				_press_label.modulate.a = alpha,
		0.15, 1.0, 0.9
	)


# ─── 輸入處理 ────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or \
	   (event is InputEventKey and event.pressed and \
	    event.keycode == KEY_ENTER):
		_on_back_pressed()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Base.tscn")
