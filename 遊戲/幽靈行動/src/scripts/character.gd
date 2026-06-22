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
var in_cover: bool = false           # 是否在掩體後
var _crouch_texture: Texture2D = null  # 蹲伏精靈（預載）
var _stand_texture: Texture2D = null   # 站立精靈（預載）

# 自動攻擊計時器
var _auto_attack_timer: float = 0.0
var auto_attack_interval: float = 1.5  # 每 1.5 秒攻擊一次（狙擊手覆寫為 3.0）

# 醫療兵被動回血
var _heal_timer: float = 0.0
const HEAL_INTERVAL: float = 5.0
const HEAL_AMOUNT_RATIO: float = 0.08  # 8% 最大 HP

# 爆破手首次大招 CD 標記（Demo 教學特例：首次 CD 縮短為 20 秒）
var _first_ult_used: bool = false

# 角色顯示尺寸（放大人物模組，讓戰鬥區不空）
const DISPLAY_SIZE: float = 72.0

# 視覺節點
var _body: Node  # Sprite2D（有 SVG 素材時）或 ColorRect（回退色塊）
var _name_label: Label
var _hp_bar: ProgressBar

func _get_gm() -> Node:
	return get_node_or_null("/root/GameManager")

func _ready() -> void:
	current_hp = max_hp
	_build_visual()
	_apply_card_stats()
	# 狙擊手攻擊間隔較長
	if char_id == "sniper":
		auto_attack_interval = 3.0
	# 初始計時器錯開，避免所有角色同時發射
	_auto_attack_timer = randf_range(0.0, auto_attack_interval)
	# 部分角色初始大招 CD 偏移：避免開局 4 招齊放破壞節奏
	# 盾兵：15s 初始 CD（讓玩家在第一波壓力下決定何時開盾）
	# 爆破手：20s 初始 CD（最強 AoE 不應開局免費）
	match char_id:
		"shield":
			is_ultimate_ready = false
			cd_timer = 15.0
		"demo":
			is_ultimate_ready = false
			cd_timer = 20.0
	# 醫療兵首次回血隨機延遲 1~3 秒，避免開局立即觸發
	if char_id == "medic":
		_heal_timer = randf_range(1.0, 3.0)

