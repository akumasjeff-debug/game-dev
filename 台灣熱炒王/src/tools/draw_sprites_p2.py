"""
draw_sprites_p2.py — 台灣熱炒王 P2 像素素材生成腳本
新增：Walk 動畫 frame 2-4（老闆娘、廚師、上班族）、外場小弟（4 件）、廚師炒菜動作（6 幀）
執行方式：python src/tools/draw_sprites_p2.py
"""

from PIL import Image
import os

# ── 色盤 ────────────────────────────────────────────────────────────────────
C = {
    "outline":      (0x1A, 0x1A, 0x2E, 255),
    "skin":         (0xFF, 0xDB, 0xB5, 255),
    "skin_dark":    (0xC6, 0x86, 0x42, 255),
    "hair_dk":      (0x2C, 0x1A, 0x0E, 255),
    "hair_br":      (0x8B, 0x69, 0x14, 255),
    "red":          (0xFF, 0x2D, 0x55, 255),
    "white":        (0xF5, 0xF5, 0xF5, 255),
    "chef_edge":    (0xCC, 0xCC, 0xCC, 255),
    "apron_blue":   (0x4A, 0x90, 0xE2, 255),
    "pants":        (0x33, 0x33, 0x33, 255),
    "skirt":        (0x1A, 0x1A, 0x2E, 255),
    "suit_blue":    (0x4A, 0x90, 0xE2, 255),
    "dark_pants":   (0x2A, 0x2A, 0x2A, 255),
    "spatula":      (0x55, 0x55, 0x55, 255),
    "lips":         (0xFF, 0x6B, 0x9D, 255),
    "wok_body":     (0x2A, 0x2A, 0x2A, 255),
    "plate_white":  (0xF5, 0xF5, 0xF5, 255),
    "plate_edge":   (0xCC, 0xCC, 0xCC, 255),
    "food_orange":  (0xFF, 0x8C, 0x42, 255),
    "transp":       (0, 0, 0, 0),
}

BASE = r"D:\開發遊戲\台灣熱炒王\src\assets\sprites"
DIRS = {
    "characters": os.path.join(BASE, "characters"),
}

results = []


def px(img, x, y, color):
    """安全設置像素（超出邊界自動忽略）"""
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)


def fill_rect(img, x1, y1, x2, y2, color):
    """填滿矩形區域（含邊界）"""
    for y in range(y1, y2 + 1):
        for x in range(x1, x2 + 1):
            px(img, x, y, color)


def save(img, directory, filename):
    path = os.path.join(DIRS[directory], filename)
    img.save(path)
    results.append(("OK", path))
    print(f"  [OK] {filename}")


# ────────────────────────────────────────────────────────────────────────────
# 工具函式：繪製老闆娘的共用上半身（依 y_offset 整體上移）
# ────────────────────────────────────────────────────────────────────────────
def draw_boss_upper(img, y_offset=0):
    """繪製老闆娘頭部+上身，y_offset < 0 表示整體上移（彈跳感）"""
    o = y_offset

    # 頭髮 y=4-5, x=4-11
    fill_rect(img, 4, 4 + o, 11, 5 + o, C["hair_dk"])

    # 瀏海 y=6
    for x in range(4, 12):
        px(img, x, 6 + o, C["hair_dk"])
    for x in range(6, 10):
        px(img, x, 6 + o, C["skin"])

    # 臉 y=7-10, x=5-10
    fill_rect(img, 5, 7 + o, 10, 10 + o, C["skin"])

    # 臉輪廓
    for y in range(7 + o, 11 + o):
        px(img, 5, y, C["skin_dark"])
        px(img, 10, y, C["skin_dark"])

    # 眼睛
    px(img, 6, 8 + o, C["outline"])
    px(img, 9, 8 + o, C["outline"])

    # 嘴
    px(img, 7, 10 + o, C["lips"])
    px(img, 8, 10 + o, C["lips"])

    # 上衣 y=11-15, x=5-10
    fill_rect(img, 5, 11 + o, 10, 15 + o, C["red"])

    # 上衣邊
    for y in range(11 + o, 16 + o):
        px(img, 4, y, C["outline"])
        px(img, 11, y, C["outline"])

    # 裙 y=16-19
    fill_rect(img, 5, 16 + o, 10, 19 + o, C["skirt"])


