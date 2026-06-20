## GameManager.gd
## AutoLoad Singleton — 遊戲狀態總管
## 負責：時間推進、資源管理、跨系統協調
## 在 project.godot 設定為 AutoLoad（名稱：GameManager）

extends Node


# ============================================================
# 信號定義
# ============================================================

## 每日開始（傳入當前年份與日數）
signal day_started(year: int, day: int)

## 每日結束（傳入當天總收入）
signal day_ended(income: float)

## 年份推進
signal year_ended(year: int)

## 金錢變動（傳入變動後的金額）
signal money_changed(new_amount: float)

## 名聲變動（傳入變動後的名聲值）
signal reputation_changed(new_value: int)

## 員工士氣變動（傳入變動後的士氣值）
signal staff_morale_changed(new_value: float)

## 遊戲暫停/繼續
signal game_paused
signal game_resumed


# ============================================================
# 遊戲狀態變數
# ============================================================

## 當前遊戲年份（從 1 開始）
var current_year: int = 1

## 當前遊戲日（累積天數，不跨年重置）
var current_day: int = 1

## 當前小時（0~23，決定營業時間）
var current_hour: float = 0.0

## 是否正在營業中
var is_open: bool = false

## 資金（新台幣遊戲幣）
var money: float = 10000.0

## 名聲值（0~1000）
var reputation: int = 0

## 員工士氣（0~100）
var staff_morale: float = 100.0

## 是否暫停時間推進
var time_paused: bool = false

## 時間加速倍率（1.0 = 正常，2.0 = 兩倍速）
var time_scale: float = 1.0


# ============================================================
# 時間系統常數
# ============================================================

## 遊戲中 1 小時對應現實秒數
const SECONDS_PER_GAME_HOUR: float = 30.0

## 營業開始時間（17:00）
const OPEN_HOUR: int = 17

## 營業結束時間（次日 02:00，用 26 表示跨日）
const CLOSE_HOUR: int = 26

## 名聲上限
const REPUTATION_MAX: int = 1000

## 名聲下限
const REPUTATION_MIN: int = 0


# ============================================================
# 內部時間累積器
# ============================================================

var _hour_accumulator: float = 0.0
var _today_income: float = 0.0
var _low_morale_penalty_active: bool = false


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	# TODO: 整合 SaveManager 後，在此呼叫 load_game()
	# 例：var save_data = SaveManager.load_game()
	#     if not save_data.is_empty(): _apply_save_data(save_data)
	_initialize_default_state()
	print("[GameManager] 初始化完成，Year %d Day %d" % [current_year, current_day])


## 套用預設初始狀態（新遊戲）
func _initialize_default_state() -> void:
	current_year = 1
	current_day = 1
	current_hour = 8.0   # 早上 8 點開始（還未營業）
	is_open = false
	money = 10000.0
	reputation = 0
	staff_morale = 100.0
	_today_income = 0.0
	_hour_accumulator = 0.0
	_low_morale_penalty_active = false


# ============================================================
# 主循環：時間推進
# ============================================================

func _process(delta: float) -> void:
	if time_paused:
		return
	tick(delta)


## 時間推進核心函式
## delta：每幀經過的秒數（已乘上 time_scale 倍率）
func tick(delta: float) -> void:
	var scaled_delta: float = delta * time_scale
	_hour_accumulator += scaled_delta

	# 每累積足夠時間，推進一小時
	while _hour_accumulator >= SECONDS_PER_GAME_HOUR:
		_hour_accumulator -= SECONDS_PER_GAME_HOUR
		_advance_one_hour()


## 推進一小時邏輯
## current_hour 以累積方式增長（17→26 為營業區間，26 = 凌晨 2 點）。
## 達到 CLOSE_HOUR（26）時觸發結算，再減去 26 歸零，不在 24 時提前歸零。
func _advance_one_hour() -> void:
	current_hour += 1.0

	# 更新營業狀態
	var hour_int: int = int(current_hour)
	var was_open: bool = is_open
	is_open = (hour_int >= OPEN_HOUR and hour_int < CLOSE_HOUR)

	# 偵測今日開始（17:00 開門）
	if hour_int == OPEN_HOUR and not was_open:
		_on_day_started()

	# 偵測今日結束（凌晨 2 點關門，hour 累積至 26）
	# 必須在歸零之前判斷，否則 hour_int 已歸零永遠 < 26
	if hour_int >= CLOSE_HOUR and was_open:
		_on_day_ended()

	# 達到凌晨 2 點（26 小時）才歸零，保持跨日累積正確
	if current_hour >= float(CLOSE_HOUR):
		current_hour -= float(CLOSE_HOUR)


## 每日開始處理
func _on_day_started() -> void:
	_today_income = 0.0
	# TODO: 通知 CustomerSpawner 開始生成客人
	# TODO: 通知 StaffManager 員工就位
	day_started.emit(current_year, current_day)
	print("[GameManager] Day %d Year %d 開始營業" % [current_day, current_year])


