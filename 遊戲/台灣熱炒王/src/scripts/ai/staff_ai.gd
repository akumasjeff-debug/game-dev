## StaffAI.gd
## 員工 AI — Node2D
## 對應 FSM 設計：godot-architecture.md § C（StaffFSM）
## 每位員工是獨立節點，由 StaffManager 生成並掛入 characters 容器

class_name StaffAI
extends Node2D


# ============================================================
# 信號定義
# ============================================================

## 任務完成時發出（task_id：完成的任務識別碼）
signal task_completed(task_id: String)

## 員工士氣歸零時發出
signal staff_angry


# ============================================================
# FSM 狀態定義（對應 StaffFSM 規格）
# ============================================================

enum State {
	IDLE,       ## 待機，等待新任務
	WALK,       ## 移動中，前往工作位置
	WORKING,    ## 工作中（炒菜/送餐/切菜）
	SATISFIED,  ## 完成任務，播放滿意動畫（播完回 IDLE）
	ANGRY,      ## 士氣歸零或長時間未分配任務（播完回 IDLE）
}


# ============================================================
# 士氣值系統
# ============================================================

## 當前士氣值（0.0~1.0）
var morale: float = 1.0

## 士氣自然遞減速率（每秒）
## 預設值為 0.005（約 200 秒從滿血歸零，正常有任務補充不會到 0）
var morale_decay_rate: float = 0.005

## 士氣恢復量（完成一次任務後）
const MORALE_RECOVER_PER_TASK: float = 0.1

## 士氣警戒線（低於此值開始播放急躁動畫）
const MORALE_WARN_THRESHOLD: float = 0.2

## 閒置時間計數器（太久沒任務觸發 ANGRY）
var _idle_timer: float = 0.0

## 閒置觸發憤怒的時間門檻（秒）
const IDLE_ANGRY_THRESHOLD: float = 120.0


# ============================================================
# 任務佇列系統
# ============================================================

## 任務佇列（先進先出）
## 每個任務為 Dictionary，結構：
##   { "id": String, "type": String, "target": Node, "data": Dictionary }
## type 對應：
##   "cook"     → 前往廚房炒菜
##   "serve"    → 取餐並送至桌位
##   "clear"    → 清理桌子
##   "restock"  → 補充食材至倉庫
var task_queue: Array = []

## 當前執行中的任務
var current_task: Dictionary = {}

## 工作進度（0.0~1.0，由 _process_working 推進）
var _work_progress: float = 0.0

## 當前工作所需時間（秒，由 task data 決定）
var _work_duration: float = 5.0

## 工作是否完成
var task_done: bool = false

## 當前工作動畫名稱（供 FSM 使用）
## TODO: 動畫整合後，由任務類型決定此值
var current_work_animation: String = "work_cook"


# ============================================================
# 移動相關
# ============================================================

## 目前移動路徑（格子座標陣列）
## TODO: PathfindingManager 整合後填入
var movement_path: Array[Vector2i] = []

## 移動速度（像素/秒）
var move_speed: float = 64.0

## 路徑是否已走完
var path_complete: bool = false

## 當前移動向量（供動畫方向使用）
var velocity: Vector2 = Vector2.ZERO

## 是否有指派任務（供 FSM 判斷走完路後的狀態）
var has_task: bool = false

## 待機位置（由 game.gd 生成員工後透過 set_home_position 設定）
var home_position: Vector2 = Vector2.ZERO

# ============================================================
# 烹飪進度條（CanvasLayer，廚師工作時顯示）
# ============================================================

## 進度條容器 CanvasLayer（layer = 3）
var _cook_bar_layer: CanvasLayer = null
## 進度條橘色填充 ColorRect
var _cook_bar_fill: ColorRect = null
const COOK_BAR_MAX_W: float = 80.0  # 進度條最大寬度（像素）

## 炒鍋位置（固定對應地圖上的炒菜台 Vector2i(1,1) * 16）
var cook_position: Vector2 = Vector2(16.0, 16.0)

## 冒煙粒子計時器（廚師炒菜時每 0.5 秒生成一個煙霧粒子）
var _smoke_timer: float = 0.0
const SMOKE_INTERVAL: float = 0.5

## 當前移動目標（直線位移）
var _move_target: Vector2 = Vector2.ZERO

## 完成任務後是否正在返回待機位
var _is_returning_home: bool = false


# ============================================================
# 動畫參考
# ============================================================

