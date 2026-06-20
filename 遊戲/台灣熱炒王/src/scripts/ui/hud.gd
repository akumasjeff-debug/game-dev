## hud.gd
## 掛在 UI.tscn 的 hud_layer 節點（或根節點）
## 以程式碼建立 Label，顯示金錢、日期、名聲、即時事件訊息

extends CanvasLayer

## 建造模式切換信號（底部工具列「建造」按鈕觸發）
signal build_mode_toggled


# ============================================================
# 私有成員
# ============================================================

var _money_label: Label
var _day_label: Label
var _time_label: Label
var _reputation_label: Label
var _message_label: Label

## 聲望進度條（背景灰條 + 橘色填充條）
var _reputation_bar_bg: ColorRect = null
var _reputation_bar_fill: ColorRect = null

## 每日語錄 Label
var _quote_label: Label = null

## MenuUI Panel 實例（懶建立）
var _menu_ui: Node = null

## 簡易功能 Panel 清單（一次只顯示一個）
var _active_simple_panel: CanvasLayer = null

var _message_timer: SceneTreeTimer = null
var _time_update_timer: float = 0.0

## 訊息佇列（保留待顯示的訊息）
var _message_queue: Array[Dictionary] = []
## 是否正在顯示訊息
var _message_displaying: bool = false

## 語錄淡出 Tween（保留引用以便提前取消）
var _quote_tween: Tween = null

## 菜單首次開啟旗標（用於首次提示）
var _menu_first_opened: bool = false

## 名聲解鎖提示旗標（達到 10 時只觸發一次）
var _reputation_10_notified: bool = false

## 擺桌按鈕引用（用於零座位時閃爍提示）
var _table_btn: Button = null

## 速度控制（1/2/3x）
var _speed_index: int = 0
const SPEED_VALUES: Array[float] = [1.0, 2.0, 3.0]
const SPEED_LABELS: Array[String] = ["x1", "x2", "x3"]
var _speed_btn: Button = null
var _pause_btn: Button = null
var _is_paused: bool = false
var _pause_overlay: CanvasLayer = null


# ============================================================
# _ready
# ============================================================

func _ready() -> void:
	add_to_group("hud")
	_build_labels()
	_connect_signals()
	# 連接 MenuManager 解鎖信號
	var mm := get_node_or_null("/root/MenuManager")
	if mm != null and mm.has_signal("dish_unlocked"):
		mm.dish_unlocked.connect(_on_dish_unlocked)


# ============================================================
# 主循環：每 5 秒更新時段顯示
# ============================================================

func _process(delta: float) -> void:
	_time_update_timer += delta
	if _time_update_timer >= 5.0:
		_time_update_timer = 0.0
		_refresh_time_label()
	# Esc 鍵 toggle 暫停
	if Input.is_action_just_pressed("ui_cancel"):
		_on_pause_btn_pressed()


## 依 GameManager.current_hour 映射台語時段文字
func _get_time_period(hour: float) -> String:
	var h: int = int(hour)
	if h >= 17 and h < 18:
		return "傍晚"
	elif h >= 18 and h < 20:
		return "晚上"
	elif h >= 20 and h < 22:
		return "宵夜"
	elif h >= 22 or h < 2:  # 22~26（凌晨 2 點前）
		return "深夜"
	elif h >= 2 and h < 17:
		return "打烊"
	else:
		return "未知"


## 刷新時段 Label
func _refresh_time_label() -> void:
	if _time_label == null:
		return
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return
	var time_str: String = gm.get_time_string()  # 例："18:00"
	var period: String = _get_time_period(gm.current_hour)
	_time_label.text = "%s %s" % [time_str, period]


# ============================================================
# 建立 Label 節點
# ============================================================

