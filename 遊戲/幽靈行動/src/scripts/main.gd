extends Node2D

# 主場景腳本
# 負責：初始化所有角色、設定路徑、連接 HUD 與決策面板

const CHARACTER_SCRIPT = preload("res://scripts/character.gd")
const ROOM_SCRIPT = preload("res://scripts/room.gd")

# 鏡頭系統
# 房間中心 y 座標（從下往上排列）：房間A、房間B、房間C、Boss房
# 計算方式：_add_room_visual 的 pos.y + size.y / 2
#   房間A：1150 + 100 = 1250
#   房間B：750  + 100 = 850
#   房間C：260  +  90 = 350
#   Boss ：120  +  60 = 180
const ROOM_CENTER_Y: Array = [1250.0, 850.0, 350.0, 180.0]

var _camera: Camera2D
var _camera_locked: bool = false
var _current_room_idx: int = 0  # 目前鏡頭所在房間索引（0=房間A）

# 主路徑點（直屏 1080x1920，從下往上）
# 節點順序：起點 → 房間A → 房間B → 岔路 → 房間C → Boss房 → 終點
const WAYPOINTS_MAIN: Array[Vector2] = [
	Vector2(540, 1750),   # 起點
	Vector2(540, 1500),   # 段1
	Vector2(540, 1250),   # 房間A 觸發點
	Vector2(540, 1000),   # 段2
	Vector2(540, 850),    # 房間B 觸發點
	Vector2(540, 680),    # 岔路觸發點
	Vector2(540, 500),    # 段3（岔路後）
	Vector2(540, 350),    # 房間C 觸發點
	Vector2(540, 200),    # Boss 房觸發點
	Vector2(540, 80),     # 終點
]

# 岔路 — 左路補給（繞道）
const WAYPOINTS_LEFT: Array[Vector2] = [
	Vector2(540, 680),    # 岔路分叉點
	Vector2(300, 580),    # 左側通道（補給）
	Vector2(300, 460),    # 左側補給箱
	Vector2(540, 350),    # 回主路（房間C）
	Vector2(540, 200),    # Boss 房
	Vector2(540, 80),     # 終點
]

# 岔路 — 右路直達（跳過補給）
const WAYPOINTS_RIGHT: Array[Vector2] = [
	Vector2(540, 680),    # 岔路分叉點
	Vector2(780, 580),    # 右側通道（直達）
	Vector2(780, 460),    # 右側匯合
	Vector2(540, 350),    # 回主路（房間C）
	Vector2(540, 200),    # Boss 房
	Vector2(540, 80),     # 終點
]

# 向後相容（保留舊名稱指向主路）
const WAYPOINTS: Array[Vector2] = WAYPOINTS_MAIN

# 房間管理：追蹤當前戰鬥中的房間
var _active_room: Node = null

# 門動畫節點（左半/右半/門框）
var _door_left: ColorRect = null
var _door_right: ColorRect = null
var _door_frame: ColorRect = null

# 全部 6 名可招募角色資料（Lv.1 基礎數值，對應 characters.json）
# 職業顏色對應 HUD_SPEC：盾兵#4488FF 醫療兵#44CC44 突擊手#E8600A 狙擊手#AA44FF 爆破手#CC2222 偵察手#44CCCC
const CHAR_DATA = [
	{"id": "shield",  "name": "盾兵",  "color": Color(0.267, 0.533, 1.0,  1.0), "max_hp": 200.0, "attack": 30.0,  "defense": 25.0, "offset": Vector2(0,   -80), "ult_name": "防禦護盾", "ult_cd": 30.0, "level": 1},
	{"id": "medic",   "name": "醫療兵","color": Color(0.267, 0.800, 0.267,1.0), "max_hp": 130.0, "attack": 20.0,  "defense": 15.0, "offset": Vector2(-40,  80), "ult_name": "緊急治療", "ult_cd": 40.0, "level": 1},
	{"id": "assault", "name": "突擊手","color": Color(0.910, 0.376, 0.039,1.0), "max_hp": 155.0, "attack": 60.0,  "defense": 15.0, "offset": Vector2(-50,   0), "ult_name": "火力全開", "ult_cd": 25.0, "level": 1},
	{"id": "sniper",  "name": "狙擊手","color": Color(0.667, 0.267, 1.0,  1.0), "max_hp": 110.0, "attack": 120.0, "defense": 10.0, "offset": Vector2(40,    80), "ult_name": "精準鎖定", "ult_cd": 35.0, "level": 1},
	{"id": "demo",    "name": "爆破手","color": Color(0.800, 0.133, 0.133,1.0), "max_hp": 135.0, "attack": 80.0,  "defense": 18.0, "offset": Vector2(50,    0), "ult_name": "引爆炸彈", "ult_cd": 45.0, "level": 1},
	{"id": "recon",   "name": "偵察手","color": Color(0.267, 0.800, 0.800,1.0), "max_hp": 140.0, "attack": 35.0,  "defense": 17.0, "offset": Vector2(0,    40), "ult_name": "煙霧封鎖", "ult_cd": 35.0, "level": 1},
]

