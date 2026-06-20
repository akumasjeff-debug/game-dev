extends Node2D

# 關卡 4：軍事指揮中心 — 限時防守任務
# 目標：守住陣地 60 秒

var mission_manager: Node = null
var _bgm: AudioStreamPlayer

# ── 增援波次系統 ──────────────────────────────────────────
var _next_wave_time: float = 20.0   # 第一波在第 20 秒
var _wave_count: int = 0
const MAX_WAVES = 3                  # 共 3 波（20s / 35s / 50s）
var _warning_shown: bool = false     # 本波「增援即將到來」提示是否已顯示
# ─────────────────────────────────────────────────────────

func _ready():
	add_to_group("main_controller")
	_start_bgm()
	_setup_mission_manager()
	await get_tree().process_frame
	_setup_patrol_routes()
	_connect_enemy_signals()
	_show_mission_objective()
	# 連接倒數計時更新到 HUD
	mission_manager.time_updated.connect(_on_time_updated)
	# 啟動 HUD 倒數顯示
	var hud_nodes = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0:
		if hud_nodes[0].has_method("start_countdown"):
			hud_nodes[0].start_countdown(60.0)

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
	mission_manager.setup_defense(60.0)
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

func _on_time_updated(remaining: float):
	var hud_nodes = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0:
		if hud_nodes[0].has_method("update_countdown"):
			hud_nodes[0].update_countdown(remaining)

	# 計算已過時間（總時 60 秒）
	var elapsed = 60.0 - remaining
	_check_reinforcement(elapsed, remaining)

func _check_reinforcement(elapsed: float, remaining: float):
	if _wave_count >= MAX_WAVES:
		return
	# 增援前 5 秒顯示提示（每波只顯示一次）
	if not _warning_shown and elapsed >= (_next_wave_time - 5.0):
		_warning_shown = true
		var hud_nodes = get_tree().get_nodes_in_group("hud")
		if hud_nodes.size() > 0 and hud_nodes[0].has_method("set_mission_text"):
			hud_nodes[0].set_mission_text("⚠ 增援即將到來！")
	# 到達波次時間則生成
	if elapsed >= _next_wave_time:
		_spawn_wave()
		_next_wave_time += 15.0
		_wave_count += 1
		_warning_shown = false
		# 還原任務文字
		var hud_nodes = get_tree().get_nodes_in_group("hud")
		if hud_nodes.size() > 0 and hud_nodes[0].has_method("set_mission_text"):
			hud_nodes[0].set_mission_text("目標：守住陣地 %d 秒" % int(remaining))

func _spawn_wave():
	var spawn_points: Array[Vector2] = [
		Vector2(randf_range(200, 1720), 50),    # 上邊緣
		Vector2(randf_range(200, 1720), 1030),  # 下邊緣
		Vector2(50, randf_range(100, 980)),     # 左邊緣
		Vector2(1870, randf_range(100, 980)),   # 右邊緣
	]
	spawn_points.shuffle()
	# 各選 2 個邊緣，各生成 1 個敵人
	for i in range(2):
		_spawn_enemy_at(spawn_points[i])

func _spawn_enemy_at(pos: Vector2):
	var scene = load("res://scenes/Enemy.tscn")
	if not scene:
		push_error("Level4: 無法載入 Enemy.tscn")
		return
	var e = scene.instantiate()
	e.global_position = pos
	add_child(e)
	# 設定初始巡邏點：生成位置 → 地圖中央
	if e.has_method("set_patrol_points"):
		var pts: Array[Vector2] = [pos, Vector2(960, 540)]
		e.set_patrol_points(pts)
	# 連接死亡信號（與 kill count 整合）
	if e.has_signal("died") and not e.died.is_connected(_on_enemy_died):
		e.died.connect(_on_enemy_died)

func _on_mission_complete():
	_stop_bgm()
	var hud_nodes = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0:
		hud_nodes[0].show_victory_panel()

func _on_mission_failed(_reason: String):
	pass  # 預留接口

func _show_mission_objective():
	var hud_nodes = get_tree().get_nodes_in_group("hud")
	if hud_nodes.size() > 0:
		var hud = hud_nodes[0]
		if hud.has_method("set_mission_text"):
			hud.set_mission_text("目標：守住陣地 60 秒")

func _setup_patrol_routes():
	var enemies_node = $World/Enemies
	if not enemies_node:
		return

	# 關卡 4 巡邏路線（敵人從四面八方逼近，各自在起始點附近小範圍巡邏）
	var routes = {
		"Enemy1":  [Vector2(150,150),  Vector2(300,150),  Vector2(300,300),  Vector2(150,300)],
		"Enemy2":  [Vector2(400,80),   Vector2(600,80),   Vector2(600,200),  Vector2(400,200)],
		"Enemy3":  [Vector2(850,60),   Vector2(1150,60),  Vector2(1150,180), Vector2(850,180)],
		"Enemy4":  [Vector2(1350,120), Vector2(1600,120), Vector2(1600,280), Vector2(1350,280)],
		"Enemy5":  [Vector2(1700,200), Vector2(1870,200), Vector2(1870,400), Vector2(1700,400)],
		"Enemy6":  [Vector2(1700,600), Vector2(1870,600), Vector2(1870,800), Vector2(1700,800)],
		"Enemy7":  [Vector2(1350,850), Vector2(1600,850), Vector2(1600,970), Vector2(1350,970)],
		"Enemy8":  [Vector2(750,870),  Vector2(1100,870), Vector2(1100,970), Vector2(750,970)],
		"Enemy9":  [Vector2(300,800),  Vector2(550,800),  Vector2(550,970),  Vector2(300,970)],
		"Enemy10": [Vector2(60,500),   Vector2(250,500),  Vector2(250,750),  Vector2(60,750)],
	}

	for enemy_name in routes:
		var enemy = enemies_node.get_node_or_null(enemy_name)
		if enemy and enemy.has_method("set_patrol_points"):
			var typed_points: Array[Vector2] = []
			for p in routes[enemy_name]:
				typed_points.append(p)
			enemy.set_patrol_points(typed_points)
