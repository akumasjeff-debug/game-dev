## SaveManager.gd
## 存檔管理器，負責主存檔與自動存檔的讀寫、版本 migration。
## JSON 格式，路徑位於 user://saves/，讀取後自動執行 SaveMigration.migrate()。
## 建議掛載為 AutoLoad 或由 GameManager 持有。
extends Node

const SaveMigration = preload("res://scripts/systems/SaveMigration.gd")

## 存檔目錄（需在寫入前確保存在）
const SAVE_DIR: String = "user://saves/"

## 主存檔路徑
const SAVE_FILE: String = "user://saves/save_01.json"

## 自動存檔路徑（每日結算後觸發）
const AUTO_SAVE_FILE: String = "user://saves/auto_save.json"

## 當前存檔格式版本號（每次存檔格式有 breaking change 時遞增）
const CURRENT_VERSION: int = 1

## 存檔操作完成信號
## success = true 表示操作成功，false 表示發生錯誤
signal save_completed(success: bool)
signal load_completed(success: bool)


## 存主存檔。
## data 為 game_data 主體（年份、金錢、地圖等），此函式負責包裝 version + save_date。
## 成功回傳 true，寫檔失敗回傳 false。
func save_game(data: Dictionary) -> bool:
	var success: bool = _write_save(SAVE_FILE, data)
	save_completed.emit(success)
	return success


## 存自動存檔（每日結算後呼叫）。
## 格式與主存檔相同，獨立檔案以防主存檔損毀。
func auto_save(data: Dictionary) -> bool:
	var success: bool = _write_save(AUTO_SAVE_FILE, data)
	# 自動存檔不發出 save_completed 信號，避免觸發 UI 提示
	return success


## 讀主存檔。
## 找不到檔案或讀取失敗回傳 {}。
## 讀取成功後自動執行 SaveMigration.migrate() 升級舊版存檔格式。
func load_game() -> Dictionary:
	var result: Dictionary = _read_save(SAVE_FILE)
	var success: bool = not result.is_empty()
	load_completed.emit(success)
	return result


## 讀自動存檔。
## 找不到或讀取失敗回傳 {}。
func load_auto_save() -> Dictionary:
	return _read_save(AUTO_SAVE_FILE)


## 檢查主存檔是否存在。
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE)


## 檢查自動存檔是否存在。
func has_auto_save() -> bool:
	return FileAccess.file_exists(AUTO_SAVE_FILE)


## 刪除主存檔（重新開始遊戲時呼叫）。
## 自動存檔不連動刪除，保留作為緊急還原用。
func delete_save() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return
	# 使用 DirAccess.open() 搭配相對路徑，避免 remove_absolute 在 Android/iOS 收到虛擬路徑失敗
	var dir := DirAccess.open("user://saves/")
	if dir == null:
		push_error("SaveManager: 無法開啟存檔目錄，錯誤代碼 %d" % DirAccess.get_open_error())
		return
	var err: Error = dir.remove("save_01.json")
	if err != OK:
		push_error("SaveManager: 刪除主存檔失敗，錯誤代碼 %d" % err)


# ──────────────────────────────────────────
# 內部方法
# ──────────────────────────────────────────

## 共用寫檔邏輯，包裝 version + save_date 後寫入 JSON。
func _write_save(path: String, game_data: Dictionary) -> bool:
	# 確保目錄存在（第一次執行時建立）
	# 使用 DirAccess.open() + make_dir_recursive，避免 make_dir_recursive_absolute 在 Android/iOS 收到虛擬路徑失敗
	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("SaveManager: 無法開啟 user:// 目錄，錯誤代碼 %d" % DirAccess.get_open_error())
		return false
	var dir_err: Error = dir.make_dir_recursive("saves")
	if dir_err != OK:
		push_error("SaveManager: 無法建立存檔目錄，錯誤代碼 %d" % dir_err)
		return false

	# 組裝存檔根節點
	var payload: Dictionary = {
		"version": CURRENT_VERSION,
		"save_date": Time.get_datetime_string_from_system(),
		"game_data": game_data,
	}

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: 無法開啟檔案寫入 %s，錯誤代碼 %d" % [path, FileAccess.get_open_error()])
		return false

	# 縮排 4 空格，方便 debug 時人工閱讀
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true


## 共用讀檔邏輯，讀取 JSON 並執行 migration，失敗時回傳 {}。
func _read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: 無法開啟存檔 %s，錯誤代碼 %d" % [path, FileAccess.get_open_error()])
		return {}

	var raw_text: String = file.get_as_text()
	file.close()

	var parse_result: Variant = JSON.parse_string(raw_text)
	if parse_result == null:
		push_error("SaveManager: 存檔 JSON 格式錯誤（%s），存檔可能損毀" % path)
		return {}

	if not parse_result is Dictionary:
		push_error("SaveManager: 存檔根節點不是 Dictionary（%s）" % path)
		return {}

	# 執行版本升級
	var migrated: Dictionary = SaveMigration.migrate(parse_result as Dictionary)
	return migrated
