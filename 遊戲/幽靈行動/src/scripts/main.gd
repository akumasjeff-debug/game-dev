extends Node2D

# 主場景腳本（v2 — 獨立房間架構）
# 每關全螢幕顯示；小隊從底部進入 → 對戰 → 破門動畫 → 下一關

const CHARACTER_SCRIPT = preload("res://scripts/character.gd")
const ROOM_SCRIPT      = preload("res://scripts/room.gd")

# ─────────────────────────────────────────────────────────────
#  關卡配置（level 1：4 房）
#  offset = 相對於房間中心 Vector2(540, 960)
# ─────────────────────────────────────────────────────────────
const ROOM_CONFIGS: Array = [
	{
		"label": "1-1",
		"enemies": [
			{"type": 0, "offset": Vector2(-200, -520)},
			{"type": 0, "offset": Vector2(0,   -560)},
			{"type": 0, "offset": Vector2(200,  -520)},
		]
	},
	{
		"label": "1-2",
		"enemies": [
			{"type": 0, "offset": Vector2(-250, -500)},
			{"type": 1, "offset": Vector2(0,   -545)},
			{"type": 0, "offset": Vector2(250,  -500)},
		]
	},
	{
		"label": "1-3",
		"enemies": [
			{"type": 0, "offset": Vector2(-280, -510)},
			{"type": 0, "offset": Vector2(-80,  -550)},
			{"type": 0, "offset": Vector2(80,   -550)},
			{"type": 1, "offset": Vector2(280,  -510)},
		]
	},
	{
		"label": "Boss",
		"enemies": [
			{"type": 0, "offset": Vector2(-220, -490)},
			{"type": 2, "offset": Vector2(0,   -545)},
			{"type": 0, "offset": Vector2(220,  -490)},
		]
	},
]

# 小隊站位（全螢幕 1080×1920；y=1540 在 HUD 上方）
const SQUAD_COMBAT_Y   := 1520.0
const SQUAD_ENTRY_Y    := 2180.0
const SQUAD_X_SLOTS: Array = [162.0, 378.0, 594.0, 810.0]

# ─────────────────────────────────────────────────────────────
#  角色基礎資料（Lv.1 × 稀有度 × 等級 乘率 → SaveManager）
# ─────────────────────────────────────────────────────────────
const CHAR_DATA = [
	{"id": "shield",  "name": "盾兵",   "color": Color(0.267, 0.533, 1.0,  1.0), "max_hp": 500.0, "attack": 30.0,  "defense": 25.0, "ult_name": "防禦護盾", "ult_cd": 30.0},  # HP 400→500：讓前線多撐 2~3s
	{"id": "medic",   "name": "醫療兵", "color": Color(0.267, 0.800, 0.267,1.0), "max_hp": 260.0, "attack": 20.0,  "defense": 15.0, "ult_name": "緊急治療", "ult_cd": 40.0},
	{"id": "assault", "name": "突擊手", "color": Color(0.910, 0.376, 0.039,1.0), "max_hp": 310.0, "attack": 60.0,  "defense": 15.0, "ult_name": "火力全開", "ult_cd": 25.0},
	{"id": "sniper",  "name": "狙擊手", "color": Color(0.667, 0.267, 1.0,  1.0), "max_hp": 220.0, "attack": 120.0, "defense": 10.0, "ult_name": "精準鎖定", "ult_cd": 35.0},
	{"id": "demo",    "name": "爆破手", "color": Color(0.800, 0.133, 0.133,1.0), "max_hp": 270.0, "attack": 80.0,  "defense": 18.0, "ult_name": "引爆炸彈", "ult_cd": 45.0},
	{"id": "recon",   "name": "偵察手", "color": Color(0.267, 0.800, 0.800,1.0), "max_hp": 280.0, "attack": 35.0,  "defense": 17.0, "ult_name": "煙霧封鎖", "ult_cd": 35.0},
]

var hud_scene: Node
var _active_room: Node = null
var _current_room_idx: int = 0
var _room_visual: Node = null
var _room_foreground: Node = null  # 玩家掩體前景層（z=5，畫在角色之上）

# 門動畫節點（left/right/frame — 保留 breach animation 用）
var _door_left: ColorRect  = null
var _door_right: ColorRect = null
var _door_frame: ColorRect = null

# 破門點擊推進狀態（用 _input 偵測觸控/點擊，Button 在真機觸控不可靠）
var _breach_active: bool = false
var _breach_cl: CanvasLayer = null
var _breach_tween: Tween = null
var _breach_on_complete: Callable = Callable()

# ─────────────────────────────────────────────────────────────
#  初始化
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	_spawn_squad()
	_connect_hud()
	_start_mission_bgm()
	_start_room(0)

