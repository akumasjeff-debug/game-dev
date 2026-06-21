"""
Ghost Squad: Tactical Command — Publish Screenshots (1080x1920)
Output: docs/screenshots/screenshot_01_base.png
        docs/screenshots/screenshot_02_mission.png
        docs/screenshots/screenshot_03_gacha.png

Colour palette matches ART_SPEC.md
"""

from PIL import Image, ImageDraw, ImageFont
import os
import random

OUT_DIR = r"d:\開發遊戲\遊戲\幽靈行動\docs\screenshots"
W, H = 1080, 1920

# ── CJK font loader ───────────────────────────────────────────────────
def find_cjk_font(size):
    candidates = [
        r"C:\Windows\Fonts\msjh.ttc",
        r"C:\Windows\Fonts\msjhbd.ttc",
        r"C:\Windows\Fonts\mingliu.ttc",
        r"C:\Windows\Fonts\kaiu.ttf",
        r"C:\Windows\Fonts\NotoSansCJK-Regular.ttc",
        r"C:\Windows\Fonts\simhei.ttf",
        r"C:\Windows\Fonts\simsun.ttc",
    ]
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()

FONT_SIZES = [10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 36, 40, 42, 48, 56, 64, 72, 80]
FONTS = {sz: find_cjk_font(sz) for sz in FONT_SIZES}

def font(size):
    closest = min(FONT_SIZES, key=lambda s: abs(s - size))
    return FONTS[closest]

# ── Colour helpers ────────────────────────────────────────────────────
def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def blend_rect(img, box, color, alpha_frac):
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    r, g, b = color
    a = int(alpha_frac * 255)
    d.rectangle(box, fill=(r, g, b, a))
    base = img.convert("RGBA")
    base.alpha_composite(overlay)
    return base.convert("RGB")

def rrect(d, box, radius, fill=None, outline=None, width=3):
    d.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)

