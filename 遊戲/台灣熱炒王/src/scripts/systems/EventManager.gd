## EventManager.gd
## 事件系統 AutoLoad Singleton
## 負責：載入 events.json、輪詢觸發條件、推送事件到 UI、執行選項效果。
## 在 project.godot 的 [autoload] 區塊新增：
##   EventManager="*res://scripts/systems/EventManager.gd"

extends Node


# ============================================================
# 信號定義
# ============================================================

## 事件觸發時發出，UI 對話框監聽此信號以顯示事件內容。
## event_data 為完整事件 Dictionary（含 id、name、dialog、options 等欄位）。
signal event_triggered(event_data: Dictionary)

## 玩家選擇選項後發出（效果已套用完畢）。
signal option_selected(event_id: String, option_index: int)


# ============================================================
# 常數
# ============================================================

const EVENTS_JSON_PATH: String = "res://resources/data/events.json"

## 名聲等級門檻（對應 trigger_condition 中的 reputation_above/below 判斷）
const REPUTATION_LV2: int = 200
const REPUTATION_LV3: int = 400
const REPUTATION_LV5: int = 700


# ============================================================
# 內部狀態
# ============================================================

## 事件快取：key = event_id (String)、value = 事件 Dictionary。
## 啟動時載入一次，執行期間不重複讀檔。
var _events_cache: Dictionary = {}

## 已觸發但尚未處理完的事件佇列（避免同一幀多個事件同時彈出）。
var _pending_queue: Array[String] = []

## 記錄今日已觸發的事件 id，避免同一天重複觸發同一事件。
var _triggered_today: Array[String] = []

## 目前是否有事件正在顯示中（防止佇列快速連發）。
var _is_showing_event: bool = false


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_load_events()
	call_deferred("_connect_signals")

func _connect_signals() -> void:
	GameManager.day_ended.connect(_on_day_ended)


## 從 res://resources/data/events.json 載入所有事件並快取到 _events_cache。
func _load_events() -> void:
	if not FileAccess.file_exists(EVENTS_JSON_PATH):
		push_error("[EventManager] 找不到事件資料檔：%s" % EVENTS_JSON_PATH)
		return

	var file := FileAccess.open(EVENTS_JSON_PATH, FileAccess.READ)
	if file == null:
		push_error("[EventManager] 無法開啟事件資料檔，錯誤代碼 %d" % FileAccess.get_open_error())
		return

	var raw_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)
	if parsed == null:
		push_error("[EventManager] events.json 格式錯誤，無法解析 JSON")
		return

	if not parsed is Dictionary:
		push_error("[EventManager] events.json 根節點不是 Dictionary")
		return

	var root: Dictionary = parsed as Dictionary
	if not root.has("events") or not root["events"] is Array:
		push_error("[EventManager] events.json 缺少 \"events\" 陣列")
		return

	_events_cache.clear()
	for event_data: Variant in root["events"]:
		if event_data is Dictionary and event_data.has("id"):
			_events_cache[event_data["id"]] = event_data

	print("[EventManager] 載入完成，共 %d 個事件" % _events_cache.size())


# ============================================================
# 公開 API：觸發條件輪詢
# ============================================================

## 輪詢所有事件，回傳符合觸發條件的事件 id 列表。
## game_state 需包含以下 key（由呼叫方從 GameManager 組裝後傳入）：
##   - "year"       : int   當前年份
##   - "day"        : int   累積天數
##   - "reputation" : int   當前名聲值（0~1000）
##   - "is_open"    : bool  是否正在營業
func check_triggers(game_state: Dictionary) -> Array:
	var triggered: Array = []

	for event_id: String in _events_cache:
		# 已在今日觸發過的事件跳過
		if event_id in _triggered_today:
			continue

		var event_data: Dictionary = _events_cache[event_id]
		var condition: Dictionary = event_data.get("trigger_condition", {})

		if _check_condition(condition, game_state):
			triggered.append(event_id)

	return triggered


