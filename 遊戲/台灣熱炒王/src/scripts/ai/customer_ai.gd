## CustomerAI.gd
## 客人 AI — Node2D
## 對應 FSM 設計：godot-architecture.md § C（CustomerFSM）
## 每位客人是獨立節點，由 CustomerSpawner 生成並掛入 characters 容器

class_name CustomerAI
extends Node2D


# ============================================================
# 信號定義
# ============================================================

## 客人離開時發出（satisfaction：0.0 生氣離開 / 1.0 滿意離開）
signal customer_left(satisfaction: float)

## 客人下單時發出（dish_id：對應菜色資料表的 ID）
signal order_placed(dish_id: String)


# ============================================================
# FSM 狀態定義（對應 CustomerFSM 規格）
# ============================================================

enum State {
	ENTERING,   ## 從入口走進來，尋找座位
	WAITING,    ## 找不到位子，在入口等待（耐心遞減）
	EATING,     ## 已入座，等待/吃飯
	SATISFIED,  ## 收到餐點後短暫滿意爆出（接回 EATING）
	ANGRY,      ## 耐心歸零，生氣爆出後離開
	LEAVING,    ## 播放離開動畫，播完後移除節點
}


# ============================================================
# 耐心值系統
# ============================================================

## 當前耐心值（0.0~1.0）
var patience: float = 1.0

## 耐心遞減速率（每秒減少量，由 CustomerData 決定）
## 預設值為 0.02（約 50 秒耐心耗盡）
var patience_decay_rate: float = 0.02

## 耐心警戒線（低於此值播放急躁動畫）
const PATIENCE_WARN_THRESHOLD: float = 0.3


# ============================================================
# 座位系統
# ============================================================

## 指派的座位節點（Node2D）
## TODO: 座位系統整合後由 SeatManager 設定此參考
var seat_node: Node2D = null

## 是否已入座
var seated: bool = false

## 是否找不到空位（觸發 WAITING 狀態）
var no_seat_available: bool = false


# ============================================================
# 點餐系統
# ============================================================

## 當前點餐的菜色 ID（對應 dishes.csv 的 id 欄位）
var current_order: String = ""

## 是否已收到餐點
var food_received: bool = false

## 是否已吃完（觸發 LEAVING）
var finished_eating: bool = false

## 吃飯計時器（秒）
var eating_timer: float = 0.0

## 吃飯所需時間（由菜色資料決定，預設 20 秒）
var eating_duration: float = 20.0


# ============================================================
# 移動相關
# ============================================================

## 目前移動路徑（格子座標陣列）
## TODO: PathfindingManager 整合後填入
var movement_path: Array[Vector2i] = []

## 移動速度（像素/秒）
var move_speed: float = 48.0

## 路徑是否已走完
var path_complete: bool = false

## 當前移動方向（供動畫使用）
var velocity: Vector2 = Vector2.ZERO


# ============================================================
# 動畫參考
# ============================================================

## TODO: AnimatedSprite2D 素材完成後，取消此處的 @onready 註解
## @onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

## 幀切換動畫（純程式碼，不依賴 AnimatedSprite2D 場景節點）
var _sprite: Sprite2D = null
var _anim_frame: int = 0
var _anim_timer: float = 0.0
const ANIM_FPS: float = 6.0

const ANIM_WALK_FRAMES: Array[String] = [
	"res://assets/sprites/characters/char_customer_a_idle.png",
	"res://assets/sprites/characters/char_customer_a_walk_f2.png",
	"res://assets/sprites/characters/char_customer_a_walk_f3.png",
	"res://assets/sprites/characters/char_customer_a_walk_f4.png",
]

# ============================================================
# 色塊視覺（不依賴外部貼圖）
# ============================================================

## 客人身體色塊（藍色）
var _body_rect: ColorRect = null
## 客人頭部色塊（皮膚色）
var _head_rect: ColorRect = null
## 對話泡泡容器
var _bubble: Control = null
## 泡泡內符號 Label
var _bubble_label: Label = null
## 耐心條背景（灰色）
var _patience_bar_bg: ColorRect = null
## 耐心條填充（依耐心值變色）
var _patience_bar_fill: ColorRect = null
## 桌上食物圓點（橘色，收到餐點後顯示）
var _food_dot: ColorRect = null


