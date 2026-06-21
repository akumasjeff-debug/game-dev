from playwright.sync_api import sync_playwright
import time
import subprocess
import sys
import os

BUILD_DIR = r"d:\開發遊戲\遊戲\幽靈行動\build\web"
OUTPUT_PATH = r"d:\開發遊戲\遊戲\幽靈行動\docs\screenshots\font_test.png"
PORT = 8775

# 啟動 HTTP server
server = subprocess.Popen(
    [sys.executable, "-m", "http.server", str(PORT), "--directory", BUILD_DIR],
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL
)
time.sleep(1)

try:
    with sync_playwright() as p:
        browser = p.chromium.launch()
        context = browser.new_context(
            viewport={"width": 1080, "height": 1920},
            # SharedArrayBuffer 需要 COOP/COEP，但截圖只看畫面
        )
        page = context.new_page()

        console_msgs = []
        page.on("console", lambda msg: console_msgs.append(f"[{msg.type}] {msg.text}"))
        page.on("pageerror", lambda err: console_msgs.append(f"[pageerror] {err}"))

        page.goto(f"http://localhost:{PORT}")
        time.sleep(10)  # 等待 Godot WASM 載入

        page.screenshot(path=OUTPUT_PATH, full_page=False)
        browser.close()

        print(f"截圖儲存至：{OUTPUT_PATH}")
        if console_msgs:
            print("Console 訊息（最後 20 筆）：")
            for m in console_msgs[-20:]:
                print(m)
        else:
            print("無 console 訊息")
finally:
    server.terminate()
    print("HTTP server 已關閉")
