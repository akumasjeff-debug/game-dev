# 台灣熱炒王 狀態

## 已完成
- [2026-06-20] 決定遊戲名稱：台灣熱炒王
- [2026-06-20] 建立專案資料夾：d:\開發遊戲\台灣熱炒王\
- [2026-06-20] 建立 CLAUDE.md（遊戲主題、風格、設計原則）
- [2026-06-20] 建立 STATE.md（本檔）
- [2026-06-20] 技術組：tech\tech-architecture.md（引擎評估 + 核心架構 + JSON Schema）
- [2026-06-20] 設計組：design\core-design.md（核心循環、六大系統、解鎖樹、年份目標、組合加成、節日事件）
- [2026-06-20] 美術組：art\art-spec.md（像素規格、33色色盤、建築/角色規格）
- [2026-06-20] 美術規格定案：格子 16x16px，角色 16x24px，基礎解析度 480x270
- [2026-06-20] 場景設計師：design\map-design.md（格子建造系統、Zone 系統、地圖三階段擴張）
- [2026-06-20] 數值企劃：design\values.md（菜單售價、名聲系統、6 組 Combo 加成）
- [2026-06-20] 關卡進度設計師：design\level-progression.md（五年里程碑、設備解鎖時序）
- [2026-06-20] 動畫規劃師：art\animation-spec.md（5 種角色 × 完整幀數規格、建築動態）
- [2026-06-20] 特效規格師：art\vfx-spec.md（12 種特效規格、層級系統、效能上限）
- [2026-06-20] UI/UX設計師：art\ui-spec.md（HUD、主選單、建造模式、對話框、字體、圖示）
- [2026-06-20] 重大決策：引擎選型確認 — Godot 4（GDScript）
- [2026-06-20] 重大決策：目標平台確認 — 手機（iOS + Android）
- [2026-06-20] 技術組（程式設計師）：src\ Godot 4 目錄結構（25 個子目錄）+ tech\godot-architecture.md + src\project.godot
- [2026-06-20] 內容組（內容企劃）：content\dishes.md（30 道菜）+ content\staff.md（10 名員工）+ content\events.md（19 個事件）
- [2026-06-20] 內容組（音效規劃）：content\audio-spec.md（6 首 BGM + 39 個音效 + Godot 4 整合規範）
- [2026-06-20] 設計組（教學設計師）：design\tutorial.md（Day 1-3 詳細教學流程 + 四角色語氣規範）
- [2026-06-20] 技術組（程式設計師）：GameManager.gd + CustomerAI.gd + StaffAI.gd + Main.tscn + Game.tscn + UI.tscn（6 個核心檔案）
- [2026-06-20] 技術組（資料管理師）：dishes.json（30 道）+ equipment.json（38 件）+ staff.json（10 人）+ events.json（19 個）
- [2026-06-20] 技術組（系統程式師）：PathfindingManager + SeatManager + MenuManager + SaveManager + SaveMigration（5 個系統腳本）
- [2026-06-20] 美術組（素材蒐集員）：content\assets-reference.md + src\assets\fonts\README.md
- [2026-06-20] 字體決策：Zpix → Fusion Pixel Font（OFL-1.1，免費商用）
- [2026-06-20] 品管組（數值驗證師）：Day 1 金流 + Year 1 可達性驗算（values.md 第五章）
- [2026-06-20] 品管組（測試員）：7 個腳本邏輯驗證，發現 5 個 bug + 3 個風險，全部修復
- [2026-06-20] 技術組（程式設計師）：AutoLoad 串接（10 個 singleton）+ audio_manager.gd + main.gd
- [2026-06-20] 內容組（在地化專員）：content\strings_zh_TW.csv（133 筆）
- [2026-06-20] 技術組（程式設計師）：BuildManager.gd + build_ui.gd + EventManager.gd + OrderManager.gd
- [2026-06-20] 美術組（美術規格師）：content\art-deliverables.md + content\art-brief.md
- [2026-06-20] 品管組（數值驗證師）：Year 1-5 全程金流驗算完成
- [2026-06-20] 技術組（程式設計師）：員工士氣系統 + TutorialManager.gd
- [2026-06-20] 設計組（場景設計師）：design\initial-map.md（6x4 起始布局）
- [2026-06-20] 工具組：39 件像素素材生成（P1+P2）
- [2026-06-20] 品管組：content\test-plan.md（12 個測試案例）
- [2026-06-20] 發布規劃師：export_presets.cfg + itch-io-listing.md
- [2026-06-20] **[DEMO里程碑]** 場景串接修復：Main.tscn instance Game.tscn + UI.tscn，game.gd/hud.gd 正確掛載
- [2026-06-20] **[DEMO里程碑]** 地板像素 tile（廚房/走道/外場三種貼圖）、設備 Sprite2D、角色 Sprite2D
- [2026-06-20] **[DEMO里程碑]** 客人 AI 完整端到端循環：進門→自動入座→點餐→烹飪→上菜→付錢→飄字→離場
- [2026-06-20] **[DEMO里程碑]** 金錢飄字（+$XXX 金色，向上淡出）
- [2026-06-20] **[DEMO里程碑]** 主選單場景：MainMenu.tscn（深褐色背景、金色標題、開始按鈕）
- [2026-06-20] **[DEMO里程碑]** 持續客人生成（每 8 秒、上限 4 人、3 個隨機入口位置）
- [2026-06-20] **[DEMO里程碑]** 視窗 3x 縮放（480x270 → 1440x810，桌機可玩）
- [2026-06-20] HUD 初始狀態信號修復（啟動時即顯示 Year 1 Day 1 / $10000）
- [2026-06-20] headless 全程 0 ERROR 0 WARNING（含完整客人 AI 循環 log 驗證）
- [2026-06-20] .godot/imported 快取建立（90 件資源）

