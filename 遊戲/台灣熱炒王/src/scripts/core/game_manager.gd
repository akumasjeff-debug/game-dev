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

## 第一次收到付款（amount >= 50 才觸發，避免測試用小額誤觸）
signal first_payment_received

## 特殊時段事件信號（hour：遊戲時刻，message：顯示訊息）
signal hour_milestone_reached(hour: int, message: String)

## 升級點數變動
signal upgrade_points_changed(new_points: int)


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

## 升級點數（每賺 $1,000 得 1 點）
var upgrade_points: int = 0


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
var _first_payment_done: bool = false


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_initialize_default_state()
	if SaveManager.has_save_file():
		var save_data: Dictionary = SaveManager.load_game()
		if not save_data.is_empty():
			var gd: Dictionary = save_data.get("game_data", {})
			if not gd.is_empty():
				apply_save_data(gd)
				print("[GameManager] 存檔讀取完成：Year %d Day %d" % [current_year, current_day])
			else:
				print("[GameManager] 存檔 game_data 為空，使用預設值")
		else:
			print("[GameManager] 存檔讀取失敗，使用預設值")
	else:
		print("[GameManager] 無既有存檔，使用預設值（新遊戲）")


## 套用預設初始狀態（新遊戲）
func _initialize_default_state() -> void:
	current_year = 1
	current_day = 1
	current_hour = 17.5  # 從 17:30 開始，避免第一幀觸發 day_started
	is_open = false
	money = 10000.0
	reputation = 0
	staff_morale = 100.0
	_today_income = 0.0
	_hour_accumulator = 0.0
	_low_morale_penalty_active = false
	_first_payment_done = false


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

	# 特殊時段提示（在歸零之前判斷，確保 hour_int 正確）
	match hour_int:
		17:
			if not was_open:  # 只在剛開門時發出
				hour_milestone_reached.emit(17, "開門！熱炒王正式營業")
		22:
			if was_open:      # 確認在營業中
				hour_milestone_reached.emit(22, "宵夜時段，客人多但也更晚")

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
	# 播放開門音效（17:00）
	var am := get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		var sfx_enter := "res://assets/audio/sfx/customer_enter.wav"
		if ResourceLoader.exists(sfx_enter):
			am.play_sfx(load(sfx_enter))


## 每日結束處理
func _on_day_ended() -> void:
	is_open = false
	hour_milestone_reached.emit(26, "今天打烊了")
	day_ended.emit(_today_income)
	# 打烊：BGM 音量用 Tween 淡出到 0.2（歷時 2 秒）
	var am_fade := get_node_or_null("/root/AudioManager")
	if am_fade != null and am_fade.has_method("fade_bgm"):
		am_fade.fade_bgm(0.2, 2.0)

	# 員工士氣低下懲罰（士氣 < 30 時效率 -20%，由各 AI 系統讀取此旗標）
	if staff_morale < 30.0:
		_low_morale_penalty_active = true
	else:
		_low_morale_penalty_active = false

	var saved: bool = SaveManager.auto_save(export_save_data())
	if not saved:
		push_warning("[GameManager] 自動存檔失敗（Day %d）" % current_day)
	else:
		print("[GameManager] 自動存檔完成（Day %d）" % current_day)
	# TODO: 通知結算 UI 顯示今日收支

	# 推進日數
	current_day += 1

	# 檢查是否進入新年份（每 90 天算一年，對應 Q1/Q2/Q3/Q4 四季節奏）
	if current_day % 90 == 0:
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

	# 升級點數：每累積 $1000 賺取 1 點
	var old_threshold: int = int((_today_income - amount) / 1000.0)
	var new_threshold: int = int(_today_income / 1000.0)
	if new_threshold > old_threshold:
		upgrade_points += (new_threshold - old_threshold)
		upgrade_points_changed.emit(upgrade_points)

	# 第一次收到付款（>= 50 元才算，避免測試觸發）
	if not _first_payment_done and amount >= 50.0:
		_first_payment_done = true
		first_payment_received.emit()


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
func export_save_data() -> Dictionary:
	return {
		"year": current_year,
		"day": current_day,
		"hour": current_hour,
		"money": money,
		"reputation": reputation,
		"staff_morale": staff_morale,
		"upgrade_points": upgrade_points,
	}


## 套用存檔資料（從 SaveManager 讀入）
func apply_save_data(data: Dictionary) -> void:
	current_year = data.get("year", 1)
	current_day = data.get("day", 1)
	# 強制設為 17.5，避免讀入存檔時的 hour 值觸發首幀 day_started（例如 hour=17.0 或 0.0）
	current_hour = 17.5
	money = data.get("money", 10000.0)
	reputation = data.get("reputation", 0)
	staff_morale = data.get("staff_morale", 100.0)
	upgrade_points = data.get("upgrade_points", 0)
	money_changed.emit(money)
	reputation_changed.emit(reputation)
	staff_morale_changed.emit(staff_morale)


## 手動存檔（供主選單、暫停畫面呼叫）
## 回傳 true 表示成功，false 表示失敗
func save_now() -> bool:
	var result: bool = SaveManager.save_game(export_save_data())
	print("[GameManager] 手動存檔 %s" % ("成功" if result else "失敗"))
	return result


# ============================================================
# 升級系統
# ============================================================

## 廚師速度 +20%（花 5 點）
var _chef_speed_level: int = 0
func upgrade_chef_speed() -> bool:
	const COST: int = 5
	if upgrade_points < COST:
		return false
	upgrade_points -= COST
	_chef_speed_level += 1
	upgrade_points_changed.emit(upgrade_points)
	return true

func get_chef_speed_multiplier() -> float:
	return 1.0 + _chef_speed_level * 0.2

## 座位數 +2（花 8 點）
func upgrade_seating() -> bool:
	const COST: int = 8
	if upgrade_points < COST:
		return false
	upgrade_points -= COST
	upgrade_points_changed.emit(upgrade_points)
	return true

## 菜色品質 +10%（花 6 點）
var _quality_level: int = 0
func upgrade_dish_quality() -> bool:
	const COST: int = 6
	if upgrade_points < COST:
		return false
	upgrade_points -= COST
	_quality_level += 1
	upgrade_points_changed.emit(upgrade_points)
	return true

func get_dish_quality_multiplier() -> float:
	return 1.0 + _quality_level * 0.1
