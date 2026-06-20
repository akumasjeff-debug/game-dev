extends Area2D

const SPEED = 850.0
const LIFETIME = 0.8

var direction: Vector2 = Vector2.RIGHT
var damage: int = 25
var from_player: bool = true
var _age: float = 0.0

func _ready():
	collision_mask = 6 if from_player else 5  # 玩家子彈打敵人+牆；敵人子彈打玩家+牆
	monitoring = true
	body_entered.connect(_on_hit)

	# 子彈精靈：用 Image.load_from_file 繞過 import
	var sprite = $Sprite2D
	var img_path = ProjectSettings.globalize_path("res://assets/vfx/generated/bullet.png")
	var img = Image.load_from_file(img_path)
	if img:
		sprite.texture = ImageTexture.create_from_image(img)
		sprite.rotation = direction.angle()

	# 短曳光線：往後延伸 10px，像子彈在飛
	var line = Line2D.new()
	line.add_point(Vector2.ZERO)
	line.add_point(-direction * 10.0)
	line.width = 2.5
	line.default_color = Color(1.0, 0.95, 0.25) if from_player else Color(1.0, 0.45, 0.1)
	line.z_index = 6
	add_child(line)

func _physics_process(delta):
	_age += delta
	if _age > LIFETIME:
		queue_free()
		return
	position += direction * SPEED * delta

func _on_hit(body):
	if from_player and body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif not from_player and body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	else:
		queue_free()  # 打到牆壁或其他碰撞體

