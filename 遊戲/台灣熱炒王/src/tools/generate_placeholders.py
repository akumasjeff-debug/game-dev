#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
台灣熱炒王 — 佔位素材生成腳本
使用純 Python 標準庫生成 PNG，不需要 Pillow

使用方式：
    python generate_placeholders.py

生成 20 件 P1 佔位 PNG，讓 Godot 載入時不因找不到 texture 而崩潰。
"""

import os
import struct
import zlib

# ---------------------------------------------------------------------------
# 5x7 點陣字型（只含 A-Z、0-9、底線、空白）
# 每個字元以 5 個 byte 表示，每 byte 的低 7 bits 對應該列的像素（bit 4 = 左）
# ---------------------------------------------------------------------------
FONT_5X7 = {
    ' ': [0x00, 0x00, 0x00, 0x00, 0x00],
    'A': [0x1e, 0x11, 0x1f, 0x11, 0x11],
    'B': [0x1e, 0x11, 0x1e, 0x11, 0x1e],
    'C': [0x1f, 0x10, 0x10, 0x10, 0x1f],
    'D': [0x1e, 0x11, 0x11, 0x11, 0x1e],
    'E': [0x1f, 0x10, 0x1e, 0x10, 0x1f],
    'F': [0x1f, 0x10, 0x1e, 0x10, 0x10],
    'G': [0x1f, 0x10, 0x17, 0x11, 0x1f],
    'H': [0x11, 0x11, 0x1f, 0x11, 0x11],
    'I': [0x1f, 0x04, 0x04, 0x04, 0x1f],
    'J': [0x1f, 0x01, 0x01, 0x11, 0x0e],
    'K': [0x11, 0x12, 0x1c, 0x12, 0x11],
    'L': [0x10, 0x10, 0x10, 0x10, 0x1f],
    'M': [0x11, 0x1b, 0x15, 0x11, 0x11],
    'N': [0x11, 0x19, 0x15, 0x13, 0x11],
    'O': [0x0e, 0x11, 0x11, 0x11, 0x0e],
    'P': [0x1e, 0x11, 0x1e, 0x10, 0x10],
    'Q': [0x0e, 0x11, 0x15, 0x12, 0x0d],
    'R': [0x1e, 0x11, 0x1e, 0x12, 0x11],
    'S': [0x0f, 0x10, 0x0e, 0x01, 0x1e],
    'T': [0x1f, 0x04, 0x04, 0x04, 0x04],
    'U': [0x11, 0x11, 0x11, 0x11, 0x1f],
    'V': [0x11, 0x11, 0x11, 0x0a, 0x04],
    'W': [0x11, 0x11, 0x15, 0x1b, 0x11],
    'X': [0x11, 0x0a, 0x04, 0x0a, 0x11],
    'Y': [0x11, 0x0a, 0x04, 0x04, 0x04],
    'Z': [0x1f, 0x02, 0x04, 0x08, 0x1f],
    '0': [0x0e, 0x13, 0x15, 0x19, 0x0e],
    '1': [0x04, 0x0c, 0x04, 0x04, 0x0e],
    '2': [0x0e, 0x01, 0x06, 0x08, 0x0f],
    '3': [0x0e, 0x01, 0x06, 0x01, 0x0e],
    '4': [0x02, 0x06, 0x0a, 0x1f, 0x02],
    '5': [0x1f, 0x10, 0x1e, 0x01, 0x1e],
    '6': [0x0f, 0x10, 0x1e, 0x11, 0x0e],
    '7': [0x1f, 0x01, 0x02, 0x04, 0x08],
    '8': [0x0e, 0x11, 0x0e, 0x11, 0x0e],
    '9': [0x0e, 0x11, 0x0f, 0x01, 0x1e],
    '_': [0x00, 0x00, 0x00, 0x00, 0x1f],
}

# 補全 7 列（字型定義只有 5 列，補兩列空白讓字元高 7px）
for _k in FONT_5X7:
    FONT_5X7[_k] = [0x00, 0x00] + FONT_5X7[_k]  # 上方留 2 列空白


def _make_chunk(name: bytes, data: bytes) -> bytes:
    """產生一個 PNG chunk（長度 + 名稱 + 資料 + CRC）"""
    crc = zlib.crc32(name + data) & 0xFFFFFFFF
    return struct.pack('>I', len(data)) + name + data + struct.pack('>I', crc)


def make_png(width: int, height: int, fill: tuple, border: tuple) -> bytes:
    """
    生成純色 RGBA PNG bytes，帶有 1px 邊框。

    fill   : (R, G, B, A) 底色
    border : (R, G, B, A) 邊框色
    """
    fr, fg, fb, fa = fill
    br, bg, bb, ba = border

    # 建立 RGBA 像素陣列
    pixels = []
    for y in range(height):
        row = []
        for x in range(width):
            if x == 0 or x == width - 1 or y == 0 or y == height - 1:
                row.extend([br, bg, bb, ba])
            else:
                row.extend([fr, fg, fb, fa])
        pixels.append(row)

    return _pixels_to_png(width, height, pixels)


def make_png_with_label(width: int, height: int, fill: tuple, border: tuple,
                        label: str) -> bytes:
    """
    生成帶有點陣文字標示的 RGBA PNG bytes。
    標示文字從左上角 (2,2) 開始繪製，顏色為白色。
    """
    fr, fg, fb, fa = fill
    br, bg, bb, ba = border
    TEXT_R, TEXT_G, TEXT_B, TEXT_A = 255, 255, 255, 220

    # 建立像素陣列（list of list，每個元素為 [R,G,B,A]）
    pixels = []
    for y in range(height):
        row = []
        for x in range(width):
            if x == 0 or x == width - 1 or y == 0 or y == height - 1:
                row.append([br, bg, bb, ba])
            else:
                row.append([fr, fg, fb, fa])
        pixels.append(row)

    # 繪製文字（從座標 (2,2) 開始，每字元佔 6px 寬）
    text = label.upper()
    char_x = 2
    char_y = 2
    for ch in text:
        glyph = FONT_5X7.get(ch, FONT_5X7[' '])
        for row_idx, bits in enumerate(glyph):
            py = char_y + row_idx
            if py >= height - 1:
                break
            for col_idx in range(5):
                px = char_x + col_idx
                if px >= width - 1:
                    break
                if bits & (0x10 >> col_idx):
                    pixels[py][px] = [TEXT_R, TEXT_G, TEXT_B, TEXT_A]
        char_x += 6
        if char_x + 5 >= width:
            # 換行（往下移 9px）
            char_x = 2
            char_y += 9
            if char_y + 7 >= height:
                break

    # 攤平成 bytes
    flat = []
    for row in pixels:
        flat.append(b'\x00')  # filter byte
        for pixel in row:
            flat.append(bytes(pixel))

    compressed = zlib.compress(b''.join(flat))
    ihdr = struct.pack('>II', width, height) + bytes([8, 6, 0, 0, 0])
    sig = b'\x89PNG\r\n\x1a\n'
    return (sig
            + _make_chunk(b'IHDR', ihdr)
            + _make_chunk(b'IDAT', compressed)
            + _make_chunk(b'IEND', b''))


def _pixels_to_png(width: int, height: int, pixels: list) -> bytes:
    """將像素陣列（list of flat int rows）轉為 PNG bytes"""
    raw_rows = []
    for row in pixels:
        raw_rows.append(b'\x00' + bytes(row))
    compressed = zlib.compress(b''.join(raw_rows))
    ihdr = struct.pack('>II', width, height) + bytes([8, 6, 0, 0, 0])
    sig = b'\x89PNG\r\n\x1a\n'
    return (sig
            + _make_chunk(b'IHDR', ihdr)
            + _make_chunk(b'IDAT', compressed)
            + _make_chunk(b'IEND', b''))


# ---------------------------------------------------------------------------
# 素材清單：(名稱, 寬, 高, 類別)
# ---------------------------------------------------------------------------
ASSETS = [
    # Characters
    ("char_boss_idle",        16, 24, "characters"),
    ("char_boss_walk",        16, 24, "characters"),
    ("char_chef_idle",        16, 24, "characters"),
    ("char_chef_walk",        16, 24, "characters"),
    ("char_customer_a_idle",  16, 24, "characters"),
    ("char_customer_a_walk",  16, 24, "characters"),
    # Equipment
    ("equip_wok_static",      32, 32, "equipment"),
    ("equip_wok_active",      32, 32, "equipment"),
    ("table_2p",              32, 16, "equipment"),
    ("table_4p",              32, 32, "equipment"),
    # Tiles
    ("tile_road",             16, 16, "tiles"),
    ("tile_floor_kitchen",    16, 16, "tiles"),
    ("tile_floor_dining",     16, 16, "tiles"),
    ("tile_floor_corridor",   16, 16, "tiles"),
    ("tile_wall_brick",       16, 16, "tiles"),
    # UI
    ("hud_icon_coin",          8,  8, "ui"),
    ("hud_icon_star",          8,  8, "ui"),
    ("hud_bg_top",           480, 28, "ui"),
    ("hud_bg_bottom",        480, 28, "ui"),
    ("btn_build",             20, 20, "ui"),
]

# 類別底色（RGBA）
COLORS = {
    "characters": ((70,  130, 200, 255), (30,  70,  130, 255)),
    "equipment":  ((220, 130,  50, 255), (160,  80,  20, 255)),
    "tiles":      ((80,  160,  80, 255), (40,  100,  40, 255)),
    "ui":         ((100, 100, 120, 255), (60,   60,  80, 255)),
}

# 輸出目錄
OUTPUT_DIRS = {
    "characters": r"d:\開發遊戲\台灣熱炒王\src\assets\sprites\characters",
    "equipment":  r"d:\開發遊戲\台灣熱炒王\src\assets\sprites\equipment",
    "tiles":      r"d:\開發遊戲\台灣熱炒王\src\assets\sprites\tiles",
    "ui":         r"d:\開發遊戲\台灣熱炒王\src\assets\sprites\ui",
}


def main():
    # 確保所有輸出目錄存在
    for category, path in OUTPUT_DIRS.items():
        os.makedirs(path, exist_ok=True)
        print(f"[目錄] {path}")

    print()

    success = 0
    failed = []

    for name, w, h, category in ASSETS:
        fill, border = COLORS[category]
        out_dir = OUTPUT_DIRS[category]
        out_path = os.path.join(out_dir, f"{name}.png")

        try:
            # 小圖（寬或高 < 12px）不繪製文字，避免超出邊界
            if w < 12 or h < 12:
                png_data = make_png(w, h, fill, border)
            else:
                # 用素材名稱的短版標示（取 _ 分隔後最後一段，避免太長）
                label = name
                png_data = make_png_with_label(w, h, fill, border, label)

            with open(out_path, 'wb') as f:
                f.write(png_data)

            # 驗證檔案確實存在且有內容
            if os.path.exists(out_path) and os.path.getsize(out_path) > 0:
                print(f"  [OK] {category}/{name}.png  ({w}x{h}px)")
                success += 1
            else:
                print(f"  [失敗] {name}.png — 檔案為空或未建立")
                failed.append(name)

        except Exception as e:
            print(f"  [錯誤] {name}.png — {e}")
            failed.append(name)

    print()
    print(f"生成完成：{success}/{len(ASSETS)} 件成功")

    if failed:
        print(f"失敗清單：{', '.join(failed)}")
    else:
        print("所有佔位素材均已成功生成。")


if __name__ == "__main__":
    main()
