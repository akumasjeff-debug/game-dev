extends Node

# 幽靈行動 — Roguelite 存檔系統 (AutoLoad: SaveSystem)

const SAVE_PATH = "user://ghost_save.json"

var gold: int = 0
var selected_class: String = "assault"
var unlocked_classes: Array = ["assault"]
var weapon_levels: Dictionary = {
	"assault": 1,
	"sniper": 1,
	"shield": 1,
	"shotgun": 1,
	"medic": 1
}
var squad_slots: int = 1   # 最多 4
var mission_progress: int = 0  # 已完成關卡數（0 = 全未完成）

func _ready():
	load_save()

func save():
	var data = {
		"gold": gold,
		"selected_class": selected_class,
		"unlocked_classes": unlocked_classes,
		"weapon_levels": weapon_levels,
		"squad_slots": squad_slots,
		"mission_progress": mission_progress
	}
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

func load_save():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var text = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	if "gold" in parsed:
		gold = int(parsed["gold"])
	if "selected_class" in parsed:
		selected_class = str(parsed["selected_class"])
	if "unlocked_classes" in parsed:
		unlocked_classes = Array(parsed["unlocked_classes"])
	if "weapon_levels" in parsed:
		# 逐欄合併，保留預設鍵
		var wl = parsed["weapon_levels"]
		for k in wl:
			weapon_levels[k] = int(wl[k])
	if "squad_slots" in parsed:
		squad_slots = int(parsed["squad_slots"])
	if "mission_progress" in parsed:
		mission_progress = int(parsed["mission_progress"])

func reset():
	gold = 0
	selected_class = "assault"
	unlocked_classes = ["assault"]
	weapon_levels = {
		"assault": 1,
		"sniper": 1,
		"shield": 1,
		"shotgun": 1,
		"medic": 1
	}
	squad_slots = 1
	mission_progress = 0
	save()
