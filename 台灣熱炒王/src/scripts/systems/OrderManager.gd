## OrderManager.gd
## 訂單管理系統 — AutoLoad Singleton
## 負責管理整個訂單生命週期：建立 → 分配廚師 → 烹飪完成 → 外場送餐 → 結帳
## 串接 CustomerAI（下單）與 StaffAI（廚師/外場任務）

extends Node


# ============================================================
# 信號定義
# ============================================================

## 新訂單建立時發出（order_data：完整訂單 Dictionary）
signal order_placed(order_data: Dictionary)

## 訂單烹飪完成、等待外場取餐時發出
signal order_ready(order_data: Dictionary)

## 訂單送達客人時發出
signal order_delivered(order_data: Dictionary)


# ============================================================
# 成員變數
# ============================================================

## 所有訂單資料表：order_id -> order_data Dictionary
var _orders: Dictionary = {}

## 等待廚師的訂單 ID 列表（尚未 assign 給任何廚師）
var _kitchen_queue: Array = []

## 等待外場員工的訂單 ID 列表（烹飪完成但還沒人送餐）
var _pending_delivery_queue: Array = []

## 遞增訂單 ID 計數器
var _order_counter: int = 0

## 備用自動完成計時器（StaffAI 未整合時的備用路徑）
## 結構：order_id -> 累積等待秒數
var _auto_cook_timers: Dictionary = {}
var _auto_deliver_timers: Dictionary = {}

## 自動完成烹飪的等待時間（秒）
## 設為 12.0 給真實廚師走路+烹飪 8 秒足夠時間，防止備用路徑搶先完成
const AUTO_COOK_DELAY: float = 12.0
## 自動送餐的等待時間（秒）
const AUTO_DELIVER_DELAY: float = 5.0


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	print("[OrderManager] 初始化完成")


# ============================================================
# 主循環：備用自動完成機制
# ============================================================

func _process(delta: float) -> void:
	_tick_auto_cook(delta)
	_tick_auto_deliver(delta)


## 對狀態為 pending 且尚無廚師的訂單，累計計時，超時後自動完成烹飪
func _tick_auto_cook(delta: float) -> void:
	for order_id: String in _kitchen_queue.duplicate():
		if not _orders.has(order_id):
			continue
		var order_data: Dictionary = _orders[order_id]
		if order_data.get("chef_id", "") != "":
			continue  # 已有真實廚師，不需備用路徑
		if order_data.get("status", "") != "pending":
			continue  # 已非 pending 狀態，跳過
		_auto_cook_timers[order_id] = _auto_cook_timers.get(order_id, 0.0) + delta
		if _auto_cook_timers[order_id] >= AUTO_COOK_DELAY:
			_auto_cook_timers.erase(order_id)
			# 標記 chef_id = "auto" 並從廚房佇列移除，防止重複觸發
			order_data["chef_id"] = "auto"
			_kitchen_queue.erase(order_id)
			print("[OrderManager] 備用路徑：訂單 %s 自動完成烹飪" % order_id)
			complete_cooking(order_id)


## 對狀態為 ready 且無人送餐的訂單，累計計時，超時後自動送達並結帳
func _tick_auto_deliver(delta: float) -> void:
	for order_id: String in _pending_delivery_queue.duplicate():
		if not _orders.has(order_id):
			continue
		var order_data: Dictionary = _orders[order_id]
		if order_data.get("server_id", "") != "":
			continue  # 已有真實外場員工，不需備用路徑
		_auto_deliver_timers[order_id] = _auto_deliver_timers.get(order_id, 0.0) + delta
		if _auto_deliver_timers[order_id] >= AUTO_DELIVER_DELAY:
			_auto_deliver_timers.erase(order_id)
			_pending_delivery_queue.erase(order_id)
			print("[OrderManager] 備用路徑：訂單 %s 自動送達客人" % order_id)
			_auto_deliver_order(order_id)


## 備用送餐：直接通知客人收餐並完成結帳（不經過員工 AI）
func _auto_deliver_order(order_id: String) -> void:
	if not _orders.has(order_id):
		return
	var order_data: Dictionary = _orders[order_id]
	# 防止重複送達：只有 ready 狀態才能進入 delivering
	if order_data.get("status", "") != "ready":
		return
	order_data["status"] = "delivering"

	# 通知客人餐點送達
	var customer_id: String = order_data["customer_id"]
	var customer_node: Node = _find_node_by_name_in_group("customers", customer_id)
	if customer_node != null:
		customer_node.receive_food()
	else:
		push_warning("[OrderManager] _auto_deliver_order：找不到客人節點 %s" % customer_id)

	order_delivered.emit(order_data)
	print("[OrderManager] 訂單 %s 備用送達完成" % order_id)

	# 結帳
	complete_payment(customer_id, 150.0)


# ============================================================
# 公開介面：訂單生命週期
# ============================================================

## 建立新訂單，加入廚房佇列
## 回傳新建立的 order_id
func place_order(customer_id: String, dish_id: String, table_tile: Vector2i) -> String:
	_order_counter += 1
	var order_id: String = "order_%03d" % _order_counter

	var order_data: Dictionary = {
		"id": order_id,
		"customer_id": customer_id,
		"dish_id": dish_id,
		"table_tile": table_tile,
		"chef_id": "",
		"server_id": "",
		"status": "pending",
		"created_at": Time.get_unix_time_from_system(),
	}

	_orders[order_id] = order_data
	_kitchen_queue.append(order_id)
	order_placed.emit(order_data)
	print("[OrderManager] 訂單 %s 建立：%s（客人 %s）" % [order_id, dish_id, customer_id])
	_try_assign_chef(order_id)
	return order_id


