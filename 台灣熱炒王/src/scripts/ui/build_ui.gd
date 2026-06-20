## build_ui.gd
## 建造模式 UI 腳本，掛載於 UI.tscn 的 build_layer/BuildPanel 下。
## 負責：
##   1. 進入建造模式時，在每個格子覆蓋 Zone 顏色（半透明 alpha 30%）
##   2. 玩家點擊格子時呼叫 BuildManager.set_zone() 切換 Zone 類型
##   3. 選中設備後，游標格子顯示半透明預覽（綠=可放置，紅=不可放置）
##   4. 點擊放置呼叫 BuildManager.place_equipment_in_zone()，觸發縮放動畫
##   5. 走道斷路時在底部 HUD 即時訊息區顯示警告，3 秒後淡出
##
## 使用方式：
##   1. 將此腳本掛到 UI.tscn 的 BuildPanel（build_layer 下）
##   2. 確保 BuildManager 已設為 AutoLoad
##   3. 進入建造模式時呼叫 enter_build_mode()，退出時呼叫 exit_build_mode()

extends Node

# ──────────────────────────────────────────
# 常數
# ──────────────────────────────────────────

const TILE_SIZE: int = 16

## Zone 對應的半透明覆蓋顏色（alpha 30% = 0.3）
const ZONE_COLORS: Dictionary = {
	BuildManager.ZoneType.KITCHEN:    Color(1.000, 0.420, 0.208, 0.30),  # #FF6B35
	BuildManager.ZoneType.SEATING:    Color(1.000, 0.973, 0.863, 0.30),  # #FFF8DC
	BuildManager.ZoneType.WALKWAY:    Color(0.800, 0.800, 0.800, 0.30),  # #CCCCCC
	BuildManager.ZoneType.STORAGE:    Color(0.545, 0.412, 0.078, 0.30),  # #8B6914
	BuildManager.ZoneType.DECORATION: Color(0.298, 0.686, 0.314, 0.30),  # #4CAF50
}

## 設備預覽顏色
const PREVIEW_CAN_PLACE:    Color = Color(0.000, 0.824, 0.416, 0.45)  # 綠色
const PREVIEW_CANNOT_PLACE: Color = Color(1.000, 0.176, 0.333, 0.45)  # 紅色

## 走道斷路訊息顯示時間（秒）
const WALKWAY_WARNING_DURATION: float = 3.0

## 走道連通性輪詢間隔（秒）
const WALKWAY_POLL_INTERVAL: float = 0.5

## 走道連通性檢查：預設從地圖左上角到右下角
## 可依實際入口/出口格修改
const WALKWAY_CHECK_FROM: Vector2i = Vector2i(6, 4)  # 入口格（initial-map.md 定案）
const WALKWAY_CHECK_TO:   Vector2i = Vector2i(3, 4)  # 出菜台格

# ──────────────────────────────────────────
# 內部狀態
# ──────────────────────────────────────────

## 是否在建造模式
var _in_build_mode: bool = false

## 目前選中的設備資料（nil 表示無選中設備，處於 Zone 點擊模式）
## 格式：{ "id": String, "size": Vector2i, "zone": BuildManager.ZoneType }
var _selected_equipment: Dictionary = {}

## 游標目前所在的格子座標
var _cursor_tile: Vector2i = Vector2i(-1, -1)

## 走道連通性輪詢計時器
var _walkway_poll_timer: float = 0.0

## 上一次走道連通狀態（用於偵測狀態改變）
var _last_walkway_connected: bool = true

## 警告淡出 Tween（用於取消舊的 Tween）
var _warning_tween: Tween = null

# ──────────────────────────────────────────
# 節點引用（@onready）
# ──────────────────────────────────────────

@onready var _build_manager: BuildManager = BuildManager

## Zone 覆蓋層：使用 CanvasLayer 繪製所有格子的 ColorRect
## 此節點在 enter_build_mode() 時動態建立，exit_build_mode() 時清除
var _zone_overlay_root: Node2D = null

