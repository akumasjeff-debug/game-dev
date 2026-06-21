extends Node2D

# 角色基礎節點：HP、大招 CD、視覺呈現

signal hp_changed(current: float, max_val: float)
signal ultimate_ready()
signal ultimate_used()
signal character_died()

@export var char_id: String = ""
@export var char_name: String = "角色"
@export var max_hp: float = 100.0
@export var attack_power: float = 30.0
@export var defense: float = 0.0  # 防禦值（百分比減傷），如 25 代表減傷 25%
@export var formation_offset: Vector2 = Vector2.ZERO
@export var body_color: Color = Color.WHITE
@export var ultimate_cd: float = 30.0
@export var ultimate_name: String = "大招"
@export var level: int = 1  # 角色等級，預設 Lv.1

var current_hp: float = 100.0
var cd_timer: float = 0.0
var is_ultimate_ready: bool = true
var is_dead: bool = false

# 自動攻擊計時器
var _auto_attack_timer: float = 0.0
var auto_attack_interval: float = 1.5  # 每 1.5 秒攻擊一次（狙擊手覆寫為 3.0）

# 爆破手首次大招 CD 標記（Demo 教學特例：首次 CD 縮短為 20 秒）
var _first_ult_used: bool = false

# 視覺節點
var _body: Node  # Sprite2D（有 SVG 素材時）或 ColorRect（回退色塊）
var _name_label: Label
var _hp_bar: ProgressBar

func _get_gm() -> Node:
	return get_node_or_null("/root/GameManager")

func _ready() -> void:
	current_hp = max_hp
	_build_visual()
	# 狙擊手攻擊間隔較長
	if char_id == "sniper":
		auto_attack_interval = 3.0
	# 初始計時器錯開，避免所有角色同時發射
	_auto_attack_timer = randf_range(0.0, auto_attack_interval)

func _build_visual() -> void:
	# 優先載入像素方塊 SVG sprite，無則退回職業色塊
	var sprite_path = "res://resources/art/sprites/" + char_id + "_sprite.svg"
	if char_id != "" and ResourceLoader.exists(sprite_path):
		var sprite = Sprite2D.new()
		sprite.texture = load(sprite_path)
		sprite.centered = true
		sprite.scale = Vector2(40.0 / 64.0, 40.0 / 64.0)  # 64px SVG 縮至 40px 顯示
		_body = sprite
	else:
		var cr = ColorRect.new()
		cr.size = Vector2(40, 40)
		cr.position = Vector2(-20, -20)
		cr.color = body_color
		_body = cr
	add_child(_body)

	# 名稱標籤
	_name_label = Label.new()
	_name_label.text = char_name
	_name_label.position = Vector2(-30, -42)
	_name_label.add_theme_font_size_override("font_size", 11)
	_name_label.modulate = Color.WHITE
	add_child(_name_label)

	# HP 條
	_hp_bar = ProgressBar.new()
	_hp_bar.size = Vector2(50, 8)
	_hp_bar.position = Vector2(-25, 24)
	_hp_bar.min_value = 0.0
	_hp_bar.max_value = max_hp
	_hp_bar.value = current_hp
	_hp_bar.show_percentage = false
	add_child(_hp_bar)

func _process(delta: float) -> void:
	if is_dead:
		return
	# CD 倒數
	if not is_ultimate_ready:
		cd_timer -= delta
		if cd_timer <= 0.0:
			cd_timer = 0.0
			is_ultimate_ready = true
			emit_signal("ultimate_ready")
	# 自動攻擊
	_auto_attack_timer -= delta
	if _auto_attack_timer <= 0.0:
		_auto_attack_timer = auto_attack_interval
		_try_auto_attack()

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_hp = max(0.0, current_hp - amount)
	if _hp_bar:
		_hp_bar.value = current_hp
	emit_signal("hp_changed", current_hp, max_hp)
	if current_hp <= 0.0:
		die()

func heal(amount: float) -> void:
	if is_dead:
		return
	current_hp = min(max_hp, current_hp + amount)
	if _hp_bar:
		_hp_bar.value = current_hp
	emit_signal("hp_changed", current_hp, max_hp)

func use_ultimate() -> bool:
	if not is_ultimate_ready or is_dead:
		return false
	is_ultimate_ready = false
	# 爆破手首次大招 CD：Demo 教學特例，第一次施放只需 20 秒 CD
	if char_id == "demo" and not _first_ult_used:
		cd_timer = 20.0
		_first_ult_used = true
	else:
		cd_timer = ultimate_cd
	emit_signal("ultimate_used")
	_apply_ultimate_effect()
	return true

# 自動攻擊音效入口：外部系統（squad AI、battle system）呼叫此方法觸發一次射擊音效
func fire_shot() -> void:
	if char_id == "demo":
		AudioManager.play_sfx("explosion")
	else:
		AudioManager.play_sfx("gunshot")