func _build_labels() -> void:
	# 頂部 HUD 背景色塊（深紫藍）
	var hud_bg := ColorRect.new()
	hud_bg.color = Color(0.07, 0.03, 0.15, 0.97)
	hud_bg.size = Vector2(480, 20)
	hud_bg.position = Vector2(0, 0)
	add_child(hud_bg)

	# 頂部底邊霓虹線（亮橘色）
	var neon_line := ColorRect.new()
	neon_line.color = Color(1.0, 0.42, 0.0, 1.0)
	neon_line.size = Vector2(480, 1)
	neon_line.position = Vector2(0, 20)
	add_child(neon_line)

	_money_label = Label.new()
	_money_label.position = Vector2(6, 4)
	_money_label.text = "$10,000"
	_money_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_money_label)

	_day_label = Label.new()
	_day_label.position = Vector2(120, 4)
	_day_label.text = "第 1 年 第 1 天"
	_day_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_day_label)

	_time_label = Label.new()
	_time_label.position = Vector2(310, 4)
	_time_label.text = "傍晚"
	_time_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_time_label)

	_reputation_label = Label.new()
	_reputation_label.position = Vector2(382, 4)
	_reputation_label.text = "聲望: 0"
	_reputation_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_reputation_label)

	# 聲望進度條（位於聲望 Label 下方，30x3px 細長條）
	_reputation_bar_bg = ColorRect.new()
	_reputation_bar_bg.color = Color(0.3, 0.3, 0.3)
	_reputation_bar_bg.size = Vector2(30, 3)
	_reputation_bar_bg.position = Vector2(382, 16)
	add_child(_reputation_bar_bg)

	_reputation_bar_fill = ColorRect.new()
	_reputation_bar_fill.color = Color(1.0, 0.6, 0.1)  # 橘色
	_reputation_bar_fill.size = Vector2(0, 3)
	_reputation_bar_fill.position = Vector2(382, 16)
	add_child(_reputation_bar_fill)

	_message_label = Label.new()
	_message_label.position = Vector2(8, 258)
	_message_label.text = ""
	_message_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_message_label)

	# 每日語錄 Label（頂部 HUD 下方，畫面頂部中央）
	_quote_label = Label.new()
	_quote_label.position = Vector2(0, 22)
	_quote_label.size = Vector2(480, 14)
	_quote_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quote_label.text = ""
	_quote_label.modulate = Color(1, 1, 1, 0)  # 初始隱藏
	_quote_label.add_theme_color_override("font_color", Color(1, 0.5, 0.1))  # 橘色
	add_child(_quote_label)

	# 套用 Fusion Pixel 字體
	_apply_fonts()

	# 速度控制按鈕（右上角）
	_build_speed_controls()

	# 底部工具列
	_build_toolbar()


func _apply_fonts() -> void:
	var font = load("res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf")
	if font:
		_money_label.add_theme_font_override("font", font)
		_money_label.add_theme_font_size_override("font_size", 12)
		_day_label.add_theme_font_override("font", font)
		_day_label.add_theme_font_size_override("font_size", 12)
		_time_label.add_theme_font_override("font", font)
		_time_label.add_theme_font_size_override("font_size", 12)
		_reputation_label.add_theme_font_override("font", font)
		_reputation_label.add_theme_font_size_override("font_size", 12)
		_message_label.add_theme_font_override("font", font)
		_message_label.add_theme_font_size_override("font_size", 10)
		if _quote_label != null:
			_quote_label.add_theme_font_override("font", font)
			_quote_label.add_theme_font_size_override("font_size", 8)
	else:
		push_warning("[hud.gd] 找不到 Fusion Pixel 字體，使用預設字體")


func _build_toolbar() -> void:
	# 底部工具列背景（深紫藍）
	var toolbar_bg := ColorRect.new()
	toolbar_bg.color = Color(0.08, 0.04, 0.18, 0.98)
	toolbar_bg.size = Vector2(480, 18)
	toolbar_bg.position = Vector2(0, 252)
	add_child(toolbar_bg)

	# 四個按鈕定義：[顯示文字, callback 方法名稱]
	var buttons_def: Array = [
		["建造", "_on_build_btn_pressed"],
		["擺桌", "_on_table_btn_pressed"],
		["雇員", "_on_staff_btn_pressed"],
		["菜單", "_on_menu_btn_pressed"],
	]

	# 各按鈕色塊顏色
	var btn_icons: Array[Color] = [
		Color(0.95, 0.55, 0.1),   # 建造：橘色
		Color(0.55, 0.35, 0.15),  # 擺桌：褐色
		Color(0.2, 0.4, 0.85),    # 雇員：藍色
		Color(0.2, 0.75, 0.3),    # 菜單：綠色
	]

	var btn_width: float = 480.0 / buttons_def.size()

	var toolbar_font = load("res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf")

	for i in range(buttons_def.size()):
		var btn_text: String = buttons_def[i][0]
		var callback_name: String = buttons_def[i][1]

		# 左側色塊圖示
		var icon_rect := ColorRect.new()
		icon_rect.color = btn_icons[i]
		icon_rect.size = Vector2(6, 12)
		icon_rect.position = Vector2(i * btn_width + 3, 255)  # 按鈕內左側
		add_child(icon_rect)

		var btn := Button.new()
		btn.text = btn_text
		btn.position = Vector2(i * btn_width, 252)
		btn.custom_minimum_size = Vector2(60, 18)
		btn.size = Vector2(btn_width, 18)
		btn.add_theme_font_size_override("font_size", 8)
		btn.add_theme_color_override("font_color", Color(0.961, 0.961, 0.961, 1.0))  # #F5F5F5
		if toolbar_font:
			btn.add_theme_font_override("font", toolbar_font)
		btn.pressed.connect(Callable(self, callback_name))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.6, 0.1))  # hover 橘色

		# hover 橘色底色 StyleBoxFlat
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.85, 0.38, 0.0, 0.7)
		hover_style.corner_radius_top_left = 3
		hover_style.corner_radius_top_right = 3
		hover_style.corner_radius_bottom_left = 3
		hover_style.corner_radius_bottom_right = 3
		btn.add_theme_stylebox_override("hover", hover_style)

		# 保存「擺桌」按鈕引用（索引 1），供 _flash_table_btn() 使用
		if i == 1:
			_table_btn = btn

		add_child(btn)


