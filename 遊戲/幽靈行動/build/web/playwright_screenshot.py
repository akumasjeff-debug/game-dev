from playwright.sync_api import sync_playwright
import time

with sync_playwright() as p:
    browser = p.chromium.launch()
    context = browser.new_context(viewport={"width": 1080, "height": 1920})
    page = context.new_page()

    console_errors = []
    page.on("console", lambda msg: console_errors.append(f"[{msg.type}] {msg.text}") if msg.type in ("error", "warning") else None)
    page.on("pageerror", lambda err: console_errors.append(f"[pageerror] {err}"))

    page.goto("http://localhost:8766")
    time.sleep(8)  # 等待 Godot 載入

    page.screenshot(path=r"d:\開發遊戲\遊戲\幽靈行動\build\web\screenshot.png", full_page=False)
    browser.close()

    print("截圖完成")
    if console_errors:
        print("Console 錯誤/警告：")
        for e in console_errors:
            print(e)
    else:
        print("無 console 錯誤")
