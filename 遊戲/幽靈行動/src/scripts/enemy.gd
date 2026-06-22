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

var _attack_timer: float = 1.0  # 初始延遲 1 秒，避免開戰瞬間立即攻擊
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
			max_hp       = 1000.0  # 1200→1000：配合 ATK 提升，縮短 1-1 時長至約 24s
			attack_power = 45.0    # 35→45：提升壓迫感，盾兵（500HP）存活約 9.3s
			attack_interval = 2.5
		EnemyType.ELITE:
			enemy_name   = "精英"
			max_hp       = 1650.0
			attack_power = 55.0
			attack_interval = 2.0
		EnemyType.BOSS:
			enemy_name   = "Boss"
			max_hp       = 2800.0
			attack_power = 65.0    # 75→65：降低 Boss 房單位時間傷害，給玩家喘息空間
			attack_interval = 2.0  # 1.5→2.0：配合 ATK 調降，讓玩家有時間反應

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

	# 敵人血條 — 寬度依類型放大確保手機可見，加背景底色提升對比（移到頭頂上方）
	var hp_bar_w: float = 80.0
	if enemy_type == EnemyType.ELITE:
		hp_bar_w = 100.0
	elif enemy_type == EnemyType.BOSS:
		hp_bar_w = 130.0

	var hp_y: float = -size.y / 2.0 - 18.0  # 血條在頭頂上方

	var hp_bg_rect = ColorRect.new()
	hp_bg_rect.size     = Vector2(hp_bar_w, 12)
	hp_bg_rect.position = Vector2(-hp_bar_w / 2.0, hp_y)
	hp_bg_rect.color    = Color(0.08, 0.05, 0.05, 0.90)
	add_child(hp_bg_rect)

	# 敵人名稱標籤 — 字型放大（原 12px 在手機上太小），放在血條上方
	_name_label = Label.new()
	_name_label.text = enemy_name
	_name_label.position = Vector2(-size.x / 2.0 - 4, hp_y - 22.0)
	_name_label.add_theme_font_size_override("font_size", 16)
	_name_label.modulate = Color(1.0, 0.85, 0.7)
	add_child(_name_label)

	_hp_bar = ProgressBar.new()
	_hp_bar.size = Vector2(hp_bar_w, 12)
	_hp_bar.position = Vector2(-hp_bar_w / 2.0, hp_y)
	_hp_bar.min_value = 0.0
	_hp_bar.max_value = max_hp
	_hp_bar.value = current_hp
	_hp_bar.show_percentage = false
	var hp_fill_style = StyleBoxFlat.new()
	if enemy_type == EnemyType.BOSS:
		hp_fill_style.bg_color = Color(0.65, 0.10, 0.80)
	elif enemy_type == EnemyType.ELITE:
		hp_fill_style.bg_color = Color(0.90, 0.50, 0.10)
	else:
		hp_fill_style.bg_color = Color(0.85, 0.20, 0.15)
	var hp_bg_style = StyleBoxFlat.new()
	hp_bg_style.bg_color = Color(0, 0, 0, 0)
	_hp_bar.add_theme_stylebox_override("fill", hp_fill_style)
	_hp_bar.add_theme_stylebox_override("background", hp_bg_style)
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
	# 進場動畫或暫停狀態：敵人不攻擊
	if gm.is_paused:
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

	if AudioManager:
		AudioManager.play_sfx("gunshot_enemy")
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
	emit_signal("enemy_died", self)
	_spawn_kill_effect()

	# 停止 HP bar 與名稱標籤
	if _hp_bar:
		_hp_bar.hide()
	if _name_label:
		_name_label.hide()

	# 死亡動畫序列
	var tw = create_tween()

	# 1. 閃白（被擊中感）
	if _body:
		tw.tween_property(_body, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.05)

	# 2. 膨脹再縮小（爆炸感）
	tw.tween_property(self, "scale", Vector2(1.4, 1.4), 0.08)
	tw.tween_property(self, "scale", Vector2(0.6, 0.6), 0.12)

	# 3. 旋轉倒下（Boss 以外）
	if enemy_type != EnemyType.BOSS:
		tw.parallel().tween_property(self, "rotation", PI * 0.5, 0.2)
		tw.parallel().tween_property(_body if _body else self, "modulate", Color(0.2, 0.0, 0.0, 0.4), 0.2)
	else:
		# Boss：更戲劇化，往後仰並變紫黑色
		tw.parallel().tween_property(self, "scale", Vector2(1.8, 1.8), 0.15)
		tw.parallel().tween_property(_body if _body else self, "modulate", Color(0.4, 0.0, 0.6, 0.8), 0.15)
		tw.tween_property(self, "scale", Vector2(0.0, 0.0), 0.3)

	# 4. 淡出
	tw.tween_property(self, "modulate:a", 0.0, 0.25)

	# 5. 移除節點
	tw.tween_callback(queue_free)

func _spawn_kill_effect() -> void:
	var scene_root = get_tree().current_scene
	if scene_root == null:
		return

	var lbl = Label.new()
	var kill_text = "ELIMINATED"
	var kill_color = Color(1.0, 0.3, 0.3)
	if enemy_type == EnemyType.ELITE:
		kill_text = "ELITE DOWN"
		kill_color = Color(1.0, 0.6, 0.1)
	elif enemy_type == EnemyType.BOSS:
		kill_text = "BOSS DEFEATED"
		kill_color = Color(0.8, 0.2, 1.0)

	# 擊殺飄字 — 字型放大確保手機螢幕清晰可見，飄升距離加大
	var kill_font_size: int = 26
	if enemy_type == EnemyType.ELITE:
		kill_font_size = 32
	elif enemy_type == EnemyType.BOSS:
		kill_font_size = 42
	lbl.text = kill_text
	lbl.add_theme_font_size_override("font_size", kill_font_size)
	lbl.modulate = kill_color
	lbl.position = global_position + Vector2(-80, -40)
	scene_root.add_child(lbl)

	var tw = create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 80, 0.9)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.9)
	tw.tween_callback(lbl.queue_free)

func get_hp_ratio() -> float:
	if max_hp <= 0.0:
		return 0.0
	return current_hp / max_hp
