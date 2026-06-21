extends Node2D

# 槍線視覺表示：從玩家中心延伸出一條線
# 父節點是 Player，rotation 由 Player 控制

@onready var line: Line2D = $Line2D
@onready var shoot_ray: RayCast2D = $ShootRay

const LINE_LENGTH = 500.0
const LINE_COLOR = Color(1, 0.8, 0, 0.8)
const LINE_COLOR_SAFE = Color(0, 1, 0, 0.5)

var safe_mode: bool = false

func _ready():
	if not line:
		line = Line2D.new()
		add_child(line)
	line.width = 2.0
	line.default_color = LINE_COLOR
	line.clear_points()
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2(LINE_LENGTH, 0))

	if shoot_ray:
		shoot_ray.target_position = Vector2(LINE_LENGTH, 0)
		shoot_ray.enabled = true
		# Layer 2 = 敵人
		shoot_ray.collision_mask = 2 | 4  # 敵人 + 牆壁

func _process(_delta):
	# 更新顏色
	if line:
		line.default_color = LINE_COLOR_SAFE if safe_mode else LINE_COLOR

func set_safe_mode(val: bool):
	safe_mode = val
