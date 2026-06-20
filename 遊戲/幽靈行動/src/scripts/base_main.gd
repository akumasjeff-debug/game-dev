extends Node2D

# Base.tscn 主腳本 — 幽靈行動指揮中心（HQ）

@onready var transition_overlay: ColorRect = $TransitionOverlay
@onready var start_btn: Button = $BottomBar/StartMissionBtn
@onready var settings_btn: Button = $BottomBar/SettingsBtn
@onready var org_name_label: Label = $Header/OrgName

var org_name: String = "Task Force NULL"

func _ready():
	# 確保 TransitionOverlay 完全透明（初始狀態）
	transition_overlay.modulate.a = 0.0
	transition_overlay.visible = true

	# 設定組織名稱
	if org_name_label:
		org_name_label.text = org_name

	# 連接按鈕
	start_btn.pressed.connect(_on_start_mission)
	settings_btn.pressed.connect(_on_settings)

func _on_start_mission():
	# TransitionOverlay 漸入（0 → 1，0.5 秒），然後切換到關卡 1
	var tween = create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
	)

func _on_settings():
	# 預留接口，目前僅在 HUD 顯示提示
	pass