## 預覽 ColorRect（游標格子上的半透明預覽）
var _preview_rect: ColorRect = null

## 底部 HUD 即時訊息 Label（需在場景內找到）
## 路徑：/root/Main/UI/hud_layer/HUD/BottomHUD/MessageLabel（依實際場景調整）
var _message_label: Label = null

## 警告訊息的容器（若找不到 HUD Label，自行建立備用 Label）
var _fallback_message_label: Label = null

# ──────────────────────────────────────────
# 初始化
# ──────────────────────────────────────────

func _ready() -> void:
	# 嘗試尋找底部 HUD 的即時訊息 Label
	# 路徑依 UI.tscn 實際節點名稱調整
	_try_find_message_label()

	# 連接 BuildManager 信號
	_build_manager.equipment_placed.connect(Callable(self, "_on_equipment_placed"))
	_build_manager.zone_changed.connect(Callable(self, "_on_zone_changed"))


func _try_find_message_label() -> void:
	## 嘗試從場景樹找底部 HUD 的 MessageLabel。
	## 若找不到，建立備用 Label 附在 CanvasLayer 上。
	var hud: Node = get_tree().root.find_child("HUD", true, false)
	if hud:
		var label: Node = hud.find_child("MessageLabel", true, false)
		if label and label is Label:
			_message_label = label as Label
			return

	# 找不到時建立備用 Label
	_create_fallback_message_label()


func _create_fallback_message_label() -> void:
	## 建立備用訊息 Label，掛在目前節點的 CanvasLayer 上。
	## 位置：底部中間，模擬 HUD 底部訊息區。
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.name = "BuildWarningLayer"
	canvas.layer = 10
	add_child(canvas)

	var label: Label = Label.new()
	label.name = "FallbackMessageLabel"
	label.text = ""
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(1, 1, 1, 0)  # 預設透明

	# 定位到底部中間（對應 480x270 解析度）
	var container: Control = Control.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	container.set_custom_minimum_size(Vector2(480, 28))
	container.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	canvas.add_child(container)
	_fallback_message_label = label

# ──────────────────────────────────────────
# 公開介面
# ──────────────────────────────────────────

## 進入建造模式。由外部（例如 HUD 建造按鈕）呼叫。
func enter_build_mode() -> void:
	if _in_build_mode:
		return
	_in_build_mode = true
	_selected_equipment = {}
	_cursor_tile = Vector2i(-1, -1)
	_last_walkway_connected = _check_walkway_connected()
	_walkway_poll_timer = 0.0

	_build_zone_overlay()
	_build_preview_rect()


## 離開建造模式。
func exit_build_mode() -> void:
	if not _in_build_mode:
		return
	_in_build_mode = false
	_selected_equipment = {}
	_cursor_tile = Vector2i(-1, -1)

	_destroy_zone_overlay()
	_destroy_preview_rect()


## 選中設備（從工具列點選後呼叫）。
## equipment_data 格式：{ "id": String, "size": Vector2i, "zone": BuildManager.ZoneType }
func select_equipment(equipment_data: Dictionary) -> void:
	_selected_equipment = equipment_data


## 清除設備選擇（回到 Zone 點擊模式）。
func deselect_equipment() -> void:
	_selected_equipment = {}

# ──────────────────────────────────────────
# 輸入處理
# ──────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not _in_build_mode:
		return

	if event is InputEventMouseMotion:
		_on_mouse_moved(event.position)

	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_on_left_click(mb.position)


func _on_mouse_moved(screen_pos: Vector2) -> void:
	## 將螢幕像素座標轉換為格子座標並更新游標。
	var tile: Vector2i = _screen_to_tile(screen_pos)
	if tile == _cursor_tile:
		return
	_cursor_tile = tile
	_update_preview()