# ─────────────────────────────────────────────────────────────
#  關卡推進
# ─────────────────────────────────────────────────────────────
func _start_room(idx: int) -> void:
	_current_room_idx = idx
	GameManager.progress = float(idx) / float(ROOM_CONFIGS.size())

	# 清除舊房間
	if _active_room and is_instance_valid(_active_room):
		_active_room.queue_free()
		_active_room = null
	if _room_visual and is_instance_valid(_room_visual):
		_room_visual.queue_free()
		_room_visual = null
	if _room_foreground and is_instance_valid(_room_foreground):
		_room_foreground.queue_free()
		_room_foreground = null

	_build_room_visual(idx)

	# 小隊進場動畫，結束後建立戰鬥房間
	_squad_enter(func():
		var cfg: Dictionary = ROOM_CONFIGS[idx]
		var room = ROOM_SCRIPT.new()
		room.room_label  = cfg["label"]
		room.enemy_configs = cfg["enemies"].duplicate(true)
		room.position    = Vector2(540, 960)
		room.name        = "Room_" + cfg["label"]
		add_child(room)
		_active_room = room
		room.room_cleared.connect(_on_room_cleared)
		room.start_battle("charge")
	)

func _squad_enter(on_done: Callable) -> void:
	var members := GameManager.squad_members
	if members.is_empty():
		on_done.call()
		return

	# 進場動畫期間暫停自動攻擊
	GameManager.is_paused = true

	var count := mini(members.size(), SQUAD_X_SLOTS.size())
	for i in range(count):
		var m = members[i]
		if m and is_instance_valid(m):
			m.global_position = Vector2(SQUAD_X_SLOTS[i], SQUAD_ENTRY_Y)

	var tw := create_tween()
	var is_first := true
	for i in range(count):
		var m = members[i]
		if m == null or not is_instance_valid(m):
			continue
		if is_first:
			tw.tween_property(m, "global_position:y", SQUAD_COMBAT_Y, 0.85)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			is_first = false
		else:
			tw.parallel().tween_property(m, "global_position:y", SQUAD_COMBAT_Y, 0.85)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func():
		# 到達戰鬥位置，恢復自動攻擊
		GameManager.is_paused = false
		on_done.call()
	)

func _on_room_cleared() -> void:
	var old_room := _active_room
	_active_room = null
	if old_room and is_instance_valid(old_room):
		old_room.queue_free()
	for m in GameManager.squad_members:
		if m and is_instance_valid(m) and m.has_method("set_cover_mode"):
			m.set_cover_mode(false)

	await get_tree().create_timer(0.3).timeout

	var next_idx := _current_room_idx + 1
	if next_idx >= ROOM_CONFIGS.size():
		GameManager.trigger_game_over(true)
		return

	_play_door_open_animation(0.0, func():
		_start_room(next_idx)
	)

# room.gd 呼叫此方法時小隊已在正確站位
# 掩體改為後景層後，角色保持站立完整顯示（不蹲伏），讓模組更突出
func _position_squad_for_combat(_rp: Vector2, _rs: Vector2) -> void:
	for m in GameManager.squad_members:
		if m and is_instance_valid(m) and m.has_method("set_cover_mode"):
			m.set_cover_mode(false)

