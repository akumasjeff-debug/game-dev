extends Node

# 本機存檔系統 — Autoload as "SaveManager"
# 使用 Godot ConfigFile 儲存玩家進度

const SAVE_PATH: String = "user://save_data.cfg"

# 離線金幣規格
const COINS_PER_HOUR: float = 50.0
const COINS_PER_SECOND: float = COINS_PER_HOUR / 3600.0
const MAX_OFFLINE_HOURS: float = 24.0
const MAX_OFFLINE_COINS: float = COINS_PER_HOUR * MAX_OFFLINE_HOURS  # 1200

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
const DEFAULT_SQUAD: Array = ["shield_r", "assault_r", "demo_r", "medic_r"]

# 執行期資料
var coins: int = DEFAULT_COINS
var character_levels: Dictionary = {}
var last_exit_timestamp: int = 0
var selected_squad: Array = []  # 4 個 card_id 字串（如 "assault_r", "shield_sr"）
var tutorial_completed: bool = false
var blue_tickets: int = 3      # 初始 3 張藍票
var gold_tickets: int = 0
var owned_characters: Array = ["shield", "assault", "medic", "demo"]  # 初始解鎖 4 角色（配合 DEFAULT_SQUAD）
var character_rarity: Dictionary = {}   # {char_id: int} 0=灰,1=銀,2=金
var character_copies: Dictionary = {}   # {char_id: int} 備份張數銀行（不含初始解鎖那張）
var stamina: int = 10
var max_stamina: int = 10
var completed_missions: Array = []  # 已完成的 mission_id 清單

# 卡牌系統
var owned_cards: Dictionary = {}   # {card_id: plus_count}  例如 {"assault_r": 2, "shield_sr": 0}
var card_levels: Dictionary = {}   # {card_id: level}  例如 {"assault_r": 3}
var gacha_pity: int = 0            # 抽卡保底計數（每 10 抽保底 SR）
var starter_claimed: bool = false  # 新手10抽是否已領取

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
	_initialize_card_defaults()

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

	# 教學進度
	cfg.set_value("player", "tutorial_completed", tutorial_completed)

	cfg.set_value("gacha", "blue_tickets", blue_tickets)
	cfg.set_value("gacha", "gold_tickets", gold_tickets)
	cfg.set_value("gacha", "owned_characters", owned_characters)
	cfg.set_value("gacha", "character_rarity", character_rarity)
	cfg.set_value("gacha", "character_copies", character_copies)
	cfg.set_value("player", "stamina", stamina)
	cfg.set_value("progress", "completed_missions", completed_missions)

	cfg.set_value("cards", "owned_cards", owned_cards)
	cfg.set_value("cards", "card_levels", card_levels)
	cfg.set_value("cards", "selected_squad", selected_squad)
	cfg.set_value("cards", "gacha_pity", gacha_pity)
	cfg.set_value("meta", "starter_claimed", starter_claimed)

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
	completed_missions = cfg.get_value("progress", "completed_missions", [])

	owned_cards = cfg.get_value("cards", "owned_cards", {})
	card_levels = cfg.get_value("cards", "card_levels", {})
	# selected_squad 統一使用 card_id 格式（如 "assault_r", "shield_sr"）
	var saved_card_squad = cfg.get_value("cards", "selected_squad", DEFAULT_SQUAD.duplicate())
	if saved_card_squad.size() == 4:
		selected_squad = saved_card_squad
	else:
		selected_squad = DEFAULT_SQUAD.duplicate()
	gacha_pity = cfg.get_value("cards", "gacha_pity", 0)
	starter_claimed = cfg.get_value("meta", "starter_claimed", false)

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

	if elapsed_seconds < 300.0:
		# 少於 5 分鐘，不顯示
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
	var cost = lv * 50
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
	return lv * 50

func reset_all() -> void:
	# DEMO 專用：清空所有存檔資料並重新初始化預設值
	var path = "user://save.cfg"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	coins = 200
	blue_tickets = 3
	gold_tickets = 0
	stamina = 10
	owned_cards = {}
	card_levels = {}
	selected_squad = []
	gacha_pity = 0
	starter_claimed = false
	completed_missions = []
	_initialize_card_defaults()

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

# ─────────────────────────────────────────
#  任務完成記錄
# ─────────────────────────────────────────

func mark_mission_complete(mission_id: String) -> void:
	if mission_id not in completed_missions:
		completed_missions.append(mission_id)
	save_game()

func is_mission_completed(mission_id: String) -> bool:
	return mission_id in completed_missions

# ─────────────────────────────────────────
#  藍票入帳
# ─────────────────────────────────────────

func add_blue_tickets(amount: int) -> void:
	blue_tickets += amount
	save_game()