func _on_left_click(screen_pos: Vector2) -> void:
	var tile: Vector2i = _screen_to_tile(screen_pos)
	if not _is_tile_in_bounds(tile):
		return

	if _selected_equipment.is_empty():
		# Zone 點擊模式：切換格子 Zone 類型
		_cycle_zone(tile)
	else:
		# 設備放置模式
		_try_place_equipment(tile)

# ──────────────────────────────────────────
# 格子座標轉換
# ──────────────────────────────────────────

func _screen_to_tile(screen_pos: Vector2) -> Vector2i:
	## 將螢幕像素座標轉為格子座標。
	## 假設地圖左上角對應螢幕 (0, 28)（頂部 HUD 28px）。
	## 若有 Camera2D 或 Viewport 縮放，需另行處理 transform。
	var map_origin: Vector2 = Vector2(0, 28)
	var local: Vector2 = screen_pos - map_origin
	return Vector2i(
		int(local.x) / TILE_SIZE,
		int(local.y) / TILE_SIZE
	)


func _tile_to_screen_pos(tile: Vector2i) -> Vector2:
	## 格子座標轉換為螢幕像素座標（格子左上角）。
	var map_origin: Vector2 = Vector2(0, 28)
	return map_origin + Vector2(tile.x * TILE_SIZE, tile.y * TILE_SIZE)


func _is_tile_in_bounds(tile: Vector2i) -> bool:
	return (
		tile.x >= 0 and tile.x < BuildManager.MAP_WIDTH and
		tile.y >= 0 and tile.y < BuildManager.MAP_HEIGHT
	)

# ──────────────────────────────────────────
# Zone 覆蓋層
# ──────────────────────────────────────────

func _build_zone_overlay() -> void:
	## 建立所有格子的 Zone 顏色覆蓋層。
	## 使用 Node2D 作根節點，每格一個 ColorRect 子節點。
	if _zone_overlay_root:
		_destroy_zone_overlay()

	_zone_overlay_root = Node2D.new()
	_zone_overlay_root.name = "ZoneOverlay"

	# 掛在 build_layer 的 CanvasLayer 上
	# 此腳本預期掛在 BuildPanel，BuildPanel 的父節點是 build_layer (CanvasLayer)
	# 因此在父節點 CanvasLayer 下加入 Node2D overlay
	get_parent().add_child(_zone_overlay_root)

	for y in range(BuildManager.MAP_HEIGHT):
		for x in range(BuildManager.MAP_WIDTH):
			var tile := Vector2i(x, y)
			var zone: BuildManager.ZoneType = _build_manager.get_zone(tile)
			_create_zone_rect(tile, zone)


func _create_zone_rect(tile: Vector2i, zone: BuildManager.ZoneType) -> void:
	## 建立單一格子的 ColorRect 覆蓋。
	if not _zone_overlay_root:
		return

	var rect: ColorRect = ColorRect.new()
	rect.name = "zone_%d_%d" % [tile.x, tile.y]
	rect.size = Vector2(TILE_SIZE, TILE_SIZE)
	rect.position = _tile_to_screen_pos(tile)

	if ZONE_COLORS.has(zone):
		rect.color = ZONE_COLORS[zone]
	else:
		rect.color = Color(0, 0, 0, 0)  # EMPTY 或未定義：完全透明

	_zone_overlay_root.add_child(rect)


func _update_zone_rect(tile: Vector2i, zone: BuildManager.ZoneType) -> void:
	## 更新單一格子的覆蓋顏色（回應 zone_changed 信號）。
	if not _zone_overlay_root:
		return
	var rect_name: String = "zone_%d_%d" % [tile.x, tile.y]
	var rect: Node = _zone_overlay_root.find_child(rect_name, false, false)
	if rect and rect is ColorRect:
		var color_rect: ColorRect = rect as ColorRect
		if ZONE_COLORS.has(zone):
			color_rect.color = ZONE_COLORS[zone]
		else:
			color_rect.color = Color(0, 0, 0, 0)


func _destroy_zone_overlay() -> void:
	if _zone_overlay_root:
		_zone_overlay_root.queue_free()
		_zone_overlay_root = null

