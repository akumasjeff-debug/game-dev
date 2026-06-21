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
var blue_tickets: int = 3      # 初始 3 張藍票
var gold_tickets: int = 0
var owned_characters: Array = ["shield", "assault", "medic", "demo"]  # 初始解鎖 4 角色（配合 DEFAULT_SQUAD）
var character_rarity: Dictionary = {}   # {char_id: int} 0=灰,1=銀,2=金
var character_copies: Dictionary = {}   # {char_id: int} 備份張數銀行（不含初始解鎖那張）
var stamina: int = 10
var max_stamina: int = 10

func _ready() -> void:
	character_levels = DEFAULT_LEVELS.duplicate()
	selected_squad = DEFAULT_SQUAD.duplicate()
	const ALL_IDS = ["shield", "medic", "assault", "sniper", "demo", "recon"]
	for id in ALL_IDS:
		if not character_rarity.has(id):
			character_rarity[id] = 0
		if not character_copies.has(id):
			character_copies[id] = 0
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

	cfg.set_value("gacha", "blue_tickets", blue_tickets)
	cfg.set_value("gacha", "gold_tickets", gold_tickets)
	cfg.set_value("gacha", "owned_characters", owned_characters)
	cfg.set_value("gacha", "character_rarity", character_rarity)
	cfg.set_value("gacha", "character_copies", character_copies)
	cfg.set_value("player", "stamina", stamina)

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

	blue_tickets = cfg.get_value("gacha", "blue_tickets", 3)
	gold_tickets = cfg.get_value("gacha", "gold_tickets", 0)
	owned_characters = cfg.get_value("gacha", "owned_characters", ["shield", "assault", "medic", "demo"])
	var saved_rarity = cfg.get_value("gacha", "character_rarity", {})
	for id in saved_rarity:
		character_rarity[id] = saved_rarity[id]
	var saved_copies = cfg.get_value("gacha", "character_copies", {})
	for id in saved_copies:
		character_copies[id] = saved_copies[id]
	stamina = cfg.get_value("player", "stamina", 10)

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

# 稀有度乘率
func get_rarity_multiplier(char_id: String) -> float:
	var r = character_rarity.get(char_id, 0)
	return 1.0 + r * 0.2   # 0=1.0, 1=1.2, 2=1.4

# 等級乘率
func get_level_multiplier(char_id: String) -> float:
	var lv = character_levels.get(char_id, 1)
	return 1.0 + (lv - 1) * 0.02   # Lv.1=1.0, Lv.10=1.18

# 嘗試升稀有度（需 2 張備份，回傳是否成功）
func try_upgrade_rarity(char_id: String) -> bool:
	var current = character_rarity.get(char_id, 0)
	if current >= 2:
		return false
	var copies = character_copies.get(char_id, 0)
	if copies < 2:
		return false
	character_copies[char_id] = copies - 2
	character_rarity[char_id] = current + 1
	save_game()
	return true

# 嘗試金幣升等（回傳是否成功）
func try_level_up(char_id: String) -> bool:
	var lv = character_levels.get(char_id, 1)
	if lv >= 10:
		return false
	var cost = (lv + 1) * 150
	if coins < cost:
		return false
	coins -= cost
	character_levels[char_id] = lv + 1
	save_game()
	return true

# 取得升一個稀有度需要的備份數（0 表示已滿或不足）
func copies_needed_for_rarity_up(char_id: String) -> int:
	if character_rarity.get(char_id, 0) >= 2:
		return 0  # 已滿
	return max(0, 2 - character_copies.get(char_id, 0))

# 取得下一等金幣費用（0 表示已滿）
func coins_needed_for_level_up(char_id: String) -> int:
	var lv = character_levels.get(char_id, 1)
	if lv >= 10:
		return 0
	return (lv + 1) * 150

func add_coins(amount: int) -> void:
	coins += amount

func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	return true

func spend_stamina() -> bool:
	if stamina >= 1:
		stamina -= 1
		save_game()
		return true
	return false

# 記錄退出時間（在 game 關閉前呼叫）
func record_exit_time() -> void:
	save_game()