## 將事件加入佇列並嘗試立即顯示（若目前沒有事件正在顯示）。
## 通常由外部（GameManager、結算系統等）在適當時機呼叫。
func trigger_event(event_id: String) -> void:
	if not _events_cache.has(event_id):
		push_warning("[EventManager] trigger_event：找不到事件 id「%s」" % event_id)
		return

	if event_id in _triggered_today:
		return

	if event_id not in _pending_queue:
		_pending_queue.append(event_id)

	_flush_queue()


## 執行玩家選擇的選項效果，並發出 option_selected 信號。
## event_id：事件 id；option_index：選項索引（0-based）。
func apply_option(event_id: String, option_index: int) -> void:
	if not _events_cache.has(event_id):
		push_warning("[EventManager] apply_option：找不到事件 id「%s」" % event_id)
		return

	var event_data: Dictionary = _events_cache[event_id]
	var options: Array = event_data.get("options", [])

	if option_index < 0 or option_index >= options.size():
		push_warning("[EventManager] apply_option：選項索引 %d 超出範圍（共 %d 個選項）" % [option_index, options.size()])
		return

	var option: Dictionary = options[option_index]
	var effects: Dictionary = option.get("effects", {})

	_apply_effects(effects, event_id)

	# 標記此事件今日已處理
	if event_id not in _triggered_today:
		_triggered_today.append(event_id)

	_is_showing_event = false
	option_selected.emit(event_id, option_index)

	# 繼續處理佇列中的下一個事件
	_flush_queue()


# ============================================================
# 內部方法：條件判斷
# ============================================================

## 判斷單一觸發條件是否符合當前遊戲狀態。
## 支援 type：reputation_above / reputation_below / day_equals / random_chance / year_start
func _check_condition(condition: Dictionary, game_state: Dictionary) -> bool:
	var cond_type: String = condition.get("type", "")
	var value: Variant = condition.get("value", 0)

	# 年份前置條件（大多數事件都有 min_year）
	var min_year: int = condition.get("min_year", 1)
	var current_year: int = game_state.get("year", 1)
	if current_year < min_year:
		return false

	match cond_type:
		"reputation_above":
			var rep: int = game_state.get("reputation", 0)
			return rep >= int(value)

		"reputation_below":
			var rep: int = game_state.get("reputation", 0)
			return rep < int(value)

		"day_equals":
			# 以年內天數比對（累積天數 mod 365，簡化版）
			var total_day: int = game_state.get("day", 1)
			var day_of_year: int = ((total_day - 1) % 365) + 1
			# 容許 ±3 天誤差（節慶事件不需精確到日）
			var target_day: int = int(value)
			return abs(day_of_year - target_day) <= 3

		"random_chance":
			# value 為觸發機率（0.0~1.0）
			var chance: float = float(value)
			return randf() < chance

		"year_start":
			# 新年開始（每年第 1 天）
			var total_day: int = game_state.get("day", 1)
			var day_of_year: int = ((total_day - 1) % 365) + 1
			return day_of_year == 1

		_:
			push_warning("[EventManager] _check_condition：未知的條件類型「%s」" % cond_type)
			return false


# ============================================================
# 內部方法：套用效果
# ============================================================