var squad_controller: Node2D
var hud_scene: Node
var decision_panel: Node
var _fork_triggered: bool = false  # 岔路是否已觸發

func _ready() -> void:
	# Bug3: 讀取並確認任務 ID
	if OS.is_debug_build():
		print("[Main] 啟動任務: %s" % GameManager.current_mission_id)
	_build_map()
	_spawn_squad()
	_setup_triggers()
	_setup_camera()
	_connect_hud()
	_connect_signals()
	_connect_restart()
	_start_mission_bgm()

func _start_mission_bgm() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am == null:
		return
	var mission_id: String = ""
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		mission_id = gm.current_mission_id
	match mission_id:
		"warehouse_01":
			am.play_bgm("warehouse_bgm")
		"harbor_01":
			am.play_bgm("harbor_bgm")
		_:
			am.play_bgm("mission")

func _setup_camera() -> void:
	_camera = Camera2D.new()
	_camera.name = "GameCamera"
	_camera.enabled = true
	# zoom：房間高度約 200px（最大），螢幕播放區高度 1740（1920 - 180 HUD）
	# 讓一個房間約佔畫面 80%：zoom = 1740 * 0.8 / 200 ≈ 6.96，約 6.0 偏安全
	# 但全圖寬 1080、房間寬 300px，zoom=6 會太窄；改用讓寬度對齊：1080/300 ≈ 3.6
	# 取 3.5 讓房間稍有留白
	_camera.zoom = Vector2(3.5, 3.5)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 4.0
	# 初始位置：畫面水平中央，y 對準房間A 中心
	_camera.global_position = Vector2(540.0, ROOM_CENTER_Y[0])
	add_child(_camera)
	_camera.make_current()
	print("[Camera] 初始化完成，位置 y=", ROOM_CENTER_Y[0])

func _process(_delta: float) -> void:
	if _camera == null or _camera_locked:
		return
	if GameManager == null:
		return
	# 找存活隊員的平均 y
	var valid_members: Array = []
	for m in GameManager.squad_members:
		if m != null and is_instance_valid(m) and not m.is_dead:
			valid_members.append(m)
	if valid_members.size() == 0:
		return
	var avg_y: float = 0.0
	for m in valid_members:
		avg_y += m.global_position.y
	avg_y /= float(valid_members.size())
	# x 固定在畫面水平中央，只讓 y 跟著小隊走
	_camera.global_position = Vector2(540.0, avg_y)

func _advance_camera_to_next_room() -> void:
	if _current_room_idx + 1 >= ROOM_CENTER_Y.size():
		return
	_current_room_idx += 1
	_camera_locked = true
	var target_y: float = ROOM_CENTER_Y[_current_room_idx]
	print("[Camera] 推進到房間 idx=", _current_room_idx, " y=", target_y)
	var tween = create_tween()
	tween.tween_property(
		_camera, "global_position",
		Vector2(540.0, target_y), 1.5
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void:
		_camera_locked = false
		print("[Camera] 到位，恢復跟隨")
	)

func _get_mission_room_color() -> Color:
	var mission_id: String = GameManager.current_mission_id if GameManager else "demo_01"
	match mission_id:
		"warehouse_01":
			return Color(0.05, 0.063, 0.09)   # 深灰黑，停車場
		"harbor_01":
			return Color(0.04, 0.083, 0.125)  # 深海藍，港口
		_:
			return Color(0.102, 0.125, 0.208) # 辦公大樓 #1A2035

func _get_mission_corridor_color() -> Color:
	var mission_id: String = GameManager.current_mission_id if GameManager else "demo_01"
	match mission_id:
		"warehouse_01":
			return Color(0.07, 0.08, 0.10)   # 深灰黑走廊
		"harbor_01":
			return Color(0.05, 0.09, 0.13)   # 深海藍走廊
		_:
			return Color(0.15, 0.15, 0.18)   # 辦公大樓走廊（原本）

func _build_map() -> void:
	var room_base = _get_mission_room_color()
	var corridor_col = _get_mission_corridor_color()

	# 繪製路徑背景（深色通道）
	var path_visual = Line2D.new()
	path_visual.name = "PathVisual"
	path_visual.width = 120.0
	path_visual.default_color = corridor_col
	for wp in WAYPOINTS:
		path_visual.add_point(wp)
	add_child(path_visual)

	# 地板紋理（用 ColorRect 模擬房間區域）
	# 各房間以任務主題色為基底，保留原有明暗層次偏移
	# 房間A（偏冷藍）
	_add_room_visual(Vector2(390, 1150), Vector2(300, 200), room_base.lightened(0.04), "房間A")
	# 房間B（略暗）
	_add_room_visual(Vector2(390, 750),  Vector2(300, 200), room_base, "房間B")
	# 房間C（略帶紫調，僅 demo_01 明顯）
	_add_room_visual(Vector2(390, 260),  Vector2(300, 180), room_base.darkened(0.04), "房間C")
	# Boss 房（維持深紅警示，不跟主題色）
	_add_room_visual(Vector2(380, 120),  Vector2(320, 120), Color(0.25, 0.08, 0.08), "Boss")

	# 起點標記
	_add_text_label(Vector2(440, 1760), "起點", Color(0.6, 0.8, 0.6))
	# 終點標記
	_add_text_label(Vector2(440, 60), "任務完成", Color(1.0, 0.9, 0.3))