## TODO: AnimatedSprite2D 素材完成後，取消此處的 @onready 註解
## @onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

## 幀切換動畫（純程式碼，不依賴 AnimatedSprite2D 場景節點）
var _sprite: Sprite2D = null
var _is_chef: bool = false
var _anim_frame: int = 0
var _anim_timer: float = 0.0
const ANIM_FPS: float = 6.0
const ANIM_COOK_FPS: float = 8.0

const ANIM_CHEF_WALK: Array[String] = [
	"res://assets/sprites/characters/char_chef_idle.png",
	"res://assets/sprites/characters/char_chef_walk_f2.png",
	"res://assets/sprites/characters/char_chef_walk_f3.png",
	"res://assets/sprites/characters/char_chef_walk_f4.png",
]
const ANIM_CHEF_COOK: Array[String] = [
	"res://assets/sprites/characters/char_chef_cook_f1.png",
	"res://assets/sprites/characters/char_chef_cook_f2.png",
	"res://assets/sprites/characters/char_chef_cook_f3.png",
	"res://assets/sprites/characters/char_chef_cook_f4.png",
	"res://assets/sprites/characters/char_chef_cook_f5.png",
	"res://assets/sprites/characters/char_chef_cook_f6.png",
]
const ANIM_WAITER_WALK: Array[String] = [
	"res://assets/sprites/characters/char_waiter_idle.png",
	"res://assets/sprites/characters/char_waiter_walk_f1.png",
]
const ANIM_WAITER_CARRY: Array[String] = [
	"res://assets/sprites/characters/char_waiter_carry_f1.png",
	"res://assets/sprites/characters/char_waiter_carry_f3.png",
]


# ============================================================
# FSM 內部狀態
# ============================================================

var _current_state: State = State.IDLE
var _satisfied_timer: float = 0.0
const SATISFIED_DISPLAY_DURATION: float = 1.0  ## 滿意動畫播放時間

## 動畫備用計時器（當 animation_finished 信號尚未連接時作為保底出口）
var _fallback_timer: float = 0.0
var _fallback_timer_active: bool = false


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	add_to_group("staff")
	# TODO: 動畫整合後，在此連接 animated_sprite.animation_finished 信號
	# animated_sprite.animation_finished.connect(_on_animation_finished)
	_enter_state(State.IDLE)


# ============================================================
# 主循環：FSM 驅動
# ============================================================

func _process(delta: float) -> void:
	_update_state(delta)


## FSM 更新（每幀呼叫）
func _update_state(delta: float) -> void:
	# 備用計時器 tick（ANGRY 狀態下 animation_finished 未連接時的保底出口）
	if _fallback_timer_active:
		_fallback_timer -= delta
		if _fallback_timer <= 0.0:
			_fallback_timer_active = false
			_on_fallback_timer_expired()
		return  # 備用計時器執行中，略過一般 match 流程

	# 士氣持續遞減（ANGRY 狀態下不遞減，已是最低）
	if _current_state != State.ANGRY:
		morale -= delta * morale_decay_rate
		morale = maxf(morale, 0.0)

	# 士氣歸零強制進入 ANGRY 狀態
	if morale <= 0.0 and _current_state not in [State.ANGRY, State.SATISFIED]:
		_transition_to(State.ANGRY)
		return

	match _current_state:
		State.IDLE:
			_process_idle(delta)

		State.WALK:
			_process_walk(delta)

		State.WORKING:
			_process_working(delta)

		State.SATISFIED:
			_process_satisfied(delta)

		State.ANGRY:
			pass  ## 由 animation_finished 信號（或備用計時器保底）驅動回到 IDLE

	_tick_animation(delta)


# ============================================================
# 各狀態處理邏輯
# ============================================================

## IDLE：等待任務
func _process_idle(delta: float) -> void:
	_idle_timer += delta
	# 長時間無任務觸發憤怒
	if _idle_timer >= IDLE_ANGRY_THRESHOLD:
		_transition_to(State.ANGRY)
		return
	# 有新任務就立即出發
	if not task_queue.is_empty():
		_start_next_task()


## WALK：移動至目標（直線位移，2px 容差視為抵達）
func _process_walk(delta: float) -> void:
	var direction: Vector2 = _move_target - position
	if direction.length() <= 2.0:
		position = _move_target
		path_complete = true
		velocity = Vector2.ZERO
		if _is_returning_home:
			_is_returning_home = false
			_transition_to(State.IDLE)
		elif has_task:
			_transition_to(State.WORKING)
		else:
			_transition_to(State.IDLE)
	else:
		velocity = direction.normalized() * move_speed
		position += velocity * delta


