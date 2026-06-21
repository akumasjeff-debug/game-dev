extends CanvasLayer

# 角色升級管理面板 — CanvasLayer layer=16
# 掛在 UpgradePanel.tscn

const CHAR_NAMES = {
	"shield": "盾兵",
	"medic": "醫療兵",
	"assault": "突擊手",
	"sniper": "狙擊手",
	"demo": "爆破手",
	"recon": "偵察手",
}

const BASE_STATS = {
	"shield":  {"hp": 200, "atk": 40,  "def": 25},
	"medic":   {"hp": 160, "atk": 25,  "def": 20},
	"assault": {"hp": 155, "atk": 60,  "def": 15},
	"sniper":  {"hp": 110, "atk": 120, "def": 10},
	"demo":    {"hp": 135, "atk": 80,  "def": 18},
	"recon":   {"hp": 140, "atk": 35,  "def": 17},
}

const POTENTIAL_UNLOCK = {
	"shield":  "破門衝擊 — 大招附帶眩暈效果",
	"medic":   "急救強化 — 大招治療量 +50%",
	"assault": "火力壓制 — 大招持續時間 +4 秒",
	"sniper":  "精準狙擊 — 瞬殺閾值提升至 35%",
	"demo":    "連鎖爆破 — 大招傷害提升至 100%",
	"recon":   "電磁脈衝 — 煙霧持續時間 +3 秒",
}

const CHAR_COLORS = {
	"shield":  Color(1.0, 0.55, 0.0),
	"medic":   Color(0.267, 0.800, 0.267),
	"assault": Color(0.910, 0.376, 0.039),
	"sniper":  Color(0.667, 0.267, 1.0),
	"demo":    Color(0.800, 0.133, 0.133),
	"recon":   Color(0.267, 0.800, 0.800),
}

const ALL_IDS = ["shield", "medic", "assault", "sniper", "demo", "recon"]
const RARITY_NAMES = ["灰色", "SR 銀", "SSR 金"]
const RARITY_COLORS = [
	Color(0.6, 0.6, 0.65),
	Color(0.82, 0.87, 1.0),
	Color(1.0, 0.85, 0.2),
]

var _char_list_container: VBoxContainer

func _ready() -> void:
	layer = 16
	_build_ui()

func _build_ui() -> void:
	# 全螢幕半透明背景
	var bg = ColorRect.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.0, 0.0, 0.0, 0.88)
	add_child(bg)

	# 主面板
	var panel = ColorRect.new()
	panel.position = Vector2(30, 60)
	panel.size = Vector2(1020, 1800)
	panel.color = Color(0.05, 0.07, 0.10, 0.97)
	add_child(panel)

	# 標題
	var title = Label.new()
	title.text = "角色升級管理"
	title.position = Vector2(330, 80)
	title.add_theme_font_size_override("font_size", 36)
	title.modulate = Color(1.0, 0.9, 0.3)
	add_child(title)

	# 分隔線
	var sep = ColorRect.new()
	sep.position = Vector2(50, 136)
	sep.size = Vector2(980, 2)
	sep.color = Color(0.5, 0.4, 0.1, 0.8)
	add_child(sep)

	# 金幣顯示
	var coins_lbl = Label.new()
	coins_lbl.name = "CoinsLabel"
	coins_lbl.position = Vector2(60, 150)
	coins_lbl.add_theme_font_size_override("font_size", 22)
	coins_lbl.modulate = Color(1.0, 0.9, 0.3)
	add_child(coins_lbl)

	# 捲動容器
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(50, 195)
	scroll.size = Vector2(980, 1510)
	add_child(scroll)

	_char_list_container = VBoxContainer.new()
	_char_list_container.custom_minimum_size = Vector2(960, 0)
	_char_list_container.add_theme_constant_override("separation", 12)
	scroll.add_child(_char_list_container)

	# 關閉按鈕
	var close_btn = Button.new()
	close_btn.text = "關閉"
	close_btn.position = Vector2(340, 1730)
	close_btn.custom_minimum_size = Vector2(400, 70)
	close_btn.add_theme_font_size_override("font_size", 26)
	_style_button(close_btn, Color(0.3, 0.1, 0.1))
	close_btn.pressed.connect(_on_close)
	add_child(close_btn)

	_rebuild_char_list()

func _rebuild_char_list() -> void:
	# 更新金幣顯示
	var coins_lbl = find_child("CoinsLabel", true, false)
	if coins_lbl:
		coins_lbl.text = "目前金幣：" + str(SaveManager.coins)

	# 清除舊列表
	for child in _char_list_container.get_children():
		child.queue_free()

	for char_id in ALL_IDS:
		var card = _build_char_card(char_id)
		_char_list_container.add_child(card)

