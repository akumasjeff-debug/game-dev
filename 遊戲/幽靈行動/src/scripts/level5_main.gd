extends Node2D

# 關卡 5：廢棄造船廠 — 殲滅任務（最終關卡）
# 目標：消滅所有敵人

var mission_manager: Node = null
var _bgm: AudioStreamPlayer

func _ready():
	add_to_group("main_controller")
	_start_bgm()
	_setup_mission_manager()
	await get_tree().process_frame
	_setup_patrol_routes()
	_connect_enemy_signals()
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
	_show_clear_text()

func _show_clear_text():
	var hud_nodes = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0:
		var hud = hud_nodes[0]
		if hud.has_method("set_mission_text"):
			hud.set_mission_text("全部消滅！任務完成！")
	# 短暫延遲後顯示勝利面板
	await get_tree().create_timer(1.5).timeout
	var hud_nodes2 = get_tree().get_nodes_in_group("hud")
	if hud_nodes2.size() > 0:
		hud_nodes2[0].show_victory_panel()

func _on_mission_failed(_reason: String):
	pass  # 預留接口

func _show_mission_objective():
	var hud_nodes = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0:
		var hud = hud_nodes[0]
		if hud.has_method("set_mission_text"):
			hud.set_mission_text("消滅所有敵人——這是最後的戰場")

func _setup_patrol_routes():
	var enemies_node = $World/Enemies
	if not enemies_node:
		return

	# 關卡 5 巡邏路線（廢棄造船廠，12 個敵人）
	# Alpha 組（5 個）：右側造船廠主體
	# Bravo 組（4 個）：中段廊道
	# Charlie 組（3 個）：左側碼頭區
	var routes = {
		"enemy_alpha_1": [Vector2(1700, 100), Vector2(1500, 100), Vector2(1500, 300), Vector2(1700, 300)],
		"enemy_alpha_2": [Vector2(1800, 300), Vector2(1550, 300), Vector2(1550, 480), Vector2(1800, 480)],
		"enemy_alpha_3": [Vector2(1850, 540), Vector2(1600, 540), Vector2(1600, 400), Vector2(1850, 400)],
		"enemy_alpha_4": [Vector2(1800, 750), Vector2(1550, 750), Vector2(1550, 600), Vector2(1800, 600)],
		"enemy_alpha_5": [Vector2(1700, 960), Vector2(1500, 960), Vector2(1500, 760), Vector2(1700, 760)],
		"enemy_bravo_1": [Vector2(1200, 150), Vector2(1000, 150), Vector2(1000, 350), Vector2(1200, 350)],
		"enemy_bravo_2": [Vector2(1200, 400), Vector2(950, 400), Vector2(950, 540), Vector2(1200, 540)],
		"enemy_bravo_3": [Vector2(1200, 680), Vector2(950, 680), Vector2(950, 540), Vector2(1200, 540)],
		"enemy_bravo_4": [Vector2(1200, 950), Vector2(1000, 950), Vector2(1000, 750), Vector2(1200, 750)],
		"enemy_charlie_1": [Vector2(800, 150), Vector2(650, 150), Vector2(650, 350), Vector2(800, 350)],
		"enemy_charlie_2": [Vector2(800, 540), Vector2(650, 540), Vector2(650, 400), Vector2(800, 400)],
		"enemy_charlie_3": [Vector2(800, 950), Vector2(650, 950), Vector2(650, 750), Vector2(800, 750)],
	}

	for enemy_name in routes:
		var enemy = enemies_node.get_node_or_null(enemy_name)
		if enemy and enemy.has_method("set_patrol_points"):
			var typed_points: Array[Vector2] = []
			for p in routes[enemy_name]:
				typed_points.append(p)
			enemy.set_patrol_points(typed_points)
