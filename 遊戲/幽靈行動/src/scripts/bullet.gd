extends Node2D

# 子彈節點 — 飛行後命中目標扣血並消失
# 由 enemy._do_attack() 或 character._try_auto_attack() 動態 instance 並加到主場景

var damage: float = 10.0
var speed: float = 850.0       # 飛行速度（提高：原 400 太慢，打擊感不足）
var direction: Vector2 = Vector2.ZERO
var target: Node = null       # 目標節點（到達後扣血）
var owner_type: String = ""   # "player" 或 "enemy"

# 子彈顏色
var _bullet_color: Color = Color(1.0, 0.9, 0.2)  # 預設黃色（玩家子彈）

# 最大飛行距離（防止子彈無限飛行）
# 注意：角色 y≈1520、敵人 y≈400，垂直距離就有 ~1120，原本 600 會讓子彈
# 飛到半空就消失、永遠打不到對方 → 必須涵蓋全螢幕對角（√(1080²+1920²)≈2200）
var _max_distance: float = 2500.0
var _traveled: float = 0.0

# 視覺節點（Sprite2D 或 ColorRect — 不可標註為 Node2D，否則 `_body is ColorRect` 會 parse error）
var _body

func _ready() -> void:
	z_index = 8  # 子彈在角色(0)與掩體(5)之上，飛行全程可見
	_build_visual()

func _build_visual() -> void:
	var sprite_path = "res://resources/art/sprites/bullet_player.svg"
	if owner_type == "enemy":
		sprite_path = "res://resources/art/sprites/bullet_enemy.svg"

	if ResourceLoader.exists(sprite_path):
		var sprite = Sprite2D.new()
		sprite.texture = load(sprite_path)
		sprite.centered = true
		sprite.scale = Vector2(2.4, 2.4)  # 放大子彈，手機上清晰可見
		_body = sprite
	else:
		# 回退：保留原 ColorRect（放大）
		var cr = ColorRect.new()
		if owner_type == "enemy":
			cr.color = Color(1.0, 0.3, 0.3)
			cr.size = Vector2(14, 14)
		else:
			cr.color = Color(1.0, 0.95, 0.3)
			cr.size = Vector2(12, 12)
		cr.position = -cr.size / 2.0
		_body = cr
	add_child(_body)

func setup(from_pos: Vector2, to_node: Node, dmg: float, btype: String) -> void:
	global_position = from_pos
	target = to_node
	damage = dmg
	owner_type = btype
	# 依據 owner_type 調整顏色（setup 在 _ready 之前或之後都可能呼叫，需同步更新）
	# 注意：_body 可能是 Sprite2D（無 .color/.size）或 ColorRect，需型別判斷
	if _body:
		if _body is ColorRect:
			if owner_type == "enemy":
				_body.color = Color(1.0, 0.3, 0.3)
				_body.size = Vector2(6, 6)
			else:
				_body.color = Color(1.0, 0.95, 0.3)
				_body.size = Vector2(5, 5)
			_body.position = -_body.size / 2.0
		elif _body is Sprite2D:
			# Sprite2D 用 modulate 調色，不調 size
			if owner_type == "enemy":
				_body.modulate = Color(1.0, 0.3, 0.3)
			else:
				_body.modulate = Color(1.0, 0.95, 0.3)
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
		if _body is ColorRect:
			_body.color = Color(1.0, 1.0, 1.0)
			_body.size = Vector2(10, 10)
			_body.position = -_body.size / 2.0
		elif _body is Sprite2D:
			_body.modulate = Color(1.0, 1.0, 1.0, 1.0)
			_body.scale = Vector2(1.5, 1.5)
	var t = get_tree().create_timer(0.05)
	if t:
		t.timeout.connect(queue_free)
	else:
		queue_free()
