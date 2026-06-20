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

## 每日語錄就緒時發出，HUD 監聽此信號以顯示語錄文字。
signal daily_quote_ready(quote: String)


# ============================================================
# 常數
# ============================================================

const EVENTS_JSON_PATH: String = "res://resources/data/events.json"

## 每日語錄（25 句，台灣熱炒店風格）
## 分四類：阿龍語錄、今日推薦、天氣吐槽、客人觀察
const DAILY_QUOTES: Array[String] = [
	# 阿龍語錄（6 句）——關於廚藝、食材、堅持的短句，嘴硬但有哲理
	"【阿龍語錄】大火要快，小火要穩，人生也是這樣。",
	"【阿龍語錄】食材這種東西，你尊重它，它才尊重你。",
	"【阿龍語錄】鍋鏟翻慢了不是問題，心浮氣躁才是問題。",
	"【阿龍語錄】一道菜要好吃，最後那口醬油加多少，才是功夫所在。",
	"【阿龍語錄】九層塔要最後才放。這不是規定，這是尊重。",
	"【阿龍語錄】炒菜沒有捷徑，但有竅門。差別在於，你肯不肯慢慢等自己熟。",
	# 今日推薦（6 句）——某道菜的推薦，帶出食材故事，口氣像手寫黑板
	"【今日推薦】三杯雞。九層塔今早剛到，香到鄰居探頭問說是不是有拜拜。",
	"【今日推薦】炒蛤蜊。蛤仔是今天清晨從漁港直送，吐沙完全，逆嘛放心。",
	"【今日推薦】皮蛋豆腐。豆腐用嫩的，皮蛋切要快，醬油膏不要省。",
	"【今日推薦】薑絲大腸。大腸滷兩小時以上，薑絲夠嗆，係配台啤的神。",
	"【今日推薦】蒜炒高麗菜。今天的高麗菜是市場阿伯說最後一批，買到就是賺到。",
	"【今日推薦】鹽酥雞。醃了一個晚上，地瓜粉裹兩層，炸起來才會那個脆。",
	# 天氣吐槽（7 句）——台灣天氣的吐槽，轉化成熱炒的氛圍語
	"【今日天氣】颱風前夕，風涼了，正是喝台啤的好時候。",
	"【今日天氣】梅雨季，外面下到不要不要，店裡的爐火反而更旺。",
	"【今日天氣】大暑，台北比鍋子還燙。但熱炒嘛，就是要那個熱氣才對味。",
	"【今日天氣】今天涼颼颼，阿龍師傅說這種天氣炒出來的空心菜特別甜。",
	"【今日天氣】午後雷陣雨，客人淋著雨衝進來，說什麼都要吃熱的。我們懂。",
	"【今日天氣】東北季風來了，外面冷，裡面的爐火配台啤，剛剛好。",
	"【今日天氣】天氣預報說要熱到 38 度。歹命，但爐子不能關，客人不會少。",
	# 客人觀察（6 句）——外場視角的小觀察，溫暖或幽默
	"【客人觀察】有對老夫婦，每週四都來坐同一張桌。點同樣的菜，話不多，但吃完都笑著走。",
	"【客人觀察】今天來了個西裝筆挺的客人，坐下來第一句話是「給我一瓶台啤」，好ㄟ，是自己人。",
	"【客人觀察】一個媽媽帶著小孩來，小孩說長大要當廚師。阿龍師傅聽到，嘴硬說「免，炒菜很累」，但臉有笑。",
	"【客人觀察】有客人說我們的三杯雞比他媽媽煮的還好吃。老闆娘說謝謝，心裡想，這句話我們收下了。",
	"【客人觀察】昨晚有桌客人喝到最後一個人，他說沒關係，他習慣了。老闆娘多給他一盤花枝，沒說原因。",
	"【客人觀察】有個阿北每次來都說「今天最後一次」，然後明天又出現了。我們已經不問了。",
]

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

