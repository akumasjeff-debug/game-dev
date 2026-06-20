extends Node2D

var mission_manager: Node = null
var _bgm: AudioStreamPlayer

func _ready():
	add_to_group("main_controller")
	_start_bgm()
	_setup_mission_manager()
	await get_tree().process_frame
	_setup_patrol_routes()
	_connect_enemy_signals()
	_create_floor_tiles()
	_setup_cover_objects()

func _start_bgm():
	_bgm = AudioStreamPlayer.new()
	add_child(_bgm)
	var f = FileAccess.open("res://assets/audio/bgm/bgm_battle.wav", FileAccess.READ)
	if not f:
		return
	f.seek(44)
	var data = f.get_buffer(f.get_length() - 44)
	f.close()
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = 22050
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = data.size() / 2  # 16-bit = 2 bytes per sample
	_bgm.stream = stream
	_bgm.volume_db = -12.0
	_bgm.play()

func _stop_bgm():
	if _bgm:
		_bgm.stop()

func _setup_mission_manager():
	mission_manager = load("res://scripts/mission_manager.gd").new()
	mission_manager.name = "MissionManager"
	add_child(mission_manager)
	mission_manager.setup_elimination()
	mission_manager.mission_complete.connect(_on_mission_complete)
	mission_manager.mission_failed.connect(_on_mission_failed)

func _connect_enemy_signals():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_signal("died") and not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died)

func _on_enemy_died(enemy):
	if mission_manager:
		mission_manager.on_enemy_died(enemy)
	var hud_nodes = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0 and hud_nodes[0].has_method("add_kill"):
		hud_nodes[0].add_kill()

func _on_mission_complete():
	_stop_bgm()
	var hud_nodes = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0:
		hud_nodes[0].show_victory_panel()

func _on_mission_failed(_reason: String):
	pass  # 目前 HUD 尚未實作失敗面板，預留接口

func _setup_patrol_routes():
	var enemies_node = $World/Enemies
	if not enemies_node:
		return

	# 每個敵人的巡邏路線（根據地圖隔間設計）
	# Enemy1 (200,200)：在 WallDiv1 左側區域巡邏，四角矩形
	# Enemy2 (600,300)：在 WallDiv1 右、WallDiv2 上方區域巡邏
	# Enemy3 (1000,600)：在 WallDiv3 右側下半部巡邏
	# Enemy4 (1400,500)：在 WallDiv5 左側中段巡邏
	# Enemy5 (1600,200)：在 WallDiv5 右側上方巡邏
	var routes = {
		"Enemy1": [Vector2(200, 200), Vector2(350, 200), Vector2(350, 350), Vector2(200, 350)],
		"Enemy2": [Vector2(600, 300), Vector2(700, 300), Vector2(700, 200), Vector2(600, 200)],
		"Enemy3": [Vector2(1000, 600), Vector2(1100, 600), Vector2(1100, 800), Vector2(900, 800)],
		"Enemy4": [Vector2(1400, 500), Vector2(1600, 500), Vector2(1600, 700), Vector2(1400, 700)],
		"Enemy5": [Vector2(1600, 200), Vector2(1800, 200), Vector2(1800, 400), Vector2(1600, 400)],
	}

	for enemy_name in routes:
		var enemy = enemies_node.get_node_or_null(enemy_name)
		if enemy and enemy.has_method("set_patrol_points"):
			var typed_points: Array[Vector2] = []
			for p in routes[enemy_name]:
				typed_points.append(p)
			enemy.set_patrol_points(typed_points)

func _setup_cover_objects():
	# 辦公室掩體物件（辦公桌、木箱、柱子）
	# 位置已避開敵人巡邏路線與現有隔牆
	var cover_defs = [
		# 辦公桌（48x32，棕色）
		{"pos": Vector2(500, 600),  "size": Vector2(48, 32), "color": Color(0.45, 0.28, 0.12), "name": "Desk1"},
		{"pos": Vector2(900, 250),  "size": Vector2(48, 32), "color": Color(0.45, 0.28, 0.12), "name": "Desk2"},
		{"pos": Vector2(1350, 300), "size": Vector2(48, 32), "color": Color(0.45, 0.28, 0.12), "name": "Desk3"},
		# 木箱（24x24，深棕色）
		{"pos": Vector2(650, 700),  "size": Vector2(24, 24), "color": Color(0.38, 0.22, 0.08), "name": "Box1"},
		{"pos": Vector2(1100, 400), "size": Vector2(24, 24), "color": Color(0.38, 0.22, 0.08), "name": "Box2"},
		{"pos": Vector2(1500, 800), "size": Vector2(24, 24), "color": Color(0.38, 0.22, 0.08), "name": "Box3"},
		# 柱子（16x48，深灰色）
		{"pos": Vector2(700, 150),  "size": Vector2(16, 48), "color": Color(0.30, 0.30, 0.30), "name": "Pillar1"},
		{"pos": Vector2(1300, 750), "size": Vector2(16, 48), "color": Color(0.30, 0.30, 0.30), "name": "Pillar2"},
	]

	var props_node = Node2D.new()
	props_node.name = "Props"
	$World.add_child(props_node)

	for def in cover_defs:
		var body = StaticBody2D.new()
		body.name = def["name"]
		body.position = def["pos"]
		body.collision_layer = 4  # 牆壁層，與現有隔牆一致
		body.collision_mask = 0

		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = def["size"]
		col.shape = shape
		body.add_child(col)

		var rect = ColorRect.new()
		rect.color = def["color"]
		rect.size = def["size"]
		rect.position = -def["size"] / 2.0
		body.add_child(rect)

		props_node.add_child(body)

func _create_floor_tiles():
	# 從 tilesheet 裁切第 2 列第 1 行（座標 0,64）的深灰地板磚，用 Sprite2D repeat 模式鋪滿地圖
	var tilesheet_path = ProjectSettings.globalize_path("res://assets/tiles/tilesheet_complete.png")
	var img = Image.load_from_file(tilesheet_path)
	if not img:
		push_warning("_create_floor_tiles: 無法載入 tilesheet_complete.png")
		return

	# 裁切磚塊（第 2 列第 1 行，深灰地板，RGBA 74,74,74）
	var tile_img = img.get_region(Rect2i(0, 64, 64, 64))
	var tile_tex = ImageTexture.create_from_image(tile_img)

	# 建立 Sprite2D，覆蓋整個地圖（1920x1080），用 region_rect 搭配 TEXTURE_REPEAT_ENABLED 鋪磚
	var floor_sprite = Sprite2D.new()
	floor_sprite.name = "FloorTiles"
	floor_sprite.texture = tile_tex
	floor_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor_sprite.region_enabled = true
	floor_sprite.region_rect = Rect2(0, 0, 1920, 1080)
	floor_sprite.centered = false
	floor_sprite.z_index = -2  # 低於 ColorRect Floor（z_index = -1）
	$World.add_child(floor_sprite)
