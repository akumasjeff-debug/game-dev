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

# 視覺強化用內部狀態
var _body_base_pos: Vector2 = Vector2.ZERO   # 身體基準位置（受擊震動還原用）
var _hp_tween: Tween = null                   # 血條補間（避免重疊）
var _hit_tween: Tween = null                  # 受擊閃白/震動補間
var _boss_aura = null                         # Boss 頭頂光環 ColorRect（untyped 避免存取 modulate/scale 的 parse error）
var _boss_marker = null                       # Boss 頭頂標記 Label（untyped）
var _aura_time: float = 0.0                   # Boss 光環呼吸計時

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
	_play_spawn_animation()

func _apply_type_stats() -> void:
	match enemy_type:
		EnemyType.NORMAL:
			enemy_name   = "普通兵"
			max_hp       = 1000.0
			attack_power = 28.0    # 45→28：隨機目標後脆皮後排也會中彈，降低 ATK 避免後排秒死
			attack_interval = 2.8  # 2.5→2.8：略放慢攻擊節奏
		EnemyType.ELITE:
			enemy_name   = "精英"
			max_hp       = 1650.0
			attack_power = 38.0    # 55→38
			attack_interval = 2.2
		EnemyType.BOSS:
			enemy_name   = "Boss"
			max_hp       = 2800.0
			attack_power = 48.0    # 65→48：降低 Boss 房單位時間傷害
			attack_interval = 2.2  # 2.0→2.2

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
		_body_base_pos = Vector2.ZERO  # Sprite2D centered，基準在原點
	else:
		var cr = ColorRect.new()
		cr.size = size
		cr.position = -size / 2.0
		cr.color = color
		_body = cr
		_body_base_pos = -size / 2.0  # ColorRect 以左上為位置基準
	add_child(_body)

	# Boss 專屬：頭頂能量光環（呼吸閃爍，威壓感）
	if enemy_type == EnemyType.BOSS:
		var aura = ColorRect.new()
		var aura_w: float = size.x + 28.0
		aura.size = Vector2(aura_w, aura_w)
		aura.position = Vector2(-aura_w / 2.0, -aura_w / 2.0)
		aura.color = Color(0.8, 0.1, 0.9, 0.12)
		aura.z_index = -1  # 在身體後方
		add_child(aura)
		_boss_aura = aura

	# 敵人血條 — 寬度依類型放大確保手機可見，加背景底色提升對比（移到頭頂上方）
	# Boss 血條更大更醒目（寬度與高度都放大）
	var hp_bar_w: float = 80.0
	var hp_bar_h: float = 12.0
	if enemy_type == EnemyType.ELITE:
		hp_bar_w = 100.0
		hp_bar_h = 14.0
	elif enemy_type == EnemyType.BOSS:
		hp_bar_w = 150.0
		hp_bar_h = 18.0

	var hp_y: float = -size.y / 2.0 - 18.0  # 血條在頭頂上方
	if enemy_type == EnemyType.BOSS:
		hp_y = -size.y / 2.0 - 24.0  # Boss 血條更高，避免被光環遮住

	# 血條外框（Boss 加金色邊提升醒目度）
	if enemy_type == EnemyType.BOSS:
		var hp_frame = ColorRect.new()
		hp_frame.size     = Vector2(hp_bar_w + 6, hp_bar_h + 6)
		hp_frame.position = Vector2(-(hp_bar_w + 6) / 2.0, hp_y - 3)
		hp_frame.color    = Color(0.85, 0.70, 0.0, 0.85)  # 金框
		add_child(hp_frame)

	var hp_bg_rect = ColorRect.new()
	hp_bg_rect.size     = Vector2(hp_bar_w, hp_bar_h)
	hp_bg_rect.position = Vector2(-hp_bar_w / 2.0, hp_y)
	hp_bg_rect.color    = Color(0.08, 0.05, 0.05, 0.90)
	add_child(hp_bg_rect)

	# 敵人名稱標籤 — 字型放大（原 12px 在手機上太小），放在血條上方
	# Boss 名稱字型更大且金色
	var name_font_size: int = 16
	if enemy_type == EnemyType.BOSS:
		name_font_size = 22
	_name_label = Label.new()
	_name_label.text = enemy_name
	_name_label.position = Vector2(-size.x / 2.0 - 4, hp_y - 24.0)
	_name_label.add_theme_font_size_override("font_size", name_font_size)
	if enemy_type == EnemyType.BOSS:
		_name_label.modulate = Color(1.0, 0.8, 0.2)  # Boss 金色名稱
	else:
		_name_label.modulate = Color(1.0, 0.85, 0.7)
	add_child(_name_label)

	# Boss 專屬頭頂標記（皇冠符號，威壓識別）
	if enemy_type == EnemyType.BOSS:
		_boss_marker = Label.new()
		_boss_marker.text = "★ BOSS ★"
		_boss_marker.position = Vector2(-44.0, hp_y - 50.0)
		_boss_marker.add_theme_font_size_override("font_size", 18)
		_boss_marker.modulate = Color(1.0, 0.25, 0.25)
		add_child(_boss_marker)

	_hp_bar = ProgressBar.new()
	_hp_bar.size = Vector2(hp_bar_w, hp_bar_h)
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
	# Boss 光環呼吸動畫（透明度與大小週期變化，營造能量威壓）
	if _boss_aura != null and is_instance_valid(_boss_aura):
		_aura_time += delta
		var pulse: float = (sin(_aura_time * 3.0) + 1.0) * 0.5  # 0~1
		_boss_aura.modulate.a = 0.5 + pulse * 0.9
		var s: float = 0.95 + pulse * 0.18
		_boss_aura.scale = Vector2(s, s)
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
		# 開火回饋：朝目標方向產生槍口閃光
		_spawn_muzzle_flash(target_node)
	else:
		# 無法取得主場景，回退直接扣血
		var gm = get_node_or_null("/root/GameManager")
		if gm:
			gm.apply_damage_to_member(target_node, attack_power)