# ============================================================
# FSM 內部狀態
# ============================================================

var _current_state: State = State.ENTERING
var _satisfied_timer: float = 0.0
const SATISFIED_DISPLAY_DURATION: float = 1.5  ## 滿意動畫播放時間

## 動畫備用計時器（當 animation_finished 信號尚未連接時作為保底出口）
var _fallback_timer: float = 0.0
var _fallback_timer_active: bool = false

## ENTERING 自動入座計時器（SeatManager 未整合時的備用路徑）
var _entering_timer: float = 0.0
const AUTO_SEAT_DELAY: float = 1.5

## WAITING 重新找位計時器
var _waiting_retry_timer: float = 0.0
const WAITING_RETRY_INTERVAL: float = 3.0


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	add_to_group("customers")
	# TODO: 動畫整合後，在此連接 animated_sprite.animation_finished 信號
	# animated_sprite.animation_finished.connect(_on_animation_finished)
	_enter_state(State.ENTERING)


# ============================================================
# 主循環：FSM 驅動
# ============================================================

func _process(delta: float) -> void:
	_update_state(delta)


## FSM 更新（每幀呼叫）
func _update_state(delta: float) -> void:
	# 備用計時器 tick（ANGRY/LEAVING 狀態下 animation_finished 未連接時的保底出口）
	if _fallback_timer_active:
		_fallback_timer -= delta
		if _fallback_timer <= 0.0:
			_fallback_timer_active = false
			_on_fallback_timer_expired()
		return  # 備用計時器執行中，不進入一般 match 流程

	match _current_state:

		State.ENTERING:
			_process_entering(delta)

		State.WAITING:
			_process_waiting(delta)

		State.EATING:
			_process_eating(delta)

		State.SATISFIED:
			_process_satisfied(delta)

		State.ANGRY:
			pass  ## 由 animation_finished 信號驅動（或備用計時器保底）轉換至 LEAVING

		State.LEAVING:
			_process_leaving(delta)

	_tick_animation(delta)


# ============================================================
# 各狀態處理邏輯
# ============================================================

## ENTERING：移動至座位
func _process_entering(delta: float) -> void:
	# TODO: PathfindingManager 整合後，呼叫 move_along_path(delta)
	# 目前以簡單計時模擬抵達
	if seated:
		_transition_to(State.EATING)
		return
	if no_seat_available:
		_transition_to(State.WAITING)
		return
	# 超時自動入座（SeatManager 未整合時的備用路徑）
	_entering_timer += delta
	if _entering_timer >= AUTO_SEAT_DELAY:
		# 若已確認無位，跳過備用入座
		if no_seat_available:
			return
		# 若沒有預留座位 meta，嘗試再找一次
		if not has_meta("assigned_seat_tile"):
			_try_reserve_seat()
			if no_seat_available:
				return
		seated = true
		# 嘗試正式占用座位
		var sm := get_tree().root.get_node_or_null("SeatManager")
		var tile: Vector2i = get_meta("assigned_seat_tile", Vector2i(2, 4))
		if sm != null and sm.has_method("assign_seat"):
			if not sm.assign_seat(name, tile):
				# 占位失敗（被搶），重新找位
				remove_meta("assigned_seat_tile")
				_entering_timer = 0.0
				_try_reserve_seat()
				return
			# 移動到座位像素位置（Tween 動畫，0.8 秒平滑移動）
			var target_pos := Vector2(tile.x * 16 + 8, tile.y * 16 + 8)
			var tw := create_tween()
			tw.tween_property(self, "position", target_pos, 0.8)
			tw.tween_callback(func(): _transition_to(State.EATING))
			return
		# 入座視覺：身體色塊短暫閃爍（0.3秒淡入）
		if _body_rect != null:
			_body_rect.modulate = Color(1, 1, 1, 0.3)
			var tw2 := create_tween()
			tw2.tween_property(_body_rect, "modulate", Color(1, 1, 1, 1), 0.3)


## WAITING：等候空位，耐心遞減，定期重新找位
func _process_waiting(delta: float) -> void:
	patience -= delta * patience_decay_rate
	if patience <= 0.0:
		_transition_to(State.ANGRY)
		return
	_update_patience_bar()
	# 每 WAITING_RETRY_INTERVAL 秒嘗試一次重新找位
	_waiting_retry_timer += delta
	if _waiting_retry_timer >= WAITING_RETRY_INTERVAL:
		_waiting_retry_timer = 0.0
		no_seat_available = false
		_try_reserve_seat()
		if not no_seat_available:
			# 找到位了，重新進入 ENTERING
			_entering_timer = 0.0
			_transition_to(State.ENTERING)


