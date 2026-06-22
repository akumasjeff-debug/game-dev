extends Control

# ───────────────────────────────────────────────────────────────
# hud_radial.gd — 技能卡 CD 環形進度繪製節點
# 由 hud.gd 動態建立，疊在角色立繪上方。
# 透過 set_cd_ratio() 設定剩餘比例（0.0=就緒, 1.0=剛施放）。
# 就緒時 ratio=0 → 不繪製環，露出立繪；CD 中繪製橘色弧線環。
# ───────────────────────────────────────────────────────────────

var cd_ratio: float = 0.0          # 0=就緒 1=滿CD（剩餘越多越接近1）
var ring_color: Color = Color(0.93, 0.45, 0.12, 0.95)   # 戰術橘
var track_color: Color = Color(0.0, 0.0, 0.0, 0.55)     # 底環暗色
var ring_width: float = 8.0
var draw_track: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_cd_ratio(r: float) -> void:
	var nr := clampf(r, 0.0, 1.0)
	if not is_equal_approx(nr, cd_ratio):
		cd_ratio = nr
		queue_redraw()

func set_ring_color(c: Color) -> void:
	if c != ring_color:
		ring_color = c
		queue_redraw()

func _draw() -> void:
	if cd_ratio <= 0.001:
		return
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - ring_width
	if radius <= 2.0:
		return
	# 底環（整圈暗色）
	if draw_track:
		draw_arc(center, radius, 0.0, TAU, 64, track_color, ring_width, true)
	# 進度弧：從正上方 (-90°) 順時針填，剩餘越多弧越長
	var start_ang := -PI * 0.5
	var sweep := TAU * cd_ratio
	draw_arc(center, radius, start_ang, start_ang + sweep, 64, ring_color, ring_width, true)