func _get_frontline_member(gm: Node) -> Node:
	# 隨機鎖定一名存活隊員（不再固定優先打盾兵）
	var alive: Array = []
	for member in gm.squad_members:
		if member != null and is_instance_valid(member) and not member.is_dead:
			alive.append(member)
	if alive.is_empty():
		return null
	return alive[randi() % alive.size()]

func take_damage(amount: float) -> void:
	if is_dead:
		return
	# Boss 大招傷害上限：單次傷害最多扣 40% 最大 HP，防止一招秒殺
	if enemy_type == EnemyType.BOSS and amount > max_hp * 0.4:
		amount = max_hp * 0.4
	current_hp = max(0.0, current_hp - amount)

	# 血條補間動畫（平滑下降，比瞬間跳值更有打擊感）
	if _hp_bar:
		if _hp_tween != null and _hp_tween.is_valid():
			_hp_tween.kill()
		_hp_tween = create_tween()
		_hp_tween.tween_property(_hp_bar, "value", current_hp, 0.18) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 受擊回饋（最後一擊交給 die() 的閃白與爆裂，避免特效重疊）
	if current_hp > 0.0:
		_play_hit_feedback()
		_spawn_damage_number(amount)
	else:
		# 致命一擊仍要顯示傷害數字，但不重複閃白（die 會接手）
		_spawn_damage_number(amount)
		die()

func die() -> void:
	is_dead = true
	emit_signal("enemy_died", self)
	_spawn_kill_effect()
	# 爆裂粒子 + 碎片噴射（強化打擊感，Boss 更猛烈）
	_spawn_death_burst()

	# 停止 HP bar、名稱、Boss 光環與標記
	if _hp_bar:
		_hp_bar.hide()
	if _name_label:
		_name_label.hide()
	if _boss_aura != null and is_instance_valid(_boss_aura):
		_boss_aura.hide()
	if _boss_marker != null and is_instance_valid(_boss_marker):
		_boss_marker.hide()

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

# ============================================================
#  視覺強化：出場 / 開火 / 受擊 / 傷害數字 / 死亡爆裂
# ============================================================