func _get_floor_tile_path() -> String:
	var mission_id: String = GameManager.current_mission_id if GameManager else "demo_01"
	match mission_id:
		"warehouse_01":
			return "res://resources/art/props/floor_tile_warehouse.svg"
		"harbor_01":
			return "res://resources/art/props/floor_tile_harbor.svg"
		_:
			return "res://resources/art/props/floor_tile_office.svg"

func _add_room_visual(pos: Vector2, size: Vector2, color: Color, label: String) -> void:
	var rect = ColorRect.new()
	rect.position = pos
	rect.size = size
	rect.color = color
	add_child(rect)
	# 地板紋理 TextureRect（tile 模式，依任務 ID 選擇對應 SVG）
	if label != "Boss":
		var tile_tex = load(_get_floor_tile_path())
		if tile_tex:
			var tex_rect = TextureRect.new()
			tex_rect.texture = tile_tex
			tex_rect.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			tex_rect.stretch_mode = TextureRect.STRETCH_TILE
			tex_rect.position = Vector2.ZERO
			tex_rect.size = size
			tex_rect.modulate = Color(1.0, 1.0, 1.0, 0.35)
			rect.add_child(tex_rect)
	_add_text_label(pos + Vector2(10, 10), label, Color(0.8, 0.8, 0.8))
	_add_room_props(rect, size, label == "Boss")
	_add_battle_covers(pos, size, rect)

func _make_cover_node(svg_path: String, size: Vector2) -> Node2D:
	var container = Node2D.new()
	if ResourceLoader.exists(svg_path):
		var tr = TextureRect.new()
		tr.texture = load(svg_path)
		tr.size = size
		tr.position = Vector2.ZERO
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		container.add_child(tr)
	else:
		# 回退：保留 ColorRect
		var cr = ColorRect.new()
		cr.size = size
		cr.position = Vector2.ZERO
		cr.color = Color(0.23, 0.25, 0.29)
		container.add_child(cr)
	return container

func _add_battle_covers(room_pos: Vector2, room_size: Vector2, room_node: Node2D) -> void:
	# 玩家側掩體（房間下方，角色躲在其後方）
	# 使用相對座標（相對 room_node.position 即 room_pos）
	var cover_width: float = min(280.0, room_size.x - 20.0)
	var cover_x: float = (room_size.x - cover_width) / 2.0
	var cover_y: float = room_size.y - 55

	# 掩體主體（SVG TextureRect，回退 ColorRect）
	var player_cover = _make_cover_node(
		"res://resources/art/props/player_cover.svg",
		Vector2(cover_width, 18)
	)
	player_cover.position = Vector2(cover_x, cover_y)
	room_node.add_child(player_cover)

	# 掩體頂部高光（裝飾層保留）
	var cover_highlight = ColorRect.new()
	cover_highlight.size = Vector2(cover_width, 5)
	cover_highlight.position = Vector2(cover_x, cover_y)
	cover_highlight.color = Color(0.42, 0.42, 0.48, 0.5)
	room_node.add_child(cover_highlight)

	# 掩體底部陰影線（裝飾層保留）
	var cover_shadow = ColorRect.new()
	cover_shadow.size = Vector2(cover_width, 3)
	cover_shadow.position = Vector2(cover_x, cover_y + 15)
	cover_shadow.color = Color(0.18, 0.18, 0.22, 0.7)
	room_node.add_child(cover_shadow)

	# 敵人側掩體（房間上方，分 3 個小掩體）
	var enemy_cover_defs: Array = [
		{"x_ratio": 0.05, "y_off": 18, "svg": "res://resources/art/props/enemy_cover_left.svg"},
		{"x_ratio": 0.38, "y_off": 26, "svg": "res://resources/art/props/enemy_cover_mid.svg"},
		{"x_ratio": 0.68, "y_off": 18, "svg": "res://resources/art/props/enemy_cover_right.svg"},
	]
	var ec_width: float = min(80.0, room_size.x * 0.25)
	for ecd in enemy_cover_defs:
		var ec_x: float = room_size.x * ecd["x_ratio"]
		var ec_y: float = float(ecd["y_off"])
		# 敵人掩體主體（SVG TextureRect，回退 ColorRect）
		var ec = _make_cover_node(ecd["svg"], Vector2(ec_width, 14))
		ec.position = Vector2(ec_x, ec_y)
		room_node.add_child(ec)
		# 頂部高光（裝飾層保留）
		var ec_h = ColorRect.new()
		ec_h.size = Vector2(ec_width, 4)
		ec_h.position = Vector2(ec_x, ec_y)
		ec_h.color = Color(0.40, 0.34, 0.30, 0.5)
		room_node.add_child(ec_h)
		# 底部陰影（裝飾層保留）
		var ec_s = ColorRect.new()
		ec_s.size = Vector2(ec_width, 2)
		ec_s.position = Vector2(ec_x, ec_y + 12)
		ec_s.color = Color(0.15, 0.12, 0.10, 0.7)
		room_node.add_child(ec_s)