## EATING：等餐、吃飯（耐心持續遞減）
func _process_eating(delta: float) -> void:
	# 等餐時耐心繼續遞減
	if not food_received:
		patience -= delta * patience_decay_rate
		if patience <= 0.0:
			_transition_to(State.ANGRY)
			return
		_update_patience_bar()
	else:
		# 已收到餐點，隱藏耐心條
		if _patience_bar_bg != null:
			_patience_bar_bg.visible = false
		if _patience_bar_fill != null:
			_patience_bar_fill.visible = false
		# 計算吃飯時間
		eating_timer += delta
		if eating_timer >= eating_duration:
			finished_eating = true
			_transition_to(State.LEAVING)


## SATISFIED：滿意爆出（短暫，播完回 EATING）
func _process_satisfied(delta: float) -> void:
	_satisfied_timer -= delta
	if _satisfied_timer <= 0.0:
		_transition_to(State.EATING)


## LEAVING：移動至出口
func _process_leaving(_delta: float) -> void:
	# 客人離場：向右移動（走出右側入口）
	# fallback_timer 負責實際 queue_free，這裡只做視覺移動
	if position.x < 100:
		position.x += _delta * 40.0


# ============================================================
# FSM 狀態轉換
# ============================================================

## 轉換至新狀態
func _transition_to(new_state: State) -> void:
	if _current_state == new_state:
		return

	# ANGRY 與 LEAVING 為高優先轉換，可打斷任何狀態
	if new_state == State.ANGRY or new_state == State.LEAVING:
		_force_transition(new_state)
		return

	_exit_state(_current_state)
	_current_state = new_state
	_enter_state(new_state)


## 強制轉換（不執行 exit_state）
func _force_transition(new_state: State) -> void:
	# TODO: 動畫整合後，在此呼叫 animated_sprite.stop()
	_current_state = new_state
	_enter_state(new_state)


## 進入狀態時的初始化
func _enter_state(state: State) -> void:
	match state:
		State.ENTERING:
			velocity = Vector2.DOWN  ## 預設向下走入
			# TODO: 動畫整合後：animated_sprite.play("walk_down")
			_try_reserve_seat()

		State.WAITING:
			velocity = Vector2.ZERO
			# TODO: 動畫整合後：animated_sprite.play("idle_normal")

		State.EATING:
			velocity = Vector2.ZERO
			# TODO: 動畫整合後：animated_sprite.play("idle_normal")
			# 入座後播放入場音效
			var _am_eating := get_node_or_null("/root/AudioManager")
			if _am_eating != null and _am_eating.has_method("play_sfx"):
				var _sfx_enter := "res://assets/audio/sfx/customer_enter.wav"
				if ResourceLoader.exists(_sfx_enter):
					_am_eating.play_sfx(load(_sfx_enter))
			# 入座後下單
			if current_order.is_empty():
				_place_order()

		State.SATISFIED:
			_satisfied_timer = SATISFIED_DISPLAY_DURATION
			# TODO: 動畫整合後：animated_sprite.play("satisfied_burst")
			# 滿意時播放音效
			var _am_satisfied := get_node_or_null("/root/AudioManager")
			if _am_satisfied != null and _am_satisfied.has_method("play_sfx"):
				var _sfx_happy := "res://assets/audio/sfx/customer_happy.wav"
				if ResourceLoader.exists(_sfx_happy):
					_am_satisfied.play_sfx(load(_sfx_happy))
			# 滿意時隱藏耐心條
			if _patience_bar_bg != null:
				_patience_bar_bg.visible = false
			if _patience_bar_fill != null:
				_patience_bar_fill.visible = false
			# 顯示粉紅色滿意點
			_show_satisfied_dot()

		State.ANGRY:
			velocity = Vector2.ZERO
			# TODO: 動畫整合後：animated_sprite.play("angry_burst")
			# 憤怒時播放音效
			var _am_angry := get_node_or_null("/root/AudioManager")
			if _am_angry != null and _am_angry.has_method("play_sfx"):
				var _sfx_angry := "res://assets/audio/sfx/customer_angry.wav"
				if ResourceLoader.exists(_sfx_angry):
					_am_angry.play_sfx(load(_sfx_angry))
			# 憤怒離場：低滿意度，扣除名聲 -1
			customer_left.emit(0.0)
			var gm_angry := get_node_or_null("/root/GameManager")
			if gm_angry != null and gm_angry.has_method("reduce_reputation"):
				gm_angry.reduce_reputation(1)
			# 隱藏耐心條
			if _patience_bar_bg != null:
				_patience_bar_bg.visible = false
			if _patience_bar_fill != null:
				_patience_bar_fill.visible = false
			# 備用計時器：1.5 秒後強制轉 LEAVING（animation_finished 未連接時的保底）
			_fallback_timer = 1.5
			_fallback_timer_active = true

		State.LEAVING:
			velocity = Vector2.UP  ## 向上走出（朝入口方向）
			# TODO: 動畫整合後：animated_sprite.play("leave")
			# 隱藏耐心條
			if _patience_bar_bg != null:
				_patience_bar_bg.visible = false
			if _patience_bar_fill != null:
				_patience_bar_fill.visible = false
			# 備用計時器：1.0 秒後強制移除節點（animation_finished 未連接時的保底）
			_fallback_timer = 1.0
			_fallback_timer_active = true

	# 更新對話泡泡
	_update_bubble()


