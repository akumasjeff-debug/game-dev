## game.gd
## 掛在 Game.tscn 根節點，負責初始化整個遊戲場景
## 包含地圖 Zone 設定、初始設備放置、信號連接、測試角色生成

extends Node2D

# 預載入 AI 腳本（確保 headless 模式也能識別 class_name）
const CustomerAIScript := preload("res://scripts/ai/customer_ai.gd")
const StaffAIScript := preload("res://scripts/ai/staff_ai.gd")

## 金錢飄字：記錄上一次金額，計算增量
var _last_money: float = 10000.0

## 霓虹招牌閃爍
var _neon_sign_label: Label = null
var _neon_time: float = 0.0

## 客人持續生成系統
var _customer_spawn_timer: float = 0.0
const CUSTOMER_SPAWN_INTERVAL: float = 8.0  # 每 8 秒生成一個客人
const MAX_CUSTOMERS: int = 6               # 最多同時 6 個客人

## DEMO 寬限期：遊戲啟動後 5 分鐘內強制允許生成客人（is_open=false 時也生成）
var _demo_time_elapsed: float = 0.0
const DEMO_SPAWN_GRACE_PERIOD: float = 300.0

# 客人入口位置（外場區右側邊緣，讓客人從右方進入）
# SEATING 區在 y=4 行，像素 y=64；從右側 x=80 進入
const SPAWN_POSITIONS: Array = [
	Vector2(80, 64),
	Vector2(80, 48),
	Vector2(80, 72),
]


# ============================================================
# _ready
# ============================================================

func _process(delta: float) -> void:
	_demo_time_elapsed += delta
	_tick_customer_spawn(delta)
	# 招牌霓虹閃爍
	_neon_time += delta
	if _neon_sign_label != null and is_instance_valid(_neon_sign_label):
		var flicker: float = 0.85 + 0.15 * sin(_neon_time * 2.1)
		_neon_sign_label.modulate = Color(1.0, flicker, flicker * 0.7, 1.0)


func _tick_customer_spawn(delta: float) -> void:
	# 打烊時停止生成（DEMO 寬限期 5 分鐘內例外，讓展示畫面有客人）
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and not gm.is_open and _demo_time_elapsed > DEMO_SPAWN_GRACE_PERIOD:
		_customer_spawn_timer = 0.0  # 打烊時重置，確保開業後有完整等待期
		return

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
	# 使用色塊作為可見身體，不依賴外部貼圖
	new_customer.setup_visuals(new_customer)
	if new_customer.has_method("play_entrance_animation"):
		new_customer.play_entrance_animation()
	print("[game.gd] 新客人生成，當前總數: %d" % (current_count + 1))


func _ready() -> void:
	_init_map_zones()
	_draw_floor_visuals()
	_draw_zone_colored_floor()
	_place_initial_equipment()
	_draw_equipment_visuals()
	_draw_table_visuals()
	_draw_zone_divider()
	_draw_dining_area_lights()
	_connect_game_signals()
	_spawn_test_customer()
	_spawn_test_staff()
	_setup_camera()
	_start_bgm()
	_draw_neon_sign()


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
# 區域彩色地板（ColorRect 覆蓋 Sprite2D 底層）
# ============================================================

func _draw_zone_colored_floor() -> void:
	var floor_node := get_node_or_null("floor_layer")
	if floor_node == null:
		push_warning("[game.gd] floor_layer 節點不存在，跳過區域彩色地板")
		return

	const TILE: int = 16
	var zone_colors: Dictionary = {
		1: Color(0.16, 0.14, 0.18),  # 廚房列 1：深暗灰紫（加深對比）
		2: Color(0.16, 0.14, 0.18),  # 廚房列 2：深暗灰紫（加深對比）
		3: Color(0.25, 0.25, 0.28),  # 走道：中灰
		4: Color(0.35, 0.26, 0.16),  # 外場：暖棕（加亮）
	}

	for y in range(1, 5):
		for x in range(1, 7):
			var cr := ColorRect.new()
			cr.color = zone_colors[y]
			cr.size = Vector2(TILE, TILE)
			cr.position = Vector2(x * TILE, y * TILE)
			floor_node.add_child(cr)

	# 外場磁磚縫隙線（每格分界加深色縱線）
	for i in range(6):
		var grout := ColorRect.new()
		grout.color = Color(0.22, 0.16, 0.10)
		grout.size = Vector2(2, 16)
		grout.position = Vector2((i + 1) * TILE, 4 * TILE)
		floor_node.add_child(grout)

	print("[game.gd] 區域彩色地板繪製完成")


