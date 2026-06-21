extends Node2D

# 房間戰鬥管理器
# 一個房間包含 N 個敵人，進入後雙方自動互毆
# 所有敵人死亡 → room_cleared → 小隊繼續推進
# 所有隊員死亡 → game_over（由 character.gd die() → GameManager.check_defeat() 觸發）

signal room_cleared()

const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")

@export var room_label: String = "房間"

# 敵人設定陣列，每個 dict 包含 type（0=普通, 1=精英, 2=Boss）與 position_offset
# 範例: [{"type":0,"offset":Vector2(-60,0)}, {"type":1,"offset":Vector2(60,0)}]
@export var enemy_configs: Array = []

var enemies: Array = []
var is_active: bool = false
var is_cleared: bool = false

func _ready() -> void:
	pass

# 由外部（decision_panel 或 decision_trigger）呼叫，傳入進入方式
# entry_mode: "charge" | "stealth" | "bomb" | "shield_rush"
func start_battle(entry_mode: String = "charge") -> void:
	if is_active or is_cleared:
		return
	is_active = true
	_spawn_enemies()
	_apply_entry_effect(entry_mode)
	_setup_squad_auto_attack()

func _spawn_enemies() -> void:
	if enemy_configs.is_empty():
		# 預設：3 個普通兵
		enemy_configs = [
			{"type": 0, "offset": Vector2(-80, 0)},
			{"type": 0, "offset": Vector2(0,   0)},
			{"type": 0, "offset": Vector2(80,  0)},
		]

	for cfg in enemy_configs:
		var e = ENEMY_SCRIPT.new()
		e.enemy_type = cfg.get("type", 0)
		e.room_ref = self
		e.position = position + cfg.get("offset", Vector2.ZERO)
		e.add_to_group("enemies")
		get_parent().add_child(e)
		enemies.append(e)
		e.enemy_died.connect(_on_enemy_died)

func _apply_entry_effect(entry_mode: String) -> void:
	var gm = get_node_or_null("/root/GameManager")
	match entry_mode:
		"charge":
			# 直衝：進場傷害由 decision_panel 的 charge 分支已處理，room.gd 不重複造成傷害
			# 直衝時敵人全速進攻（無特殊效果，正常戰鬥）
			pass
		"stealth":
			# 靜悄悄：全隊無進場傷害，且第一個普通兵直接秒殺（靜默接觸）
			for e in enemies:
				if is_instance_valid(e) and e.enemy_type == 0:
					e.take_damage(e.max_hp)
					break
		"bomb":
			# 炸彈：所有敵人扣 70% HP，消耗爆破手大招
			if gm:
				for member in gm.squad_members:
					if member != null and is_instance_valid(member) and member.char_id == "demo":
						if member.is_ultimate_ready:
							member.is_ultimate_ready = false
							member.cd_timer = member.ultimate_cd
			for e in enemies:
				if is_instance_valid(e):
					e.take_damage(e.max_hp * 0.7)
		"shield_rush":
			# 舉盾突入：進場傷害由 decision_panel 的 shield_entry 分支已處理，room.gd 激活 shield buff
			if gm:
				gm.activate_shield_buff()

func _setup_squad_auto_attack() -> void:
	# 讓每個存活的隊員自動攻擊敵人
	# 使用 Timer 節點驅動攻擊循環（每 1.5 秒全員攻擊一次）
	var timer = Timer.new()
	timer.wait_time = 1.5
	timer.autostart = true
	timer.name = "SquadAttackTimer"
	add_child(timer)
	timer.timeout.connect(_squad_attack_round)

func _squad_attack_round() -> void:
	if is_cleared or not is_active:
		return
	var gm = get_node_or_null("/root/GameManager")
	if gm == null:
		return

	# 取得存活的敵人列表
	var alive_enemies = _get_alive_enemies()
	if alive_enemies.is_empty():
		return

	# 每個存活隊員攻擊一個敵人（優先打血量最低的）
	var target = _pick_weakest_enemy(alive_enemies)
	if target == null:
		return

	var attack_mult = gm.get_attack_multiplier()

	for member in gm.squad_members:
		if member == null or not is_instance_valid(member) or member.is_dead:
			continue
		var dmg = member.attack_power * attack_mult
		# 狙擊手標記：若有標記且目標是此敵人，秒殺
		if gm.sniper_marked_target != null and gm.sniper_marked_target == target:
			dmg = target.max_hp * 2.0
			gm.consume_sniper_mark()
		target.take_damage(dmg)
		# 播放射擊音效
		member.fire_shot()
		# 狙擊手鎖定秒殺後換目標
		if not is_instance_valid(target) or target.is_dead:
			target = _pick_weakest_enemy(_get_alive_enemies())
			if target == null:
				break

func _get_alive_enemies() -> Array:
	var alive = []
	for e in enemies:
		if e != null and is_instance_valid(e) and not e.is_dead:
			alive.append(e)
	return alive

func _pick_weakest_enemy(alive_list: Array) -> Node:
	if alive_list.is_empty():
		return null
	var weakest = alive_list[0]
	for e in alive_list:
		if e.get_hp_ratio() < weakest.get_hp_ratio():
			weakest = e
	return weakest

func _on_enemy_died(_enemy: Node) -> void:
	# 稍後檢查（等 queue_free 前的短暫延遲）
	var t = get_tree().create_timer(0.4)
	t.timeout.connect(_check_cleared)

func _check_cleared() -> void:
	if is_cleared:
		return
	# 確認所有敵人都已死亡
	for e in enemies:
		if e != null and is_instance_valid(e) and not e.is_dead:
			return
	# 所有敵人死亡
	is_cleared = true
	is_active = false
	var timer_node = get_node_or_null("SquadAttackTimer")
	if timer_node:
		timer_node.queue_free()
	emit_signal("room_cleared")
	# 通知 GameManager 繼續推進
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.resume_squad()

func get_alive_enemy_count() -> int:
	return _get_alive_enemies().size()
