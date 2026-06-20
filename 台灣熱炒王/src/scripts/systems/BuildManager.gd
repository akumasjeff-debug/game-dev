## BuildManager.gd
## 建築管理器，負責地圖格子的 Zone 管理與設備放置/移除。
## AutoLoad singleton，供全局存取。
extends Node

# ──────────────────────────────────────────
# 列舉
# ──────────────────────────────────────────

enum ZoneType {
	EMPTY,
	KITCHEN,
	SEATING,
	WALKWAY,
	STORAGE,
	DECORATION
}

# ──────────────────────────────────────────
# 常數
# ──────────────────────────────────────────

const MAP_WIDTH: int = 16
const MAP_HEIGHT: int = 10
const TILE_SIZE: int = 16

# ──────────────────────────────────────────
# 信號
# ──────────────────────────────────────────

## 設備放置成功後發送，tile 為左上角格子座標
signal equipment_placed(tile: Vector2i, equipment_id: String)

## 設備移除後發送，tile 為被點擊的格子（設備佔用的任意一格）
signal equipment_removed(tile: Vector2i)

## 格子 Zone 類型變更後發送
signal zone_changed(tile: Vector2i, zone: ZoneType)

# ──────────────────────────────────────────
# 資料
# ──────────────────────────────────────────

## zone_map[Vector2i] = ZoneType，儲存每個格子的 Zone 類型
var zone_map: Dictionary = {}

## equipment_map[Vector2i] = equipment_id，儲存已放置設備佔用的所有格子
## 一個多格設備的每個佔用格都存同一個 equipment_id，
## 以便移除時可從任意佔用格反查整組格子
var equipment_map: Dictionary = {}

## _equipment_origin[equipment_id] = Array[Vector2i]，記錄每組設備佔用的所有格子
## 用於移除時快速清除所有佔用格，避免逐一掃描整張地圖
var _equipment_origin: Dictionary = {}

# ──────────────────────────────────────────
# 核心方法
# ──────────────────────────────────────────

## 驗證從 tile 開始的 size 範圍是否可放置設備。
## 條件：全部格子都是 required_zone、無設備佔用、在地圖範圍內。
func check_placement(tile: Vector2i, size: Vector2i, required_zone: ZoneType) -> bool:
	for dy in range(size.y):
		for dx in range(size.x):
			var cell := tile + Vector2i(dx, dy)

			# 地圖範圍驗證（左上角從 0,0 開始，右下角最大格為 MAP_WIDTH-1, MAP_HEIGHT-1）
			if cell.x < 0 or cell.x >= MAP_WIDTH or cell.y < 0 or cell.y >= MAP_HEIGHT:
				return false

			# Zone 類型驗證
			if get_zone(cell) != required_zone:
				return false

			# 設備佔用驗證
			if equipment_map.has(cell):
				return false

	return true


## 放置設備，通過 check_placement 後才寫入資料並發送信號。
## tile 為設備左上角格子，size 為佔用範圍，equipment_id 為唯一識別碼。
## 回傳 true 表示放置成功，false 表示驗證失敗。
func place_equipment(tile: Vector2i, size: Vector2i, equipment_id: String) -> bool:
	# check_placement 需要 required_zone，設備放置時以 KITCHEN 為預設，
	# 呼叫端應直接呼叫 check_placement 先行驗證，或由外部傳入所需 zone 類型。
	# 此方法保留完整簽名，place_equipment 本身不再重複做 zone 驗證，
	# 改為只驗證「無超界」與「無重疊」（因 zone 合法性由外部在呼叫前確認）。
	# 若需強制綁定 zone，請改用 place_equipment_in_zone。

	# 先驗證邊界與重疊
	for dy in range(size.y):
		for dx in range(size.x):
			var cell := tile + Vector2i(dx, dy)
			if cell.x < 0 or cell.x >= MAP_WIDTH or cell.y < 0 or cell.y >= MAP_HEIGHT:
				return false
			if equipment_map.has(cell):
				return false

	# 寫入所有佔用格
	var occupied_cells: Array[Vector2i] = []
	for dy in range(size.y):
		for dx in range(size.x):
			var cell := tile + Vector2i(dx, dy)
			equipment_map[cell] = equipment_id
			occupied_cells.append(cell)

	_equipment_origin[equipment_id] = occupied_cells
	equipment_placed.emit(tile, equipment_id)
	return true


