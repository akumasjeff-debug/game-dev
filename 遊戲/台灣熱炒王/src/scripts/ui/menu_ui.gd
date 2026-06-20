## menu_ui.gd
## 菜單管理 Panel — 顯示所有菜色並提供 ON/OFF 切換
## 以程式碼建立節點，不依賴 .tscn 場景檔
## layer = 5（比 HUD=1、Dialog=2 都高）

extends CanvasLayer

signal panel_closed

# ── 常數 ─────────────────────────────────────────────────────────────
const PANEL_W: float = 380.0
const PANEL_H: float = 200.0
const SCREEN_W: float = 480.0
const SCREEN_H: float = 270.0

const COLOR_BG       := Color(0.102, 0.102, 0.180, 0.9)   # #1A1A2E alpha=0.9
const COLOR_GOLD     := Color(1.0, 0.843, 0.0, 1.0)        # #FFD700
const COLOR_ON       := Color(0.133, 0.694, 0.298, 1.0)    # 綠色 #22B14C
const COLOR_OFF      := Color(0.502, 0.502, 0.502, 1.0)    # 灰色 #808080
const COLOR_TEXT     := Color(0.961, 0.961, 0.961, 1.0)    # #F5F5F5
const COLOR_LOCKED   := Color(0.55, 0.55, 0.55, 1.0)       # 鎖定菜色（灰色）
const COLOR_DARKLOCK := Color(0.35, 0.35, 0.35, 1.0)       # 深灰（未開放）

# ── 節點引用 ─────────────────────────────────────────────────────────
var _panel_root: Control = null
var _scroll_container: ScrollContainer = null
var _dish_list_vbox: VBoxContainer = null

# ── 字體 ─────────────────────────────────────────────────────────────
var _font: Font = null


# ============================================================
# 生命週期
# ============================================================

func _ready() -> void:
	layer = 5
	visible = false

	# 嘗試載入像素字體
	var font_path := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf"
	if ResourceLoader.exists(font_path):
		_font = load(font_path)
	else:
		push_warning("[menu_ui.gd] 找不到 Fusion Pixel 字體，使用預設字體")

	_build_panel()


# ============================================================
# 建立 Panel 節點樹
# ============================================================

func _build_panel() -> void:
	# 半透明背景（全螢幕點擊關閉）
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.0)  # 完全透明，只攔截點擊
	dim.size = Vector2(SCREEN_W, SCREEN_H)
	dim.position = Vector2.ZERO
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	dim.gui_input.connect(_on_dim_input)

	# 主 Panel 容器
	_panel_root = Control.new()
	_panel_root.size = Vector2(PANEL_W, PANEL_H)
	_panel_root.position = Vector2(
		(SCREEN_W - PANEL_W) * 0.5,
		(SCREEN_H - PANEL_H) * 0.5
	)
	add_child(_panel_root)

	# Panel 背景色塊
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.size = Vector2(PANEL_W, PANEL_H)
	bg.position = Vector2.ZERO
	_panel_root.add_child(bg)

	# ── 標題列 ──────────────────────────────────────────────
	var title_lbl := Label.new()
	title_lbl.text = "菜單管理"
	title_lbl.position = Vector2(12, 6)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	_apply_font(title_lbl, 14)
	_panel_root.add_child(title_lbl)

	# ── 關閉按鈕（右上角） ───────────────────────────────────
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.size = Vector2(20, 20)
	close_btn.position = Vector2(PANEL_W - 24, 4)
	close_btn.flat = true
	close_btn.add_theme_color_override("font_color", COLOR_GOLD)
	_apply_font(close_btn, 12)
	close_btn.pressed.connect(hide_panel)
	_panel_root.add_child(close_btn)

	# 標題分隔線
	var sep := ColorRect.new()
	sep.color = COLOR_GOLD
	sep.size = Vector2(PANEL_W - 16, 1)
	sep.position = Vector2(8, 26)
	_panel_root.add_child(sep)

	# ── 可捲動菜色列表 ───────────────────────────────────────
	_scroll_container = ScrollContainer.new()
	_scroll_container.position = Vector2(8, 32)
	_scroll_container.size = Vector2(PANEL_W - 16, PANEL_H - 40)
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel_root.add_child(_scroll_container)

	_dish_list_vbox = VBoxContainer.new()
	_dish_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.add_child(_dish_list_vbox)


# ============================================================
# 公開方法
# ============================================================

func show_panel() -> void:
	_refresh_dish_list()
	visible = true


func hide_panel() -> void:
	visible = false
	panel_closed.emit()


# ============================================================
# 列表刷新
# ============================================================

