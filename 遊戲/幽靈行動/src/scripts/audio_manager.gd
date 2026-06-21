extends Node

# AudioManager — 音效/BGM 統一管理 Autoload
# 設計為黑盒子：其他腳本只呼叫 play_sfx / play_bgm / stop_bgm / play_ult

# ─── 音量設定（0.0 ~ 1.0）───
var bgm_volume: float = 0.8
var sfx_volume: float = 1.0
var ambient_volume: float = 0.5

# ─── SFX 音效池（同時多個音效不互相中斷）───
const SFX_POOL_SIZE: int = 8
var _sfx_pool: Array = []

# ─── BGM 播放器（兩個，用於 crossfade）───
var _bgm_a: AudioStreamPlayer
var _bgm_b: AudioStreamPlayer
var _bgm_active: int = 0  # 0 = A 為主，1 = B 為主
var _crossfade_timer: float = 0.0
var _crossfade_duration: float = 0.5
var _is_crossfading: bool = false

# ─── 音效名稱對應檔案路徑 ───
const SFX_MAP: Dictionary = {
	"btn_click":        "res://audio/ui/btn_click.wav",
	"decision_open":    "res://audio/ui/decision_open.wav",
	"decision_confirm": "res://audio/ui/decision_confirm.wav",
	"ult_ready":        "res://audio/ui/ult_ready.wav",
	"victory":          "res://audio/ui/victory.wav",
	"defeat":           "res://audio/ui/defeat.wav",
	"gunshot":          "res://audio/combat/gunshot.wav",
	"explosion":        "res://audio/combat/explosion.wav",
	"footstep":         "res://audio/combat/footstep.wav",
}

# ─── 大招音效對應（char_id → 檔案路徑）───
const ULT_MAP: Dictionary = {
	"盾兵":  "res://audio/ult/shield_ult.wav",
	"醫療兵": "res://audio/ult/medic_ult.wav",
	"突擊手": "res://audio/ult/assault_ult.wav",
	"狙擊手": "res://audio/ult/sniper_ult.wav",
	"爆破手": "res://audio/ult/demo_ult.wav",
	"偵察手": "res://audio/ult/recon_ult.wav",
	# 支援 char_id 英文格式
	"shield":  "res://audio/ult/shield_ult.wav",
	"medic":   "res://audio/ult/medic_ult.wav",
	"assault": "res://audio/ult/assault_ult.wav",
	"sniper":  "res://audio/ult/sniper_ult.wav",
	"demo":    "res://audio/ult/demo_ult.wav",
	"recon":   "res://audio/ult/recon_ult.wav",
}

func _ready() -> void:
	_build_sfx_pool()
	_build_bgm_players()

func _build_sfx_pool() -> void:
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_pool.append(player)

func _build_bgm_players() -> void:
	_bgm_a = AudioStreamPlayer.new()
	_bgm_a.bus = "Master"
	_bgm_a.volume_db = _linear_to_db(bgm_volume)
	add_child(_bgm_a)

	_bgm_b = AudioStreamPlayer.new()
	_bgm_b.bus = "Master"
	_bgm_b.volume_db = _linear_to_db(0.0)
	add_child(_bgm_b)

# ─── 公開 API ───

func play_sfx(name: String) -> void:
	if not SFX_MAP.has(name):
		push_warning("AudioManager: 未知音效 '%s'" % name)
		return
	var stream = _load_stream(SFX_MAP[name])
	if stream == null:
		return
	var player = _get_free_sfx_player()
	if player == null:
		return
	player.stream = stream
	player.volume_db = _linear_to_db(sfx_volume)
	player.play()

func play_bgm(name: String) -> void:
	if not SFX_MAP.has(name) and not name.begins_with("res://"):
		push_warning("AudioManager: 未知 BGM '%s'" % name)
		return
	var path: String = name if name.begins_with("res://") else SFX_MAP[name]
	var stream = _load_stream(path)
	if stream == null:
		return
	# AudioStreamWAV 需要設 loop_mode；其他格式（OGG、MP3）有獨立 loop 屬性
	var wav_stream = stream as AudioStreamWAV
	if wav_stream:
		wav_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

	# 切換 crossfade
	var incoming: AudioStreamPlayer = _bgm_b if _bgm_active == 0 else _bgm_a
	incoming.stream = stream
	incoming.volume_db = _linear_to_db(0.0)
	incoming.play()
	_is_crossfading = true
	_crossfade_timer = 0.0
	_bgm_active = 1 - _bgm_active

func stop_bgm() -> void:
	_bgm_a.stop()
	_bgm_b.stop()
	_is_crossfading = false

func play_ult(char_class: String) -> void:
	if not ULT_MAP.has(char_class):
		push_warning("AudioManager: 未知職業大招 '%s'" % char_class)
		return
	var stream = _load_stream(ULT_MAP[char_class])
	if stream == null:
		return
	var player = _get_free_sfx_player()
	if player == null:
		return
	player.stream = stream
	player.volume_db = _linear_to_db(sfx_volume)
	player.play()

# ─── 音量控制 ───

func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)

func set_bgm_volume(value: float) -> void:
	bgm_volume = clamp(value, 0.0, 1.0)
	var outgoing: AudioStreamPlayer = _bgm_a if _bgm_active == 0 else _bgm_b
	outgoing.volume_db = _linear_to_db(bgm_volume)

func set_ambient_volume(value: float) -> void:
	ambient_volume = clamp(value, 0.0, 1.0)

# ─── Crossfade 處理 ───

func _process(delta: float) -> void:
	if not _is_crossfading:
		return
	_crossfade_timer += delta
	var t: float = clamp(_crossfade_timer / _crossfade_duration, 0.0, 1.0)

	# 新軌淡入，舊軌淡出
	var incoming: AudioStreamPlayer = _bgm_b if _bgm_active == 1 else _bgm_a
	var outgoing: AudioStreamPlayer = _bgm_a if _bgm_active == 1 else _bgm_b

	incoming.volume_db = _linear_to_db(bgm_volume * t)
	outgoing.volume_db = _linear_to_db(bgm_volume * (1.0 - t))

	if t >= 1.0:
		outgoing.stop()
		_is_crossfading = false

# ─── 內部輔助 ───

func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	# 全滿時回收最舊的（第一個）
	return _sfx_pool[0]

func _load_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: 找不到音效檔 '%s'" % path)
		return null
	return load(path) as AudioStream

func _linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return linear_to_db(linear)