def draw_chef_upper(img, y_offset=0):
    """繪製廚師頭部+上身（不含腳），y_offset < 0 整體上移"""
    o = y_offset

    # 廚師帽帽頂 y=2-3
    fill_rect(img, 4, 2 + o, 11, 3 + o, C["white"])

    # 帽沿 y=4-5
    fill_rect(img, 4, 4 + o, 11, 5 + o, C["white"])

    # 臉 y=6-11
    fill_rect(img, 5, 6 + o, 10, 11 + o, C["skin"])

    # 眼睛
    px(img, 6, 8 + o, C["outline"])
    px(img, 9, 8 + o, C["outline"])

    # 鬍渣
    px(img, 6, 10 + o, C["hair_dk"])
    px(img, 8, 10 + o, C["hair_dk"])

    # 廚師服身體 y=12-17
    fill_rect(img, 4, 12 + o, 11, 17 + o, C["white"])

    # 廚師服邊緣
    for y in range(12 + o, 18 + o):
        px(img, 4, y, C["chef_edge"])
        px(img, 11, y, C["chef_edge"])

    # 圍裙
    fill_rect(img, 6, 14 + o, 9, 17 + o, C["apron_blue"])


def draw_customer_a_upper(img, y_offset=0):
    """繪製上班族頭部+上身，y_offset < 0 整體上移"""
    o = y_offset

    # 短髮
    fill_rect(img, 5, 4 + o, 10, 6 + o, C["hair_dk"])

    # 臉
    fill_rect(img, 5, 7 + o, 10, 10 + o, C["skin"])

    # 眼睛
    px(img, 6, 8 + o, C["outline"])
    px(img, 9, 8 + o, C["outline"])

    # 上衣
    fill_rect(img, 5, 11 + o, 10, 15 + o, C["suit_blue"])

    # 紅領帶
    fill_rect(img, 7, 12 + o, 8, 15 + o, C["red"])

    # 褲子
    fill_rect(img, 5, 16 + o, 10, 20 + o, C["dark_pants"])


# ── Walk 動畫：老闆娘 frame 2（雙腳並攏上移 1px）────────────────────────────
def draw_char_boss_walk_f2():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_boss_upper(img, y_offset=-1)
    # 裙已在 upper 中繪製（y=15-18 因 -1），腳部並攏置中
    fill_rect(img, 6, 19, 9, 21, C["skin"])
    fill_rect(img, 6, 22, 9, 22, C["hair_dk"])
    save(img, "characters", "char_boss_walk_f2.png")


# ── Walk 動畫：老闆娘 frame 3（左腳前伸）────────────────────────────────────
def draw_char_boss_walk_f3():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_boss_upper(img, y_offset=0)
    # 右腳正常 y=20-22
    fill_rect(img, 9, 20, 10, 22, C["skin"])
    fill_rect(img, 9, 23, 10, 23, C["hair_dk"])
    # 左腳前伸：x=5-6 下移 1px（y=21-23）
    fill_rect(img, 5, 21, 6, 23, C["skin"])
    save(img, "characters", "char_boss_walk_f3.png")


# ── Walk 動畫：老闆娘 frame 4（同 f2）───────────────────────────────────────
def draw_char_boss_walk_f4():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_boss_upper(img, y_offset=-1)
    fill_rect(img, 6, 19, 9, 21, C["skin"])
    fill_rect(img, 6, 22, 9, 22, C["hair_dk"])
    save(img, "characters", "char_boss_walk_f4.png")