func _add_room_props(room_node: Node2D, room_size: Vector2, is_boss: bool) -> void:
	var prop_paths: Array
	if is_boss:
		prop_paths = [
			["res://resources/art/props/server_rack.svg", Vector2(16, 16)],
			["res://resources/art/props/server_rack.svg", Vector2(room_size.x - 64, 16)],
			["res://resources/art/props/crate.svg",       Vector2(16, room_size.y - 60)],
		]
	else:
		prop_paths = [
			["res://resources/art/props/crate.svg",   Vector2(12, 12)],
			["res://resources/art/props/locker.svg",  Vector2(room_size.x - 58, 12)],
			["res://resources/art/props/barrel.svg",  Vector2(12, room_size.y - 58)],
		]

	for entry in prop_paths:
		var path: String = entry[0]
		var prop_pos: Vector2 = entry[1]
		if not ResourceLoader.exists(path):
			continue
		var spr = Sprite2D.new()
		spr.texture = load(path)
		spr.centered = false
		spr.position = prop_pos
		spr.scale = Vector2(0.75, 0.75)
		room_node.add_child(spr)

func _add_text_label(pos: Vector2, text: String, color: Color) -> void:
	var lbl = Label.new()
	lbl.position = pos
	lbl.text = text
	lbl.modulate = color
	lbl.add_theme_font_size_override("font_size", 18)
	add_child(lbl)

func _spawn_squad() -> void:
	squad_controller = load("res://scripts/squad_controller.gd").new()
	squad_controller.name = "SquadController"
	add_child(squad_controller)

	# P2：從 SaveManager 讀取陣容與等級；回退到 CHAR_DATA 預設值（開發用）
	var squad_ids: Array = SaveManager.selected_squad
	if squad_ids.is_empty():
		squad_ids = ["shield", "assault", "demo", "medic"]

	var members: Array = []
	for char_id in squad_ids:
		# 在 CHAR_DATA 中找對應資料
		var data = _get_char_data(char_id)
		if data.is_empty():
			continue
		var char_node = CHARACTER_SCRIPT.new()
		char_node.name = char_id
		char_node.char_id = data["id"]
		char_node.char_name = data["name"]
		char_node.body_color = data["color"]
		# 套用稀有度 × 等級乘率（基礎數值為 Lv.1 數值）
		var rarity_mult = SaveManager.get_rarity_multiplier(char_id)
		var level_mult = SaveManager.get_level_multiplier(char_id)
		char_node.max_hp = data["max_hp"] * rarity_mult * level_mult
		char_node.attack_power = data["attack"] * rarity_mult * level_mult
		char_node.defense = data.get("defense", 0.0) * rarity_mult * level_mult
		char_node.formation_offset = data["offset"]
		char_node.ultimate_name = data["ult_name"]
		char_node.ultimate_cd = data["ult_cd"]
		# 讀取 SaveManager 中存的等級
		var saved_level = SaveManager.character_levels.get(char_id, 1)
		char_node.level = saved_level
		char_node.add_to_group("squad")
		add_child(char_node)
		members.append(char_node)

	GameManager.squad_members = members

	var wps: Array[Vector2] = []
	for wp in WAYPOINTS:
		wps.append(wp)
	squad_controller.setup(wps, members)

func _get_char_data(char_id: String) -> Dictionary:
	for data in CHAR_DATA:
		if data["id"] == char_id:
			return data
	return {}