## 將選項 effects Dictionary 的數值變化套用到 GameManager。
## 已知欄位：money、reputation、staff_morale、custom。
## custom 為文字描述，不直接操作，僅記錄 log 提供 UI 使用。
func _apply_effects(effects: Dictionary, event_id: String) -> void:
	# 金錢效果
	if effects.has("money"):
		var delta_money: float = float(effects["money"])
		if delta_money > 0.0:
			if GameManager.has_method("add_money"):
				GameManager.add_money(delta_money)
			else:
				push_warning("[EventManager] GameManager 沒有 add_money 方法，事件 %s 的金錢增加效果未套用" % event_id)
		elif delta_money < 0.0:
			if GameManager.has_method("spend_money"):
				var success: bool = GameManager.spend_money(-delta_money)
				if not success:
					push_warning("[EventManager] 金錢不足，事件 %s 的支出效果僅部分套用（金錢歸零）" % event_id)
					# 金錢不足時強制歸零而非負值
					if GameManager.has_method("get_money"):
						var current: float = GameManager.get_money()
						if current > 0.0:
							GameManager.spend_money(current)
			else:
				push_warning("[EventManager] GameManager 沒有 spend_money 方法，事件 %s 的金錢扣除效果未套用" % event_id)

	# 名聲效果
	if effects.has("reputation"):
		var delta_rep: int = int(effects["reputation"])
		if delta_rep > 0:
			if GameManager.has_method("add_reputation"):
				GameManager.add_reputation(delta_rep)
			else:
				push_warning("[EventManager] GameManager 沒有 add_reputation 方法，事件 %s 的名聲增加效果未套用" % event_id)
		elif delta_rep < 0:
			if GameManager.has_method("reduce_reputation"):
				GameManager.reduce_reputation(-delta_rep)
			else:
				push_warning("[EventManager] GameManager 沒有 reduce_reputation 方法，事件 %s 的名聲扣除效果未套用" % event_id)

	# 員工士氣效果
	if effects.has("staff_morale"):
		var delta_morale: float = float(effects["staff_morale"])
		if delta_morale > 0.0:
			GameManager.add_staff_morale(delta_morale)
		elif delta_morale < 0.0:
			GameManager.reduce_staff_morale(-delta_morale)

	# custom 效果為文字描述，由 UI 層讀取 option["effects"]["custom"] 顯示，不在此處執行
	if effects.has("custom"):
		print("[EventManager] 事件 %s 自定義效果：%s" % [event_id, effects["custom"]])


# ============================================================
# 內部方法：佇列管理
# ============================================================

## 若目前沒有事件正在顯示，從佇列取出下一個事件並推送給 UI。
func _flush_queue() -> void:
	if _is_showing_event:
		return
	if _pending_queue.is_empty():
		return

	var next_id: String = _pending_queue.pop_front()

	if not _events_cache.has(next_id):
		# 資料已移除，跳到下一個
		_flush_queue()
		return

	_is_showing_event = true
	_triggered_today.append(next_id)

	# 暫停遊戲時間推進，讓玩家有時間閱讀事件對話
	if GameManager.has_method("pause_time"):
		GameManager.pause_time()
	else:
		get_tree().paused = true
		push_warning("[EventManager] GameManager 沒有 pause_time 方法，改用 get_tree().paused")

	event_triggered.emit(_events_cache[next_id])
	print("[EventManager] 觸發事件：%s（%s）" % [next_id, _events_cache[next_id].get("name", "?")])


## 玩家呼叫 apply_option 後，若需要恢復遊戲，在此統一處理。
## 注意：resume 由 apply_option 呼叫後的 _flush_queue 流程決定時機。
## 若佇列已空，才恢復時間推進。
func _resume_game_if_idle() -> void:
	if _pending_queue.is_empty() and not _is_showing_event:
		if GameManager.has_method("resume_time"):
			GameManager.resume_time()
		else:
			get_tree().paused = false


# ============================================================
# 信號處理
# ============================================================

## 每日結束時清空今日觸發紀錄，使同一事件明天可以再次觸發。
func _on_day_ended(_income: float) -> void:
	_triggered_today.clear()
	# 每日結束時若有殘留佇列也一併清空（防止跨日堆積）
	_pending_queue.clear()
	_is_showing_event = false


# ============================================================
# 工具方法（供外部查詢使用）
# ============================================================

## 取得單一事件資料（供 UI 層讀取 dialog、options 等詳細欄位）。
## 找不到時回傳空 Dictionary。
func get_event_data(event_id: String) -> Dictionary:
	return _events_cache.get(event_id, {})


## 取得所有已載入的事件 id 列表。
func get_all_event_ids() -> Array:
	return _events_cache.keys()


## 回傳事件系統是否已成功載入資料。
func is_loaded() -> bool:
	return not _events_cache.is_empty()
