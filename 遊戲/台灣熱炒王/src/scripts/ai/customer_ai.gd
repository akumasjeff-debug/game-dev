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


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	add_to_group("customers")
	# TODO: 動畫整合後，在此連接 animated_sprite.animation_finished 信號
	# animated_sprite.animation_finished.connect(_on_animation_finished)
	_enter_state(State.ENTERING)
	print("[CustomerAI] 客人生成，初始狀態 ENTERING")


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
		seated = true
		print("[CustomerAI] 自動入座（備用路徑，%.1f 秒後）" % AUTO_SEAT_DELAY)
		_transition_to(State.EATING)


## WAITING：等候空位，耐心遞減
func _process_waiting(delta: float) -> void:
	patience -= delta * patience_decay_rate
	if patience <= 0.0:
		_transition_to(State.ANGRY)
		return
	# TODO: 輪詢空位（由 SeatManager 整合後實作）
	# if find_available_seat():
	#     seated = true
	#     _transition_to(State.ENTERING)


## EATING：等餐、吃飯（耐心持續遞減）
func _process_eating(delta: float) -> void:
	# 等餐時耐心繼續遞減
	if not food_received:
		patience -= delta * patience_decay_rate
		if patience <= 0.0:
			_transition_to(State.ANGRY)
			return
	else:
		# 已收到餐點，計算吃飯時間
		eating_timer += delta
		if eating_timer >= eating_duration:
			finished_eating = true
			print("[CustomerAI] 客人吃完，準備離開")
			_transition_to(State.LEAVING)


## SATISFIED：滿意爆出（短暫，播完回 EATING）
func _process_satisfied(delta: float) -> void:
	_satisfied_timer -= delta
	if _satisfied_timer <= 0.0:
		_transition_to(State.EATING)


## LEAVING：移動至出口
func _process_leaving(_delta: float) -> void:
	# TODO: PathfindingManager 整合後，呼叫移動至入口的邏輯
	# 目前以延遲後移除節點模擬
	pass


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

		State.WAITING:
			velocity = Vector2.ZERO
			# TODO: 動畫整合後：animated_sprite.play("idle_normal")

		State.EATING:
			velocity = Vector2.ZERO
			# TODO: 動畫整合後：animated_sprite.play("idle_normal")
			# 入座後下單
			if current_order.is_empty():
				_place_order()

		State.SATISFIED:
			_satisfied_timer = SATISFIED_DISPLAY_DURATION
			# TODO: 動畫整合後：animated_sprite.play("satisfied_burst")

		State.ANGRY:
			velocity = Vector2.ZERO
			# TODO: 動畫整合後：animated_sprite.play("angry_burst")
			# 憤怒離場：低滿意度
			customer_left.emit(0.0)
			# 備用計時器：1.5 秒後強制轉 LEAVING（animation_finished 未連接時的保底）
			_fallback_timer = 1.5
			_fallback_timer_active = true

		State.LEAVING:
			velocity = Vector2.UP  ## 向上走出（朝入口方向）
			# TODO: 動畫整合後：animated_sprite.play("leave")
			# 備用計時器：1.0 秒後強制移除節點（animation_finished 未連接時的保底）
			_fallback_timer = 1.0
			_fallback_timer_active = true


## 離開狀態時的清理
func _exit_state(_state: State) -> void:
	pass  ## 預留擴充，目前不需要 exit 清理


# ============================================================
# 點餐邏輯
# ============================================================

## 下單（隨機選擇菜色）
## TODO: 整合菜單系統後，由 MenuManager 提供可點菜色清單
func _place_order() -> void:
	# 暫時硬編碼幾個菜色 ID，待菜色資料表完成後替換
	var available_dishes: Array[String] = ["sanpei_chicken", "clam_stirfry", "pidan_tofu"]
	if available_dishes.is_empty():
		return
	current_order = available_dishes[randi() % available_dishes.size()]
	order_placed.emit(current_order)
	print("[CustomerAI] 客人點了：%s" % current_order)
	# 串接 OrderManager：下單進入廚房佇列
	if OrderManager:
		var table_pos := Vector2i(0, 0)
		if seat_node != null:
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


## 查詢目前 FSM 狀態（供 Debug 使用）
func get_state_name() -> String:
	return State.keys()[_current_state]


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
		print("[CustomerAI] 客人滿意離場（吃完離開）")
	else:
		print("[CustomerAI] 客人離場（未吃完）")
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


## 幀切換 tick（由 _update_state 末尾呼叫）
func _tick_animation(delta: float) -> void:
	if _sprite == null:
		return

	var is_walking: bool = (_current_state == State.ENTERING or _current_state == State.LEAVING)

	if is_walking:
		_anim_timer += delta
		if _anim_timer >= 1.0 / ANIM_FPS:
			_anim_timer -= 1.0 / ANIM_FPS
			_anim_frame = (_anim_frame + 1) % ANIM_WALK_FRAMES.size()
			_sprite.texture = load(ANIM_WALK_FRAMES[_anim_frame])
	else:
		# 非走路狀態：固定顯示 idle（frame 0）
		if _anim_frame != 0:
			_anim_frame = 0
			_anim_timer = 0.0
			_sprite.texture = load(ANIM_WALK_FRAMES[0])