func _build_speed_controls() -> void:
	var ctrl_font = load("res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf")

	# 速度按鈕（右上角，暫停按鈕右側）
	_speed_btn = Button.new()
	_speed_btn.text = ">> x1"
	_speed_btn.size = Vector2(42, 16)
	_speed_btn.position = Vector2(432, 2)
	_speed_btn.add_theme_font_size_override("font_size", 7)
	_speed_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_speed_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.6, 0.1))
	if ctrl_font:
		_speed_btn.add_theme_font_override("font", ctrl_font)
	_speed_btn.pressed.connect(_on_speed_btn_pressed)
	add_child(_speed_btn)

	# 暫停按鈕（速度按鈕左側）
	_pause_btn = Button.new()
	_pause_btn.text = "||"
	_pause_btn.size = Vector2(20, 16)
	_pause_btn.position = Vector2(410, 2)
	_pause_btn.add_theme_font_size_override("font_size", 7)
	_pause_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_pause_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.6, 0.1))
	if ctrl_font:
		_pause_btn.add_theme_font_override("font", ctrl_font)
	_pause_btn.pressed.connect(_on_pause_btn_pressed)
	add_child(_pause_btn)


# ============================================================
# 信號連接
# ============================================================

func _connect_signals() -> void:
	# GameManager
	if Engine.has_singleton("GameManager"):
		var gm := Engine.get_singleton("GameManager")
		if not gm.money_changed.is_connected(_on_money_changed):
			gm.money_changed.connect(_on_money_changed)
		if not gm.day_started.is_connected(_on_day_started):
			gm.day_started.connect(_on_day_started)
		if not gm.reputation_changed.is_connected(_on_reputation_changed):
			gm.reputation_changed.connect(_on_reputation_changed)
	else:
		# AutoLoad singleton 直接以全域名稱存取
		_connect_game_manager_autoload()

	# EventManager
	if Engine.has_singleton("EventManager"):
		var em := Engine.get_singleton("EventManager")
		if not em.event_triggered.is_connected(_on_event_triggered):
			em.event_triggered.connect(_on_event_triggered)
		if not em.daily_quote_ready.is_connected(_on_daily_quote_ready):
			em.daily_quote_ready.connect(_on_daily_quote_ready)
	else:
		_connect_event_manager_autoload()


func _connect_game_manager_autoload() -> void:
	# Godot 4 AutoLoad 以全域節點路徑存取
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		push_warning("[hud.gd] 找不到 GameManager，跳過信號連接")
		return
	if not gm.money_changed.is_connected(_on_money_changed):
		gm.money_changed.connect(_on_money_changed)
	if not gm.day_started.is_connected(_on_day_started):
		gm.day_started.connect(_on_day_started)
	if not gm.reputation_changed.is_connected(_on_reputation_changed):
		gm.reputation_changed.connect(_on_reputation_changed)
	if not gm.day_ended.is_connected(_on_day_ended):
		gm.day_ended.connect(_on_day_ended)
	if gm.has_signal("first_payment_received"):
		if not gm.first_payment_received.is_connected(_on_first_payment):
			gm.first_payment_received.connect(_on_first_payment)
	if gm.has_signal("hour_milestone_reached"):
		if not gm.hour_milestone_reached.is_connected(_on_hour_milestone):
			gm.hour_milestone_reached.connect(_on_hour_milestone)
	print("[hud.gd] GameManager 信號連接完成（AutoLoad）")


func _connect_event_manager_autoload() -> void:
	var em := get_node_or_null("/root/EventManager")
	if em == null:
		push_warning("[hud.gd] 找不到 EventManager，跳過信號連接")
		return
	if not em.event_triggered.is_connected(_on_event_triggered):
		em.event_triggered.connect(_on_event_triggered)
	if not em.daily_quote_ready.is_connected(_on_daily_quote_ready):
		em.daily_quote_ready.connect(_on_daily_quote_ready)
	print("[hud.gd] EventManager 信號連接完成（AutoLoad）")


# ============================================================
# 信號回調
# ============================================================

func _on_money_changed(new_amount: float) -> void:
	if _money_label == null:
		return
	var amount: int = int(new_amount)
	# 千位分隔格式
	var s: String = str(amount)
	var result: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	_money_label.text = "$" + result

	# 金錢變動動畫（追蹤前一次金額以判斷增減）
	if not _money_label.has_meta("_prev_amount"):
		_money_label.set_meta("_prev_amount", new_amount)
		return
	var prev_amount: float = float(_money_label.get_meta("_prev_amount"))
	_money_label.set_meta("_prev_amount", new_amount)

	if new_amount > prev_amount:
		# 增加：金色閃光
		var tw := create_tween()
		tw.tween_property(_money_label, "modulate", Color(1.5, 1.2, 0.2), 0.15)
		tw.tween_property(_money_label, "modulate", Color(1, 1, 1), 0.35)
	elif new_amount < prev_amount:
		# 減少：紅色閃光
		var tw := create_tween()
		tw.tween_property(_money_label, "modulate", Color(1.5, 0.2, 0.2), 0.15)
		tw.tween_property(_money_label, "modulate", Color(1, 1, 1), 0.35)

	# 低錢警告：金錢低於 $3,000 時文字持續顯示紅色
	if new_amount < 3000.0:
		_money_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	else:
		_money_label.add_theme_color_override("font_color", Color.WHITE)