## 嘗試從 SeatManager 找並預留一個空位
## 需要處理競爭條件：get_available_seat 和 set_seat_waiting 之間可能有其他客人搶先
func _try_reserve_seat() -> void:
	var sm := get_tree().root.get_node_or_null("SeatManager")
	if sm == null:
		# 沒有 SeatManager，使用備用路徑（AUTO_SEAT_DELAY 計時）
		return

	# 嘗試多次（最多查完所有座位）
	for _attempt in range(8):
		var tile: Vector2i = sm.get_available_seat()
		if tile == Vector2i(-1, -1):
			# 全部座位都被佔用
			no_seat_available = true
			return
		# 嘗試預留（可能被其他客人搶先，set_seat_waiting 會回傳 false）
		var reserved: bool = sm.set_seat_waiting(name, tile)
		if reserved:
			set_meta("assigned_seat_tile", tile)
			return
		# 搶位失敗，繼續嘗試下一個（get_available_seat 不會再回傳已 WAITING 的位）
	# 嘗試 8 次仍失敗，視為無位
	no_seat_available = true


## 離開狀態時的清理
func _exit_state(_state: State) -> void:
	pass  ## 預留擴充，目前不需要 exit 清理


# ============================================================
# 點餐邏輯
# ============================================================

## 下單（從 MenuManager 取得已解鎖菜色，隨機選擇 1-3 道）
func _place_order() -> void:
	var available_dishes: Array[String] = []
	var mm := get_node_or_null("/root/MenuManager")
	var mm_exists := mm != null and mm.has_method("get_available_dishes")
	if mm_exists:
		for dish: Dictionary in mm.get_available_dishes():
			var dish_id: String = str(dish.get("id", ""))
			if dish_id != "":
				available_dishes.append(dish_id)
		# MenuManager 存在但沒有任何已解鎖菜色：客人立刻離場
		if available_dishes.is_empty():
			_transition_to(State.LEAVING)
			return
	else:
		# MenuManager 不存在，使用備用菜色（開發早期保底路徑）
		available_dishes = ["stir_fry_water_spinach", "century_egg_tofu", "three_cup_chicken"]
	# 隨機點 1-3 道菜，總價累積；只送第一道的 order_placed 信號
	var order_count: int = randi_range(1, 3)
	var total_price: float = 0.0
	var mm_price := get_node_or_null("/root/MenuManager")
	for _i in range(order_count):
		var dish_id: String = available_dishes[randi() % available_dishes.size()]
		if _i == 0:
			current_order = dish_id
			order_placed.emit(dish_id)
			# 下單音效
			var am_order := get_node_or_null("/root/AudioManager")
			if am_order != null and am_order.has_method("play_sfx"):
				var sfx_order := "res://assets/audio/sfx/order.wav"
				if ResourceLoader.exists(sfx_order):
					am_order.play_sfx(load(sfx_order))
		if mm_price != null and mm_price.has_method("get_dish"):
			var dish_data: Dictionary = mm_price.get_dish(dish_id)
			total_price += float(dish_data.get("price", dish_data.get("base_price", 80.0)))
		else:
			total_price += 80.0
	# 把總價存起來，結帳時使用
	set_meta("total_order_price", total_price)
	if OrderManager:
		var table_pos := Vector2i(0, 0)
		if has_meta("assigned_seat_tile"):
			table_pos = get_meta("assigned_seat_tile")
		elif seat_node != null:
			table_pos = Vector2i(int(seat_node.position.x / 16), int(seat_node.position.y / 16))
		OrderManager.place_order(name, current_order, table_pos)