# ─────────────────────────────────────────────────────────────
#  房間視覺建立
# ─────────────────────────────────────────────────────────────
func _build_room_visual(idx: int) -> void:
	var visual := Node2D.new()
	visual.name = "RoomVisual"
	visual.z_index = -10  # 背景層：永遠在小隊角色與敵人之下（否則全螢幕 bg 會蓋住角色）
	_room_visual  = visual
	add_child(visual)

	var cfg: Dictionary = ROOM_CONFIGS[idx]
	var is_boss: bool = cfg["label"] == "Boss"
	var theme := _get_room_theme()  # "office" | "warehouse" | "harbor"
	var bg_col  := Color(0.16, 0.04, 0.05) if is_boss else _get_mission_room_color()

	# ── 1. 全螢幕底色 ──
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size     = Vector2(1080, 1920)
	bg.color    = bg_col
	visual.add_child(bg)

	# ── 2. 牆面區（上方為敵方背牆，建立「房間後牆」感）──
	_build_back_wall(visual, theme, is_boss)

	# ── 3. 地板：紋理 tile + 透視格線（縱深感）──
	var tile := _get_floor_tile_path()
	if ResourceLoader.exists(tile):
		var tr := TextureRect.new()
		tr.texture        = load(tile)
		tr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		tr.stretch_mode   = TextureRect.STRETCH_TILE
		tr.position       = Vector2(0, 470)
		tr.size           = Vector2(1080, 1450)
		tr.modulate       = Color(1, 1, 1, 0.20)
		visual.add_child(tr)
	_build_floor_perspective(visual, theme)

	# ── 4. 牆/地接縫分界線（戰術感）──
	var divider := ColorRect.new()
	divider.position = Vector2(0, 470)
	divider.size     = Vector2(1080, 4)
	divider.color    = _theme_accent(theme, 0.5)
	visual.add_child(divider)
	var divider_glow := ColorRect.new()
	divider_glow.position = Vector2(0, 474)
	divider_glow.size     = Vector2(1080, 10)
	divider_glow.color    = _theme_accent(theme, 0.12)
	visual.add_child(divider_glow)

	# ── 5. 區域光照（敵方上方燈光錐 + 我方下方暖光）──
	_build_ambient_lighting(visual, theme, is_boss)

	# ── 6. 中段環境素材（兩側分布避開中央對戰通道）──
	_add_environment_props(visual)

	# ── 7. 氛圍光效：警示燈光帶 / 地面反光 / 暗角 ──
	_build_atmosphere_fx(visual, theme, is_boss)

	# 敵人掩體（上方）
	var ec_defs: Array = [
		{"svg": "res://resources/art/props/enemy_cover_left.svg",  "x": 55,  "y": 380, "w": 300, "h": 22},
		{"svg": "res://resources/art/props/enemy_cover_mid.svg",   "x": 390, "y": 330, "w": 300, "h": 22},
		{"svg": "res://resources/art/props/enemy_cover_right.svg", "x": 725, "y": 380, "w": 300, "h": 22},
	]
	for ecd in ec_defs:
		_add_cover(visual, ecd["svg"],
			Vector2(ecd["x"], ecd["y"]), Vector2(ecd["w"], ecd["h"]),
			Color(0.40, 0.30, 0.25, 0.7))

	# 玩家掩體：4 段獨立沙袋堆（中間不相連），各對應一個角色站位
	# 後景層（z=-1）畫在角色之下 → 完整角色模組顯示在掩體前方，更突出
	# 固定位置不隨角色移動
	var fg := Node2D.new()
	fg.name = "RoomCoverBack"
	fg.z_index = -1
	_room_foreground = fg
	add_child(fg)

	for sx in SQUAD_X_SLOTS:
		_add_cover(fg, "res://resources/art/props/player_cover_seg.svg",
			Vector2(sx - 90.0, 1518.0), Vector2(180, 56),
			Color(0.43, 0.42, 0.30, 0.95))

	# 房間標籤底色（提升可讀性，半透明深色帶）
	var lbl_bg := ColorRect.new()
	lbl_bg.position = Vector2(0, 10)
	lbl_bg.size     = Vector2(1080, 60)
	lbl_bg.color    = Color(0.0, 0.0, 0.0, 0.55)
	visual.add_child(lbl_bg)

	# 房間標籤 — 主標題（大字，左側）
	var lbl := Label.new()
	lbl.text     = "ROOM  %s" % cfg["label"]
	lbl.position = Vector2(30, 14)
	lbl.size     = Vector2(600, 46)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color",
		Color(1.0, 0.5, 0.5, 1.0) if is_boss else Color(0.85, 0.92, 1.0, 1.0))
	if ResourceLoader.exists("res://resources/fonts/chinese_font.ttf"):
		lbl.add_theme_font_override("font", load("res://resources/fonts/chinese_font.ttf"))
	visual.add_child(lbl)

	# BOSS 警告標籤（右側，醒目橙紅）
	if is_boss:
		var boss_warn := Label.new()
		boss_warn.text     = "! BOSS !"
		boss_warn.position = Vector2(650, 14)
		boss_warn.size     = Vector2(400, 46)
		boss_warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		boss_warn.add_theme_font_size_override("font_size", 28)
		boss_warn.add_theme_color_override("font_color", Color(1.0, 0.30, 0.15, 1.0))
		if ResourceLoader.exists("res://resources/fonts/chinese_font.ttf"):
			boss_warn.add_theme_font_override("font", load("res://resources/fonts/chinese_font.ttf"))
		visual.add_child(boss_warn)

