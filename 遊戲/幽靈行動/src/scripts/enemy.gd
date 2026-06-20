extends CharacterBody2D

# 敵人數值
const MAX_HP = 75
const SPEED = 120.0
const DAMAGE = 20
const FIRE_RATE = 0.5
const VISION_RANGE = 350.0
const VISION_ANGLE = deg_to_rad(120.0)
const ATTACK_RANGE = 150.0
const WAYPOINT_REACH_DIST = 20.0

# 狀態機
enum State { PATROL, ALERT, CHASE, SHOOT }
var state: State = State.PATROL

# 內部變數
var hp: int = MAX_HP
var fire_timer: float = FIRE_RATE  # 避免第一幀立即開槍
var current_waypoint: int = 0
var player: Node2D = null
var patrol_points: Array[Vector2] = []
var alert_timer: float = 0.0
var last_known_player_pos: Vector2 = Vector2.ZERO
var can_see_player: bool = false

# 視覺元件（動態建立）
var _vision_cone: Polygon2D

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var vision_ray: RayCast2D = $VisionRay
@onready var sprite = $CopSprite
@onready var hp_bar: ColorRect = $HPBar
@onready var hp_fill: ColorRect = $HPBar/HPFill

signal died(enemy)

func _ready():
	add_to_group("enemies")
	if patrol_points.is_empty():
		patrol_points = [global_position, global_position + Vector2(100, 0), global_position + Vector2(100, 100)]

	# 建立敵人視野錐形（紅色半透明，指向本地 +X 方向，父節點 rotation 自動帶動）
	_vision_cone = Polygon2D.new()
	_vision_cone.color = Color(1.0, 0.2, 0.2, 0.07)
	_vision_cone.z_index = 2
	var pts = PackedVector2Array()
	pts.append(Vector2.ZERO)
	var half = VISION_ANGLE / 2.0
	for i in range(17):
		var t = float(i) / 16.0
		var a = -half + t * VISION_ANGLE
		pts.append(Vector2(cos(a), sin(a)) * VISION_RANGE)
	_vision_cone.polygon = pts
	add_child(_vision_cone)

	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	_update_hp_bar()

func _physics_process(delta):
	fire_timer -= delta
	can_see_player = _check_vision()
	# 更新 sprite 方向
	if sprite and sprite.has_method("update_direction"):
		sprite.update_direction(rotation)
	match state:
		State.PATROL:
			_do_patrol(delta)
			if can_see_player:
				_set_state(State.CHASE)
		State.ALERT:
			_do_alert(delta)
			if can_see_player:
				_set_state(State.CHASE)
		State.CHASE:
			_do_chase(delta)
			if not can_see_player:
				# 失去視線 → 回警覺，前往最後目擊點
				alert_timer = 4.0
				_set_state(State.ALERT)
			elif global_position.distance_to(player.global_position) <= ATTACK_RANGE:
				_set_state(State.SHOOT)
		State.SHOOT:
			if not can_see_player:
				_set_state(State.CHASE)
			else:
				_do_shoot(delta)

func _check_vision() -> bool:
	if not player:
		return false

	# 距離檢查
	var to_player = player.global_position - global_position
	if to_player.length() > VISION_RANGE:
		return false

	# 視野錐形角度（只能看到正前方 120° 內）
	var angle = abs(wrapf(to_player.angle() - rotation, -PI, PI))
	if angle > VISION_ANGLE / 2.0:
		return false

	# 射線確認（牆壁遮擋）
	if vision_ray:
		vision_ray.target_position = to_local(player.global_position)
		vision_ray.force_raycast_update()
		if vision_ray.is_colliding():
			var hit = vision_ray.get_collider()
			if not hit or not hit.is_in_group("player"):
				return false

	last_known_player_pos = player.global_position
	return true

func _do_patrol(_delta):
	if patrol_points.is_empty():
		return
	var target = patrol_points[current_waypoint]
	var dir = (target - global_position)
	if dir.length() < WAYPOINT_REACH_DIST:
		current_waypoint = (current_waypoint + 1) % patrol_points.size()
	else:
		velocity = dir.normalized() * SPEED * 0.6
		rotation = dir.angle()
	move_and_slide()

func _do_alert(delta):
	alert_timer -= delta
	# 往最後目擊點移動（若有），到了就停下來等
	if last_known_player_pos != Vector2.ZERO:
		var dir = last_known_player_pos - global_position
		if dir.length() > WAYPOINT_REACH_DIST:
			velocity = dir.normalized() * SPEED * 0.7
			rotation = dir.angle()
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	if alert_timer <= 0.0:
		last_known_player_pos = Vector2.ZERO
		_set_state(State.PATROL)

func _do_chase(_delta):
	if not player:
		_set_state(State.PATROL)
		return
	var target = player.global_position
	var dir = (target - global_position)
	velocity = dir.normalized() * SPEED
	rotation = dir.angle()
	if nav_agent:
		nav_agent.target_position = target
		var next = nav_agent.get_next_path_position()
		var nav_dir = (next - global_position).normalized()
		velocity = nav_dir * SPEED
	move_and_slide()

func _do_shoot(_delta):
	if not player:
		return
	velocity = Vector2.ZERO
	var dir = (player.global_position - global_position)
	rotation = dir.angle()
	# 離開攻擊範圍則追擊（can_see_player 已確認為 true 才會到這裡）
	if dir.length() > ATTACK_RANGE * 1.2:
		_set_state(State.CHASE)
		return
	if fire_timer <= 0.0:
		fire_timer = FIRE_RATE
		_shoot()

func _shoot():
	if player and player.has_method("take_damage"):
		# 簡易命中判斷：射線（用 vision_ray 重用）
		if vision_ray:
			vision_ray.target_position = to_local(player.global_position)
			vision_ray.force_raycast_update()
			if vision_ray.is_colliding():
				var hit = vision_ray.get_collider()
				if hit and hit.is_in_group("player"):
					player.take_damage(DAMAGE)

func _set_state(new_state: State):
	state = new_state
	if not sprite:
		return
	# 保留紅色基底 (1, 0.35, 0.35)，用亮度變化表示狀態
	match new_state:
		State.PATROL:
			sprite.modulate = Color(1.0, 0.35, 0.35)   # 正常紅
		State.ALERT:
			sprite.modulate = Color(1.0, 0.75, 0.1)    # 橘色=警覺
		State.CHASE:
			sprite.modulate = Color(1.0, 0.2, 0.2)     # 深紅=追擊
		State.SHOOT:
			sprite.modulate = Color(1.0, 0.1, 0.1)     # 最深紅=射擊

func take_damage(amount: int):
	hp -= amount
	hp = max(0, hp)
	_update_hp_bar()
	# 受傷立即進入追擊狀態
	if state == State.PATROL or state == State.ALERT:
		_set_state(State.CHASE)
	if hp <= 0:
		_die()

func _update_hp_bar():
	if hp_fill:
		hp_fill.size.x = (float(hp) / float(MAX_HP)) * 24.0

func _die():
	emit_signal("died", self)
	queue_free()

# 由地圖場景設定巡邏點
func set_patrol_points(points: Array[Vector2]):
	patrol_points = points
	current_waypoint = 0