# ─────────────────────────────────────────
#  卡牌系統
# ─────────────────────────────────────────

func _initialize_card_defaults() -> void:
	if owned_cards.is_empty():
		for class_id in ["shield", "assault", "demo", "medic", "sniper", "recon"]:
			owned_cards[class_id + "_r"] = 0
			card_levels[class_id + "_r"] = 1
		selected_squad = ["shield_r", "assault_r", "medic_r", "sniper_r"]
		save_game()

# 查詢是否擁有某張卡
func has_card(card_id: String) -> bool:
	return owned_cards.has(card_id)

# 取得卡片強化值
func get_card_plus(card_id: String) -> int:
	return owned_cards.get(card_id, 0)

# 取得卡片等級
func get_card_level(card_id: String) -> int:
	return card_levels.get(card_id, 1)

# 抽到卡片（新卡或重複）
# 回傳 {"result": "new"/"plus"/"overflow", "plus": N, "coins": N}
func add_card(card_id: String, max_plus: int = 3) -> Dictionary:
	if not owned_cards.has(card_id):
		owned_cards[card_id] = 0
		card_levels[card_id] = 1
		save_game()
		return {"result": "new", "plus": 0, "coins": 0}
	else:
		var current_plus = owned_cards[card_id]
		if current_plus < max_plus:
			owned_cards[card_id] += 1
			save_game()
			return {"result": "plus", "plus": owned_cards[card_id], "coins": 0}
		else:
			# 上限：轉換為金幣
			add_coins(50)
			return {"result": "overflow", "plus": current_plus, "coins": 50}

# 升級卡片（消耗金幣）
func upgrade_card(card_id: String, cost: int) -> bool:
	if coins < cost:
		return false
	if not card_levels.has(card_id):
		return false
	coins -= cost
	card_levels[card_id] = card_levels[card_id] + 1
	save_game()
	return true

# 設定出戰陣容（最多 4 個 card_id）
func set_selected_squad(squad: Array) -> void:
	selected_squad = squad.slice(0, 4)
	save_game()

# 取得特定職業的所有擁有卡片
func get_cards_by_class(char_class: String) -> Array:
	var result = []
	for card_id in owned_cards.keys():
		if card_id.begins_with(char_class + "_"):
			result.append(card_id)
	return result

# ─────────────────────────────────────────
#  新手10抽系統
# ─────────────────────────────────────────

# 執行新手 10 連抽，回傳 card_id Array
# 保證至少 1 張 SR 以上（第 10 抽若還沒出 SR 則強制保底）
func claim_starter_pulls() -> Array:
	if starter_claimed:
		return []
	starter_claimed = true

	var results = []
	var has_sr_or_above = false

	for i in range(10):
		var force_sr = (i == 9 and not has_sr_or_above)
		var card_id = _do_single_pull(force_sr)
		results.append(card_id)
		var grade = card_id.split("_")[1].to_upper()
		if grade in ["SR", "SSR", "QR"]:
			has_sr_or_above = true
		add_card(card_id, _get_max_plus(card_id))

	save_game()
	return results

func _do_single_pull(guaranteed_sr: bool = false) -> String:
	var config = _load_gacha_config()
	if config.is_empty():
		return "assault_r"  # fallback

	var pool_by_grade = config.get("pool_by_grade", {})
	var rates = config.get("rates", {"R": 0.75, "SR": 0.18, "SSR": 0.06, "QR": 0.01})

	var grade: String
	if guaranteed_sr:
		# 保底：只從 SR/SSR/QR 中抽，內部機率 SR 65%、SSR 25%、QR 10%
		var r = randf()
		if r < 0.10:
			grade = "QR"
		elif r < 0.35:
			grade = "SSR"
		else:
			grade = "SR"
	else:
		var r = randf()
		var qr_rate = rates.get("QR", 0.01)
		var ssr_rate = rates.get("SSR", 0.06)
		var sr_rate = rates.get("SR", 0.18)
		if r < qr_rate:
			grade = "QR"
		elif r < qr_rate + ssr_rate:
			grade = "SSR"
		elif r < qr_rate + ssr_rate + sr_rate:
			grade = "SR"
		else:
			grade = "R"

	var pool = pool_by_grade.get(grade, ["assault_r"])
	return pool[randi() % pool.size()]

func _get_max_plus(card_id: String) -> int:
	var parts = card_id.split("_")
	if parts.size() < 2:
		return 3
	var grade = parts[1]
	match grade:
		"r": return 3
		"sr": return 4
		"ssr": return 5
		"qr": return 6
	return 3

func _load_gacha_config() -> Dictionary:
	var path = "res://resources/data/gacha_config.json"
	if not ResourceLoader.exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text = file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	return data if data != null else {}
