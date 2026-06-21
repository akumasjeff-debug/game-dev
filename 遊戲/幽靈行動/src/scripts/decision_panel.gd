extends Control

# 決策面板 UI 邏輯
# 此腳本掛在 CanvasLayer/Root (Control) 下

signal option_selected(option_id: String, decision_type: String)

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var desc_label: Label = $Panel/VBox/DescLabel
@onready var buttons_container: VBoxContainer = $Panel/VBox/ButtonsContainer

var current_decision: Dictionary = {}

func _ready() -> void:
	hide()
	GameManager.decision_triggered.connect(_on_decision_triggered)

func _on_decision_triggered(decision_data: Dictionary) -> void:
	current_decision = decision_data
	_populate(decision_data)
	show()
	AudioManager.play_sfx("decision_open")

func _populate(data: Dictionary) -> void:
	title_label.text = data.get("title", "決策")
	desc_label.text = data.get("description", "")

	# 清除舊按鈕
	for child in buttons_container.get_children():
		child.queue_free()

	# 建立選項按鈕
	var options: Array = data.get("options", [])
	for opt in options:
		var btn = _create_option_button(opt)
		buttons_container.add_child(btn)

func _create_option_button(opt: Dictionary) -> Button:
	var btn = Button.new()
	var opt_text = opt.get("text", "？")
	var opt_desc = opt.get("desc", "")
	btn.text = opt_text + "\n" + opt_desc
	btn.custom_minimum_size = Vector2(600, 90)
	btn.add_theme_font_size_override("font_size", 22)

	# 按鈕樣式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.25, 0.4, 0.95)
	style.border_color = Color(0.4, 0.7, 1.0, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.25, 0.4, 0.6, 0.95)
	hover_style.border_color = Color(0.6, 0.9, 1.0, 1.0)
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(8)
	hover_style.content_margin_left = 16
	hover_style.content_margin_right = 16
	hover_style.content_margin_top = 8
	hover_style.content_margin_bottom = 8
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
					# 直衝：全隊受到隨機傷害，套用 shield buff 減傷
					# Bug2 修正：sniper pending 消耗後對敵人造成 300% 攻擊傷害，全隊正常受傷
					if GameManager.sniper_mark_pending:
						GameManager.sniper_mark_pending = false
						# 計算狙擊手攻擊傷害（300% 攻擊力，對虛擬敵人）
						var sniper_node = _get_sniper_member()
						if sniper_node != null:
							var sniper_dmg = sniper_node.attack_power * 3.0 * GameManager.get_attack_multiplier()
							if OS.is_debug_build():
								print("[狙擊手大招] 精準鎖定！對敵人造成 %.1f 傷害，敵人被消滅！" % sniper_dmg)
						# 精準狙擊後，此次直衝敵人大幅削弱（進場傷害減半）
						for member in GameManager.squad_members:
							if member != null and is_instance_valid(member) and not member.is_dead:
								var dmg = randf_range(15.0, 35.0) * 0.5
								# Bug1 修正：乘以當前攻擊倍率
								dmg *= GameManager.get_attack_multiplier()
								GameManager.apply_damage_to_member(member, dmg)
					else:
						for member in GameManager.squad_members:
							if member != null and is_instance_valid(member) and not member.is_dead:
								var dmg = randf_range(15.0, 35.0)
								# Bug1 修正：乘以當前攻擊倍率（突擊手大招加成）
								dmg *= GameManager.get_attack_multiplier()
								# 若 demo 有 bomb pending，此次遭遇傷害減為 30%
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
					# 抽卡券（P2 實作，目前僅顯示）
					pass
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
