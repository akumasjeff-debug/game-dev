extends Node2D

# 霧戰暫時停用 - 全圖可見模式
# 未來確認核心玩法後再決定是否加入

func _ready():
	add_to_group("fog_of_war")

# 供敵人查詢：暫時永遠回傳 true（全圖可見）
func is_in_clear_vision(_pos: Vector2) -> bool:
	return true
