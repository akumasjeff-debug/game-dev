extends Control

@onready var level_label: Label = $CenterContainer/VBoxContainer/LevelLabel
@onready var kills_label: Label = $CenterContainer/VBoxContainer/KillsLabel
@onready var reward_label: Label = $CenterContainer/VBoxContainer/RewardLabel
@onready var total_label: Label = $CenterContainer/VBoxContainer/TotalLabel
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton

func _ready():
	# 把本局獎勵累加進總金錢
	GameData.total_money += GameData.last_level_reward

	level_label.text = "關卡：" + GameData.last_level_name
	kills_label.text = "敵人消滅：" + str(GameData.last_enemies_killed)
	reward_label.text = "金錢獎勵：+$" + str(GameData.last_level_reward)
	total_label.text = "累積金錢：$" + str(GameData.total_money)

	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/Base.tscn")
