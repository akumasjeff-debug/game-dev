extends Node

# 幽靈行動 — 陣形系統 (AutoLoad: FormationSystem)
# 本輪只建立架構 + 鍵盤切換，視覺效果後續再補

const FORMATIONS = ["攻堅", "散開", "防守", "快速"]

var current_index: int = 0

signal formation_changed(index: int, name: String)

func _ready():
	pass

func get_current_formation() -> String:
	return FORMATIONS[current_index]

func get_current_index() -> int:
	return current_index

func next_formation():
	current_index = (current_index + 1) % FORMATIONS.size()
	emit_signal("formation_changed", current_index, FORMATIONS[current_index])

func prev_formation():
	current_index = (current_index - 1 + FORMATIONS.size()) % FORMATIONS.size()
	emit_signal("formation_changed", current_index, FORMATIONS[current_index])