## 記錄每個事件的最後觸發遊戲天數（用於 7 天冷卻）
var _event_last_triggered_day: Dictionary = {}

## 事件冷卻天數
const EVENT_COOLDOWN_DAYS: int = 7


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_load_events()
	call_deferred("_connect_signals")

func _connect_signals() -> void:
	GameManager.day_ended.connect(_on_day_ended)
	GameManager.day_started.connect(_on_day_started_quote)


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

	# 取得目前遊戲天數（供冷卻期判斷使用）
	var gm_cd := get_node_or_null("/root/GameManager")
	var current_game_day: int = gm_cd.current_day if gm_cd != null else 1

	for event_id: String in _events_cache:
		# 已在今日觸發過的事件跳過
		if event_id in _triggered_today:
			continue

		# 冷卻期判斷（同一事件 7 天內不重複）
		if _event_last_triggered_day.has(event_id):
			var last_day: int = _event_last_triggered_day[event_id]
			if current_game_day - last_day < EVENT_COOLDOWN_DAYS:
				continue  # 冷卻中，跳過

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

	# 顯示選擇結果回饋
	var option_data: Dictionary = options[option_index]
	var effects_data: Dictionary = option_data.get("effects", {})
	var feedback_parts: Array = []
	if effects_data.has("money"):
		var m: float = float(effects_data["money"])
		if m > 0:
			feedback_parts.append("收入 +$%d" % int(m))
		elif m < 0:
			feedback_parts.append("支出 $%d" % int(-m))
	if effects_data.has("reputation"):
		var r: int = int(effects_data["reputation"])
		if r > 0:
			feedback_parts.append("名聲 +%d" % r)
		elif r < 0:
			feedback_parts.append("名聲 %d" % r)
	if effects_data.has("custom"):
		feedback_parts.append(str(effects_data["custom"]))
	if not feedback_parts.is_empty():
		var feedback_msg: String = "結果：" + "，".join(feedback_parts)
		var hud_nodes: Array[Node] = get_tree().get_nodes_in_group("hud")
		for hud_node: Node in hud_nodes:
			if hud_node.has_method("_show_message"):
				hud_node._show_message(feedback_msg, 4.0)
				break
		print("[EventManager] 選擇回饋：%s" % feedback_msg)

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

	# 記錄觸發天數（7天冷卻）
	var gm_flush := get_node_or_null("/root/GameManager")
	if gm_flush != null:
		_event_last_triggered_day[next_id] = gm_flush.current_day

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

	# 每日結束後自動輪詢觸發條件，取一個事件觸發
	_auto_trigger_daily_event()


## 每日自動觸發一個隨機事件（從符合條件的事件中選一個）
func _auto_trigger_daily_event() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return
	var game_state: Dictionary = {
		"year": gm.current_year,
		"day": gm.current_day,
		"reputation": gm.reputation,
		"is_open": false,  # 已打烊
	}
	var eligible: Array = check_triggers(game_state)
	if eligible.is_empty():
		print("[EventManager] 今日無符合條件的事件")
		return
	# 隨機選一個觸發
	var selected_id: String = eligible[randi() % eligible.size()]
	print("[EventManager] 今日自動觸發事件：%s" % selected_id)
	# 延遲 1 秒觸發，讓結算面板先顯示
	await get_tree().create_timer(1.0).timeout
	trigger_event(selected_id)


## 每日開始時呼叫，隨機取一句語錄並發出信號。
func _on_day_started_quote(_year: int, _day: int) -> void:
	emit_daily_quote()


## 隨機取一句每日語錄並發出 daily_quote_ready 信號。
## 可由外部直接呼叫（例如測試用途）。
func emit_daily_quote() -> void:
	if DAILY_QUOTES.is_empty():
		return
	var idx: int = randi() % DAILY_QUOTES.size()
	daily_quote_ready.emit(DAILY_QUOTES[idx])


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