func _add_environment_props(parent: Node) -> void:
	var mid: String = GameManager.current_mission_id if GameManager else "demo_01"

	# [svg, x, y, w, h, fallback_color]
	# 兩側貼牆擺放，避開中央對戰通道（y=920~1380，x<140 或 x>940）
	var props: Array = []

	match mid:
		"warehouse_01":
			props = [
				# 左側：堆疊木箱（大→小，層次）+ 油桶 + 警戒斜紋
				["res://resources/art/props/parking_pillar.svg",  0, 500,  18, 920, Color(0.16, 0.16, 0.18)],
				["res://resources/art/props/crate.svg",           14, 560,  96,  96, Color(0.35, 0.28, 0.18)],
				["res://resources/art/props/crate.svg",           40, 656,  64,  64, Color(0.30, 0.24, 0.15)],
				["res://resources/art/props/hazard_stripe.svg",   10, 740, 120,  24, Color(0.55, 0.45, 0.10)],
				["res://resources/art/props/barrel.svg",          16, 930,  56,  78, Color(0.25, 0.28, 0.20)],
				["res://resources/art/props/crate.svg",           20,1020,  74,  74, Color(0.35, 0.28, 0.18)],
				["res://resources/art/props/barrel.svg",          30,1120,  52,  72, Color(0.22, 0.30, 0.22)],
				["res://resources/art/props/crate.svg",           18,1230,  64,  64, Color(0.30, 0.24, 0.15)],
				# 右側鏡像
				["res://resources/art/props/parking_pillar.svg",1062, 500,  18, 920, Color(0.16, 0.16, 0.18)],
				["res://resources/art/props/crate.svg",          970, 560,  96,  96, Color(0.35, 0.28, 0.18)],
				["res://resources/art/props/crate.svg",          976, 656,  64,  64, Color(0.30, 0.24, 0.15)],
				["res://resources/art/props/hazard_stripe.svg",  950, 740, 120,  24, Color(0.55, 0.45, 0.10)],
				["res://resources/art/props/barrel.svg",        1008, 930,  56,  78, Color(0.25, 0.28, 0.20)],
				["res://resources/art/props/crate.svg",          986,1020,  74,  74, Color(0.35, 0.28, 0.18)],
				["res://resources/art/props/barrel.svg",        1000,1120,  52,  72, Color(0.22, 0.30, 0.22)],
				["res://resources/art/props/crate.svg",          998,1230,  64,  64, Color(0.30, 0.24, 0.15)],
			]
		"harbor_01":
			props = [
				# 左側：貨櫃疊高（深藍）+ 油桶 + 繩堆 + 警戒斜紋
				["res://resources/art/props/harbor_container.svg",  2, 520, 120, 130, Color(0.12, 0.28, 0.40)],
				["res://resources/art/props/harbor_container.svg", 10, 650,  96, 100, Color(0.10, 0.24, 0.34)],
				["res://resources/art/props/hazard_stripe.svg",     6, 760, 120,  24, Color(0.55, 0.45, 0.10)],
				["res://resources/art/props/barrel.svg",           18, 930,  54,  74, Color(0.20, 0.25, 0.30)],
				["res://resources/art/props/harbor_rope.svg",      10,1018,  70,  22, Color(0.42, 0.35, 0.22)],
				["res://resources/art/props/harbor_container.svg",  8,1060, 100, 110, Color(0.12, 0.28, 0.40)],
				["res://resources/art/props/barrel.svg",           22,1200,  54,  74, Color(0.20, 0.25, 0.30)],
				# 右側鏡像
				["res://resources/art/props/harbor_container.svg", 958, 520, 120, 130, Color(0.12, 0.28, 0.40)],
				["res://resources/art/props/harbor_container.svg", 974, 650,  96, 100, Color(0.10, 0.24, 0.34)],
				["res://resources/art/props/hazard_stripe.svg",    954, 760, 120,  24, Color(0.55, 0.45, 0.10)],
				["res://resources/art/props/barrel.svg",          1008, 930,  54,  74, Color(0.20, 0.25, 0.30)],
				["res://resources/art/props/harbor_rope.svg",      1000,1018,  70,  22, Color(0.42, 0.35, 0.22)],
				["res://resources/art/props/harbor_container.svg", 972,1060, 100, 110, Color(0.12, 0.28, 0.40)],
				["res://resources/art/props/barrel.svg",          1004,1200,  54,  74, Color(0.20, 0.25, 0.30)],
			]
		_:  # office（預設）
			props = [
				# 左側：伺服器機架 + 置物櫃 + 辦公桌 + 木箱 + 牆裂
				["res://resources/art/props/wall_crack.svg",      0, 500,  16, 920, Color(0.13, 0.13, 0.17)],
				["res://resources/art/props/server_rack.svg",     8, 540,  74, 170, Color(0.20, 0.20, 0.26)],
				["res://resources/art/props/server_rack.svg",    14, 712,  64, 150, Color(0.18, 0.18, 0.24)],
				["res://resources/art/props/locker.svg",         12, 930,  62, 104, Color(0.20, 0.30, 0.25)],
				["res://resources/art/props/desk.svg",            6,1050,  96,  72, Color(0.30, 0.24, 0.16)],
				["res://resources/art/props/crate.svg",          20,1150,  62,  62, Color(0.32, 0.28, 0.22)],
				["res://resources/art/props/locker.svg",         12,1230,  62, 104, Color(0.20, 0.30, 0.25)],
				# 右側鏡像
				["res://resources/art/props/wall_crack.svg",    1064, 500,  16, 920, Color(0.13, 0.13, 0.17)],
				["res://resources/art/props/server_rack.svg",    998, 540,  74, 170, Color(0.20, 0.20, 0.26)],
				["res://resources/art/props/server_rack.svg",   1002, 712,  64, 150, Color(0.18, 0.18, 0.24)],
				["res://resources/art/props/locker.svg",        1006, 930,  62, 104, Color(0.20, 0.30, 0.25)],
				["res://resources/art/props/desk.svg",           978,1050,  96,  72, Color(0.30, 0.24, 0.16)],
				["res://resources/art/props/crate.svg",          998,1150,  62,  62, Color(0.32, 0.28, 0.22)],
				["res://resources/art/props/locker.svg",        1006,1230,  62, 104, Color(0.20, 0.30, 0.25)],
			]

	for p in props:
		var svg: String = p[0]
		var pos := Vector2(float(p[1]), float(p[2]))
		var sz  := Vector2(float(p[3]), float(p[4]))
		var col: Color = p[5]
		if ResourceLoader.exists(svg):
			var tr := TextureRect.new()
			tr.texture      = load(svg)
			tr.position     = pos
			tr.size         = sz
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			parent.add_child(tr)
		else:
			var cr := ColorRect.new()
			cr.position = pos
			cr.size     = sz
			cr.color    = col
			parent.add_child(cr)

