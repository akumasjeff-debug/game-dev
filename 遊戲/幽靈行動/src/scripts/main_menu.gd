extends Control

const CHINESE_FONT_PATH := "res://resources/fonts/chinese_font.ttf"
const BASE_SCENE_PATH    := "res://scenes/Base.tscn"

# 畫布規格 1080×1920
const CW := 1080.0
const CH := 1920.0

# ── 統一設計配色（軍事深藍灰 + 金/橘點綴）──
const COL_BG_DEEP   := Color(0.035, 0.055, 0.095)
const COL_BG_MID    := Color(0.06, 0.10, 0.17)
const COL_STEEL     := Color(0.30, 0.45, 0.65)
const COL_GOLD      := Color(1.0, 0.78, 0.25)
const COL_ORANGE    := Color(1.0, 0.55, 0.12)
const COL_INK       := Color(0.96, 0.97, 1.0)

var _font: FontFile
var _fade: ColorRect

# 動態裝飾
var _scan_line: ColorRect
var _title_node: Control
var _glow_particles: Array = []
var _t: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists(CHINESE_FONT_PATH):
		_font = load(CHINESE_FONT_PATH)
	_build_bg()
	_build_decos()
	_build_title()
	_build_buttons()
	_build_version()
	_build_fade()
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.85).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_t += delta
	# 標題呼吸光暈
	if _title_node and is_instance_valid(_title_node):
		var glow := _title_node.get_node_or_null("TitleGlow")
		if glow:
			glow.modulate.a = 0.18 + sin(_t * 1.4) * 0.10
	# 掃描線緩慢下移
	if _scan_line and is_instance_valid(_scan_line):
		_scan_line.position.y += delta * 90.0
		if _scan_line.position.y > CH:
			_scan_line.position.y = -40.0
	# 浮動粒子
	for p in _glow_particles:
		if not is_instance_valid(p):
			continue
		p.position.y -= p.get_meta("spd", 12.0) * delta
		p.position.x += sin(_t * p.get_meta("phase", 1.0)) * 0.3
		if p.position.y < -10.0:
			p.position.y = CH + 10.0

# ── 背景 ─────────────────────────────────────────────────────────────
func _build_bg() -> void:
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size     = Vector2(CW, CH)
	bg.color    = COL_BG_DEEP
	add_child(bg)

	# 上半漸層層次（用三段帶模擬垂直漸層）
	var bands := 5
	for i in range(bands):
		var band := ColorRect.new()
		var frac := float(i) / float(bands)
		band.position = Vector2(0, frac * CH * 0.6)
		band.size     = Vector2(CW, CH * 0.6 / bands + 2)
		var a := 0.55 * (1.0 - frac)
		band.color    = Color(COL_BG_MID.r, COL_BG_MID.g, COL_BG_MID.b, a)
		add_child(band)

	# 底部暗角（聚焦中央）
	var vign := ColorRect.new()
	vign.position = Vector2(0, CH * 0.62)
	vign.size     = Vector2(CW, CH * 0.38)
	vign.color    = Color(0.0, 0.0, 0.0, 0.45)
	add_child(vign)

	# 掃描線（科技感）
	_scan_line = ColorRect.new()
	_scan_line.position = Vector2(0, 0)
	_scan_line.size     = Vector2(CW, 3)
	_scan_line.color    = Color(COL_STEEL.r, COL_STEEL.g, COL_STEEL.b, 0.10)
	add_child(_scan_line)

	# 浮動光點（戰場灰塵/光塵）
	for i in range(14):
		var dot := ColorRect.new()
		var sz := randf_range(2.0, 5.0)
		dot.size = Vector2(sz, sz)
		dot.position = Vector2(randf_range(40, CW - 40), randf_range(0, CH))
		dot.color = Color(COL_STEEL.r, COL_STEEL.g, COL_STEEL.b, randf_range(0.10, 0.30))
		dot.set_meta("spd", randf_range(8.0, 22.0))
		dot.set_meta("phase", randf_range(0.6, 1.8))
		add_child(dot)
		_glow_particles.append(dot)

