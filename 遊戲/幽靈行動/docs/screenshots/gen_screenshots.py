"""
Ghost Ops - Screenshot Generator
Based on actual GDScript source: base.gd, hud.gd, decision_panel.gd, main.gd
Output: 540x960 (half of 1080x1920)
Scale: 0.5x
Chinese characters displayed via system fonts or fallback labels
"""

from PIL import Image, ImageDraw, ImageFont
import os

# ── Output directory ──────────────────────────────────────────────────
OUT_DIR = r"d:\開發遊戲\遊戲\幽靈行動\docs\screenshots"
W, H = 540, 960
SCALE = 0.5

# ── Find a CJK-capable font ───────────────────────────────────────────
def find_cjk_font(size):
    """Try several common CJK font paths; fall back to default."""
    candidates = [
        r"C:\Windows\Fonts\msjh.ttc",       # Microsoft JhengHei (繁中)
        r"C:\Windows\Fonts\msjhbd.ttc",
        r"C:\Windows\Fonts\mingliu.ttc",
        r"C:\Windows\Fonts\kaiu.ttf",
        r"C:\Windows\Fonts\NotoSansCJK-Regular.ttc",
        r"C:\Windows\Fonts\simhei.ttf",      # Simplified fallback
        r"C:\Windows\Fonts\simsun.ttc",
    ]
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()

# Pre-load common sizes
FONTS = {sz: find_cjk_font(sz) for sz in [10, 11, 12, 13, 14, 16, 18, 20, 22, 24, 28, 30, 32, 36, 40, 42, 48]}

def font(size):
    return FONTS.get(size, FONTS[16])

# ── Colour helpers ────────────────────────────────────────────────────
def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def hex2rgba(h, a=255):
    return (*hex2rgb(h), a)

def blend(base_img, overlay_color, alpha_frac, box=None):
    """Blend a semi-transparent rectangle onto base_img."""
    overlay = Image.new("RGBA", base_img.size, (0, 0, 0, 0))
    odraw = ImageDraw.Draw(overlay)
    r, g, b = overlay_color
    a = int(alpha_frac * 255)
    if box:
        odraw.rectangle(box, fill=(r, g, b, a))
    else:
        odraw.rectangle([0, 0, base_img.width - 1, base_img.height - 1], fill=(r, g, b, a))
    base_img = Image.alpha_composite(base_img.convert("RGBA"), overlay)
    return base_img

def rounded_rect(draw, box, radius, fill, outline=None, outline_width=2):
    x0, y0, x1, y1 = box
    draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=fill,
                            outline=outline, width=outline_width)

