"""
draw_itch_assets.py
生成台灣熱炒王 itch.io 封面圖與模擬截圖。

輸出：
  content/itch_cover.png    (630x500)
  content/screenshot_01.png (480x270)

使用方法：
  python src/tools/draw_itch_assets.py
"""

from PIL import Image, ImageDraw, ImageFont
import os
import sys

# ─────────────────────────────────────────
# 路徑設定
# ─────────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
CONTENT_DIR = os.path.join(PROJECT_ROOT, "content")
os.makedirs(CONTENT_DIR, exist_ok=True)

COVER_PATH = os.path.join(CONTENT_DIR, "itch_cover.png")
SCREENSHOT_PATH = os.path.join(CONTENT_DIR, "screenshot_01.png")

# ─────────────────────────────────────────
# 字體載入輔助
# ─────────────────────────────────────────
FONT_PATHS_ZH = [
    "C:/Windows/Fonts/msjh.ttc",
    "C:/Windows/Fonts/msyh.ttc",
    "C:/Windows/Fonts/simsun.ttc",
    "C:/Windows/Fonts/mingliu.ttc",
]

def load_font(size: int, prefer_zh: bool = True) -> ImageFont.FreeTypeFont:
    """嘗試載入中文字體，失敗時回傳預設字體。"""
    if prefer_zh:
        for path in FONT_PATHS_ZH:
            if os.path.exists(path):
                try:
                    return ImageFont.truetype(path, size)
                except Exception:
                    continue
    # 回傳 PIL 內建點陣字體（不支援中文，但不會崩潰）
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()

def draw_text_centered(draw: ImageDraw.ImageDraw, y: int, text: str,
                        font: ImageFont.FreeTypeFont, fill: str,
                        canvas_width: int):
    """水平置中繪製文字。"""
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    x = (canvas_width - text_w) // 2
    draw.text((x, y), text, font=font, fill=fill)


