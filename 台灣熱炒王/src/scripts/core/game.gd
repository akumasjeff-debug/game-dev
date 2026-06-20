## game.gd
## 掛在 Game.tscn 根節點，負責初始化整個遊戲場景
## 包含地圖 Zone 設定、初始設備放置、信號連接、測試角色生成

extends Node2D

# 預載入 AI 腳本（確保 headless 模式也能識別 class_name）
const CustomerAIScript := preload("res://scripts/ai/customer_ai.gd")
const StaffAIScript := preload("res://scripts/ai/staff_ai.gd")

## 金錢飄字：記錄上一次金額，計算增量
var _last_money: float = 10000.0

## 客人持續生成系統
var _customer_spawn_timer: float = 0.0
const CUSTOMER_SPAWN_INTERVAL: float = 8.0  # 每 8 秒生成一個客人
const MAX_CUSTOMERS: int = 4               # 最多同時 4 個客人

# 客人入口位置（外場區右側邊緣，讓客人從右方進入）
const SPAWN_POSITIONS: Array = [
	Vector2(96, 64),
	Vector2(96, 48),
	Vector2(96, 72),
]


# ============================================================
# _ready
# ============================================================

func _process(delta: float) -> void:
	_tick_customer_spawn(delta)


func _tick_customer_spawn(delta: float) -> void:
	_customer_spawn_timer += delta
	if _customer_spawn_timer < CUSTOMER_SPAWN_INTERVAL:
		return
	_customer_spawn_timer = 0.0

	var container := get_node_or_null("characters")
	if container == null:
		return

	var current_count: int = container.get_children().filter(
		func(n): return n.is_in_group("customers")
	).size()

	if current_count >= MAX_CUSTOMERS:
		return

	var new_customer: Node2D = CustomerAIScript.new()
	var spawn_pos: Vector2 = SPAWN_POSITIONS[randi() % SPAWN_POSITIONS.size()]
	new_customer.position = spawn_pos
	container.add_child(new_customer)
	new_customer.add_to_group("customers")
	var sp_spawn: Sprite2D = _add_sprite(new_customer, "res://assets/sprites/characters/char_customer_a_idle.png")
	new_customer.set_sprite(sp_spawn)
	print("[game.gd] 新客人生成，當前總數: %d" % (current_count + 1))


func _ready() -> void:
	_init_map_zones()
	_draw_floor_visuals()
	_place_initial_equipment()
	_draw_equipment_visuals()
	_connect_game_signals()
	_spawn_test_customer()
	_spawn_test_staff()
	_setup_camera()
	_start_bgm()


# ============================================================
# 地圖初始化
# ============================================================

func _init_map_zones() -> void:
	# 廚房區（KITCHEN）：y in [1,2]，x in [1..6]
	for y in [1, 2]:
		for x in range(1, 7):
			BuildManager.set_zone(Vector2i(x, y), BuildManager.ZoneType.KITCHEN)

	# 走道區（WALKWAY）：y=3，x in [1..6]
	for x in range(1, 7):
		BuildManager.set_zone(Vector2i(x, 3), BuildManager.ZoneType.WALKWAY)

	# 外場區（SEATING）：y=4，x in [1..6]
	for x in range(1, 7):
		BuildManager.set_zone(Vector2i(x, 4), BuildManager.ZoneType.SEATING)

	print("[game.gd] 地圖 Zone 初始化完成")


# ============================================================
# 地板視覺（Sprite2D 像素 tile）
# ============================================================