# ── Walk 動畫：廚師 frame 2（雙腳並攏上移 1px）─────────────────────────────
def draw_char_chef_walk_f2():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_chef_upper(img, y_offset=-1)
    # 鍋鏟柄（隨身體上移）
    for y in range(12, 17):
        px(img, 11, y - 1, C["spatula"])
    # 褲子並攏（y=17-20 因上移 -1）
    fill_rect(img, 5, 17, 10, 20, C["pants"])
    # 腳部並攏置中 y=19-21
    fill_rect(img, 6, 19, 9, 21, C["pants"])
    fill_rect(img, 6, 22, 9, 22, C["outline"])
    save(img, "characters", "char_chef_walk_f2.png")


# ── Walk 動畫：廚師 frame 3（右腳前伸）──────────────────────────────────────
def draw_char_chef_walk_f3():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_chef_upper(img, y_offset=0)
    # 鍋鏟柄保持 x=11
    for y in range(13, 18):
        px(img, 11, y, C["spatula"])
    # 褲子
    fill_rect(img, 5, 18, 10, 21, C["pants"])
    # 左腳正常 y=20-22
    fill_rect(img, 5, 20, 6, 22, C["pants"])
    fill_rect(img, 5, 23, 6, 23, C["outline"])
    # 右腳前伸 x=9-10 下移 1px（y=21-23）
    fill_rect(img, 9, 21, 10, 23, C["pants"])
    fill_rect(img, 9, 23, 10, 23, C["outline"])
    save(img, "characters", "char_chef_walk_f3.png")


# ── Walk 動畫：廚師 frame 4（同 f2）─────────────────────────────────────────
def draw_char_chef_walk_f4():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_chef_upper(img, y_offset=-1)
    for y in range(12, 17):
        px(img, 11, y - 1, C["spatula"])
    fill_rect(img, 5, 17, 10, 20, C["pants"])
    fill_rect(img, 6, 19, 9, 21, C["pants"])
    fill_rect(img, 6, 22, 9, 22, C["outline"])
    save(img, "characters", "char_chef_walk_f4.png")


# ── Walk 動畫：上班族 frame 2（雙腳並攏上移 1px）────────────────────────────
def draw_char_customer_a_walk_f2():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_customer_a_upper(img, y_offset=-1)
    # 腳部並攏置中
    fill_rect(img, 6, 19, 9, 21, C["dark_pants"])
    fill_rect(img, 6, 22, 9, 22, C["outline"])
    save(img, "characters", "char_customer_a_walk_f2.png")


# ── Walk 動畫：上班族 frame 3（右腳前伸）────────────────────────────────────
def draw_char_customer_a_walk_f3():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_customer_a_upper(img, y_offset=0)
    # 左腳正常
    fill_rect(img, 5, 20, 6, 22, C["dark_pants"])
    fill_rect(img, 5, 23, 6, 23, C["outline"])
    # 右腳前伸 x=9-10 下移 1px（y=21-23）
    fill_rect(img, 9, 21, 10, 23, C["dark_pants"])
    fill_rect(img, 9, 23, 10, 23, C["outline"])
    save(img, "characters", "char_customer_a_walk_f3.png")


# ── Walk 動畫：上班族 frame 4（同 f2）───────────────────────────────────────
def draw_char_customer_a_walk_f4():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_customer_a_upper(img, y_offset=-1)
    fill_rect(img, 6, 19, 9, 21, C["dark_pants"])
    fill_rect(img, 6, 22, 9, 22, C["outline"])
    save(img, "characters", "char_customer_a_walk_f4.png")


# ── 工具函式：繪製外場小弟共用上身 ─────────────────────────────────────────
def draw_waiter_body(img):
    """繪製外場小弟頭部、上衣、褲子（不含腳）"""
    # 頭髮（短黑髮微翹）y=4-5, x=4-11
    fill_rect(img, 4, 4, 11, 5, C["hair_dk"])
    # 微翹：y=3 x=5, x=10
    px(img, 5, 3, C["hair_dk"])
    px(img, 10, 3, C["hair_dk"])

    # 臉 y=6-10, x=5-10
    fill_rect(img, 5, 6, 10, 10, C["skin"])

    # 眼睛 y=8
    px(img, 6, 8, C["outline"])
    px(img, 9, 8, C["outline"])

    # 上衣（藍色 polo）y=11-15, x=5-10
    fill_rect(img, 5, 11, 10, 15, C["suit_blue"])

    # 白領 y=11, x=7-8
    fill_rect(img, 7, 11, 8, 11, C["white"])

    # 褲子 y=16-20, x=5-10
    fill_rect(img, 5, 16, 10, 20, C["pants"])