func _add_cover(parent: Node, svg: String, pos: Vector2, size: Vector2, fallback: Color) -> void:
	if ResourceLoader.exists(svg):
		var tr := TextureRect.new()
		tr.texture      = load(svg)
		tr.position     = pos
		tr.size         = size
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		parent.add_child(tr)
	else:
		var cr := ColorRect.new()
		cr.position = pos
		cr.size     = size
		cr.color    = fallback
		parent.add_child(cr)

# ─────────────────────────────────────────────────────────────
#  場景氛圍建構（背牆 / 透視地板 / 光照 / 暗角）
#  注意：會建立 ColorRect 的區域變數一律 untyped，避免 Godot 4.6
#  對 `var x: Node2D = ColorRect.new()` 觸發 parse 警告/錯誤。
# ─────────────────────────────────────────────────────────────

# 主題判定：office / warehouse / harbor
func _get_room_theme() -> String:
	var mid: String = GameManager.current_mission_id if GameManager else "demo_01"
	match mid:
		"warehouse_01": return "warehouse"
		"harbor_01":    return "harbor"
		_:              return "office"

# 各主題強調色（警示燈/分界線/光暈用）
func _theme_accent(theme: String, a: float) -> Color:
	match theme:
		"warehouse": return Color(0.95, 0.62, 0.15, a)   # 工業橙
		"harbor":    return Color(0.25, 0.70, 0.95, a)   # 港口冷藍
		_:           return Color(0.45, 0.70, 1.00, a)   # 辦公冷白藍

# 背牆：上方為敵方所在的房間後牆，分層提升縱深
func _build_back_wall(parent: Node, theme: String, is_boss: bool) -> void:
	# 後牆主面板（頂部到地板分界 y=470）
	var wall = ColorRect.new()
	wall.position = Vector2(0, 0)
	wall.size     = Vector2(1080, 470)
	match theme:
		"warehouse": wall.color = Color(0.09, 0.085, 0.10)
		"harbor":    wall.color = Color(0.06, 0.10, 0.14)
		_:           wall.color = Color(0.10, 0.11, 0.15)
	if is_boss:
		wall.color = Color(0.12, 0.05, 0.06)
	parent.add_child(wall)

	# 牆面踢腳暗帶（牆與地交界陰影）
	var skirt = ColorRect.new()
	skirt.position = Vector2(0, 430)
	skirt.size     = Vector2(1080, 40)
	skirt.color    = Color(0, 0, 0, 0.45)
	parent.add_child(skirt)

	# 牆面垂直分隔柱（建立牆面結構），三條
	for wx in [270.0, 540.0, 810.0]:
		var pil = ColorRect.new()
		pil.position = Vector2(wx - 6, 0)
		pil.size     = Vector2(12, 430)
		pil.color    = Color(0, 0, 0, 0.22)
		parent.add_child(pil)

	# 主題特徵牆飾
	match theme:
		"office":
			# 兩扇夜景窗
			for ox in [120.0, 720.0]:
				_blit_svg(parent, "res://resources/art/props/office_window.svg",
					Vector2(ox, 70), Vector2(140, 230), Color(0.12, 0.18, 0.28))
		"warehouse":
			# 牆面管線
			_blit_svg(parent, "res://resources/art/props/pipe_vertical.svg",
				Vector2(70, 10), Vector2(40, 420), Color(0.16, 0.16, 0.18))
			_blit_svg(parent, "res://resources/art/props/pipe_vertical.svg",
				Vector2(970, 10), Vector2(40, 420), Color(0.16, 0.16, 0.18))
		"harbor":
			# 遠景起重機剪影
			_blit_svg(parent, "res://resources/art/props/harbor_crane.svg",
				Vector2(620, 40), Vector2(220, 400), Color(0.08, 0.14, 0.20))

# 透視地板格線：縱向線向中心 (540) 收斂，橫向線間距隨深度遞增 → 假 3D 縱深
func _build_floor_perspective(parent: Node, theme: String) -> void:
	var line_col := _theme_accent(theme, 0.10)
	var horizon_x := 540.0
	var top_y := 480.0
	var bot_y := 1900.0

	# 縱向收斂線（從底部均分點連向頂部消失點附近）
	var bottom_xs: Array = [-120.0, 120.0, 360.0, 540.0, 720.0, 960.0, 1200.0]
	for bx in bottom_xs:
		var top_x: float = lerpf(bx, horizon_x, 0.62)
		var ln := Line2D.new()
		ln.add_point(Vector2(top_x, top_y))
		ln.add_point(Vector2(bx, bot_y))
		ln.width = 2.0
		ln.default_color = line_col
		ln.antialiased = false
		parent.add_child(ln)

	# 橫向線：間距由上而下加大（近大遠小）
	var ys: Array = [560.0, 700.0, 880.0, 1110.0, 1400.0, 1760.0]
	for gy in ys:
		# 越往下越寬、越亮
		var t: float = clampf((gy - top_y) / (bot_y - top_y), 0.0, 1.0)
		var hln := Line2D.new()
		hln.add_point(Vector2(0, gy))
		hln.add_point(Vector2(1080, gy))
		hln.width = 1.0 + t * 2.0
		hln.default_color = _theme_accent(theme, 0.05 + t * 0.08)
		hln.antialiased = false
		parent.add_child(hln)

