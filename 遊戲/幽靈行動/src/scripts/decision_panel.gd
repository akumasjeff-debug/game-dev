extends Control

# 決策面板 UI 邏輯
# 此腳本掛在 CanvasLayer/Root (Control) 下

signal option_selected(option_id: String, decision_type: String)

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var desc_label: Label = $Panel/VBox/DescLabel
@onready var buttons_container: HBoxContainer = $Panel/VBox/ButtonsContainer

var current_decision: Dictionary = {}

func _ready() -> void:
	hide()
	GameManager.decision_triggered.connect(_on_decision_triggered)

func _on_decision_triggered(decision_data: Dictionary) -> void:
	current_decision = decision_data
	_populate(decision_data)
	show()
	AudioManager.play_sfx("decision_open")

func _get_squad_rarity(char_id: String) -> int:
	# 取得小隊中指定職業的稀有度（不在小隊中則回傳 -1）
	for member in GameManager.squad_members:
		if member != null and is_instance_valid(member) and member.char_id == char_id and not member.is_dead:
			return SaveManager.character_rarity.get(char_id, 0)
	return -1

func _build_rarity_options(base_options: Array) -> Array:
	# 根據小隊陣容與稀有度動態加入額外選項
	var options = base_options.duplicate()

	# 盾兵 SR+ → 舉盾突入；SSR → 盾牆壓制
	var shield_rarity = _get_squad_rarity("shield")
	if shield_rarity >= 1:
		options.append({"id": "shield_rush", "text": "舉盾突入 [SR]", "desc": "盾兵先衝入，全隊進門期間受傷減半（盾兵承受雙倍傷害）"})
	if shield_rarity >= 2:
		options.append({"id": "shield_wall", "text": "盾牆壓制 [SSR]", "desc": "盾兵正面壓制，隊友從兩側清除 50% 敵人"})

	# 突擊手 SR+ → 爆發射擊；SSR → 側翼突破
	var assault_rarity = _get_squad_rarity("assault")
	if assault_rarity >= 1:
		options.append({"id": "assault_burst", "text": "爆發射擊 [SR]", "desc": "3 秒內全隊攻速 x2，快速清空小型房間"})
	if assault_rarity >= 2:
		options.append({"id": "flank", "text": "側翼突破 [SSR]", "desc": "從側面進入，敵人防禦值降低 50%"})

	# 狙擊手 SR+ → 目標標記
	var sniper_rarity = _get_squad_rarity("sniper")
	if sniper_rarity >= 1:
		options.append({"id": "mark_target", "text": "目標標記 [SR]", "desc": "標記一個目標，全隊對其傷害 +40%，持續 10 秒"})

	# 爆破手 SR+ → 定向炸藥
	var demo_rarity = _get_squad_rarity("demo")
	if demo_rarity >= 1:
		options.append({"id": "directed_bomb", "text": "定向炸藥 [SR]", "desc": "進門前引爆，房間敵人立即扣 60% HP"})

	# 醫療兵 SR+ → 急救注射
	var medic_rarity = _get_squad_rarity("medic")
	if medic_rarity >= 1:
		options.append({"id": "medic_inject", "text": "急救注射 [SR]", "desc": "立即對 HP 最低的隊員恢復 40% HP"})

	# 偵察手 SR+ → 煙幕掩護
	var recon_rarity = _get_squad_rarity("recon")
	if recon_rarity >= 1:
		options.append({"id": "smoke_cover", "text": "煙幕掩護 [SR]", "desc": "移動時不觸發敵人警戒，持續 10 秒（此場景無效時自動跳過）"})

	return options

func _is_char_in_squad(char_id: String) -> bool:
	for member in GameManager.squad_members:
		if member != null and is_instance_valid(member) and member.char_id == char_id and not member.is_dead:
			return true
	return false

func _populate(data: Dictionary) -> void:
	title_label.text = data.get("title", "決策")

	# 偵察手情報：若小隊有偵察手且為 room 類型，在描述中加入敵人數量情報
	var base_desc = data.get("description", "")
	if data.get("type", "") == "room" and _is_char_in_squad("recon"):
		var enemy_count = randi_range(1, 4)
		base_desc = "偵察手情報：房間內約有 " + str(enemy_count) + " 名敵人\n" + base_desc

	# 得失評估提示
	var risk_hint = current_decision.get("risk_hint", "")
	if risk_hint == "":
		# 自動根據類型產生
		match data.get("type", ""):
			"room":
				risk_hint = "★ 清除房間獲得戰場優勢，注意隊員 HP 消耗"
			"supply":
				risk_hint = "★ 補給機會，優先補充低 HP 隊員"
			_:
				risk_hint = ""
	if risk_hint != "":
		desc_label.text = base_desc + "\n\n⚠ " + risk_hint
	else:
		desc_label.text = base_desc

	# 清除舊按鈕
	for child in buttons_container.get_children():
		child.queue_free()

	# 建立選項按鈕（room 類型動態加入稀有度選項）
	var options: Array = data.get("options", [])
	if data.get("type", "") == "room":
		options = _build_rarity_options(options)
	for opt in options:
		var btn = _create_option_button(opt)
		buttons_container.add_child(btn)

