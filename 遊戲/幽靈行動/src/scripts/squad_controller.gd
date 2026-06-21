extends Node2D

# 小隊推進控制器
# 沿 waypoints 路徑移動，保持隊形

signal progress_updated(ratio: float)
signal reached_end()

@export var move_speed: float = 80.0  # pixels/sec

var waypoints: Array[Vector2] = []
var current_waypoint_index: int = 0
var total_distance: float = 0.0
var traveled_distance: float = 0.0
var reached_destination: bool = false

var members: Array = []
var _pivot_position: Vector2 = Vector2.ZERO

func _get_gm() -> Node:
	return get_node_or_null("/root/GameManager")

func _ready() -> void:
	pass

func setup(wps: Array[Vector2], squad: Array) -> void:
	waypoints = wps
	members = squad
	if waypoints.size() > 0:
		_pivot_position = waypoints[0]
		_calculate_total_distance()
	_update_member_positions()

func _calculate_total_distance() -> void:
	total_distance = 0.0
	for i in range(waypoints.size() - 1):
		total_distance += waypoints[i].distance_to(waypoints[i + 1])

func _process(delta: float) -> void:
	var gm = _get_gm()
	if gm == null:
		return
	if gm.is_paused or reached_destination or gm.is_game_over:
		return
	_advance(delta, gm)

func _advance(delta: float, gm: Node) -> void:
	if waypoints.size() < 2:
		return
	if current_waypoint_index >= waypoints.size() - 1:
		return

	var from = waypoints[current_waypoint_index]
	var to = waypoints[current_waypoint_index + 1]
	var segment_length = from.distance_to(to)

	if segment_length <= 0.0:
		current_waypoint_index += 1
		return

	var step = move_speed * delta
	traveled_distance += step

	var direction = (to - from).normalized()
	_pivot_position += direction * step

	if _pivot_position.distance_to(from) >= segment_length:
		_pivot_position = to
		current_waypoint_index += 1

		if current_waypoint_index >= waypoints.size() - 1:
			reached_destination = true
			emit_signal("reached_end")
			return

	_update_member_positions()

	var ratio = clamp(traveled_distance / total_distance, 0.0, 1.0)
	gm.set_progress(ratio)
	emit_signal("progress_updated", ratio)

func _update_member_positions() -> void:
	for member in members:
		if member != null and is_instance_valid(member):
			member.position = _pivot_position + member.formation_offset

func get_pivot_position() -> Vector2:
	return _pivot_position

func set_pivot(pos: Vector2) -> void:
	_pivot_position = pos
	_update_member_positions()

func replace_remaining_path(new_waypoints: Array[Vector2]) -> void:
	# 替換剩餘路徑：從當前位置接上新 waypoints
	# 保留已走的距離，重新計算 total_distance
	var current_pos = _pivot_position
	waypoints = [current_pos]
	for wp in new_waypoints:
		waypoints.append(wp)
	current_waypoint_index = 0
	reached_destination = false
	_calculate_total_distance()
	# 重置 traveled_distance 為已走比例（保持進度條連續）
	# 用保守估計：不重置，讓進度條繼續累積
	_update_member_positions()
