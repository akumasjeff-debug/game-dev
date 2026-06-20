extends AnimatedSprite2D

# 8 方向 AnimatedSprite2D 控制器
# 根據父節點 rotation 自動切換對應方向動畫
# 使用 set_as_top_level 讓 sprite 不跟著父節點旋轉

const IDLE_PATH = "res://assets/characters/swat/policeman_cc0/Policeman/_idle/"
const WALK_PATH = "res://assets/characters/swat/policeman_cc0/Policeman/_walk/"
const SHOOT_PATH = "res://assets/characters/swat/policeman_cc0/Policeman/_shoot/"

const SCALE_FACTOR = 0.25
const IDLE_FPS = 10
const WALK_FPS = 12
const SHOOT_FPS = 14
const NUM_DIRS = 8

# direction 0 = 南（下），順時針排列
# rotation=0 (右/東) → offset 讓它對應正確 direction
# 若角色朝向看起來歪的，調整這個值 (0-7)
const DIR_OFFSET = 6

func _ready():
	top_level = true   # 脫離父節點 transform，sprite 不跟著父節點旋轉
	scale = Vector2(SCALE_FACTOR, SCALE_FACTOR)
	_build_frames()

func _build_frames():
	var sf = SpriteFrames.new()

	# idle（每方向 16 幀）
	for dir in range(NUM_DIRS):
		var anim = "idle_%d" % dir
		sf.add_animation(anim)
		sf.set_animation_speed(anim, IDLE_FPS)
		sf.set_animation_loop(anim, true)
		for f in range(16):
			var path = IDLE_PATH + "cop_idle_%d%04d.png" % [dir, f]
			var tex = _try_load(path)
			if tex:
				sf.add_frame(anim, tex)

	# walk（掃目錄，按方向分組）
	_load_dir_anim(sf, WALK_PATH, "cop_walk_", "walk", WALK_FPS, 8)

	# shoot（掃目錄，按方向分組）
	_load_dir_anim(sf, SHOOT_PATH, "cop_shoot_", "shoot", SHOOT_FPS, 6)

	sprite_frames = sf
	play("idle_0")

func _load_dir_anim(sf: SpriteFrames, dir_path: String, prefix: String,
					anim_prefix: String, fps: float, _frames_hint: int):
	var abs_dir = ProjectSettings.globalize_path(dir_path)
	for dir in range(NUM_DIRS):
		var anim = "%s_%d" % [anim_prefix, dir]
		sf.add_animation(anim)
		sf.set_animation_speed(anim, fps)
		sf.set_animation_loop(anim, true)

		var da = DirAccess.open(abs_dir)
		if not da:
			continue
		var files: Array[String] = []
		da.list_dir_begin()
		var fname = da.get_next()
		while fname != "":
			if fname.begins_with(prefix + str(dir)):
				files.append(fname)
			fname = da.get_next()
		da.list_dir_end()
		files.sort()
		for f in files:
			var tex = _try_load(dir_path + f)
			if tex:
				sf.add_frame(anim, tex)

func _try_load(path: String) -> Texture2D:
	var abs_path = ProjectSettings.globalize_path(path)
	var img = Image.load_from_file(abs_path)
	if img:
		return ImageTexture.create_from_image(img)
	return null

func _process(_delta):
	# top_level = true 後節點脫離父節點 transform，需手動跟隨 parent position
	global_position = get_parent().global_position
	# global_rotation 保持 0（top_level 預設就是 0，不需額外設定）

func update_direction(angle: float):
	var normalized = fmod(angle + 2.0 * PI, 2.0 * PI)
	var dir = (int(round(normalized / (PI / 4.0))) + DIR_OFFSET) % NUM_DIRS
	_try_anim("idle_%d" % dir)

func play_walk(angle: float):
	var normalized = fmod(angle + 2.0 * PI, 2.0 * PI)
	var dir = (int(round(normalized / (PI / 4.0))) + DIR_OFFSET) % NUM_DIRS
	_try_anim("walk_%d" % dir)

func play_shoot(angle: float):
	var normalized = fmod(angle + 2.0 * PI, 2.0 * PI)
	var dir = (int(round(normalized / (PI / 4.0))) + DIR_OFFSET) % NUM_DIRS
	_try_anim("shoot_%d" % dir)

func _try_anim(anim: String):
	if sprite_frames and sprite_frames.has_animation(anim) and animation != anim:
		play(anim)