# 出場動畫：上方掉落 + 淡入 + 著地彈跳，讓開戰有節奏感
func _play_spawn_animation() -> void:
	if _body == null:
		return
	var final_pos: Vector2 = position
	# 從上方略高處掉入 + 透明 → 不透明
	position = final_pos + Vector2(0, -36)
	modulate.a = 0.0
	# Boss 出場稍慢、更有份量
	var fall_time: float = 0.28
	var settle_time: float = 0.12
	if enemy_type == EnemyType.BOSS:
		fall_time = 0.42
		settle_time = 0.16
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, fall_time * 0.6)
	tw.parallel().tween_property(self, "position", final_pos + Vector2(0, 4), fall_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# 著地小回彈
	tw.tween_property(self, "position", final_pos, settle_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Boss 著地時光環閃一下
	if enemy_type == EnemyType.BOSS and _boss_aura != null and is_instance_valid(_boss_aura):
		tw.parallel().tween_property(_boss_aura, "modulate:a", 1.4, settle_time)

# 槍口閃光：朝目標方向的位置產生一個短暫黃白光點
func _spawn_muzzle_flash(target_node: Node) -> void:
	if _body == null or not is_instance_valid(_body):
		return
	# 計算朝向目標的方向
	var dir: Vector2 = Vector2(0, 1)  # 預設朝下（敵人在上方，打下方隊員）
	if target_node != null and is_instance_valid(target_node) and target_node is Node2D:
		var to_target: Vector2 = (target_node.global_position - global_position)
		if to_target.length() > 0.1:
			dir = to_target.normalized()

	var size = TYPE_SIZES[enemy_type]
	var flash_dist: float = size.x * 0.5 + 6.0

	# 閃光核心（亮黃白方塊）
	var flash = ColorRect.new()
	var fsize: float = 12.0
	if enemy_type == EnemyType.ELITE:
		fsize = 15.0
	elif enemy_type == EnemyType.BOSS:
		fsize = 20.0
	flash.size = Vector2(fsize, fsize)
	flash.color = Color(1.0, 0.92, 0.55, 0.95)
	flash.position = dir * flash_dist - Vector2(fsize / 2.0, fsize / 2.0)
	flash.z_index = 5
	add_child(flash)

	# 閃光快速放大後消失
	var tw = create_tween()
	tw.tween_property(flash, "scale", Vector2(1.6, 1.6), 0.04)
	tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.10)
	tw.tween_callback(flash.queue_free)

	# 槍口後座：身體沿反方向微震一下
	if _body is Node2D:
		var recoil: Vector2 = -dir * 3.0
		var bt = create_tween()
		bt.tween_property(_body, "position", _body_base_pos + recoil, 0.04)
		bt.tween_property(_body, "position", _body_base_pos, 0.08)

# 受擊回饋：閃白 + 左右抖動（不影響 die 的最終閃白）
func _play_hit_feedback() -> void:
	if _body == null or not is_instance_valid(_body) or not (_body is CanvasItem):
		return
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	# 閃白（用untyped區域變數避免 Node 型別存取 modulate 的 parse error）
	var body_ci = _body
	body_ci.modulate = Color(2.2, 2.2, 2.2, 1.0)
	_hit_tween = create_tween()
	_hit_tween.tween_property(_body, "modulate", Color(1, 1, 1, 1), 0.12)

	# 震動（左右快速抖動後歸位）
	if _body is Node2D:
		var st = create_tween()
		st.tween_property(_body, "position", _body_base_pos + Vector2(4, 0), 0.03)
		st.tween_property(_body, "position", _body_base_pos + Vector2(-3, 0), 0.03)
		st.tween_property(_body, "position", _body_base_pos + Vector2(2, 0), 0.03)
		st.tween_property(_body, "position", _body_base_pos, 0.03)

# 傷害數字：受傷時冒出白/黃飄字，傷害越高越大越黃
func _spawn_damage_number(amount: float) -> void:
	var scene_root = get_tree().current_scene if get_tree() else null
	if scene_root == null:
		return
	var lbl = Label.new()
	lbl.text = str(int(round(amount)))
	# 傷害量決定字級與顏色（小傷白色，大傷金黃且更大）
	var dmg_ratio: float = clamp(amount / max(1.0, max_hp * 0.15), 0.0, 1.0)
	var font_size: int = int(round(lerp(18.0, 34.0, dmg_ratio)))
	lbl.add_theme_font_size_override("font_size", font_size)
	# 白 → 黃 漸層
	var col: Color = Color(1.0, 1.0, 1.0).lerp(Color(1.0, 0.85, 0.2), dmg_ratio)
	lbl.modulate = col
	# 描邊提升可讀性（深色 outline）
	lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.0, 0.9))
	lbl.add_theme_constant_override("outline_size", 4)
	# 隨機水平偏移避免連續傷害數字重疊
	var jitter_x: float = randf_range(-14.0, 14.0)
	lbl.position = global_position + Vector2(jitter_x - 6, -TYPE_SIZES[enemy_type].y * 0.5 - 8)
	lbl.z_index = 20
	scene_root.add_child(lbl)

	var rise: float = 46.0 + dmg_ratio * 24.0
	var tw = create_tween()
	# 先上彈一點再緩升（彈跳手感）
	tw.tween_property(lbl, "position:y", lbl.position.y - rise * 0.6, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "position:y", lbl.position.y - rise, 0.45)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.45)
	tw.tween_callback(lbl.queue_free)