func _setup_triggers() -> void:
	# 節點順序：房間A → 房間B → 岔路（左:補給/右:直達）→ 房間C → Boss → 終點

	# 決策點1 — 房間A（敵人數由任務配置決定）
	_create_room_trigger(Vector2(540, 1270), "房間A",
		_build_enemy_configs_from_mission("room_a"))

	# 決策點2 — 房間B（敵人數由任務配置決定）
	_create_room_trigger(Vector2(540, 870), "房間B",
		_build_enemy_configs_from_mission("room_b"))

	# 岔路觸發點（左:補給繞道 / 右:直達）
	_create_fork_trigger(Vector2(540, 700))

	# 補給箱觸發（左路才會走到，但設在主路繼續路徑上也可觸發）
	_create_trigger(Vector2(300, 460), "supply", "補給箱")

	# 決策點3 — 房間C（敵人數由任務配置決定）
	_create_room_trigger(Vector2(540, 370), "房間C",
		_build_enemy_configs_from_mission("room_c"))

	# Boss 決策點（進 Boss 房前的戰術選擇，y=280 以拉開與 Boss 房 y=210 的距離）
	_create_boss_decision_trigger(Vector2(540, 280))

	# Boss 房（敵人數由任務配置決定，在 Boss 決策後生成）
	_create_boss_room_trigger(Vector2(540, 210))

	# 終點觸發
	_create_end_trigger(Vector2(540, 90))

# 從 GameManager 讀取指定房間的敵人配置，回傳 [{type, offset}] 陣列
# 若 GameManager 無資料則回退到 demo_01 預設值
func _build_enemy_configs_from_mission(room_key: String) -> Array:
	# 取得敵人數量配置
	var gm = get_node_or_null("/root/GameManager")
	var cfg: Dictionary
	if gm and gm.missions_data.size() > 0:
		cfg = gm.get_mission_enemy_config(room_key)
	else:
		# 回退預設值（對應 demo_01）
		match room_key:
			"room_a": cfg = {"normal": 2, "elite": 0, "boss": 0}
			"room_b": cfg = {"normal": 1, "elite": 1, "boss": 0}
			"room_c": cfg = {"normal": 0, "elite": 1, "boss": 0}
			"boss_room": cfg = {"normal": 0, "elite": 0, "boss": 1}
			_: cfg = {"normal": 1, "elite": 0, "boss": 0}

	var normal_count: int = cfg.get("normal", 0)
	var elite_count: int = cfg.get("elite", 0)
	var boss_count: int = cfg.get("boss", 0)
	var total: int = normal_count + elite_count + boss_count
	if total == 0:
		total = 1

	# 計算橫向間距，均分在 ±120 範圍內
	var spacing: float = min(240.0 / float(max(total, 1)), 80.0)
	var start_x: float = -spacing * float(total - 1) / 2.0

	var result: Array = []
	var idx: int = 0

	# 先排普通兵（type=0），再精英（type=1），再 Boss（type=2）
	for _i in range(normal_count):
		result.append({"type": 0, "offset": Vector2(start_x + spacing * float(idx), -80)})
		idx += 1
	for _i in range(elite_count):
		result.append({"type": 1, "offset": Vector2(start_x + spacing * float(idx), -80)})
		idx += 1
	for _i in range(boss_count):
		result.append({"type": 2, "offset": Vector2(start_x + spacing * float(idx), -80)})
		idx += 1

	if OS.is_debug_build():
		print("[Main] %s 敵人配置: normal=%d elite=%d boss=%d" % [room_key, normal_count, elite_count, boss_count])
	return result

func _create_room_trigger(pos: Vector2, label: String, enemy_configs: Array) -> void:
	# 房間觸發器：進入時顯示決策面板，選擇後生成敵人開始戰鬥
	var area = Area2D.new()
	area.position = pos
	area.name = "RoomTrigger_" + label

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 80.0
	shape.shape = circle
	area.add_child(shape)

	# 視覺標記
	var marker = ColorRect.new()
	marker.size = Vector2(60, 60)
	marker.position = Vector2(-30, -30)
	marker.color = Color(0.8, 0.2, 0.2, 0.4)
	area.add_child(marker)

	var mlbl = Label.new()
	mlbl.text = "!" + label
	mlbl.position = Vector2(-50, -56)
	mlbl.add_theme_font_size_override("font_size", 16)
	mlbl.modulate = Color.WHITE
	area.add_child(mlbl)

	# 儲存在 meta 供信號回調使用
	area.set_meta("triggered", false)
	area.set_meta("label", label)
	area.set_meta("enemy_configs", enemy_configs)
	area.set_meta("room_node", null)

	area.body_entered.connect(_on_room_trigger_entered.bind(area))
	add_child(area)