# ── 軍事網格裝飾 ──────────────────────────────────────────────────────
func _build_decos() -> void:
	# 頂部 HUD 角框（左上 + 右上），戰術介面感
	_corner_bracket(Vector2(40, 60), false, false)
	_corner_bracket(Vector2(CW - 40, 60), true, false)

	# 左右斜線（保留原氛圍但更精緻）
	var left_bar := ColorRect.new()
	left_bar.size     = Vector2(6, 640)
	left_bar.position = Vector2(64, 220)
	left_bar.color    = Color(COL_STEEL.r, COL_STEEL.g, COL_STEEL.b, 0.22)
	left_bar.rotation = deg_to_rad(-12)
	add_child(left_bar)

	var right_bar := ColorRect.new()
	right_bar.size     = Vector2(6, 640)
	right_bar.position = Vector2(CW - 70, 220)
	right_bar.color    = Color(COL_STEEL.r, COL_STEEL.g, COL_STEEL.b, 0.22)
	right_bar.rotation = deg_to_rad(-12)
	add_child(right_bar)

	# 中央細網格（標題下方裝飾條）
	for i in range(7):
		var tick := ColorRect.new()
		tick.size = Vector2(2, 14)
		tick.position = Vector2(420 + i * 40, 792)
		tick.color = Color(COL_STEEL.r, COL_STEEL.g, COL_STEEL.b, 0.35)
		add_child(tick)

func _corner_bracket(origin: Vector2, mirror_x: bool, mirror_y: bool) -> void:
	var len_h := 64.0
	var len_v := 64.0
	var sx := -1.0 if mirror_x else 1.0
	var sy := -1.0 if mirror_y else 1.0
	var h := ColorRect.new()
	h.size = Vector2(len_h, 4)
	h.position = origin + Vector2(0 if sx > 0 else -len_h, 0)
	h.color = Color(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, 0.55)
	add_child(h)
	var v := ColorRect.new()
	v.size = Vector2(4, len_v)
	v.position = origin + Vector2(0, 0 if sy > 0 else -len_v)
	v.color = Color(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, 0.55)
	add_child(v)

# ── 標題區 ────────────────────────────────────────────────────────────
func _build_title() -> void:
	_title_node = Control.new()
	_title_node.position = Vector2(0, 0)
	_title_node.size = Vector2(CW, CH)
	add_child(_title_node)

	# 標題後方光暈
	var glow := ColorRect.new()
	glow.name = "TitleGlow"
	glow.position = Vector2(140, 500)
	glow.size     = Vector2(CW - 280, 200)
	glow.color    = Color(COL_ORANGE.r, COL_ORANGE.g, COL_ORANGE.b, 0.20)
	_title_node.add_child(glow)

	# 主標題「幽靈行動」
	var title := Label.new()
	title.text = "幽靈行動"
	title.position = Vector2(0, 510)
	title.size     = Vector2(CW, 140)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 104)
	title.add_theme_color_override("font_color", COL_INK)
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.08, 0.30, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 5)
	title.add_theme_color_override("font_outline_color", Color(COL_ORANGE.r, COL_ORANGE.g, COL_ORANGE.b, 0.5))
	title.add_theme_constant_override("outline_size", 6)
	if _font:
		title.add_theme_font_override("font", _font)
	_title_node.add_child(title)

	# 副標題「GHOST MISSION」+ 兩側線條
	var sub := Label.new()
	sub.text = "G H O S T   M I S S I O N"
	sub.position = Vector2(0, 656)
	sub.size     = Vector2(CW, 50)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 30)
	sub.add_theme_color_override("font_color", Color(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, 0.9))
	if _font:
		sub.add_theme_font_override("font", _font)
	_title_node.add_child(sub)

	# 副標兩側裝飾線
	var ll := ColorRect.new()
	ll.position = Vector2(250, 680)
	ll.size = Vector2(70, 2)
	ll.color = Color(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, 0.6)
	_title_node.add_child(ll)
	var rl := ColorRect.new()
	rl.position = Vector2(CW - 320, 680)
	rl.size = Vector2(70, 2)
	rl.color = Color(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, 0.6)
	_title_node.add_child(rl)

	# 副副標題
	var sub2 := Label.new()
	sub2.text = "戰術潛入 · 傭兵養成"
	sub2.position = Vector2(0, 722)
	sub2.size     = Vector2(CW, 46)
	sub2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub2.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	sub2.add_theme_font_size_override("font_size", 26)
	sub2.add_theme_color_override("font_color", Color(0.55, 0.70, 0.88, 0.80))
	if _font:
		sub2.add_theme_font_override("font", _font)
	_title_node.add_child(sub2)