# ═══════════════════════════════════════════════════════════
#  1. itch.io 封面圖  630 × 500
# ═══════════════════════════════════════════════════════════
def draw_cover():
    W, H = 630, 500
    img = Image.new("RGB", (W, H), "#1A1A2E")
    draw = ImageDraw.Draw(img)

    # ── 背景地面（下半部）─────────────────────────────────
    draw.rectangle([0, 300, W, H], fill="#2A0A00")

    # ── 霓虹招牌外框 ──────────────────────────────────────
    draw.rectangle([115, 40, 515, 130], fill="#FF2D55", outline="#FF6B9D", width=3)

    # 招牌內裝飾線
    draw.rectangle([122, 47, 508, 123], outline="#FF6B9D", width=1)

    # 招牌文字
    font_title = load_font(48)
    font_title_fallback = load_font(36, prefer_zh=False)

    title_zh = "台灣熱炒王"
    title_en = "Taiwan Stir-Fry King"

    # 先嘗試中文
    bbox_zh = draw.textbbox((0, 0), title_zh, font=font_title)
    if (bbox_zh[2] - bbox_zh[0]) > 10:
        draw_text_centered(draw, 68, title_zh, font_title, "#FFD700", W)
    else:
        draw_text_centered(draw, 72, title_en, font_title_fallback, "#FFD700", W)

    # ── 左側廚房區 (x=0~200, y=130~300) ──────────────────
    draw.rectangle([0, 130, 200, 300], fill="#8B4513")

    # 炒鍋（外鍋）
    draw.ellipse([30, 180, 150, 260], fill="#2A2A2A")
    # 炒鍋（內鍋面）
    draw.ellipse([50, 195, 130, 245], fill="#555555")
    # 鍋柄
    draw.rectangle([140, 210, 170, 220], fill="#888888")

    # 火焰（三角形組合）
    flame_colors = ["#FF4500", "#FF6600", "#FFD700"]
    for i, fc in enumerate(flame_colors):
        offset = i * 4
        draw.polygon([
            (70 + offset, 290),
            (90, 258 + offset),
            (110 - offset, 290)
        ], fill=fc)

    # 牆壁磚塊紋路
    for bx in range(0, 200, 40):
        for by in range(130, 300, 20):
            draw.rectangle([bx, by, bx + 38, by + 18], outline="#6B3410", width=1)

    # 抽油煙機
    draw.rectangle([20, 130, 180, 155], fill="#444444")
    draw.rectangle([30, 155, 170, 165], fill="#333333")

    # ── 右側外場區 (x=200~630, y=130~300) ────────────────
    draw.rectangle([200, 130, W, 300], fill="#D2B48C")

    # 木質地板紋路
    for fx in range(200, W, 60):
        draw.line([fx, 130, fx, 300], fill="#C19A6B", width=1)
    for fy in range(130, 300, 30):
        draw.line([200, fy, W, fy], fill="#C9A87C", width=1)

    # 折疊桌
    draw.rectangle([280, 170, 480, 250], fill="#DEB887", outline="#8B4513", width=2)
    # 桌腳
    draw.rectangle([290, 248, 300, 270], fill="#8B4513")
    draw.rectangle([460, 248, 470, 270], fill="#8B4513")

    # 四張椅子（桌子四角）
    chairs = [
        (280, 158, 312, 172),   # 上左
        (448, 158, 480, 172),   # 上右
        (280, 250, 312, 270),   # 下左
        (448, 250, 480, 270),   # 下右
    ]
    for ch in chairs:
        draw.rectangle(ch, fill="#FF2D55", outline="#8B0000", width=1)

    # 第二張桌子（右側）
    draw.rectangle([490, 185, 610, 245], fill="#DEB887", outline="#8B4513", width=2)
    chairs2 = [
        (490, 173, 518, 187),
        (582, 173, 610, 187),
        (490, 245, 518, 262),
        (582, 245, 610, 262),
    ]
    for ch in chairs2:
        draw.rectangle(ch, fill="#FF2D55", outline="#8B0000", width=1)

    # 吊燈
    for lx in [320, 430, 545]:
        draw.line([lx, 130, lx, 150], fill="#888888", width=1)
        draw.ellipse([lx - 12, 148, lx + 12, 168], fill="#FFF5B0", outline="#CCAA00", width=1)

    # ── 角色（廚師）x=90, y=130~180 ──────────────────────
    # 廚師帽
    draw.rectangle([84, 130, 96, 138], fill="#F5F5F5")
    draw.rectangle([82, 137, 98, 141], fill="#F5F5F5")
    # 頭
    draw.ellipse([85, 140, 95, 150], fill="#FFDBB5")
    # 身體（白廚師服）
    draw.rectangle([83, 150, 97, 175], fill="#F5F5F5")
    # 圍裙
    draw.rectangle([84, 155, 96, 175], fill="#CCCCCC")
    # 手
    draw.line([83, 160, 76, 168], fill="#FFDBB5", width=2)
    draw.line([97, 160, 104, 168], fill="#FFDBB5", width=2)
    # 腳
    draw.rectangle([84, 175, 90, 185], fill="#2C3E50")
    draw.rectangle([90, 175, 97, 185], fill="#2C3E50")

    # ── 角色（老闆娘）x=230, y=150~200 ──────────────────
    # 頭
    draw.ellipse([225, 150, 235, 160], fill="#FFDBB5")
    # 髮型
    draw.arc([222, 148, 238, 162], start=180, end=0, fill="#3D1A00", width=3)
    # 身體（紅色）
    draw.rectangle([223, 160, 237, 190], fill="#FF2D55")
    # 裙子
    draw.polygon([(218, 190), (223, 190), (226, 205), (234, 205), (237, 190), (242, 190)],
                 fill="#CC1144")
    # 手
    draw.line([223, 165, 216, 173], fill="#FFDBB5", width=2)
    draw.line([237, 165, 244, 173], fill="#FFDBB5", width=2)
    # 腳
    draw.rectangle([224, 205, 229, 215], fill="#2C1A0E")
    draw.rectangle([231, 205, 236, 215], fill="#2C1A0E")

    # ── 角色（客人A）x=310, y=160~210 ────────────────────
    draw.ellipse([305, 160, 315, 170], fill="#FFDBB5")
    draw.rectangle([303, 170, 317, 198], fill="#4A90E2")
    draw.rectangle([304, 198, 309, 208], fill="#333333")
    draw.rectangle([311, 198, 316, 208], fill="#333333")

    # ── 角色（客人B）x=370, y=160~210 ────────────────────
    draw.ellipse([365, 160, 375, 170], fill="#C68642")
    draw.rectangle([363, 170, 377, 198], fill="#2C1A0E")
    draw.rectangle([364, 198, 369, 208], fill="#1A0A00")
    draw.rectangle([371, 198, 376, 208], fill="#1A0A00")

    # ── 啤酒瓶（右下角）─────────────────────────────────
    # 瓶身
    draw.rectangle([510, 350, 540, 450], fill="#4CAF50", outline="#388E3C", width=1)
    # 瓶頸
    draw.rectangle([515, 330, 535, 355], fill="#4CAF50", outline="#388E3C", width=1)
    # 瓶蓋
    draw.rectangle([512, 325, 538, 335], fill="#F5A623", outline="#D4891A", width=1)
    # 標籤
    draw.rectangle([513, 375, 537, 420], fill="#FFD700", outline="#CC9900", width=1)

    # 標籤文字
    font_small = load_font(10)
    draw.text((515, 388), "台", font=font_small, fill="white")
    draw.text((515, 402), "啤", font=font_small, fill="white")

    # 第二瓶（稍微偏移）
    draw.rectangle([548, 365, 575, 455], fill="#4CAF50", outline="#388E3C", width=1)
    draw.rectangle([553, 347, 570, 368], fill="#4CAF50", outline="#388E3C", width=1)
    draw.rectangle([550, 342, 573, 352], fill="#F5A623", outline="#D4891A", width=1)
    draw.rectangle([551, 388, 572, 428], fill="#FFD700", outline="#CC9900", width=1)

    # ── 地面裝飾 ─────────────────────────────────────────
    # 地板磚紋
    for gx in range(0, W, 50):
        draw.line([gx, 300, gx, H], fill="#3A1500", width=1)
    for gy in range(300, H, 40):
        draw.line([0, gy, W, gy], fill="#3A1500", width=1)

    # 地面陰影
    draw.rectangle([0, 295, W, 310], fill="#1A0800")

    # ── 底部文字 ─────────────────────────────────────────
    font_mid = load_font(22)
    font_sm2 = load_font(16)

    draw_text_centered(draw, 430, "手機模擬經營 x 台灣夜市文化", font_mid, "#F5F5F5", W)
    draw_text_centered(draw, 465, "itch.io Demo", font_sm2, "#CCCCCC", W)

    # ── 霓虹燈邊框效果 ────────────────────────────────────
    # 頂部霓虹線
    draw.rectangle([0, 0, W, 4], fill="#FF2D55")
    # 底部霓虹線
    draw.rectangle([0, H - 4, W, H], fill="#FF2D55")
    # 左右霓虹線
    draw.rectangle([0, 0, 4, H], fill="#FF2D55")
    draw.rectangle([W - 4, 0, W, H], fill="#FF2D55")

    img.save(COVER_PATH, "PNG")
    print(f"封面圖已儲存：{COVER_PATH}")
    w, h = img.size
    print(f"  尺寸：{w} x {h} px")
    return img