# 區域光照：敵方頂燈光錐（梯形 Polygon2D）+ 我方下方暖光
func _build_ambient_lighting(parent: Node, theme: String, is_boss: bool) -> void:
	var cone_col := _theme_accent(theme, 0.06)
	if is_boss:
		cone_col = Color(0.95, 0.20, 0.15, 0.07)

	# 敵方上方三道頂燈光錐（梯形：燈在牆頂，向地面擴散）
	for cx in [270.0, 540.0, 810.0]:
		var cone := Polygon2D.new()
		cone.polygon = PackedVector2Array([
			Vector2(cx - 70, 40),
			Vector2(cx + 70, 40),
			Vector2(cx + 180, 720),
			Vector2(cx - 180, 720),
		])
		cone.color = cone_col
		parent.add_child(cone)
		# 燈具本體
		_blit_svg(parent, "res://resources/art/props/ceiling_light.svg",
			Vector2(cx - 80, 24), Vector2(160, 40), _theme_accent(theme, 0.6))

	# 我方下方暖色聚光（角色站位區，烘托主角）
	var warm := Polygon2D.new()
	warm.polygon = PackedVector2Array([
		Vector2(120, 1920),
		Vector2(960, 1920),
		Vector2(760, 1340),
		Vector2(320, 1340),
	])
	warm.color = Color(0.40, 0.34, 0.22, 0.10) if not is_boss else Color(0.5, 0.18, 0.15, 0.10)
	parent.add_child(warm)

# 氛圍特效：暗角(vignette) + 警示燈光斑 + 邊緣漸層
func _build_atmosphere_fx(parent: Node, theme: String, is_boss: bool) -> void:
	# 四邊暗角：用半透明黑長條框出（手機直屏，左右+上下）
	var vig_specs: Array = [
		[Vector2(0, 0),    Vector2(1080, 140)],    # 上
		[Vector2(0, 1780), Vector2(1080, 140)],    # 下
		[Vector2(0, 0),    Vector2(110, 1920)],    # 左
		[Vector2(970, 0),  Vector2(110, 1920)],    # 右
	]
	for vs in vig_specs:
		var vg = ColorRect.new()
		vg.position = vs[0]
		vg.size     = vs[1]
		vg.color    = Color(0, 0, 0, 0.30)
		parent.add_child(vg)
	# 角落更深一層
	for cp in [Vector2(0, 0), Vector2(980, 0), Vector2(0, 1820), Vector2(980, 1820)]:
		var corner = ColorRect.new()
		corner.position = cp
		corner.size     = Vector2(100, 100)
		corner.color    = Color(0, 0, 0, 0.28)
		parent.add_child(corner)

	# 警示燈：Boss 房紅色雙閃，一般房依主題色（牆角光斑 + 燈具）
	var lamp_col := _theme_accent(theme, 1.0)
	if is_boss:
		lamp_col = Color(1.0, 0.22, 0.15, 1.0)
	for lx in [60.0, 980.0]:
		# 牆上警示燈本體
		_blit_svg(parent, "res://resources/art/props/warning_lamp.svg",
			Vector2(lx - 4, 360), Vector2(48, 56), lamp_col)
		# 燈光斑（向地面投射的紅/藍暈）
		var glow := Polygon2D.new()
		var gx: float = float(lx) + 20.0
		glow.polygon = PackedVector2Array([
			Vector2(gx - 50, 400),
			Vector2(gx + 50, 400),
			Vector2(gx + 130, 760),
			Vector2(gx - 130, 760),
		])
		glow.color = Color(lamp_col.r, lamp_col.g, lamp_col.b, 0.09)
		parent.add_child(glow)

	# Boss 房額外：地面血色警戒漫光帶
	if is_boss:
		var redfloor = ColorRect.new()
		redfloor.position = Vector2(0, 470)
		redfloor.size     = Vector2(1080, 300)
		redfloor.color    = Color(0.6, 0.05, 0.05, 0.06)
		parent.add_child(redfloor)

# 統一的 SVG 貼圖小工具（找不到資源時用 fallback 純色塊）
func _blit_svg(parent: Node, svg: String, pos: Vector2, size: Vector2, fallback: Color) -> void:
	if ResourceLoader.exists(svg):
		var tr := TextureRect.new()
		tr.texture      = load(svg)
		tr.position     = pos
		tr.size         = size
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		parent.add_child(tr)
	else:
		var cr = ColorRect.new()
		cr.position = pos
		cr.size     = size
		cr.color    = fallback
		parent.add_child(cr)

# ─────────────────────────────────────────────────────────────
#  任務主題色
# ─────────────────────────────────────────────────────────────
func _get_mission_room_color() -> Color:
	var mid: String = GameManager.current_mission_id if GameManager else "demo_01"
	match mid:
		"warehouse_01": return Color(0.05, 0.063, 0.09)
		"harbor_01":    return Color(0.04, 0.083, 0.125)
		_:              return Color(0.102, 0.125, 0.208)