# ──────────────────────────────────────────
# 設備預覽
# ──────────────────────────────────────────

func _build_preview_rect() -> void:
	## 建立游標格子的半透明預覽 ColorRect。
	if _preview_rect:
		_destroy_preview_rect()

	_preview_rect = ColorRect.new()
	_preview_rect.name = "EquipmentPreview"
	_preview_rect.size = Vector2(TILE_SIZE, TILE_SIZE)
	_preview_rect.color = Color(0, 0, 0, 0)  # 初始透明
	_preview_rect.visible = false

	get_parent().add_child(_preview_rect)


func _update_preview() -> void:
	## 依游標格子更新預覽 ColorRect 的位置與顏色。
	if not _preview_rect:
		return

	if _selected_equipment.is_empty() or not _is_tile_in_bounds(_cursor_tile):
		_preview_rect.visible = false
		return

	_preview_rect.visible = true

	var size: Vector2i = _selected_equipment.get("size", Vector2i(1, 1)) as Vector2i
	var zone: BuildManager.ZoneType = _selected_equipment.get(
		"zone", BuildManager.ZoneType.EMPTY
	) as BuildManager.ZoneType

	var can_place: bool = _build_manager.check_placement(_cursor_tile, size, zone)

	_preview_rect.position = _tile_to_screen_pos(_cursor_tile)
	_preview_rect.size = Vector2(size.x * TILE_SIZE, size.y * TILE_SIZE)
	_preview_rect.color = PREVIEW_CAN_PLACE if can_place else PREVIEW_CANNOT_PLACE


func _destroy_preview_rect() -> void:
	if _preview_rect:
		_preview_rect.queue_free()
		_preview_rect = null

# ──────────────────────────────────────────
# Zone 點擊切換
# ──────────────────────────────────────────

## Zone 循環順序
const ZONE_CYCLE: Array = [
	BuildManager.ZoneType.EMPTY,
	BuildManager.ZoneType.KITCHEN,
	BuildManager.ZoneType.SEATING,
	BuildManager.ZoneType.WALKWAY,
	BuildManager.ZoneType.STORAGE,
	BuildManager.ZoneType.DECORATION,
]

func _cycle_zone(tile: Vector2i) -> void:
	## 點擊格子時，依循環順序切換到下一個 Zone 類型。
	var current: BuildManager.ZoneType = _build_manager.get_zone(tile)
	var idx: int = ZONE_CYCLE.find(current)
	if idx < 0:
		idx = 0
	var next_idx: int = (idx + 1) % ZONE_CYCLE.size()
	var next_zone: BuildManager.ZoneType = ZONE_CYCLE[next_idx] as BuildManager.ZoneType
	_build_manager.set_zone(tile, next_zone)

# ──────────────────────────────────────────
# 設備放置
# ──────────────────────────────────────────

func _try_place_equipment(tile: Vector2i) -> void:
	## 嘗試在格子放置選中設備，成功後觸發縮放動畫。
	if _selected_equipment.is_empty():
		return

	var equipment_id: String = _selected_equipment.get("id", "") as String
	var size: Vector2i = _selected_equipment.get("size", Vector2i(1, 1)) as Vector2i
	var zone: BuildManager.ZoneType = _selected_equipment.get(
		"zone", BuildManager.ZoneType.EMPTY
	) as BuildManager.ZoneType

	if equipment_id == "":
		return

	var success: bool = _build_manager.place_equipment_in_zone(tile, size, equipment_id, zone)
	if success:
		_play_place_animation(tile, size)


