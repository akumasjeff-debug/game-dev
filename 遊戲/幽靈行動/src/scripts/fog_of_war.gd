extends Node2D

const MAP_WIDTH = 1920
const MAP_HEIGHT = 1080
const CELL_SIZE = 20
const GRID_W = MAP_WIDTH / CELL_SIZE   # 96
const GRID_H = MAP_HEIGHT / CELL_SIZE  # 54

# 格子狀態
const UNEXPLORED = 0
const EXPLORED = 1
const VISIBLE = 2

var grid: PackedByteArray        # GRID_W * GRID_H 個 byte，值為 0/1/2
var wall_grid: PackedByteArray   # 牆壁格子集合（1=牆壁，0=通道）
var fog_image: Image
var fog_texture: ImageTexture
var fog_sprite: Sprite2D

# 視野參數（與 Player 同步）
const CONE_ANGLE = deg_to_rad(120.0)
const CONE_RANGE = 300.0
const CONE_STEPS = 24  # 射線數量，越多越精準但越慢

func _ready():
	add_to_group("fog_of_war")
	grid = PackedByteArray()
	grid.resize(GRID_W * GRID_H)
	grid.fill(UNEXPLORED)
	wall_grid = PackedByteArray()
	wall_grid.resize(GRID_W * GRID_H)
	wall_grid.fill(0)
	# 延遲一幀後掃描牆壁（確保物理世界已初始化）
	await get_tree().process_frame
	_build_wall_grid()

	# 建立 Image（RGBA8，96x54）
	fog_image = Image.create(GRID_W, GRID_H, false, Image.FORMAT_RGBA8)
	fog_image.fill(Color(0, 0, 0, 1))  # 初始全黑

	fog_texture = ImageTexture.create_from_image(fog_image)

	# Sprite2D 放大到地圖尺寸
	fog_sprite = Sprite2D.new()
	fog_sprite.texture = fog_texture
	fog_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fog_sprite.position = Vector2(MAP_WIDTH / 2.0, MAP_HEIGHT / 2.0)
	fog_sprite.scale = Vector2(float(MAP_WIDTH) / GRID_W, float(MAP_HEIGHT) / GRID_H)
	fog_sprite.z_index = 8
	add_child(fog_sprite)

func _process(_delta):
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]

	# 先把上一幀的 VISIBLE 格子降回 EXPLORED
	for i in range(grid.size()):
		if grid[i] == VISIBLE:
			grid[i] = EXPLORED

	# 計算玩家視野內的格子
	var p_pos = player.global_position
	var p_rot = player.rotation
	_mark_visible_cells(p_pos, p_rot)

	# 更新 Image 並上傳 Texture
	_update_texture()

func _build_wall_grid():
	# 用物理點查詢掃描每個格子中心，確認是否在牆壁 StaticBody2D 內
	# 牆壁碰撞層 = 4，用 point_query 判斷
	var space = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.collision_mask = 4  # 只查牆壁層
	query.collide_with_areas = false
	query.collide_with_bodies = true
	for gy in range(GRID_H):
		for gx in range(GRID_W):
			var center = Vector2(gx * CELL_SIZE + CELL_SIZE / 2.0, gy * CELL_SIZE + CELL_SIZE / 2.0)
			query.position = center
			var results = space.intersect_point(query, 1)
			if results.size() > 0:
				wall_grid[gy * GRID_W + gx] = 1

func _mark_visible_cells(p_pos: Vector2, p_rot: float):
	var half_cone = CONE_ANGLE / 2.0
	# 發射 CONE_STEPS 條射線掃描扇形
	for i in range(CONE_STEPS + 1):
		var t = float(i) / float(CONE_STEPS)
		var ray_angle = p_rot - half_cone + t * CONE_ANGLE
		var ray_dir = Vector2(cos(ray_angle), sin(ray_angle))
		# 沿射線步進，每 CELL_SIZE/2 步一格（避免穿透）
		var step = CELL_SIZE / 2.0
		var steps = int(CONE_RANGE / step)
		for s in range(steps):
			var world_pos = p_pos + ray_dir * (s * step)
			var gx = int(world_pos.x / CELL_SIZE)
			var gy = int(world_pos.y / CELL_SIZE)
			if gx < 0 or gx >= GRID_W or gy < 0 or gy >= GRID_H:
				break
			# 遇到牆壁格就停止（牆壁本身也標記為已探索但不透明）
			if wall_grid[gy * GRID_W + gx] == 1:
				break
			var idx = gy * GRID_W + gx
			grid[idx] = VISIBLE

	# 也標記玩家腳下的格子（避免玩家周圍小圈看不見）
	var px = int(p_pos.x / CELL_SIZE)
	var py = int(p_pos.y / CELL_SIZE)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var gx = px + dx
			var gy = py + dy
			if gx >= 0 and gx < GRID_W and gy >= 0 and gy < GRID_H:
				if wall_grid[gy * GRID_W + gx] == 0:
					grid[gy * GRID_W + gx] = VISIBLE

func _update_texture():
	for gy in range(GRID_H):
		for gx in range(GRID_W):
			var idx = gy * GRID_W + gx
			var color: Color
			match grid[idx]:
				UNEXPLORED:
					color = Color(0, 0, 0, 1.0)
				EXPLORED:
					color = Color(0, 0, 0, 0.65)
				VISIBLE:
					color = Color(0, 0, 0, 0.0)
				_:
					color = Color(0, 0, 0, 1.0)
			fog_image.set_pixel(gx, gy, color)
	fog_texture.update(fog_image)

# 供外部查詢：某個世界座標是否在當前視線內
func is_in_clear_vision(pos: Vector2) -> bool:
	var gx = int(pos.x / CELL_SIZE)
	var gy = int(pos.y / CELL_SIZE)
	if gx < 0 or gx >= GRID_W or gy < 0 or gy >= GRID_H:
		return false
	return grid[gy * GRID_W + gx] == VISIBLE
