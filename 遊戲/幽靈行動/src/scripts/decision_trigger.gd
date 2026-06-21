extends Area2D

# 決策點觸發器
# 掛在場景中的 Area2D 節點，進入時觸發決策面板

@export var decision_type: String = "room"  # "room" / "supply" / "fork" / "shield_entry"
@export var location_name: String = "前方房間"
@export var already_triggered: bool = false

# events.json 對應的 type 名稱映射
# decision_type -> events.json 中的 type 欄位
const EVENT_TYPE_MAP: Dictionary = {
	"room":   "room_entry",
	"supply": "supply_box",
	"fork":   "fork_road",
}

# 從 events.json 讀取的事件資料（Autoload 時共用）
static var _events_cache: Dictionary = {}
static var _events_loaded: bool = false

# 基礎決策資料定義（fallback 用）
var BASE_DECISION_DATA = {
	"room": {
		"type": "room",
		"title": "前方房間",
		"description": "偵測到敵方移動，如何進入？",
		"options": [
			{"id": "charge",  "text": "直衝突入",   "desc": "快速但危險，全隊可能受傷"},
			{"id": "stealth", "text": "靜悄進入", "desc": "緩慢但安全，敵人無法提前警戒"},
			{"id": "bomb",    "text": "投擲炸彈",   "desc": "需要爆破手，清場效果佳"}
		]
	},
	"supply": {
		"type": "supply",
		"title": "發現補給箱",
		"description": "補給箱完好無損，選擇補給項目：",
		"options": [
			{"id": "heal", "text": "全體補血",   "desc": "全隊回復 40% HP"},
			{"id": "ammo", "text": "補充炸彈",   "desc": "爆破手大招 CD 重置"},
			{"id": "card", "text": "取得抽卡券", "desc": "獲得 1 張抽卡券（P2 實作）"}
		]
	}
}

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if already_triggered:
		return
	if body.is_in_group("squad"):
		_trigger()

func _trigger() -> void:
	already_triggered = true
	var data = _build_decision_data()
	data["location"] = location_name
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.trigger_decision(data)
	modulate = Color(0.3, 0.3, 0.3, 0.5)

# 偵察手預警：在觸發決策點前 5 秒呼叫此方法
# 由上一個決策點觸發完成後，若小隊有偵察手且 rand < 0.4，提前顯示預警
func try_recon_warning(next_trigger_type: String) -> void:
	if not _has_recon_in_squad():
		return
	if randf() >= 0.4:
		return
	var hud = get_tree().get_root().find_child("HUD", true, false)
	if hud and hud.has_method("show_recon_warning"):
		var type_display = _get_type_display_name(next_trigger_type)
		hud.show_recon_warning(type_display)

func _has_recon_in_squad() -> bool:
	var gm = get_node_or_null("/root/GameManager")
	if gm == null:
		return false
	for member in gm.squad_members:
		if member != null and is_instance_valid(member) and member.char_id == "recon" and not member.is_dead:
			return true
	return false

func _get_type_display_name(type: String) -> String:
	match type:
		"room":
			return "敵人房間"
		"supply":
			return "補給箱"
		"fork":
			return "岔路"
		"boss":
			return "Boss"
		_:
			return "未知威脅"

func _build_decision_data() -> Dictionary:
	# 深拷貝基礎資料，避免修改原始定義
	var base = BASE_DECISION_DATA.get(decision_type, BASE_DECISION_DATA["room"])
	var data: Dictionary = {
		"type": base["type"],
		"title": base["title"],
		"description": base["description"],
		"options": [],
	}
	for opt in base["options"]:
		data["options"].append(opt.duplicate())

	# Lv.3 盾兵解鎖：「舉盾突入」選項（僅 room 類型）
	if decision_type == "room":
		var shield_lv = _get_shield_level()
		if shield_lv >= 3:
			data["options"].append({
				"id": "shield_rush",
				"text": "[盾兵 Lv.3] 舉盾突入",
				"desc": "進門期間全隊受傷減半，盾兵衝在前方"
			})
			# 將決策類型改為 shield_entry，讓面板呼叫對應效果
			data["type"] = "shield_entry"

	return data

func _get_shield_level() -> int:
	var gm = get_node_or_null("/root/GameManager")
	if gm == null:
		return 1
	for member in gm.squad_members:
		if member != null and is_instance_valid(member) and member.char_id == "shield":
			return member.level if member.get("level") != null else 1
	return 1