## 將訂單指派給廚師，呼叫 StaffAI 開始烹飪任務
func assign_to_chef(order_id: String, staff_id: String) -> void:
	if not _orders.has(order_id):
		push_warning("[OrderManager] assign_to_chef：找不到訂單 %s" % order_id)
		return

	var order_data: Dictionary = _orders[order_id]
	order_data["chef_id"] = staff_id
	order_data["status"] = "cooking"

	# 從廚房佇列移除
	_kitchen_queue.erase(order_id)

	# 找到對應的 StaffAI 節點並指派任務
	var staff_node: Node = _find_node_by_name_in_group("staff", staff_id)
	if staff_node != null:
		staff_node.assign_task({
			"id": order_id,
			"type": "cook",
			"target": null,
			"data": {"duration": 8.0}
		})
	else:
		push_warning("[OrderManager] assign_to_chef：找不到員工節點 %s" % staff_id)

	print("[OrderManager] 訂單 %s 指派給廚師 %s" % [order_id, staff_id])


## 廚師完成烹飪，通知外場準備送餐
func complete_cooking(order_id: String) -> void:
	if not _orders.has(order_id):
		push_warning("[OrderManager] complete_cooking：找不到訂單 %s" % order_id)
		return

	var order_data: Dictionary = _orders[order_id]
	# 防止重複觸發：只有 pending 或 cooking 狀態才能進入 ready
	if order_data.get("status", "") not in ["pending", "cooking"]:
		return
	order_data["status"] = "ready"
	order_ready.emit(order_data)
	print("[OrderManager] 訂單 %s 完成烹飪，等待外場取餐" % order_id)

	# 嘗試立即派遣閒置外場員工
	_notify_available_server(order_id)


## 外場員工送餐到桌，觸發結帳
func deliver_to_table(order_id: String, staff_id: String) -> void:
	if not _orders.has(order_id):
		push_warning("[OrderManager] deliver_to_table：找不到訂單 %s" % order_id)
		return

	var order_data: Dictionary = _orders[order_id]
	# 防止重複送達：只有 ready 狀態才能進入 delivering
	if order_data.get("status", "") != "ready":
		return
	order_data["server_id"] = staff_id
	order_data["status"] = "delivering"

	# 指派外場送餐任務
	var staff_node: Node = _find_node_by_name_in_group("staff", staff_id)
	if staff_node != null:
		staff_node.assign_task({
			"id": order_id + "_deliver",
			"type": "serve",
			"target": null,
			"data": {"duration": 4.0}
		})
	else:
		push_warning("[OrderManager] deliver_to_table：找不到員工節點 %s" % staff_id)

	# 通知客人餐點送達
	var customer_id: String = order_data["customer_id"]
	var customer_node: Node = _find_node_by_name_in_group("customers", customer_id)
	if customer_node != null:
		customer_node.receive_food()
	else:
		push_warning("[OrderManager] deliver_to_table：找不到客人節點 %s" % customer_id)

	order_delivered.emit(order_data)
	print("[OrderManager] 訂單 %s 由 %s 送達" % [order_id, staff_id])

	# 結帳（菜單整合前暫用固定金額）
	complete_payment(customer_id, 150.0)


## 客人結帳，金錢入帳並將訂單標記為完成
func complete_payment(customer_id: String, amount: float) -> void:
	GameManager.add_money(amount)
	print("[OrderManager] 客人 %s 結帳 $%s" % [customer_id, amount])

	# 找到該客人對應的未完成訂單，標記為 done
	for order_id: String in _orders:
		var order_data: Dictionary = _orders[order_id]
		if order_data["customer_id"] == customer_id and order_data["status"] != "done":
			order_data["status"] = "done"
			break


# ============================================================
# 私有輔助函式
# ============================================================

## 尋找閒置外場員工送餐；若無空閒員工則加入待送佇列
func _notify_available_server(order_id: String) -> void:
	var staff_nodes: Array[Node] = get_tree().get_nodes_in_group("staff")
	for staff_node: Node in staff_nodes:
		# 確認節點具備所需屬性（型別保護）
		if not ("task_queue" in staff_node and "current_task" in staff_node):
			continue
		var is_queue_empty: bool = (staff_node.task_queue as Array).is_empty()
		var is_task_empty: bool = (staff_node.current_task as Dictionary).is_empty()
		if is_queue_empty and is_task_empty:
			deliver_to_table(order_id, staff_node.name)
			return

	# 沒有空閒員工，加入待送佇列
	_pending_delivery_queue.append(order_id)
	print("[OrderManager] 訂單 %s 等待外場員工（佇列中）" % order_id)


## 嘗試找空閒廚師分配烹飪任務
func _try_assign_chef(order_id: String) -> void:
	var staff_nodes: Array[Node] = get_tree().get_nodes_in_group("staff")
	for staff_node: Node in staff_nodes:
		if not ("task_queue" in staff_node and "current_task" in staff_node and "_is_chef" in staff_node):
			continue
		if not staff_node._is_chef:
			continue  # 只找廚師，不派外場
		var is_queue_empty: bool = (staff_node.task_queue as Array).is_empty()
		var is_task_empty: bool = (staff_node.current_task as Dictionary).is_empty()
		if is_queue_empty and is_task_empty:
			assign_to_chef(order_id, staff_node.name)
			return
	# 沒空閒廚師，留在 kitchen_queue，備用路徑繼續兜底
	print("[OrderManager] 無空閒廚師，訂單 %s 留在廚房佇列" % order_id)


## 在指定群組中依名稱尋找節點，找不到回傳 null
func _find_node_by_name_in_group(group: String, node_name: String) -> Node:
	var nodes: Array[Node] = get_tree().get_nodes_in_group(group)
	for node: Node in nodes:
		if node.name == node_name:
			return node
	return null
