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


def remove_handwriting(image_path: str, debug: bool = False) -> None:
    # 用 numpy 繞過 OpenCV 不支援中文路徑的問題
    img = cv2.imdecode(np.fromfile(image_path, dtype=np.uint8), cv2.IMREAD_COLOR)
    if img is None:
        print(f"錯誤：無法讀取圖片 {image_path}")
        sys.exit(1)

    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

    # 紅色在 HSV 空間分兩段（0-10 和 160-180）
    mask_red1 = cv2.inRange(hsv, np.array([0, 60, 60]),   np.array([10, 255, 255]))
    mask_red2 = cv2.inRange(hsv, np.array([160, 60, 60]), np.array([180, 255, 255]))
    mask = cv2.bitwise_or(mask_red1, mask_red2)

    # 膨脹遮罩，確保筆跡邊緣全覆蓋
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    mask = cv2.dilate(mask, kernel, iterations=2)

    if debug:
        debug_path = Path(image_path).with_stem(Path(image_path).stem + "_mask")
        cv2.imwrite(str(debug_path), mask)
        print(f"遮罩已儲存：{debug_path}")

    # Inpainting：從周圍背景重建，不生成文字，不會出現亂碼
    result = cv2.inpaint(img, mask, inpaintRadius=5, flags=cv2.INPAINT_NS)

    out_path = Path(image_path).with_stem(Path(image_path).stem + "_clean")
    out_path = out_path.with_suffix(".jpg")
    cv2.imencode(".jpg", result, [cv2.IMWRITE_JPEG_QUALITY, 95])[1].tofile(str(out_path))
    print(f"完成！輸出：{out_path}")


def batch_process(folder: str, debug: bool = False) -> None:
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
        remove_handwriting(str(img_path), debug=debug)


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
