## SeatManager.gd
## 座位管理器，追蹤所有座位的可用狀態，供客人 AI 與 GameManager 呼叫。
## 座位由 GameManager 在桌椅設備放置/拆除時透過 register_seat / unregister_seat 管理。
extends Node

## 座位狀態列舉
enum SeatStatus {
	EMPTY    = 0,  ## 空位，可指派客人
	WAITING  = 1,  ## 有客人已找到此座位但尚未入座（保留中）
	OCCUPIED = 2,  ## 客人已入座用餐
}

## 座位資料字典
## key:   Vector2i（座位格子座標，與 TileMap 對齊）
## value: Dictionary { "status": SeatStatus, "customer_id": String }
var seats: Dictionary = {}

## 座位狀態變更信號，在 assign_seat / set_seat_waiting / free_seat 時發出。
signal seat_status_changed(tile: Vector2i, new_status: SeatStatus)


## 登記一個新座位（初始狀態為 EMPTY）。
## 由 GameManager 在桌椅設備放置成功後呼叫。
func register_seat(tile: Vector2i) -> void:
	if seats.has(tile):
		push_warning("SeatManager: 座位 %s 已存在，略過重複登記" % str(tile))
		return
	seats[tile] = {
		"status": SeatStatus.EMPTY,
		"customer_id": "",
	}


## 移除座位（桌椅被拆除時呼叫）。
## 若座位上有客人，強制釋放不發出信號（客人狀態由外部 AI 自行處理）。
func unregister_seat(tile: Vector2i) -> void:
	if not seats.has(tile):
		push_warning("SeatManager: 嘗試移除不存在的座位 %s" % str(tile))
		return
	seats.erase(tile)


## 回傳第一個狀態為 EMPTY 的座位 tile 座標。
## 無空位時回傳 Vector2i(-1, -1)。
## 注意：目前為線性掃描，座位數量多時可考慮維護一個 empty_seats 集合。
func get_available_seat() -> Vector2i:
	if seats.is_empty():
		push_warning("SeatManager: 座位表為空，尚未登記任何座位")
		return Vector2i(-1, -1)
	for tile: Vector2i in seats:
		if seats[tile]["status"] == SeatStatus.EMPTY:
			return tile
	return Vector2i(-1, -1)


## 指派座位給客人（設為 OCCUPIED）。
## 成功回傳 true；座位不存在或已被佔用（WAITING/OCCUPIED）回傳 false。
## WAITING 狀態：若 customer_id 不同，視為其他客人搶佔，拒絕並回傳 false。
func assign_seat(customer_id: String, tile: Vector2i) -> bool:
	if not seats.has(tile):
		push_warning("SeatManager: 座位 %s 不存在" % str(tile))
		return false
	var current_status: SeatStatus = seats[tile]["status"]
	if current_status == SeatStatus.OCCUPIED:
		return false
	# WAITING 狀態下驗證 customer_id，防止不同客人搶佔同一預留座位
	if current_status == SeatStatus.WAITING:
		var reserved_for: String = seats[tile]["customer_id"]
		if reserved_for != customer_id:
			push_warning("SeatManager: 座位 %s 已由 %s 預留，拒絕 %s 的指派請求" % [str(tile), reserved_for, customer_id])
			return false
	seats[tile]["status"] = SeatStatus.OCCUPIED
	seats[tile]["customer_id"] = customer_id
	seat_status_changed.emit(tile, SeatStatus.OCCUPIED)
	return true


## 設定座位為 WAITING 狀態（客人找到座位但尚未走到並入座）。
## 用於「預留」座位，防止其他客人同時搶佔同一個空位。
## 成功回傳 true；座位不存在或已被佔用（OCCUPIED）回傳 false。
func set_seat_waiting(customer_id: String, tile: Vector2i) -> bool:
	if not seats.has(tile):
		push_warning("SeatManager: 座位 %s 不存在" % str(tile))
		return false
	var current_status: SeatStatus = seats[tile]["status"]
	if current_status == SeatStatus.OCCUPIED:
		return false
	seats[tile]["status"] = SeatStatus.WAITING
	seats[tile]["customer_id"] = customer_id
	seat_status_changed.emit(tile, SeatStatus.WAITING)
	return true


## 釋放座位（客人付款離開後呼叫），重置為 EMPTY 並清除 customer_id。
func free_seat(tile: Vector2i) -> void:
	if not seats.has(tile):
		push_warning("SeatManager: 嘗試釋放不存在的座位 %s" % str(tile))
		return
	seats[tile]["status"] = SeatStatus.EMPTY
	seats[tile]["customer_id"] = ""
	seat_status_changed.emit(tile, SeatStatus.EMPTY)


## 查詢座位狀態。不存在的座位視為 EMPTY（安全預設值）。
func get_seat_status(tile: Vector2i) -> SeatStatus:
	if not seats.has(tile):
		return SeatStatus.EMPTY
	return seats[tile]["status"] as SeatStatus


## 回傳完整 seats 字典的副本，供外部唯讀查詢（防止外部直接修改內部狀態）。
func get_all_seats() -> Dictionary:
	return seats.duplicate(false)