# ============================================================
# 桌面視覺（ColorRect 米色桌面）
# ============================================================

func _draw_table_visuals() -> void:
	var obj_node := get_node_or_null("object_layer")
	if obj_node == null:
		push_warning("[game.gd] object_layer 節點不存在，跳過桌面視覺")
		return

	const TILE: int = 16
	var table_positions: Array = [Vector2i(2, 4), Vector2i(4, 4), Vector2i(6, 4)]

	for tile in table_positions:
		var px: float = tile.x * TILE
		var py: float = tile.y * TILE

		# 深褐色邊框（底層，比桌子大 1px）
		var border := ColorRect.new()
		border.color = Color(0.35, 0.22, 0.08)
		border.size = Vector2(32, 22)
		border.position = Vector2(px, py)
		obj_node.add_child(border)

		# 桌面（明亮米色，對比暗棕地板）
		var cr := ColorRect.new()
		cr.color = Color(0.92, 0.83, 0.62)
		cr.size = Vector2(30, 20)
		cr.position = Vector2(px + 1, py + 1)
		obj_node.add_child(cr)

		# 上方椅子（台灣熱炒店鮮豔紅椅）
		var chair_top := ColorRect.new()
		chair_top.color = Color(0.82, 0.12, 0.08)
		chair_top.size = Vector2(10, 8)
		chair_top.position = Vector2(px + 11, py - 9)
		obj_node.add_child(chair_top)

		# 下方椅子（台灣熱炒店鮮豔紅椅）
		var chair_bot := ColorRect.new()
		chair_bot.color = Color(0.82, 0.12, 0.08)
		chair_bot.size = Vector2(10, 8)
		chair_bot.position = Vector2(px + 11, py + 22)
		obj_node.add_child(chair_bot)

	print("[game.gd] 桌面視覺繪製完成（桌A/桌B，含邊框+椅子）")


# ============================================================
# 走道分隔線（外場與走道之間的橘色線）
# ============================================================

func _draw_zone_divider() -> void:
	var obj_node := get_node_or_null("object_layer")
	if obj_node == null:
		push_warning("[game.gd] object_layer 節點不存在，跳過走道分隔線")
		return

	const TILE: int = 16

	# 上陰影線
	var shadow_top := ColorRect.new()
	shadow_top.color = Color(0.08, 0.06, 0.04, 0.8)
	shadow_top.size = Vector2(6 * TILE, 2)
	shadow_top.position = Vector2(1 * TILE, 4 * TILE - 3)
	obj_node.add_child(shadow_top)

	# 橘色分隔線
	var divider := ColorRect.new()
	divider.color = Color(0.95, 0.55, 0.1)  # 橘色
	divider.size = Vector2(6 * TILE, 2)
	divider.position = Vector2(1 * TILE, 4 * TILE - 1)
	obj_node.add_child(divider)

	# 下陰影線
	var shadow_bot := ColorRect.new()
	shadow_bot.color = Color(0.08, 0.06, 0.04, 0.8)
	shadow_bot.size = Vector2(6 * TILE, 2)
	shadow_bot.position = Vector2(1 * TILE, 4 * TILE + 1)
	obj_node.add_child(shadow_bot)

	print("[game.gd] 走道分隔線繪製完成（含上下陰影）")


