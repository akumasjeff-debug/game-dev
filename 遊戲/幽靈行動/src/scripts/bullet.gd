extends Area2D

# 飛行子彈（備用，主要用 RayCast 即時命中）
const SPEED = 800.0
const LIFETIME = 1.0

var direction: Vector2 = Vector2.RIGHT
var damage: int = 25
var timer: float = 0.0
var from_player: bool = true

func _ready():
	# 碰撞層設定
	if from_player:
		collision_layer = 8   # Layer 4 = 子彈
		collision_mask = 2 | 4  # 敵人 + 牆壁
	else:
		collision_layer = 8
		collision_mask = 1 | 4  # 玩家 + 牆壁

func _physics_process(delta):
	timer += delta
	if timer >= LIFETIME:
		queue_free()
		return
	position += direction * SPEED * delta

func _on_body_entered(body):
	if from_player and body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
	elif not from_player and body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
	queue_free()
