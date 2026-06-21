from playwright.sync_api import sync_playwright
import time

# 遊戲原始解析度：1080 x 1920
# Playwright viewport：540 x 960
# 縮放比：0.5 (所有 game 座標 / 2 = viewport 座標)
#
# 出發按鈕：  game pos (290, 1100), size (500, 90) → center game (540, 1145) → viewport (270, 572)
# 確認出發：  game pos (290, 780),  size (500, 90) → center game (540, 825)  → viewport (270, 412)

with sync_playwright() as p:
    browser = p.chromium.launch(
        headless=True,
        args=['--no-sandbox', '--disable-web-security',
              '--enable-features=SharedArrayBuffer',
              '--disable-features=VizDisplayCompositor']
    )
    page = browser.new_page(viewport={'width': 540, 'height': 960})
    page.goto('http://localhost:8765', timeout=30000)
    time.sleep(5)
    page.screenshot(path='d:/開發遊戲/遊戲/幽靈行動/build/verify_01_base.png')
    print('Screenshot 1: base screen')

    # 點擊「出發」按鈕
    page.mouse.click(270, 572)
    time.sleep(2)
    page.screenshot(path='d:/開發遊戲/遊戲/幽靈行動/build/verify_02_squad.png')
    print('Screenshot 2: squad confirm')

    # 點擊「確認出發」按鈕
    page.mouse.click(270, 412)
    time.sleep(14)  # 等待開場動廊 + 場景切換
    page.screenshot(path='d:/開發遊戲/遊戲/幽靈行動/build/verify_03_battle.png')
    print('Screenshot 3: battle scene')

    browser.close()
    print('Playwright verification complete')
