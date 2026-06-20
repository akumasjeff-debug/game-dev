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

var _message_timer: SceneTreeTimer = null
var _time_update_timer: float = 0.0


# ============================================================
# _ready
# ============================================================

func _ready() -> void:
	_build_labels()
	_connect_signals()


# ============================================================
# 主循環：每 5 秒更新時段顯示
# ============================================================

func _process(delta: float) -> void:
	_time_update_timer += delta
	if _time_update_timer >= 5.0:
		_time_update_timer = 0.0
		_refresh_time_label()


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
	else:
		return "打烊"


## 刷新時段 Label
func _refresh_time_label() -> void:
	if _time_label == null:
		return
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return
	_time_label.text = _get_time_period(gm.current_hour)


# ============================================================
# 建立 Label 節點
# ============================================================

func _build_labels() -> void:
	# 頂部 HUD 背景色塊
	var hud_bg := ColorRect.new()
	hud_bg.color = Color(0.102, 0.102, 0.180, 0.85)  # #1A1A2E alpha=0.85
	hud_bg.size = Vector2(480, 20)
	hud_bg.position = Vector2(0, 0)
	add_child(hud_bg)

	# 頂部底邊霓虹線（1px 高 #FF2D55）
	var neon_line := ColorRect.new()
	neon_line.color = Color(1.0, 0.176, 0.333, 1.0)  # #FF2D55
	neon_line.size = Vector2(480, 1)
	neon_line.position = Vector2(0, 20)
	add_child(neon_line)

	_money_label = Label.new()
	_money_label.position = Vector2(8, 4)
	_money_label.text = "$0"
	_money_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_money_label)

	_time_label = Label.new()
	_time_label.position = Vector2(220, 4)
	_time_label.text = "傍晚"
	_time_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_time_label)

	_day_label = Label.new()
	_day_label.position = Vector2(180, 4)
	_day_label.text = "第 1 年 第 1 天"
	_day_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_day_label)

	_reputation_label = Label.new()
	_reputation_label.position = Vector2(380, 4)
	_reputation_label.text = "聲望: 0"
	_reputation_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_reputation_label)

	_message_label = Label.new()
	_message_label.position = Vector2(8, 258)
	_message_label.text = ""
	_message_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_message_label)

	# 套用 Fusion Pixel 字體
	_apply_fonts()

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
	else:
		push_warning("[hud.gd] 找不到 Fusion Pixel 字體，使用預設字體")


func _build_toolbar() -> void:
	# 底部工具列背景
	var toolbar_bg := ColorRect.new()
	toolbar_bg.color = Color(0.102, 0.102, 0.180, 0.85)  # #1A1A2E alpha=0.85
	toolbar_bg.size = Vector2(480, 18)
	toolbar_bg.position = Vector2(0, 252)
	add_child(toolbar_bg)

	# 四個按鈕定義：[顯示文字, 是否接線]
	var buttons_def: Array = [
		["建造", true],
		["擺桌", false],
		["雇員", false],
		["菜單", false],
	]

	var btn_width: float = 480.0 / buttons_def.size()

	for i in range(buttons_def.size()):
		var btn_text: String = buttons_def[i][0]
		var btn_active: bool = buttons_def[i][1]

		var btn := Button.new()
		btn.text = btn_text
		btn.position = Vector2(i * btn_width, 252)
		btn.custom_minimum_size = Vector2(60, 18)
		btn.size = Vector2(btn_width, 18)
		btn.add_theme_font_size_override("font_size", 8)
		btn.add_theme_color_override("font_color", Color(0.961, 0.961, 0.961, 1.0))  # #F5F5F5

		if btn_active:
			btn.pressed.connect(func(): build_mode_toggled.emit())

		add_child(btn)


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
	print("[hud.gd] GameManager 信號連接完成（AutoLoad）")


func _connect_event_manager_autoload() -> void:
	var em := get_node_or_null("/root/EventManager")
	if em == null:
		push_warning("[hud.gd] 找不到 EventManager，跳過信號連接")
		return
	if not em.event_triggered.is_connected(_on_event_triggered):
		em.event_triggered.connect(_on_event_triggered)
	print("[hud.gd] EventManager 信號連接完成（AutoLoad）")


# ============================================================
# 信號回調
# ============================================================

func _on_money_changed(new_amount: float) -> void:
	if _money_label != null:
		_money_label.text = "$%d" % int(new_amount)


func _on_day_started(year: int, day: int) -> void:
	if _day_label != null:
		_day_label.text = "第 %d 年 第 %d 天" % [year, day]


func _on_reputation_changed(new_value: int) -> void:
	if _reputation_label != null:
		_reputation_label.text = "聲望: %d" % new_value


func _on_event_triggered(event_data: Dictionary) -> void:
	if _message_label == null:
		return

	var name_str: String = event_data.get("name", "")
	_message_label.text = name_str

	# 取消舊的計時器（若還在倒數）
	if _message_timer != null:
		# SceneTreeTimer 無法直接取消，讓它自然到期即可，
		# 下面重新建立新計時器覆蓋顯示
		pass

	_message_timer = get_tree().create_timer(3.0)
	_message_timer.timeout.connect(_clear_message, CONNECT_ONE_SHOT)


func _clear_message() -> void:
	if _message_label != null:
		_message_label.text = ""
	_message_timer = null
