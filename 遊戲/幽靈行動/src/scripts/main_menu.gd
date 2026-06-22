extends Control

const CHINESE_FONT_PATH := "res://resources/fonts/chinese_font.ttf"
const BASE_SCENE_PATH    := "res://scenes/Base.tscn"

# 畫布規格 1080×1920
const CW := 1080.0
const CH := 1920.0

var _font: FontFile
var _fade: ColorRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists(CHINESE_FONT_PATH):
		_font = load(CHINESE_FONT_PATH)
	_build_bg()
	_build_decos()
	_build_title()
	_build_button()
	_build_version()
	_build_fade()
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.85).set_ease(Tween.EASE_OUT)

# ── 背景 ─────────────────────────────────────────────────────────────
func _build_bg() -> void:
	# 主背景深藍黑
	var bg := ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size     = Vector2(CW, CH)
	bg.color    = Color(0.02, 0.04, 0.10)
	add_child(bg)

	# 上半層次感漸層（較亮一點）
	var grad := ColorRect.new()
	grad.position = Vector2(0, 0)
	grad.size     = Vector2(CW, CH * 0.55)
	grad.color    = Color(0.04, 0.08, 0.18, 0.7)
	add_child(grad)

# ── 軍事斜線裝飾 ──────────────────────────────────────────────────────
func _build_decos() -> void:
	# 左側斜線（旋轉矩形）
	var left_bar := ColorRect.new()
	left_bar.size     = Vector2(8, 600)
	left_bar.position = Vector2(60, 200)
	left_bar.color    = Color(0.15, 0.25, 0.55, 0.30)
	left_bar.rotation = deg_to_rad(-12)
	add_child(left_bar)

	var left_bar2 := ColorRect.new()
	left_bar2.size     = Vector2(3, 480)
	left_bar2.position = Vector2(90, 250)
	left_bar2.color    = Color(0.20, 0.35, 0.65, 0.20)
	left_bar2.rotation = deg_to_rad(-12)
	add_child(left_bar2)

	# 右側斜線
	var right_bar := ColorRect.new()
	right_bar.size     = Vector2(8, 600)
	right_bar.position = Vector2(CW - 70, 200)
	right_bar.color    = Color(0.15, 0.25, 0.55, 0.30)
	right_bar.rotation = deg_to_rad(-12)
	add_child(right_bar)

	var right_bar2 := ColorRect.new()
	right_bar2.size     = Vector2(3, 480)
	right_bar2.position = Vector2(CW - 98, 250)
	right_bar2.color    = Color(0.20, 0.35, 0.65, 0.20)
	right_bar2.rotation = deg_to_rad(-12)
	add_child(right_bar2)

# ── 標題區 ────────────────────────────────────────────────────────────
func _build_title() -> void:
	# 主標題「幽靈行動」— 垂直 1/3 處，字號 96，全寬居中
	var title := Label.new()
	title.text = "幽靈行動"
	title.position = Vector2(0, 520)
	title.size     = Vector2(CW, 130)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.1, 0.4, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	if _font:
		title.add_theme_font_override("font", _font)
	add_child(title)

	# 副標題「GHOST MISSION」
	var sub := Label.new()
	sub.text = "GHOST MISSION"
	sub.position = Vector2(0, 658)
	sub.size     = Vector2(CW, 55)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 28)
	sub.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.85))
	if _font:
		sub.add_theme_font_override("font", _font)
	add_child(sub)

	# 副副標題「戰術潛入 · 傭兵養成」
	var sub2 := Label.new()
	sub2.text = "戰術潛入 · 傭兵養成"
	sub2.position = Vector2(0, 718)
	sub2.size     = Vector2(CW, 50)
	sub2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub2.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	sub2.add_theme_font_size_override("font_size", 24)
	sub2.add_theme_color_override("font_color", Color(0.45, 0.65, 0.85, 0.75))
	if _font:
		sub2.add_theme_font_override("font", _font)
	add_child(sub2)

	# 分隔線：寬 300，居中 x=(1080-300)/2=390
	var line := ColorRect.new()
	line.position = Vector2(390, 775)
	line.size     = Vector2(300, 3)
	line.color    = Color(0.3, 0.5, 0.9, 0.6)
	add_child(line)

# ── 開始遊戲按鈕 ──────────────────────────────────────────────────────
func _build_button() -> void:
	var btn := Button.new()
	btn.text     = "開始遊戲"
	btn.position = Vector2(160, 820)
	btn.size     = Vector2(760, 140)
	btn.add_theme_font_size_override("font_size", 48)
	btn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.0))
	if _font:
		btn.add_theme_font_override("font", _font)

	# normal 樣式
	var st := StyleBoxFlat.new()
	st.bg_color     = Color(0.06, 0.12, 0.30)
	st.border_color = Color(0.3, 0.55, 0.9)
	st.set_border_width_all(2)
	st.set_corner_radius_all(12)
	btn.add_theme_stylebox_override("normal", st)

	# hover 樣式（稍亮）
	var sh := st.duplicate() as StyleBoxFlat
	sh.bg_color     = Color(0.10, 0.20, 0.48)
	sh.border_color = Color(0.45, 0.70, 1.0)
	btn.add_theme_stylebox_override("hover", sh)

	# pressed 樣式
	var sp := st.duplicate() as StyleBoxFlat
	sp.bg_color     = Color(0.04, 0.08, 0.20)
	sp.border_color = Color(0.25, 0.45, 0.75)
	btn.add_theme_stylebox_override("pressed", sp)

	btn.pressed.connect(_on_start)
	add_child(btn)

# ── 版本標示 ──────────────────────────────────────────────────────────
func _build_version() -> void:
	var lbl := Label.new()
	lbl.text     = "v0.5.6 DEMO"
	# 右下角：x=800, y=1880，寬 260，高 30
	lbl.position = Vector2(800, 1880)
	lbl.size     = Vector2(260, 30)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
	if _font:
		lbl.add_theme_font_override("font", _font)
	add_child(lbl)

# ── 進場 Fade 遮罩 ────────────────────────────────────────────────────
func _build_fade() -> void:
	_fade = ColorRect.new()
	# 遮罩必須覆蓋全螢幕，這裡用 PRESET_FULL_RECT 沒有問題
	# （根節點已設定 FULL_RECT，fade 跟著根節點拉伸，不是靠 anchor 計算子節點位置）
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.color        = Color(0, 0, 0, 1.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

# ── 場景切換 ──────────────────────────────────────────────────────────
func _on_start() -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.45).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): get_tree().change_scene_to_file(BASE_SCENE_PATH))