func _build_visual() -> void:
	# 優先載入像素方塊 SVG sprite，無則退回職業色塊
	var sprite_path = "res://resources/art/sprites/" + char_id + "_sprite.svg"
	if char_id != "" and ResourceLoader.exists(sprite_path):
		var sprite = Sprite2D.new()
		sprite.texture = load(sprite_path)
		sprite.centered = true
		sprite.scale = Vector2(DISPLAY_SIZE / 64.0, DISPLAY_SIZE / 64.0)  # 放大人物模組
		_body = sprite
		# 預載站立與蹲伏貼圖
		_stand_texture = sprite.texture
		var crouch_path = "res://resources/art/sprites/crouch/crouch_" + char_id + ".svg"
		if ResourceLoader.exists(crouch_path):
			_crouch_texture = load(crouch_path)
	else:
		var cr = ColorRect.new()
		cr.size = Vector2(DISPLAY_SIZE, DISPLAY_SIZE)
		cr.position = Vector2(-DISPLAY_SIZE / 2.0, -DISPLAY_SIZE / 2.0)
		cr.color = body_color
		_body = cr
	add_child(_body)

	var half := DISPLAY_SIZE / 2.0

	# HP 條（角色頭頂上方，綠色醒目）
	_hp_bar = ProgressBar.new()
	_hp_bar.size = Vector2(64, 10)
	_hp_bar.position = Vector2(-32, -half - 16)
	_hp_bar.min_value = 0.0
	_hp_bar.max_value = max_hp
	_hp_bar.value = current_hp
	_hp_bar.show_percentage = false
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.10, 0.10, 0.12, 0.9)
	hp_bg.set_corner_radius_all(2)
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.30, 0.85, 0.35)
	hp_fill.set_corner_radius_all(2)
	_hp_bar.add_theme_stylebox_override("background", hp_bg)
	_hp_bar.add_theme_stylebox_override("fill", hp_fill)
	add_child(_hp_bar)

	# 名稱標籤（移到血條下方，小字，上方不再有任何 UI）
	_name_label = Label.new()
	_name_label.text = char_name
	_name_label.size = Vector2(80, 16)
	_name_label.position = Vector2(-40, half + 18)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.modulate = Color(0.85, 0.9, 1.0)
	if ResourceLoader.exists("res://resources/fonts/chinese_font.ttf"):
		_name_label.add_theme_font_override("font", load("res://resources/fonts/chinese_font.ttf"))
	add_child(_name_label)

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
	# 醫療兵被動回血
	if char_id == "medic":
		_heal_timer -= delta
		if _heal_timer <= 0.0:
			_heal_timer = HEAL_INTERVAL
			_do_passive_heal()

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_hp = max(0.0, current_hp - amount)
	if _hp_bar:
		_hp_bar.value = current_hp
	emit_signal("hp_changed", current_hp, max_hp)
	if current_hp > 0.0:
		if AudioManager:
			AudioManager.play_sfx("impact_hit")
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
	if AudioManager:
		AudioManager.play_sfx("ult_activate")
	# 各職業大招效果 — P1 實作
	var gm = _get_gm()
	if gm == null:
		return
	match char_id:
		"shield":
			# 全隊受傷害降低 50%，持續 5 秒
			gm.activate_shield_buff()
		"assault":
			# 鎖定當前 HP 最低的敵人，造成其當前 HP 80% 的傷害
			var a_enemies = get_tree().get_nodes_in_group("enemies") if get_tree() else []
			if a_enemies.size() > 0:
				var a_target = a_enemies[0]
				for e in a_enemies:
					if e and is_instance_valid(e) and e.get("current_hp") != null:
						if e.current_hp < a_target.current_hp:
							a_target = e
				if a_target and is_instance_valid(a_target) and a_target.has_method("take_damage"):
					var a_dmg = a_target.current_hp * 0.8
					a_target.take_damage(a_dmg)
					if OS.is_debug_build():
						print("[突擊手大招] 鎖定最弱敵人！造成 %.1f 傷害（當前 HP 的 80%%）" % a_dmg)
			else:
				if OS.is_debug_build():
					print("[突擊手大招] 無敵人目標")
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
						# fallback：造成目標 max_hp 60% 的傷害（720 傷害對 max_hp=1200 的普通兵）
						var sniper_dmg = target.max_hp * 0.6 if target.get("max_hp") != null else attack_power * 3.0
						target.take_damage(sniper_dmg)
						if OS.is_debug_build():
							print("[狙擊手大招] 精準鎖定！造成 %.1f 傷害（max_hp 60%%）" % sniper_dmg)
			else:
				# 沒有實體敵人時，設一個 pending 標記供下次決策傷害事件使用
				gm.set_sniper_mark(null)
				gm.sniper_mark_pending = true
				if OS.is_debug_build():
					print("[狙擊手大招] 精準鎖定標記！下次進入房間觸發。")
		"medic":
			# Lv.6+ 「戰場復甦」：優先復活最近倒下的隊員（本關限一次）
			# Lv.1-5 維持原效果：全隊立即恢復 30% 最大 HP
			if level >= 6 and not gm.medic_revive_used:
				var revive_target = gm.find_dead_member()
				if revive_target != null:
					gm.medic_revive_used = true
					revive_target.revive(0.5)
					if OS.is_debug_build():
						print("[醫療兵大招 Lv.6] 戰場復甦：復活 %s！" % revive_target.char_name)
					return
				# 沒有倒下隊員時降級為全隊回血
				if OS.is_debug_build():
					print("[醫療兵大招 Lv.6] 無倒下隊員，改為全隊回血")
			# 預設效果：全隊立即恢復 80 HP（固定值，不過強）
			for member in gm.squad_members:
				if member != null and is_instance_valid(member) and not member.is_dead:
					member.heal(80.0)
		"demo":
			# 房間內所有敵人立即扣 40% max_hp（AoE）
			var targets = get_tree().get_nodes_in_group("enemies") if get_tree() else []
			for enemy in targets:
				if enemy != null and is_instance_valid(enemy) and enemy.has_method("take_damage"):
					enemy.take_damage(enemy.max_hp * 0.4)
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

func revive(hp_ratio: float = 0.5) -> void:
	if not is_dead:
		return
	is_dead = false
	current_hp = max_hp * hp_ratio
	if _hp_bar:
		_hp_bar.max_value = max_hp
		_hp_bar.value = current_hp
	if _name_label:
		_name_label.modulate = Color.WHITE
	emit_signal("hp_changed", current_hp, max_hp)
	# 復活特效：閃白光
	if _body:
		_body.modulate = Color(1, 1, 1, 1)
		var tw = create_tween()
		tw.tween_property(_body, "modulate", Color(2, 2, 2, 1), 0.15)
		tw.tween_property(_body, "modulate", Color(1, 1, 1, 1), 0.3)
	if OS.is_debug_build():
		print("[復活] %s 以 %.0f%% HP 復活（HP: %.1f / %.1f）" % [char_name, hp_ratio * 100.0, current_hp, max_hp])

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

