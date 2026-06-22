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
var _glow            # 飛行微光（在 _body 下方，淡黃光暈）
var _has_hit: bool = false  # 防止重複命中

# 拖尾：記錄上次留下殘影的位置，每飛行一段距離留一段漸淡殘影
var _last_trail_pos: Vector2 = Vector2.ZERO
const TRAIL_STEP: float = 22.0   # 每飛行 22px 留一段殘影（拉大間距 = 控制殘影總量、顧效能）

func _ready() -> void:
	z_index = 8  # 子彈在角色(0)與掩體(5)之上，飛行全程可見
	_build_visual()

func _build_visual() -> void:
	var sprite_path = "res://resources/art/sprites/bullet_player.svg"
	if owner_type == "enemy":
		sprite_path = "res://resources/art/sprites/bullet_enemy.svg"

	# 飛行微光（軟光暈，墊在子彈下方一層）
	var glow = ColorRect.new()
	glow.size = Vector2(20, 20)
	glow.position = -glow.size / 2.0
	glow.color = Color(1.0, 0.85, 0.3, 0.18) if owner_type != "enemy" else Color(1.0, 0.35, 0.3, 0.18)
	glow.z_index = -1
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow = glow
	add_child(_glow)

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
	_last_trail_pos = from_pos
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
	if _glow:
		_glow.color = Color(1.0, 0.85, 0.3, 0.18) if owner_type != "enemy" else Color(1.0, 0.35, 0.3, 0.18)
	if target and is_instance_valid(target):
		direction = (target.global_position - from_pos).normalized()
	else:
		direction = Vector2.UP
	# 子彈尖端朝飛行方向（SVG 預設尖端朝上 = -Y，故旋轉量為 direction.angle() + 90°）
	if _body and direction != Vector2.ZERO:
		rotation = direction.angle() + PI / 2.0

func _process(delta: float) -> void:
	if not is_instance_valid(self):
		return

	# 飛行
	var move = direction * speed * delta
	global_position += move
	_traveled += move.length()

	# 留下拖尾殘影（每隔 TRAIL_STEP 距離一段）
	if global_position.distance_to(_last_trail_pos) >= TRAIL_STEP:
		_spawn_trail_segment(_last_trail_pos)
		_last_trail_pos = global_position

	# 檢查命中目標
	if target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist < 20.0:
			_on_hit()
			return

	# 超出最大距離或目標無效，消失
	if _traveled >= _max_distance or not is_instance_valid(target):
		queue_free()

# 在指定全域座標生成一段拖尾殘影，自行淡出消失（不阻塞、不增加碰撞）
func _spawn_trail_segment(at_global: Vector2) -> void:
	var tree = get_tree()
	var main = tree.current_scene if tree else null
	if main == null:
		return
	var seg = ColorRect.new()
	seg.size = Vector2(7, 7)
	seg.color = Color(1.0, 0.82, 0.25, 0.5) if owner_type != "enemy" else Color(1.0, 0.35, 0.3, 0.5)
	seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seg.z_index = 7  # 在子彈本體(8)下方
	main.add_child(seg)
	seg.global_position = at_global - seg.size / 2.0
	var tw = tree.create_tween()
	tw.tween_property(seg, "modulate:a", 0.0, 0.18)
	tw.parallel().tween_property(seg, "scale", Vector2(0.3, 0.3), 0.18)
	tw.tween_callback(seg.queue_free)

func _on_hit() -> void:
	if _has_hit:
		return
	_has_hit = true
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
	# 命中特效（爆閃 + 火花）
	_spawn_impact_burst()
	_flash_hit()

# 命中爆閃：在命中點生成一圈擴散白光 + 數個火花，獨立於子彈本體（子彈隨即消失）
func _spawn_impact_burst() -> void:
	var tree = get_tree()
	var main = tree.current_scene if tree else null
	if main == null:
		return
	var hit_pos = global_position
	if target and is_instance_valid(target):
		hit_pos = target.global_position
	var base_col = Color(1.0, 0.95, 0.5) if owner_type != "enemy" else Color(1.0, 0.4, 0.35)

	# 中央爆閃圓（由小放大後淡出）
	var flash = ColorRect.new()
	flash.size = Vector2(26, 26)
	flash.color = Color(base_col.r, base_col.g, base_col.b, 0.9)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 9
	flash.pivot_offset = flash.size / 2.0
	main.add_child(flash)
	flash.global_position = hit_pos - flash.size / 2.0
	flash.scale = Vector2(0.4, 0.4)
	var ft = tree.create_tween()
	ft.tween_property(flash, "scale", Vector2(1.4, 1.4), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ft.parallel().tween_property(flash, "modulate:a", 0.0, 0.14)
	ft.tween_callback(flash.queue_free)

	# 火花粒子（4 顆向外噴，效能控制在低量）
	var spark_count = 4
	for i in range(spark_count):
		var spark = ColorRect.new()
		spark.size = Vector2(5, 5)
		spark.color = base_col
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spark.z_index = 9
		main.add_child(spark)
		spark.global_position = hit_pos - spark.size / 2.0
		var ang = TAU * float(i) / float(spark_count) + randf_range(-0.4, 0.4)
		var dist = randf_range(18.0, 30.0)
		var dest = hit_pos + Vector2(cos(ang), sin(ang)) * dist - spark.size / 2.0
		var st = tree.create_tween()
		st.tween_property(spark, "global_position", dest, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		st.parallel().tween_property(spark, "modulate:a", 0.0, 0.16)
		st.tween_callback(spark.queue_free)

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
