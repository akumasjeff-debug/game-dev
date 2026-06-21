extends Node

# 抽卡系統 — Autoload as "GachaManager"
# 新設計：6 職業等機率（各 16.67%），稀有度由備份張數累積升級

const ALL_CHARS = ["shield", "medic", "assault", "sniper", "demo", "recon"]

# 保底：連續 6 抽沒出新角色 → 下抽強制給未解鎖角色（若仍有未解鎖）
var _no_new_streak: int = 0

func _ready() -> void:
	pass

func pull(ticket_type: String) -> Dictionary:
	# 扣票
	if ticket_type == "gold":
		if SaveManager.gold_tickets <= 0:
			return {}
		SaveManager.gold_tickets -= 1
	else:
		if SaveManager.blue_tickets <= 0:
			return {}
		SaveManager.blue_tickets -= 1

	var char_id = _pick_char()
	return _apply_result(char_id, ticket_type)

func pull_10(ticket_type: String) -> Array:
	var needed = 10
	if ticket_type == "gold":
		if SaveManager.gold_tickets < needed:
			return []
	else:
		if SaveManager.blue_tickets < needed:
			return []
	var results = []
	for i in range(needed):
		var r = pull(ticket_type)
		if not r.is_empty():
			results.append(r)
	return results

func _pick_char() -> String:
	# 保底：連 6 抽都是已有角色 → 強制抽未解鎖
	var unowned = ALL_CHARS.filter(func(id): return not (id in SaveManager.owned_characters))
	if _no_new_streak >= 6 and unowned.size() > 0:
		_no_new_streak = 0
		return unowned[randi() % unowned.size()]
	return ALL_CHARS[randi() % ALL_CHARS.size()]

func _apply_result(char_id: String, ticket_type: String = "blue") -> Dictionary:
	var is_new = false
	var copies_gained = 0
	var copy_multiplier = 2 if ticket_type == "gold" else 1   # 金票備份 x2

	if char_id in SaveManager.owned_characters:
		# 已解鎖 → 備份張數 +1 或 +2（或補償 1 張藍票）
		var current_rarity = SaveManager.character_rarity.get(char_id, 0)
		if current_rarity >= 2:
			# 已是 SSR → 補償：給 1 張藍票
			SaveManager.blue_tickets += 1
			copies_gained = 0
		else:
			var copies = SaveManager.character_copies.get(char_id, 0)
			var gained = 1 * copy_multiplier
			SaveManager.character_copies[char_id] = copies + gained
			copies_gained = gained
		_no_new_streak += 1
	else:
		# 新角色 → 解鎖
		is_new = true
		SaveManager.owned_characters.append(char_id)
		if not SaveManager.character_rarity.has(char_id):
			SaveManager.character_rarity[char_id] = 0
		if not SaveManager.character_copies.has(char_id):
			SaveManager.character_copies[char_id] = 0
		_no_new_streak = 0

	SaveManager.save_game()
	return {
		"char_id": char_id,
		"is_new": is_new,
		"copies_gained": copies_gained,
		"current_copies": SaveManager.character_copies.get(char_id, 0),
		"current_rarity": SaveManager.character_rarity.get(char_id, 0),
		"ticket_type": ticket_type,
	}