func _do_passive_heal() -> void:
	var gm = _get_gm()
	if gm == null:
		return
	# 找 HP 比例最低的存活隊員（含自己）
	var lowest_target: Node = null
	var lowest_ratio: float = 1.0
	for member in gm.squad_members:
		if member == null or not is_instance_valid(member):
			continue
		if member.is_dead:
			continue
		var ratio: float = member.current_hp / member.max_hp if member.max_hp > 0.0 else 1.0
		if ratio < lowest_ratio:
			lowest_ratio = ratio
			lowest_target = member

	# 全員滿血則跳過
	if lowest_target == null or lowest_ratio >= 0.99:
		return

	var heal_amount: float = lowest_target.max_hp * HEAL_AMOUNT_RATIO
	lowest_target.heal(heal_amount)  # 呼叫 heal() 同步更新 HP bar 並發射 hp_changed signal

	_show_heal_text(lowest_target, heal_amount)
	if OS.is_debug_build():
		print("[醫療兵被動] 對 %s 回血 %.1f（HP比例 %.0f%%→%.0f%%）" % [
			lowest_target.char_name,
			heal_amount,
			lowest_ratio * 100.0,
			(lowest_target.current_hp / lowest_target.max_hp) * 100.0
		])

func _show_heal_text(target: Node, amount: float) -> void:
	var lbl := Label.new()
	lbl.text = "+%dhp" % int(amount)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.modulate = Color(0.3, 1.0, 0.3)
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	tree.current_scene.add_child(lbl)
	# 飄字位置：目標全域座標轉換為主場景本地座標
	lbl.global_position = target.global_position + Vector2(-15.0, -40.0)
	var tw := get_tree().create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 30.0, 0.8)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw.tween_callback(lbl.queue_free)

func set_cover_mode(value: bool) -> void:
	in_cover = value
	if _body is Sprite2D:
		if value and _crouch_texture:
			_body.texture = _crouch_texture
			_body.scale = Vector2(DISPLAY_SIZE / 32.0, DISPLAY_SIZE / 32.0)
		elif _stand_texture:
			_body.texture = _stand_texture
			_body.scale = Vector2(DISPLAY_SIZE / 64.0, DISPLAY_SIZE / 64.0)

func _pop_up_animation() -> void:
	# 射擊站起動畫：向上彈出 12px 再回原位
	# 若在掩體中，暫時切換到站立精靈
	if in_cover and _body is Sprite2D and _stand_texture:
		_body.texture = _stand_texture
		_body.scale = Vector2(DISPLAY_SIZE / 64.0, DISPLAY_SIZE / 64.0)
	var start_y: float = global_position.y
	var tween = create_tween()
	tween.tween_property(self, "global_position:y", start_y - 12.0, 0.08)
	tween.tween_interval(0.15)
	tween.tween_property(self, "global_position:y", start_y, 0.08)
	# 動畫結束後回到蹲伏精靈
	tween.tween_callback(func():
		if in_cover and _body is Sprite2D and _crouch_texture:
			_body.texture = _crouch_texture
			_body.scale = Vector2(DISPLAY_SIZE / 32.0, DISPLAY_SIZE / 32.0)
	)

# 從卡牌資料套用數值（grade 倍率 + plus 強化）
func _apply_card_stats() -> void:
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr == null:
		return

	# 找出這個角色對應的 card_id
	var card_id = _find_my_card_id(save_mgr)
	if card_id.is_empty():
		return

	# 讀取 cards.json
	var card_info = _load_card_info(card_id)
	if card_info.is_empty():
		return

	# 套用基礎數值
	var base_hp = card_info.get("base_hp", max_hp)
	var base_atk = card_info.get("base_atk", attack_power)

	# 等級加成（每級 +5% 基礎值）
	var lv = save_mgr.get_card_level(card_id) if save_mgr.has_method("get_card_level") else 1
	var lv_mult = 1.0 + (lv - 1) * 0.05

	# 強化加成（每+1 提升 3%）
	var plus = save_mgr.get_card_plus(card_id) if save_mgr.has_method("get_card_plus") else 0
	var plus_mult = 1.0 + plus * 0.03

	max_hp = base_hp * lv_mult * plus_mult
	current_hp = max_hp
	attack_power = base_atk * lv_mult * plus_mult

	if _hp_bar:
		_hp_bar.max_value = max_hp
		_hp_bar.value = current_hp

func _find_my_card_id(save_mgr: Node) -> String:
	# 從 selected_squad 中找到對應此 char_id 的 card_id
	if save_mgr.get("selected_squad") == null:
		return ""
	var squad = save_mgr.selected_squad
	for card_id in squad:
		if card_id.begins_with(char_id + "_"):
			return card_id
	return ""

func _load_card_info(card_id: String) -> Dictionary:
	var path = "res://resources/data/cards.json"
	if not ResourceLoader.exists(path):
		return {}
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var raw = JSON.parse_string(f.get_as_text())
	f.close()
	if raw is Array:
		for c in raw:
			if c is Dictionary and c.get("id") == card_id:
				return c
	elif raw is Dictionary and raw.has("cards"):
		for c in raw["cards"]:
			if c is Dictionary and c.get("id") == card_id:
				return c
	return {}

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