func _get_unlocked_decisions_text(char_id: String) -> String:
	var rarity = SaveManager.character_rarity.get(char_id, 0)
	match char_id:
		"shield":
			if rarity >= 2: return "已解鎖：舉盾突入 / 盾牆壓制"
			elif rarity >= 1: return "已解鎖：舉盾突入"
			else: return "解鎖 SR 後獲得：舉盾突入"
		"assault":
			if rarity >= 2: return "已解鎖：爆發射擊 / 側翼突破"
			elif rarity >= 1: return "已解鎖：爆發射擊"
			else: return "解鎖 SR 後獲得：爆發射擊"
		"sniper":
			if rarity >= 1: return "已解鎖：目標標記"
			else: return "解鎖 SR 後獲得：目標標記"
		"demo":
			if rarity >= 1: return "已解鎖：定向炸藥"
			else: return "解鎖 SR 後獲得：定向炸藥"
		"medic":
			if rarity >= 1: return "已解鎖：急救注射"
			else: return "解鎖 SR 後獲得：急救注射"
		"recon":
			if rarity >= 1: return "已解鎖：煙幕掩護"
			else: return "解鎖 SR 後獲得：煙幕掩護"
	return ""

func _build_char_card(char_id: String) -> Control:
	var owned = char_id in SaveManager.owned_characters
	var rarity = SaveManager.character_rarity.get(char_id, 0)
	var copies = SaveManager.character_copies.get(char_id, 0)
	var lv = SaveManager.character_levels.get(char_id, 1)
	var char_name = CHAR_NAMES.get(char_id, char_id)
	var char_color = CHAR_COLORS.get(char_id, Color.WHITE)

	var card = ColorRect.new()
	card.custom_minimum_size = Vector2(950, 230)
	card.color = Color(0.08, 0.10, 0.14, 0.95)

	# 左側色條
	var bar = ColorRect.new()
	bar.size = Vector2(5, 140)
	bar.color = char_color if owned else Color(0.3, 0.3, 0.3)
	card.add_child(bar)

	# 職業名稱
	var name_lbl = Label.new()
	name_lbl.text = char_name
	name_lbl.position = Vector2(18, 10)
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.modulate = RARITY_COLORS[rarity] if owned else Color(0.4, 0.4, 0.4)
	card.add_child(name_lbl)

	if not owned:
		# 未解鎖
		var lock_lbl = Label.new()
		lock_lbl.text = "[未解鎖]"
		lock_lbl.position = Vector2(18, 50)
		lock_lbl.add_theme_font_size_override("font_size", 20)
		lock_lbl.modulate = Color(0.5, 0.5, 0.5)
		card.add_child(lock_lbl)
		# 決策說明（未解鎖狀態）
		var decision_lbl_u = Label.new()
		decision_lbl_u.text = _get_unlocked_decisions_text(char_id)
		decision_lbl_u.position = Vector2(18, 148)
		decision_lbl_u.add_theme_font_size_override("font_size", 15)
		decision_lbl_u.modulate = Color(0.5, 0.5, 0.5)
		card.add_child(decision_lbl_u)
		return card

	# 稀有度
	var rarity_lbl = Label.new()
	rarity_lbl.text = "稀有度：" + RARITY_NAMES[rarity]
	rarity_lbl.position = Vector2(18, 48)
	rarity_lbl.add_theme_font_size_override("font_size", 18)
	rarity_lbl.modulate = RARITY_COLORS[rarity]
	card.add_child(rarity_lbl)

	# 備份數
	var copies_lbl = Label.new()
	copies_lbl.text = "備份：" + str(copies) + " 張"
	copies_lbl.position = Vector2(18, 74)
	copies_lbl.add_theme_font_size_override("font_size", 16)
	copies_lbl.modulate = Color(0.8, 0.8, 0.8)
	card.add_child(copies_lbl)

	# 等級
	var lv_lbl = Label.new()
	lv_lbl.text = "Lv. " + str(lv) + " / 10"
	lv_lbl.position = Vector2(18, 98)
	lv_lbl.add_theme_font_size_override("font_size", 16)
	lv_lbl.modulate = Color(0.7, 1.0, 0.7)
	card.add_child(lv_lbl)

	# 實際數值顯示（改進 1）
	var mult = SaveManager.get_rarity_multiplier(char_id) * SaveManager.get_level_multiplier(char_id)
	var base = BASE_STATS.get(char_id, {"hp": 100, "atk": 30, "def": 10})
	var hp_real = int(base["hp"] * mult)
	var atk_real = int(base["atk"] * mult)
	var def_real = int(base["def"] * mult)
	var stats_lbl = Label.new()
	stats_lbl.text = "HP " + str(hp_real) + "  ATK " + str(atk_real) + "  DEF " + str(def_real)
	stats_lbl.position = Vector2(18, 122)
	stats_lbl.add_theme_font_size_override("font_size", 15)
	stats_lbl.modulate = Color(0.7, 0.9, 0.7)
	card.add_child(stats_lbl)

	# 提升稀有度按鈕
	var rarity_btn = Button.new()
	if rarity >= 2:
		rarity_btn.text = "已達 SSR"
		rarity_btn.disabled = true
		_style_button(rarity_btn, Color(0.25, 0.25, 0.1))
	elif copies < 2:
		rarity_btn.text = "提升稀有度（需 " + str(2 - copies) + " 備份）"
		rarity_btn.disabled = true
		_style_button(rarity_btn, Color(0.15, 0.15, 0.25))
	else:
		rarity_btn.text = "提升稀有度（費 2 備份）"
		rarity_btn.disabled = false
		_style_button(rarity_btn, Color(0.15, 0.10, 0.40))
	rarity_btn.position = Vector2(380, 12)
	rarity_btn.custom_minimum_size = Vector2(270, 52)
	rarity_btn.add_theme_font_size_override("font_size", 17)
	rarity_btn.pressed.connect(_on_rarity_up.bind(char_id))
	card.add_child(rarity_btn)

	# 金幣升等按鈕
	var cost = SaveManager.coins_needed_for_level_up(char_id)
	var lv_btn = Button.new()
	if lv >= 10:
		lv_btn.text = "等級已滿"
		lv_btn.disabled = true
		_style_button(lv_btn, Color(0.25, 0.20, 0.0))
	elif SaveManager.coins < cost:
		lv_btn.text = "金幣升等（需 " + str(cost) + " 金）"
		lv_btn.disabled = true
		_style_button(lv_btn, Color(0.15, 0.15, 0.10))
	else:
		lv_btn.text = "金幣升等（" + str(cost) + " 金）"
		lv_btn.disabled = false
		_style_button(lv_btn, Color(0.35, 0.25, 0.0))
	lv_btn.position = Vector2(660, 12)
	lv_btn.custom_minimum_size = Vector2(275, 52)
	lv_btn.add_theme_font_size_override("font_size", 17)
	lv_btn.pressed.connect(_on_level_up.bind(char_id))
	card.add_child(lv_btn)

	# 每升幅說明（改進 2）
	var per_lv_lbl = Label.new()
	per_lv_lbl.text = "每升 1 等：各項數值 +2%"
	per_lv_lbl.position = Vector2(660, 70)
	per_lv_lbl.add_theme_font_size_override("font_size", 13)
	per_lv_lbl.modulate = Color(0.5, 0.7, 0.5)
	card.add_child(per_lv_lbl)

	# 決策解鎖說明
	var decision_lbl = Label.new()
	decision_lbl.text = _get_unlocked_decisions_text(char_id)
	decision_lbl.position = Vector2(18, 148)
	decision_lbl.add_theme_font_size_override("font_size", 15)
	decision_lbl.modulate = Color(0.5, 1.0, 0.5) if rarity >= 1 else Color(0.5, 0.5, 0.5)
	card.add_child(decision_lbl)

	# 潛能解鎖提示（改進 3）
	var potential_txt = POTENTIAL_UNLOCK.get(char_id, "")
	var pot_lbl = Label.new()
	if lv >= 10:
		pot_lbl.text = "✨ " + potential_txt + "（已解鎖！）"
		pot_lbl.modulate = Color(1.0, 0.85, 0.2)
	else:
		pot_lbl.text = "Lv.10 潛能：" + potential_txt
		pot_lbl.modulate = Color(0.4, 0.4, 0.4)
	pot_lbl.position = Vector2(18, 185)
	pot_lbl.add_theme_font_size_override("font_size", 13)
	pot_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	pot_lbl.custom_minimum_size = Vector2(900, 0)
	card.add_child(pot_lbl)

	return card

func _on_rarity_up(char_id: String) -> void:
	AudioManager.play_sfx("btn_click")
	SaveManager.try_upgrade_rarity(char_id)
	_rebuild_char_list()

func _on_level_up(char_id: String) -> void:
	AudioManager.play_sfx("btn_click")
	SaveManager.try_level_up(char_id)
	_rebuild_char_list()

func _on_close() -> void:
	AudioManager.play_sfx("btn_click")
	queue_free()

func _style_button(btn: Button, bg_color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = Color(bg_color.r + 0.2, bg_color.g + 0.2, bg_color.b + 0.2, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(bg_color.r + 0.1, bg_color.g + 0.1, bg_color.b + 0.1)
	hover_style.border_color = Color(bg_color.r + 0.3, bg_color.g + 0.3, bg_color.b + 0.3, 0.9)
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", hover_style)