# ── 按鈕區 ────────────────────────────────────────────────────────────
func _build_buttons() -> void:
	var has_save := _has_save()

	if has_save:
		# 有存檔：繼續（主） + 開始新遊戲（次）
		var cont := _make_menu_button("繼續任務", true)
		cont.position = Vector2(160, 980)
		cont.pressed.connect(_on_continue)
		add_child(cont)
		_attach_button_fx(cont)

		var fresh := _make_menu_button("新的開始", false)
		fresh.position = Vector2(160, 1140)
		fresh.pressed.connect(_on_start)
		add_child(fresh)
		_attach_button_fx(fresh)
	else:
		# 無存檔：開始遊戲（主）
		var start := _make_menu_button("開始遊戲", true)
		start.position = Vector2(160, 1040)
		start.pressed.connect(_on_start)
		add_child(start)
		_attach_button_fx(start)

func _make_menu_button(txt: String, primary: bool) -> Button:
	var btn := Button.new()
	btn.text     = txt
	btn.size     = Vector2(760, 140)
	btn.custom_minimum_size = Vector2(760, 140)
	btn.add_theme_font_size_override("font_size", 50 if primary else 40)
	btn.focus_mode = Control.FOCUS_NONE
	if _font:
		btn.add_theme_font_override("font", _font)

	var bg_normal: Color
	var bg_hover: Color
	var bg_press: Color
	var border: Color
	var font_col: Color
	if primary:
		bg_normal = Color(0.55, 0.28, 0.04)
		bg_hover  = Color(0.72, 0.38, 0.06)
		bg_press  = Color(0.42, 0.20, 0.02)
		border    = COL_GOLD
		font_col  = Color(1.0, 0.96, 0.86)
	else:
		bg_normal = Color(0.08, 0.13, 0.22)
		bg_hover  = Color(0.13, 0.20, 0.32)
		bg_press  = Color(0.05, 0.09, 0.16)
		border    = COL_STEEL
		font_col  = Color(0.82, 0.90, 1.0)

	btn.add_theme_color_override("font_color", font_col)
	btn.add_theme_color_override("font_hover_color", font_col)
	btn.add_theme_color_override("font_pressed_color", font_col)

	var st := StyleBoxFlat.new()
	st.bg_color = bg_normal
	st.border_color = border
	st.set_border_width_all(3)
	st.set_corner_radius_all(16)
	st.shadow_color = Color(0, 0, 0, 0.5)
	st.shadow_size = 8
	st.shadow_offset = Vector2(0, 4)
	btn.add_theme_stylebox_override("normal", st)

	var sh := st.duplicate() as StyleBoxFlat
	sh.bg_color = bg_hover
	sh.set_border_width_all(4)
	btn.add_theme_stylebox_override("hover", sh)

	var sp := st.duplicate() as StyleBoxFlat
	sp.bg_color = bg_press
	sp.shadow_size = 2
	sp.shadow_offset = Vector2(0, 1)
	btn.add_theme_stylebox_override("pressed", sp)

	btn.pivot_offset = Vector2(380, 70)
	return btn

# 按鈕互動回饋：hover 放大、按下縮小
func _attach_button_fx(btn: Button) -> void:
	btn.mouse_entered.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_ease(Tween.EASE_OUT)
	)
	btn.button_down.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(0.97, 0.97), 0.06)
	)
	btn.button_up.connect(func():
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

func _has_save() -> bool:
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null:
		return false
	# 嘗試多種既有判斷方式，避免依賴單一 API
	if sm.has_method("has_save"):
		return sm.has_save()
	if sm.has_method("save_exists"):
		return sm.save_exists()
	# 後備：以金幣或擁有卡片是否存在判斷
	var owned = sm.get("owned_cards")
	if owned is Dictionary and not owned.is_empty():
		return true
	return false

# ── 版本標示 ──────────────────────────────────────────────────────────
func _build_version() -> void:
	var lbl := Label.new()
	lbl.text     = "v0.6.4 DEMO"
	lbl.position = Vector2(700, 1850)
	lbl.size     = Vector2(360, 30)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.40, 0.45, 0.55, 0.7))
	if _font:
		lbl.add_theme_font_override("font", _font)
	add_child(lbl)

# ── 進場 Fade 遮罩 ────────────────────────────────────────────────────
func _build_fade() -> void:
	_fade = ColorRect.new()
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.color        = Color(0, 0, 0, 1.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

# ── 場景切換 ──────────────────────────────────────────────────────────
func _on_start() -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("btn_click")
	_goto_base()

func _on_continue() -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("btn_click")
	_goto_base()

func _goto_base() -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.40).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): get_tree().change_scene_to_file(BASE_SCENE_PATH))
