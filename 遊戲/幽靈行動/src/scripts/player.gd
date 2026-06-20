extends CharacterBody2D

# 數值（改為 var 以支援職業系統動態修改）
var SPEED = 150.0
var MAX_HP = 100
var MAX_AMMO = 30
var FIRE_RATE = 0.1       # 600 RPM = 每 0.1 秒一發
var DAMAGE = 25
var RELOAD_TIME = 2.0
var RANGE = 500.0

# 狀態
var hp: int = MAX_HP
var ammo: int = MAX_AMMO
var locked_target: Node2D = null  # 鎖定的目標
var reloading: bool = false
var fire_timer: float = 0.0
var reload_timer: float = 0.0
var _is_dead: bool = false
var _hit_flash_timer: float = 0.0
const HIT_FLASH_DURATION = 0.15

# 職業
var current_class: String = "assault"

# 準星
var _crosshair: Node2D

# 參考
@onready var vision_cone = $VisionCone
@onready var cop_sprite = $CopSprite

# 音效
var _sfx_gunshot: AudioStreamPlayer
var _sfx_reload: AudioStreamPlayer

signal hp_changed(current_hp, max_hp)
signal ammo_changed(current_ammo, max_ammo)
signal reload_started()
signal reload_finished()
signal died()

func _load_wav(path: String) -> AudioStreamWAV:
	# 用 FileAccess 直接讀取 WAV PCM，繞過 import 系統
	var full_path = ProjectSettings.globalize_path(path)
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return null
	# 跳過 WAV header（44 bytes）
	f.seek(44)
	var data = f.get_buffer(f.get_length() - 44)
	f.close()
	var stream = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = 22050
	return stream

func _ready():
	add_to_group("player")
	cop_sprite.reconfigure("player")  # 玩家使用藍色精靈集

	# 建立槍聲播放器
	_sfx_gunshot = AudioStreamPlayer.new()
	add_child(_sfx_gunshot)
	var gs_stream = _load_wav("res://assets/audio/sfx/gunshot.wav")
	if gs_stream:
		_sfx_gunshot.stream = gs_stream

	# 建立換彈聲播放器
	_sfx_reload = AudioStreamPlayer.new()
	add_child(_sfx_reload)
	var rl_stream = _load_wav("res://assets/audio/sfx/reload.wav")
	if rl_stream:
		_sfx_reload.stream = rl_stream

	emit_signal("hp_changed", hp, MAX_HP)
	emit_signal("ammo_changed", ammo, MAX_AMMO)

	# 隱藏系統游標
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# 建立準星（圓形 + 十字線），加到場景根節點而非玩家子節點
	_crosshair = Node2D.new()
	_crosshair.z_index = 20
	get_parent().call_deferred("add_child", _crosshair)

	# 外圓
	var circle = _make_circle_outline(12.0, Color(1, 1, 1, 0.8))
	_crosshair.add_child(circle)

	# 四條短線（十字）
	for i in range(4):
		var angle = float(i) * PI / 2.0
		var line = Line2D.new()
		line.add_point(Vector2(cos(angle) * 15.0, sin(angle) * 15.0))
		line.add_point(Vector2(cos(angle) * 22.0, sin(angle) * 22.0))
		line.width = 1.5
		line.default_color = Color(1, 1, 1, 0.8)
		_crosshair.add_child(line)

func _make_circle_outline(radius: float, color: Color) -> Node2D:
	var node = Node2D.new()
	var line = Line2D.new()
	for i in range(33):
		var a = float(i) / 32.0 * TAU
		line.add_point(Vector2(cos(a), sin(a)) * radius)
	line.width = 1.5
	line.default_color = color
	node.add_child(line)
	return node

func _process(_delta):
	# 更新準星位置跟隨滑鼠
	if _crosshair and is_instance_valid(_crosshair):
		_crosshair.global_position = get_global_mouse_position()

func _physics_process(delta):
	_handle_input(delta)
	_update_aim()
	_handle_shooting(delta)
	_handle_reload(delta)
	move_and_slide()
	# 受傷閃紅（只作用在 sprite）
	if cop_sprite:
		if _hit_flash_timer > 0.0:
			_hit_flash_timer -= delta
			cop_sprite.modulate = Color(1.5, 0.3, 0.3)
		else:
			cop_sprite.modulate = Color(1, 1, 1)

func _handle_input(delta):
	var dir = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		dir.y -= 1
	if Input.is_action_pressed("move_down"):
		dir.y += 1
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_right"):
		dir.x += 1

	# 滑鼠左鍵點擊 → 嘗試鎖定最近的敵人
	if Input.is_action_just_pressed("shoot"):
		_try_lock_target()

	# 手動換彈（R 鍵）：未在換彈中且彈藥不滿時可觸發
	if Input.is_action_just_pressed("manual_reload") and not reloading and ammo < MAX_AMMO:
		_start_reload()

	velocity = dir.normalized() * SPEED