## 金錢不足時閃紅提示（Tween 驅動，0.1秒變紅→0.3秒回白）
func _flash_money_red() -> void:
	if _money_label == null:
		return
	var tween := create_tween()
	tween.tween_property(_money_label, "modulate", Color(1, 0.1, 0.1), 0.1)
	tween.tween_property(_money_label, "modulate", Color(1, 1, 1), 0.3)


func _on_day_started(year: int, day: int) -> void:
	if _day_label != null:
		_day_label.text = "第 %d 年 第 %d 天" % [year, day]
	# 扣除每日薪水：廚師 $800 + 外場 $600 = $1,400
	# Day 1 Year 1 不扣薪（開幕第一天補貼）
	if year == 1 and day == 1:
		_show_message("開業第一天！薪水補貼中，今日免扣薪。", 3.0)
		return
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("spend_money"):
		if gm.spend_money(1400.0):
			_show_salary_popup(-1400)
		# 若金錢不足，不強制扣到負數，改為扣除士氣
		else:
			_flash_money_red()
			if gm.has_method("reduce_staff_morale"):
				gm.reduce_staff_morale(20.0)
			_show_message("資金不足，員工士氣 -20！", 4.0)


func _show_salary_popup(amount: int) -> void:
	# 在畫面中央上方顯示紅色「-$1,400 薪水」飄字
	var popup_layer := CanvasLayer.new()
	popup_layer.layer = 3
	get_tree().root.add_child(popup_layer)

	var label := Label.new()
	label.position = Vector2(180, 100)
	label.text = "-$%d 薪水" % abs(amount)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))  # 紅色
	label.add_theme_font_size_override("font_size", 12)
	var font_path := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf"
	if ResourceLoader.exists(font_path):
		label.add_theme_font_override("font", load(font_path))
	popup_layer.add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 25.0, 1.2)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.2)
	tween.tween_callback(popup_layer.queue_free)


func _on_reputation_changed(new_value: int) -> void:
	if _reputation_label == null:
		return
	var rank: String
	var rank_color: Color
	if new_value < 100:
		rank = "新手"
		rank_color = Color(0.9, 0.9, 0.9)   # 白
	elif new_value < 300:
		rank = "知名"
		rank_color = Color(1.0, 0.6, 0.1)   # 橘
	elif new_value < 600:
		rank = "名店"
		rank_color = Color(1.0, 0.843, 0.0) # 金
	else:
		rank = "傳奇"
		rank_color = Color(1.0, 0.2, 0.2)   # 紅
	_reputation_label.text = "%s %d" % [rank, new_value]
	_reputation_label.add_theme_color_override("font_color", rank_color)

	# 名聲變化時閃爍提示
	var flash_tween := create_tween()
	flash_tween.tween_property(_reputation_label, "modulate", Color(2, 2, 0.5), 0.15)
	flash_tween.tween_property(_reputation_label, "modulate", Color(1, 1, 1), 0.3)

	# 閃白光（聲望 Label 區域 1 幀 ColorRect 疊加）
	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 5
	get_tree().root.add_child(flash_layer)
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.25)
	flash.position = Vector2(_reputation_label.global_position.x - 2, 0)
	flash.size = Vector2(80, 22)
	flash_layer.add_child(flash)
	var tw_flash := create_tween()
	tw_flash.tween_property(flash, "modulate:a", 0.0, 0.3)
	tw_flash.tween_callback(flash_layer.queue_free)

	# 更新聲望進度條
	_update_reputation_bar(new_value)

	# 達到 10 聲望時顯示解鎖提示（只觸發一次）
	if new_value >= 10 and not _reputation_10_notified:
		_reputation_10_notified = true
		_show_unlock_banner("解鎖新菜色！")


func _update_reputation_bar(rep: int) -> void:
	if _reputation_bar_fill == null:
		return
	# 依當前等級計算到下一級的進度
	var progress: float
	if rep < 100:
		progress = float(rep) / 100.0
	elif rep < 300:
		progress = float(rep - 100) / 200.0
	elif rep < 600:
		progress = float(rep - 300) / 300.0
	else:
		progress = float(rep - 600) / 400.0
	_reputation_bar_fill.size.x = 30.0 * clampf(progress, 0.0, 1.0)


func _show_unlock_banner(text: String) -> void:
	var banner := Label.new()
	banner.text = text
	banner.position = Vector2(0, 28)
	banner.size = Vector2(480, 14)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	banner.add_theme_font_size_override("font_size", 10)
	var font_path := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf"
	if ResourceLoader.exists(font_path):
		banner.add_theme_font_override("font", load(font_path))
	add_child(banner)
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_property(banner, "modulate:a", 0.0, 1.0)
	tw.tween_callback(banner.queue_free)