func _get_floor_tile_path() -> String:
	var mid: String = GameManager.current_mission_id if GameManager else "demo_01"
	match mid:
		"warehouse_01": return "res://resources/art/props/floor_tile_warehouse.svg"
		"harbor_01":    return "res://resources/art/props/floor_tile_harbor.svg"
		_:              return "res://resources/art/props/floor_tile_office.svg"

# ─────────────────────────────────────────────────────────────
#  小隊生成
# ─────────────────────────────────────────────────────────────
func _spawn_squad() -> void:
	var squad_ids: Array = SaveManager.selected_squad
	if squad_ids.is_empty():
		squad_ids = ["shield", "assault", "demo", "medic"]

	var members: Array = []
	var spawn_idx := 0
	var class_count: Dictionary = {}

	for char_id in squad_ids:
		var data := _get_char_data(char_id)
		if data.is_empty():
			continue
		var char_node = CHARACTER_SCRIPT.new()
		char_node.name      = char_id + "_" + str(spawn_idx)
		char_node.char_id   = data["id"]
		char_node.char_name = data["name"]
		char_node.body_color= data["color"]
		var rarity_mult := SaveManager.get_rarity_multiplier(char_id)
		var level_mult  := SaveManager.get_level_multiplier(char_id)
		char_node.max_hp      = data["max_hp"]  * rarity_mult * level_mult
		char_node.attack_power= data["attack"]  * rarity_mult * level_mult
		char_node.defense     = data.get("defense", 0.0) * rarity_mult * level_mult
		char_node.ultimate_name = data["ult_name"]
		char_node.ultimate_cd   = data["ult_cd"]
		var same_cls: int = class_count.get(data["id"], 0)
		char_node.formation_offset = Vector2(float(same_cls) * 32.0, 0)
		class_count[data["id"]] = same_cls + 1
		var saved_level = SaveManager.character_levels.get(char_id, 1)
		char_node.level = saved_level
		char_node.add_to_group("squad")
		add_child(char_node)
		members.append(char_node)
		spawn_idx += 1

	GameManager.squad_members = members
	GameManager.is_paused     = false
	GameManager.is_game_over  = false

func _get_char_data(char_id: String) -> Dictionary:
	var class_id := char_id
	for suffix in ["_qr", "_ssr", "_sr", "_r"]:
		if char_id.ends_with(suffix):
			class_id = char_id.substr(0, char_id.length() - suffix.length())
			break
	for data in CHAR_DATA:
		if data["id"] == class_id:
			return data
	return {}

# ─────────────────────────────────────────────────────────────
#  HUD 連接
# ─────────────────────────────────────────────────────────────
func _connect_hud() -> void:
	hud_scene = $HUD
	if hud_scene and hud_scene.has_method("setup_cards"):
		hud_scene.setup_cards(GameManager.squad_members)

# ─────────────────────────────────────────────────────────────
#  BGM
# ─────────────────────────────────────────────────────────────
func _start_mission_bgm() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am == null:
		return
	var mid: String = GameManager.current_mission_id if GameManager else ""
	match mid:
		"warehouse_01": am.play_bgm("warehouse_bgm")
		"harbor_01":    am.play_bgm("harbor_bgm")
		_:              am.play_bgm("mission")