## WORKING：執行任務
func _process_working(delta: float) -> void:
	_work_progress += delta / _work_duration
	if _work_progress >= 1.0:
		_work_progress = 1.0
		task_done = true
		_remove_cook_bar()
		_complete_current_task()
	else:
		# 更新烹飪進度條寬度
		_update_cook_bar(_work_progress)
	# 廚師炒菜冒煙效果
	if _is_chef:
		_smoke_timer += delta
		if _smoke_timer >= SMOKE_INTERVAL:
			_smoke_timer = 0.0
			_spawn_smoke_particle()


## SATISFIED：完成任務慶祝動畫
func _process_satisfied(delta: float) -> void:
	_satisfied_timer -= delta
	if _satisfied_timer <= 0.0:
		# 有待辦任務就繼續
		if not task_queue.is_empty():
			_start_next_task()
			return
		# 若離待機位超過 4px，先走回待機位
		if home_position != Vector2.ZERO and (position - home_position).length() > 4.0:
			_is_returning_home = true
			_move_target = home_position
			has_task = false
			_transition_to(State.WALK)
		else:
			_transition_to(State.IDLE)


# ============================================================
# FSM 狀態轉換
# ============================================================

## 轉換至新狀態
func _transition_to(new_state: State) -> void:
	if _current_state == new_state:
		return
	_exit_state(_current_state)
	_current_state = new_state
	_enter_state(new_state)


## 進入狀態時的初始化
func _enter_state(state: State) -> void:
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			_idle_timer = 0.0
			has_task = false
			# TODO: 動畫整合後：animated_sprite.play("idle")

		State.WALK:
			task_done = false
			path_complete = false
			# _is_returning_home 與 _move_target 由呼叫端在 transition 前設定好
			# 若非返回待機，則依任務類型決定移動目標
			if not _is_returning_home:
				var task_type: String = current_task.get("type", "")
				match task_type:
					"cook":
						_move_target = cook_position
					"serve":
						# 優先從任務資料取得桌子位置
						var task_data: Dictionary = current_task.get("data", {})
						if task_data.has("target_pos"):
							_move_target = task_data["target_pos"]
						elif task_data.has("table_tile"):
							var tile: Vector2i = task_data["table_tile"]
							_move_target = Vector2(tile.x * 16 + 8, tile.y * 16 + 8)
						elif current_task.has("table_tile"):
							var tile: Vector2i = current_task["table_tile"]
							_move_target = Vector2(tile.x * 16 + 8, tile.y * 16 + 8)
						else:
							# fallback：沒有位置資訊，回待機位
							_move_target = home_position if home_position != Vector2.ZERO else position
					_:
						_move_target = home_position if home_position != Vector2.ZERO else position
			# TODO: 動畫整合後：animated_sprite.play("walk_%s" % _direction_suffix())

		State.WORKING:
			_work_progress = 0.0
			task_done = false
			# TODO: 動畫整合後：animated_sprite.play(current_work_animation)
			# 若為廚師炒菜任務，顯示進度條
			if _is_chef and current_task.get("type", "") == "cook":
				_create_cook_bar()

		State.SATISFIED:
			_satisfied_timer = SATISFIED_DISPLAY_DURATION
			# TODO: 動畫整合後：animated_sprite.play("satisfied")

		State.ANGRY:
			velocity = Vector2.ZERO
			morale = 0.0
			staff_angry.emit()
			# TODO: 動畫整合後：animated_sprite.play("angry")
			# 備用計時器：2.0 秒後強制回 IDLE（animation_finished 未連接時的保底）
			_fallback_timer = 2.0
			_fallback_timer_active = true


## 離開狀態時的清理
func _exit_state(_state: State) -> void:
	pass  ## 預留擴充，目前不需要 exit 清理


# ============================================================
# 任務管理
# ============================================================

## 加入新任務至佇列尾端
## task_data 結構：{ "id": String, "type": String, "target": Node, "data": Dictionary }
func assign_task(task_data: Dictionary) -> void:
	if task_data.is_empty():
		push_warning("[StaffAI] assign_task 收到空任務")
		return
	# 廚師最多同時 2 個烹飪任務
	if _is_chef and task_queue.size() >= 2:
		push_warning("[StaffAI] 廚師任務佇列已滿（上限2），丟棄任務 %s" % task_data.get("id", ""))
		return
	task_queue.append(task_data)
	# 若正在 IDLE，立即開始
	if _current_state == State.IDLE:
		_start_next_task()