func _update_aim():
	# 有鎖定目標時，玩家朝向鎖定目標（不跟滑鼠）
	if locked_target and is_instance_valid(locked_target):
		var dir = locked_target.global_position - global_position
		rotation = dir.angle()
	else:
		# 原本邏輯：朝向滑鼠或移動方向
		var mouse_pos = get_global_mouse_position()
		var dir_to_mouse = (mouse_pos - global_position)
		if dir_to_mouse.length() > 5.0:
			rotation = dir_to_mouse.angle()
		elif velocity.length() > 10.0:
			rotation = velocity.angle()
		else:
			var nearest = _find_nearest_enemy()
			if nearest:
				var dir = (nearest.global_position - global_position)
				rotation = dir.angle()

	# 視野錐形跟著子節點繼承的 Player rotation，不需額外設定

	# 8 方向 sprite 更新
	if cop_sprite:
		if velocity.length() > 10.0:
			cop_sprite.play_walk(rotation)
		else:
			cop_sprite.update_direction(rotation)

func _find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist = INF
	for e in enemies:
		var d = global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest

func _try_lock_target():
	var mouse_pos = get_global_mouse_position()
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist = 200.0  # 點擊容差 200px
	for e in enemies:
		var d = mouse_pos.distance_to(e.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = e
	locked_target = closest  # 若點到空地，清除鎖定（closest = null）

func _handle_shooting(delta):
	if reloading:
		return
	fire_timer -= delta
	if fire_timer <= 0.0:
		var target = _find_enemy_in_cone()
		if target:
			_fire(target)

func _find_enemy_in_cone() -> Node2D:
	var space = get_world_2d().direct_space_state

	# 若有 locked_target 且在視野內 + 有 LOS，優先選它
	if locked_target and is_instance_valid(locked_target):
		var to_locked = locked_target.global_position - global_position
		var dist = to_locked.length()
		if dist <= RANGE:
			var query = PhysicsRayQueryParameters2D.create(global_position, locked_target.global_position, 4)
			query.exclude = [self]
			var result = space.intersect_ray(query)
			if not result:
				return locked_target  # 優先打鎖定目標
		else:
			locked_target = null  # 超出範圍自動解鎖

	# 若無鎖定目標，走原本邏輯（視野內最近敵人）
	var enemies = get_tree().get_nodes_in_group("enemies")
	var half_cone = deg_to_rad(60.0)  # 120° 扇形的一半
	var nearest: Node2D = null
	var nearest_dist = INF
	for e in enemies:
		var to_enemy = e.global_position - global_position
		var dist = to_enemy.length()
		if dist > RANGE:
			continue
		# 角度差計算（標準化到 -PI ~ PI）
		var diff = fmod(to_enemy.angle() - rotation + 3.0 * PI, 2.0 * PI) - PI
		if abs(diff) > half_cone:
			continue
		# 視線穿透檢查（只擋牆壁，collision_mask = 4）
		var query = PhysicsRayQueryParameters2D.create(global_position, e.global_position, 4)
		query.exclude = [self]
		var result = space.intersect_ray(query)
		if result:
			continue  # 中間有牆，射不到
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = e
	return nearest

func _fire(target):
	fire_timer = FIRE_RATE
	ammo -= 1
	emit_signal("ammo_changed", ammo, MAX_AMMO)
	if _sfx_gunshot and _sfx_gunshot.stream:
		_sfx_gunshot.play()
	_spawn_bullet(target.global_position)
	if ammo <= 0:
		_start_reload()

func _spawn_bullet(target_pos: Vector2):
	var scene = load("res://scenes/Bullet.tscn")
	if not scene:
		return
	var bullet = scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = (target_pos - global_position).normalized()
	bullet.damage = DAMAGE
	bullet.from_player = true
	get_parent().add_child(bullet)

func _start_reload():
	if reloading:
		return
	reloading = true
	reload_timer = RELOAD_TIME
	if _sfx_reload and _sfx_reload.stream:
		_sfx_reload.play()
	emit_signal("reload_started")

func _handle_reload(delta):
	if not reloading:
		return
	reload_timer -= delta
	if reload_timer <= 0.0:
		reloading = false
		ammo = MAX_AMMO
		emit_signal("reload_finished")
		emit_signal("ammo_changed", ammo, MAX_AMMO)

func take_damage(amount: int):
	if _is_dead:
		return
	hp -= amount
	hp = max(0, hp)
	_hit_flash_timer = HIT_FLASH_DURATION
	emit_signal("hp_changed", hp, MAX_HP)
	if hp <= 0:
		_is_dead = true
		emit_signal("died")
		_die()

func _die():
	set_physics_process(false)
	# 恢復系統游標
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# 隱藏準星
	if _crosshair and is_instance_valid(_crosshair):
		_crosshair.visible = false
	# 簡易死亡：隱藏玩家
	hide()

# 套用職業數值
func apply_class(class_key: String):
	var data = ClassData.CLASSES.get(class_key, ClassData.CLASSES["assault"])
	current_class = class_key
	MAX_HP = data["hp"]
	SPEED = data["speed"]
	DAMAGE = data["damage"]
	FIRE_RATE = data["fire_rate"]
	MAX_AMMO = data["ammo"]
	RELOAD_TIME = data["reload_time"]
	RANGE = data["range"]
	# 重設當前狀態為新職業的滿值
	hp = MAX_HP
	ammo = MAX_AMMO
	reloading = false
	fire_timer = 0.0
	reload_timer = 0.0
	emit_signal("hp_changed", hp, MAX_HP)
	emit_signal("ammo_changed", ammo, MAX_AMMO)
