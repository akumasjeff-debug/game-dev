## MenuManager.gd
## 菜單管理器，從 dishes.json 載入所有菜品資料，並管理菜色的解鎖/鎖定狀態。
## 遊戲啟動時自動載入，供訂單系統、UI、成就系統查詢。
extends Node

## dishes.json 資料路徑（Godot res:// 路徑）
const DISHES_DATA_PATH: String = "res://resources/data/dishes.json"

## 菜品資料字典
## key:   dish_id (String)
## value: Dictionary，完整菜品資料
##        { "id": String, "name": String, "price": int, "cost": int,
##          "category": String, "unlocked": bool }
var _dishes: Dictionary = {}


func _ready() -> void:
	_load_dishes()


## 從 JSON 載入菜品資料。
## 錯誤時 push_error 並保持 _dishes 為空字典，不 crash。
func _load_dishes() -> void:
	_dishes.clear()

	if not FileAccess.file_exists(DISHES_DATA_PATH):
		push_error("MenuManager: 找不到菜品資料檔 %s" % DISHES_DATA_PATH)
		return

	var file := FileAccess.open(DISHES_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("MenuManager: 無法開啟菜品資料檔 %s" % DISHES_DATA_PATH)
		return

	var raw_text: String = file.get_as_text()
	file.close()

	var parse_result: Variant = JSON.parse_string(raw_text)
	if parse_result == null:
		push_error("MenuManager: dishes.json JSON 格式錯誤，請確認檔案內容")
		return

	if not parse_result is Array:
		push_error("MenuManager: dishes.json 根節點應為 Array，實際為 %s" % typeof(parse_result))
		return

	var dish_array: Array = parse_result as Array
	for entry: Variant in dish_array:
		if not entry is Dictionary:
			push_warning("MenuManager: 略過非 Dictionary 的菜品項目")
			continue
		var dish: Dictionary = entry as Dictionary
		if not dish.has("id"):
			push_warning("MenuManager: 略過缺少 'id' 欄位的菜品項目")
			continue
		var dish_id: String = str(dish["id"])
		_dishes[dish_id] = dish

	# 載入完成，回報數量（方便 debug）
	# print("MenuManager: 已載入 %d 道菜品" % _dishes.size())


## 回傳所有已解鎖（unlocked == true）的菜品 Dictionary 陣列。
## 供訂單系統隨機點餐或 UI 顯示使用。
func get_available_dishes() -> Array:
	var result: Array = []
	for dish_id: String in _dishes:
		var dish: Dictionary = _dishes[dish_id]
		if dish.get("unlocked", false):
			result.append(dish)
	return result


## 查詢某道菜是否可用（存在且已解鎖）。
func is_dish_available(dish_id: String) -> bool:
	if not _dishes.has(dish_id):
		return false
	return _dishes[dish_id].get("unlocked", false)


## 解鎖菜色（設 unlocked = true）。
## 用於達成解鎖條件（年份推進、成就觸發）時呼叫。
func unlock_dish(dish_id: String) -> void:
	if not _dishes.has(dish_id):
		push_warning("MenuManager: 嘗試解鎖不存在的菜品 '%s'" % dish_id)
		return
	_dishes[dish_id]["unlocked"] = true


## 鎖定菜色（設 unlocked = false）。
## 用於特殊事件（食材短缺、衛生事件）暫時下架某道菜。
func lock_dish(dish_id: String) -> void:
	if not _dishes.has(dish_id):
		push_warning("MenuManager: 嘗試鎖定不存在的菜品 '%s'" % dish_id)
		return
	_dishes[dish_id]["unlocked"] = false


## 取得單一菜品完整資料。
## 不存在時回傳空 Dictionary {}。
func get_dish(dish_id: String) -> Dictionary:
	if not _dishes.has(dish_id):
		return {}
	return _dishes[dish_id]


## 依分類篩選可用菜品，回傳該分類下所有 unlocked == true 的菜品陣列。
## category 範例："炒類", "燒烤", "飲料", "涼拌"
func get_dishes_by_category(category: String) -> Array:
	var result: Array = []
	for dish_id: String in _dishes:
		var dish: Dictionary = _dishes[dish_id]
		if dish.get("category", "") == category and dish.get("unlocked", false):
			result.append(dish)
	return result


## 重新從 JSON 載入所有菜品資料，覆蓋當前記憶體狀態。
## 主要用於 debug 工具或熱重載，正式遊戲流程不需呼叫。
## 注意：此操作會清除當前所有解鎖狀態！正式流程應使用存檔資料還原解鎖狀態。
func reload_dishes() -> void:
	_load_dishes()
