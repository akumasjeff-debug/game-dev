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

# 爆破手首次大招 CD 標記（Demo 教學特例：首次 CD 縮短為 20 秒）
var _first_ult_used: bool = false

# 視覺節點
var _body: ColorRect
var _name_label: Label
var _hp_bar: ProgressBar

func _get_gm() -> Node:
	return get_node_or_null("/root/GameManager")

func _ready() -> void:
	current_hp = max_hp
	_build_visual()

func _build_visual() -> void:
	# 身體（40x40 方塊）
	_body = ColorRect.new()
	_body.size = Vector2(40, 40)
	_body.position = Vector2(-20, -20)
	_body.color = body_color
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
			# 標記一個敵人，下一次攻擊秒殺（HP 歸零）
			# 標記邏輯：由 game_manager 持有 mark，攻擊時消耗
			# 此處先設 flag，enemy 或 decision 攻擊時會呼叫 consume_sniper_mark
			var enemies = get_tree().get_nodes_in_group("enemies") if get_tree() else []
			if enemies.size() > 0:
				gm.set_sniper_mark(enemies[0])
			else:
				# 沒有實體敵人時，設一個 pending 標記供下次決策傷害事件使用
				gm.set_sniper_mark(null)
				gm.sniper_mark_pending = true
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
			# 電磁脈衝：所有敵人攻擊失效 5 秒
			gm.activate_recon_blind()

func die() -> void:
	is_dead = true
	if _body:
		_body.color = Color(0.3, 0.3, 0.3)
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
