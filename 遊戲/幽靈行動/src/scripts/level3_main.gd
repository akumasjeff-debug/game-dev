extends Node2D

# 關卡 3：醫院急救室 — 救援任務
# 目標：護送人質至逃脫區域

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
	# 用 gameplay_bgm.wav（rescue 任務用不同緊張感）
	var f = FileAccess.open("res://assets/audio/bgm/gameplay_bgm.wav", FileAccess.READ)
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
	var hostage = $World/Hostage
	var exit_zone = $World/ExitZone
	mission_manager.setup_rescue(hostage, exit_zone)
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

func _on_mission_failed(reason: String):
	_stop_bgm()
	var hud_nodes = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0 and hud_nodes[0].has_method("_on_mission_failed"):
		hud_nodes[0]._on_mission_failed(reason)

func _show_mission_objective():
	var hud_nodes = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0:
		var hud = hud_nodes[0]
		if hud.has_method("set_mission_text"):
			hud.set_mission_text("目標：護送人質至逃脫區域")

func _setup_patrol_routes():
	var enemies_node = $World/Enemies
	if not enemies_node:
		return
	var routes = {
		"Enemy0": [Vector2(480,100),Vector2(560,100),Vector2(560,300),Vector2(480,300)],
		"Enemy1": [Vector2(400,800),Vector2(560,800),Vector2(560,900),Vector2(400,900)],
		"Enemy2": [Vector2(700,300),Vector2(820,300),Vector2(820,500),Vector2(700,500)],
		"Enemy3": [Vector2(700,650),Vector2(820,650),Vector2(820,800),Vector2(700,800)],
		"Enemy4": [Vector2(1020,100),Vector2(1180,100),Vector2(1180,280),Vector2(1020,280)],
		"Enemy5": [Vector2(1020,460),Vector2(1180,460),Vector2(1180,620),Vector2(1020,620)],
		"Enemy6": [Vector2(1020,780),Vector2(1180,780),Vector2(1180,960),Vector2(1020,960)],
		"Enemy7": [Vector2(1360,280),Vector2(1520,280),Vector2(1520,440),Vector2(1360,440)],
		"Enemy8": [Vector2(1360,640),Vector2(1520,640),Vector2(1520,800),Vector2(1360,800)],
	}
	for enemy_name in routes:
		var enemy = enemies_node.get_node_or_null(enemy_name)
		if enemy and enemy.has_method("set_patrol_points"):
			var typed_points: Array[Vector2] = []
			for p in routes[enemy_name]:
				typed_points.append(p)
			enemy.set_patrol_points(typed_points)