## 開始執行佇列中的下一個任務
func _start_next_task() -> void:
	if task_queue.is_empty():
		return
	current_task = task_queue.pop_front()
	has_task = true
	_work_duration = current_task.get("data", {}).get("duration", 5.0)
	current_work_animation = _get_work_animation(current_task.get("type", "cook"))
	_transition_to(State.WALK)


## 完成當前任務
func _complete_current_task() -> void:
	var completed_id: String = current_task.get("id", "")
	var task_type: String = current_task.get("type", "")
	task_completed.emit(completed_id)
	morale = minf(morale + MORALE_RECOVER_PER_TASK, 1.0)
	# 串接 OrderManager：炒菜完成通知
	if task_type == "cook" and OrderManager:
		# 炒菜完成時播放音效
		var am_cook := get_node_or_null("/root/AudioManager")
		if am_cook != null and am_cook.has_method("play_sfx"):
			var sfx_cook := "res://assets/audio/sfx/cook_done.wav"
			if ResourceLoader.exists(sfx_cook):
				am_cook.play_sfx(load(sfx_cook))
		OrderManager.complete_cooking(completed_id)
		# 飄字「送餐！」（若無外場員工時的視覺提示）
		_show_deliver_popup()
	# 串接 OrderManager：送餐完成通知
	elif task_type == "serve" and OrderManager:
		# task id 格式為 "<order_id>_deliver"，取出原始 order_id
		var order_id: String = completed_id.trim_suffix("_deliver")
		if OrderManager.has_method("order_delivered_by_staff"):
			OrderManager.order_delivered_by_staff(order_id)
		elif OrderManager.has_method("deliver_to_table"):
			# deliver_to_table 需要 order_id 與 staff_id，
			# 但此時訂單已在 delivering 狀態，呼叫會因狀態檢查而略過，
			# 故改為直接觸發 complete_payment
			var om_orders: Dictionary = OrderManager._orders
			if om_orders.has(order_id):
				var order_data: Dictionary = om_orders[order_id]
				if order_data.get("status", "") == "delivering":
					order_data["status"] = "done"
					var customer_id: String = order_data.get("customer_id", "")
					if customer_id != "":
						var dish_id_pay: String = order_data.get("dish_id", "")
						var pay_price: float = 160.0
						var mm_pay := get_node_or_null("/root/MenuManager")
						if mm_pay != null and dish_id_pay != "":
							var dish_pay: Dictionary = mm_pay.get_dish(dish_id_pay)
							if not dish_pay.is_empty():
								pay_price = float(dish_pay.get("price", dish_pay.get("base_price", 160.0)))
						OrderManager.complete_payment(customer_id, pay_price)
	current_task = {}
	has_task = false
	_transition_to(State.SATISFIED)


## 清空任務佇列（緊急中斷用）
func clear_task_queue() -> void:
	task_queue.clear()
	current_task = {}
	has_task = false
	_remove_cook_bar()


# ============================================================
# 工具函式
# ============================================================

## 設定待機位置（由 game.gd 在生成員工後呼叫）
func set_home_position(pos: Vector2) -> void:
	home_position = pos


## 依任務類型取得對應工作動畫名稱
## TODO: 動畫整合後，確認這些動畫名稱與 AnimatedSprite2D 的 animation 名稱一致
func _get_work_animation(task_type: String) -> String:
	match task_type:
		"cook":    return "work_cook"
		"serve":   return "work_serve"
		"clear":   return "work_clear"
		"restock": return "work_restock"
		_:         return "work_cook"


## 依移動向量取得動畫方向後綴
func _direction_suffix() -> String:
	var vel: Vector2 = velocity.normalized()
	if vel == Vector2.ZERO:
		return "down"
	if abs(vel.x) > abs(vel.y):
		return "right" if vel.x > 0 else "left"
	else:
		return "down" if vel.y > 0 else "up"


