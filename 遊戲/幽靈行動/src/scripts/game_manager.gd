extends Node

# 全局狀態管理 — Autoload as "GameManager"

signal squad_paused()
signal squad_resumed()
signal game_won()
signal game_lost()
signal decision_triggered(decision_data: Dictionary)

var is_paused: bool = false
var is_game_over: bool = false
var squad_members: Array = []
var progress: float = 0.0  # 0.0 ~ 1.0 關卡進度
var current_mission_id: String = ""  # Bug3: 從基地帶入的任務 ID

# P1 Buff 狀態
var shield_buff_active: bool = false       # 盾兵大招：全隊傷害 -50%，持續 5 秒
var shield_buff_timer: float = 0.0
var assault_buff_active: bool = false      # 突擊手大招：全隊攻擊 +60%，持續 8 秒
var assault_buff_timer: float = 0.0
var sniper_marked_target: Node = null      # 狙擊手標記：下一次攻擊秒殺
var sniper_mark_pending: bool = false      # 無實體敵人時，下次決策傷害事件秒殺
var demo_bomb_pending: bool = false        # 爆破手炸彈 pending：下次遭遇敵人扣 70% HP
var enemies_blinded: bool = false          # 偵察手大招：敵人攻擊失效
var enemies_blinded_timer: float = 0.0

const SHIELD_BUFF_DURATION: float = 5.0
const SHIELD_BUFF_DAMAGE_REDUCTION: float = 0.5
const ASSAULT_BUFF_DURATION: float = 8.0
const ASSAULT_BUFF_ATTACK_MULTIPLIER: float = 1.6
const RECON_BLIND_DURATION: float = 5.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# 倒數 buff 計時器
	if shield_buff_active:
		shield_buff_timer -= delta
		if shield_buff_timer <= 0.0:
			shield_buff_active = false
			shield_buff_timer = 0.0

	if assault_buff_active:
		assault_buff_timer -= delta
		if assault_buff_timer <= 0.0:
			assault_buff_active = false
			assault_buff_timer = 0.0

	if enemies_blinded:
		enemies_blinded_timer -= delta
		if enemies_blinded_timer <= 0.0:
			enemies_blinded = false
			enemies_blinded_timer = 0.0

func apply_damage_to_member(member: Node, raw_amount: float) -> void:
	# 統一傷害入口：偵察手 blind 時敵人不造成傷害
	if enemies_blinded:
		return
	var final_amount = raw_amount
	if shield_buff_active:
		final_amount *= (1.0 - SHIELD_BUFF_DAMAGE_REDUCTION)
	# 百分比防禦減傷：member.defense 為 0~100，代表減傷百分比
	if member.get("defense") != null and member.defense > 0.0:
		var defense_ratio = float(member.defense) / 100.0
		final_amount = final_amount * (1.0 - defense_ratio)
	final_amount = max(1.0, final_amount)  # 至少造成 1 點傷害
	member.take_damage(final_amount)

func get_attack_multiplier() -> float:
	# 傳回當前攻擊倍率（供 auto_attack 使用）
	if assault_buff_active:
		return ASSAULT_BUFF_ATTACK_MULTIPLIER
	return 1.0

func activate_shield_buff() -> void:
	shield_buff_active = true
	shield_buff_timer = SHIELD_BUFF_DURATION

func activate_assault_buff() -> void:
	assault_buff_active = true
	assault_buff_timer = ASSAULT_BUFF_DURATION

func activate_recon_blind() -> void:
	enemies_blinded = true
	enemies_blinded_timer = RECON_BLIND_DURATION

func set_sniper_mark(target: Node) -> void:
	sniper_marked_target = target

func consume_sniper_mark() -> Node:
	var t = sniper_marked_target
	sniper_marked_target = null
	return t

func pause_squad() -> void:
	if is_game_over:
		return
	is_paused = true
	emit_signal("squad_paused")

func resume_squad() -> void:
	if is_game_over:
		return
	is_paused = false
	emit_signal("squad_resumed")

func trigger_decision(decision_data: Dictionary) -> void:
	pause_squad()
	emit_signal("decision_triggered", decision_data)

func check_defeat() -> void:
	if is_game_over:
		return
	var all_dead = true
	for member in squad_members:
		if member != null and is_instance_valid(member) and member.current_hp > 0:
			all_dead = false
			break
	if all_dead:
		trigger_game_over(false)

func trigger_game_over(won: bool) -> void:
	if is_game_over:
		return
	is_game_over = true
	is_paused = true
	if won:
		emit_signal("game_won")
	else:
		emit_signal("game_lost")

func set_progress(value: float) -> void:
	progress = clamp(value, 0.0, 1.0)