func _create_option_button(opt: Dictionary) -> Button:
	var btn = Button.new()
	var opt_text = opt.get("text", "？")
	var opt_desc = opt.get("desc", "")
	btn.text = opt_text + "\n" + opt_desc
	btn.custom_minimum_size = Vector2(280, 120)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 18)

	# 按鈕樣式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.20, 0.35, 0.95)
	style.border_color = Color(0.4, 0.7, 1.0, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.22, 0.35, 0.55, 0.95)
	hover_style.border_color = Color(0.6, 0.9, 1.0, 1.0)
	hover_style.set_border_width_all(3)
	hover_style.set_corner_radius_all(8)
	hover_style.content_margin_left = 12
	hover_style.content_margin_right = 12
	hover_style.content_margin_top = 10
	hover_style.content_margin_bottom = 10
	btn.add_theme_stylebox_override("hover", hover_style)

	var opt_id = opt.get("id", "")
	btn.pressed.connect(_on_option_pressed.bind(opt_id))
	return btn

func _on_option_pressed(opt_id: String) -> void:
	AudioManager.play_sfx("decision_confirm")
	var decision_type = current_decision.get("type", "")
	_apply_decision_effect(opt_id, decision_type)
	emit_signal("option_selected", opt_id, decision_type)
	hide()
	GameManager.resume_squad()

