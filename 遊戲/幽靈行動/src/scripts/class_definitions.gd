extends Node

# 幽靈行動 — 職業定義
# 所有職業的數值與特殊邏輯由此處統一管理

const CLASS_DATA = {
	"assault": {
		"display_name": "突擊手",
		"speed": 150.0,
		"max_hp": 100,
		"damage": 25,
		"fire_rate": 0.1,
		"max_ammo": 30,
		"reload_time": 2.0,
		"range": 500.0,
		"cone_angle": 120.0,
		"special": ""
	},
	"sniper": {
		"display_name": "狙擊手",
		"speed": 90.0,
		"max_hp": 100,
		"damage": 80,
		"fire_rate": 0.6,
		"max_ammo": 5,
		"reload_time": 4.0,
		"range": 1200.0,
		"cone_angle": 60.0,
		"special": "slow_reload"
	},
	"shield": {
		"display_name": "盾兵",
		"speed": 75.0,
		"max_hp": 150,
		"damage": 15,
		"fire_rate": 0.3,
		"max_ammo": 15,
		"reload_time": 2.5,
		"range": 250.0,
		"cone_angle": 180.0,
		"special": "frontal_defense"  # 正面傷害 -85%
	},
	"shotgun": {
		"display_name": "散彈手",
		"speed": 120.0,
		"max_hp": 120,
		"damage": 35,
		"fire_rate": 0.5,
		"max_ammo": 8,
		"reload_time": 2.5,
		"range": 150.0,
		"cone_angle": 90.0,
		"special": "shotgun_spread"  # 5 顆散彈
	},
	"medic": {
		"display_name": "醫療手",
		"speed": 128.0,
		"max_hp": 120,
		"damage": 18,
		"fire_rate": 0.12,
		"max_ammo": 40,
		"reload_time": 1.5,
		"range": 380.0,
		"cone_angle": 150.0,
		"special": "fast_revive"
	}
}

# 取得職業顯示名稱
static func get_display_name(class_type: String) -> String:
	if class_type in CLASS_DATA:
		return CLASS_DATA[class_type]["display_name"]
	return "未知"

# 取得職業所有數值
static func get_class_stats(class_type: String) -> Dictionary:
	if class_type in CLASS_DATA:
		return CLASS_DATA[class_type]
	return CLASS_DATA["assault"]
