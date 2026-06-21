extends Node2D

# 敵人節點：彩色方塊表示，自動攻擊最前方存活隊員

signal enemy_died(enemy: Node)

enum EnemyType { NORMAL, ELITE, BOSS }

@export var enemy_type: EnemyType = EnemyType.NORMAL
@export var enemy_name: String = "普通兵"

# 數值由類型決定（_ready 中初始化）
var max_hp: float = 100.0
var current_hp: float = 100.0
var attack_power: float = 15.0
var attack_interval: float = 2.0  # 每隔幾秒攻擊一次

var _attack_timer: float = 0.0
var is_dead: bool = false

# 視覺節點
var _body: Node  # Sprite2D（有 SVG 時）或 ColorRect（回退）
var _name_label: Label
var _hp_bar: ProgressBar

# 由 room.gd 設定（攻擊目標來源）
var room_ref: Node = null

# 敵人類型對應顏色
const TYPE_COLORS: Array[Color] = [
	Color(0.85, 0.25, 0.25, 1.0),   # 普通兵：紅色
	Color(0.90, 0.55, 0.10, 1.0),   # 精英：橙色
	Color(0.70, 0.10, 0.80, 1.0),   # Boss：紫色
]

const TYPE_SIZES: Array[Vector2] = [
	Vector2(36, 36),  # 普通兵
	Vector2(48, 48),  # 精英
	Vector2(64, 64),  # Boss
]

func _ready() -> void:
	_apply_type_stats()
	current_hp = max_hp
	_build_visual()
	add_to_group("enemies")

func _apply_type_stats() -> void:
	match enemy_type:
		EnemyType.NORMAL:
			enemy_name   = "普通兵"
			max_hp       = 150.0
			attack_power = 35.0
			attack_interval = 2.0
		EnemyType.ELITE:
			enemy_name   = "精英"
			max_hp       = 300.0
			attack_power = 50.0
			attack_interval = 2.0
		EnemyType.BOSS:
			enemy_name   = "Boss"
			max_hp       = 600.0
			attack_power = 70.0
			attack_interval = 1.5

const SPRITE_PATHS: Array[String] = [
	"res://resources/art/sprites/grunt_sprite.svg",   # NORMAL
	"res://resources/art/sprites/elite_sprite.svg",   # ELITE
	"res://resources/art/sprites/boss_sprite.svg",    # BOSS
]

func _build_visual() -> void:
	var size = TYPE_SIZES[enemy_type]
	var color = TYPE_COLORS[enemy_type]
	var sprite_path = SPRITE_PATHS[enemy_type]

	if ResourceLoader.exists(sprite_path):
		var sprite = Sprite2D.new()
		sprite.texture = load(sprite_path)
		sprite.centered = true
		sprite.scale = Vector2(size.x / 64.0, size.y / 64.0)
		_body = sprite
	else:
		var cr = ColorRect.new()
		cr.size = size
		cr.position = -size / 2.0
		cr.color = color
		_body = cr
	add_child(_body)

	_name_label = Label.new()
	_name_label.text = enemy_name
	_name_label.position = Vector2(-size.x / 2.0, -size.y / 2.0 - 20)
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.modulate = Color.WHITE
	add_child(_name_label)

	_hp_bar = ProgressBar.new()
	_hp_bar.size = Vector2(size.x + 10, 8)
	_hp_bar.position = Vector2(-size.x / 2.0 - 5, size.y / 2.0 + 4)
	_hp_bar.min_value = 0.0
	_hp_bar.max_value = max_hp
	_hp_bar.value = current_hp
	_hp_bar.show_percentage = false
	add_child(_hp_bar)

func _process(delta: float) -> void:
	if is_dead:
		return
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = attack_interval
		_do_attack()

func _do_attack() -> void:
	# 取得最前方存活隊員（squad group 中第一個非死亡的）
	var gm = get_node_or_null("/root/GameManager")
	if gm == null:
		return
	# 偵察手大招 blind 狀態：敵人攻擊無效
	if gm.enemies_blinded:
		return
	var best_target = _get_frontline_member(gm)
	if best_target == null:
		return
	# 發射子彈（命中後才透過 GameManager 扣血）
	_fire_bullet(best_target)

func _fire_bullet(target_node: Node) -> void:
	var bullet_script = load("res://scripts/bullet.gd")
	if bullet_script == null:
		# 回退：直接透過 GameManager 扣血
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			gm.apply_damage_to_member(target_node, attack_power)
		return

	var bullet = Node2D.new()
	bullet.set_script(bullet_script)
	# 加到主場景根節點（讓子彈不隨房間移動）
	var main = get_tree().current_scene if get_tree() else null
	if main:
		main.add_child(bullet)
		bullet.setup(global_position, target_node, attack_power, "enemy")
	else:
		# 無法取得主場景，回退直接扣血
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			gm.apply_damage_to_member(target_node, attack_power)

func _get_frontline_member(gm: Node) -> Node:
	# 盾兵優先作為前線（有盾兵且未死亡）；否則取第一個存活隊員
	for member in gm.squad_members:
		if member != null and is_instance_valid(member) and not member.is_dead and member.char_id == "shield":
			return member
	for member in gm.squad_members:
		if member != null and is_instance_valid(member) and not member.is_dead:
			return member
	return null

func take_damage(amount: float) -> void:
	if is_dead:
		return
	# Boss 大招傷害上限：單次傷害最多扣 40% 最大 HP，防止一招秒殺
	if enemy_type == EnemyType.BOSS and amount > max_hp * 0.4:
		amount = max_hp * 0.4
	current_hp = max(0.0, current_hp - amount)
	if _hp_bar:
		_hp_bar.value = current_hp
	if current_hp <= 0.0:
		die()

func die() -> void:
	is_dead = true
	if _body:
		_body.modulate = Color(0.3, 0.3, 0.3, 0.6)
	if _name_label:
		_name_label.modulate = Color(0.4, 0.4, 0.4)
	emit_signal("enemy_died", self)
	# 延遲 0.3 秒後從場景移除（讓死亡顏色閃一下）
	var t = get_tree().create_timer(0.3)
	t.timeout.connect(queue_free)

func get_hp_ratio() -> float:
	if max_hp <= 0.0:
		return 0.0
	return current_hp / max_hp
