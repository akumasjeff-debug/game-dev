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
var _body_home: Vector2 = Vector2.ZERO  # 身體原始 position（Sprite2D=(0,0)、ColorRect=(-36,-36)），供動畫復位

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
	_body_home = _body.position  # 記錄原始位置，供受擊抖動 / 倒下 / 復活復位使用

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
	_tween_hp_bar(current_hp)
	emit_signal("hp_changed", current_hp, max_hp)
	if current_hp > 0.0:
		if AudioManager:
			AudioManager.play_sfx("impact_hit")
		# 受擊回饋：閃紅 + 抖動 + 紅色傷害飄字
		_hit_flash()
		_hit_shake()
		_show_damage_text(amount)
	if current_hp <= 0.0:
		die()

func heal(amount: float) -> void:
	if is_dead:
		return
	current_hp = min(max_hp, current_hp + amount)
	_tween_hp_bar(current_hp)
	emit_signal("hp_changed", current_hp, max_hp)

# 血條補間：數值平滑過渡而非瞬間跳變，受傷時更有「血量被削」的感受
func _tween_hp_bar(to_value: float) -> void:
	if _hp_bar == null or not is_instance_valid(_hp_bar):
		return
	_hp_bar.max_value = max_hp
	var tw = create_tween()
	tw.tween_property(_hp_bar, "value", to_value, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# 受擊閃紅：身體短暫染紅再恢復
func _hit_flash() -> void:
	if _body == null or not is_instance_valid(_body):
		return
	_body.modulate = Color(1.6, 0.4, 0.4, 1.0)
	var tw = create_tween()
	tw.tween_property(_body, "modulate", Color(1, 1, 1, 1), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# 受擊抖動：身體左右快速顫動數次後歸位（位移作用在 _body，不動 self 座標避免干擾隊形）
func _hit_shake() -> void:
	if _body == null or not is_instance_valid(_body):
		return
	# 以原始位置為基準（避免連續受擊時殘餘位移累積導致身體漂移）
	var base := _body_home
	var tw = create_tween()
	tw.tween_property(_body, "position", base + Vector2(5, 0), 0.03)
	tw.tween_property(_body, "position", base + Vector2(-4, 0), 0.03)
	tw.tween_property(_body, "position", base + Vector2(3, 0), 0.03)
	tw.tween_property(_body, "position", base, 0.04)

# 受傷紅色飄字（與醫療回血綠字風格統一：同樣往上飄並淡出）
func _show_damage_text(amount: float) -> void:
	if amount <= 0.0:
		return
	var lbl := Label.new()
	lbl.text = "-%d" % int(round(amount))
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.modulate = Color(1.0, 0.35, 0.3)
	lbl.add_theme_color_override("font_outline_color", Color(0.2, 0.0, 0.0, 0.9))
	lbl.add_theme_constant_override("outline_size", 4)
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	tree.current_scene.add_child(lbl)
	lbl.global_position = global_position + Vector2(randf_range(-6.0, 6.0), -46.0)
	var tw := tree.create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 36.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw.tween_callback(lbl.queue_free)

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
	# 角色身上爆發職業色光環 + 粒子（搭配橫幅）
	_spawn_ultimate_aura()
	# 畫面中央顯示技能敘述 + 持續時間
	_show_ultimate_banner()
	# 套用各職業大招的實際遊戲效果
	_apply_ultimate_gameplay()

# 大招施放特效：角色身上爆發職業色光環 + 向外噴射的職業色粒子 + 短暫放大
func _spawn_ultimate_aura() -> void:
	var aura_col := body_color
	# body_color 預設可能是白色，依職業給定鮮明色（與 sprite 配色一致）
	match char_id:
		"shield": aura_col = Color(0.27, 0.53, 1.0)
		"medic": aura_col = Color(0.27, 0.85, 0.27)
		"assault": aura_col = Color(1.0, 0.55, 0.1)
		"sniper": aura_col = Color(0.67, 0.27, 1.0)
		"demo": aura_col = Color(1.0, 0.2, 0.2)
		"recon": aura_col = Color(0.2, 0.85, 0.85)

	# 擴張光環（由小到大環狀光圈淡出）
	var ring = ColorRect.new()
	ring.size = Vector2(DISPLAY_SIZE * 1.6, DISPLAY_SIZE * 1.6)
	ring.color = Color(aura_col.r, aura_col.g, aura_col.b, 0.45)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.z_index = -1  # 墊在角色後方，不遮住角色本體
	ring.pivot_offset = ring.size / 2.0
	add_child(ring)
	ring.position = -ring.size / 2.0
	ring.scale = Vector2(0.3, 0.3)
	var rt = create_tween()
	rt.tween_property(ring, "scale", Vector2(1.6, 1.6), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	rt.parallel().tween_property(ring, "modulate:a", 0.0, 0.55)
	rt.tween_callback(ring.queue_free)

	# 角色本體短暫染上職業色光輝後恢復（強調「我發動了」）
	if _body and is_instance_valid(_body):
		var bt = create_tween()
		bt.tween_property(_body, "modulate", Color(aura_col.r + 0.6, aura_col.g + 0.6, aura_col.b + 0.6, 1.0), 0.12)
		bt.tween_property(_body, "modulate", Color(1, 1, 1, 1), 0.35)

	# 向外噴射的職業色粒子（10 顆，效能可控）
	var count = 10
	for i in range(count):
		var p = ColorRect.new()
		p.size = Vector2(7, 7)
		p.color = aura_col
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.z_index = 2
		add_child(p)
		p.position = -p.size / 2.0
		var ang = TAU * float(i) / float(count) + randf_range(-0.2, 0.2)
		var dist = randf_range(50.0, 90.0)
		var dest = Vector2(cos(ang), sin(ang)) * dist - p.size / 2.0
		var pt = create_tween()
		pt.tween_property(p, "position", dest, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		pt.parallel().tween_property(p, "modulate:a", 0.0, 0.5)
		pt.tween_callback(p.queue_free)

# 各職業大招效果 — P1 實作（與視覺特效分離，職責清晰）
func _apply_ultimate_gameplay() -> void:
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
	# 死亡表現：灰化 + 倒下（傾倒）+ 下沉淡出
	if _body and is_instance_valid(_body):
		# pivot 設在底部中心，傾倒看起來像從腳下倒下（Sprite2D 用 offset 不便，這裡用 ColorRect/Sprite 通用的 position 偏移近似）
		var dt = create_tween()
		# 先灰化
		dt.tween_property(_body, "modulate", Color(0.35, 0.35, 0.35, 1.0), 0.18)
		# 傾倒：旋轉約 80 度 + 略往下沉
		dt.parallel().tween_property(_body, "rotation_degrees", 80.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		dt.parallel().tween_property(_body, "position", _body.position + Vector2(8.0, 14.0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		# 倒地後再淡暗一點（保留灰色殘影，不完全消失，玩家仍看得到倒下的隊員）
		dt.tween_property(_body, "modulate", Color(0.30, 0.30, 0.30, 0.7), 0.25)
	elif _body:
		_body.modulate = Color(0.35, 0.35, 0.35)
	# 隱藏血條（已陣亡不需顯示）
	if _hp_bar and is_instance_valid(_hp_bar):
		var ht = create_tween()
		ht.tween_property(_hp_bar, "modulate:a", 0.0, 0.25)
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
		_hp_bar.modulate.a = 1.0  # 恢復死亡時淡出的血條
	if _name_label:
		_name_label.modulate = Color.WHITE
	emit_signal("hp_changed", current_hp, max_hp)
	# 復活特效：站起（復位 die() 造成的傾倒/下沉）+ 閃白光
	if _body and is_instance_valid(_body):
		_body.modulate = Color(1, 1, 1, 1)
		var up = create_tween()
		# 站回原位（rotation/position 由 die() 改動，這裡歸零）
		up.tween_property(_body, "rotation_degrees", 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		up.parallel().tween_property(_body, "position", _body_home, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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
	# 隨機射擊一名存活敵人（不再固定鎖定最近）
	var enemies = tree.get_nodes_in_group("enemies")
	var alive_enemies: Array = []
	for e in enemies:
		if e == null or not is_instance_valid(e):
			continue
		if e.get("is_dead") and e.is_dead:
			continue
		alive_enemies.append(e)

	if alive_enemies.is_empty():
		return
	var best_target: Node = alive_enemies[randi() % alive_enemies.size()]

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
	lbl.text = "+%d" % int(amount)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.modulate = Color(0.3, 1.0, 0.35)
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.2, 0.0, 0.9))
	lbl.add_theme_constant_override("outline_size", 4)
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	tree.current_scene.add_child(lbl)
	# 飄字位置：目標全域座標轉換為主場景本地座標
	lbl.global_position = target.global_position + Vector2(-15.0, -46.0)
	var tw := get_tree().create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 36.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.7)
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
	# 俐落彈起：快速上彈（QUAD ease-out），短停頓，回落帶 BACK 緩衝更有彈性
	tween.tween_property(self, "global_position:y", start_y - 12.0, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.12)
	tween.tween_property(self, "global_position:y", start_y, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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

# 大招敘述 + 持續時間
func _get_ultimate_info() -> Dictionary:
	match char_id:
		"shield":
			return {"desc": "全隊受到傷害 -50%", "duration": 5.0}
		"assault":
			return {"desc": "鎖定最弱敵人，造成 80% 當前 HP 傷害", "duration": 0.0}
		"sniper":
			return {"desc": "精準狙殺，對最弱目標致命一擊", "duration": 0.0}
		"medic":
			if level >= 6:
				return {"desc": "戰場復甦：復活倒下隊員 / 全隊回血", "duration": 0.0}
			return {"desc": "全隊立即回復 HP", "duration": 0.0}
		"demo":
			return {"desc": "全場敵人 -40% 最大 HP（AoE）", "duration": 0.0}
		"recon":
			return {"desc": "煙霧封鎖，敵人攻擊全失效", "duration": 5.0}
		_:
			return {"desc": "", "duration": 0.0}

func _show_ultimate_banner() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var info := _get_ultimate_info()
	var desc: String = info["desc"]
	var dur: float = info["duration"]

	var cl := CanvasLayer.new()
	cl.layer = 15
	tree.current_scene.add_child(cl)

	var panel := ColorRect.new()
	panel.color    = Color(0.05, 0.07, 0.12, 0.82)
	panel.size     = Vector2(760, 132)
	panel.position = Vector2(160, 540)
	cl.add_child(panel)

	# 左側職業色條
	var color_bar := ColorRect.new()
	color_bar.color    = body_color
	color_bar.size     = Vector2(10, 132)
	color_bar.position = Vector2(160, 540)
	cl.add_child(color_bar)

	var has_font := ResourceLoader.exists("res://resources/fonts/chinese_font.ttf")
	var font: Font = load("res://resources/fonts/chinese_font.ttf") if has_font else null

	var title := Label.new()
	title.text     = "%s 發動！%s" % [char_name, ultimate_name]
	title.position = Vector2(192, 556)
	title.size     = Vector2(700, 44)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	if font: title.add_theme_font_override("font", font)
	cl.add_child(title)

	var sub := Label.new()
	sub.text     = desc
	sub.position = Vector2(192, 604)
	sub.size     = Vector2(700, 34)
	sub.add_theme_font_size_override("font_size", 26)
	sub.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	if font: sub.add_theme_font_override("font", font)
	cl.add_child(sub)

	var cd := Label.new()
	cd.position = Vector2(192, 638)
	cd.size     = Vector2(700, 30)
	cd.add_theme_font_size_override("font_size", 24)
	cd.add_theme_color_override("font_color", Color(0.45, 1.0, 0.5))
	if font: cd.add_theme_font_override("font", font)
	cl.add_child(cd)

	if dur > 0.0:
		cd.text = "持續 %.1f 秒" % dur
		var cdt := tree.create_tween()
		cdt.tween_method(_update_cd_label.bind(cd), dur, 0.0, dur)
		cdt.tween_callback(cl.queue_free)
	else:
		cd.text = "立即生效"
		var t := tree.create_timer(2.2)
		t.timeout.connect(cl.queue_free)

func _update_cd_label(value: float, label: Label) -> void:
	if is_instance_valid(label):
		label.text = "持續 %.1f 秒" % value

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
	# 開火回饋：槍口閃光 + 後座/站起動畫（皆非阻塞）
	var fire_dir := Vector2.UP
	if target_node and is_instance_valid(target_node):
		fire_dir = (target_node.global_position - global_position).normalized()
	_spawn_muzzle_flash(fire_dir)
	_recoil_animation(fire_dir)
	_pop_up_animation()

# 槍口閃光：朝射擊方向在角色前方爆出一團短暫亮光（自行消失，不影響邏輯）
func _spawn_muzzle_flash(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	# 槍口位置：角色身體外緣，朝目標方向偏移
	var origin: Vector2 = global_position + dir * (DISPLAY_SIZE * 0.45)
	# 核心亮光（白黃，大塊）
	var flash = ColorRect.new()
	flash.size = Vector2(26, 26)
	var flash_col := Color(1.0, 0.95, 0.55) if char_id != "demo" else Color(1.0, 0.7, 0.25)
	flash.color = flash_col
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 10
	flash.pivot_offset = flash.size / 2.0
	add_child(flash)
	# 轉成本地座標（add_child 到 self，position 為相對 self）
	flash.position = to_local(origin) - flash.size / 2.0
	flash.scale = Vector2(0.5, 0.5)
	var tw = create_tween()
	tw.tween_property(flash, "scale", Vector2(1.3, 1.3), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.08)
	tw.tween_callback(flash.queue_free)
	# 外圈小火星（3 顆，朝射擊方向小幅噴散）
	for i in range(3):
		var sp = ColorRect.new()
		sp.size = Vector2(4, 4)
		sp.color = flash_col
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sp.z_index = 10
		add_child(sp)
		sp.position = to_local(origin) - sp.size / 2.0
		var spread = dir.rotated(randf_range(-0.5, 0.5))
		var dest = to_local(origin + spread * randf_range(16.0, 28.0)) - sp.size / 2.0
		var st = create_tween()
		st.tween_property(sp, "position", dest, 0.1).set_ease(Tween.EASE_OUT)
		st.parallel().tween_property(sp, "modulate:a", 0.0, 0.1)
		st.tween_callback(sp.queue_free)

# 後座動畫：身體朝射擊反方向頓挫一下再回位（短促，強調「開火」力道）
func _recoil_animation(dir: Vector2) -> void:
	if _body == null or not is_instance_valid(_body):
		return
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	# 沿射擊反方向位移（後座），幅度小而快
	var kick: Vector2 = -dir * 6.0
	var base := _body_home
	var tw = create_tween()
	tw.tween_property(_body, "position", base + kick, 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_body, "position", base, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
