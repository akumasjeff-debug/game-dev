import subprocess
import sys
import os
import time

# 啟動本地伺服器
build_dir = r"d:\開發遊戲\遊戲\幽靈行動\build\web"
server = subprocess.Popen(
    [sys.executable, "-m", "http.server", "8766", "--directory", build_dir],
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL
)
time.sleep(2)

try:
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        browser = p.chromium.launch(args=["--no-sandbox"])
        ctx = browser.new_context(viewport={"width": 390, "height": 844})  # iPhone 14 尺寸
        page = ctx.new_page()
        page.goto("http://localhost:8766", timeout=30000)
        time.sleep(6)  # 等遊戲載入
        page.screenshot(path=r"d:\開發遊戲\遊戲\幽靈行動\build\screenshot_v3_mobile.png")
        print("截圖完成")
        browser.close()
except Exception as e:
    print(f"錯誤：{e}")
finally:
    server.terminate()