# 死亡爆裂：噴射碎片方塊 + 中心爆閃，Boss 數量更多、範圍更大
func _spawn_death_burst() -> void:
	var scene_root = get_tree().current_scene if get_tree() else null
	if scene_root == null:
		return
	var origin: Vector2 = global_position

	# 中心爆閃圈
	var flash = ColorRect.new()
	var fsize: float = TYPE_SIZES[enemy_type].x + 10.0
	flash.size = Vector2(fsize, fsize)
	flash.position = origin - Vector2(fsize / 2.0, fsize / 2.0)
	flash.color = Color(1.0, 0.85, 0.5, 0.9)
	flash.z_index = 15
	scene_root.add_child(flash)
	var ft = create_tween()
	ft.tween_property(flash, "scale", Vector2(1.8, 1.8), 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ft.parallel().tween_property(flash, "modulate:a", 0.0, 0.22)
	ft.tween_callback(flash.queue_free)

	# 碎片數量（控制上限以維持效能）
	var shard_count: int = 8
	var shard_color: Color = Color(0.85, 0.2, 0.15)  # NORMAL 紅
	if enemy_type == EnemyType.ELITE:
		shard_count = 11
		shard_color = Color(0.95, 0.5, 0.1)  # 橙
	elif enemy_type == EnemyType.BOSS:
		shard_count = 16
		shard_color = Color(0.75, 0.15, 0.85)  # 紫

	for i in range(shard_count):
		var shard = ColorRect.new()
		var ssize: float = randf_range(4.0, 9.0)
		if enemy_type == EnemyType.BOSS:
			ssize = randf_range(6.0, 13.0)
		shard.size = Vector2(ssize, ssize)
		shard.position = origin - Vector2(ssize / 2.0, ssize / 2.0)
		# 偶數碎片偏暗色，奇數偏亮，增加層次
		shard.color = shard_color.darkened(0.2) if (i % 2 == 0) else shard_color.lightened(0.25)
		shard.z_index = 14
		scene_root.add_child(shard)

		var ang: float = TAU * float(i) / float(shard_count) + randf_range(-0.3, 0.3)
		var dist: float = randf_range(40.0, 90.0)
		if enemy_type == EnemyType.BOSS:
			dist = randf_range(70.0, 150.0)
		var target_pos: Vector2 = origin + Vector2(cos(ang), sin(ang)) * dist - Vector2(ssize / 2.0, ssize / 2.0)

		var st = create_tween()
		st.tween_property(shard, "position", target_pos, randf_range(0.3, 0.5)) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		st.parallel().tween_property(shard, "rotation", randf_range(-PI, PI), 0.45)
		st.parallel().tween_property(shard, "modulate:a", 0.0, 0.5)
		st.tween_callback(shard.queue_free)
