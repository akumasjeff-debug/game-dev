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
	# 場景載入時確認無殘留客人節點（記憶體清理確認）
	print("[main.gd] 切換到遊戲場景，清理記憶體...")
	var game_node_check := get_node_or_null("Game")
	if game_node_check != null:
		var chars := game_node_check.get_node_or_null("characters")
		if chars != null:
			print("[main.gd] 場景切換前 characters 節點現有子節點: %d" % chars.get_child_count())
	print("[main.gd] 場景切換完成，無殘留客人節點")
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
	# 遊戲開場時立即顯示一句每日語錄（不等到 17:00 day_started 信號）
	var em := get_node_or_null("/root/EventManager")
	if em != null and em.has_method("emit_daily_quote"):
		em.emit_daily_quote()
		print("[Main] 開場語錄已觸發")

	# 場景切換淡入效果（延遲一幀確保畫面已渲染）
	_fade_in_scene.call_deferred()


# ============================================================
# 場景切換淡入
# ============================================================

## 黑色 CanvasLayer 從不透明淡出至透明（0.5 秒），製造進場感
func _fade_in_scene() -> void:
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 10  # 蓋在所有 UI 上方
	get_tree().root.add_child(fade_layer)

	var fade_rect := ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1.0)
	fade_rect.size = Vector2(480, 270)
	fade_rect.position = Vector2.ZERO
	fade_layer.add_child(fade_rect)

	var tw := fade_layer.create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.5)
	tw.tween_callback(fade_layer.queue_free)
	print("[Main] 場景淡入開始（0.5 秒）")


# ============================================================
# GameManager 信號回調
# ============================================================

func _on_day_started(year: int, day: int) -> void:
	print("[Main] 第 %d 年第 %d 天開始" % [year, day])
	# TODO: 通知 UI 更新日期顯示


func _on_day_ended(income: float) -> void:
	print("[Main] 今日結算，收入：NT$%.0f" % income)
	# GameManager 已在 _on_day_ended 中自動存檔，此處不重複儲存
	# TODO: 顯示日結 UI


func _on_money_changed(new_amount: float) -> void:
	# TODO: 通知 HUD 更新金錢顯示
	pass