func _draw_floor_visuals() -> void:
	var floor_node := get_node_or_null("floor_layer")
	if floor_node == null:
		push_warning("[game.gd] floor_layer 節點不存在，跳過地板視覺")
		return

	const TILE: int = 16

	# 各 Zone 對應的 tile 貼圖（y 軸對應 Zone 行）
	var zone_textures: Dictionary = {
		1: load("res://assets/sprites/tiles/tile_floor_kitchen.png"),
		2: load("res://assets/sprites/tiles/tile_floor_kitchen.png"),
		3: load("res://assets/sprites/tiles/tile_floor_corridor.png"),
		4: load("res://assets/sprites/tiles/tile_floor_dining.png"),
	}

	for y in range(1, 5):
		for x in range(1, 7):
			var sprite := Sprite2D.new()
			sprite.texture = zone_textures.get(y, null)
			sprite.centered = false
			sprite.position = Vector2(x * TILE, y * TILE)
			floor_node.add_child(sprite)

	print("[game.gd] 地板視覺繪製完成（像素 tile x%d）" % (4 * 6))


# ============================================================
# 初始設備放置
# ============================================================

func _place_initial_equipment() -> void:
	# 炒菜台：[行2,列2] = Vector2i(1, 1)
	BuildManager.place_equipment(Vector2i(1, 1), Vector2i(1, 1), "stove_wok_lv1")

	# 出菜台：[行3,列4] = Vector2i(3, 2)
	BuildManager.place_equipment(Vector2i(3, 2), Vector2i(1, 1), "counter_serving")

	# 折疊桌A：[行5,列3] = Vector2i(2, 4)
	BuildManager.place_equipment(Vector2i(2, 4), Vector2i(1, 1), "table_4p_a")

	# 折疊桌B：[行5,列6] = Vector2i(5, 4)
	BuildManager.place_equipment(Vector2i(5, 4), Vector2i(1, 1), "table_4p_b")

	print("[game.gd] 初始設備放置完成")


# ============================================================
# 設備視覺（Sprite2D）
# ============================================================

func _draw_equipment_visuals() -> void:
	var obj_node := get_node_or_null("object_layer")
	if obj_node == null:
		push_warning("[game.gd] object_layer 節點不存在，跳過設備視覺")
		return

	const TILE: int = 16

	# 炒菜台在 (1,1)
	var wok_sprite := Sprite2D.new()
	wok_sprite.texture = load("res://assets/sprites/equipment/equip_wok_static.png")
	wok_sprite.centered = false
	wok_sprite.position = Vector2(1 * TILE, 1 * TILE)
	obj_node.add_child(wok_sprite)

	# 4人桌A在 (2,4)
	var table_a := Sprite2D.new()
	table_a.texture = load("res://assets/sprites/equipment/table_4p.png")
	table_a.centered = false
	table_a.position = Vector2(2 * TILE, 4 * TILE)
	obj_node.add_child(table_a)

	# 4人桌B在 (5,4)
	var table_b := Sprite2D.new()
	table_b.texture = load("res://assets/sprites/equipment/table_4p.png")
	table_b.centered = false
	table_b.position = Vector2(5 * TILE, 4 * TILE)
	obj_node.add_child(table_b)

	print("[game.gd] 設備視覺繪製完成（炒菜台、4人桌A、4人桌B）")


# ============================================================
# 信號連接
# ============================================================

func _connect_game_signals() -> void:
	if not GameManager.day_started.is_connected(_on_day_started):
		GameManager.day_started.connect(_on_day_started)
	if not GameManager.day_ended.is_connected(_on_day_ended):
		GameManager.day_ended.connect(_on_day_ended)
	if not GameManager.money_changed.is_connected(_on_money_changed_for_popup):
		GameManager.money_changed.connect(_on_money_changed_for_popup)
	print("[game.gd] GameManager 信號連接完成")


func _on_day_started(year: int, day: int) -> void:
	print("[game.gd] 新的一天開始 — Year %d, Day %d" % [year, day])
	# 後續可更新場景狀態（開燈、員工就位等）


func _on_day_ended(income: float) -> void:
	print("[game.gd] 一天結束 — 今日收入: $%d" % int(income))
	# 後續可觸發結算 UI


# ============================================================
# 測試角色生成
# ============================================================

