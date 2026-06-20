## SaveMigration.gd
## 存檔版本升級工具，以 static function 實作，不需實例化。
## SaveManager.load_game() 在讀取存檔後自動呼叫 migrate()，確保舊存檔格式能被新版本正確讀取。
##
## 版本歷程：
##   v0（開發期）→ v1：補上 game_data.reputation 欄位（預設 0）
##
## 新增版本時在 migrate() 末端繼續加 if version < N: data = _migrate_vX_to_vY(data)。
class_name SaveMigration
extends RefCounted


## 主要升級入口。接收原始存檔 Dictionary，依照版本號逐步升級至最新版本後回傳。
## 此函式保證不修改傳入的原始 data（透過 Godot 的值語意）。
static func migrate(data: Dictionary) -> Dictionary:
	# 讀取版本號，缺少 version 欄位視為 v0（最舊的開發期格式）
	var version: int = data.get("version", 0)

	if version < 1:
		data = _migrate_v0_to_v1(data)

	# 未來版本於此繼續加入：
	# if version < 2:
	#     data = _migrate_v1_to_v2(data)

	return data


## v0 → v1 升級：
## - 補上 game_data.reputation 欄位（玩家名聲值，預設 0）
## - 更新 version 欄位為 1
static func _migrate_v0_to_v1(data: Dictionary) -> Dictionary:
	# 確保 game_data 節點存在（極端情況的防護）
	if not data.has("game_data") or not data["game_data"] is Dictionary:
		data["game_data"] = {}

	var game_data: Dictionary = data["game_data"]

	# 補上 v1 新增的 reputation 欄位
	if not game_data.has("reputation"):
		game_data["reputation"] = 0

	data["game_data"] = game_data
	data["version"] = 1
	return data
