extends Node

# 本機存檔系統 — Autoload as "SaveManager"
# 使用 Godot ConfigFile 儲存玩家進度

const SAVE_PATH: String = "user://save_data.cfg"

# 離線金幣規格
const COINS_PER_HOUR: float = 100.0
const COINS_PER_SECOND: float = COINS_PER_HOUR / 3600.0
const MAX_OFFLINE_HOURS: float = 24.0
const MAX_OFFLINE_COINS: float = COINS_PER_HOUR * MAX_OFFLINE_HOURS  # 2400

# 預設值
const DEFAULT_COINS: int = 0
const DEFAULT_LEVELS: Dictionary = {
	"shield": 1,
	"medic": 1,
	"assault": 1,
	"sniper": 1,
	"demo": 1,
	"recon": 1
}
const DEFAULT_SQUAD: Array = ["shield", "assault", "demo", "medic"]

# 執行期資料
var coins: int = DEFAULT_COINS
var character_levels: Dictionary = {}
var last_exit_timestamp: int = 0
var selected_squad: Array = []  # 4 個 char_id 字串
var tutorial_completed: bool = false

func _ready() -> void:
	character_levels = DEFAULT_LEVELS.duplicate()
	selected_squad = DEFAULT_SQUAD.duplicate()
	load_game()

# ─────────────────────────────────────────
#  存檔 / 讀檔
# ─────────────────────────────────────────

func save_game() -> void:
	var cfg = ConfigFile.new()

	cfg.set_value("player", "coins", coins)
	cfg.set_value("player", "last_exit_timestamp", int(Time.get_unix_time_from_system()))

	# 角色等級
	for char_id in character_levels:
		cfg.set_value("character_levels", char_id, character_levels[char_id])

	# 選定陣容
	cfg.set_value("squad", "selected", selected_squad)

	# 教學進度
	cfg.set_value("player", "tutorial_completed", tutorial_completed)

	var err = cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("[SaveManager] 存檔失敗: " + str(err))

func load_game() -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err != OK:
		# 首次啟動，使用預設值
		return

	coins = cfg.get_value("player", "coins", DEFAULT_COINS)
	last_exit_timestamp = cfg.get_value("player", "last_exit_timestamp", 0)
	tutorial_completed = cfg.get_value("player", "tutorial_completed", false)

	# 角色等級
	for char_id in DEFAULT_LEVELS:
		var saved_level = cfg.get_value("character_levels", char_id, 1)
		character_levels[char_id] = saved_level

	# 陣容
	var saved_squad = cfg.get_value("squad", "selected", DEFAULT_SQUAD)
	if saved_squad.size() == 4:
		selected_squad = saved_squad
	else:
		selected_squad = DEFAULT_SQUAD.duplicate()

# ─────────────────────────────────────────
#  離線金幣計算
# ─────────────────────────────────────────

# 計算離線金幣，並清除 timestamp（避免重複計算）
# 回傳 { "minutes": int, "coins": int }
func calculate_offline_reward() -> Dictionary:
	if last_exit_timestamp <= 0:
		return {"minutes": 0, "coins": 0}

	var now: int = int(Time.get_unix_time_from_system())
	var elapsed_seconds: float = float(now - last_exit_timestamp)

	if elapsed_seconds < 60.0:
		# 少於 1 分鐘，不顯示
		last_exit_timestamp = 0
		return {"minutes": 0, "coins": 0}

	# 限制最大離線時間
	var capped_seconds: float = minf(elapsed_seconds, MAX_OFFLINE_HOURS * 3600.0)
	var earned_coins: int = int(capped_seconds * COINS_PER_SECOND)
	var elapsed_minutes: int = int(elapsed_seconds / 60.0)

	# 清除 timestamp，避免重複計算
	last_exit_timestamp = 0

	return {"minutes": elapsed_minutes, "coins": earned_coins}

func add_coins(amount: int) -> void:
	coins += amount

func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	return true

# 記錄退出時間（在 game 關閉前呼叫）
func record_exit_time() -> void:
	save_game()