func _apply_decision_effect(opt_id: String, decision_type: String) -> void:
	match decision_type:
		"room":
			match opt_id:
				"charge":
					# 直衝：全隊受到隨機進場傷害
					# 突擊手大招 assault_buff_active：攻擊倍率讓玩家隊伍輸出更強，進場傷害同步降低（壓制優勢）
					var atk_mult = GameManager.get_attack_multiplier()
					# 突擊手大招激活時，進場傷害因壓制優勢降低（反比：攻擊更強，受傷更少）
					var incoming_reduction = 1.0 / atk_mult  # assault buff(x1.6) → 進場傷害 x0.625

					if GameManager.sniper_mark_pending:
						GameManager.sniper_mark_pending = false
						# 狙擊手大招 pending：精準狙擊消滅前排，進場傷害再減半
						var sniper_node = _get_sniper_member()
						if sniper_node != null:
							var sniper_dmg = sniper_node.attack_power * 3.0
							if OS.is_debug_build():
								print("[狙擊手大招] 精準鎖定！對敵人造成 %.1f 傷害，前排消滅！" % sniper_dmg)
						for member in GameManager.squad_members:
							if member != null and is_instance_valid(member) and not member.is_dead:
								var dmg = randf_range(15.0, 35.0) * 0.5 * incoming_reduction
								GameManager.apply_damage_to_member(member, dmg)
					else:
						for member in GameManager.squad_members:
							if member != null and is_instance_valid(member) and not member.is_dead:
								var dmg = randf_range(15.0, 35.0) * incoming_reduction
								# 爆破手炸彈 pending：進場傷害再降至 30%
								if GameManager.demo_bomb_pending:
									dmg *= 0.3
								GameManager.apply_damage_to_member(member, dmg)
					GameManager.demo_bomb_pending = false
				"stealth":
					# 靜悄悄：無傷害
					pass
				"bomb":
					# 炸彈：消耗爆破手大招 CD，全隊無傷害
					for member in GameManager.squad_members:
						if member != null and is_instance_valid(member) and member.char_id == "demo":
							if member.is_ultimate_ready:
								member.is_ultimate_ready = false
								member.cd_timer = member.ultimate_cd
				# ── 稀有度解鎖選項效果 ──
				"shield_wall":
					# 盾牆壓制：激活護盾 buff + 對所有敵人扣 50% 當前 HP
					GameManager.activate_shield_buff()
					var enemies_sw = get_tree().get_nodes_in_group("enemies")
					for enemy in enemies_sw:
						if enemy and is_instance_valid(enemy) and enemy.has_method("take_damage"):
							enemy.take_damage(enemy.current_hp * 0.5)
				"assault_burst":
					# 爆發射擊：攻擊 buff
					GameManager.activate_assault_buff()
				"flank":
					# 側翼突破：對所有敵人造成 30% 最大 HP 傷害
					var enemies_fl = get_tree().get_nodes_in_group("enemies")
					for enemy in enemies_fl:
						if enemy and is_instance_valid(enemy) and enemy.has_method("take_damage"):
							enemy.take_damage(enemy.max_hp * 0.3)
				"mark_target":
					# 目標標記：攻擊 buff（模擬）
					GameManager.activate_assault_buff()
				"directed_bomb":
					# 定向炸藥：對所有敵人扣 60% 當前 HP
					var enemies_db = get_tree().get_nodes_in_group("enemies")
					for enemy in enemies_db:
						if enemy and is_instance_valid(enemy) and enemy.has_method("take_damage"):
							enemy.take_damage(enemy.current_hp * 0.6)
				"medic_inject":
					# 急救注射：對 HP 最低的隊員恢復 40% 最大 HP
					var target_mi = null
					var lowest_ratio_mi = 1.0
					for member in GameManager.squad_members:
						if member != null and is_instance_valid(member) and not member.is_dead:
							var ratio = member.current_hp / member.max_hp
							if ratio < lowest_ratio_mi:
								lowest_ratio_mi = ratio
								target_mi = member
					if target_mi:
						target_mi.heal(target_mi.max_hp * 0.4)
				"smoke_cover":
					# 煙幕掩護：偵察手盲眼效果
					GameManager.activate_recon_blind()
		"supply":
			match opt_id:
				"heal":
					# 補血
					for member in GameManager.squad_members:
						if member != null and is_instance_valid(member) and not member.is_dead:
							member.heal(member.max_hp * 0.4)
				"ammo":
					# 爆破手 CD 重置
					for member in GameManager.squad_members:
						if member != null and is_instance_valid(member) and member.char_id == "demo":
							member.is_ultimate_ready = true
							member.cd_timer = 0.0
				"card":
					# 給玩家 1 張藍色票
					SaveManager.blue_tickets += 1
					SaveManager.save_game()
		"boss":
			match opt_id:
				"boss_charge":
					# 直衝 Boss：無特殊效果，直接進入 Boss 戰
					if OS.is_debug_build():
						print("[Boss決策] 直衝 Boss！全隊承受第一波攻擊...")
				"boss_flank":
					# 側翼迂迴：激活護盾 buff，進場受傷 -30%（內含在 shield buff 50% 減傷中）
					GameManager.activate_shield_buff()
					if OS.is_debug_build():
						print("[Boss決策] 側翼迂迴！護盾激活，進場傷害降低。")
				"boss_bait":
					# 引蛇出洞：消滅 Boss 房部分護衛（AOE 傷害效果，使用爆破手大招風格）
					var enemies_bait = get_tree().get_nodes_in_group("enemies")
					var killed = 0
					for enemy in enemies_bait:
						if enemy and is_instance_valid(enemy) and enemy.has_method("take_damage"):
							if killed < 2:
								enemy.take_damage(enemy.max_hp + 9999)  # 瞬殺 2 名護衛
								killed += 1
					if OS.is_debug_build():
						print("[Boss決策] 引蛇出洞！消滅 %d 名護衛。" % killed)
		"fork":
			_apply_fork_effect(opt_id)
		"shield_entry":
			_apply_shield_entry_effect(opt_id)

func _apply_fork_effect(opt_id: String) -> void:
	var main_scene = get_tree().current_scene if get_tree() else null
	if main_scene == null or not main_scene.has_method("switch_path"):
		return
	main_scene.switch_path(opt_id)

func _apply_shield_entry_effect(opt_id: String) -> void:
	match opt_id:
		"shield_rush":
			# 舉盾突入：進門期間全隊受傷減半（激活 shield buff 3 秒）
			GameManager.activate_shield_buff()
			# 直接進入並承受傷害（減半後）
			for member in GameManager.squad_members:
				if member != null and is_instance_valid(member) and not member.is_dead:
					var dmg = randf_range(10.0, 20.0)
					GameManager.apply_damage_to_member(member, dmg)
		"stealth":
			pass
		"bomb":
			for member in GameManager.squad_members:
				if member != null and is_instance_valid(member) and member.char_id == "demo":
					if member.is_ultimate_ready:
						member.is_ultimate_ready = false
						member.cd_timer = member.ultimate_cd

func _get_sniper_member() -> Node:
	for member in GameManager.squad_members:
		if member != null and is_instance_valid(member) and member.char_id == "sniper" and not member.is_dead:
			return member
	return null