def centered_text(d, y, text, fnt, color, img_width=W):
    bbox = d.textbbox((0, 0), text, font=fnt)
    tw = bbox[2] - bbox[0]
    d.text(((img_width - tw) // 2, y), text, font=fnt, fill=color)

# ── Brand bar (top) ───────────────────────────────────────────────────
def draw_top_bar(d, subtitle=""):
    """Shared header: dark bar + game title + subtitle."""
    d.rectangle([0, 0, W, 110], fill=hex2rgb("0D0F0D"))
    d.line([(0, 110), (W, 110)], fill=hex2rgb("E8600A"), width=3)
    centered_text(d, 12, "GHOST SQUAD: TACTICAL COMMAND", font(32), hex2rgb("E8600A"))
    if subtitle:
        centered_text(d, 66, subtitle, font(24), hex2rgb("AACCAA"))

# ─────────────────────────────────────────────────────────────────────
# SCREENSHOT 1 — Base Scene  (1080 x 1920)
# ─────────────────────────────────────────────────────────────────────
def draw_screen1():
    img = Image.new("RGB", (W, H), hex2rgb("0F150F"))
    d = ImageDraw.Draw(img)

    draw_top_bar(d, "基地指揮中心  |  Base HQ")

    # ── Section: Mission Board ────────────────────────────────────────
    section_y = 150
    d.text((30, section_y), "任務板", font=font(28), fill=hex2rgb("CCFFCC"))
    d.line([(30, section_y + 42), (1050, section_y + 42)], fill=hex2rgb("4D804D"), width=2)

    # Mission card
    card_y = section_y + 55
    card_h = 200
    rrect(d, [30, card_y, 1050, card_y + card_h], radius=10,
          fill=hex2rgb("141E14"), outline=hex2rgb("2A4A2A"), width=2)
    d.rectangle([30, card_y, 42, card_y + card_h], fill=hex2rgb("E6B31A"))
    d.text((55, card_y + 14), "[主線任務]", font=font(22), fill=hex2rgb("FFCC33"))
    d.text((55, card_y + 50), "辦公大樓清查", font=font(36), fill=(255, 255, 255))
    d.text((55, card_y + 100), "難度：★★☆", font=font(22), fill=hex2rgb("FF9933"))
    d.text((55, card_y + 138), "情報顯示敵軍正在盤踞 C 棟，需要特戰小隊滲透清查。", font=font(20), fill=hex2rgb("BBBBBB"))
    d.text((55, card_y + 170), "獎勵：+200 金幣", font=font(20), fill=hex2rgb("80FF80"))
    rrect(d, [840, card_y + 140, 1040, card_y + 185], radius=8,
          fill=hex2rgb("3A5A1A"), outline=hex2rgb("5A8A2A"), width=2)
    centered_text(d, card_y + 152, "[ DEMO 任務 ]", font(20), hex2rgb("66FF66"))

    # ── Section: Squad Select ─────────────────────────────────────────
    squad_y = card_y + card_h + 60
    d.text((30, squad_y), "陣容選擇（選 4 人出戰）", font=font(28), fill=hex2rgb("CCFFCC"))
    d.line([(30, squad_y + 42), (1050, squad_y + 42)], fill=hex2rgb("4D804D"), width=2)
    d.text((30, squad_y + 55), "可用職業：", font=font(22), fill=hex2rgb("AAAAAA"))

    # 6 class buttons — two rows of 3
    classes = [
        ("盾兵",    "2255BB", True),
        ("醫療兵",  "22BB88", True),
        ("突擊手",  "E8600A", True),
        ("狙擊手",  "7755AA", True),
        ("爆破手",  "DDAA00", False),
        ("偵察手",  "33CC55", False),
    ]
    btn_w, btn_h = 320, 90
    cols_per_row = 3
    for i, (name, col, selected) in enumerate(classes):
        row = i // cols_per_row
        col_idx = i % cols_per_row
        bx = 30 + col_idx * (btn_w + 22)
        by = squad_y + 90 + row * (btn_h + 18)
        bg = hex2rgb("0A1A0A") if selected else hex2rgb("1A2A1A")
        border = hex2rgb(col) if selected else hex2rgb("3A4A3A")
        border_w = 3 if selected else 1
        rrect(d, [bx, by, bx + btn_w, by + btn_h], radius=8,
              fill=bg, outline=border, width=border_w)
        label = name + "  ✓" if selected else name
        txt_col = hex2rgb(col) if selected else hex2rgb("888888")
        d.text((bx + 16, by + 24), label, font=font(28), fill=txt_col)

    # Squad slots "出戰陣容"
    slots_y = squad_y + 320
    d.text((30, slots_y), "出戰陣容：", font=font(22), fill=hex2rgb("AAAAAA"))
    slot_classes = [("盾兵", "2255BB"), ("醫療兵", "22BB88"), ("突擊手", "E8600A"), ("狙擊手", "7755AA")]
    slot_w, slot_h = 240, 80
    for i, (sname, scol) in enumerate(slot_classes):
        sx = 30 + i * (slot_w + 14)
        sy = slots_y + 38
        rrect(d, [sx, sy, sx + slot_w, sy + slot_h], radius=8,
              fill=hex2rgb("1A1A26"), outline=hex2rgb(scol), width=3)
        d.text((sx + 14, sy + 20), sname, font=font(28), fill=hex2rgb(scol))

    # ── Gold display ──────────────────────────────────────────────────
    gold_y = slots_y + 160
    rrect(d, [30, gold_y, 520, gold_y + 90], radius=10,
          fill=hex2rgb("1A1A0A"), outline=hex2rgb("DDAA00"), width=2)
    d.text((50, gold_y + 20), "金幣：500", font=font(36), fill=hex2rgb("FFD700"))

    # ── Launch button ─────────────────────────────────────────────────
    btn_big_y = 1720
    rrect(d, [240, btn_big_y, 840, btn_big_y + 120], radius=14,
          fill=hex2rgb("991F00"), outline=hex2rgb("CC3300"), width=3)
    centered_text(d, btn_big_y + 30, "出發執行任務", font(56), (255, 255, 255))

    # ── Footer label ──────────────────────────────────────────────────
    d.text((30, 1880), "Demo v0.1.0  |  Ghost Squad: Tactical Command",
           font=font(18), fill=hex2rgb("446644"))

    img.save(os.path.join(OUT_DIR, "screenshot_01_base.png"))
    print("Saved screenshot_01_base.png  (1080x1920)")


# ─────────────────────────────────────────────────────────────────────
# SCREENSHOT 2 — Mission In Progress
# ─────────────────────────────────────────────────────────────────────
def draw_screen2():
    img = Image.new("RGB", (W, H), hex2rgb("0F1A0F"))
    d = ImageDraw.Draw(img)

    # ── Map path ──────────────────────────────────────────────────────
    path_x = W // 2
    d.line([(path_x, 1700), (path_x, 140)], fill=hex2rgb("1E2A1E"), width=120)

    # Rooms along path
    rooms = [
        (230, 1450, 620, 200, "222A22", "入口大廳",  False),
        (230, 1150, 620, 200, "1E2230", "走廊 A",    False),
        (230,  840, 620, 210, "282030", "伏擊房間",  True),
        (230,  540, 620, 200, "28201E", "指揮室",    False),
        (230,  200, 620, 240, "3A1010", "BOSS 房",   False),
    ]
    for rx, ry, rw, rh, col, label, is_current in rooms:
        border_col = "E8600A" if is_current else "2A3A2A"
        bw = 3 if is_current else 1
        rrect(d, [rx, ry, rx + rw, ry + rh], radius=8,
              fill=hex2rgb(col), outline=hex2rgb(border_col), width=bw)
        d.text((rx + 18, ry + 14), label, font=font(26), fill=hex2rgb("CCCCCC"))
        if is_current:
            d.text((rx + 18, ry + 56), ">> 進行中", font=font(22), fill=hex2rgb("E8600A"))

    # Enemy blips in ambush room
    for ex, ey in [(460, 925), (560, 955), (660, 910)]:
        d.ellipse([ex - 22, ey - 22, ex + 22, ey + 22], fill=hex2rgb("8B0000"))
        d.ellipse([ex - 22, ey - 22, ex + 22, ey + 22], outline=hex2rgb("FF2222"), width=2)
        d.text((ex - 8, ey - 10), "敵", font=font(20), fill=hex2rgb("FF6666"))

    # Squad characters in corridor A (moving up)
    squad_members = [
        (380, 1290, "2255BB", "盾"),
        (440, 1310, "22BB88", "醫"),
        (500, 1290, "E8600A", "突"),
        (560, 1300, "7755AA", "狙"),
    ]
    for cx, cy, col, abbr in squad_members:
        d.ellipse([cx - 28, cy - 28, cx + 28, cy + 28],
                  fill=hex2rgb(col), outline=(255, 255, 255), width=2)
        d.text((cx - 10, cy - 14), abbr, font=font(24), fill=(10, 10, 10))

    # Movement arrows
    for tx in [380, 440, 500, 560]:
        for oy in [0, 30, 60]:
            d.line([(tx, 1240 - oy), (tx, 1240 - oy - 20)], fill=hex2rgb("FFEE00"), width=3)

    # ── Top HUD strip ─────────────────────────────────────────────────
    img = blend_rect(img, [0, 0, W, 130], (0, 0, 0), 0.82)
    d = ImageDraw.Draw(img)
    d.line([(0, 130), (W, 130)], fill=hex2rgb("333333"), width=1)
    d.text((30, 16), "辦公大樓清查", font=font(30), fill=(255, 255, 255))
    # Progress bar
    d.rectangle([30, 70, 1050, 96], fill=hex2rgb("2A2A2A"), outline=hex2rgb("3A3A3A"))
    d.rectangle([30, 70, 490, 96], fill=hex2rgb("44CC44"))  # 45% progress
    d.text((30, 104), "進度 45%", font=font(20), fill=hex2rgb("AAAAAA"))
    d.text((900, 104), "房間 2/5", font=font(20), fill=hex2rgb("AAAAAA"))

    # ── Bottom HUD ────────────────────────────────────────────────────
    hud_h = 260
    hud_y = H - hud_h
    img = blend_rect(img, [0, hud_y, W, H], (0, 0, 0), 0.88)
    d = ImageDraw.Draw(img)
    d.line([(0, hud_y), (W, hud_y)], fill=hex2rgb("444444"), width=2)

    # 4 character cards
    card_w, card_h = 248, 230
    char_cards = [
        ("2255BB", "盾兵",  True,  True),
        ("22BB88", "醫療兵", True,  False),
        ("E8600A", "突擊手", True,  True),
        ("7755AA", "狙擊手", False, False),
    ]
    for i, (col, name, ult_ready, low_hp) in enumerate(char_cards):
        cx = 12 + i * (card_w + 12)
        cy = hud_y + 16
        border = hex2rgb("E8600A") if ult_ready else hex2rgb("3A4A3A")
        rrect(d, [cx, cy, cx + card_w, cy + card_h], radius=8,
              fill=hex2rgb("1A2B1A"), outline=border, width=3)
        # Class colour circle
        d.ellipse([cx + 10, cy + 10, cx + 56, cy + 56], fill=hex2rgb(col))
        d.text((cx + 66, cy + 18), name, font=font(22), fill=hex2rgb("F0F0F0"))
        # HP bar
        hp = 0.30 if low_hp else 0.72
        hp_col = "CC2222" if low_hp else "44CC44"
        d.rectangle([cx + 10, cy + 70, cx + card_w - 10, cy + 88],
                    fill=hex2rgb("3A3A3A"))
        d.rectangle([cx + 10, cy + 70, cx + 10 + int((card_w - 20) * hp), cy + 88],
                    fill=hex2rgb(hp_col))
        hp_label = f"{int(hp * 100)}%"
        d.text((cx + card_w - 46, cy + 56), hp_label, font=font(20),
               fill=hex2rgb("F0F0F0"))
        # Ult area
        ult_y = cy + card_h - 80
        d.rectangle([cx, ult_y, cx + card_w, cy + card_h], fill=hex2rgb("223322"))
        if ult_ready:
            rrect(d, [cx + 10, ult_y + 10, cx + card_w - 10, ult_y + 60], radius=6,
                  fill=hex2rgb("1A3A1A"), outline=hex2rgb("44CC44"), width=2)
            centered_text(d, ult_y + 22, "大招就緒 !", font(22), hex2rgb("44CC44"),
                          img_width=cx + card_w)
        else:
            d.text((cx + 14, ult_y + 20), "冷卻中…", font=font(20), fill=hex2rgb("666666"))

    img.save(os.path.join(OUT_DIR, "screenshot_02_mission.png"))
    print("Saved screenshot_02_mission.png  (1080x1920)")


# ─────────────────────────────────────────────────────────────────────
# SCREENSHOT 3 — Gacha / Recruitment Center
# ─────────────────────────────────────────────────────────────────────
def draw_screen3():
    img = Image.new("RGB", (W, H), hex2rgb("0A0A12"))
    d = ImageDraw.Draw(img)

    # Starfield background
    rng = random.Random(7)
    for _ in range(200):
        sx = rng.randint(0, W)
        sy = rng.randint(0, H)
        sr = rng.randint(1, 3)
        sa = rng.randint(40, 160)
        col_choice = rng.choice(["FFFFFF", "AADDFF", "FFDDAA"])
        r, g, b = hex2rgb(col_choice)
        overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        od.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=(r, g, b, sa))
        img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    d = ImageDraw.Draw(img)

    # Header
    d.rectangle([0, 0, W, 120], fill=hex2rgb("06080F"))
    d.line([(0, 120), (W, 120)], fill=hex2rgb("5533CC"), width=3)
    centered_text(d, 16, "GHOST SQUAD: TACTICAL COMMAND", font(28), hex2rgb("7755AA"))
    centered_text(d, 72, "特戰招募中心  |  Tactical Recruitment", font(26), hex2rgb("AAAADD"))

    # Section title
    d.text((30, 148), "可招募隊員", font=font(30), fill=hex2rgb("CCBBFF"))
    d.line([(30, 192), (1050, 192)], fill=hex2rgb("3A2A5A"), width=2)

    # 6 character cards in 2x3 grid
    recruit_classes = [
        ("盾兵",    "2255BB", "Tank",       "★★★★★", True),
        ("醫療兵",  "22BB88", "Medic",      "★★★★☆", True),
        ("突擊手",  "E8600A", "Assault",    "★★★★★", True),
        ("狙擊手",  "7755AA", "Sniper",     "★★★★☆", False),
        ("爆破手",  "DDAA00", "Demolitions","★★★☆☆", False),
        ("偵察手",  "33CC55", "Recon",      "★★★★☆", False),
    ]
    card_w, card_h = 320, 420
    card_gap_x = 30
    card_gap_y = 28
    start_x = (W - 2 * card_w - card_gap_x) // 2
    start_y = 210

    for i, (name, col, eng, stars, owned) in enumerate(recruit_classes):
        row = i // 3
        col_idx = i % 3
        cx = 30 + col_idx * (card_w + 14)
        cy = start_y + row * (card_h + card_gap_y)

        # Card background
        bg_col = "0E1522" if not owned else "0E160E"
        border_col = col if owned else "3A3A5A"
        rrect(d, [cx, cy, cx + card_w, cy + card_h], radius=12,
              fill=hex2rgb(bg_col), outline=hex2rgb(border_col), width=3 if owned else 1)

        # Large class colour block (art placeholder)
        art_h = 220
        rrect(d, [cx + 8, cy + 8, cx + card_w - 8, cy + 8 + art_h], radius=8,
              fill=hex2rgb(col + "33") if not owned else hex2rgb(col + "22"),
              outline=hex2rgb(col), width=2)

        # Big centre circle (character silhouette placeholder)
        cr = 70
        ccx = cx + card_w // 2
        ccy = cy + 8 + art_h // 2
        d.ellipse([ccx - cr, ccy - cr, ccx + cr, ccy + cr],
                  fill=hex2rgb(col), outline=(255, 255, 255), width=2)
        d.text((ccx - 18, ccy - 22), name[0], font=font(56), fill=(10, 10, 10))

        # Owned badge
        if owned:
            rrect(d, [cx + card_w - 80, cy + 12, cx + card_w - 10, cy + 46], radius=6,
                  fill=hex2rgb("1A4A1A"), outline=hex2rgb("44CC44"), width=1)
            d.text((cx + card_w - 74, cy + 16), "已擁有", font=font(18), fill=hex2rgb("66FF66"))

        # Card info section
        info_y = cy + 8 + art_h + 14
        d.text((cx + 14, info_y), name, font=font(28), fill=hex2rgb(col))
        d.text((cx + 14, info_y + 38), eng, font=font(20), fill=hex2rgb("888888"))
        d.text((cx + 14, info_y + 68), stars, font=font(22), fill=hex2rgb("FFD700"))

        # Level indicator
        level_txt = "Lv.5  |  最高 Lv.9" if owned else "Lv.1  |  未招募"
        level_col = "AAFFAA" if owned else "666666"
        d.text((cx + 14, info_y + 98), level_txt, font=font(18), fill=hex2rgb(level_col))

        # Recruit button
        btn_y = cy + card_h - 56
        if owned:
            rrect(d, [cx + 10, btn_y, cx + card_w - 10, btn_y + 44], radius=8,
                  fill=hex2rgb("223322"), outline=hex2rgb("44CC44"), width=2)
            centered_text(d, btn_y + 10, "升級  ▲", font(22), hex2rgb("66FF66"))
        else:
            rrect(d, [cx + 10, btn_y, cx + card_w - 10, btn_y + 44], radius=8,
                  fill=hex2rgb("1A1A3A"), outline=hex2rgb("5533CC"), width=2)
            centered_text(d, btn_y + 10, "招募  ▶", font(22), hex2rgb("AAAAFF"))

    # ── Bottom resource bar ───────────────────────────────────────────
    res_y = H - 160
    img_rgba = img.convert("RGBA")
    bar_overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    bd = ImageDraw.Draw(bar_overlay)
    bd.rectangle([0, res_y, W, H], fill=(5, 5, 12, 230))
    img_rgba.alpha_composite(bar_overlay)
    img = img_rgba.convert("RGB")
    d = ImageDraw.Draw(img)
    d.line([(0, res_y), (W, res_y)], fill=hex2rgb("3A2A5A"), width=2)

    d.text((30, res_y + 24), "資源", font=font(24), fill=hex2rgb("AAAAAA"))
    d.text((30, res_y + 70), "金幣：500", font=font(32), fill=hex2rgb("FFD700"))
    d.text((380, res_y + 70), "招募券：3", font=font(32), fill=hex2rgb("AAAAFF"))
    d.text((730, res_y + 70), "寶石：120", font=font(32), fill=hex2rgb("CC66FF"))

    # Big recruit button
    rrect(d, [700, res_y + 14, 1050, res_y + 130], radius=12,
          fill=hex2rgb("221144"), outline=hex2rgb("7755AA"), width=3)
    centered_text(d, res_y + 54, "立即招募", font(36), hex2rgb("CCBBFF"))

    img.save(os.path.join(OUT_DIR, "screenshot_03_gacha.png"))
    print("Saved screenshot_03_gacha.png  (1080x1920)")


# ── Main ──────────────────────────────────────────────────────────────
if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    draw_screen1()
    draw_screen2()
    draw_screen3()

    print("\nVerification:")
    for fname in ["screenshot_01_base.png", "screenshot_02_mission.png", "screenshot_03_gacha.png"]:
        fp = os.path.join(OUT_DIR, fname)
        if os.path.exists(fp):
            with Image.open(fp) as chk:
                sz_kb = os.path.getsize(fp) // 1024
                print(f"  OK  {fname}  {chk.size[0]}x{chk.size[1]}  {sz_kb} KB")
        else:
            print(f"  MISSING  {fname}")