# ── 外場小弟 idle（16x24）───────────────────────────────────────────────────
def draw_char_waiter_idle():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_waiter_body(img)
    # 鞋 y=21-23：左 x=5-6，右 x=9-10
    fill_rect(img, 5, 21, 6, 23, C["outline"])
    fill_rect(img, 9, 21, 10, 23, C["outline"])
    save(img, "characters", "char_waiter_idle.png")


# ── 外場小弟 walk frame 1（16x24）───────────────────────────────────────────
def draw_char_waiter_walk_f1():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_waiter_body(img)
    # 右腳前伸：x=9-10 y=21-23
    fill_rect(img, 9, 21, 10, 23, C["outline"])
    # 左腳正常：x=5-6 y=21-23
    fill_rect(img, 5, 21, 6, 23, C["outline"])
    # 左手前擺：x=4 y=13（1px 藍衣）
    px(img, 4, 13, C["suit_blue"])
    save(img, "characters", "char_waiter_walk_f1.png")


# ── 外場小弟 carry frame 1（16x24）──────────────────────────────────────────
def draw_char_waiter_carry_f1():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_waiter_body(img)
    # 鞋（站立）
    fill_rect(img, 5, 21, 6, 23, C["outline"])
    fill_rect(img, 9, 21, 10, 23, C["outline"])

    # 右手高舉持盤：手臂 x=10-11 y=6-8
    fill_rect(img, 10, 6, 11, 8, C["suit_blue"])

    # 餐盤底 y=5-6 x=9-13（白）
    fill_rect(img, 9, 5, 13, 6, C["plate_white"])
    # 餐盤邊框（上方單行）
    for x in range(9, 14):
        px(img, x, 4, C["plate_edge"])
    for x in range(9, 14):
        px(img, x, 6, C["plate_edge"])
    px(img, 9, 5, C["plate_edge"])
    px(img, 13, 5, C["plate_edge"])

    # 盤上食物（橘色菜餚暗示）y=5 x=10-12
    for x in range(10, 13):
        px(img, x, 5, C["food_orange"])

    save(img, "characters", "char_waiter_carry_f1.png")


# ── 外場小弟 carry frame 3（16x24，另一腳前伸）──────────────────────────────
def draw_char_waiter_carry_f3():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_waiter_body(img)

    # 左腳前伸：x=5-6 y=21-23
    fill_rect(img, 5, 21, 6, 23, C["outline"])
    # 右腳正常：x=9-10 y=21-23
    fill_rect(img, 9, 21, 10, 23, C["outline"])

    # 右手高舉持盤（同 carry_f1）
    fill_rect(img, 10, 6, 11, 8, C["suit_blue"])

    # 餐盤
    fill_rect(img, 9, 5, 13, 6, C["plate_white"])
    for x in range(9, 14):
        px(img, x, 4, C["plate_edge"])
    for x in range(9, 14):
        px(img, x, 6, C["plate_edge"])
    px(img, 9, 5, C["plate_edge"])
    px(img, 13, 5, C["plate_edge"])

    # 食物
    for x in range(10, 13):
        px(img, x, 5, C["food_orange"])

    save(img, "characters", "char_waiter_carry_f3.png")