# ============================================================
# 外部介面（供其他系統呼叫）
# ============================================================

## 通知客人餐點送達
## 若客人已進入 ANGRY 或 LEAVING，忽略此呼叫（不可搶救回滿意）
func receive_food() -> void:
	if _current_state == State.ANGRY or _current_state == State.LEAVING:
		return
	food_received = true
	eating_timer = 0.0
	_transition_to(State.SATISFIED)
	_show_food_on_table()


## 在客人腳部顯示橘色小碗代表桌上已有食物
func _show_food_on_table() -> void:
	if _food_dot != null:
		return  # 已存在，不重複建立
	var food_dot := ColorRect.new()
	food_dot.color = Color(0.95, 0.55, 0.1, 0.9)  # 橘色（代表碗/餐點）
	food_dot.size = Vector2(12, 8)
	food_dot.position = Vector2(-6, 4)  # 在角色腳部桌上
	add_child(food_dot)
	_food_dot = food_dot


## 查詢目前 FSM 狀態（供 Debug 使用）
func get_state_name() -> String:
	return State.keys()[_current_state]


## 顯示粉紅色滿意點（8x8），1.5 秒後 0.5 秒淡出消失
func _show_satisfied_dot() -> void:
	var dot := ColorRect.new()
	dot.color = Color(1.0, 0.5, 0.7, 0.9)  # 粉紅色
	dot.size = Vector2(8, 8)
	dot.position = Vector2(-4, -50)  # 頭頂上方
	add_child(dot)
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(dot, "modulate:a", 0.0, 0.5)
	tw.tween_callback(dot.queue_free)


## 客人入場淡入動畫（由 game.gd 在 add_child + setup_visuals 後呼叫）
## 從右方 8px 淡入並向左移動 0.5 秒（對應 SPAWN_POSITIONS 右側入口）
func play_entrance_animation() -> void:
	var start_pos: Vector2 = position + Vector2(8, 0)
	position = start_pos
	if _body_rect != null:
		_body_rect.modulate = Color(1, 1, 1, 0)
	if _head_rect != null:
		_head_rect.modulate = Color(1, 1, 1, 0)
	if _bubble != null:
		_bubble.modulate = Color(1, 1, 1, 0)

	# 進場光暈（淡黃色 20x20px，alpha 0.3→0，0.3秒）
	var tree := get_tree()
	if tree != null:
		var glow_layer := CanvasLayer.new()
		glow_layer.layer = 3
		tree.root.add_child(glow_layer)
		var glow := ColorRect.new()
		glow.color = Color(1.0, 0.95, 0.6, 0.3)
		glow.size = Vector2(20, 20)
		# 轉換到螢幕座標（估算）
		glow.position = Vector2(200, 150)
		glow_layer.add_child(glow)
		var glow_tw := create_tween()
		glow_tw.tween_property(glow, "modulate:a", 0.0, 0.3)
		glow_tw.tween_callback(glow_layer.queue_free)

	var tw := create_tween()
	tw.tween_property(self, "position", position - Vector2(8, 0), 0.5)
	if _body_rect != null:
		tw.parallel().tween_property(_body_rect, "modulate", Color(1, 1, 1, 1), 0.5)
	if _head_rect != null:
		tw.parallel().tween_property(_head_rect, "modulate", Color(1, 1, 1, 1), 0.5)
	if _bubble != null:
		tw.parallel().tween_property(_bubble, "modulate", Color(1, 1, 1, 1), 0.5)


