## TutorialManager.gd
## AutoLoad singleton — 管理 Day 1 教學步驟序列
## 職責：追蹤步驟進度、發送步驟變更信號、教學保護狀態維護
## 對外 API：start_tutorial()、complete_current_step(condition_id)、
##            get_current_step()、is_active()

extends Node

# ── 信號 ──────────────────────────────────────────────────────────────
## 步驟切換時發出；UI 層監聽此信號更新對話框、高亮、提示
signal step_changed(step_number: int, step_data: Dictionary)
## Day 1 全部步驟完成時發出
signal tutorial_day1_complete

# ── 狀態變數 ──────────────────────────────────────────────────────────
## 步驟資料清單，由 _build_day1_steps() 填入
var _steps: Array = []

## 當前步驟索引；-1 表示教學尚未啟動
var current_step_index: int = -1

## 教學是否進行中
var is_tutorial_active: bool = false

## 教學保護旗標：Day 1 期間名聲只加不減
## Day 1 完成後設為 false，由名聲系統讀取此值決定是否套用保護
var tutorial_protection_active: bool = true

# ── 生命週期 ──────────────────────────────────────────────────────────
func _ready() -> void:
	_build_day1_steps()

	# 監聽 GameManager 的 day_started 信號，Year 1 Day 1 自動啟動教學
	if GameManager.has_signal("day_started"):
		GameManager.day_started.connect(_on_game_day_started)

	print("[TutorialManager] 初始化完成，共 %d 步驟" % _steps.size())

# ── 公開 API ──────────────────────────────────────────────────────────

## 啟動 Day 1 教學。通常由 _on_game_day_started 自動呼叫；也可從外部強制呼叫。
func start_tutorial() -> void:
	if is_tutorial_active:
		push_warning("[TutorialManager] start_tutorial() 呼叫時教學已在進行中，忽略。")
		return

	current_step_index = 0
	is_tutorial_active = true
	tutorial_protection_active = true

	var step_data: Dictionary = _steps[current_step_index]
	print("[TutorialManager] 教學開始，第 %d 步：%s" % [step_data["step"], step_data["trigger"]])
	step_changed.emit(step_data["step"], step_data)

## 外部系統呼叫此方法通知「某個條件已滿足」。
## condition_id 必須與當前步驟的 complete_condition 相符，否則忽略。
func complete_current_step(condition_id: String) -> void:
	if not is_tutorial_active:
		return

	if current_step_index < 0 or current_step_index >= _steps.size():
		return

	var current: Dictionary = _steps[current_step_index]
	if condition_id != current["complete_condition"]:
		# 條件不匹配，忽略（允許遊戲自由發出各種事件）
		return

	print("[TutorialManager] 步驟 %d 完成，條件：%s" % [current["step"], condition_id])
	_advance_step()

## 回傳當前步驟的完整資料；若教學尚未開始則回傳空 Dictionary。
func get_current_step() -> Dictionary:
	if not is_tutorial_active or current_step_index < 0 or current_step_index >= _steps.size():
		return {}
	return _steps[current_step_index]

## 回傳教學是否進行中。
func is_active() -> bool:
	return is_tutorial_active

# ── 私有方法 ──────────────────────────────────────────────────────────

## 推進至下一步驟。若已完成最後一步則觸發 Day 1 完成流程。
func _advance_step() -> void:
	current_step_index += 1

	if current_step_index >= _steps.size():
		_on_day1_complete()
		return

	var step_data: Dictionary = _steps[current_step_index]
	print("[TutorialManager] 進入步驟 %d：%s" % [step_data["step"], step_data["trigger"]])
	step_changed.emit(step_data["step"], step_data)

## Day 1 全部步驟完成後的後續動作。
func _on_day1_complete() -> void:
	is_tutorial_active = false
	tutorial_protection_active = false
	print("[TutorialManager] Day 1 教學完成，解除教學保護，觸發開業補貼事件。")

	# 觸發開業補貼事件（event_subsidy 為 EventManager 中已定義的事件 ID）
	if EventManager.has_method("trigger_event"):
		EventManager.trigger_event("event_subsidy")

	tutorial_day1_complete.emit()

## GameManager.day_started 信號的接收函式。
## Year 1 Day 1 且教學尚未啟動時自動開始教學。
func _on_game_day_started(year: int, day: int) -> void:
	if year == 1 and day == 1 and not is_tutorial_active:
		start_tutorial()