func _on_room_trigger_entered(body: Node2D, area: Area2D) -> void:
	if area.get_meta("triggered", false):
		return
	if not body.is_in_group("squad"):
		return
	area.set_meta("triggered", true)

	var label = area.get_meta("label", "房間")
	var enemy_configs = area.get_meta("enemy_configs", [])

	# Boss 房特效：震屏 + 紅色危險閃光
	if label == "Boss房":
		_do_camera_shake(10.0, 0.5)
		_flash_danger_overlay()

	# 建立房間節點
	var room = ROOM_SCRIPT.new()
	room.room_label = label
	room.enemy_configs = enemy_configs.duplicate(true)
	room.position = area.position
	room.name = "Room_" + label
	add_child(room)
	_active_room = room

	# 顯示決策面板（暫停小隊，等玩家選擇進入方式）
	var decision_data = {
		"type": "room",
		"title": "進入 " + label,
		"description": "偵測到敵方移動，如何進入？",
		"options": [
			{"id": "charge",  "text": "直衝突入",   "desc": "快速但危險，全隊可能受傷"},
			{"id": "stealth", "text": "靜悄進入", "desc": "緩慢但安全，敵人無法提前警戒"},
			{"id": "bomb",    "text": "投擲炸彈",   "desc": "需要爆破手，清場效果佳"},
		],
	}

	# 連接決策選擇信號（只連接一次）
	# DecisionPanel 是 CanvasLayer，script 在其子節點 Root 上
	var dp = get_node_or_null("DecisionPanel/Root")
	if dp:
		# 使用 lambda 捕捉 room 參考
		var callback = func(opt_id: String, _dec_type: String):
			_on_room_entry_selected(opt_id, room)
		dp.option_selected.connect(callback, CONNECT_ONE_SHOT)

	GameManager.trigger_decision(decision_data)

	# 連接房間清空信號
	room.room_cleared.connect(_on_room_cleared)

func _on_room_entry_selected(opt_id: String, room: Node) -> void:
	if room == null or not is_instance_valid(room):
		return
	room.start_battle(opt_id)

func _do_camera_shake(intensity: float = 8.0, duration: float = 0.4) -> void:
	var cam = get_viewport().get_camera_2d()
	if cam == null:
		return
	var original_offset = cam.offset
	var tw = create_tween()
	var steps = 8
	for i in range(steps):
		var rand_x = randf_range(-intensity, intensity)
		var rand_y = randf_range(-intensity, intensity)
		tw.tween_property(cam, "offset", original_offset + Vector2(rand_x, rand_y), duration / steps)
	tw.tween_property(cam, "offset", original_offset, 0.05)

func _flash_danger_overlay() -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0.8, 0.0, 0.0, 0.35)
	overlay.size = Vector2(1080, 1920)
	var cl = CanvasLayer.new()
	cl.layer = 10
	cl.add_child(overlay)
	add_child(cl)
	var tw = create_tween()
	tw.tween_property(overlay, "modulate:a", 0.0, 0.4)
	tw.tween_callback(cl.queue_free)

func _on_room_cleared() -> void:
	_active_room = null
	# GameManager.resume_squad() 已在 room.gd 的 _check_cleared() 中呼叫
	print("[Main] 房間清空，小隊繼續推進")
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		for member in gm.squad_members:
			if member and is_instance_valid(member) and member.has_method("set_cover_mode"):
				member.set_cover_mode(false)
	# 延遲 0.3 秒後播放門打開動畫，動畫結束後再推進鏡頭
	await get_tree().create_timer(0.3).timeout
	# 計算門的 y 座標：當前房間頂部（房間中心 y 減去半個房間高度）
	var door_y: float
	if _current_room_idx < ROOM_CENTER_Y.size():
		# 各房間高度：A=200, B=200, C=180, Boss=120；取半高估算頂部
		var half_heights: Array = [100.0, 100.0, 90.0, 60.0]
		var half_h: float = half_heights[_current_room_idx] if _current_room_idx < half_heights.size() else 90.0
		door_y = ROOM_CENTER_Y[_current_room_idx] - half_h
	else:
		door_y = _camera.global_position.y - 120.0
	_play_door_open_animation(door_y, func():
		_advance_camera_to_next_room()
	)

func _play_door_open_animation(door_y: float, on_complete: Callable) -> void:
	# 清除上一個門（若存在）
	if _door_left and is_instance_valid(_door_left):
		_door_left.queue_free()
	if _door_right and is_instance_valid(_door_right):
		_door_right.queue_free()
	if _door_frame and is_instance_valid(_door_frame):
		_door_frame.queue_free()
	_door_left = null
	_door_right = null
	_door_frame = null

	# 門的尺寸：寬 240px（約配合房間寬度 300px），高 28px
	# x 對準鏡頭水平中心 540（世界座標）
	var door_total_w: float = 240.0
	var door_h: float = 28.0
	var door_x_center: float = 540.0

	# 門框（在最底層，較門板稍大）
	_door_frame = ColorRect.new()
	_door_frame.size = Vector2(door_total_w + 8.0, door_h + 4.0)
	_door_frame.position = Vector2(door_x_center - door_total_w / 2.0 - 4.0, door_y - door_h / 2.0 - 2.0)
	_door_frame.color = Color(0.25, 0.25, 0.30)
	add_child(_door_frame)

	# 左半門（右邊緣貼中線，向左滑開）
	_door_left = ColorRect.new()
	_door_left.size = Vector2(door_total_w / 2.0, door_h)
	_door_left.position = Vector2(door_x_center - door_total_w / 2.0, door_y - door_h / 2.0)
	_door_left.color = Color(0.15, 0.15, 0.18)
	add_child(_door_left)

	# 右半門（左邊緣貼中線，向右滑開）
	_door_right = ColorRect.new()
	_door_right.size = Vector2(door_total_w / 2.0, door_h)
	_door_right.position = Vector2(door_x_center, door_y - door_h / 2.0)
	_door_right.color = Color(0.15, 0.15, 0.18)
	add_child(_door_right)

	print("[Door] 播放門打開動畫，door_y=", door_y)

	# Tween：門向兩側滑開（0.6 秒），結束後執行 callback 並清除節點
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_door_left, "position:x",
		door_x_center - door_total_w, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_door_right, "position:x",
		door_x_center + door_total_w / 2.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.set_parallel(false)
	tween.tween_callback(on_complete)
	var dl_ref = _door_left
	var dr_ref = _door_right
	var df_ref = _door_frame
	tween.tween_callback(func():
		if dl_ref and is_instance_valid(dl_ref): dl_ref.queue_free()
		if dr_ref and is_instance_valid(dr_ref): dr_ref.queue_free()
		if df_ref and is_instance_valid(df_ref): df_ref.queue_free()
	)