## 備用計時器到期時的處理（ANGRY → LEAVING，LEAVING → queue_free）
func _on_fallback_timer_expired() -> void:
	match _current_state:
		State.ANGRY:
			_force_transition(State.LEAVING)
		State.LEAVING:
			_on_leaving_complete()


## 通知完成離場（動畫播完後呼叫，或由計時器呼叫）
## TODO: 動畫整合後，連接 animated_sprite.animation_finished 信號
func _on_leaving_complete() -> void:
	if finished_eating:
		customer_left.emit(1.0)  ## 滿意離場
		# 依剩餘耐心決定聲望加成
		var gm := get_node_or_null("/root/GameManager")
		if gm != null and gm.has_method("add_reputation"):
			if patience > 0.5:
				gm.add_reputation(2)  # 快速完食
			else:
				gm.add_reputation(1)  # 正常完食
		# 滿意離場時播放硬幣音效
		var am_coin := get_node_or_null("/root/AudioManager")
		if am_coin != null and am_coin.has_method("play_sfx"):
			var sfx_coin := "res://assets/audio/sfx/coin.wav"
			if ResourceLoader.exists(sfx_coin):
				am_coin.play_sfx(load(sfx_coin))
		# 結帳：從 meta 取累積總價（含多道菜），乘上客人類型消費倍率
		var pay_amount: float = get_meta("total_order_price", 160.0)
		var spend_mult: float = get_meta("spend_multiplier", 1.0)
		pay_amount *= spend_mult
		if OrderManager:
			OrderManager.complete_payment(name, pay_amount)
	# 清理食物圓點
	if _food_dot != null and is_instance_valid(_food_dot):
		_food_dot.queue_free()
		_food_dot = null
	# 釋放座位
	var sm := get_tree().root.get_node_or_null("SeatManager")
	if sm != null and sm.has_method("free_seat"):
		var tile: Vector2i = get_meta("assigned_seat_tile", Vector2i(-1, -1))
		if tile != Vector2i(-1, -1):
			sm.free_seat(tile)
	queue_free()


# ============================================================
# 動畫信號回調（預留）
# ============================================================

## TODO: AnimatedSprite2D 整合後，連接 animation_finished 信號
## func _on_animation_finished() -> void:
##     match _current_state:
##         State.SATISFIED:
##             _transition_to(State.EATING)
##         State.ANGRY:
##             _force_transition(State.LEAVING)
##         State.LEAVING:
##             _on_leaving_complete()


# ============================================================
# 幀切換動畫（Timer float 驅動，不依賴 AnimatedSprite2D）
# ============================================================

## 外部呼叫：傳入已掛好的 Sprite2D 參考
func set_sprite(s: Sprite2D) -> void:
	_sprite = s


# ============================================================
# 色塊視覺建立（公開方法，由 game.gd 在生成客人後呼叫）
# ============================================================

## Kenney tilemap 人物 region（16x16px，每格含 1px spacing 共 17px）
## 確認尺寸：kenney_tilemap.png = 458x305px，每格 17px（16px+1px spacing）
## tilemap.png 人物區在右側（第 24 欄，x=408），共 18 行人物
## 每個人物格子：16x16px（有效像素約在格內 y=2..15，x方向410..421）
## 依類型分配不同的 y offset（行索引 * 17）
const KENNEY_TILEMAP_PATH: String = "res://assets/sprites/characters/kenney_tilemap.png"
const KENNEY_CHAR_X: int = 408   ## 人物區 x 起點（第 24 欄，x = 24 * 17 = 408）
const KENNEY_CHAR_W: int = 16    ## 人物寬（格子寬）
const KENNEY_CHAR_H: int = 16    ## 人物高（單格，16x16px 格子）

## 4種客人對應的 y region offset（行索引 * 17）
const KENNEY_CHAR_Y_OFFSETS: Array[int] = [0, 17, 34, 51]

## 靜態快取（類別層級，只載入一次，所有客人共用）
static var _kenney_tex_cache: Texture2D = null

## 取得 Kenney tilemap texture（優先用靜態快取，避免重複 load）
static func _get_kenney_texture() -> Texture2D:
	if _kenney_tex_cache == null:
		if ResourceLoader.exists(KENNEY_TILEMAP_PATH):
			_kenney_tex_cache = load(KENNEY_TILEMAP_PATH)
	return _kenney_tex_cache

