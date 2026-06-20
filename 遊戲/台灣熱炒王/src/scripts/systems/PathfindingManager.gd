## PathfindingManager.gd
## 路徑尋路管理器，基於 AStar2D 管理格子地圖的路徑查詢。
## 由 GameManager 在初始化時呼叫 set_map_rect() 設定地圖範圍，
## 每次設備放置/移除後呼叫 mark_tile_occupied / mark_tile_free 並觸發 rebuild_graph()。
extends Node

# AStar2D 尋路圖
var _astar: AStar2D = AStar2D.new()

# 手動標記為不可通行的格子（key: Vector2i, value: bool）
# 設備放置時寫入，設備移除時清除
var occupied_tiles: Dictionary = {}

# 路徑快取，key 格式為 "{from_x},{from_y}_{to_x},{to_y}"
# 地圖變更後需清除，避免使用過期快取
var _path_cache: Dictionary = {}

# 當前生效的地圖範圍（由 set_map_rect 設定）
var _map_rect: Rect2i = Rect2i(0, 0, 0, 0)

# 是否已完成初始化
var _initialized: bool = false


## 設定地圖範圍，由 GameManager 在地圖載入完成後呼叫。
## rect 為可通行的格子範圍，例如 Rect2i(1, 1, 16, 10)。
func set_map_rect(rect: Rect2i) -> void:
	_map_rect = rect
	_initialized = true
	rebuild_graph()


## 重建整個 AStar2D 尋路圖。
## 應在地圖範圍變更、設備批次放置完成後呼叫。
## 單次放置/移除建議只呼叫 mark_tile_occupied / mark_tile_free，
## 再手動呼叫 rebuild_graph() 以避免頻繁重建造成效能問題。
func rebuild_graph() -> void:
	if not _initialized:
		push_warning("PathfindingManager: 尚未設定地圖範圍，請先呼叫 set_map_rect()")
		return

	# 清除舊圖與快取
	_astar.clear()
	_path_cache.clear()

	# 第一遍：加入所有可通行格子作為 AStar 節點
	for y in range(_map_rect.position.y, _map_rect.end.y + 1):
		for x in range(_map_rect.position.x, _map_rect.end.x + 1):
			var cell := Vector2i(x, y)
			if _is_walkable(cell):
				var point_id: int = _cell_to_id(cell)
				# AStar2D 使用浮點位置，以格子座標直接作為位置
				_astar.add_point(point_id, Vector2(float(x), float(y)))

	# 第二遍：連接四方向（上下左右）相鄰的可通行格子
	for y in range(_map_rect.position.y, _map_rect.end.y + 1):
		for x in range(_map_rect.position.x, _map_rect.end.x + 1):
			var cell := Vector2i(x, y)
			var cell_id: int = _cell_to_id(cell)
			if not _astar.has_point(cell_id):
				continue
			# 只連接右方與下方，避免重複連接（AStar2D connect_points 是雙向的）
			var neighbors: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1)]
			for offset: Vector2i in neighbors:
				var ncell: Vector2i = cell + offset
				var ncell_id: int = _cell_to_id(ncell)
				if _astar.has_point(ncell_id):
					_astar.connect_points(cell_id, ncell_id)


## 查詢從 from_tile 到 to_tile 的路徑，回傳格子座標陣列（含起點與終點）。
## 找不到路徑或兩點相同時回傳空陣列。
func find_path(from_tile: Vector2i, to_tile: Vector2i) -> Array[Vector2i]:
	if not _initialized:
		push_warning("PathfindingManager: 尚未初始化，無法查詢路徑")
		return []

	if from_tile == to_tile:
		return []

	# 查詢快取
	var cache_key: String = "%d,%d_%d,%d" % [from_tile.x, from_tile.y, to_tile.x, to_tile.y]
	if _path_cache.has(cache_key):
		return _path_cache[cache_key]

	var from_id: int = _cell_to_id(from_tile)
	var to_id: int = _cell_to_id(to_tile)

	# 起點或終點不在尋路圖中（不可通行）
	if not _astar.has_point(from_id) or not _astar.has_point(to_id):
		return []

	var id_path: PackedInt64Array = _astar.get_id_path(from_id, to_id)
	var result: Array[Vector2i] = []
	for id: int in id_path:
		result.append(_id_to_cell(id))

	# 寫入快取（路徑為空也快取，避免重複查詢不可達路徑）
	_path_cache[cache_key] = result
	return result


## 標記格子為不可通行（設備放置時呼叫）。
## 標記後需要呼叫 rebuild_graph() 才會生效。
func mark_tile_occupied(tile: Vector2i) -> void:
	occupied_tiles[tile] = true
	_path_cache.clear()


## 標記格子恢復可通行（設備移除時呼叫）。
## 標記後需要呼叫 rebuild_graph() 才會生效。
func mark_tile_free(tile: Vector2i) -> void:
	occupied_tiles.erase(tile)
	_path_cache.clear()


## 查詢某格子是否可通行（不需重建圖，直接查詢狀態）。
func is_passable(tile: Vector2i) -> bool:
	return _is_walkable(tile)


# ──────────────────────────────────────────
# 內部方法
# ──────────────────────────────────────────

## 判斷格子是否可行走。
## 走道區（WALKWAY）一定可通行；其他區域若未被手動標記佔用也可通行。
## 注意：PathfindingManager 本身不持有 TileMap 參照，
## 走道判斷由 GameManager 在 rebuild_graph 前透過 mark_tile_occupied 批次標記完成。
## 若需要精確的 zone_type 判斷，外部在 rebuild 前呼叫 mark_tile_occupied 標記設備格子即可。
func _is_walkable(cell: Vector2i) -> bool:
	# 超出地圖範圍一定不可通行
	if not _map_rect.has_point(cell):
		return false
	# 若被手動標記為佔用，則不可通行
	if occupied_tiles.has(cell):
		return false
	return true


## 格子座標轉換為 AStar2D 點 ID。
## 公式：cell.y * 1000 + cell.x，支援最大地圖寬度 999（16x10 最大規格完全安全）。
## 原公式 * 100 在地圖寬度 > 99 時會發生 ID 碰撞（例如 (0,1) 和 (100,0) 得到相同 ID）。
func _cell_to_id(cell: Vector2i) -> int:
	return cell.y * 1000 + cell.x


## AStar2D 點 ID 轉換回格子座標。
func _id_to_cell(id: int) -> Vector2i:
	return Vector2i(id % 1000, id / 1000)