func _create_trigger(pos: Vector2, type: String, label: String) -> void:
	var area = Area2D.new()
	area.position = pos
	area.name = "Trigger_" + label

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 80.0
	shape.shape = circle
	area.add_child(shape)

	# 視覺標記
	var marker = ColorRect.new()
	marker.size = Vector2(60, 60)
	marker.position = Vector2(-30, -30)
	marker.color = Color(1.0, 0.8, 0.1, 0.4) if type == "supply" else Color(0.9, 0.3, 0.3, 0.4)
	area.add_child(marker)

	var mlbl = Label.new()
	mlbl.text = "!" + label
	mlbl.position = Vector2(-50, -56)
	mlbl.add_theme_font_size_override("font_size", 16)
	mlbl.modulate = Color.WHITE
	area.add_child(mlbl)

	var trigger_script = load("res://scripts/decision_trigger.gd")
	area.set_script(trigger_script)
	area.decision_type = type
	area.location_name = label

	add_child(area)

func _create_boss_decision_trigger(pos: Vector2) -> void:
	# Boss 決策點：進入 Boss 房前的戰術選擇
	var area = Area2D.new()
	area.position = pos
	area.name = "BossDecisionTrigger"

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 80.0
	shape.shape = circle
	area.add_child(shape)

	# 視覺標記（紅色警示）
	var marker = ColorRect.new()
	marker.size = Vector2(80, 80)
	marker.position = Vector2(-40, -40)
	marker.color = Color(0.8, 0.1, 0.1, 0.6)
	area.add_child(marker)

	var mlbl = Label.new()
	mlbl.text = "BOSS"
	mlbl.position = Vector2(-28, -56)
	mlbl.add_theme_font_size_override("font_size", 20)
	mlbl.modulate = Color(1.0, 0.3, 0.3)
	area.add_child(mlbl)

	area.set_meta("triggered", false)
	area.body_entered.connect(_on_boss_decision_entered.bind(area))
	add_child(area)

func _on_boss_decision_entered(body: Node2D, area: Area2D) -> void:
	if area.get_meta("triggered", false):
		return
	if not body.is_in_group("squad"):
		return
	area.set_meta("triggered", true)

	var decision_data = {
		"type": "boss",
		"title": "目標：指揮官",
		"description": "前方就是 Boss 房，指揮官帶著精銳衛隊守在裡面，如何行動？",
		"options": [
			{"id": "boss_charge",  "text": "直衝 Boss", "desc": "全隊直接衝入，承受 Boss 第一波攻擊，速戰速決"},
			{"id": "boss_flank",   "text": "側翼迂迴",  "desc": "繞路消耗更長，但陣型更有利，進場受傷 -30%"},
			{"id": "boss_bait",    "text": "引蛇出洞",  "desc": "引 Boss 離開房間，先消滅 2 名護衛，減少進場壓力"},
		]
	}
	GameManager.trigger_decision(decision_data)

func _create_boss_room_trigger(pos: Vector2) -> void:
	# Boss 房觸發（生成 Boss 敵人，在 Boss 決策後觸發，敵人數由任務配置決定）
	_create_room_trigger(pos, "Boss房", _build_enemy_configs_from_mission("boss_room"))

func _create_end_trigger(pos: Vector2) -> void:
	var area = Area2D.new()
	area.position = pos
	area.name = "EndTrigger"

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 80.0
	shape.shape = circle
	area.add_child(shape)

	area.body_entered.connect(_on_end_reached)
	add_child(area)

func _on_end_reached(body: Node2D) -> void:
	if body.is_in_group("squad"):
		# 觸發勝利（票券獎勵由 hud.gd _on_game_won 統一處理）
		GameManager.trigger_game_over(true)

