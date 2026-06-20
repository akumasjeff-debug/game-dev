"""
draw_sprites.py — 台灣熱炒王 P1 像素素材生成腳本
使用 PIL 逐像素繪製所有 P1 素材，覆蓋現有佔位圖。
執行方式：python src/tools/draw_sprites.py
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
    "apron_blue":   (0x4A, 0x90, 0xE2, 255),
    "floor_k1":     (0x8B, 0x45, 0x13, 255),   # 廚房磚底
    "floor_k2":     (0xA0, 0x52, 0x2D, 255),   # 廚房磚亮
    "floor_k_dk":   (0x6B, 0x34, 0x10, 255),   # 廚房磚縫
    "floor_d1":     (0xD2, 0xB4, 0x8C, 255),   # 外場木淺
    "floor_d2":     (0xC1, 0x9A, 0x6B, 255),   # 外場木紋
    "floor_d3":     (0x8B, 0x69, 0x14, 255),   # 外場左邊
    "corridor":     (0x80, 0x80, 0x80, 255),
    "corr_hi":      (0x99, 0x99, 0x99, 255),
    "corr_dk":      (0x77, 0x77, 0x77, 255),
    "road1":        (0x3D, 0x3D, 0x3D, 255),
    "road2":        (0x55, 0x55, 0x55, 255),
    "road3":        (0x2A, 0x2A, 0x2A, 255),
    "brick_dk":     (0x8B, 0x00, 0x00, 255),
    "brick_br":     (0xCC, 0x22, 0x00, 255),
    "wok_body":     (0x2A, 0x2A, 0x2A, 255),
    "wok_mid":      (0x55, 0x55, 0x55, 255),
    "wok_hi":       (0x77, 0x77, 0x77, 255),
    "handle":       (0x8B, 0x45, 0x13, 255),
    "table_wood":   (0xDE, 0xB8, 0x87, 255),
    "table_cloth":  (0xFF, 0xFF, 0xFF, 255),
    "lips":         (0xFF, 0x6B, 0x9D, 255),
    "chef_edge":    (0xCC, 0xCC, 0xCC, 255),
    "pants":        (0x33, 0x33, 0x33, 255),
    "skirt":        (0x1A, 0x1A, 0x2E, 255),
    "rack":         (0x55, 0x55, 0x55, 255),
    "rack_dk":      (0x33, 0x33, 0x33, 255),
    "transp":       (0, 0, 0, 0),
    "suit_blue":    (0x4A, 0x90, 0xE2, 255),
    "dark_pants":   (0x2A, 0x2A, 0x2A, 255),
    "spatula":      (0x55, 0x55, 0x55, 255),
    "fire_base":    (0xFF, 0x45, 0x00, 255),
    "fire_mid":     (0xFF, 0x8C, 0x00, 255),
    "fire_top":     (0xFF, 0xD7, 0x00, 255),
    "wok_hot":      (0x77, 0x77, 0x77, 255),
    "coin_gold":    (0xF5, 0xA6, 0x23, 255),
    "coin_hi":      (0xFF, 0xD7, 0x00, 255),
    "coin_dk":      (0xC6, 0x86, 0x42, 255),
    "hud_bg":       (0x1A, 0x1A, 0x2E, 217),
    "hud_line":     (0xFF, 0x2D, 0x55, 255),
    "btn_bg":       (0x2A, 0x2A, 0x4A, 255),
    "btn_border":   (0x44, 0x44, 0x66, 255),
    "btn_green":    (0x00, 0xD2, 0x6A, 255),
}

BASE = r"D:\開發遊戲\台灣熱炒王\src\assets\sprites"
DIRS = {
    "tiles":      os.path.join(BASE, "tiles"),
    "characters": os.path.join(BASE, "characters"),
    "equipment":  os.path.join(BASE, "equipment"),
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


def draw_rect_outline(img, x1, y1, x2, y2, color):
    """畫矩形輪廓（1px）"""
    for x in range(x1, x2 + 1):
        px(img, x, y1, color)
        px(img, x, y2, color)
    for y in range(y1, y2 + 1):
        px(img, x1, y, color)
        px(img, x2, y, color)


def save(img, directory, filename):
    path = os.path.join(DIRS[directory], filename)
    img.save(path)
    results.append(("OK", path))
    print(f"  [OK] {filename}")


# ── 1. tile_floor_kitchen.png (16x16) ───────────────────────────────────────
def draw_tile_floor_kitchen():
    img = Image.new("RGBA", (16, 16), C["floor_k1"])

    # 外框 1px
    draw_rect_outline(img, 0, 0, 15, 15, C["outline"])

    # 磚縫水平線 y=7
    for x in range(1, 15):
        px(img, x, 7, C["floor_k_dk"])

    # 磚縫垂直線 x=4, x=11
    for y in range(1, 7):
        px(img, 4, y, C["floor_k_dk"])
        px(img, 11, y, C["floor_k_dk"])
    for y in range(8, 15):
        px(img, 4, y, C["floor_k_dk"])
        px(img, 11, y, C["floor_k_dk"])

    # 右下角 2x2 高光
    fill_rect(img, 13, 13, 14, 14, C["floor_k2"])

    save(img, "tiles", "tile_floor_kitchen.png")


# ── 2. tile_floor_dining.png (16x16) ────────────────────────────────────────
def draw_tile_floor_dining():
    img = Image.new("RGBA", (16, 16), C["floor_d1"])

    # 木紋水平線 y=3,7,11,15
    for y in [3, 7, 11, 15]:
        for x in range(1, 16):
            px(img, x, y, C["floor_d2"])

    # 左邊緣 1px
    for y in range(16):
        px(img, 0, y, C["floor_d3"])

    save(img, "tiles", "tile_floor_dining.png")


# ── 3. tile_floor_corridor.png (16x16) ──────────────────────────────────────
def draw_tile_floor_corridor():
    img = Image.new("RGBA", (16, 16), C["corridor"])

    # 四角 1px 高光
    px(img, 0, 0, C["corr_hi"])
    px(img, 15, 0, C["corr_hi"])
    px(img, 0, 15, C["corr_hi"])
    px(img, 15, 15, C["corr_hi"])

    # 中央 8x8 略深（從 4,4 到 11,11）
    fill_rect(img, 4, 4, 11, 11, C["corr_dk"])

    save(img, "tiles", "tile_floor_corridor.png")


# ── 4. tile_road.png (16x16) ─────────────────────────────────────────────────
def draw_tile_road():
    img = Image.new("RGBA", (16, 16), C["road1"])

    # 固定 6 個散點
    dots = [(2, 3), (5, 7), (8, 2), (11, 5), (3, 12), (13, 10)]
    for dx, dy in dots:
        px(img, dx, dy, C["road2"])

    # 右側 1px 邊線
    for y in range(16):
        px(img, 15, y, C["road3"])

    save(img, "tiles", "tile_road.png")


# ── 5. tile_wall_brick.png (16x16) ──────────────────────────────────────────
def draw_tile_wall_brick():
    img = Image.new("RGBA", (16, 16), C["brick_dk"])

    # 上排磚塊
    fill_rect(img, 1, 1, 7, 6, C["brick_br"])
    fill_rect(img, 9, 1, 14, 6, C["brick_br"])

    # 下排磚塊（錯排）
    fill_rect(img, 1, 9, 5, 14, C["brick_br"])
    fill_rect(img, 7, 9, 14, 14, C["brick_br"])

    save(img, "tiles", "tile_wall_brick.png")


# ── 6. char_boss_idle.png (16x24) ───────────────────────────────────────────
def draw_char_boss_idle():
    img = Image.new("RGBA", (16, 24), C["transp"])

    # 頭髮 y=4-5, x=4-11
    fill_rect(img, 4, 4, 11, 5, C["hair_dk"])

    # 瀏海 y=6, x=4-11（中間 x=6-9 露膚）
    for x in range(4, 12):
        px(img, x, 6, C["hair_dk"])
    for x in range(6, 10):
        px(img, x, 6, C["skin"])

    # 臉 y=7-10, x=5-10
    fill_rect(img, 5, 7, 10, 10, C["skin"])

    # 臉輪廓（左右邊緣暗膚）
    for y in range(7, 11):
        px(img, 5, y, C["skin_dark"])
        px(img, 10, y, C["skin_dark"])

    # 眼睛 y=8: x=6, x=9
    px(img, 6, 8, C["outline"])
    px(img, 9, 8, C["outline"])

    # 嘴 y=10: x=7-8
    px(img, 7, 10, C["lips"])
    px(img, 8, 10, C["lips"])

    # 身體上衣 y=11-15, x=5-10
    fill_rect(img, 5, 11, 10, 15, C["red"])

    # 上衣邊 x=4, x=11
    for y in range(11, 16):
        px(img, 4, y, C["outline"])
        px(img, 11, y, C["outline"])

    # 腰帶 y=16, x=5-10
    fill_rect(img, 5, 16, 10, 16, C["hair_dk"])

    # 裙 y=16-19, x=5-10（深藍黑）
    fill_rect(img, 5, 16, 10, 19, C["skirt"])

    # 腳 y=20-22：左 x=5-6，右 x=9-10
    fill_rect(img, 5, 20, 6, 22, C["skin"])
    fill_rect(img, 9, 20, 10, 22, C["skin"])

    # 鞋 y=23：x=5-6, x=9-10
    fill_rect(img, 5, 23, 6, 23, C["hair_dk"])
    fill_rect(img, 9, 23, 10, 23, C["hair_dk"])

    save(img, "characters", "char_boss_idle.png")


# ── 7. char_chef_idle.png (16x24) ───────────────────────────────────────────
def draw_char_chef_idle():
    img = Image.new("RGBA", (16, 24), C["transp"])

    # 廚師帽帽頂 y=2-3, x=4-11
    fill_rect(img, 4, 2, 11, 3, C["white"])

    # 帽沿 y=4-5, x=4-11
    fill_rect(img, 4, 4, 11, 5, C["white"])

    # 臉 y=6-11, x=5-10
    fill_rect(img, 5, 6, 10, 11, C["skin"])

    # 眼睛 y=8: x=6, x=9
    px(img, 6, 8, C["outline"])
    px(img, 9, 8, C["outline"])

    # 鬍渣 y=10: x=6,8（每隔一格）
    px(img, 6, 10, C["hair_dk"])
    px(img, 8, 10, C["hair_dk"])

    # 廚師服身體 y=12-17, x=4-11
    fill_rect(img, 4, 12, 11, 17, C["white"])

    # 廚師服邊緣 x=4, x=11
    for y in range(12, 18):
        px(img, 4, y, C["chef_edge"])
        px(img, 11, y, C["chef_edge"])

    # 圍裙 y=14-17, x=6-9
    fill_rect(img, 6, 14, 9, 17, C["apron_blue"])

    # 褲子 y=18-21, x=5-10
    fill_rect(img, 5, 18, 10, 21, C["pants"])

    # 鞋 y=22-23: 左 x=5-6，右 x=9-10
    fill_rect(img, 5, 22, 6, 23, C["outline"])
    fill_rect(img, 9, 22, 10, 23, C["outline"])

    save(img, "characters", "char_chef_idle.png")


# ── 8. equip_wok_static.png (32x32) ─────────────────────────────────────────
def draw_equip_wok_static():
    img = Image.new("RGBA", (32, 32), C["transp"])

    # 鍋身外輪廓（橢圓形近似，y=14-26, x=8-23）
    draw_rect_outline(img, 8, 14, 23, 26, C["outline"])

    # 鍋身填色（內部 y=15-25, x=9-22）
    fill_rect(img, 9, 15, 22, 25, C["wok_body"])

    # 鍋身兩側斜角輪廓修正（讓它更像橢圓）
    # 上邊弧度
    px(img, 8, 14, C["transp"])
    px(img, 9, 14, C["outline"])
    px(img, 22, 14, C["outline"])
    px(img, 23, 14, C["transp"])
    # 下邊弧度
    px(img, 8, 26, C["transp"])
    px(img, 9, 26, C["outline"])
    px(img, 22, 26, C["outline"])
    px(img, 23, 26, C["transp"])

    # 鍋身外輪廓側邊修正
    px(img, 8, 15, C["outline"])
    px(img, 8, 25, C["outline"])
    px(img, 23, 15, C["outline"])
    px(img, 23, 25, C["outline"])

    # 鍋內亮面 y=16-24, x=10-21
    fill_rect(img, 10, 16, 21, 24, C["wok_mid"])

    # 鍋底高光 y=22-23, x=12-19
    fill_rect(img, 12, 22, 19, 23, C["wok_hi"])

    # 把手左 y=18-20, x=3-8
    fill_rect(img, 3, 18, 8, 20, C["handle"])
    draw_rect_outline(img, 3, 18, 8, 20, C["outline"])

    # 把手右 y=18-20, x=23-28
    fill_rect(img, 23, 18, 28, 20, C["handle"])
    draw_rect_outline(img, 23, 18, 28, 20, C["outline"])

    # 爐架 y=27-30, x=6-25
    # 三條橫槓（每隔 1px）
    for y in [27, 29, 31]:
        for x in range(6, 26):
            px(img, x, y, C["rack"])
        for x in range(6, 26):
            if y + 1 <= 31:
                px(img, x, y + 1 if y < 30 else y, C["rack_dk"])

    # 爐架外輪廓
    draw_rect_outline(img, 6, 27, 25, 30, C["rack_dk"])

    save(img, "equipment", "equip_wok_static.png")


# ── 9. table_2p.png (32x16) ──────────────────────────────────────────────────
def draw_table_2p():
    img = Image.new("RGBA", (32, 16), C["transp"])

    # 桌面外框 y=4-11, x=6-25
    fill_rect(img, 6, 4, 25, 11, C["table_wood"])
    draw_rect_outline(img, 6, 4, 25, 11, C["outline"])

    # 桌布 y=5-10, x=7-24
    fill_rect(img, 7, 5, 24, 10, C["table_cloth"])

    # 左椅 y=5-10, x=1-5
    fill_rect(img, 1, 5, 5, 10, C["red"])
    draw_rect_outline(img, 1, 5, 5, 10, C["outline"])

    # 右椅 y=5-10, x=26-30
    fill_rect(img, 26, 5, 30, 10, C["red"])
    draw_rect_outline(img, 26, 5, 30, 10, C["outline"])

    save(img, "equipment", "table_2p.png")


# ── 10. char_boss_walk.png (16x24) ──────────────────────────────────────────
def draw_char_boss_walk():
    img = Image.new("RGBA", (16, 24), C["transp"])

    # 頭髮 y=4-5, x=4-11
    fill_rect(img, 4, 4, 11, 5, C["hair_dk"])

    # 瀏海 y=6, x=4-11（中間 x=6-9 露膚）
    for x in range(4, 12):
        px(img, x, 6, C["hair_dk"])
    for x in range(6, 10):
        px(img, x, 6, C["skin"])

    # 臉 y=7-10, x=5-10
    fill_rect(img, 5, 7, 10, 10, C["skin"])

    # 臉輪廓
    for y in range(7, 11):
        px(img, 5, y, C["skin_dark"])
        px(img, 10, y, C["skin_dark"])

    # 眼睛
    px(img, 6, 8, C["outline"])
    px(img, 9, 8, C["outline"])

    # 嘴
    px(img, 7, 10, C["lips"])
    px(img, 8, 10, C["lips"])

    # 身體上衣 y=11-15, x=5-10
    fill_rect(img, 5, 11, 10, 15, C["red"])

    # 上衣邊
    for y in range(11, 16):
        px(img, 4, y, C["outline"])
        px(img, 11, y, C["outline"])

    # 左手微前（x=4 y=12-14）
    for y in range(12, 15):
        px(img, 4, y, C["red"])

    # 裙 y=16-19
    fill_rect(img, 5, 16, 10, 19, C["skirt"])

    # 腳：左腳 y=20-22 x=5-6（idle 同位置）
    fill_rect(img, 5, 20, 6, 22, C["skin"])

    # 右腳前伸：y=21-23 x=9-10（下移 1px）
    fill_rect(img, 9, 21, 10, 23, C["skin"])

    # 鞋（左 idle，右前伸）
    fill_rect(img, 5, 23, 6, 23, C["hair_dk"])
    # 右腳鞋已在 y=23 x=9-10 含在腳內，補暗色
    fill_rect(img, 9, 23, 10, 23, C["hair_dk"])

    save(img, "characters", "char_boss_walk.png")


# ── 11. char_chef_walk.png (16x24) ──────────────────────────────────────────
def draw_char_chef_walk():
    img = Image.new("RGBA", (16, 24), C["transp"])

    # 廚師帽帽頂 y=2-3, x=4-11
    fill_rect(img, 4, 2, 11, 3, C["white"])

    # 帽沿 y=4-5, x=4-11
    fill_rect(img, 4, 4, 11, 5, C["white"])

    # 臉 y=6-11, x=5-10
    fill_rect(img, 5, 6, 10, 11, C["skin"])

    # 眼睛
    px(img, 6, 8, C["outline"])
    px(img, 9, 8, C["outline"])

    # 鬍渣
    px(img, 6, 10, C["hair_dk"])
    px(img, 8, 10, C["hair_dk"])

    # 廚師服身體 y=12-17, x=4-11
    fill_rect(img, 4, 12, 11, 17, C["white"])

    # 廚師服邊緣
    for y in range(12, 18):
        px(img, 4, y, C["chef_edge"])
        px(img, 11, y, C["chef_edge"])

    # 圍裙
    fill_rect(img, 6, 14, 9, 17, C["apron_blue"])

    # 右手持鍋鏟：x=11 y=13-17 加 1px（鍋鏟柄向右延伸）
    for y in range(13, 18):
        px(img, 11, y, C["spatula"])

    # 褲子 y=18-21, x=5-10
    fill_rect(img, 5, 18, 10, 21, C["pants"])

    # 左腳前伸：y=20-22 x=5-6（下移 1px，原 y=19-21）
    fill_rect(img, 5, 20, 6, 22, C["pants"])

    # 鞋：左腳 y=23，右腳 y=22-23
    fill_rect(img, 5, 23, 6, 23, C["outline"])
    fill_rect(img, 9, 22, 10, 23, C["outline"])

    save(img, "characters", "char_chef_walk.png")


# ── 12. char_customer_a_idle.png (16x24) ─────────────────────────────────────
def draw_char_customer_a_idle():
    img = Image.new("RGBA", (16, 24), C["transp"])

    # 短髮 y=4-6, x=5-10
    fill_rect(img, 5, 4, 10, 6, C["hair_dk"])

    # 臉 y=7-10, x=5-10
    fill_rect(img, 5, 7, 10, 10, C["skin"])

    # 眼睛
    px(img, 6, 8, C["outline"])
    px(img, 9, 8, C["outline"])

    # 上衣（藍色西裝）y=11-15, x=5-10
    fill_rect(img, 5, 11, 10, 15, C["suit_blue"])

    # 紅領帶 y=12-15, x=7-8
    fill_rect(img, 7, 12, 8, 15, C["red"])

    # 下半身（坐姿，深色褲子）y=16-23, x=5-10
    fill_rect(img, 5, 16, 10, 23, C["dark_pants"])

    save(img, "characters", "char_customer_a_idle.png")


# ── 13. char_customer_a_walk.png (16x24) ─────────────────────────────────────
def draw_char_customer_a_walk():
    img = Image.new("RGBA", (16, 24), C["transp"])

    # 短髮 y=4-6, x=5-10
    fill_rect(img, 5, 4, 10, 6, C["hair_dk"])

    # 臉 y=7-10, x=5-10
    fill_rect(img, 5, 7, 10, 10, C["skin"])

    # 眼睛
    px(img, 6, 8, C["outline"])
    px(img, 9, 8, C["outline"])

    # 上衣（藍色西裝）y=11-15, x=5-10
    fill_rect(img, 5, 11, 10, 15, C["suit_blue"])

    # 紅領帶 y=12-15, x=7-8
    fill_rect(img, 7, 12, 8, 15, C["red"])

    # 褲子（站立）y=16-20, x=5-10
    fill_rect(img, 5, 16, 10, 20, C["dark_pants"])

    # 鞋 y=21-23：左 x=5-6，右 x=9-10
    fill_rect(img, 5, 21, 6, 23, C["outline"])
    fill_rect(img, 9, 21, 10, 23, C["outline"])

    # 左腿前伸：y=16-22 x=5-6（補下移 1px）
    fill_rect(img, 5, 17, 6, 22, C["dark_pants"])
    fill_rect(img, 5, 22, 6, 22, C["outline"])

    save(img, "characters", "char_customer_a_walk.png")


# ── 14. equip_wok_active.png (32x32) ─────────────────────────────────────────
def draw_equip_wok_active():
    img = Image.new("RGBA", (32, 32), C["transp"])

    # 鍋身外輪廓
    draw_rect_outline(img, 8, 14, 23, 26, C["outline"])

    # 鍋身填色
    fill_rect(img, 9, 15, 22, 25, C["wok_body"])

    # 弧度修正
    px(img, 8, 14, C["transp"])
    px(img, 9, 14, C["outline"])
    px(img, 22, 14, C["outline"])
    px(img, 23, 14, C["transp"])
    px(img, 8, 26, C["transp"])
    px(img, 9, 26, C["outline"])
    px(img, 22, 26, C["outline"])
    px(img, 23, 26, C["transp"])
    px(img, 8, 15, C["outline"])
    px(img, 8, 25, C["outline"])
    px(img, 23, 15, C["outline"])
    px(img, 23, 25, C["outline"])

    # 鍋內亮面
    fill_rect(img, 10, 16, 21, 24, C["wok_mid"])

    # 鍋內熱氣（食材炒動）y=15-16, x=12-19
    fill_rect(img, 12, 15, 19, 16, C["wok_hot"])

    # 把手左
    fill_rect(img, 3, 18, 8, 20, C["handle"])
    draw_rect_outline(img, 3, 18, 8, 20, C["outline"])

    # 把手右
    fill_rect(img, 23, 18, 28, 20, C["handle"])
    draw_rect_outline(img, 23, 18, 28, 20, C["outline"])

    # 爐架 y=27-30
    for y in [27, 29, 31]:
        for x in range(6, 26):
            px(img, x, y, C["rack"])
        for x in range(6, 26):
            if y + 1 <= 31:
                px(img, x, y + 1 if y < 30 else y, C["rack_dk"])
    draw_rect_outline(img, 6, 27, 25, 30, C["rack_dk"])

    # 爐火：底部 y=30 x=11-20 #FF4500
    for x in range(11, 21):
        px(img, x, 30, C["fire_base"])
    # 中部 y=28-29 x=13-18 #FF8C00
    fill_rect(img, 13, 28, 18, 29, C["fire_mid"])
    # 頂部 y=27 x=15-16 #FFD700
    fill_rect(img, 15, 27, 16, 27, C["fire_top"])

    save(img, "equipment", "equip_wok_active.png")


# ── 15. table_4p.png (32x32) ─────────────────────────────────────────────────
def draw_table_4p():
    img = Image.new("RGBA", (32, 32), C["transp"])

    # 桌面 y=8-23, x=8-23
    fill_rect(img, 8, 8, 23, 23, C["table_wood"])
    draw_rect_outline(img, 8, 8, 23, 23, C["outline"])

    # 桌布中央 y=9-22, x=9-22
    fill_rect(img, 9, 9, 22, 22, C["table_cloth"])

    # 上方椅子 y=2-7, x=10-21
    fill_rect(img, 10, 2, 21, 7, C["red"])
    draw_rect_outline(img, 10, 2, 21, 7, C["outline"])

    # 下方椅子 y=24-29, x=10-21
    fill_rect(img, 10, 24, 21, 29, C["red"])
    draw_rect_outline(img, 10, 24, 21, 29, C["outline"])

    # 左椅 y=10-21, x=2-7
    fill_rect(img, 2, 10, 7, 21, C["red"])
    draw_rect_outline(img, 2, 10, 7, 21, C["outline"])

    # 右椅 y=10-21, x=24-29
    fill_rect(img, 24, 10, 29, 21, C["red"])
    draw_rect_outline(img, 24, 10, 29, 21, C["outline"])

    save(img, "equipment", "table_4p.png")


# ── 16. hud_icon_coin.png (8x8) ──────────────────────────────────────────────
def draw_hud_icon_coin():
    img = Image.new("RGBA", (8, 8), C["transp"])

    # 外圓形填色（鑽石形近似圓）
    coin_pixels = [
        (1, [3, 4]),
        (2, [2, 3, 4, 5]),
        (3, [2, 3, 4, 5]),
        (4, [2, 3, 4, 5]),
        (5, [2, 3, 4, 5]),
        (6, [3, 4]),
    ]
    for y, xs in coin_pixels:
        for x in xs:
            px(img, x, y, C["coin_gold"])

    # 邊緣暗色（外圓邊 1px）—— 覆蓋最外層像素
    edge_pixels = [
        (1, [3, 4]),
        (6, [3, 4]),
        (2, [2, 5]),
        (3, [2, 5]),
        (4, [2, 5]),
        (5, [2, 5]),
    ]
    for y, xs in edge_pixels:
        for x in xs:
            px(img, x, y, C["coin_dk"])

    # 內部高光
    px(img, 3, 2, C["coin_hi"])
    px(img, 3, 3, C["coin_hi"])

    save(img, "tiles", "hud_icon_coin.png")


# ── 17. hud_icon_star.png (8x8) ──────────────────────────────────────────────
def draw_hud_icon_star():
    img = Image.new("RGBA", (8, 8), C["transp"])

    # 5 角星填充
    star_pixels = [
        (1, [3, 4]),
        (2, [2, 3, 4, 5]),
        (3, [1, 2, 3, 4, 5, 6]),
        (4, [2, 3, 4, 5]),
        (5, [1, 2, 5, 6]),
        (6, [1, 6]),
    ]
    for y, xs in star_pixels:
        for x in xs:
            px(img, x, y, C["coin_gold"])

    # 輪廓 #8B6914
    outline_pixels = [
        (1, [3, 4]),
        (2, [2, 5]),
        (3, [1, 6]),
        (4, [2, 5]),
        (5, [1, 6]),
        (6, [1, 6]),
    ]
    for y, xs in outline_pixels:
        for x in xs:
            px(img, x, y, C["hair_br"])

    save(img, "tiles", "hud_icon_star.png")


# ── 18. hud_bg_top.png (480x28) ──────────────────────────────────────────────
def draw_hud_bg_top():
    img = Image.new("RGBA", (480, 28), C["hud_bg"])

    # 最下方 1px 霓虹線
    for x in range(480):
        px(img, x, 27, C["hud_line"])

    save(img, "tiles", "hud_bg_top.png")


# ── 19. hud_bg_bottom.png (480x28) ───────────────────────────────────────────
def draw_hud_bg_bottom():
    img = Image.new("RGBA", (480, 28), C["hud_bg"])

    # 最上方 1px 霓虹線
    for x in range(480):
        px(img, x, 0, C["hud_line"])

    save(img, "tiles", "hud_bg_bottom.png")


# ── 20. btn_build.png (20x20) ────────────────────────────────────────────────
def draw_btn_build():
    img = Image.new("RGBA", (20, 20), C["btn_bg"])

    # 外框 1px
    draw_rect_outline(img, 0, 0, 19, 19, C["btn_border"])

    # 「+」符號
    # 橫槓 y=9-10, x=4-15
    fill_rect(img, 4, 9, 15, 10, C["btn_green"])
    # 直槓 x=9-10, y=4-15
    fill_rect(img, 9, 4, 10, 15, C["btn_green"])

    save(img, "tiles", "btn_build.png")


# ── 主程式 ───────────────────────────────────────────────────────────────────
def main():
    print("台灣熱炒王 P1 像素素材補完（11 件新素材）...\n")

    # 確認輸出目錄存在
    for d in DIRS.values():
        os.makedirs(d, exist_ok=True)

    # 只執行新增的 11 個（不重複跑已有的 9 個）
    new_tasks = [
        ("char_boss_walk.png",        draw_char_boss_walk),
        ("char_chef_walk.png",        draw_char_chef_walk),
        ("char_customer_a_idle.png",  draw_char_customer_a_idle),
        ("char_customer_a_walk.png",  draw_char_customer_a_walk),
        ("equip_wok_active.png",      draw_equip_wok_active),
        ("table_4p.png",              draw_table_4p),
        ("hud_icon_coin.png",         draw_hud_icon_coin),
        ("hud_icon_star.png",         draw_hud_icon_star),
        ("hud_bg_top.png",            draw_hud_bg_top),
        ("hud_bg_bottom.png",         draw_hud_bg_bottom),
        ("btn_build.png",             draw_btn_build),
    ]

    errors = []
    for name, fn in new_tasks:
        try:
            fn()
        except Exception as e:
            results.append(("FAIL", name))
            errors.append((name, str(e)))
            print(f"  [FAIL] {name}: {e}")

    print(f"\n生成完成：{len(new_tasks) - len(errors)}/{len(new_tasks)} 成功")

    if errors:
        print("\n失敗清單：")
        for name, err in errors:
            print(f"  {name}: {err}")
    else:
        print("所有新素材已成功寫入，可直接在 Godot 中查看效果。")


if __name__ == "__main__":
    main()