func _on_event_triggered(event_data: Dictionary) -> void:
	if _message_label == null:
		return

	var name_str: String = event_data.get("name", "")
	_show_message(name_str, 3.0)

	# 若事件有選項，呼叫 EventManager 的選擇 UI
	var options: Array = event_data.get("options", [])
	if not options.is_empty():
		var em := get_node_or_null("/root/EventManager")
		if em != null and em.has_method("show_event_choice"):
			em.show_event_choice(event_data)


func _clear_message() -> void:
	# 保留空函式避免舊的 CONNECT_ONE_SHOT 連接報錯；實際清空由 _on_message_done 接管
	_message_timer = null


# ============================================================
# 阿龍台詞：第一次收到付款
# ============================================================

func _on_first_payment() -> void:
	_show_message("阿龍說：「第一桌，開張了！好兆頭！」", 5.0)


func _on_hour_milestone(hour: int, message: String) -> void:
	# 加入佇列，顯示時再套用對應顏色（佇列只記錄文字與時長）
	_show_message(message, 3.0)


## 在 _message_label 顯示指定文字，duration 秒後自動清除（佇列模式）
func _show_message(text: String, duration: float) -> void:
	if _message_label == null:
		return
	# 加入佇列
	_message_queue.append({"text": text, "duration": duration})
	# 如果目前沒在顯示，立即開始
	if not _message_displaying:
		_dequeue_message()


func _dequeue_message() -> void:
	if _message_queue.is_empty():
		_message_displaying = false
		if _message_label != null:
			_message_label.text = ""
		return
	_message_displaying = true
	var msg: Dictionary = _message_queue.pop_front()
	_message_label.text = msg["text"]
	_message_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	_message_timer = get_tree().create_timer(msg["duration"])
	_message_timer.timeout.connect(_on_message_done, CONNECT_ONE_SHOT)


func _on_message_done() -> void:
	_message_timer = null
	_message_displaying = false
	_dequeue_message()


# ============================================================
# 每日結算回調
# ============================================================

func _on_day_ended(income: float) -> void:
	_show_day_summary_panel(income)


func _show_day_summary_panel(income: float) -> void:
	# 建立 CanvasLayer layer=8
	var cl := CanvasLayer.new()
	cl.layer = 8
	get_tree().root.add_child(cl)

	# 半透明深色背景
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.size = Vector2(480, 270)
	bg.position = Vector2.ZERO
	cl.add_child(bg)

	# 結算框橘色邊框（比面板大 4px，position 偏移 -2px）
	var box_border := ColorRect.new()
	box_border.color = Color(0.9, 0.4, 0.05)
	box_border.size = Vector2(224, 154)
	box_border.position = Vector2(128, 73)
	cl.add_child(box_border)

	# 結算框（深夜藍）
	var box := ColorRect.new()
	box.color = Color(0.05, 0.08, 0.18, 0.96)
	box.size = Vector2(220, 150)
	box.position = Vector2(130, 75)
	cl.add_child(box)

	var font_path := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf"
	var panel_font: Font = null
	if ResourceLoader.exists(font_path):
		panel_font = load(font_path)

	# 標題
	var title := Label.new()
	title.text = "今日收攤"
	title.position = Vector2(185, 83)
	title.add_theme_color_override("font_color", Color(1, 0.843, 0))
	title.add_theme_font_size_override("font_size", 12)
	if panel_font:
		title.add_theme_font_override("font", panel_font)
	cl.add_child(title)

	# 分隔線
	var sep := ColorRect.new()
	sep.color = Color(1, 0.843, 0)
	sep.size = Vector2(204, 1)
	sep.position = Vector2(138, 100)
	cl.add_child(sep)

	# 今日收入
	var income_lbl := Label.new()
	income_lbl.text = "今日收入：$%s" % _format_money(int(income))
	income_lbl.position = Vector2(145, 106)
	income_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	income_lbl.add_theme_font_size_override("font_size", 10)
	if panel_font:
		income_lbl.add_theme_font_override("font", panel_font)
	cl.add_child(income_lbl)

	# 今日薪水支出
	var salary_lbl := Label.new()
	salary_lbl.text = "薪水支出：-$1,400"
	salary_lbl.position = Vector2(145, 122)
	salary_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	salary_lbl.add_theme_font_size_override("font_size", 10)
	if panel_font:
		salary_lbl.add_theme_font_override("font", panel_font)
	cl.add_child(salary_lbl)

	# 食材成本（估算為收入的 30%）
	var food_cost := income * 0.30
	var food_lbl := Label.new()
	food_lbl.text = "食材成本：-$%s" % _format_money(int(food_cost))
	food_lbl.position = Vector2(145, 138)
	food_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	food_lbl.add_theme_font_size_override("font_size", 10)
	if panel_font:
		food_lbl.add_theme_font_override("font", panel_font)
	cl.add_child(food_lbl)

	# 淨利計算（收入 - 薪水 - 食材）
	var net_income := income - 1400.0 - food_cost
	var net_color := Color(0.2, 1.0, 0.4) if net_income >= 0 else Color(1.0, 0.3, 0.3)
	var net_lbl := Label.new()
	net_lbl.text = "今日淨利：$%s" % _format_money(int(net_income))
	net_lbl.position = Vector2(145, 164)
	net_lbl.add_theme_color_override("font_color", net_color)
	net_lbl.add_theme_font_size_override("font_size", 10)
	if panel_font:
		net_lbl.add_theme_font_override("font", panel_font)
	cl.add_child(net_lbl)

	# 繼續按鈕
	var cont_btn := Button.new()
	cont_btn.text = "繼續"
	cont_btn.size = Vector2(80, 22)
	cont_btn.position = Vector2(200, 190)
	cont_btn.add_theme_font_size_override("font_size", 10)
	if panel_font:
		cont_btn.add_theme_font_override("font", panel_font)
	cont_btn.pressed.connect(cl.queue_free)
	cl.add_child(cont_btn)


