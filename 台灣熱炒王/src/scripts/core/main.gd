## main.gd
## 主場景根節點腳本
## 負責場景初始化、子場景切換、全局 UI 協調

extends Node


# ============================================================
# 節點引用
# ============================================================

## 遊戲主場景容器（掛 Game.tscn）
@onready var game_node: Node2D = $Game

## UI 根節點（UI.tscn 根節點為 Node，內含多個 CanvasLayer）
@onready var ui_layer: Node = $UI


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	print("[Main] 主場景初始化")
	# 連接 GameManager 信號
	GameManager.day_started.connect(_on_day_started)
	GameManager.day_ended.connect(_on_day_ended)
	GameManager.money_changed.connect(_on_money_changed)

	# 所有子節點（含 HUD）的 _ready() 已執行完畢，主動發射初始狀態
	# 讓 HUD 從啟動就顯示正確數值，不必等到第一個遊戲內事件觸發
	GameManager.money_changed.emit(GameManager.money)
	GameManager.reputation_changed.emit(GameManager.reputation)
	GameManager.day_started.emit(GameManager.current_year, GameManager.current_day)
	print("[Main] 初始狀態信號已發射（Year %d, Day %d, $%d）" % [
		GameManager.current_year, GameManager.current_day, int(GameManager.money)
	])


# ============================================================
# GameManager 信號回調
# ============================================================

func _on_day_started(year: int, day: int) -> void:
	print("[Main] 第 %d 年第 %d 天開始" % [year, day])
	# TODO: 通知 UI 更新日期顯示


func _on_day_ended(income: float) -> void:
	print("[Main] 今日結算，收入：NT$%.0f" % income)
	# TODO: 顯示日結 UI


func _on_money_changed(new_amount: float) -> void:
	# TODO: 通知 HUD 更新金錢顯示
	pass