## 炒菜完成時顯示飄字「送餐！」（無外場員工時的視覺提示）
func _show_deliver_popup() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var popup_layer := CanvasLayer.new()
	popup_layer.layer = 4
	tree.root.add_child(popup_layer)
	var lbl := Label.new()
	lbl.text = "送餐！"
	lbl.position = Vector2(180, 140)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.1))
	lbl.add_theme_font_size_override("font_size", 12)
	var fp := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf"
	if ResourceLoader.exists(fp):
		lbl.add_theme_font_override("font", load(fp))
	popup_layer.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 20.0, 0.8)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw.tween_callback(popup_layer.queue_free)


## 廚師炒菜時在炒菜台上方生成白色煙霧粒子
func _spawn_smoke_particle() -> void:
	var tree := get_tree()
	if tree == null:
		return
	# 在炒菜台上方（螢幕座標）生成白色煙霧粒子
	# 炒菜台世界座標 (20,16)，Camera zoom=2.5 center=(60,50)
	# 螢幕座標 x=240+(20-60)*2.5=140, y=135+(16-50)*2.5=50
	var smoke_layer := CanvasLayer.new()
	smoke_layer.layer = 4
	tree.root.add_child(smoke_layer)

	var smoke := ColorRect.new()
	smoke.color = Color(0.9, 0.9, 0.9, 0.7)  # 白色半透明
	smoke.size = Vector2(4, 4)
	var start_x: float = 136.0 + randf() * 8.0
	smoke.position = Vector2(start_x, 50.0)
	smoke_layer.add_child(smoke)

	var tw := create_tween()
	tw.tween_property(smoke, "position:y", smoke.position.y - 20.0, 0.8)
	tw.parallel().tween_property(smoke, "modulate:a", 0.0, 0.8)
	tw.tween_callback(smoke_layer.queue_free)


## 備用計時器到期時的處理（ANGRY → IDLE，附帶少量士氣恢復）
func _on_fallback_timer_expired() -> void:
	if _current_state == State.ANGRY:
		morale = 0.3  ## 憤怒後恢復少量士氣（與動畫版行為一致）
		_transition_to(State.IDLE)


## 查詢目前 FSM 狀態名稱（供 Debug 使用）
func get_state_name() -> String:
	return State.keys()[_current_state]


## 查詢任務佇列長度（供 StaffManager 做排程用）
func get_task_queue_size() -> int:
	return task_queue.size()


# ============================================================
# 動畫信號回調（預留）
# ============================================================

## TODO: AnimatedSprite2D 整合後，連接 animation_finished 信號
## func _on_animation_finished() -> void:
##     match _current_state:
##         State.SATISFIED:
##             if not task_queue.is_empty():
##                 _start_next_task()
##             else:
##                 _transition_to(State.IDLE)
##         State.ANGRY:
##             morale = 0.3  ## 憤怒後恢復少量士氣
##             _transition_to(State.IDLE)


# ============================================================
# 幀切換動畫（Timer float 驅動，不依賴 AnimatedSprite2D）
# ============================================================

## 外部呼叫：傳入已掛好的 Sprite2D 參考與角色類型
func set_sprite(s: Sprite2D, is_chef: bool = false) -> void:
	_sprite = s
	_is_chef = is_chef


# ============================================================
# 烹飪進度條管理
# ============================================================