func _refresh_dish_list() -> void:
	# 清除舊項目
	for child in _dish_list_vbox.get_children():
		child.queue_free()

	var mm := get_node_or_null("/root/MenuManager")
	if mm == null:
		var err_lbl := Label.new()
		err_lbl.text = "（找不到 MenuManager）"
		err_lbl.add_theme_color_override("font_color", COLOR_TEXT)
		_apply_font(err_lbl, 9)
		_dish_list_vbox.add_child(err_lbl)
		return

	var all_dishes: Array = mm.get_all_dishes()

	if all_dishes.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "（沒有菜品資料）"
		empty_lbl.add_theme_color_override("font_color", COLOR_TEXT)
		_apply_font(empty_lbl, 9)
		_dish_list_vbox.add_child(empty_lbl)
		return

	for dish: Dictionary in all_dishes:
		_add_dish_row(dish)


func _add_dish_row(dish: Dictionary) -> void:
	var dish_id: String = str(dish.get("id", ""))
	var dish_name: String = str(dish.get("name", "未知菜色"))
	var dish_price: int = int(dish.get("price", 0))
	var is_unlocked: bool = dish.get("unlocked", false)
	var requires_reputation: bool = dish.get("requires_reputation", false)
	var unlock_reputation: int = int(dish.get("unlock_reputation", 0))

	# 行容器
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)
	_dish_list_vbox.add_child(row)

	# ON/OFF 色塊（鎖定菜色用灰色）
	var toggle_rect := ColorRect.new()
	toggle_rect.custom_minimum_size = Vector2(16, 16)
	if is_unlocked:
		toggle_rect.color = COLOR_ON
	elif requires_reputation:
		toggle_rect.color = COLOR_LOCKED
	else:
		toggle_rect.color = COLOR_DARKLOCK
	toggle_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(toggle_rect)

	# 狀態文字
	var state_lbl := Label.new()
	state_lbl.custom_minimum_size = Vector2(24, 0)
	if is_unlocked:
		state_lbl.text = "ON"
		state_lbl.add_theme_color_override("font_color", COLOR_ON)
	else:
		state_lbl.text = "OFF"
		state_lbl.add_theme_color_override("font_color", COLOR_OFF)
	_apply_font(state_lbl, 9)
	row.add_child(state_lbl)

	# 菜名（鎖定菜色加 [鎖] 標記與解鎖條件）
	var name_lbl := Label.new()
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_unlocked:
		name_lbl.text = dish_name
		name_lbl.add_theme_color_override("font_color", COLOR_TEXT)
	elif requires_reputation:
		name_lbl.text = "[鎖] %s 聲望%d解鎖" % [dish_name, unlock_reputation]
		name_lbl.add_theme_color_override("font_color", COLOR_LOCKED)
	else:
		name_lbl.text = "[鎖] %s 未開放" % dish_name
		name_lbl.add_theme_color_override("font_color", COLOR_DARKLOCK)
	_apply_font(name_lbl, 9)
	row.add_child(name_lbl)

	# 價格（鎖定菜色用灰色）
	var price_lbl := Label.new()
	price_lbl.text = "$%d" % dish_price
	price_lbl.add_theme_color_override("font_color", COLOR_TEXT if is_unlocked else COLOR_LOCKED)
	_apply_font(price_lbl, 9)
	row.add_child(price_lbl)

	# 捕捉行點擊 — 用透明 Button 蓋住整行
	var click_btn := Button.new()
	click_btn.flat = true
	click_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	click_btn.text = ""
	# 讓 button 浮在 row 上方（添加到 row 之外做絕對定位比較麻煩，
	# 改用 row 的 gui_input 訊號比較乾淨）
	click_btn.visible = false  # 不顯示，改用下方 gui_input
	row.add_child(click_btn)

	# 直接讓行本身可以接收點擊（鎖定菜色不可切換）
	if is_unlocked or not requires_reputation:
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.gui_input.connect(
			func(event: InputEvent) -> void:
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					if not requires_reputation or is_unlocked:
						_toggle_dish(dish_id, toggle_rect, state_lbl)
		)
	else:
		# 已鎖定且需聲望：行本身吸收點擊但不做任何事（避免穿透）
		row.mouse_filter = Control.MOUSE_FILTER_STOP


func _toggle_dish(dish_id: String, rect: ColorRect, lbl: Label) -> void:
	var mm := get_node_or_null("/root/MenuManager")
	if mm == null:
		return

	var is_unlocked: bool = mm.is_dish_available(dish_id)

	if is_unlocked:
		mm.lock_dish(dish_id)
		rect.color = COLOR_OFF
		lbl.text = "OFF"
		lbl.add_theme_color_override("font_color", COLOR_OFF)
	else:
		mm.unlock_dish(dish_id)
		rect.color = COLOR_ON
		lbl.text = "ON"
		lbl.add_theme_color_override("font_color", COLOR_ON)


# ============================================================
# 工具
# ============================================================

func _apply_font(node: Control, size: int) -> void:
	if _font != null:
		node.add_theme_font_override("font", _font)
	node.add_theme_font_size_override("font_size", size)


func _on_dim_input(event: InputEvent) -> void:
	# 點擊 Panel 外部區域（透明 dim 層）時關閉
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 判斷是否點在 Panel 內部
		var panel_rect := Rect2(_panel_root.position, _panel_root.size)
		if not panel_rect.has_point(event.position):
			hide_panel()