## 當前客人使用的 sprite（Kenney tilemap region 或 null）
var _char_sprite: Sprite2D = null
## 客人類型（0-3），由 setup_visuals 設定
var _type_index: int = 0


## 在 parent 節點上建立身體色塊 + 頭部色塊 + 對話泡泡
## 優先使用 Kenney tilemap Sprite2D，若載入失敗則 fallback 到純色塊
func setup_visuals(parent: Node2D) -> void:
	# 依隨機決定客人類型（0=上班族 1=情侶 2=老客人 3=學生）
	_type_index = randi() % 4
	var type_index: int = _type_index

	# ── Sprite2D（Kenney tilemap 人物切片）────────────────────
	var use_sprite: bool = false
	var tilemap_tex: Texture2D = CustomerAI._get_kenney_texture()
	if tilemap_tex != null:
		_char_sprite = Sprite2D.new()
		_char_sprite.texture = tilemap_tex
		_char_sprite.region_enabled = true
		var char_y: int = KENNEY_CHAR_Y_OFFSETS[type_index]
		_char_sprite.region_rect = Rect2(KENNEY_CHAR_X, char_y, KENNEY_CHAR_W, KENNEY_CHAR_H)
		_char_sprite.centered = true
		_char_sprite.position = Vector2(0, -8)   # 以角色中心對齊節點原點（16x16格子，偏移8px）
		_char_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # 像素清晰
		_char_sprite.z_index = 2                  # 確保在 ColorRect 之上
		_char_sprite.scale = Vector2(1.5, 1.5)   # 放大 1.5x 與廚師比例一致
		parent.add_child(_char_sprite)
		use_sprite = true

	# ── ColorRect fallback（Sprite2D 不可用時）────────────────
	# 身體（精緻化比例，配合 zoom 2.5：10x14px）
	_body_rect = ColorRect.new()
	var type_colors: Array[Color] = [
		Color(0.15, 0.35, 0.65),  # 上班族：深藍
		Color(0.85, 0.42, 0.58),  # 情侶：粉紅
		Color(0.85, 0.48, 0.12),  # 老客人：橘色
		Color(0.75, 0.72, 0.15),  # 學生：黃色
	]
	_body_rect.color = type_colors[type_index]
	_body_rect.size = Vector2(10, 14)
	_body_rect.position = Vector2(-5, -12)  # 以中心對齊節點原點
	# 有 sprite 時隱藏色塊，但保留節點（耐心條/泡泡的相對位置參考用）
	_body_rect.visible = not use_sprite
	parent.add_child(_body_rect)

	# 頭部（皮膚色，8x7px）
	_head_rect = ColorRect.new()
	_head_rect.color = Color(0.95, 0.75, 0.6)
	_head_rect.size = Vector2(8, 7)
	_head_rect.position = Vector2(-4, -19)  # 在身體上方
	_head_rect.visible = not use_sprite
	parent.add_child(_head_rect)

	# 頭髮色塊（依角色類型，8x3px，頭頂位置）
	var hair := ColorRect.new()
	hair.size = Vector2(8, 3)
	hair.position = Vector2(-4, -22)
	var hair_colors: Array[Color] = [
		Color(0.1, 0.1, 0.15),    # 上班族：黑髮
		Color(0.45, 0.28, 0.12),  # 情侶：褐髮
		Color(0.75, 0.72, 0.68),  # 老客人：灰白髮
		Color(0.28, 0.18, 0.08),  # 學生：深棕髮
	]
	hair.color = hair_colors[type_index]
	hair.visible = not use_sprite
	parent.add_child(hair)

	# 對話泡泡容器（Control，位於頭部上方）
	_bubble = Control.new()
	_bubble.position = Vector2(-8, -38)
	_bubble.size = Vector2(16, 14)
	parent.add_child(_bubble)

	# 泡泡背景（白色半透明）
	var bubble_bg := ColorRect.new()
	bubble_bg.color = Color(1, 1, 1, 0.85)
	bubble_bg.size = Vector2(16, 14)
	bubble_bg.position = Vector2.ZERO
	_bubble.add_child(bubble_bg)

	# 泡泡符號 Label
	_bubble_label = Label.new()
	_bubble_label.position = Vector2(1, -1)
	_bubble_label.size = Vector2(14, 14)
	_bubble_label.add_theme_font_size_override("font_size", 9)
	_bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bubble_label.text = "？"
	_bubble_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	_bubble.add_child(_bubble_label)

	_bubble.visible = true

	# 耐心條背景（灰色，緊貼頭部上方）
	_patience_bar_bg = ColorRect.new()
	_patience_bar_bg.color = Color(0.3, 0.3, 0.3)
	_patience_bar_bg.size = Vector2(16, 2)
	_patience_bar_bg.position = Vector2(-5, -27)
	parent.add_child(_patience_bar_bg)

	# 耐心條填充（初始綠色，寬度隨耐心值縮減）
	_patience_bar_fill = ColorRect.new()
	_patience_bar_fill.color = Color(0.2, 0.9, 0.2)
	_patience_bar_fill.size = Vector2(16, 2)
	_patience_bar_fill.position = Vector2(-5, -27)
	parent.add_child(_patience_bar_fill)

	# 依客人類型設定耐心值和消費倍率
	match _type_index:
		0:  # 上班族：耐心30秒，消費x1.0
			patience_decay_rate = 1.0 / 30.0
			set_meta("spend_multiplier", 1.0)
		1:  # 情侶：耐心60秒，消費x1.5
			patience_decay_rate = 1.0 / 60.0
			set_meta("spend_multiplier", 1.5)
		2:  # 老客人：耐心90秒，消費x0.8
			patience_decay_rate = 1.0 / 90.0
			set_meta("spend_multiplier", 0.8)
		3:  # 學生：耐心20秒，消費x0.7
			patience_decay_rate = 1.0 / 20.0
			set_meta("spend_multiplier", 0.7)