## 每日結束處理
func _on_day_ended() -> void:
	is_open = false
	day_ended.emit(_today_income)

	# 員工士氣低下懲罰（士氣 < 30 時效率 -20%，由各 AI 系統讀取此旗標）
	if staff_morale < 30.0:
		_low_morale_penalty_active = true
	else:
		_low_morale_penalty_active = false

	# TODO: 呼叫 SaveManager.save_game() 自動存檔
	# TODO: 通知結算 UI 顯示今日收支

	# 推進日數
	current_day += 1

	# 檢查是否進入新年份（每 30 天算一年）
	# TODO: 正式年份推進條件由數值企劃的 progression-design.md 確認
	if current_day % 30 == 0:
		_on_year_ended()

	print("[GameManager] 今日結束，收入：NT$%.0f" % _today_income)


## 年份結束處理
func _on_year_ended() -> void:
	year_ended.emit(current_year)
	current_year += 1
	# TODO: 通知解鎖系統檢查新年份解鎖內容
	print("[GameManager] 進入第 %d 年" % current_year)


# ============================================================
# 金錢操作（帶邊界檢查）
# ============================================================

## 取得當前金錢
func get_money() -> float:
	return money


## 增加金錢（收入）
## amount：金額（必須 > 0）
func add_money(amount: float) -> void:
	if amount <= 0.0:
		push_warning("[GameManager] add_money 收到非正值：%.2f" % amount)
		return
	money += amount
	_today_income += amount
	money_changed.emit(money)


## 扣除金錢（支出）
## amount：金額（必須 > 0）
## 回傳 true 表示成功扣款，false 表示金錢不足
func spend_money(amount: float) -> bool:
	if amount <= 0.0:
		push_warning("[GameManager] spend_money 收到非正值：%.2f" % amount)
		return false
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	return true


## 檢查是否有足夠金錢
func has_enough_money(amount: float) -> bool:
	return money >= amount


# ============================================================
# 名聲操作（帶邊界檢查，0~1000）
# ============================================================

## 取得當前名聲
func get_reputation() -> int:
	return reputation


## 增加名聲
## amount：增加量（必須 > 0）
func add_reputation(amount: int) -> void:
	if amount <= 0:
		push_warning("[GameManager] add_reputation 收到非正值：%d" % amount)
		return
	reputation = clampi(reputation + amount, REPUTATION_MIN, REPUTATION_MAX)
	reputation_changed.emit(reputation)


## 扣除名聲
## amount：扣除量（必須 > 0）
func reduce_reputation(amount: int) -> void:
	if amount <= 0:
		push_warning("[GameManager] reduce_reputation 收到非正值：%d" % amount)
		return
	reputation = clampi(reputation - amount, REPUTATION_MIN, REPUTATION_MAX)
	reputation_changed.emit(reputation)


# ============================================================
# 員工士氣操作（帶邊界檢查，0~100）
# ============================================================

## 取得當前員工士氣
func get_staff_morale() -> float:
	return staff_morale


## 增加員工士氣
## amount：增加量（必須 > 0）
func add_staff_morale(amount: float) -> void:
	if amount <= 0.0:
		push_warning("[GameManager] add_staff_morale 收到非正值：%.2f" % amount)
		return
	staff_morale = clampf(staff_morale + amount, 0.0, 100.0)
	staff_morale_changed.emit(staff_morale)


## 扣除員工士氣
## amount：扣除量（必須 > 0）
func reduce_staff_morale(amount: float) -> void:
	if amount <= 0.0:
		push_warning("[GameManager] reduce_staff_morale 收到非正值：%.2f" % amount)
		return
	staff_morale = clampf(staff_morale - amount, 0.0, 100.0)
	staff_morale_changed.emit(staff_morale)


## 取得士氣低下懲罰旗標（士氣 < 30 時為 true，由各 AI 系統讀取）
func is_low_morale_penalty_active() -> bool:
	return _low_morale_penalty_active


# ============================================================
# 時間控制
# ============================================================

## 暫停時間推進
func pause_time() -> void:
	time_paused = true
	game_paused.emit()


## 繼續時間推進
func resume_time() -> void:
	time_paused = false
	game_resumed.emit()


## 設定時間倍率（1.0/2.0/4.0）
func set_time_scale(scale: float) -> void:
	time_scale = clampf(scale, 0.0, 4.0)


## 取得目前遊戲時間（格式化字串，例："17:30"）
func get_time_string() -> String:
	var h: int = int(current_hour) % 24
	var m: int = int((current_hour - int(current_hour)) * 60)
	return "%02d:%02d" % [h, m]


# ============================================================
# 存檔整合介面（預留）
# ============================================================

## 匯出存檔資料（給 SaveManager 呼叫）
## TODO: SaveManager 整合後補充此函式
func export_save_data() -> Dictionary:
	return {
		"year": current_year,
		"day": current_day,
		"money": money,
		"reputation": reputation,
		"staff_morale": staff_morale,
	}


## 套用存檔資料（從 SaveManager 讀入）
## TODO: SaveManager 整合後補充此函式
func apply_save_data(data: Dictionary) -> void:
	current_year = data.get("year", 1)
	current_day = data.get("day", 1)
	money = data.get("money", 10000.0)
	reputation = data.get("reputation", 0)
	staff_morale = data.get("staff_morale", 100.0)
	money_changed.emit(money)
	reputation_changed.emit(reputation)
	staff_morale_changed.emit(staff_morale)
