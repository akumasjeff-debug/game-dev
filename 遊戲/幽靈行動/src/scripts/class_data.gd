class_name ClassData

# 職業定義
const CLASSES = {
	"assault": {
		"name": "突擊手",
		"hp": 100,
		"speed": 150.0,
		"damage": 25,
		"fire_rate": 0.1,
		"ammo": 30,
		"reload_time": 2.0,
		"range": 500.0,
		"color": Color(0.3, 0.6, 1.0),  # 藍色
	},
	"sniper": {
		"name": "狙擊手",
		"hp": 80,
		"speed": 120.0,
		"damage": 75,
		"fire_rate": 1.2,
		"ammo": 10,
		"reload_time": 3.0,
		"range": 900.0,
		"color": Color(0.2, 0.8, 0.3),  # 綠色
	},
	"heavy": {
		"name": "重裝兵",
		"hp": 150,
		"speed": 90.0,
		"damage": 15,
		"fire_rate": 0.06,
		"ammo": 60,
		"reload_time": 3.5,
		"range": 300.0,
		"color": Color(0.9, 0.4, 0.1),  # 橘色
	},
	"medic": {
		"name": "醫療兵",
		"hp": 90,
		"speed": 140.0,
		"damage": 20,
		"fire_rate": 0.15,
		"ammo": 20,
		"reload_time": 1.5,
		"range": 400.0,
		"color": Color(0.9, 0.9, 0.2),  # 黃色
	},
}
