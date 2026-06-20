extends CanvasLayer

@onready var hp_bar: ProgressBar = $HUDContainer/HPSection/HPBar
@onready var hp_label: Label = $HUDContainer/HPSection/HPLabel
@onready var ammo_bar: ProgressBar = $HUDContainer/AmmoSection/AmmoBar
@onready var ammo_label: Label = $HUDContainer/AmmoSection/AmmoLabel
@onready var reload_label: Label = $HUDContainer/ReloadLabel
@onready var death_panel: Control = $DeathPanel
@onready var victory_panel: Control = $VictoryPanel
@onready var failed_panel: Control = $FailedPanel
@onready var _kill_label: Label = $KillLabel
@onready var _class_label: Label = $ClassLabel
@onready var _multi_kill_label: Label = $MultiKillLabel

var player: Node2D = null
var _mission_label: Label

# ── 擊殺計數 ─────────────────────────────────────────────
var kill_count: int = 0
var _recent_kills: int = 0          # 1 秒內的擊殺數（連殺判斷用）
var _kill_reset_timer: float = 0.0  # 倒數計時（>0 時代表計時中）
var _multi_kill_show_timer: float = 0.0  # 「連殺！」顯示剩餘秒數
const MULTI_KILL_WINDOW: float = 1.0     # 連殺判定視窗（秒）
const MULTI_KILL_DISPLAY: float = 0.8    # 「連殺！」顯示時長（秒）

# ── HP 條顏色常數 ────────────────────────────────────────
const HP_COLOR_HIGH  = Color(0.15, 0.85, 0.2,  1.0)  # 100%–51%  綠色
const HP_COLOR_MID   = Color(0.95, 0.85, 0.1,  1.0)  # 50%–26%   黃色
const HP_COLOR_LOW   = Color(0.9,  0.15, 0.1,  1.0)  # 25% 以下   紅色

func _ready():
	add_to_group("hud")
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		player.hp_changed.connect(_on_hp_changed)
		player.ammo_changed.connect(_on_ammo_changed)
		player.reload_started.connect(_on_reload_started)
		player.reload_finished.connect(_on_reload_finished)
		player.died.connect(_on_player_died)

	# 初始狀態
	if reload_label:
		reload_label.visible = false
	if death_panel:
		death_panel.visible = false
	if victory_panel:
		victory_panel.visible = false
	if failed_panel:
		failed_panel.visible = false
	if _multi_kill_label:
		_multi_kill_label.visible = false

	# 職業標籤初始值
	if _class_label:
		_class_label.text = "[突擊手]"

	# 擊殺計數初始
	_update_kill_display()

	# 動態建立任務文字標籤（畫面上方正中）
	_mission_label = Label.new()
	_mission_label.text = ""
	_mission_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mission_label.anchor_left   = 0.5
	_mission_label.anchor_right  = 0.5
	_mission_label.anchor_top    = 0.0
	_mission_label.anchor_bottom = 0.0
	_mission_label.offset_left   = -200.0
	_mission_label.offset_right  = 200.0
	_mission_label.offset_top    = 10.0
	_mission_label.offset_bottom = 36.0
	_mission_label.modulate = Color(1.0, 0.584, 0.0, 1.0)  # #ff9500
	_mission_label.add_theme_font_size_override("font_size", 16)
	add_child(_mission_label)

func _process(delta: float):
	# 連殺計時視窗倒數
	if _kill_reset_timer > 0.0:
		_kill_reset_timer -= delta
		if _kill_reset_timer <= 0.0:
			_recent_kills = 0

	# 「連殺！」顯示計時
	if _multi_kill_show_timer > 0.0:
		_multi_kill_show_timer -= delta
		if _multi_kill_show_timer <= 0.0 and _multi_kill_label:
			_multi_kill_label.visible = false

func _input(event):
	if death_panel and death_panel.visible and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
	if victory_panel and victory_panel.visible and event.is_action_pressed("restart"):
		_go_to_next_level()
	if failed_panel and failed_panel.visible and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()

func _go_to_next_level():
	get_tree().change_scene_to_file("res://scenes/ResultScreen.tscn")

# ── 擊殺計數 ────────────────────────────────────────────
func add_kill():
	kill_count += 1
	_recent_kills += 1
	_kill_reset_timer = MULTI_KILL_WINDOW  # 重設視窗

	# 同步到 GameData（讓結算畫面能顯示正確擊殺數）
	GameData.last_enemies_killed = kill_count

	_update_kill_display()
	_check_multi_kill()

func _update_kill_display():
	if _kill_label:
		_kill_label.text = "☠ " + str(kill_count)

func _check_multi_kill():
	if _recent_kills >= 2 and _multi_kill_label:
		_multi_kill_label.visible = true
		_multi_kill_show_timer = MULTI_KILL_DISPLAY

# ── HP 更新（含顏色動態）────────────────────────────────
func _on_hp_changed(current_hp: int, max_hp: int):
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
		# 動態更改 HP 條填充顏色
		var ratio: float = float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
		var fill_style = hp_bar.get_theme_stylebox("fill")
		if fill_style and fill_style is StyleBoxFlat:
			if ratio > 0.5:
				fill_style.bg_color = HP_COLOR_HIGH
			elif ratio > 0.25:
				fill_style.bg_color = HP_COLOR_MID
			else:
				fill_style.bg_color = HP_COLOR_LOW
	if hp_label:
		hp_label.text = "HP  %d / %d" % [current_hp, max_hp]

# ── 彈藥更新（數字格式） ──────────────────────────────────
func _on_ammo_changed(current_ammo: int, max_ammo: int):
	if ammo_bar:
		ammo_bar.max_value = max_ammo
		ammo_bar.value = current_ammo
	if ammo_label:
		ammo_label.text = "◉ %d / %d" % [current_ammo, max_ammo]

func _on_reload_started():
	if reload_label:
		reload_label.visible = true
	if ammo_label:
		ammo_label.text = "RELOADING..."

func _on_reload_finished():
	if reload_label:
		reload_label.visible = false
	if ammo_label and player:
		ammo_label.text = "◉ %d / %d" % [player.ammo, player.MAX_AMMO]

func _on_player_died():
	if death_panel:
		death_panel.visible = true

func show_victory_panel():
	if victory_panel:
		victory_panel.visible = true

func set_mission_text(text: String):
	if _mission_label:
		_mission_label.text = text

# ── 職業標籤更新（供未來職業系統呼叫） ──────────────────────
func set_class_name(class_name_text: String):
	if _class_label:
		_class_label.text = "[" + class_name_text + "]"

func start_countdown(seconds: float):
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
		if remaining <= 15.0:
			lbl.add_theme_color_override("font_color", Color(1, 0.1, 0.1))

func _on_mission_failed(reason: String):
	if failed_panel:
		var label = failed_panel.get_node_or_null("FailedLabel")
		if label:
			label.text = "任務失敗\n%s\n按 Enter 重新開始" % reason
		failed_panel.visible = true