# ============================================================
# 外場燈泡裝飾
# ============================================================

func _draw_dining_area_lights() -> void:
	var obj_node := get_node_or_null("object_layer")
	if obj_node == null:
		return
	const TILE: int = 16
	# 在分隔線上方加燈泡裝飾（5顆均勻分布吊燈，5x5px）
	for i in range(5):
		# 燈泡光暈（12x8px 淡黃色，位於燈泡下方）
		var glow := ColorRect.new()
		glow.color = Color(1.0, 0.92, 0.6, 0.12)
		glow.size = Vector2(12, 8)
		glow.position = Vector2(TILE + i * 16 + 4 - 4, TILE * 4 - 8 + 5)
		obj_node.add_child(glow)

		# 燈泡本體（暖白色，5x5px，位置更高）
		var bulb := ColorRect.new()
		bulb.color = Color(1.0, 0.98, 0.85, 0.9)
		bulb.size = Vector2(5, 5)
		bulb.position = Vector2(TILE + i * 16 + 4, TILE * 4 - 8)
		obj_node.add_child(bulb)

	# 橘色霓虹反光條（外場入口橫條，模擬燈光落地）
	var neon_glow := ColorRect.new()
	neon_glow.color = Color(0.95, 0.55, 0.1, 0.15)
	neon_glow.size = Vector2(6 * TILE, 5)
	neon_glow.position = Vector2(TILE, TILE * 4)
	obj_node.add_child(neon_glow)

	print("[game.gd] 外場燈泡裝飾繪製完成（5顆吊燈+光暈+霓虹反光）")


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

	# 折疊桌B：[行5,列6] = Vector2i(5, 4)（位置調整為中間桌）
	BuildManager.place_equipment(Vector2i(5, 4), Vector2i(1, 1), "table_4p_b")

	# 折疊桌C：[行5,列7] = Vector2i(6, 4)（新增右側第三張桌）
	BuildManager.place_equipment(Vector2i(6, 4), Vector2i(1, 1), "table_4p_c")

	# 登記初始座位到 SeatManager（每張 4人桌登記 4 個座位格）
	var sm := get_node_or_null("/root/SeatManager")
	if sm != null:
		# 桌A：Vector2i(2,4) 及周圍座位
		sm.register_seat(Vector2i(2, 4))
		sm.register_seat(Vector2i(3, 4))
		# 桌B：Vector2i(4,4) 中間桌座位（原桌B位置調整）
		sm.register_seat(Vector2i(4, 4))
		sm.register_seat(Vector2i(5, 4))
		# 桌C：Vector2i(6,4) 右側新桌座位（register_seat 有重複防呆）
		sm.register_seat(Vector2i(6, 4))
		print("[game.gd] 已登記 5 個初始座位（三張桌）")

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

	# 廚房後壁基線（深灰橫條，代表廚房後牆）
	var kitchen_wall := ColorRect.new()
	kitchen_wall.color = Color(0.15, 0.15, 0.18)
	kitchen_wall.size = Vector2(6 * TILE, 3)
	kitchen_wall.position = Vector2(1 * TILE, 1 * TILE)
	obj_node.add_child(kitchen_wall)

	# 炒菜台在 (1,1) — 深棕台面 + 亮灰鍋子 + 火焰 + 頂部邊框
	var wok_base := ColorRect.new()
	wok_base.color = Color(0.32, 0.22, 0.10)   # 深棕台面
	wok_base.size = Vector2(28, 16)
	wok_base.position = Vector2(1 * TILE, 1 * TILE + 2)
	obj_node.add_child(wok_base)

	# 台面頂部邊框（深色線條感）
	var wok_border := ColorRect.new()
	wok_border.color = Color(0.18, 0.18, 0.20)
	wok_border.size = Vector2(28, 2)
	wok_border.position = Vector2(1 * TILE, 1 * TILE + 2)
	obj_node.add_child(wok_border)

	var wok_pot := ColorRect.new()
	wok_pot.color = Color(0.6, 0.6, 0.62)    # 亮灰鍋子
	wok_pot.size = Vector2(18, 10)
	wok_pot.position = Vector2(1 * TILE + 5, 1 * TILE + 5)
	obj_node.add_child(wok_pot)

	# 火焰效果（鍋子下方兩個橘色點）
	var flame_l := ColorRect.new()
	flame_l.color = Color(0.95, 0.45, 0.05)
	flame_l.size = Vector2(4, 4)
	flame_l.position = Vector2(1 * TILE + 7, 1 * TILE + 14)
	obj_node.add_child(flame_l)

	var flame_r := ColorRect.new()
	flame_r.color = Color(1.0, 0.65, 0.1)
	flame_r.size = Vector2(4, 4)
	flame_r.position = Vector2(1 * TILE + 13, 1 * TILE + 14)
	obj_node.add_child(flame_r)

	# 炒菜台標籤「炒菜台 Lv.1」
	var wok_label := Label.new()
	wok_label.text = "Wok Lv.1"
	wok_label.position = Vector2(1 * TILE, 1 * TILE - 12)
	wok_label.add_theme_font_size_override("font_size", 6)
	wok_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	var label_font_path := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf"
	if ResourceLoader.exists(label_font_path):
		var lf = load(label_font_path)
		wok_label.add_theme_font_override("font", lf)
		wok_label.text = "炒菜台 Lv.1"
	obj_node.add_child(wok_label)

	# 收銀台（出菜台）在 (3,2) — 木棕色台面 + 收銀機螢幕
	var counter := ColorRect.new()
	counter.color = Color(0.42, 0.28, 0.12)    # 木棕色
	counter.size = Vector2(20, 12)
	counter.position = Vector2(3 * TILE + 1, 2 * TILE + 3)
	obj_node.add_child(counter)

	# 收銀機螢幕（深藍綠）
	var counter_screen := ColorRect.new()
	counter_screen.color = Color(0.08, 0.28, 0.22)
	counter_screen.size = Vector2(10, 7)
	counter_screen.position = Vector2(3 * TILE + 5, 2 * TILE + 4)
	obj_node.add_child(counter_screen)

	# 桌A 和 桌B 的 Sprite2D（若貼圖存在才加）
	for table_pos in [Vector2i(2, 4), Vector2i(5, 4)]:
		var path := "res://assets/sprites/equipment/table_4p.png"
		if ResourceLoader.exists(path):
			var table_spr := Sprite2D.new()
			table_spr.texture = load(path)
			table_spr.centered = false
			table_spr.position = Vector2(table_pos.x * TILE, table_pos.y * TILE)
			obj_node.add_child(table_spr)

	print("[game.gd] 設備視覺繪製完成（炒菜台ColorRect + 收銀台 + 桌椅）")


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
	# SEATING 區 y=4 行中心，x=48 對應第 3 格（像素 16*3=48）
	customer.position = Vector2(48, 64)

	var container := get_node_or_null("characters")
	if container != null:
		container.add_child(customer)
	else:
		add_child(customer)

	customer.add_to_group("customers")
	# 使用色塊作為可見身體，不依賴外部貼圖
	customer.setup_visuals(customer)
	if customer.has_method("play_entrance_animation"):
		customer.play_entrance_animation()
	print("[game.gd] 測試客人已生成，位置: ", customer.position)


