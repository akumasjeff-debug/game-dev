extends Node

# 任務類型
enum MissionType { ELIMINATION, RESCUE, ASSASSINATION, DEFENSE }

# 當前任務設定
var mission_type: MissionType = MissionType.ELIMINATION
var time_limit: float = 0.0      # DEFENSE 用，秒，0=無限時
var time_remaining: float = 0.0
var target_name: String = ""     # ASSASSINATION 用，目標敵人名稱
var hostage: Node2D = null       # RESCUE 用，人質節點
var exit_zone: Area2D = null     # RESCUE 用，逃脫區域

signal mission_complete()
signal mission_failed(reason: String)
signal time_updated(remaining: float)

func _ready():
	add_to_group("mission_manager")

func _process(delta):
	if mission_type == MissionType.DEFENSE and time_limit > 0:
		time_remaining -= delta
		emit_signal("time_updated", time_remaining)
		if time_remaining <= 0:
			emit_signal("mission_complete")

# 設定任務（由關卡腳本呼叫）
func setup_elimination():
	mission_type = MissionType.ELIMINATION

func setup_rescue(h: Node2D, exit: Area2D):
	mission_type = MissionType.RESCUE
	hostage = h
	exit_zone = exit
	# 當人質進入逃脫區域時完成
	if exit_zone:
		exit_zone.body_entered.connect(_on_exit_body_entered)

func setup_assassination(target: String):
	mission_type = MissionType.ASSASSINATION
	target_name = target

func setup_defense(duration: float):
	mission_type = MissionType.DEFENSE
	time_limit = duration
	time_remaining = duration

# 由外部呼叫：敵人死亡時
func on_enemy_died(enemy: Node2D):
	match mission_type:
		MissionType.ELIMINATION:
			await get_tree().process_frame
			var enemies = get_tree().get_nodes_in_group("enemies")
			if enemies.is_empty():
				emit_signal("mission_complete")
		MissionType.ASSASSINATION:
			if enemy.name == target_name:
				emit_signal("mission_complete")

# 逃脫區域觸發
func _on_exit_body_entered(body: Node2D):
	if mission_type == MissionType.RESCUE:
		if body == hostage:
			emit_signal("mission_complete")

# 人質死亡時呼叫
func on_hostage_died():
	if mission_type == MissionType.RESCUE:
		emit_signal("mission_failed", "人質陣亡")
