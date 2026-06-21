"""
幽靈行動 itch.io 發布素材生成器
角色使用與 SVG sprite 一致的像素方塊座標重繪
"""
from PIL import Image, ImageDraw, ImageFont
import os, shutil

BG        = (20, 23, 31)
WHITE     = (232, 232, 232)
ORANGE    = (232, 96, 10)
BLUE      = (68, 136, 255)
SUBTEXT   = (136, 170, 204)
GRID_LINE = (30, 38, 55)
GLOW_BLUE = (30, 60, 120)

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))


def draw_grid(draw, W, H, cell=40):
    for x in range(0, W, cell):
        draw.line([(x, 0), (x, H)], fill=GRID_LINE, width=1)
    for y in range(0, H, cell):
        draw.line([(0, y), (W, y)], fill=GRID_LINE, width=1)


def get_font(size):
    for path in [
        "C:/Windows/Fonts/msjhbd.ttc",
        "C:/Windows/Fonts/msjh.ttc",
        "C:/Windows/Fonts/msgothic.ttc",
    ]:
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            pass
    return ImageFont.load_default()


def draw_char(draw, cx, cy, char_type, size=80):
    """
    按 SVG sprite 64×64 座標重繪像素方塊角色。
    cx, cy = 角色中心；size = 在畫布上的顯示尺寸（px）。
    """
    s  = size / 64.0        # 縮放比例
    ox = cx - size // 2     # 左上角原點 x
    oy = cy - size // 2     # 左上角原點 y

    def r(x, y, w, h, fill):
        x0 = ox + round(x * s)
        y0 = oy + round(y * s)
        x1 = ox + round((x + w) * s) - 1
        y1 = oy + round((y + h) * s) - 1
        if x1 > x0 and y1 > y0:
            draw.rectangle([x0, y0, x1, y1], fill=fill)

    # ── 落地陰影 ──────────────────────────────────────────
    shadow_w = {"shield": 14, "medic": 12, "assault": 16,
                "sniper": 20, "demo": 18, "recon": 14}[char_type]
    ex0 = ox + round((32 - shadow_w) * s)
    ey0 = oy + round(52 * s)
    ex1 = ox + round((32 + shadow_w) * s)
    ey1 = oy + round(60 * s)
    draw.ellipse([ex0, ey0, ex1, ey1], fill=(0, 0, 0, 90) if False else (10, 12, 16))

    # ── 各職業 ────────────────────────────────────────────

    if char_type == "shield":
        # 盾牌（最大識別特徵，藍色大盾在左）
        r(6, 12, 14, 40, (0x11, 0x33, 0xAA))   # 盾本體（深藍邊）
        r(8, 14, 10, 36, (0x22, 0x55, 0xBB))   # 盾主面
        r(10, 18, 6,  28, (0x44, 0x88, 0xCC))  # 盾高光條
        r(14, 28, 2,  8,  (0x88, 0xBB, 0xFF))  # 盾中心裝飾
        # 身體
        r(24, 22, 16, 26, (0x1A, 0x2A, 0x4A))
        r(24, 36, 16, 2,  (0x11, 0x22, 0x44))  # 腰帶
        # 頭盔
        r(24, 12, 16, 12, (0x1A, 0x2A, 0x3A))
        r(24, 14, 16, 6,  (0x22, 0x55, 0xBB))  # 藍色護目鏡
        r(26, 15, 6,  4,  (0x44, 0x88, 0xFF))  # 護目鏡亮點
        # 右肩 SMG
        r(40, 22, 6,  4,  (0x33, 0x44, 0x55))
        r(44, 20, 4,  12, (0x2A, 0x2A, 0x2A))
        # 兩臂
        r(18, 24, 8,  4,  (0x22, 0x33, 0x55))
        r(38, 24, 8,  4,  (0x22, 0x33, 0x55))
        # 腿
        r(24, 50, 6,  6,  (0x12, 0x18, 0x28))
        r(34, 50, 6,  6,  (0x12, 0x18, 0x28))

    elif char_type == "medic":
        # 背包（最大特徵，從頭頂往上突出，十字標）
        r(22, 2,  20, 14, (0x1A, 0x3A, 0x28))  # 背包本體
        r(24, 4,  16, 10, (0x1E, 0x42, 0x2E))  # 背包正面
        # 白十字
        r(30, 5,  4,  8,  WHITE)
        r(27, 8,  10, 2,  WHITE)
        # 天線
        r(31, 0,  2,  6,  (0x44, 0x88, 0x66))
        # 頭盔
        r(24, 14, 16, 10, (0x18, 0x2A, 0x1E))
        r(26, 16, 12, 4,  (0x22, 0x3A, 0x28))  # 帽帶
        # 身體
        r(24, 22, 16, 26, (0x18, 0x2A, 0x1E))
        r(26, 24, 12, 22, (0x1A, 0x30, 0x22))
        # 左臂紅十字臂章
        r(16, 26, 8,  4,  (0x18, 0x2A, 0x1E))
        r(18, 24, 4,  8,  (0x22, 0x88, 0x55))  # 臂章底
        r(19, 25, 2,  6,  WHITE)
        r(18, 27, 4,  2,  WHITE)
        # 右手 pistol
        r(40, 28, 8,  4,  (0x1A, 0x1A, 0x1A))
        r(42, 32, 4,  6,  (0x22, 0x22, 0x22))
        # 腿
        r(24, 50, 6,  6,  (0x0E, 0x18, 0x12))
        r(34, 50, 6,  6,  (0x0E, 0x18, 0x12))

    elif char_type == "assault":
        # 突擊步槍（最大特徵，槍管貫穿上方，橙色前托）
        r(29, 0,  6,  20, (0x2A, 0x2A, 0x2A))  # 長槍管
        r(28, 14, 8,  6,  (0xE8, 0x60, 0x0A))  # 橙色前托
        r(26, 18, 12, 10, (0x33, 0x33, 0x33))  # 槍身
        r(29, 26, 6,  8,  (0x22, 0x22, 0x22))  # 彈匣
        # 身體（戰術背心，多口袋）
        r(20, 26, 24, 24, (0x1E, 0x2A, 0x18))
        r(21, 27, 6,  5,  (0x16, 0x20, 0x12))  # 彈匣袋×4
        r(37, 27, 6,  5,  (0x16, 0x20, 0x12))
        r(21, 34, 6,  5,  (0x16, 0x20, 0x12))
        r(37, 34, 6,  5,  (0x16, 0x20, 0x12))
        # 雙手握槍
        r(20, 16, 8,  6,  (0x1C, 0x28, 0x10))
        r(36, 16, 8,  6,  (0x1C, 0x28, 0x10))
        # 雙臂
        r(16, 22, 10, 4,  (0x1A, 0x20, 0x10))
        r(38, 22, 10, 4,  (0x1A, 0x20, 0x10))
        # 頭盔
        r(23, 22, 18, 6,  (0x22, 0x2A, 0x18))
        r(24, 22, 16, 3,  (0xE8, 0x60, 0x0A))  # 橙色護目鏡條
        # 腿
        r(22, 50, 8,  6,  (0x0E, 0x14, 0x08))
        r(34, 50, 8,  6,  (0x0E, 0x14, 0x08))

    elif char_type == "sniper":
        # 鬼影斗篷（最大特徵，超寬）+ 超長槍管
        r(8,  18, 48, 30, (0x1A, 0x28, 0x12))  # 斗篷主體
        # 斗篷草葉紋
        r(8,  20, 4,  4,  (0x24, 0x36, 0x18))
        r(16, 18, 4,  6,  (0x1E, 0x30, 0x14))
        r(24, 16, 4,  6,  (0x24, 0x38, 0x18))
        r(40, 18, 4,  6,  (0x24, 0x36, 0x18))
        r(50, 36, 4,  6,  (0x1A, 0x28, 0x10))
        # 紫色識別緞帶
        r(22, 20, 20, 3,  (0x77, 0x55, 0xAA))
        # 超長槍管（從最上方貫穿）
        r(30, 0,  4,  22, (0x22, 0x22, 0x30))  # 槍管
        r(29, 0,  6,  6,  (0x2A, 0x2A, 0x3A))  # 消音器
        r(28, 10, 8,  5,  (0x33, 0x33, 0x48))  # 瞄準鏡
        r(30, 11, 4,  3,  (0x77, 0x55, 0xAA))  # 瞄準鏡紫色鏡片
        # 雙手
        r(22, 16, 8,  4,  (0x1A, 0x20, 0x10))
        r(34, 20, 8,  4,  (0x1A, 0x20, 0x10))
        # 腿
        r(24, 50, 6,  6,  (0x0E, 0x18, 0x0A))
        r(34, 50, 6,  6,  (0x0E, 0x18, 0x0A))

    elif char_type == "demo":
        # 黃黑警告條紋背包（最大特徵，佔上方）
        r(18, 2,  28, 20, (0x11, 0x11, 0x00))  # 背包底黑
        # 黃色條紋
        r(18, 2,  28, 4,  (0xDD, 0xAA, 0x00))
        r(18, 10, 28, 4,  (0xDD, 0xAA, 0x00))
        r(18, 18, 28, 4,  (0xDD, 0xAA, 0x00))
        # 引線接頭（黃）
        r(22, 0,  4,  6,  (0xDD, 0xAA, 0x00))
        r(38, 0,  4,  6,  (0xDD, 0xAA, 0x00))
        # 肩帶
        r(20, 20, 6,  6,  (0x1A, 0x1A, 0x08))
        r(38, 20, 6,  6,  (0x1A, 0x1A, 0x08))
        # 寬壯身體
        r(18, 24, 28, 24, (0x20, 0x1E, 0x10))
        # 頭盔
        r(20, 16, 24, 10, (0x1A, 0x1A, 0x10))
        # 黃色護目鏡橫跨臉（最醒目）
        r(20, 16, 24, 5,  (0xDD, 0xAA, 0x00))
        r(31, 16, 2,  5,  (0xAA, 0x88, 0x00))  # 護目鏡分隔
        r(21, 17, 9,  3,  (0xFF, 0xCC, 0x33))  # 護目鏡亮面
        r(34, 17, 9,  3,  (0xFF, 0xCC, 0x33))
        # 散彈槍左
        r(4,  28, 16, 6,  (0x2A, 0x2A, 0x2A))
        r(0,  29, 6,  4,  (0x1A, 0x1A, 0x1A))
        # 腿
        r(20, 50, 10, 6,  (0x10, 0x10, 0x0A))
        r(34, 50, 10, 6,  (0x10, 0x10, 0x0A))

    elif char_type == "recon":
        # T形夜視鏡（最大特徵，綠色發光鏡頭向上突出）
        r(18, 8,  28, 6,  (0x1A, 0x2A, 0x1A))   # 橫向夾具
        r(18, 0,  10, 10, (0x1A, 0x1A, 0x1A))   # 右管
        r(36, 0,  10, 10, (0x1A, 0x1A, 0x1A))   # 左管
        r(19, 1,  8,  8,  (0x33, 0xCC, 0x55))   # 右鏡頭（鮮綠）
        r(37, 1,  8,  8,  (0x33, 0xCC, 0x55))   # 左鏡頭（鮮綠）
        r(20, 2,  3,  3,  (0x88, 0xFF, 0x88))   # 高光
        r(38, 2,  3,  3,  (0x88, 0xFF, 0x88))
        r(22, 4,  3,  3,  (0x00, 0x66, 0x00))   # 瞳孔
        r(40, 4,  3,  3,  (0x00, 0x66, 0x00))
        r(28, 2,  8,  6,  (0x22, 0x33, 0x22))   # 中央橋接
        # 頭盔
        r(24, 10, 16, 12, (0x1A, 0x2A, 0x1A))
        r(22, 14, 20, 4,  (0x16, 0x22, 0x16))   # 頭盔邊緣
        # 身體
        r(24, 22, 16, 26, (0x18, 0x22, 0x18))
        r(31, 22, 2,  26, (0x10, 0x18, 0x10))   # 中線
        # 兩臂
        r(18, 24, 8,  4,  (0x16, 0x20, 0x16))
        r(38, 24, 8,  4,  (0x16, 0x20, 0x16))
        # 右肩背包
        r(40, 18, 8,  12, (0x12, 0x1C, 0x12))
        r(42, 23, 3,  3,  (0x33, 0xCC, 0x55))   # 偵察鏡綠光
        # 腰帶煙霧彈
        r(26, 44, 5,  5,  (0x2A, 0x3A, 0x2A))
        r(33, 44, 5,  5,  (0x2A, 0x3A, 0x2A))
        r(28, 43, 2,  2,  (0x33, 0xCC, 0x55))   # 拉環
        r(35, 43, 2,  2,  (0x33, 0xCC, 0x55))
        # 腿
        r(24, 50, 6,  6,  (0x0E, 0x18, 0x0E))
        r(34, 50, 6,  6,  (0x0E, 0x18, 0x0E))