## 將整數金額格式化為千位分隔字串（例：1234567 → "1,234,567"）
func _format_money(amount: int) -> String:
	var s: String = str(amount)
	var result: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result


# ============================================================
# 每日語錄回調
# ============================================================

func _on_daily_quote_ready(quote: String) -> void:
	if _quote_label == null:
		return

	# 取消上一個語錄的淡出 Tween（若還在執行中）
	if _quote_tween != null and _quote_tween.is_running():
		_quote_tween.kill()
		_quote_tween = null

	_quote_label.text = quote
	_quote_label.modulate = Color(1, 1, 1, 0)

	# 淡入 0.5 秒 → 停留 4 秒 → 淡出 1 秒
	_quote_tween = create_tween()
	_quote_tween.tween_property(_quote_label, "modulate", Color(1, 1, 1, 1), 0.5)
	_quote_tween.tween_interval(4.0)
	_quote_tween.tween_property(_quote_label, "modulate", Color(1, 1, 1, 0), 1.0)


# ============================================================
# 菜單 Panel
# ============================================================

func _on_menu_btn_pressed() -> void:
	# 零座位防呆：若沒有任何座位，提示玩家先擺桌（但不阻止開啟菜單）
	var sm := get_node_or_null("/root/SeatManager")
	if sm != null:
		var all_seats: Array = sm.get_all_seats()
		if all_seats.is_empty():
			_show_message("請先擺桌，才能讓客人入座！", 3.0)
			_flash_table_btn()
			# 不 return，仍然讓菜單顯示

	# 首次開啟菜單提示
	if not _menu_first_opened:
		_menu_first_opened = true
		_show_message("提示：選幾道你有把握的菜，菜色太多會來不及出菜！", 5.0)

	# 若 Panel 已存在且可見，則關閉（toggle 行為）
	if _menu_ui != null and _menu_ui.visible:
		if _menu_ui.has_method("hide_panel"):
			_menu_ui.hide_panel()
		return

	# 懶建立：第一次按才 new()
	# menu_ui.gd extends CanvasLayer，直接 load().new() 即可取得正確型別
	if _menu_ui == null:
		var script = load("res://scripts/ui/menu_ui.gd")
		if script == null:
			push_error("[hud.gd] 無法載入 menu_ui.gd")
			return
		_menu_ui = script.new()
		get_tree().root.add_child(_menu_ui)

	if _menu_ui.has_method("show_panel"):
		_menu_ui.show_panel()


# ============================================================
# 建造、擺桌、雇員按鈕（簡易 Panel）
# ============================================================

func _on_build_btn_pressed() -> void:
	build_mode_toggled.emit()
	var items: Array = [
		{"label": "快炒爐", "price": 2000},
		{"label": "冰箱", "price": 3000},
		{"label": "收銀台", "price": 1500},
	]
	_show_shop_panel("建造設備", items)


func _on_table_btn_pressed() -> void:
	var items: Array = [
		{"label": "方桌（4人）", "price": 500, "seats": 2},
		{"label": "圓桌（6人）", "price": 800, "seats": 3},
	]
	_show_shop_panel("擺桌", items)


func _on_staff_btn_pressed() -> void:
	var info_items: Array = [
		"廚師阿龍 — 廚師 — $800/天",
		"外場小弟 — 外場 — $600/天",
	]
	_show_info_panel("員工管理", info_items)


# ============================================================
# 簡易 Panel Helper
# ============================================================

## 關閉並釋放目前顯示中的簡易 Panel
func _close_active_panel() -> void:
	if _active_simple_panel != null and is_instance_valid(_active_simple_panel):
		_active_simple_panel.queue_free()
	_active_simple_panel = null


