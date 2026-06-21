"""
remove_handwriting.py
把考卷照片的紅色手寫筆跡自動移除，還原成空白試卷。

用法：
    python remove_handwriting.py <圖片路徑>
    python remove_handwriting.py <圖片路徑> --debug   (顯示偵測到的遮罩)

輸出：在同一資料夾產生 <原檔名>_clean.jpg
"""

import cv2
import numpy as np
import argparse
import sys
from pathlib import Path


def remove_handwriting(image_path: str, pencil_min: int = 15, pencil_max: int = 80, debug: bool = False) -> None:
    # 用 numpy 繞過 OpenCV 不支援中文路徑的問題
    img = cv2.imdecode(np.fromfile(image_path, dtype=np.uint8), cv2.IMREAD_COLOR)
    if img is None:
        print(f"錯誤：無法讀取圖片 {image_path}")
        sys.exit(1)

    # === 1. 紅色筆跡（顏色偵測）===
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    mask_red1 = cv2.inRange(hsv, np.array([0, 60, 60]),   np.array([10, 255, 255]))
    mask_red2 = cv2.inRange(hsv, np.array([160, 60, 60]), np.array([180, 255, 255]))
    mask_red = cv2.bitwise_or(mask_red1, mask_red2)

    # === 2. 鉛筆筆跡（局部對比偵測）===
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    # 用大範圍模糊估算「局部背景亮度」
    bg = cv2.GaussianBlur(gray, (61, 61), 0)
    # 計算每個像素比周圍背景暗多少
    diff = np.clip(bg.astype(np.int16) - gray.astype(np.int16), 0, 255).astype(np.uint8)
    # 鉛筆：稍微暗（pencil_min~pencil_max）；印刷文字：非常暗（>100）
    mask_pencil = np.zeros_like(gray, dtype=np.uint8)
    mask_pencil[(diff >= pencil_min) & (diff <= pencil_max)] = 255

    # === 合併遮罩 ===
    mask = cv2.bitwise_or(mask_red, mask_pencil)

    # 清除孤立雜點
    kernel_clean = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2, 2))
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel_clean)
    # 稍微膨脹確保邊緣覆蓋
    kernel_dilate = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (4, 4))
    mask = cv2.dilate(mask, kernel_dilate, iterations=2)

    if debug:
        debug_path = Path(image_path).with_stem(Path(image_path).stem + "_mask")
        cv2.imencode(".jpg", mask)[1].tofile(str(debug_path))
        print(f"遮罩已儲存：{debug_path}")

    # Inpainting：從周圍背景重建，不生成文字，不會出現亂碼
    result = cv2.inpaint(img, mask, inpaintRadius=5, flags=cv2.INPAINT_NS)

    out_path = Path(image_path).with_stem(Path(image_path).stem + "_clean")
    out_path = out_path.with_suffix(".jpg")
    cv2.imencode(".jpg", result, [cv2.IMWRITE_JPEG_QUALITY, 95])[1].tofile(str(out_path))
    print(f"完成！輸出：{out_path}")


def batch_process(folder: str, pencil_min: int = 15, pencil_max: int = 80, debug: bool = False) -> None:
    folder_path = Path(folder)
    images = list(folder_path.glob("*.jpg")) + list(folder_path.glob("*.png")) + \
             list(folder_path.glob("*.jpeg")) + list(folder_path.glob("*.JPG"))

    # 跳過已經處理過的輸出檔
    images = [p for p in images if "_clean" not in p.stem and "_mask" not in p.stem]

    if not images:
        print("找不到圖片")
        return

    print(f"找到 {len(images)} 張圖片，開始批次處理...")
    for i, img_path in enumerate(images, 1):
        print(f"[{i}/{len(images)}] 處理：{img_path.name}")
        remove_handwriting(str(img_path), pencil_min=pencil_min, pencil_max=pencil_max, debug=debug)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="自動移除考卷手寫筆跡")
    parser.add_argument("input", help="圖片路徑 或 資料夾路徑（批次處理）")
    parser.add_argument("--debug", action="store_true", help="同時輸出遮罩圖")
    args = parser.parse_args()

    path = Path(args.input)
    if path.is_dir():
        batch_process(str(path), debug=args.debug)
    elif path.is_file():
        remove_handwriting(str(path), debug=args.debug)
    else:
        print(f"錯誤：找不到 {args.input}")
        sys.exit(1)