## 在廚師頭頂上方建立進度條 CanvasLayer（跟隨廚師世界座標換算至螢幕）
## CanvasLayer 使用螢幕座標；廚師站在 (20, 36)，Camera zoom=2.5, pos=(60,50)
## 換算：螢幕中心=(240,135)，廚師螢幕位置=(240+(20-60)*2.5, 135+(36-50)*2.5)=(140,100)
func _create_cook_bar() -> void:
	_remove_cook_bar()  # 確保舊的已清除

	if get_tree() == null:
		return

	_cook_bar_layer = CanvasLayer.new()
	_cook_bar_layer.layer = 3
	get_tree().root.add_child(_cook_bar_layer)

	# 進度條顯示在廚師頭頂上方（螢幕固定座標，根據廚師位置估算）
	# 廚師在世界座標 (20,36)，Camera zoom=2.5 center=(60,50)
	# 螢幕座標: x=240+(20-60)*2.5=140, y=135+(36-50)*2.5=100 → 頭頂再上 18px = y=82
	const BAR_X: float = 100.0  # 廚師頭頂對應螢幕 x-20（讓進度條居中於廚師上方）
	const BAR_Y: float = 80.0   # 廚師頭頂螢幕位置（y=100 - 20px 上方）

	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.3, 0.3, 0.3, 0.85)
	bar_bg.size = Vector2(COOK_BAR_MAX_W, 6)
	bar_bg.position = Vector2(BAR_X, BAR_Y)
	_cook_bar_layer.add_child(bar_bg)

	# 「烹飪中」標籤（進度條正上方，垂直排列）
	var bar_label := Label.new()
	bar_label.name = "cook_label"
	var cook_font_path := "res://assets/fonts/fusion-pixel-12px-proportional-zh_hant.ttf"
	if ResourceLoader.exists(cook_font_path):
		bar_label.text = "烹飪中"
		var cook_font = load(cook_font_path)
		bar_label.add_theme_font_override("font", cook_font)
		bar_label.add_theme_font_size_override("font_size", 8)
	else:
		bar_label.text = "cooking"
		bar_label.add_theme_font_size_override("font_size", 8)
	bar_label.position = Vector2(BAR_X, BAR_Y - 12)  # 進度條正上方 12px
	bar_label.add_theme_color_override("font_color", Color(1, 0.7, 0.2))
	_cook_bar_layer.add_child(bar_label)

	_cook_bar_fill = ColorRect.new()
	_cook_bar_fill.color = Color(0.95, 0.55, 0.1)
	_cook_bar_fill.size = Vector2(0, 6)
	_cook_bar_fill.position = Vector2(BAR_X, BAR_Y)
	_cook_bar_layer.add_child(_cook_bar_fill)


## 更新進度條寬度（progress: 0.0 ~ 1.0）
func _update_cook_bar(progress: float) -> void:
	if _cook_bar_fill == null or not is_instance_valid(_cook_bar_fill):
		return
	_cook_bar_fill.size.x = COOK_BAR_MAX_W * clampf(progress, 0.0, 1.0)


## 移除進度條
func _remove_cook_bar() -> void:
	if _cook_bar_layer != null and is_instance_valid(_cook_bar_layer):
		_cook_bar_layer.queue_free()
	_cook_bar_layer = null
	_cook_bar_fill = null


## 幀切換 tick（由 _update_state 末尾呼叫）
func _tick_animation(delta: float) -> void:
	if _sprite == null:
		return

	match _current_state:

		State.WALK:
			# 走路幀循環
			var fps: float = ANIM_FPS
			var frames: Array[String] = ANIM_CHEF_WALK if _is_chef else ANIM_WAITER_WALK
			_anim_timer += delta
			if _anim_timer >= 1.0 / fps:
				_anim_timer -= 1.0 / fps
				var next_walk_frame: int = (_anim_frame + 1) % frames.size()
				if next_walk_frame != _anim_frame:
					_anim_frame = next_walk_frame
					var walk_path: String = frames[_anim_frame]
					if ResourceLoader.exists(walk_path):
						_sprite.texture = load(walk_path)

		State.WORKING:
			# 工作幀循環
			if _is_chef:
				# 廚師炒菜：6幀，8 FPS
				_anim_timer += delta
				if _anim_timer >= 1.0 / ANIM_COOK_FPS:
					_anim_timer -= 1.0 / ANIM_COOK_FPS
					var next_cook_frame: int = (_anim_frame + 1) % ANIM_CHEF_COOK.size()
					if next_cook_frame != _anim_frame:
						_anim_frame = next_cook_frame
						var cook_path: String = ANIM_CHEF_COOK[_anim_frame]
						if ResourceLoader.exists(cook_path):
							_sprite.texture = load(cook_path)
			else:
				# 外場端餐：2幀，6 FPS
				_anim_timer += delta
				if _anim_timer >= 1.0 / ANIM_FPS:
					_anim_timer -= 1.0 / ANIM_FPS
					var next_carry_frame: int = (_anim_frame + 1) % ANIM_WAITER_CARRY.size()
					if next_carry_frame != _anim_frame:
						_anim_frame = next_carry_frame
						var carry_path: String = ANIM_WAITER_CARRY[_anim_frame]
						if ResourceLoader.exists(carry_path):
							_sprite.texture = load(carry_path)

		_:
			# IDLE / SATISFIED / ANGRY：顯示待機幀（frame 0）
			if _anim_frame != 0:
				_anim_frame = 0
				_anim_timer = 0.0
				var idle_tex: String = ANIM_CHEF_WALK[0] if _is_chef else ANIM_WAITER_WALK[0]
				if ResourceLoader.exists(idle_tex):
					_sprite.texture = load(idle_tex)
