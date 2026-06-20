extends CanvasLayer

@onready var hp_bar: ProgressBar = $HUDContainer/HPSection/HPBar
@onready var hp_label: Label = $HUDContainer/HPSection/HPLabel
@onready var ammo_bar: ProgressBar = $HUDContainer/AmmoSection/AmmoBar
@onready var ammo_label: Label = $HUDContainer/AmmoSection/AmmoLabel
@onready var reload_label: Label = $HUDContainer/ReloadLabel
@onready var safe_indicator: ColorRect = $SafeIndicator
@onready var safe_label: Label = $SafeIndicator/SafeLabel
@onready var safe_hint: Label = $SafeIndicator/SafeHint
@onready var auto_aim_label: Label = $AutoAimLabel
@onready var death_panel: Control = $DeathPanel
@onready var victory_panel: Control = $VictoryPanel
@onready var failed_panel: Control = $FailedPanel

var player: Node2D = null
var _mission_label: Label

func _ready():
	add_to_group("hud")
	# 連接玩家信號，快取 player 參考
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		player.hp_changed.connect(_on_hp_changed)
		player.ammo_changed.connect(_on_ammo_changed)
		player.reload_started.connect(_on_reload_started)
		player.reload_finished.connect(_on_reload_finished)
		player.died.connect(_on_player_died)
		player.auto_aim_changed.connect(_on_auto_aim_changed)

	# 初始狀態
	if reload_label:
		reload_label.visible = false
	if death_panel:
		death_panel.visible = false
	if victory_panel:
		victory_panel.visible = false
	if failed_panel:
		failed_panel.visible = false
	if auto_aim_label:
		auto_aim_label.visible = false
	_update_safe_indicator(false)

	# 動態建立任務文字標籤
	_mission_label = Label.new()
	_mission_label.text = ""
	_mission_label.position = Vector2(10, 170)
	_mission_label.modulate = Color(1.0, 0.85, 0.1, 0.9)
	_mission_label.add_theme_font_size_override("font_size", 18)
	add_child(_mission_label)

func _process(_delta):
	# 同步安全模式狀態（直接使用快取的 player）
	if player and is_instance_valid(player):
		if "safe_mode" in player:
			_update_safe_indicator(player.safe_mode)

func _input(event):
	if death_panel and death_panel.visible and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
	if victory_panel and victory_panel.visible and event.is_action_pressed("restart"):
		_go_to_next_level()
	if failed_panel and failed_panel.visible and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()

func _go_to_next_level():
	# 根據當前場景決定下一關
	var current = get_tree().current_scene.scene_file_path
	var next_map = {
		"res://scenes/Main.tscn":   "res://scenes/Level2.tscn",
		"res://scenes/Level2.tscn": "res://scenes/Level3.tscn",
		"res://scenes/Level3.tscn": "res://scenes/Level4.tscn",
		"res://scenes/Level4.tscn": "res://scenes/Level5.tscn",
	}
	if current in next_map:
		get_tree().change_scene_to_file(next_map[current])
	else:
		# Level5 完成 → 回到指揮中心（HQ）
		get_tree().change_scene_to_file("res://scenes/Base.tscn")

func _on_hp_changed(current_hp: int, max_hp: int):
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
	if hp_label:
		hp_label.text = "HP  %d / %d" % [current_hp, max_hp]

func _on_ammo_changed(current_ammo: int, max_ammo: int):
	if ammo_bar:
		ammo_bar.max_value = max_ammo
		ammo_bar.value = current_ammo
	if ammo_label:
		ammo_label.text = "彈藥  %d / %d" % [current_ammo, max_ammo]

func _on_reload_started():
	if reload_label:
		reload_label.visible = true
	if ammo_label:
		ammo_label.text = "RELOADING..."

func _on_reload_finished():
	if reload_label:
		reload_label.visible = false
	# 還原彈藥文字（修正換彈文字殘留問題）
	if ammo_label and player:
		ammo_label.text = "彈藥  %d / %d" % [player.ammo, player.MAX_AMMO]

func _on_player_died():
	if death_panel:
		death_panel.visible = true

func _update_safe_indicator(is_safe: bool):
	if safe_indicator:
		safe_indicator.color = Color(0, 0.8, 0) if is_safe else Color(0.8, 0, 0)
	if safe_label:
		safe_label.text = "SAFE" if is_safe else "FIRE"

func _on_auto_aim_changed(is_auto_aiming: bool):
	if auto_aim_label:
		auto_aim_label.visible = is_auto_aiming

func show_victory_panel():
	if victory_panel:
		victory_panel.visible = true

func set_mission_text(text: String):
	if _mission_label:
		_mission_label.text = text

func start_countdown(seconds: float):
	# 建立倒數計時 Label，顯示在畫面上方正中央
	var timer_lbl = Label.new()
	timer_lbl.name = "CountdownLabel"
	timer_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	timer_lbl.add_theme_font_size_override("font_size", 32)
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_lbl.position = Vector2(860, 16)
	timer_lbl.size = Vector2(200, 40)
	add_child(timer_lbl)

func update_countdown(remaining: float):
	var lbl = find_child("CountdownLabel", true, false)
	if lbl:
		var mins = int(remaining) / 60
		var secs = int(remaining) % 60
		lbl.text = "%d:%02d" % [mins, secs]
		# 剩下 15 秒以內改為橘紅色
		if remaining <= 15.0:
			lbl.add_theme_color_override("font_color", Color(1, 0.1, 0.1))

func _on_mission_failed(reason: String):
	if failed_panel:
		var label = failed_panel.get_node_or_null("FailedLabel")
		if label:
			label.text = "任務失敗\n%s\n按 Enter 重新開始" % reason
		failed_panel.visible = true