## 建立可購買設備的 Panel（CanvasLayer layer=5）
## items: Array[Dictionary]，每項有 "label" 和 "price"
func _show_shop_panel(title: String, items: Array) -> void:
	_close_active_panel()

	var cl := CanvasLayer.new()
	cl.layer = 5
	get_tree().root.add_child(cl)
	_active_simple_panel = cl

	const PW: float = 240.0
	const PH_BASE: float = 50.0
	const ROW_H: float = 22.0
	const SCREEN_W: float = 480.0
	const SCREEN_H: float = 270.0

	var panel_font_path := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf"
	var panel_font: Font = null
	if ResourceLoader.exists(panel_font_path):
		panel_font = load(panel_font_path)

	var panel_h: float = PH_BASE + items.size() * ROW_H

	# 背景
	var bg := ColorRect.new()
	bg.color = Color(0.102, 0.102, 0.180, 0.92)
	bg.size = Vector2(PW, panel_h)
	bg.position = Vector2((SCREEN_W - PW) * 0.5, (SCREEN_H - panel_h) * 0.5)
	cl.add_child(bg)

	# 標題
	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.position = bg.position + Vector2(10, 6)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0))
	title_lbl.add_theme_font_size_override("font_size", 11)
	if panel_font:
		title_lbl.add_theme_font_override("font", panel_font)
	cl.add_child(title_lbl)

	# 分隔線
	var sep := ColorRect.new()
	sep.color = Color(1.0, 0.843, 0.0)
	sep.size = Vector2(PW - 16, 1)
	sep.position = bg.position + Vector2(8, 22)
	cl.add_child(sep)

	# 每個品項
	for i in range(items.size()):
		var item: Dictionary = items[i]
		var row_y: float = bg.position.y + 28 + i * ROW_H

		var item_lbl := Label.new()
		item_lbl.text = "%s  $%d" % [item["label"], item["price"]]
		item_lbl.position = Vector2(bg.position.x + 10, row_y)
		item_lbl.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96))
		item_lbl.add_theme_font_size_override("font_size", 9)
		if panel_font:
			item_lbl.add_theme_font_override("font", panel_font)
		cl.add_child(item_lbl)

		var buy_btn := Button.new()
		buy_btn.text = "購買"
		buy_btn.size = Vector2(36, 16)
		buy_btn.position = Vector2(bg.position.x + PW - 46, row_y)
		buy_btn.add_theme_font_size_override("font_size", 8)
		if panel_font:
			buy_btn.add_theme_font_override("font", panel_font)
		var price: int = item["price"]
		var item_name: String = item["label"]
		var item_copy: Dictionary = items[i]  # 捕獲副本給 lambda 使用
		buy_btn.pressed.connect(func() -> void:
			var gm := get_node_or_null("/root/GameManager")
			if gm != null and gm.has_method("spend_money"):
				if gm.spend_money(float(price)):
					print("[hud.gd] 購買成功：%s $%d" % [item_name, price])
					# 若 item 有 seats 資訊，新增座位到 SeatManager
					var seat_count: int = item_copy.get("seats", 0)
					if seat_count > 0:
						var sm := get_node_or_null("/root/SeatManager")
						if sm != null and sm.has_method("register_seat"):
							# 找一個空的格子（從 x=1..6, y=4 外場區找未登記的格）
							var all_seats: Dictionary = sm.get_all_seats()
							var added: int = 0
							for ty in [4, 3]:
								for tx in range(1, 7):
									if added >= seat_count:
										break
									var tile := Vector2i(tx, ty)
									if not all_seats.has(tile):
										sm.register_seat(tile)
										added += 1
							print("[hud.gd] 新增 %d 個座位" % added)
				else:
					print("[hud.gd] 金錢不足，無法購買 %s" % item_name)
					_flash_money_red()
			else:
				print("[hud.gd] 找不到 GameManager")
		)
		cl.add_child(buy_btn)

	# 關閉按鈕
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.flat = true
	close_btn.size = Vector2(18, 18)
	close_btn.position = bg.position + Vector2(PW - 22, 4)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0))
	close_btn.add_theme_font_size_override("font_size", 10)
	if panel_font:
		close_btn.add_theme_font_override("font", panel_font)
	close_btn.pressed.connect(_close_active_panel)
	cl.add_child(close_btn)