- [2026-06-20] DEMO 測試協議（三組平行審查）：測試員 + 數值驗證師 + UI/UX設計師，共發現 2 BUG + 1 BLOCK + 多項 WARN
- [2026-06-20] 修復：StaffAI「serve」任務走向桌子（外場員工送餐邏輯）
- [2026-06-20] 修復：complete_payment 改為僅標記 delivering 狀態訂單，防止多訂單誤清
- [2026-06-20] 修復：year 進位條件 30 → 90 天（與設計文件一致，Year 1 Q1-Q4 節奏恢復）
- [2026-06-20] 修復：IDLE_ANGRY_THRESHOLD 60 → 120 秒（DEMO 展示期間不觸發員工莫名憤怒）
- [2026-06-20] 修復：HUD 雙重讀檔（main.gd 移除多餘讀檔，唯一入口為 GameManager AutoLoad）
- [2026-06-20] 修復：存檔 key 名稱 current_year/current_day → year/day（讀檔後年份不再重置）
- [2026-06-20] 修復：save/load 補上 current_hour（時間不再每次讀檔重置為預設值）
- [2026-06-20] 修復：備用結帳金額 $150 → $160（接近三道示範菜均價）
- [2026-06-20] 修復：HUD 新增時段欄位（傍晚/晚上/宵夜/深夜/打烊）
- [2026-06-20] 修復：HUD 頂部背景色塊 #1A1A2E + 底部霓虹紅線
- [2026-06-20] 修復：日期格式改繁中「第 N 年 第 N 天」
- [2026-06-20] 修復：金錢飄字改掛獨立 CanvasLayer(layer=2)，不再被 HUD 遮住
- [2026-06-20] 修復：底部工具列動態建立（建造/擺桌/雇員/菜單四個快捷按鈕）
- [2026-06-20] 修復：build_ui.gd 觸控座標改用 get_screen_transform().affine_inverse()，縮放不偏移
- [2026-06-20] 修復：建造模式新增「╳ 離開」按鈕（enter/exit 時自動顯示/隱藏）
- [2026-06-20] 數值企劃：dishes.json 10 道菜成本同步 values.md（蔬菜 75%、肉類 60%、海鮮 50% 毛利率統一）
- [2026-06-20] P2 動畫：walk 4 幀循環（老闆娘/廚師/上班族）+ 外場小弟 idle/walk/端餐盤 + 廚師炒菜 6 幀

## 進行中
- （無）

- [2026-06-20] itch.io 素材生成：content\itch_cover.png（630x500）+ content\screenshot_01.png（480x270）

## 待辦（需使用者操作）
- [ ] 字體：下載 Fusion Pixel Font .ttf 放入 src/assets/fonts/（https://github.com/TakWolf/fusion-pixel-font/releases）
- [ ] 音樂：下載熱鬧台灣風 BGM（.ogg）放入 src/assets/audio/bgm/main_theme.ogg（建議 OpenGameArt.org）
- [ ] itch.io：封面圖和截圖已備妥（content\），照 content\itch-io-listing.md 建立頁面並上傳

## 待確認
- 無

## 已知問題
- 字體缺失：src/assets/fonts/ 只有 README.md，HUD 目前 fallback 系統字，需使用者下載 Fusion Pixel Font
- AudioManager BGM Bus 設為 "Master"，等實際音頻資源加入後確認
- 地板視覺目前用像素 Sprite2D（不是 TileMapLayer + TileSet），擴張地圖時需重構（技術債）
- 炒菜台座標硬編碼 Vector2(16,16)，地圖改動後需同步（技術債）

## 操作紀錄
- [2026-06-20] 新增遊戲專案資料夾：d:\開發遊戲\台灣熱炒王\
- [2026-06-20] 新增 src\assets\ui\ 目錄與 icon.png 佔位圖
- [2026-06-20] 新增 src\scenes\main_menu\ 目錄
- [2026-06-20] 生成 .godot\imported\ 快取（90 件資源）
- [2026-06-20] project.godot 主場景改為 MainMenu.tscn；視窗 scale=3.0