func _connect_hud() -> void:
	hud_scene = $HUD
	if hud_scene and hud_scene.has_method("setup_cards"):
		hud_scene.setup_cards(GameManager.squad_members)

	# 連接進度更新
	if squad_controller:
		squad_controller.progress_updated.connect(hud_scene.update_progress)

	# 連接決策面板
	decision_panel = $DecisionPanel

	# 連接結算按鈕（RestartBtn 返回基地，RetryBtn 重試）
	if hud_scene:
		var restart_btn = hud_scene.find_child("RestartBtn", true, false)
		if restart_btn and not restart_btn.pressed.is_connected(hud_scene._on_restart_pressed):
			restart_btn.pressed.connect(hud_scene._on_restart_pressed)
		var retry_btn = hud_scene.find_child("RetryBtn", true, false)
		if retry_btn and not retry_btn.pressed.is_connected(hud_scene._on_retry_pressed):
			retry_btn.pressed.connect(hud_scene._on_retry_pressed)

func _create_fork_trigger(pos: Vector2) -> void:
	# 岔路觸發點：直接用 Area2D + inline 腳本連接
	var area = Area2D.new()
	area.position = pos
	area.name = "ForkTrigger"

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 80.0
	shape.shape = circle
	area.add_child(shape)

	# 視覺標記（菱形用 ColorRect 模擬）
	var marker = ColorRect.new()
	marker.size = Vector2(70, 70)
	marker.position = Vector2(-35, -35)
	marker.color = Color(0.5, 0.2, 0.9, 0.5)
	area.add_child(marker)

	var mlbl = Label.new()
	mlbl.text = "岔路"
	mlbl.position = Vector2(-28, -56)
	mlbl.add_theme_font_size_override("font_size", 18)
	mlbl.modulate = Color(0.9, 0.7, 1.0)
	area.add_child(mlbl)

	area.body_entered.connect(_on_fork_trigger_entered)
	add_child(area)

func _on_fork_trigger_entered(body: Node2D) -> void:
	if _fork_triggered:
		return
	if not body.is_in_group("squad"):
		return
	_fork_triggered = true

	# 取得盾兵等級，判斷是否顯示 Lv.3 解鎖選項
	var shield_member = _get_member_by_id("shield")
	var shield_level = shield_member.level if shield_member and shield_member.get("level") != null else 1

	var options = [
		{"id": "left",  "text": "左路（繞道補給）", "desc": "繞道補給箱，可補充物資"},
		{"id": "right", "text": "右路（直達房間C）","desc": "直接抵達，節省時間"},
	]

	var decision_data = {
		"type": "fork",
		"title": "前方出現岔路",
		"description": "選擇前進路線：",
		"options": options,
		"shield_level": shield_level,
	}
	GameManager.trigger_decision(decision_data)

func _get_member_by_id(id: String) -> Node:
	for member in GameManager.squad_members:
		if member != null and is_instance_valid(member) and member.char_id == id:
			return member
	return null

func switch_path(path_id: String) -> void:
	# 切換 squad_controller 的剩餘路徑
	var new_wps_raw: Array[Vector2] = []
	match path_id:
		"left":
			new_wps_raw = WAYPOINTS_LEFT
		"right":
			new_wps_raw = WAYPOINTS_RIGHT
		_:
			return

	# 從現在位置接上新路徑（第一個點已是當前分叉點，略過）
	var new_wps: Array[Vector2] = []
	for i in range(1, new_wps_raw.size()):
		new_wps.append(new_wps_raw[i])

	if squad_controller and squad_controller.has_method("replace_remaining_path"):
		squad_controller.replace_remaining_path(new_wps)

func _position_squad_for_combat(room_pos: Vector2, room_size: Vector2) -> void:
	# 戰鬥開始時，把小隊重新排列到玩家掩體後方
	# 玩家掩體在 room_pos.y + room_size.y - 55，角色站在掩體再下方 25px
	if not GameManager or GameManager.squad_members.size() == 0:
		return
	var combat_y: float = room_pos.y + room_size.y - 25.0
	# x 槽位：在房間寬度內均分（最多 5 個）
	var alive_members: Array = []
	for m in GameManager.squad_members:
		if m != null and is_instance_valid(m) and not m.is_dead:
			alive_members.append(m)
	var count: int = alive_members.size()
	if count == 0:
		return
	var step: float = room_size.x / float(count + 1)
	for i in range(count):
		var member = alive_members[i]
		member.global_position = Vector2(room_pos.x + step * float(i + 1), combat_y)

	var gm = get_node_or_null("/root/GameManager")
	if gm:
		for member in gm.squad_members:
			if member and is_instance_valid(member) and member.has_method("set_cover_mode"):
				member.set_cover_mode(true)

func _connect_signals() -> void:
	pass

func _connect_restart() -> void:
	pass