# ─────────────────────────────────────────────────────────────────────
# SCREEN 1 — Base Scene  (base.gd)
# Real coords 1080x1920, drawn at 540x960 (0.5x)
# ─────────────────────────────────────────────────────────────────────
def draw_screen1():
    img = Image.new("RGB", (W, H), hex2rgb("0F150F"))
    d = ImageDraw.Draw(img)

    # ── Top bar (100px real → 50px drawn) ──────────────────────────
    d.rectangle([0, 0, W, 50], fill=hex2rgb("0D0F0D"))
    # Title "幽靈行動 — 基地"  (font_size 32 → ~16px drawn)
    d.text((15, 13), "幽靈行動 — 基地", font=font(16), fill=(230, 230, 178))
    # Coins label right side  (font_size 26 → ~13px drawn)
    coins_txt = "金幣：500"
    d.text((380, 16), coins_txt, font=font(13), fill=(255, 230, 77))

    # ── Mission Board ──────────────────────────────────────────────
    # Section title y=120 real → 60 drawn
    d.text((15, 60), "任務板", font=font(13), fill=hex2rgb("CCFFCC"))
    # Separator y=158 real → 79 drawn
    d.line([(15, 79), (525, 79)], fill=hex2rgb("4D804D"), width=1)

    # Mission card  y=170 real → 85 drawn, h=175 real → 87 drawn, w=1020 real → 510 drawn
    card_y = 85
    card_h = 87
    rounded_rect(d, [15, card_y, 525, card_y + card_h], radius=4,
                 fill=hex2rgb("141E14"), outline=None)
    # Left gold border strip  3px real → 1.5 → 2px drawn
    d.rectangle([15, card_y, 18, card_y + card_h], fill=hex2rgb("E6B31A"))
    # [主線] label
    d.text((22, card_y + 5), "[主線]", font=font(9), fill=(255, 204, 51))
    # Mission title
    d.text((22, card_y + 17), "辦公大樓清查", font=font(12), fill=(255, 255, 255))
    # Difficulty
    d.text((22, card_y + 35), "難度：★★", font=font(9), fill=(255, 153, 51))
    # Desc
    d.text((22, card_y + 48), "情報顯示敵軍盤踞...", font=font(8), fill=(191, 191, 191))
    # DEMO tag (right side)
    d.text((385, card_y + 35), "[ DEMO 任務 ]", font=font(9), fill=hex2rgb("66FF66"))
    # Reward
    d.text((22, card_y + 68), "獎勵：200 金幣", font=font(9), fill=hex2rgb("80FF80"))

    # ── Squad Panel  y=560 real → 280 drawn ───────────────────────
    squad_y = 200
    d.text((15, squad_y), "陣容選擇（選 4 人）", font=font(13), fill=hex2rgb("CCFFCC"))
    d.line([(15, squad_y + 19), (525, squad_y + 19)], fill=hex2rgb("4D804D"), width=1)

    # "可用職業：" label
    d.text((15, squad_y + 25), "可用職業：", font=font(9), fill=(178, 178, 178))

    # 6 class buttons (155x60 real → 77x30 drawn, gap 165 real → 82 drawn)
    classes = [
        ("盾兵",  "FF8C00", True),
        ("醫療兵", "FFFFFF", True),
        ("突擊手", "FF2121", True),
        ("狙擊手", "45FF45", True),
        ("爆破手", "CCAA00", False),
        ("偵察手", "00CCCC", False),
    ]
    btn_w, btn_h = 77, 30
    for i, (name, col, selected) in enumerate(classes):
        bx = 15 + i * 84
        by = squad_y + 38
        bg_col = hex2rgb("1A2B1A") if not selected else hex2rgb("0A1A0A")
        border_col = hex2rgb(col) if selected else hex2rgb("3A4A3A")
        rounded_rect(d, [bx, by, bx + btn_w, by + btn_h], radius=4,
                     fill=bg_col, outline=border_col, outline_width=2 if selected else 1)
        label = name + " ✓" if selected else name
        txt_col = hex2rgb(col) if selected else (178, 178, 178)
        d.text((bx + 4, by + 8), label, font=font(9), fill=txt_col)

    # Squad slots "出戰陣容：" (4 slots)
    d.text((15, squad_y + 75), "出戰陣容：", font=font(9), fill=(178, 178, 178))
    slot_classes = [("盾兵", "FF8C00"), ("醫療兵", "FFFFFF"), ("突擊手", "E8600A"), ("狙擊手", "45FF45")]
    slot_w = 120
    for i, (name, col) in enumerate(slot_classes):
        sx = 15 + i * 127
        sy = squad_y + 90
        rounded_rect(d, [sx, sy, sx + slot_w, sy + 35], radius=4,
                     fill=hex2rgb("1A1A26"), outline=hex2rgb(col), outline_width=2)
        d.text((sx + 8, sy + 10), name, font=font(11), fill=hex2rgb(col))

    # ── Launch Button  y=900 real → 450 drawn, 500x90 real → 250x45 drawn ──
    launch_y = 430
    rounded_rect(d, [145, launch_y, 395, launch_y + 45], radius=6,
                 fill=hex2rgb("991F00"), outline=hex2rgb("CC3300"), outline_width=2)
    # Center text
    txt = "出發"
    bbox = d.textbbox((0, 0), txt, font=font(20))
    tw = bbox[2] - bbox[0]
    d.text((270 - tw // 2, launch_y + 11), txt, font=font(20), fill=(255, 255, 255))

    img.save(os.path.join(OUT_DIR, "01_base.png"))
    print("Saved 01_base.png")


# ─────────────────────────────────────────────────────────────────────
# SCREEN 2 — Mission Scene + HUD  (main.gd + hud.gd)
# ─────────────────────────────────────────────────────────────────────
def draw_screen2():
    img = Image.new("RGB", (W, H), hex2rgb("1A2A1A"))
    d = ImageDraw.Draw(img)

    # ── Map path line (from main.gd WAYPOINTS scaled 0.5x) ─────────
    waypoints = [
        (270, 875), (270, 750), (270, 625), (270, 500),
        (270, 425), (270, 340), (270, 250), (270, 175),
        (270, 100), (270, 40),
    ]
    for i in range(len(waypoints) - 1):
        d.line([waypoints[i], waypoints[i+1]], fill=hex2rgb("262629"), width=60)

    # Room visuals (from _add_room_visual, scaled 0.5x)
    rooms = [
        ((195, 575), (150, 100), "272B36", "房間A"),   # (390,1150) * 0.5 = 195,575; 300x200→150x100
        ((195, 375), (150, 100), "272734", "房間B"),
        ((195, 130), (150,  90), "292228", "房間C"),
        ((190,  60), (160,  60), "402020", "Boss"),
    ]
    for (rx, ry), (rw, rh), col, label in rooms:
        d.rectangle([rx, ry, rx + rw, ry + rh], fill=hex2rgb(col))
        d.text((rx + 5, ry + 5), label, font=font(9), fill=(204, 204, 204))

    # Start & end labels
    d.text((220, 882), "起點", font=font(9), fill=hex2rgb("99CC99"))
    d.text((220, 28), "任務完成", font=font(9), fill=hex2rgb("FFE64D"))

    # Enemy markers (grey squares with red tint)
    enemy_positions = [(250, 560), (300, 560)]
    for ex, ey in enemy_positions:
        d.rectangle([ex - 12, ey - 12, ex + 12, ey + 12], fill=(90, 30, 30))
        d.rectangle([ex - 12, ey - 12, ex + 12, ey + 12], outline=(180, 60, 60), width=1)
        d.text((ex - 5, ey - 6), "敵", font=font(9), fill=(220, 80, 80))

    # Squad character circles (scaled: 40px radius → 20px)
    squad_chars = [
        (205, 710, "FF8C00", "盾"),
        (240, 710, "FFFFFF", "醫"),
        (270, 710, "E8600A", "突"),
        (305, 710, "45FF45", "狙"),
    ]
    # Path highlight dots
    for cx, cy, col, abbr in squad_chars:
        d.ellipse([cx - 20, cy - 20, cx + 20, cy + 20],
                  fill=hex2rgb(col), outline=(255, 255, 255), width=1)
        d.text((cx - 7, cy - 7), abbr, font=font(10), fill=(20, 20, 20))

    # Yellow dashed path to enemies
    for i in range(0, 50, 8):
        d.line([(270, 710 - i), (270, 710 - i - 4)], fill=(255, 220, 0), width=2)

    # ── Top HUD strip ───────────────────────────────────────────────
    # Semi-transparent dark bar at top
    top_strip = Image.new("RGBA", (W, 35), (0, 0, 0, 180))
    img_rgba = img.convert("RGBA")
    img_rgba.alpha_composite(top_strip, (0, 0))
    img = img_rgba.convert("RGB")
    d = ImageDraw.Draw(img)

    # Progress bar bg + fill
    d.rectangle([10, 8, 530, 20], fill=(40, 40, 40))
    d.rectangle([10, 8, 250, 20], fill=hex2rgb("44CC44"))  # ~46% done
    d.text((220, 22), "房間A", font=font(9), fill=(255, 255, 255))
    d.text((10, 22), "進度 46%", font=font(9), fill=(200, 200, 200))

    # ── Bottom HUD (hud.gd: CARD_W=236 CARD_H=178 → 118x89 drawn) ─
    hud_h = 120
    hud_y = H - hud_h
    # HUD background (semi-transparent black)
    hud_bg = Image.new("RGBA", (W, hud_h), (0, 0, 0, 230))
    img_rgba2 = img.convert("RGBA")
    img_rgba2.alpha_composite(hud_bg, (0, hud_y))
    img = img_rgba2.convert("RGB")
    d = ImageDraw.Draw(img)

    # 4 character cards (118x89 each, gap ~5px, from x=8)
    # Card colors from hud.gd COLOR_NORMAL_BG #1A2B1A, border #3A4A3A, ready border #E8600A
    card_colors = [
        ("FF8C00", "盾兵",  True),   # shield
        ("44CC44", "醫療兵", True),   # medic (hud uses #44CC44 not white)
        ("E8600A", "突擊手", True),   # assault
        ("AA44FF", "狙擊手", True),   # sniper (from main.gd CHAR_DATA)
    ]
    cw, ch = 118, 89
    for i, (col, name, ready) in enumerate(card_colors):
        cx = 8 + i * (cw + 5)
        cy = hud_y + 4
        # Card bg
        rounded_rect(d, [cx, cy, cx + cw, cy + ch], radius=4,
                     fill=hex2rgb("1A2B1A"),
                     outline=hex2rgb("E8600A") if ready else hex2rgb("3A4A3A"),
                     outline_width=2)
        # Class circle (44x44 real → 22x22 drawn), at x+5,y+3
        circle_r = 11
        d.ellipse([cx + 5, cy + 3, cx + 5 + circle_r * 2, cy + 3 + circle_r * 2],
                  fill=hex2rgb(col))
        # Name
        d.text((cx + 30, cy + 8), name, font=font(9), fill=hex2rgb("F0F0F0"))
        # HP bar bg (at y+29 real 58→29 drawn)
        d.rectangle([cx + 5, cy + 29, cx + cw - 5, cy + 34], fill=hex2rgb("3A3A3A"))
        # HP bar fill (70% full = green)
        hp_end = cx + 5 + int((cw - 10) * 0.70)
        d.rectangle([cx + 5, cy + 29, hp_end, cy + 34], fill=hex2rgb("44CC44"))
        # HP%
        d.text((cx + cw - 28, cy + 20), "70%", font=font(8), fill=hex2rgb("F0F0F0"))
        # Ult area bg (bottom 44px → 44 real / 2 = 22 drawn)
        ult_y = cy + ch - 40
        d.rectangle([cx, ult_y, cx + cw, cy + ch], fill=hex2rgb("223322"))
        # Ult ready text / CD text
        if ready:
            ult_txt = "大招就緒"
            d.text((cx + 16, ult_y + 4), ult_txt, font=font(9), fill=hex2rgb("44CC44"))
        else:
            d.text((cx + 25, ult_y + 4), "冷卻中", font=font(9), fill=hex2rgb("888888"))

    img.save(os.path.join(OUT_DIR, "02_mission.png"))
    print("Saved 02_mission.png")


# ─────────────────────────────────────────────────────────────────────
# SCREEN 3 — Decision Panel  (decision_panel.gd)
# ─────────────────────────────────────────────────────────────────────
def draw_screen3():
    # Base = blurred/dark version of mission scene background
    img = Image.new("RGB", (W, H), hex2rgb("1A2A1A"))
    d = ImageDraw.Draw(img)

    # Background scene elements (same as screen 2 but simplified)
    waypoints = [(270, 875), (270, 40)]
    d.line([waypoints[0], waypoints[1]], fill=hex2rgb("222226"), width=60)

    rooms_bg = [
        ((195, 575), (150, 100), "202330"),
        ((195, 375), (150, 100), "202230"),
        ((195, 130), (150,  90), "201B28"),
        ((190,  60), (160,  60), "301818"),
    ]
    for (rx, ry), (rw, rh), col in rooms_bg:
        d.rectangle([rx, ry, rx + rw, ry + rh], fill=hex2rgb(col))

    # Dim overlay 60%
    img = blend(img, (0, 0, 0), 0.60)
    d = ImageDraw.Draw(img)

    # ── Decision Panel ─────────────────────────────────────────────
    # Panel: 460x380 real → 230x190 drawn, centered
    pw, ph = 360, 300
    px = (W - pw) // 2
    py = (H - ph) // 2 - 30
    rounded_rect(d, [px, py, px + pw, py + ph], radius=6,
                 fill=hex2rgb("0D190D"), outline=hex2rgb("336633"), outline_width=2)

    # Title
    title = "前方房間"
    bbox = d.textbbox((0, 0), title, font=font(16))
    tw = bbox[2] - bbox[0]
    d.text((px + (pw - tw) // 2, py + 14), title, font=font(16), fill=(255, 255, 255))

    # Subtitle
    sub = "偵測到敵方移動，如何進入？"
    bbox2 = d.textbbox((0, 0), sub, font=font(10))
    tw2 = bbox2[2] - bbox2[0]
    d.text((px + (pw - tw2) // 2, py + 36), sub, font=font(10), fill=(160, 160, 160))

    # Separator
    d.line([(px + 16, py + 54), (px + pw - 16, py + 54)], fill=hex2rgb("336633"), width=1)

    # Three option buttons (actual decision_panel.gd options)
    options = [
        ("直衝突入",  "快速但危險，全隊可能受傷",     "1E3A1E", "4D994D", "▶"),
        ("靜悄進入",  "緩慢但安全，敵人無法提前警戒",  "1E2A3A", "4D664D", "▷"),
        ("投擲炸彈",  "需要爆破手，清場效果佳",        "3A2A1E", "996633", "●"),
    ]
    opt_h = 60
    for i, (label, desc, bg, border, icon) in enumerate(options):
        oy = py + 64 + i * (opt_h + 8)
        rounded_rect(d, [px + 12, oy, px + pw - 12, oy + opt_h], radius=4,
                     fill=hex2rgb(bg), outline=hex2rgb(border), outline_width=2)
        # Icon
        icon_col = hex2rgb("E8600A") if i == 2 else (180, 220, 180)
        d.text((px + 20, oy + 16), icon, font=font(12), fill=icon_col)
        # Main label
        d.text((px + 38, oy + 10), label, font=font(13), fill=(255, 255, 255))
        # Desc
        d.text((px + 38, oy + 30), desc, font=font(9), fill=(140, 140, 140))

    img = img.convert("RGB")
    img.save(os.path.join(OUT_DIR, "03_decision.png"))
    print("Saved 03_decision.png")


# ─────────────────────────────────────────────────────────────────────
# SCREEN 4 — Victory Screen  (hud.gd _on_game_won)
# ─────────────────────────────────────────────────────────────────────
def draw_screen4():
    # Gradient background from #0A1A0A to #1A3A1A
    img = Image.new("RGB", (W, H))
    for y in range(H):
        frac = y / H
        r = int(10 + frac * (26 - 10))
        g = int(26 + frac * (58 - 26))
        b = int(10 + frac * (26 - 10))
        for x in range(W):
            img.putpixel((x, y), (r, g, b))
    d = ImageDraw.Draw(img)

    # Subtle particle dots for ambience
    import random
    rng = random.Random(42)
    for _ in range(80):
        px_ = rng.randint(0, W)
        py_ = rng.randint(0, 400)
        r_ = rng.randint(1, 3)
        alpha_ = rng.randint(60, 180)
        d.ellipse([px_ - r_, py_ - r_, px_ + r_, py_ + r_],
                  fill=(255, 215, 0, alpha_))

    # ── Victory title  y=200 real → 100 drawn ─────────────────────
    v_title = "任務完成！"
    bbox = d.textbbox((0, 0), v_title, font=font(36))
    tw = bbox[2] - bbox[0]
    d.text(((W - tw) // 2, 130), v_title, font=font(36), fill=hex2rgb("FFD700"))

    # Subtitle  y=260 real → 130 drawn
    sub = "辦公大樓清查 — 全部清除"
    bbox2 = d.textbbox((0, 0), sub, font=font(14))
    tw2 = bbox2[2] - bbox2[0]
    d.text(((W - tw2) // 2, 176), sub, font=font(14), fill=(255, 255, 255))

    # ── Reward block  y=320 real → 160 drawn, 360x100 real → 180x50 drawn ──
    rw_, rh_ = 320, 80
    rx = (W - rw_) // 2
    ry = 220
    rounded_rect(d, [rx, ry, rx + rw_, ry + rh_], radius=8,
                 fill=hex2rgb("1A2A1A"), outline=hex2rgb("336633"), outline_width=2)
    # "獎勵" title
    d.text((rx + 16, ry + 8), "獎勵", font=font(12), fill=hex2rgb("66FF66"))
    # Gold coin circle
    d.ellipse([rx + 14, ry + 30, rx + 50, ry + 66], fill=hex2rgb("FFD700"))
    d.text((rx + 22, ry + 39), "幣", font=font(14), fill=(80, 50, 0))
    # Coin amount
    d.text((rx + 60, ry + 35), "+ 200 金幣", font=font(20), fill=hex2rgb("FFD700"))

    # ── Stats  y=440 real → 220 drawn ──────────────────────────────
    stats_y = 330
    d.text(((W - 130) // 2, stats_y), "隊員存活：3/4", font=font(14), fill=(255, 255, 255))
    d.text(((W - 130) // 2, stats_y + 26), "通關時間：4:32", font=font(14), fill=(255, 255, 255))

    # ── Return button  y=580 real → 290 drawn, 280x50 real → 140x25 drawn ──
    btn_w, btn_h = 280, 50
    bx = (W - btn_w) // 2
    by = 420
    rounded_rect(d, [bx, by, bx + btn_w, by + btn_h], radius=8,
                 fill=hex2rgb("3A5A1A"), outline=hex2rgb("5A8A2A"), outline_width=2)
    btn_txt = "返回基地"
    bbox3 = d.textbbox((0, 0), btn_txt, font=font(18))
    tw3 = bbox3[2] - bbox3[0]
    d.text((bx + (btn_w - tw3) // 2, by + 15), btn_txt, font=font(18), fill=(255, 255, 255))

    img.save(os.path.join(OUT_DIR, "04_victory.png"))
    print("Saved 04_victory.png")


# ── Main ──────────────────────────────────────────────────────────────
if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    draw_screen1()
    draw_screen2()
    draw_screen3()
    draw_screen4()

    # Verify
    files = ["01_base.png", "02_mission.png", "03_decision.png", "04_victory.png"]
    print("\nVerification:")
    for f in files:
        fp = os.path.join(OUT_DIR, f)
        if os.path.exists(fp):
            size = os.path.getsize(fp)
            print(f"  ✓ {f}  ({size:,} bytes)")
        else:
            print(f"  ✗ {f}  MISSING")