func _spawn_test_staff() -> void:
	# 廚師 — 廚房區（炒菜台旁偏下，視覺更合理）
	var chef: Node2D = StaffAIScript.new()
	chef.position = Vector2(20, 36)

	# 外場員工 — 外場中央略右，靠近桌椅區
	var waiter: Node2D = StaffAIScript.new()
	waiter.position = Vector2(56, 72)

	var container := get_node_or_null("characters")
	if container != null:
		container.add_child(chef)
		container.add_child(waiter)
	else:
		add_child(chef)
		add_child(waiter)

	# 廚師色塊（深藍廚師服）
	var chef_body := ColorRect.new()
	chef_body.color = Color(0.1, 0.22, 0.42)  # 深藍廚師服
	chef_body.size = Vector2(10, 18)
	chef_body.position = Vector2(-5, -14)
	chef.add_child(chef_body)
	# 廚師左臂
	var chef_arm_l := ColorRect.new()
	chef_arm_l.color = Color(0.1, 0.22, 0.42)
	chef_arm_l.size = Vector2(3, 6)
	chef_arm_l.position = Vector2(-8, -12)
	chef.add_child(chef_arm_l)
	# 廚師右臂
	var chef_arm_r := ColorRect.new()
	chef_arm_r.color = Color(0.1, 0.22, 0.42)
	chef_arm_r.size = Vector2(3, 6)
	chef_arm_r.position = Vector2(5, -12)
	chef.add_child(chef_arm_r)
	var chef_head := ColorRect.new()
	chef_head.color = Color(0.85, 0.68, 0.52)   # 稍深膚色
	chef_head.size = Vector2(10, 6)
	chef_head.position = Vector2(-5, -20)
	chef.add_child(chef_head)
	# 廚師帽（略灰白）
	var chef_hat := ColorRect.new()
	chef_hat.color = Color(0.95, 0.95, 0.95)
	chef_hat.size = Vector2(8, 4)
	chef_hat.position = Vector2(-4, -24)
	chef.add_child(chef_hat)

	# 外場員工色塊（黑色工作服）
	var waiter_body := ColorRect.new()
	waiter_body.color = Color(0.15, 0.15, 0.2)  # 深色工作服
	waiter_body.size = Vector2(10, 18)
	waiter_body.position = Vector2(-5, -14)
	waiter.add_child(waiter_body)
	var waiter_head := ColorRect.new()
	waiter_head.color = Color(0.9, 0.75, 0.6)
	waiter_head.size = Vector2(10, 6)
	waiter_head.position = Vector2(-5, -20)
	waiter.add_child(waiter_head)

	# 載入廚師 Sprite2D
	# chef_a2.png 內容區域從 x=26, y=14 開始，不適合直接用 region(0,0,24,32)
	# 改用 char_chef_idle.png（16x24px，整張圖即為廚師待機幀，像素正確）
	var char_chef_path := "res://assets/sprites/characters/char_chef_idle.png"
	if ResourceLoader.exists(char_chef_path):
		var chef_spr := Sprite2D.new()
		var chef_tex = load(char_chef_path)
		if chef_tex != null:
			chef_spr.texture = chef_tex
			chef_spr.centered = true
			chef_spr.position = Vector2(0, -12)  # 以角色中心對齊節點原點
			chef_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # 像素清晰
			chef.add_child(chef_spr)
			# 有 sprite 時隱藏 ColorRect
			chef_body.visible = false
			chef_arm_l.visible = false
			chef_arm_r.visible = false
			chef_head.visible = false
			chef_hat.visible = false
			chef.set_sprite(chef_spr, true)
			print("[game.gd] 廚師使用 char_chef_idle.png sprite（16x24px）")
		else:
			chef.set_sprite(null, true)
	else:
		chef.set_sprite(null, true)

	var waiter_tex_path := "res://assets/sprites/characters/char_waiter_idle.png"
	if ResourceLoader.exists(waiter_tex_path):
		var sp_waiter: Sprite2D = _add_sprite(waiter, waiter_tex_path)
		waiter.set_sprite(sp_waiter, false)
	else:
		waiter.set_sprite(null, false)

	# 設定待機位置，讓 StaffAI 知道任務完成後要走回哪裡
	chef.set_home_position(Vector2(20, 36))
	waiter.set_home_position(Vector2(56, 72))

	print("[game.gd] 測試員工已生成（廚師: %s，外場: %s）" % [chef.position, waiter.position])