# ── cover.png（630×500）──────────────────────────────────────

def make_cover():
    W, H = 630, 500
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)
    draw_grid(draw, W, H, cell=40)

    # 6個職業（recon 也加進來）
    chars = ['shield', 'medic', 'assault', 'sniper', 'demo', 'recon']
    accent_colors = [
        (0x44, 0x88, 0xFF),  # 盾兵藍
        (0x22, 0xBB, 0x88),  # 醫療兵綠
        (0xE8, 0x60, 0x0A),  # 突擊手橙
        (0x77, 0x55, 0xAA),  # 狙擊手紫
        (0xDD, 0xAA, 0x00),  # 爆破手黃
        (0x33, 0xCC, 0x55),  # 偵察手綠
    ]
    n = len(chars)
    spacing = W // (n + 1)
    char_y = 120
    char_size = 72  # 像素尺寸

    for i, (char, col) in enumerate(zip(chars, accent_colors)):
        cx = spacing * (i + 1)
        # 角色外框光暈（用細矩形框模擬）
        hw = char_size // 2 + 6
        draw.rectangle([cx - hw, char_y - hw, cx + hw, char_y + hw],
                       outline=col, width=1)
        draw_char(draw, cx, char_y, char, size=char_size)

    # 橙色分隔線
    draw.line([(30, 175), (W - 30, 175)], fill=ORANGE, width=2)

    font_title = get_font(82)
    title = "幽靈行動"
    bbox = draw.textbbox((0, 0), title, font=font_title)
    draw.text(((W - (bbox[2]-bbox[0])) // 2, 188), title, font=font_title, fill=WHITE)

    font_en = get_font(28)
    en = "GHOST  MISSION"
    bbox2 = draw.textbbox((0, 0), en, font=font_en)
    draw.text(((W - (bbox2[2]-bbox2[0])) // 2, 282), en, font=font_en, fill=SUBTEXT)

    font_desc = get_font(18)
    desc = "俯視角戰術 Roguelite  ·  手機直屏"
    bbox3 = draw.textbbox((0, 0), desc, font=font_desc)
    draw.text(((W - (bbox3[2]-bbox3[0])) // 2, 325), desc, font=font_desc, fill=SUBTEXT)

    draw.line([(30, 375), (W - 30, 375)], fill=BLUE, width=1)

    font_demo = get_font(22)
    demo_t = "[ DEMO ]"
    bbox_d = draw.textbbox((0, 0), demo_t, font=font_demo)
    dw = bbox_d[2] - bbox_d[0]
    tx, ty = W - dw - 46, 390
    draw.rectangle([tx-8, ty-4, tx+dw+8, ty+30], fill=(50,30,10), outline=ORANGE, width=2)
    draw.text((tx, ty), demo_t, font=font_demo, fill=ORANGE)

    font_tiny = get_font(13)
    draw.text((30, 395), "Tactical  ·  Strategic  ·  Roguelite", font=font_tiny, fill=GRID_LINE)

    out = os.path.join(OUTPUT_DIR, "cover.png")
    img.save(out)
    print(f"cover.png saved ({W}x{H})")
    return out


# ── banner.png（960×540）────────────────────────────────────

def make_banner():
    W, H = 960, 540
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)
    draw_grid(draw, W, H, cell=50)

    # 左側深色覆蓋
    for i in range(W // 2 + 80):
        t = min(1.0, i / 320.0)
        c = tuple(int(BG[k] * (1 - 0.3 * (1-t))) for k in range(3))
        draw.line([(i, 0), (i, H)], fill=c)

    # 左側 3 個角色，垂直排列在 Y 中央，帶光框
    chars3 = [('shield', (0x44,0x88,0xFF)),
              ('medic',  (0x22,0xBB,0x88)),
              ('assault',(0xE8,0x60,0x0A))]
    cs = 90  # char size
    for i, (char, col) in enumerate(chars3):
        cx = 120 + i * 135
        cy = H // 2 + 15
        hw = cs // 2 + 5
        draw.rectangle([cx-hw, cy-hw, cx+hw, cy+hw], outline=col, width=1)
        draw_char(draw, cx, cy, char, size=cs)

    # 垂直橙色分隔
    div_x = 490
    draw.line([(div_x, 50), (div_x, H-50)], fill=ORANGE, width=2)

    # 右側文字
    tx = div_x + 45
    font_big = get_font(96)
    draw.text((tx, 90), "幽靈行動", font=font_big, fill=WHITE)

    font_en = get_font(38)
    draw.text((tx, 210), "GHOST MISSION", font=font_en, fill=SUBTEXT)

    font_tag = get_font(22)
    draw.text((tx, 268), "俯視角戰術 Roguelite  ·  手機直屏", font=font_tag, fill=SUBTEXT)

    font_demo = get_font(28)
    demo_t = "[ DEMO ]"
    bbox_d = draw.textbbox((0, 0), demo_t, font=font_demo)
    dw = bbox_d[2] - bbox_d[0]
    tdy = 325
    draw.rectangle([tx-8, tdy-4, tx+dw+8, tdy+36], fill=(50,30,10), outline=ORANGE, width=2)
    draw.text((tx, tdy), demo_t, font=font_demo, fill=ORANGE)

    draw.line([(tx, H-75), (W-40, H-75)], fill=BLUE, width=1)
    font_sm = get_font(15)
    draw.text((tx, H-60), "Tactical  ·  Strategic  ·  Roguelite", font=font_sm, fill=GRID_LINE)

    out = os.path.join(OUTPUT_DIR, "banner.png")
    img.save(out)
    print(f"banner.png saved ({W}x{H})")
    return out


# ── icon.png（256×256）──────────────────────────────────────

def make_icon():
    W, H = 256, 256
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)

    # 藍色發光底圓（模擬）
    for rr in range(100, 55, -5):
        t = (rr - 55) / 45.0
        gc = (int(20 + 10*t), int(23 + 37*t), int(31 + 89*t))
        ex = W//2 - rr
        ey = H//2 - rr
        draw.ellipse([ex, ey, ex+2*rr, ey+2*rr], fill=gc)

    # 盾兵（scale 放大，置中）
    draw_char(draw, W//2, H//2 + 10, 'shield', size=160)

    # 外框
    draw.rectangle([4, 4, W-5, H-5], outline=(50,60,80), width=2)

    font_gm = get_font(24)
    gm = "GM"
    bbox_gm = draw.textbbox((0, 0), gm, font=font_gm)
    gw = bbox_gm[2] - bbox_gm[0]
    draw.text(((W-gw)//2, H-40), gm, font=font_gm, fill=(68,136,255))

    out = os.path.join(OUTPUT_DIR, "icon.png")
    img.save(out)
    print(f"icon.png saved ({W}x{H})")
    return out


# ── 主程式 ────────────────────────────────────────────────────

if __name__ == "__main__":
    make_cover()
    make_banner()
    make_icon()

    src_icon = os.path.normpath(
        os.path.join(OUTPUT_DIR, "..", "..", "src", "icon.png")
    )
    try:
        shutil.copy2(os.path.join(OUTPUT_DIR, "icon.png"), src_icon)
        print(f"icon.png → {src_icon}")
    except Exception as e:
        print(f"警告：無法複製到 src/: {e}")

    print("\n完成。素材儲存於 press_kit/")