## 依目前狀態更新對話泡泡顯示
func _update_bubble() -> void:
	if _bubble == null or _bubble_label == null:
		return

	match _current_state:
		State.ENTERING, State.WAITING:
			_bubble.visible = true
			_bubble_label.text = "?"
			_bubble_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.6))

		State.EATING:
			_bubble.visible = true
			if food_received:
				_bubble_label.text = "!"
				_bubble_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.0))
			else:
				_bubble_label.text = "..."
				_bubble_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))

		State.SATISFIED:
			_bubble.visible = true
			_bubble_label.text = ":)"
			_bubble_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.5))

		State.ANGRY:
			_bubble.visible = true
			_bubble_label.text = "X"
			_bubble_label.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))

		State.LEAVING:
			_bubble.visible = false


## 更新耐心條寬度與顏色（由 WAITING/EATING 狀態每幀呼叫）
func _update_patience_bar() -> void:
	if _patience_bar_bg == null or _patience_bar_fill == null:
		return
	_patience_bar_bg.visible = true
	_patience_bar_fill.visible = true
	var new_width: float = 16.0 * patience
	if abs(_patience_bar_fill.size.x - new_width) > 0.1:  # 只在變化大於 0.1px 時更新
		_patience_bar_fill.size.x = new_width
	if patience > 0.5:
		_patience_bar_fill.color = Color(0.2, 0.9, 0.2)   # 綠
	elif patience > 0.3:
		_patience_bar_fill.color = Color(0.9, 0.7, 0.1)   # 黃
	else:
		_patience_bar_fill.color = Color(0.9, 0.1, 0.1)   # 紅


## 幀切換 tick（由 _update_state 末尾呼叫）
func _tick_animation(delta: float) -> void:
	if _sprite == null:
		return

	var is_walking: bool = (_current_state == State.ENTERING or _current_state == State.LEAVING)

	if is_walking:
		_anim_timer += delta
		if _anim_timer >= 1.0 / ANIM_FPS:
			_anim_timer -= 1.0 / ANIM_FPS
			var next_frame: int = (_anim_frame + 1) % ANIM_WALK_FRAMES.size()
			if next_frame != _anim_frame:
				_anim_frame = next_frame
				var frame_path: String = ANIM_WALK_FRAMES[_anim_frame]
				if ResourceLoader.exists(frame_path):
					_sprite.texture = load(frame_path)
	else:
		# 非走路狀態：固定顯示 idle（frame 0）
		if _anim_frame != 0:
			_anim_frame = 0
			_anim_timer = 0.0
			var idle_path: String = ANIM_WALK_FRAMES[0]
			if ResourceLoader.exists(idle_path):
				_sprite.texture = load(idle_path)