# ─────────────────────────────────────────────────────────────
#  破門過場動畫（可點擊跳過）
# ─────────────────────────────────────────────────────────────
func _play_door_open_animation(_door_y: float, on_complete: Callable) -> void:
	for v in [_door_left, _door_right, _door_frame]:
		if v and is_instance_valid(v):
			v.queue_free()
	_door_left  = null
	_door_right = null
	_door_frame = null

	var cl := CanvasLayer.new()
	cl.layer = 100  # 拉到最高，確保在 HUD 與任何疊加層之上
	add_child(cl)

	var bar_top := ColorRect.new()
	bar_top.color    = Color.BLACK
	bar_top.size     = Vector2(1080, 260)
	bar_top.position = Vector2(0, -260)
	cl.add_child(bar_top)

	var bar_bot := ColorRect.new()
	bar_bot.color    = Color.BLACK
	bar_bot.size     = Vector2(1080, 260)
	bar_bot.position = Vector2(0, 1920)
	cl.add_child(bar_bot)

	var center_bg := ColorRect.new()
	center_bg.color    = Color(0.02, 0.02, 0.04)
	center_bg.size     = Vector2(1080, 400)
	center_bg.position = Vector2(0, 760)
	center_bg.modulate.a = 0.0
	cl.add_child(center_bg)

	var scene_tex: TextureRect = null
	var scene_path := "res://resources/art/cutscenes/breach_scene.svg"
	if ResourceLoader.exists(scene_path):
		scene_tex          = TextureRect.new()
		scene_tex.texture  = load(scene_path)
		scene_tex.size     = Vector2(1080, 400)
		scene_tex.position = Vector2(0, 760)
		scene_tex.stretch_mode = TextureRect.STRETCH_SCALE
		scene_tex.modulate.a   = 0.0
		cl.add_child(scene_tex)

	var breach_label := Label.new()
	breach_label.text = "BREACH"
	breach_label.add_theme_font_size_override("font_size", 120)
	breach_label.size     = Vector2(800, 140)
	breach_label.position = Vector2(140, 890)
	breach_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	breach_label.modulate = Color(1, 1, 1, 0)
	cl.add_child(breach_label)

	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.size  = Vector2(1080, 1920)
	cl.add_child(flash)

	var tw := create_tween()

	# 破門點擊推進：交給 main._input() 偵測（Button.pressed 在真機觸控收不到）
	_breach_cl          = cl
	_breach_tween       = tw
	_breach_on_complete = on_complete
	_breach_active      = false  # 進場動畫播完才開放點擊

	tw.tween_property(bar_top, "position:y", 0.0, 0.15).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(bar_bot, "position:y", 1660.0, 0.15).set_ease(Tween.EASE_OUT)
	tw.tween_property(center_bg, "modulate:a", 1.0, 0.08)
	if scene_tex:
		tw.parallel().tween_property(scene_tex, "modulate:a", 1.0, 0.08)
	tw.tween_property(breach_label, "modulate:a", 1.0, 0.05)
	tw.parallel().tween_property(breach_label, "scale", Vector2(1.15, 1.15), 0.05)
	tw.tween_property(flash, "color:a", 0.85, 0.06)
	tw.tween_property(flash, "color:a", 0.0, 0.10)
	tw.parallel().tween_property(breach_label, "modulate:a", 0.0, 0.10)
	# 破門畫面定格 —— 三重保險推進：①全螢幕 Button ②_input ③安全自動推進，確保真機絕不卡死
	tw.tween_callback(func():
		_breach_active = true

		# ① 全螢幕點擊捕捉 Button（Control GUI 輸入，真機點按鈕證實可用；process_always 防任何 pause）
		var catcher := Button.new()
		catcher.flat         = true
		catcher.size         = Vector2(1080, 1920)
		catcher.position     = Vector2.ZERO
		catcher.focus_mode   = Control.FOCUS_NONE
		catcher.mouse_filter = Control.MOUSE_FILTER_STOP
		catcher.process_mode = Node.PROCESS_MODE_ALWAYS
		var empty := StyleBoxEmpty.new()
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			catcher.add_theme_stylebox_override(st, empty)
		cl.add_child(catcher)
		catcher.pressed.connect(_finish_breach)
		catcher.gui_input.connect(func(ev):
			if (ev is InputEventScreenTouch and ev.pressed) or (ev is InputEventMouseButton and ev.pressed):
				_finish_breach()
		)

		# 提示底襯（半透明圓角深底，讓文字在任何場景上都清楚）
		var hint_bg = ColorRect.new()
		hint_bg.color = Color(0.0, 0.0, 0.0, 0.45)
		hint_bg.size  = Vector2(560, 92)
		hint_bg.position = Vector2(260, 1474)
		hint_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cl.add_child(hint_bg)

		# 提示上緣強調色細線（戰術 HUD 風格）
		var hint_line = ColorRect.new()
		hint_line.color = Color(0.45, 0.70, 1.0, 0.9)
		hint_line.size  = Vector2(560, 3)
		hint_line.position = Vector2(260, 1474)
		hint_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cl.add_child(hint_line)

		var hint := Label.new()
		hint.text = ">>  點擊任意處繼續"
		hint.add_theme_font_size_override("font_size", 46)
		hint.size = Vector2(560, 92)
		hint.position = Vector2(260, 1484)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint.modulate = Color(1, 1, 1, 0.0)
		if ResourceLoader.exists("res://resources/fonts/chinese_font.ttf"):
			hint.add_theme_font_override("font", load("res://resources/fonts/chinese_font.ttf"))
		cl.add_child(hint)

		# 文字 + 底襯一起脈動（呼吸提示）
		var ht := create_tween().set_loops()
		ht.tween_property(hint, "modulate:a", 1.0, 0.5)
		ht.parallel().tween_property(hint_bg, "modulate:a", 1.0, 0.5)
		ht.tween_property(hint, "modulate:a", 0.4, 0.5)
		ht.parallel().tween_property(hint_bg, "modulate:a", 0.55, 0.5)

		# ③ 安全自動推進：3.5 秒內若觸控都沒被偵測，自動進下一關，永不卡死
		# （process_always + ignore_time_scale，不受暫停/變速影響）
		var fb := get_tree().create_timer(3.5, true, false, true)
		fb.timeout.connect(_finish_breach)
	)

# ② 破門定格時，偵測任意觸控/點擊 → 推進下一關（與 Button 互為備援）
func _input(event: InputEvent) -> void:
	if not _breach_active:
		return
	var tapped := false
	if event is InputEventScreenTouch and event.pressed:
		tapped = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped = true
	if tapped:
		_finish_breach()
		get_viewport().set_input_as_handled()

func _finish_breach() -> void:
	if not _breach_active:
		return
	_breach_active = false
	if _breach_tween and _breach_tween.is_valid():
		_breach_tween.kill()
	_breach_tween = null
	if _breach_cl and is_instance_valid(_breach_cl):
		_breach_cl.queue_free()
	_breach_cl = null
	var cb := _breach_on_complete
	_breach_on_complete = Callable()
	if cb.is_valid():
		cb.call()
