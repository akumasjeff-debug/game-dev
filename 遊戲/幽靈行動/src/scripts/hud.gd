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

var player: Node2D = null

func _ready():
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
	if auto_aim_label:
		auto_aim_label.visible = false
	_update_safe_indicator(false)

func _process(_delta):
	# 同步安全模式狀態（直接使用快取的 player）
	if player and is_instance_valid(player):
		if "safe_mode" in player:
			_update_safe_indicator(player.safe_mode)

func _input(event):
	if death_panel and death_panel.visible and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()

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