# ═══════════════════════════════════════════════════════════
#  2. 模擬遊戲截圖  480 × 270
# ═══════════════════════════════════════════════════════════
def draw_screenshot():
    W, H = 480, 270
    img = Image.new("RGB", (W, H), "#2D2D2D")
    draw = ImageDraw.Draw(img)

    CELL = 32
    MAP_X, MAP_Y = 10, 30  # y=30 以留出 HUD 頂部空間（20px + 10px padding）
    COLS, ROWS = 6, 4

    # ── 地圖背景 ─────────────────────────────────────────
    for row in range(ROWS):
        for col in range(COLS):
            x0 = MAP_X + col * CELL
            y0 = MAP_Y + row * CELL
            x1 = x0 + CELL
            y1 = y0 + CELL

            if col < 2:
                # 廚房區（左 2 列）
                fill = "#8B4513"
                grid_color = "#6B3410"
            elif row == 3:
                # 走道（y=3 橫列）
                fill = "#808080"
                grid_color = "#666666"
            else:
                # 外場（右 4 列）
                fill = "#D2B48C"
                grid_color = "#C19A6B"

            draw.rectangle([x0, y0, x1, y1], fill=fill, outline=grid_color, width=1)

    # ── 炒鍋（格 1,1 → col=1, row=1）────────────────────
    kx = MAP_X + 1 * CELL
    ky = MAP_Y + 1 * CELL
    # 鍋
    draw.ellipse([kx + 4, ky + 4, kx + 28, ky + 20], fill="#2A2A2A", outline="#444444", width=1)
    draw.ellipse([kx + 8, ky + 7, kx + 24, ky + 17], fill="#555555")
    # 火焰
    draw.polygon([(kx + 12, ky + 28), (kx + 16, ky + 20), (kx + 20, ky + 28)], fill="#FF4500")
    draw.polygon([(kx + 14, ky + 26), (kx + 16, ky + 21), (kx + 18, ky + 26)], fill="#FFD700")

    # ── 桌椅（格 3,1 → col=3, row=1）────────────────────
    for table_col in [3, 5]:
        if table_col >= COLS:
            continue
        tx = MAP_X + table_col * CELL
        ty = MAP_Y + 1 * CELL
        # 桌面
        draw.rectangle([tx + 4, ty + 8, tx + 28, ty + 24], fill="#DEB887", outline="#8B4513", width=1)
        # 左椅
        draw.rectangle([tx - 2, ty + 10, tx + 6, ty + 22], fill="#FF2D55", outline="#8B0000", width=1)
        # 右椅
        draw.rectangle([tx + 26, ty + 10, tx + 34, ty + 22], fill="#FF2D55", outline="#8B0000", width=1)

    # ── 牆壁 ─────────────────────────────────────────────
    # 廚房與外場分隔線
    wall_x = MAP_X + 2 * CELL
    draw.line([wall_x, MAP_Y, wall_x, MAP_Y + ROWS * CELL], fill="#4A2800", width=3)

    # ── 角色：廚師（鍋旁）────────────────────────────────
    def draw_character(cx, cy, head_color, body_color, hat_color=None):
        """繪製簡化像素人物（10x18）"""
        # 帽子
        if hat_color:
            draw.rectangle([cx + 1, cy, cx + 9, cy + 4], fill=hat_color)
        # 頭
        draw.ellipse([cx + 1, cy + 4, cx + 9, cy + 12], fill=head_color)
        # 身體
        draw.rectangle([cx + 1, cy + 12, cx + 9, cy + 22], fill=body_color)
        # 腳
        draw.rectangle([cx + 2, cy + 22, cx + 5, cy + 26], fill="#2C3E50")
        draw.rectangle([cx + 6, cy + 22, cx + 9, cy + 26], fill="#2C3E50")

    # 廚師
    chef_x = MAP_X + 1 * CELL + 2
    chef_y = MAP_Y + 0 * CELL + 2
    draw_character(chef_x, chef_y, "#FFDBB5", "#F5F5F5", hat_color="#F5F5F5")

    # 老闆娘（走道）
    boss_x = MAP_X + 2 * CELL + 8
    boss_y = MAP_Y + 3 * CELL - 16
    draw_character(boss_x, boss_y, "#FFDBB5", "#FF2D55")

    # 客人（桌旁）
    guest_x = MAP_X + 4 * CELL + 2
    guest_y = MAP_Y + 1 * CELL + 2
    draw_character(guest_x, guest_y, "#FFDBB5", "#4A90E2")

    # ── HUD 頂部（y=0-20）────────────────────────────────
    # 半透明背景（用填色代替）
    draw.rectangle([0, 0, W, 20], fill="#1A1A2E")

    font_hud = load_font(13)
    font_hud_sm = load_font(11)

    draw.text((8, 3), "$12,450", font=font_hud, fill="#FFD700")
    draw.text((4, 3), "$", font=font_hud_sm, fill="#FFD700")

    # 日期文字
    draw_text_centered(draw, 3, "第 3 年  第 47 天", font_hud_sm, "#FFFFFF", W)

    # 時段
    font_hud_time = load_font(13)
    bbox_time = draw.textbbox((0, 0), "宵夜", font=font_hud_time)
    draw.text((W - bbox_time[2] - 10, 3), "宵夜", font=font_hud_time, fill="#FF8C42")

    # 底部霓虹線
    draw.rectangle([0, 20, W, 22], fill="#FF2D55")

    # ── HUD 底部（y=250-270）─────────────────────────────
    draw.rectangle([0, 250, W, H], fill="#1A1A2E")

    font_btn = load_font(10)
    buttons = ["建造", "擺桌", "雇員", "菜單"]
    btn_w = 60
    btn_spacing = (W - len(buttons) * btn_w) // (len(buttons) + 1)

    for i, btn_text in enumerate(buttons):
        bx = btn_spacing + i * (btn_w + btn_spacing)
        by = 253
        draw.rectangle([bx, by, bx + btn_w, by + 14], fill="#2A2A4A", outline="#4A4A8A", width=1)
        bbox_b = draw.textbbox((0, 0), btn_text, font=font_btn)
        text_w = bbox_b[2] - bbox_b[0]
        draw.text((bx + (btn_w - text_w) // 2, by + 2), btn_text, font=font_btn, fill="#FFFFFF")

    # ── 右側資訊面板（x=205-480, y=22-250）──────────────
    panel_x = MAP_X + COLS * CELL + 10
    panel_y = MAP_Y

    # 面板背景
    draw.rectangle([panel_x, panel_y, W - 5, H - 25], fill="#111122", outline="#333355", width=1)

    font_panel = load_font(11)
    font_panel_val = load_font(12)

    # 面板標題
    draw.rectangle([panel_x, panel_y, W - 5, panel_y + 16], fill="#2A2A4A")
    draw.text((panel_x + 5, panel_y + 2), "今日狀況", font=font_panel, fill="#AAAAFF")

    # 面板資料
    panel_data = [
        ("來客數", "23 人"),
        ("營業額", "$4,820"),
        ("食材", "80%"),
        ("滿意度", "★★★★"),
    ]
    for j, (label, value) in enumerate(panel_data):
        row_y = panel_y + 20 + j * 28
        draw.text((panel_x + 5, row_y), label, font=font_panel, fill="#888888")
        draw.text((panel_x + 5, row_y + 12), value, font=font_panel_val, fill="#FFFFFF")
        if j < len(panel_data) - 1:
            draw.line([panel_x + 3, row_y + 26, W - 8, row_y + 26], fill="#222244", width=1)

    # 快速操作提示
    hint_y = panel_y + 145
    draw.rectangle([panel_x + 2, hint_y, W - 7, hint_y + 14], fill="#1A1A3A")
    draw.text((panel_x + 5, hint_y + 1), "點格子放置建築", font=font_panel, fill="#666688")

    # 時間進度條
    time_y = panel_y + 162
    draw.text((panel_x + 5, time_y), "營業時間", font=font_panel, fill="#888888")
    bar_x = panel_x + 5
    bar_w = W - 15 - panel_x
    draw.rectangle([bar_x, time_y + 13, bar_x + bar_w, time_y + 20], fill="#222244")
    draw.rectangle([bar_x, time_y + 13, bar_x + int(bar_w * 0.7), time_y + 20], fill="#FF8C42")

    img.save(SCREENSHOT_PATH, "PNG")
    print(f"模擬截圖已儲存：{SCREENSHOT_PATH}")
    w, h = img.size
    print(f"  尺寸：{w} x {h} px")
    return img


# ─────────────────────────────────────────
# 主程式
# ─────────────────────────────────────────
if __name__ == "__main__":
    print("=== 台灣熱炒王 itch.io 素材生成工具 ===")
    print()

    cover = draw_cover()
    print()
    shot = draw_screenshot()
    print()
    print("完成！兩張圖皆已輸出至 content/ 資料夾。")