# ============================================================
# 事件選擇 UI
# ============================================================

## 顯示事件選擇面板（A/B 選擇按鈕）。
## event_data 為完整事件 Dictionary（含 id、name、dialog、options 等欄位）。
## 通常由 event_triggered 信號的接收方呼叫，或直接傳入 event_id 取資料後呼叫。
func show_event_choice(event_data: Dictionary) -> void:
	var event_id: String = event_data.get("id", "")
	var event_name: String = event_data.get("name", "事件")
	var event_dialog: String = event_data.get("dialog", "")
	var options: Array = event_data.get("options", [])

	# 若無選項，不需顯示面板（由 hud 的 _on_event_triggered 處理純訊息型事件）
	if options.is_empty():
		return

	# 建立 CanvasLayer（layer=6，高於 HUD=1、Dialog=2、MenuUI=5）
	var cl := CanvasLayer.new()
	cl.layer = 6
	get_tree().root.add_child(cl)

	# 半透明背景
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.size = Vector2(480, 270)
	dim.position = Vector2.ZERO
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	cl.add_child(dim)

	# 面板大小依選項數動態計算
	const PW: float = 320.0
	const HEADER_H: float = 58.0
	const BTN_H: float = 28.0
	const BTN_GAP: float = 6.0
	var panel_h: float = HEADER_H + options.size() * (BTN_H + BTN_GAP) + 12.0
	var panel_x: float = (480.0 - PW) * 0.5
	var panel_y: float = (270.0 - panel_h) * 0.5

	var panel_bg := ColorRect.new()
	panel_bg.color = Color(0.102, 0.102, 0.180, 0.95)
	panel_bg.size = Vector2(PW, panel_h)
	panel_bg.position = Vector2(panel_x, panel_y)
	cl.add_child(panel_bg)

	# 嘗試載入字體
	var font_path := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf"
	var ef: Font = null
	if ResourceLoader.exists(font_path):
		ef = load(font_path)

	# 事件名稱標題
	var title_lbl := Label.new()
	title_lbl.text = event_name
	title_lbl.position = Vector2(panel_x + 12, panel_y + 8)
	title_lbl.size = Vector2(PW - 24, 16)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0))
	title_lbl.add_theme_font_size_override("font_size", 12)
	if ef:
		title_lbl.add_theme_font_override("font", ef)
	cl.add_child(title_lbl)

	# 分隔線
	var sep := ColorRect.new()
	sep.color = Color(1.0, 0.843, 0.0)
	sep.size = Vector2(PW - 24, 1)
	sep.position = Vector2(panel_x + 12, panel_y + 26)
	cl.add_child(sep)

	# 事件說明文字
	var desc_lbl := Label.new()
	desc_lbl.text = event_dialog
	desc_lbl.position = Vector2(panel_x + 12, panel_y + 30)
	desc_lbl.size = Vector2(PW - 24, 24)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96))
	desc_lbl.add_theme_font_size_override("font_size", 9)
	if ef:
		desc_lbl.add_theme_font_override("font", ef)
	cl.add_child(desc_lbl)

	# 選項按鈕
	for i in range(options.size()):
		var option: Dictionary = options[i]
		var option_text: String = option.get("text", "選項 %d" % (i + 1))
		var btn_y: float = panel_y + HEADER_H + i * (BTN_H + BTN_GAP)

		var opt_btn := Button.new()
		opt_btn.text = option_text
		opt_btn.position = Vector2(panel_x + 16, btn_y)
		opt_btn.size = Vector2(PW - 32, BTN_H)
		opt_btn.add_theme_font_size_override("font_size", 9)
		opt_btn.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96))
		if ef:
			opt_btn.add_theme_font_override("font", ef)
		var captured_index: int = i
		var captured_id: String = event_id
		opt_btn.pressed.connect(func() -> void:
			apply_option(captured_id, captured_index)
			cl.queue_free()
		)
		cl.add_child(opt_btn)