## 放置設備並驗證所有格子都符合指定 Zone 類型。
## 為完整版本，整合 check_placement 的 Zone 驗證。
func place_equipment_in_zone(tile: Vector2i, size: Vector2i, equipment_id: String, required_zone: ZoneType) -> bool:
	if not check_placement(tile, size, required_zone):
		return false

	# 寫入所有佔用格
	var occupied_cells: Array[Vector2i] = []
	for dy in range(size.y):
		for dx in range(size.x):
			var cell := tile + Vector2i(dx, dy)
			equipment_map[cell] = equipment_id
			occupied_cells.append(cell)

	_equipment_origin[equipment_id] = occupied_cells
	equipment_placed.emit(tile, equipment_id)
	return true


## 移除格子上的設備，會清除該設備佔用的所有格子。
## tile 可以是設備佔用的任意一格。
func remove_equipment(tile: Vector2i) -> void:
	if not equipment_map.has(tile):
		return

	var eq_id: String = equipment_map[tile]

	# 清除所有佔用格
	if _equipment_origin.has(eq_id):
		var cells: Array = _equipment_origin[eq_id]
		for cell in cells:
			equipment_map.erase(cell)
		_equipment_origin.erase(eq_id)
	else:
		# 防禦性處理：_equipment_origin 遺漏時，只清除當前格
		equipment_map.erase(tile)

	equipment_removed.emit(tile)


## 設定格子的 Zone 類型並發送信號。
func set_zone(tile: Vector2i, zone: ZoneType) -> void:
	zone_map[tile] = zone
	zone_changed.emit(tile, zone)


## 取得格子的 Zone 類型，未設定的格子回傳 EMPTY。
func get_zone(tile: Vector2i) -> ZoneType:
	if zone_map.has(tile):
		return zone_map[tile] as ZoneType
	return ZoneType.EMPTY


