from playwright.sync_api import sync_playwright
import time

with sync_playwright() as p:
    b = p.chromium.launch()
    page = b.new_page(viewport={"width":1080,"height":1920})
    page.goto("http://localhost:8767")
    time.sleep(6)
    page.screenshot(path=r"d:\開發遊戲\遊戲\幽靈行動\build\web\screenshot_final.png")
    b.close()
    print("截圖完成")