# ============================================================
# 攝影機設定
# ============================================================

func _setup_camera() -> void:
	var cam := get_node_or_null("Camera")
	if cam == null:
		push_warning("[game.gd] Camera 節點不存在，跳過攝影機設定")
		return
	# zoom=2.5 讓整個店面廚房+外場都可見，留有適當邊距
	# position=(60,50) 建築中心偏下，讓外場完整可見
	cam.position = Vector2(60, 50)
	cam.zoom = Vector2(2.5, 2.5)
	cam.make_current()
	print("[game.gd] 攝影機位置設定完成: ", cam.position, " zoom: ", cam.zoom)


# ============================================================
# BGM
# ============================================================

## 嘗試播放 BGM；優先 .wav，其次 .ogg，均無則跳過
func _start_bgm() -> void:
	if not AudioManager.has_method("play_bgm"):
		print("[game.gd] AudioManager 沒有 play_bgm，跳過 BGM")
		return

	# 優先尋找 .wav，其次 .ogg
	var bgm_paths: Array[String] = [
		"res://assets/audio/bgm/main_theme.wav",
		"res://assets/audio/bgm/main_theme.ogg",
	]
	var bgm_stream: AudioStream = null
	for p in bgm_paths:
		if ResourceLoader.exists(p):
			bgm_stream = load(p)
			if bgm_stream != null:
				print("[game.gd] 載入 BGM：%s" % p)
				break

	if bgm_stream == null:
		print("[game.gd] BGM 檔案不存在，跳過 BGM 播放")
		return

	AudioManager.play_bgm(bgm_stream)
	print("[game.gd] BGM 開始播放")


