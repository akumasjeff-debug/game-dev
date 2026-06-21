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
const SQUAD_X_SLOTS: Array = [165.0, 390.0, 690.0, 915.0]

# ─────────────────────────────────────────────────────────────
#  角色基礎資料（Lv.1 × 稀有度 × 等級 乘率 → SaveManager）
# ─────────────────────────────────────────────────────────────
const CHAR_DATA = [
	{"id": "shield",  "name": "盾兵",   "color": Color(0.267, 0.533, 1.0,  1.0), "max_hp": 400.0, "attack": 30.0,  "defense": 25.0, "ult_name": "防禦護盾", "ult_cd": 30.0},
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

# 門動畫節點（left/right/frame — 保留 breach animation 用）
var _door_left: ColorRect  = null
var _door_right: ColorRect = null
var _door_frame: ColorRect = null

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

	_build_room_visual(idx)

	# 小隊進場動畫，結束後建立戰鬥房間
	_squad_enter(func():
		var cfg := ROOM_CONFIGS[idx]
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
	_active_room = null
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

# room.gd 呼叫此方法時小隊已在正確站位，只啟動掩護模式
func _position_squad_for_combat(_rp: Vector2, _rs: Vector2) -> void:
	for m in GameManager.squad_members:
		if m and is_instance_valid(m) and m.has_method("set_cover_mode"):
			m.set_cover_mode(true)

# ─────────────────────────────────────────────────────────────
#  房間視覺建立
# ─────────────────────────────────────────────────────────────
func _build_room_visual(idx: int) -> void:
	var visual := Node2D.new()
	visual.name = "RoomVisual"
	_room_visual  = visual
	add_child(visual)

	var cfg     := ROOM_CONFIGS[idx]
	var is_boss := cfg["label"] == "Boss"
	var bg_col  := Color(0.20, 0.05, 0.05) if is_boss else _get_mission_room_color()

	# 全螢幕背景
	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size     = Vector2(1080, 1920)
	bg.color    = bg_col
	visual.add_child(bg)

	# 地板紋理（中段）
	var tile := _get_floor_tile_path()
	if ResourceLoader.exists(tile):
		var tr := TextureRect.new()
		tr.texture        = load(tile)
		tr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		tr.stretch_mode   = TextureRect.STRETCH_TILE
		tr.position       = Vector2(0, 900)
		tr.size           = Vector2(1080, 780)
		tr.modulate       = Color(1, 1, 1, 0.22)
		visual.add_child(tr)

	# 上下分界線（戰術感）
	var divider := ColorRect.new()
	divider.position = Vector2(0, 900)
	divider.size     = Vector2(1080, 3)
	divider.color    = Color(0.3, 0.3, 0.4, 0.4)
	visual.add_child(divider)

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

	# 玩家掩體（下方，y=1360 確保在隊員站位 1520 上方）
	_add_cover(visual, "res://resources/art/props/player_cover.svg",
		Vector2(80, 1360), Vector2(920, 26),
		Color(0.35, 0.38, 0.45, 0.8))

	# 玩家掩體下方陰影
	var pshadow := ColorRect.new()
	pshadow.position = Vector2(80, 1386)
	pshadow.size     = Vector2(920, 4)
	pshadow.color    = Color(0.15, 0.15, 0.20, 0.7)
	visual.add_child(pshadow)

	# 房間標籤
	var lbl := Label.new()
	lbl.text     = "ROOM %s%s" % [cfg["label"], "  ⚠ BOSS" if is_boss else ""]
	lbl.position = Vector2(0, 16)
	lbl.size     = Vector2(1080, 44)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color",
		Color(0.9, 0.4, 0.4, 0.8) if is_boss else Color(0.7, 0.7, 0.8, 0.55))
	if ResourceLoader.exists("res://resources/fonts/chinese_font.ttf"):
		lbl.add_theme_font_override("font", load("res://resources/fonts/chinese_font.ttf"))
	visual.add_child(lbl)

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
	cl.layer = 20
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
	var _skipped := false

	# 透明點擊區：玩家點擊跳過
	var skip_btn := Button.new()
	skip_btn.flat         = true
	skip_btn.size         = Vector2(1080, 1920)
	skip_btn.position     = Vector2.ZERO
	skip_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var empty_style := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus"]:
		skip_btn.add_theme_stylebox_override(state, empty_style)
	cl.add_child(skip_btn)
	skip_btn.pressed.connect(func():
		if _skipped: return
		_skipped = true
		tw.kill()
		cl.queue_free()
		on_complete.call()
	)

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
	tw.tween_interval(0.15)
	if scene_tex:
		tw.tween_property(scene_tex, "modulate:a", 0.0, 0.10)
	tw.parallel().tween_property(center_bg, "modulate:a", 0.0, 0.10)
	tw.tween_property(bar_top, "position:y", -260.0, 0.15).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(bar_bot, "position:y", 1920.0, 0.15).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		cl.queue_free()
		on_complete.call()
	)