# ────────────────────────────────────────────────────────────────────────────
# 工具函式：廚師炒菜共用背面身體
# ────────────────────────────────────────────────────────────────────────────
def draw_chef_cook_body(img):
    """廚師背面：帽子、頭髮背面、上衣背面、褲子（不含鍋/手）"""
    # 帽子帽頂 y=2-3
    fill_rect(img, 4, 2, 11, 3, C["white"])
    # 帽沿 y=4-5
    fill_rect(img, 4, 4, 11, 5, C["white"])

    # 頭髮背面 y=6-7, x=5-10（看不到臉）
    fill_rect(img, 5, 6, 10, 7, C["hair_dk"])

    # 上衣背面 y=11-15, x=5-10
    fill_rect(img, 5, 11, 10, 15, C["white"])
    # 邊緣灰
    for y in range(11, 16):
        px(img, 4, y, C["chef_edge"])
        px(img, 11, y, C["chef_edge"])

    # 圍裙背面（隱約可見）y=14-17 x=6-9
    fill_rect(img, 6, 14, 9, 17, C["apron_blue"])

    # 褲子 y=18-23, x=5-10
    fill_rect(img, 5, 18, 10, 23, C["pants"])
    # 鞋 y=22-23
    fill_rect(img, 5, 22, 6, 23, C["outline"])
    fill_rect(img, 9, 22, 10, 23, C["outline"])


def draw_wok(img, wx1, wy1, wx2, wy2):
    """在指定位置繪製簡化版鍋（矩形輪廓 + 填色）"""
    fill_rect(img, wx1, wy1, wx2, wy2, C["wok_body"])
    # 上沿高光（1px）
    for x in range(wx1, wx2 + 1):
        px(img, x, wy1, (0x55, 0x55, 0x55, 255))
    # 輪廓
    for x in range(wx1, wx2 + 1):
        px(img, x, wy1 - 1 if wy1 > 0 else wy1, C["outline"])
        px(img, x, wy2 + 1 if wy2 < 23 else wy2, C["outline"])
    for y in range(wy1, wy2 + 1):
        px(img, wx1 - 1 if wx1 > 0 else wx1, y, C["outline"])
        px(img, wx2 + 1 if wx2 < 15 else wx2, y, C["outline"])


# ── 廚師炒菜 f1（基準位，雙手握鍋）─────────────────────────────────────────
def draw_char_chef_cook_f1():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_chef_cook_body(img)

    # 鍋 y=8-11, x=5-10
    draw_wok(img, 5, 8, 10, 11)

    # 雙臂前伸（面朝上方）：左臂 x=4-5 y=12-13，右臂 x=10-11 y=12-13
    fill_rect(img, 4, 12, 5, 13, C["skin"])
    fill_rect(img, 10, 12, 11, 13, C["skin"])

    save(img, "characters", "char_chef_cook_f1.png")


# ── 廚師炒菜 f2（鍋往右傾，x 右移 2px）─────────────────────────────────────
def draw_char_chef_cook_f2():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_chef_cook_body(img)

    # 鍋右移 2px：x=7-12, y=8-11
    draw_wok(img, 7, 8, 12, 11)

    # 雙臂微調（跟著鍋右移）
    fill_rect(img, 5, 12, 6, 13, C["skin"])
    fill_rect(img, 11, 12, 12, 13, C["skin"])

    save(img, "characters", "char_chef_cook_f2.png")


# ── 廚師炒菜 f3（鍋舉起，食材粒子）────────────────────────────────────────
def draw_char_chef_cook_f3():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_chef_cook_body(img)

    # 鍋上移 3px：y=5-8, x=5-10
    draw_wok(img, 5, 5, 10, 8)

    # 食材粒子 y=3-4 x=7-9（橘色）
    for x in range(7, 10):
        px(img, x, 3, C["food_orange"])
        px(img, x, 4, C["food_orange"])

    # 手臂高舉：x=4-5 y=9-10，x=10-11 y=9-10
    fill_rect(img, 4, 9, 5, 10, C["skin"])
    fill_rect(img, 10, 9, 11, 10, C["skin"])

    save(img, "characters", "char_chef_cook_f3.png")


# ── 廚師炒菜 f4（鍋傾左，x 左移 2px）──────────────────────────────────────
def draw_char_chef_cook_f4():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_chef_cook_body(img)

    # 鍋左移 2px：x=3-8, y=8-11
    draw_wok(img, 3, 8, 8, 11)

    # 雙臂微調（跟著鍋左移）
    fill_rect(img, 3, 12, 4, 13, C["skin"])
    fill_rect(img, 9, 12, 10, 13, C["skin"])

    save(img, "characters", "char_chef_cook_f4.png")