# ============================================================
# 霓虹招牌
# ============================================================

func _draw_neon_sign() -> void:
	var obj_node := get_node_or_null("object_layer")
	if obj_node == null:
		return
	# 霓虹招牌：在廚房上方（y=2px 附近）
	# 先加紅色邊框底層（74x16px）
	var sign_border := ColorRect.new()
	sign_border.color = Color(0.8, 0.1, 0.05)
	sign_border.size = Vector2(74, 16)
	sign_border.position = Vector2(15, 1)
	obj_node.add_child(sign_border)

	# 深紫背景（72x14px，偏移 1px 製造邊框效果）
	var sign_bg := ColorRect.new()
	sign_bg.color = Color(0.18, 0.04, 0.28, 0.95)
	sign_bg.size = Vector2(72, 14)
	sign_bg.position = Vector2(16, 2)
	obj_node.add_child(sign_bg)

	var sign_label := Label.new()
	sign_label.text = "阿嬤熱炒"
	sign_label.position = Vector2(18, 2)
	sign_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.1))
	sign_label.add_theme_font_size_override("font_size", 8)
	var font_path := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf"
	if ResourceLoader.exists(font_path):
		sign_label.add_theme_font_override("font", load(font_path))
	obj_node.add_child(sign_label)
	_neon_sign_label = sign_label
	print("[game.gd] 霓虹招牌繪製完成（深紫背景+紅色邊框）")


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
## 使用 call_deferred 避免在 _ready() 階段 add_child 時的節點忙碌警告
func _show_money_popup(amount: float) -> void:
	# 延遲一幀再建立，確保節點樹穩定
	_spawn_money_popup_deferred.call_deferred(amount)


func _spawn_money_popup_deferred(amount: float) -> void:
	var popup_layer := CanvasLayer.new()
	popup_layer.layer = 2
	get_tree().root.add_child(popup_layer)

	var label := Label.new()
	label.position = Vector2(200, 180)
	label.text = "+$%d" % int(amount)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))  # 金色
	label.add_theme_font_size_override("font_size", 14)
	var popup_font_path := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf"
	if ResourceLoader.exists(popup_font_path):
		label.add_theme_font_override("font", load(popup_font_path))
	popup_layer.add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30.0, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(popup_layer.queue_free)
	print("[game.gd] 金錢飄字：+$%d" % int(amount))
