## AudioManager.gd
## 音訊管理 AutoLoad — 全局單例
## 負責 BGM 播放控制與 SFX 一次性音效播放
## 掛載方式：project.godot [autoload] AudioManager="*res://scripts/core/audio_manager.gd"

extends Node


# ============================================================
# 常數
# ============================================================

## 靜音時使用的 dB 值（AudioStreamPlayer 的有效靜音下限）
const DB_SILENT: float = -80.0

## 線性音量 0.0~1.0 對應的 dB 轉換下限（避免 log(0)）
const VOLUME_MIN: float = 0.0001


# ============================================================
# 音訊節點
# ============================================================

## BGM 播放器（同一時間只播一首，淡出後換曲）
var _bgm_player: AudioStreamPlayer

## SFX 播放器（一次性音效，複音需求後續可改用 AudioStreamPolyphonic）
var _sfx_player: AudioStreamPlayer


# ============================================================
# 音量屬性
# ============================================================

## BGM 音量（0.0 = 靜音，1.0 = 滿音量）
var bgm_volume: float = 1.0 :
	set(value):
		bgm_volume = clampf(value, 0.0, 1.0)
		_apply_bgm_volume()

## SFX 音量（0.0 = 靜音，1.0 = 滿音量）
var sfx_volume: float = 1.0 :
	set(value):
		sfx_volume = clampf(value, 0.0, 1.0)
		_apply_sfx_volume()


# ============================================================
# 內部狀態
# ============================================================

## 目前播放中的 BGM stream，用於防止重複播放同一首
var _current_bgm_stream: AudioStream = null


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	# 建立 BGM 播放器
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = "BGM"
	add_child(_bgm_player)

	# 建立 SFX 播放器
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SFXPlayer"
	_sfx_player.bus = "SFX"
	add_child(_sfx_player)

	# 套用初始音量
	_apply_bgm_volume()
	_apply_sfx_volume()

	print("[AudioManager] 初始化完成，BGM bus=%s SFX bus=%s" % [_bgm_player.bus, _sfx_player.bus])


# ============================================================
# BGM 控制
# ============================================================

## 播放 BGM；若傳入的 stream 與目前相同則不重播
## stream: 要播放的 AudioStream 資源；傳入 null 等同呼叫 stop_bgm()
func play_bgm(stream: AudioStream) -> void:
	if stream == null:
		stop_bgm()
		return

	# 同一首不重播
	if stream == _current_bgm_stream and _bgm_player.playing:
		return

	_current_bgm_stream = stream
	_bgm_player.stream = stream
	_bgm_player.play()
	print("[AudioManager] 播放 BGM：%s" % stream.resource_path)


## 停止 BGM 播放
func stop_bgm() -> void:
	if _bgm_player.playing:
		_bgm_player.stop()
	_current_bgm_stream = null
	print("[AudioManager] BGM 停止")


# ============================================================
# SFX 控制
# ============================================================

## 播放一次性音效（不影響 BGM）
## stream: 要播放的 AudioStream 資源
func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		push_warning("[AudioManager] play_sfx 收到 null stream，略過")
		return

	_sfx_player.stream = stream
	_sfx_player.play()


# ============================================================
# 音量控制（外部介面）
# ============================================================

## 設定 BGM 音量（0.0~1.0）
func set_bgm_volume(value: float) -> void:
	bgm_volume = value


## 設定 SFX 音量（0.0~1.0）
func set_sfx_volume(value: float) -> void:
	sfx_volume = value


# ============================================================
# 內部音量套用
# ============================================================

## 將線性音量值轉換為 dB 並套用至 BGM 播放器
func _apply_bgm_volume() -> void:
	if _bgm_player == null:
		return
	_bgm_player.volume_db = _linear_to_db(bgm_volume)


## 將線性音量值轉換為 dB 並套用至 SFX 播放器
func _apply_sfx_volume() -> void:
	if _sfx_player == null:
		return
	_sfx_player.volume_db = _linear_to_db(sfx_volume)


## 線性音量（0.0~1.0）轉換為 dB
## 0.0 → DB_SILENT（-80 dB），1.0 → 0 dB
func _linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return DB_SILENT
	# clamp 到最小正值，避免 log(0)
	var clamped: float = maxf(linear, VOLUME_MIN)
	return 20.0 * log(clamped) / log(10.0)