## 查詢 tile 四個相鄰格子的設備，根據相鄰組合回傳加成字典。
## 格式：{"combo_type": String, "bonus_value": float}
## 無加成時回傳空字典。
## 規則來源：design/map-design.md 第 98-108 行
##
## 支援的相鄰加成組合：
##   same_kitchen        — 同類廚房設備相鄰，出菜效率 +8%
##   stove_to_counter    — 快炒爐緊鄰出菜台，出菜速度 +15%
##   seating_decoration  — 桌椅旁邊有裝飾物，每桌滿意度 +5%
##   table_tv            — 大圓桌緊鄰電視，翻桌率 -10%（客人坐比較久）
##   ac_coverage         — 冷氣貼牆且覆蓋範圍內有 4 桌以上，夏季滿意度加成翻倍
##   storage_kitchen     — 倉庫區緊鄰廚房區，補貨速度 +20%
##   neon_entrance       — 霓虹招牌在入口格旁邊，月進客數 +10%
func get_adjacency_bonus(tile: Vector2i) -> Dictionary:
	var directions: Array[Vector2i] = [
		Vector2i(0, -1),  # 上
		Vector2i(0,  1),  # 下
		Vector2i(-1, 0),  # 左
		Vector2i( 1, 0),  # 右
	]

	# 收集相鄰格子的設備 ID 與 Zone
	var neighbor_equipment: Array[String] = []
	var neighbor_zones: Array[ZoneType] = []
	for dir in directions:
		var neighbor := tile + dir
		if equipment_map.has(neighbor):
			neighbor_equipment.append(equipment_map[neighbor] as String)
		else:
			neighbor_equipment.append("")
		neighbor_zones.append(get_zone(neighbor))

	var self_eq: String = equipment_map.get(tile, "") as String
	var self_zone: ZoneType = get_zone(tile)

	# ── 規則 1：同類廚房設備相鄰（同區塊），出菜效率 +8%
	# 判斷：tile 與任一相鄰格同為 KITCHEN Zone 且都有設備
	if self_zone == ZoneType.KITCHEN and self_eq != "":
		for i in range(neighbor_equipment.size()):
			if neighbor_zones[i] == ZoneType.KITCHEN and neighbor_equipment[i] != "":
				return {"combo_type": "same_kitchen", "bonus_value": 0.08}

	# ── 規則 2：快炒爐緊鄰出菜台，出菜速度 +15%
	# 判斷：tile 是 stove_*，相鄰有 counter_*；或反向
	var is_stove: bool = self_eq.begins_with("stove")
	var is_counter: bool = self_eq.begins_with("counter")
	if is_stove or is_counter:
		for eq_id in neighbor_equipment:
			if eq_id == "":
				continue
			var neighbor_is_stove: bool = eq_id.begins_with("stove")
			var neighbor_is_counter: bool = eq_id.begins_with("counter")
			if (is_stove and neighbor_is_counter) or (is_counter and neighbor_is_stove):
				return {"combo_type": "stove_to_counter", "bonus_value": 0.15}

	# ── 規則 3：桌椅旁邊有裝飾物，每桌滿意度 +5%
	# 判斷：tile 為 SEATING Zone 且有設備，相鄰有 DECORATION Zone 格子
	if self_zone == ZoneType.SEATING and self_eq != "":
		for zone in neighbor_zones:
			if zone == ZoneType.DECORATION:
				return {"combo_type": "seating_decoration", "bonus_value": 0.05}

	# ── 規則 4：大圓桌緊鄰電視，翻桌率 -10%
	# 判斷：tile 是 round_table_*，相鄰有 tv_*；或反向
	var is_round_table: bool = self_eq.begins_with("round_table")
	var is_tv: bool = self_eq.begins_with("tv")
	if is_round_table or is_tv:
		for eq_id in neighbor_equipment:
			if eq_id == "":
				continue
			var n_is_round_table: bool = eq_id.begins_with("round_table")
			var n_is_tv: bool = eq_id.begins_with("tv")
			if (is_round_table and n_is_tv) or (is_tv and n_is_round_table):
				return {"combo_type": "table_tv", "bonus_value": -0.10}

	# ── 規則 5：冷氣貼牆且覆蓋範圍內有 4 桌以上，夏季滿意度加成翻倍
	# 判斷：tile 是 ac_*，且 tile 正上方超出地圖（貼北牆）或四方向有一方超界（貼牆），
	# 同時 3x3 覆蓋範圍內計算 seating_* 設備數 >= 4
	if self_eq.begins_with("ac"):
		var is_wall_adjacent: bool = false
		for dir in directions:
			var neighbor := tile + dir
			if neighbor.x < 0 or neighbor.x >= MAP_WIDTH or neighbor.y < 0 or neighbor.y >= MAP_HEIGHT:
				is_wall_adjacent = true
				break
		if is_wall_adjacent:
			var seating_count: int = 0
			for cy in range(tile.y - 2, tile.y + 3):
				for cx in range(tile.x - 2, tile.x + 3):
					var check_cell := Vector2i(cx, cy)
					if equipment_map.has(check_cell):
						var eq: String = equipment_map[check_cell] as String
						if eq.begins_with("seating") or eq.begins_with("table") or eq.begins_with("chair"):
							seating_count += 1
			if seating_count >= 4:
				return {"combo_type": "ac_coverage", "bonus_value": 2.0}

	# ── 規則 6：倉庫區緊鄰廚房區，補貨速度 +20%
	# 判斷：tile 為 STORAGE Zone，相鄰有 KITCHEN Zone；或反向
	var is_storage_zone: bool = self_zone == ZoneType.STORAGE
	var is_kitchen_zone: bool = self_zone == ZoneType.KITCHEN
	if is_storage_zone or is_kitchen_zone:
		for zone in neighbor_zones:
			if (is_storage_zone and zone == ZoneType.KITCHEN) or (is_kitchen_zone and zone == ZoneType.STORAGE):
				return {"combo_type": "storage_kitchen", "bonus_value": 0.20}

	# ── 規則 7：霓虹招牌在入口格旁邊，月進客數 +10%
	# 判斷：tile 是 neon_sign_*，相鄰有 entrance_* 設備；或 tile 是入口且相鄰有霓虹招牌
	var is_neon: bool = self_eq.begins_with("neon_sign")
	var is_entrance: bool = self_eq.begins_with("entrance")
	if is_neon or is_entrance:
		for eq_id in neighbor_equipment:
			if eq_id == "":
				continue
			var n_is_neon: bool = eq_id.begins_with("neon_sign")
			var n_is_entrance: bool = eq_id.begins_with("entrance")
			if (is_neon and n_is_entrance) or (is_entrance and n_is_neon):
				return {"combo_type": "neon_entrance", "bonus_value": 0.10}

	return {}


## 驗證 from_tile 到 to_tile 是否連通。
## 透過 PathfindingManager（AutoLoad）的 find_path 方法查詢，
## 回傳 true 表示有可通行路徑。
func is_path_connected(from_tile: Vector2i, to_tile: Vector2i) -> bool:
	# PathfindingManager 以 find_path 回傳空陣列代表不可達
	var path: Array[Vector2i] = PathfindingManager.find_path(from_tile, to_tile)
	return path.size() > 0