# ── 廚師炒菜 f5（回正中，鍋略低 1px）───────────────────────────────────────
def draw_char_chef_cook_f5():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_chef_cook_body(img)

    # 鍋比基準低 1px：y=9-12, x=5-10
    draw_wok(img, 5, 9, 10, 12)

    # 手臂略低
    fill_rect(img, 4, 13, 5, 14, C["skin"])
    fill_rect(img, 10, 13, 11, 14, C["skin"])

    save(img, "characters", "char_chef_cook_f5.png")


# ── 廚師炒菜 f6（同 f1，循環收尾）──────────────────────────────────────────
def draw_char_chef_cook_f6():
    img = Image.new("RGBA", (16, 24), C["transp"])
    draw_chef_cook_body(img)

    # 同 f1：鍋 y=8-11 x=5-10
    draw_wok(img, 5, 8, 10, 11)

    # 雙手
    fill_rect(img, 4, 12, 5, 13, C["skin"])
    fill_rect(img, 10, 12, 11, 13, C["skin"])

    save(img, "characters", "char_chef_cook_f6.png")


# ── 主程式 ───────────────────────────────────────────────────────────────────
def main():
    print("台灣熱炒王 P2 像素素材生成（18 件）...\n")

    for d in DIRS.values():
        os.makedirs(d, exist_ok=True)

    tasks = [
        # Walk 動畫補幀：老闆娘 f2-f4
        ("char_boss_walk_f2.png",          draw_char_boss_walk_f2),
        ("char_boss_walk_f3.png",          draw_char_boss_walk_f3),
        ("char_boss_walk_f4.png",          draw_char_boss_walk_f4),
        # Walk 動畫補幀：廚師 f2-f4
        ("char_chef_walk_f2.png",          draw_char_chef_walk_f2),
        ("char_chef_walk_f3.png",          draw_char_chef_walk_f3),
        ("char_chef_walk_f4.png",          draw_char_chef_walk_f4),
        # Walk 動畫補幀：上班族 f2-f4
        ("char_customer_a_walk_f2.png",    draw_char_customer_a_walk_f2),
        ("char_customer_a_walk_f3.png",    draw_char_customer_a_walk_f3),
        ("char_customer_a_walk_f4.png",    draw_char_customer_a_walk_f4),
        # 外場小弟 4 件
        ("char_waiter_idle.png",           draw_char_waiter_idle),
        ("char_waiter_walk_f1.png",        draw_char_waiter_walk_f1),
        ("char_waiter_carry_f1.png",       draw_char_waiter_carry_f1),
        ("char_waiter_carry_f3.png",       draw_char_waiter_carry_f3),
        # 廚師炒菜 6 幀
        ("char_chef_cook_f1.png",          draw_char_chef_cook_f1),
        ("char_chef_cook_f2.png",          draw_char_chef_cook_f2),
        ("char_chef_cook_f3.png",          draw_char_chef_cook_f3),
        ("char_chef_cook_f4.png",          draw_char_chef_cook_f4),
        ("char_chef_cook_f5.png",          draw_char_chef_cook_f5),
        ("char_chef_cook_f6.png",          draw_char_chef_cook_f6),
    ]

    errors = []
    for name, fn in tasks:
        try:
            fn()
        except Exception as e:
            results.append(("FAIL", name))
            errors.append((name, str(e)))
            print(f"  [FAIL] {name}: {e}")

    ok_count = len(tasks) - len(errors)
    print(f"\n生成完成：{ok_count}/{len(tasks)} 成功")

    if errors:
        print("\n失敗清單：")
        for name, err in errors:
            print(f"  {name}: {err}")
    else:
        print("所有 P2 素材已成功寫入。")
        print("\n輸出路徑：src\\assets\\sprites\\characters\\")
        print("新增素材清單：")
        for _, path in results:
            print(f"  {os.path.basename(path)}")


if __name__ == "__main__":
    main()