func _apply_ultimate_effect() -> void:
	# 各職業大招效果 — P1 實作
	var gm = _get_gm()
	if gm == null:
		return
	match char_id:
		"shield":
			# 全隊受傷害降低 50%，持續 5 秒
			gm.activate_shield_buff()
		"assault":
			# 全隊攻擊力提升 60%，持續 8 秒
			gm.activate_assault_buff()
		"sniper":
			# 精準鎖定：目標 HP < 25% 時瞬殺；否則造成 300% 攻擊力傷害
			var enemies = get_tree().get_nodes_in_group("enemies") if get_tree() else []
			if enemies.size() > 0:
				var target = enemies[0]
				# 找血量最低的目標
				for e in enemies:
					if e and is_instance_valid(e) and e.get("current_hp") != null:
						if e.current_hp < target.current_hp:
							target = e
				if target and is_instance_valid(target) and target.has_method("take_damage"):
					var t_hp_ratio = 0.0
					if target.get("max_hp") != null and target.max_hp > 0:
						t_hp_ratio = float(target.current_hp) / float(target.max_hp)
					if t_hp_ratio < 0.25:
						# 目標 HP < 25%：瞬殺
						target.take_damage(target.current_hp + 9999.0)
						if OS.is_debug_build():
							print("[狙擊手大招] 精準鎖定！目標 HP < 25%，瞬殺！")
					else:
						# fallback：300% 攻擊力傷害
						var dmg = attack_power * 3.0
						target.take_damage(dmg)
						if OS.is_debug_build():
							print("[狙擊手大招] 精準鎖定！目標 HP 不足，造成 %.1f 傷害。" % dmg)
			else:
				# 沒有實體敵人時，設一個 pending 標記供下次決策傷害事件使用
				gm.set_sniper_mark(null)
				gm.sniper_mark_pending = true
				if OS.is_debug_build():
					print("[狙擊手大招] 精準鎖定標記！下次進入房間觸發。")
		"medic":
			# 全隊立即恢復 30% 最大 HP
			for member in gm.squad_members:
				if member != null and is_instance_valid(member) and not member.is_dead:
					member.heal(member.max_hp * 0.3)
		"demo":
			# 房間內所有敵人立即扣 70% HP
			var targets = get_tree().get_nodes_in_group("enemies") if get_tree() else []
			for enemy in targets:
				if enemy != null and is_instance_valid(enemy) and enemy.has_method("take_damage"):
					enemy.take_damage(enemy.max_hp * 0.7)
			# 若無實體敵人，標記 pending 供決策傷害事件使用
			if targets.size() == 0:
				gm.demo_bomb_pending = true
		"recon":
			# 煙霧封鎖：所有敵人攻擊失效 5 秒
			gm.activate_recon_blind()

func die() -> void:
	is_dead = true
	if _body:
		_body.modulate = Color(0.35, 0.35, 0.35)  # 死亡灰化（Sprite2D 和 ColorRect 皆支援 modulate）
	if _name_label:
		_name_label.modulate = Color(0.5, 0.5, 0.5)
	emit_signal("character_died")
	var gm = _get_gm()
	if gm:
		gm.check_defeat()

func get_hp_ratio() -> float:
	if max_hp <= 0:
		return 0.0
	return current_hp / max_hp

func get_cd_ratio() -> float:
	if is_ultimate_ready:
		return 1.0
	if ultimate_cd <= 0:
		return 1.0
	return 1.0 - (cd_timer / ultimate_cd)

func get_cd_remaining() -> float:
	return cd_timer

func _try_auto_attack() -> void:
	var gm = _get_gm()
	if gm == null:
		return
	if gm.get("is_paused") and gm.is_paused:
		return
	# 找最近的存活敵人
	var tree = get_tree()
	if tree == null:
		return
	var enemies = tree.get_nodes_in_group("enemies")
	var best_target: Node = null
	var best_dist: float = 9999.0
	for e in enemies:
		if e == null or not is_instance_valid(e):
			continue
		if e.get("is_dead") and e.is_dead:
			continue
		var d = global_position.distance_to(e.global_position)
		if d < best_dist:
			best_dist = d
			best_target = e

	if best_target == null:
		return

	# 計算最終攻擊力（含突擊手 buff 倍率）
	var total_atk = attack_power
	var atk_multiplier = gm.get_attack_multiplier() if gm.has_method("get_attack_multiplier") else 1.0
	total_atk *= atk_multiplier

	# 觸發射擊音效
	fire_shot()

	# 發射子彈
	_fire_player_bullet(best_target, total_atk)

func _pop_up_animation() -> void:
	# 射擊站起動畫：向上彈出 12px 再回原位
	var start_y: float = global_position.y
	var tween = create_tween()
	tween.tween_property(self, "global_position:y", start_y - 12.0, 0.08)
	tween.tween_interval(0.15)
	tween.tween_property(self, "global_position:y", start_y, 0.08)

func _fire_player_bullet(target_node: Node, dmg: float) -> void:
	var bullet_script = load("res://scripts/bullet.gd")
	if bullet_script == null:
		# 回退：直接扣血
		if target_node.has_method("take_damage"):
			target_node.take_damage(dmg)
		return

	var bullet = Node2D.new()
	bullet.set_script(bullet_script)
	var tree = get_tree()
	var main = tree.current_scene if tree else null
	if main:
		main.add_child(bullet)
		bullet.setup(global_position, target_node, dmg, "player")
	else:
		# 無法取得主場景，回退直接扣血
		if target_node.has_method("take_damage"):
			target_node.take_damage(dmg)
	# 射擊後站起動畫（不阻塞，Tween 非同步執行）
	_pop_up_animation()
