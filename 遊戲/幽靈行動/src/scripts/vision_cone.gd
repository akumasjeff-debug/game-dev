extends Node2D

# 視野錐形 - 繪製 120 度扇形
# 同時負責霧戰遮罩管理

const CONE_ANGLE = deg_to_rad(120.0)
const CONE_RANGE = 300.0
const CONE_STEPS = 16  # 扇形分段數

var cone_direction: float = 0.0  # 弧度，由 Player 設定

@onready var cone_polygon: Polygon2D = $ConePolygon

func _ready():
	if not cone_polygon:
		cone_polygon = Polygon2D.new()
		add_child(cone_polygon)
	cone_polygon.color = Color(1, 1, 0.8, 0.15)
	cone_polygon.z_index = 5
	_update_cone()

func _process(_delta):
	_update_cone()

func _update_cone():
	if not cone_polygon:
		return
	var points = PackedVector2Array()
	points.append(Vector2.ZERO)
	var half = CONE_ANGLE / 2.0
	for i in range(CONE_STEPS + 1):
		var t = float(i) / float(CONE_STEPS)
		# 直接用本地 +X 方向為中心，子節點已跟著 Player 旋轉，不需再加 cone_direction
		var angle = -half + t * CONE_ANGLE
		points.append(Vector2(cos(angle), sin(angle)) * CONE_RANGE)
	cone_polygon.polygon = points