## 建立純資訊展示 Panel（CanvasLayer layer=5）
## lines: Array[String]，每行一條文字
func _show_info_panel(title: String, lines: Array) -> void:
	_close_active_panel()

	var cl := CanvasLayer.new()
	cl.layer = 5
	get_tree().root.add_child(cl)
	_active_simple_panel = cl

	const PW: float = 260.0
	const PH_BASE: float = 46.0
	const ROW_H: float = 20.0
	const SCREEN_W: float = 480.0
	const SCREEN_H: float = 270.0

	var panel_font_path := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf"
	var panel_font: Font = null
	if ResourceLoader.exists(panel_font_path):
		panel_font = load(panel_font_path)

	var panel_h: float = PH_BASE + lines.size() * ROW_H

	var bg := ColorRect.new()
	bg.color = Color(0.102, 0.102, 0.180, 0.92)
	bg.size = Vector2(PW, panel_h)
	bg.position = Vector2((SCREEN_W - PW) * 0.5, (SCREEN_H - panel_h) * 0.5)
	cl.add_child(bg)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.position = bg.position + Vector2(10, 6)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0))
	title_lbl.add_theme_font_size_override("font_size", 11)
	if panel_font:
		title_lbl.add_theme_font_override("font", panel_font)
	cl.add_child(title_lbl)

	var sep := ColorRect.new()
	sep.color = Color(1.0, 0.843, 0.0)
	sep.size = Vector2(PW - 16, 1)
	sep.position = bg.position + Vector2(8, 22)
	cl.add_child(sep)

	for i in range(lines.size()):
		var row_lbl := Label.new()
		row_lbl.text = lines[i]
		row_lbl.position = bg.position + Vector2(10, 28 + i * ROW_H)
		row_lbl.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96))
		row_lbl.add_theme_font_size_override("font_size", 9)
		if panel_font:
			row_lbl.add_theme_font_override("font", panel_font)
		cl.add_child(row_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.flat = true
	close_btn.size = Vector2(18, 18)
	close_btn.position = bg.position + Vector2(PW - 22, 4)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0))
	close_btn.add_theme_font_size_override("font_size", 10)
	if panel_font:
		close_btn.add_theme_font_override("font", panel_font)
	close_btn.pressed.connect(_close_active_panel)
	cl.add_child(close_btn)


# ============================================================
# 擺桌按鈕閃爍提示
# ============================================================

## 菜色解鎖視覺效果：全螢幕橘色閃光 + 解鎖提示文字
func _on_dish_unlocked(dish_id: String, dish_name: String) -> void:
	# 全螢幕橘色閃光（CanvasLayer layer=9）
	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 9
	get_tree().root.add_child(flash_layer)
	var flash_bg := ColorRect.new()
	flash_bg.color = Color(1.0, 0.6, 0.0, 0.0)
	flash_bg.size = Vector2(480, 270)
	flash_bg.position = Vector2.ZERO
	flash_layer.add_child(flash_bg)
	var tw := create_tween()
	tw.tween_property(flash_bg, "color:a", 0.5, 0.15)
	tw.tween_property(flash_bg, "color:a", 0.0, 0.4)
	tw.tween_callback(flash_layer.queue_free)
	# 解鎖提示文字
	_show_unlock_banner("新菜解鎖：%s！" % dish_name)
	print("[hud.gd] 菜色解鎖效果：%s" % dish_name)


## 擺桌按鈕黃色閃爍提示（提醒玩家先擺桌，在零座位時呼叫）
func _flash_table_btn() -> void:
	if _table_btn == null:
		return
	var tw := create_tween()
	tw.tween_property(_table_btn, "modulate", Color(1.5, 1.5, 0.3), 0.2)
	tw.tween_property(_table_btn, "modulate", Color(1, 1, 1), 0.2)
	tw.tween_property(_table_btn, "modulate", Color(1.5, 1.5, 0.3), 0.2)
	tw.tween_property(_table_btn, "modulate", Color(1, 1, 1), 0.2)


# ============================================================
# 速度控制
# ============================================================

func _on_speed_btn_pressed() -> void:
	_speed_index = (_speed_index + 1) % SPEED_VALUES.size()
	var new_scale: float = SPEED_VALUES[_speed_index]
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("set_time_scale"):
		gm.set_time_scale(new_scale)
	if _speed_btn != null:
		_speed_btn.text = ">> %s" % SPEED_LABELS[_speed_index]
	print("[hud.gd] 速度切換：%s" % SPEED_LABELS[_speed_index])


func _on_pause_btn_pressed() -> void:
	_is_paused = not _is_paused
	var gm := get_node_or_null("/root/GameManager")
	if _is_paused:
		if gm != null and gm.has_method("pause_time"):
			gm.pause_time()
		if _pause_btn != null:
			_pause_btn.text = ">|"
		_show_pause_overlay()
	else:
		if gm != null and gm.has_method("resume_time"):
			gm.resume_time()
		if _pause_btn != null:
			_pause_btn.text = "||"
		_hide_pause_overlay()
	print("[hud.gd] 暫停切換：%s" % str(_is_paused))


func _show_pause_overlay() -> void:
	if _pause_overlay != null and is_instance_valid(_pause_overlay):
		return
	_pause_overlay = CanvasLayer.new()
	_pause_overlay.layer = 10
	get_tree().root.add_child(_pause_overlay)
	var lbl := Label.new()
	lbl.text = "已暫停"
	lbl.position = Vector2(200, 125)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0))
	lbl.add_theme_font_size_override("font_size", 20)
	var f = load("res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf")
	if f:
		lbl.add_theme_font_override("font", f)
	_pause_overlay.add_child(lbl)


func _hide_pause_overlay() -> void:
	if _pause_overlay != null and is_instance_valid(_pause_overlay):
		_pause_overlay.queue_free()
	_pause_overlay = null
