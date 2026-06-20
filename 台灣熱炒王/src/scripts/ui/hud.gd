## hud.gd
## 掛在 UI.tscn 的 hud_layer 節點（或根節點）
## 以程式碼建立 Label，顯示金錢、日期、名聲、即時事件訊息

extends CanvasLayer


# ============================================================
# 私有成員
# ============================================================

var _money_label: Label
var _day_label: Label
var _reputation_label: Label
var _message_label: Label

var _message_timer: SceneTreeTimer = null


# ============================================================
# _ready
# ============================================================

func _ready() -> void:
	_build_labels()
	_connect_signals()


# ============================================================
# 建立 Label 節點
# ============================================================

func _build_labels() -> void:
	_money_label = Label.new()
	_money_label.position = Vector2(8, 4)
	_money_label.text = "$0"
	_money_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(_money_label)

	_day_label = Label.new()
	_day_label.position = Vector2(180, 4)
	_day_label.text = "Year 1 - Day 1"
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
		_day_label.text = "Year %d - Day %d" % [year, day]


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