func _play_place_animation(tile: Vector2i, size: Vector2i) -> void:
	## 放置成功動畫：在放置格子上顯示一個白色閃光 ColorRect，
	## 同時對覆蓋格子做縮放效果（100%→120%→100%，200ms）。
	##
	## 注意：實際設備 Sprite 的縮放動畫需由設備節點自己處理；
	## 這裡用一個暫時的閃光 ColorRect 作為 UI 層的視覺反饋，
	## 縮放以 _zone_overlay_root 的 scale 屬性模擬（僅影響 overlay）。

	var flash: ColorRect = ColorRect.new()
	flash.size = Vector2(size.x * TILE_SIZE, size.y * TILE_SIZE)
	flash.position = _tile_to_screen_pos(tile)
	flash.color = Color(1, 1, 1, 0.6)  # 白色閃光
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if _zone_overlay_root:
		_zone_overlay_root.add_child(flash)
	else:
		get_parent().add_child(flash)

	# 縮放動畫：100%→120%→100%，總時長 200ms
	var tween: Tween = create_tween()
	tween.tween_property(flash, "scale", Vector2(1.2, 1.2), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_IN)
	# 動畫結束後淡出並移除
	tween.tween_property(flash, "modulate:a", 0.0, 0.05)
	tween.tween_callback(Callable(flash, "queue_free"))

# ──────────────────────────────────────────
# 走道連通性輪詢
# ──────────────────────────────────────────

func _process(delta: float) -> void:
	if not _in_build_mode:
		return

	_walkway_poll_timer += delta
	if _walkway_poll_timer >= WALKWAY_POLL_INTERVAL:
		_walkway_poll_timer = 0.0
		_poll_walkway_connectivity()


func _poll_walkway_connectivity() -> void:
	## 輪詢走道連通性，若狀態從「連通」→「斷路」則顯示警告。
	## BuildManager 無 walkway_blocked 信號，以輪詢替代。
	var connected: bool = _check_walkway_connected()
	if _last_walkway_connected and not connected:
		_show_walkway_warning()
	_last_walkway_connected = connected


func _check_walkway_connected() -> bool:
	## 呼叫 BuildManager.is_path_connected() 檢查走道是否連通。
	return _build_manager.is_path_connected(WALKWAY_CHECK_FROM, WALKWAY_CHECK_TO)

# ──────────────────────────────────────────
# 走道斷路警告
# ──────────────────────────────────────────

func _show_walkway_warning() -> void:
	## 在底部 HUD 即時訊息區顯示「⚠ 通道堵住了！員工出不去」，3 秒後淡出。
	var label: Label = _get_active_message_label()
	if not label:
		return

	label.text = "⚠ 通道堵住了！員工出不去"
	label.modulate = Color(1, 0.9, 0.2, 1.0)  # 黃色警告字

	# 取消舊的淡出 Tween
	if _warning_tween and _warning_tween.is_valid():
		_warning_tween.kill()

	# 顯示 3 秒後淡出
	_warning_tween = create_tween()
	_warning_tween.tween_interval(WALKWAY_WARNING_DURATION)
	_warning_tween.tween_property(label, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
	_warning_tween.tween_callback(Callable(self, "_clear_warning_label").bind(label))


func _clear_warning_label(label: Label) -> void:
	label.text = ""
	label.modulate = Color(1, 1, 1, 1)


func _get_active_message_label() -> Label:
	## 優先使用找到的 HUD Label，否則用備用 Label。
	if _message_label and is_instance_valid(_message_label):
		return _message_label
	if _fallback_message_label and is_instance_valid(_fallback_message_label):
		_fallback_message_label.modulate = Color(1, 0.9, 0.2, 1.0)
		return _fallback_message_label
	return null

# ──────────────────────────────────────────
# 信號回調
# ──────────────────────────────────────────

func _on_zone_changed(tile: Vector2i, zone: BuildManager.ZoneType) -> void:
	## BuildManager 發出 zone_changed 時，更新對應格子的覆蓋顏色。
	_update_zone_rect(tile, zone)


func _on_equipment_placed(tile: Vector2i, _equipment_id: String) -> void:
	## 設備放置後，同步更新覆蓋層（設備格子可能改變顯示需求）。
	## 目前僅更新游標格子的預覽狀態。
	_update_preview()