func _add_sprite(parent: Node2D, texture_path: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(texture_path)
	sprite.centered = false
	parent.add_child(sprite)
	return sprite


func _spawn_test_customer() -> void:
	var customer: Node2D = CustomerAIScript.new()
	customer.position = Vector2(60, 80)

	var container := get_node_or_null("characters")
	if container != null:
		container.add_child(customer)
	else:
		add_child(customer)

	customer.add_to_group("customers")
	var sp_customer: Sprite2D = _add_sprite(customer, "res://assets/sprites/characters/char_customer_a_idle.png")
	customer.set_sprite(sp_customer)
	print("[game.gd] 測試客人已生成，位置: ", customer.position)


func _spawn_test_staff() -> void:
	# 廚師 — 廚房區
	var chef: Node2D = StaffAIScript.new()
	chef.position = Vector2(24, 24)

	# 外場員工 — 外場區
	var waiter: Node2D = StaffAIScript.new()
	waiter.position = Vector2(40, 64)

	var container := get_node_or_null("characters")
	if container != null:
		container.add_child(chef)
		container.add_child(waiter)
	else:
		add_child(chef)
		add_child(waiter)

	var sp_chef: Sprite2D = _add_sprite(chef, "res://assets/sprites/characters/char_chef_idle.png")
	chef.set_sprite(sp_chef, true)
	var sp_waiter: Sprite2D = _add_sprite(waiter, "res://assets/sprites/characters/char_waiter_idle.png")
	waiter.set_sprite(sp_waiter, false)

	# 設定待機位置，讓 StaffAI 知道任務完成後要走回哪裡
	chef.set_home_position(Vector2(24, 24))
	waiter.set_home_position(Vector2(40, 64))

	print("[game.gd] 測試員工已生成（廚師: %s，外場: %s）" % [chef.position, waiter.position])


# ============================================================
# 攝影機設定
# ============================================================

func _setup_camera() -> void:
	var cam := get_node_or_null("Camera")
	if cam == null:
		push_warning("[game.gd] Camera 節點不存在，跳過攝影機設定")
		return
	# 地圖中心：x = (1+6)/2*16 = 56, y = (1+4)/2*16 = 40
	cam.position = Vector2(56, 40)
	print("[game.gd] 攝影機位置設定完成: ", cam.position)


# ============================================================
# BGM
# ============================================================

## 嘗試播放 BGM；若找不到音頻資源則優雅跳過
func _start_bgm() -> void:
	if not AudioManager.has_method("play_bgm"):
		print("[game.gd] AudioManager 沒有 play_bgm，跳過 BGM")
		return

	# 嘗試載入 main_theme 音頻（無檔案時跳過，不報 error）
	var bgm_path: String = "res://assets/audio/bgm/main_theme.ogg"
	if not ResourceLoader.exists(bgm_path):
		print("[game.gd] BGM 檔案不存在（%s），跳過 BGM 播放" % bgm_path)
		return

	var bgm_stream: AudioStream = load(bgm_path)
	if bgm_stream == null:
		print("[game.gd] BGM 載入失敗，跳過 BGM 播放")
		return

	AudioManager.play_bgm(bgm_stream)
	print("[game.gd] BGM 開始播放")


# ============================================================
# 金錢飄字
# ============================================================

## 監聽 money_changed 信號，只在金錢增加時顯示飄字
func _on_money_changed_for_popup(new_amount: float) -> void:
	if new_amount > _last_money:
		_show_money_popup(new_amount - _last_money)
	_last_money = new_amount


## 建立一個向上飄動並淡出的金錢 Label
## 使用獨立 CanvasLayer（layer=2）確保顯示在 HUD（layer=1）上方
func _show_money_popup(amount: float) -> void:
	var popup_layer := CanvasLayer.new()
	popup_layer.layer = 2
	get_tree().root.add_child(popup_layer)

	var label := Label.new()
	label.position = Vector2(240, 160)
	label.text = "+$%d" % int(amount)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))  # 金色
	popup_layer.add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30.0, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(popup_layer.queue_free)
	print("[game.gd] 金錢飄字：+$%d" % int(amount))
