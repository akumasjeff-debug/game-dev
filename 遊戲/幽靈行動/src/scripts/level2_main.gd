extends Node2D

# 關卡 2：倉庫廠房 — 暗殺任務
# 目標：消滅 BossEnemy（倉庫主管）

var mission_manager: Node = null
var _bgm: AudioStreamPlayer

func _ready():
	add_to_group("main_controller")
	_start_bgm()
	_setup_mission_manager()
	await get_tree().process_frame
	_setup_patrol_routes()
	_connect_enemy_signals()
	_configure_boss_enemy()
	_show_mission_objective()

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
	stream.loop_end = data.size() / 2
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
	mission_manager.setup_assassination("BossEnemy")
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

func _on_mission_complete():
	_stop_bgm()
	var hud_nodes = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0:
		hud_nodes[0].show_victory_panel()

func _on_mission_failed(_reason: String):
	pass  # 目前 HUD 尚未實作失敗面板，預留接口

func _configure_boss_enemy():
	# TODO: enemy.gd 中 SPEED 與 VISION_RANGE 皆為 const，
	# 需改為 var 才能在此修改。目前先略過，不 crash。
	# 預期 BossEnemy 規格：視野 400px，移速 80px/s。
	var boss = $World/Enemies/BossEnemy
	if boss and boss.has_method("set_vision_range"):
		boss.set_vision_range(400.0)
	if boss and "SPEED" in boss:
		boss.SPEED = 80.0

func _show_mission_objective():
	var hud_nodes = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0:
		var hud = hud_nodes[0]
		if hud.has_method("set_mission_text"):
			hud.set_mission_text("目標：暗殺倉庫主管")

func _setup_patrol_routes():
	var enemies_node = $World/Enemies
	if not enemies_node:
		return

	# 關卡 2 巡邏路線（依倉庫隔間設計）
	# Enemy0 (300,200)：左上隔間巡邏
	# Enemy1 (600,150)：左上通道巡邏
	# Enemy2 (500,500)：左下開放區巡邏
	# Enemy3 (900,300)：中段隔間巡邏
	# Enemy4 (1200,200)：右上隔間巡邏
	# Enemy5 (1100,700)：右下隔間巡邏
	# BossEnemy (1650,540)：最右側大房間巡邏
	var routes = {
		"Enemy0": [Vector2(200, 150), Vector2(350, 150), Vector2(350, 350), Vector2(200, 350)],
		"Enemy1": [Vector2(450, 80), Vector2(700, 80), Vector2(700, 180), Vector2(450, 180)],
		"Enemy2": [Vector2(100, 450), Vector2(350, 450), Vector2(350, 900), Vector2(100, 900)],
		"Enemy3": [Vector2(800, 100), Vector2(1000, 100), Vector2(1000, 380), Vector2(800, 380)],
		"Enemy4": [Vector2(1100, 80), Vector2(1300, 80), Vector2(1300, 250), Vector2(1100, 250)],
		"Enemy5": [Vector2(1100, 600), Vector2(1300, 600), Vector2(1300, 950), Vector2(1100, 950)],
		"BossEnemy": [Vector2(1450, 300), Vector2(1850, 300), Vector2(1850, 800), Vector2(1450, 800)],
	}

	for enemy_name in routes:
		var enemy = enemies_node.get_node_or_null(enemy_name)
		if enemy and enemy.has_method("set_patrol_points"):
			var typed_points: Array[Vector2] = []
			for p in routes[enemy_name]:
				typed_points.append(p)
			enemy.set_patrol_points(typed_points)
