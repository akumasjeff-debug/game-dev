extends Node2D

# 子彈節點 — 飛行後命中目標扣血並消失
# 由 enemy._do_attack() 或 character._try_auto_attack() 動態 instance 並加到主場景

var damage: float = 10.0
var speed: float = 400.0
var direction: Vector2 = Vector2.ZERO
var target: Node = null       # 目標節點（到達後扣血）
var owner_type: String = ""   # "player" 或 "enemy"

# 子彈顏色
var _bullet_color: Color = Color(1.0, 0.9, 0.2)  # 預設黃色（玩家子彈）

# 最大飛行距離（防止子彈無限飛行）
var _max_distance: float = 600.0
var _traveled: float = 0.0

# 視覺節點
var _body: ColorRect

func _ready() -> void:
	_build_visual()

func _build_visual() -> void:
	_body = ColorRect.new()
	if owner_type == "enemy":
		_bullet_color = Color(1.0, 0.3, 0.3)   # 紅色（敵人子彈）
		_body.size = Vector2(6, 6)
	else:
		_bullet_color = Color(1.0, 0.95, 0.3)  # 黃色（玩家子彈）
		_body.size = Vector2(5, 5)
	_body.color = _bullet_color
	_body.position = -_body.size / 2.0
	add_child(_body)

func setup(from_pos: Vector2, to_node: Node, dmg: float, btype: String) -> void:
	global_position = from_pos
	target = to_node
	damage = dmg
	owner_type = btype
	# 依據 owner_type 調整顏色（setup 在 _ready 之前或之後都可能呼叫，需同步更新）
	if _body:
		if owner_type == "enemy":
			_body.color = Color(1.0, 0.3, 0.3)
			_body.size = Vector2(6, 6)
		else:
			_body.color = Color(1.0, 0.95, 0.3)
			_body.size = Vector2(5, 5)
		_body.position = -_body.size / 2.0
	if target and is_instance_valid(target):
		direction = (target.global_position - from_pos).normalized()
	else:
		direction = Vector2.UP

func _process(delta: float) -> void:
	if not is_instance_valid(self):
		return

	# 飛行
	var move = direction * speed * delta
	global_position += move
	_traveled += move.length()

	# 檢查命中目標
	if target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist < 20.0:
			_on_hit()
			return

	# 超出最大距離或目標無效，消失
	if _traveled >= _max_distance or not is_instance_valid(target):
		queue_free()

func _on_hit() -> void:
	# 對目標扣血
	if target and is_instance_valid(target):
		if owner_type == "enemy":
			# 敵人子彈走 GameManager，套用防禦與 buff 計算
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("apply_damage_to_member"):
				gm.apply_damage_to_member(target, damage)
			elif target.has_method("take_damage"):
				target.take_damage(damage)
		else:
			# 玩家子彈直接扣敵人血
			if target.has_method("take_damage"):
				target.take_damage(damage)
	# 命中特效（短暫閃光）
	_flash_hit()

func _flash_hit() -> void:
	if _body:
		_body.color = Color(1.0, 1.0, 1.0)
		_body.size = Vector2(10, 10)
		_body.position = -_body.size / 2.0
	var t = get_tree().create_timer(0.05)
	if t:
		t.timeout.connect(queue_free)
	else:
		queue_free()