## 建立 Day 1 的 9 個步驟資料清單。
func _build_day1_steps() -> void:
	_steps = [
		# ── 步驟 1：認識你的店 ──────────────────────────────────────
		# 觸發：遊戲首次啟動載入完成
		# 完成：點擊螢幕任意位置
		{
			"step": 1,
			"trigger": "on_game_start",
			"dialog_speaker": "阿龍師傅",
			"dialog_text": "妳就是新老闆娘？好，我先帶妳看一下我們這間店。",
			"highlight_node": "",       # 整個地圖高亮由 UI 層依空字串判斷處理
			"complete_condition": "on_screen_tapped",
			"lock_input": false,
		},
		# ── 步驟 2：開門！第一組客人來了 ────────────────────────────
		# 觸發：步驟 1 完成後自動進入 17:00
		# 完成：點擊「開門」按鈕
		{
			"step": 2,
			"trigger": "on_step1_complete",
			"dialog_speaker": "老闆娘",
			"dialog_text": "好，時間到了，開門開門！",
			"highlight_node": "hud_layer/btn_open_door",
			"complete_condition": "on_door_opened",
			"lock_input": true,
		},
		# ── 步驟 3：帶客入座 ─────────────────────────────────────────
		# 觸發：開門後第一組客人（2 人老街坊）出現在入口
		# 完成：客人走到方桌並坐下（AI 自動執行）
		{
			"step": 3,
			"trigger": "on_step2_complete",
			"dialog_speaker": "阿龍師傅",
			"dialog_text": "來了來了，老街坊。他們會自己找桌子坐，妳看著。",
			"highlight_node": "",
			"complete_condition": "on_customer_seated",
			"lock_input": false,
		},
		# ── 步驟 4：接單！看訂單出現 ────────────────────────────────
		# 觸發：客人坐下後訂單氣泡出現
		# 完成：點擊訂單氣泡（或 3 秒後自動推進）
		{
			"step": 4,
			"trigger": "on_step3_complete",
			"dialog_speaker": "阿龍師傅",
			"dialog_text": "三杯雞一份、啤酒兩罐。好，我去炒。",
			"highlight_node": "game_layer/order_bubble",
			"complete_condition": "on_order_viewed",
			"lock_input": false,
		},
		# ── 步驟 5：看阿龍師傅炒菜 ──────────────────────────────────
		# 觸發：訂單確認後廚房出現烹飪進度條
		# 完成：烹飪進度條跑完，三杯雞完成
		{
			"step": 5,
			"trigger": "on_step4_complete",
			"dialog_speaker": "系統",
			"dialog_text": "廚師正在烹飪。進度條跑完就可以出菜了。",
			"highlight_node": "game_layer/wok_progress_bar",
			"complete_condition": "on_cooking_done",
			"lock_input": false,
		},
		# ── 步驟 6：送餐 ─────────────────────────────────────────────
		# 觸發：三杯雞完成出現在出菜台
		# 完成：點擊出菜台送餐
		{
			"step": 6,
			"trigger": "on_step5_complete",
			"dialog_speaker": "老闆娘",
			"dialog_text": "好，我去端過去！",
			"highlight_node": "game_layer/serving_counter",
			"complete_condition": "on_dish_served",
			"lock_input": true,
		},
		# ── 步驟 7：收款，看日結算 ───────────────────────────────────
		# 觸發：客人用餐完畢離席
		# 完成：點擊收款圖示（或 5 秒後自動收款）
		{
			"step": 7,
			"trigger": "on_step6_complete",
			"dialog_speaker": "老闆娘",
			"dialog_text": "謝謝光臨，慢走！",
			"highlight_node": "hud_layer/btn_cashier",
			"complete_condition": "on_payment_done",
			"lock_input": false,
		},
		# ── 步驟 8：組合加成初體驗 ───────────────────────────────────
		# 觸發：Day 1 第三組客人結帳且該桌含三杯雞 + 台啤（固定腳本）
		# 完成：玩家看到組合加成彈出框（無需操作，自動觀看）
		{
			"step": 8,
			"trigger": "on_third_customer_combo",
			"dialog_speaker": "阿龍師傅",
			"dialog_text": "台啤配熱炒，這才是台灣味！記起來，搭對了就有加成。",
			"highlight_node": "",
			"complete_condition": "on_combo_viewed",
			"lock_input": false,
		},
		# ── 步驟 9：打烊與日結算 ─────────────────────────────────────
		# 觸發：Day 1 全部 10 組客人完成服務（或 00:00 自動打烊）
		# 完成：玩家看完日結算並點「確認」
		{
			"step": 9,
			"trigger": "on_step8_complete",
			"dialog_speaker": "老闆娘",
			"dialog_text": "第一天嘛，正常啦。系統說有補貼，收到了。",
			"highlight_node": "",
			"complete_condition": "on_day_settlement_confirmed",
			"lock_input": false,
		},
	]
