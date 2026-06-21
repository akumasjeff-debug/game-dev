extends CharacterBody2D

# --- 狀態機 ---
enum State { IDLE, FOLLOWING, STOPPED }
var state: State = State.IDLE

# --- 數值 ---
const SPEED: float = 100.0
const FOLLOW_RANGE: float = 80.0

# --- 參考 ---
var _player: Node2D = null
@onready var _nav: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	add_to_group("hostages")
	# 等一幀讓場景樹穩定後再找玩家，NavigationServer 也需要一幀初始化
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
		# 監聽玩家死亡事件
		if _player.has_signal("died"):
			_player.died.connect(_on_player_died)

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			_check_player_proximity()
		State.FOLLOWING:
			_follow_player()
		State.STOPPED:
			velocity = Vector2.ZERO
			move_and_slide()

# --- 接近偵測 ---
func _check_player_proximity() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var dist = global_position.distance_to(_player.global_position)
	if dist <= FOLLOW_RANGE:
		state = State.FOLLOWING

# --- 跟隨邏輯 ---
func _follow_player() -> void:
	if _player == null or not is_instance_valid(_player):
		state = State.STOPPED
		return

	# 更新導航目標
	_nav.target_position = _player.global_position

	# NavigationServer 尚未準備好時跳過
	if _nav.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var next_pos = _nav.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	velocity = direction * SPEED
	move_and_slide()

# --- 玩家死亡回呼 ---
func _on_player_died() -> void:
	state = State.STOPPED

# --- 外部查詢介面 ---
func get_is_following() -> bool:
	return state == State.FOLLOWING
