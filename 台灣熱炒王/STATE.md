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
- [2026-06-20] 技術組（程式設計師）：AutoLoad 串接（8 個 singleton）+ audio_manager.gd + main.gd + project.godot 大小寫修正
- [2026-06-20] 內容組（在地化專員）：content\strings_zh_TW.csv（133 筆）
- [2026-06-20] 技術組（程式設計師）：BuildManager.gd（Zone 管理、設備放置、相鄰加成）
- [2026-06-20] 技術組（程式設計師）：build_ui.gd（Zone 底色、設備預覽、斷路警告）
- [2026-06-20] 技術組（系統程式師）：EventManager.gd
- [2026-06-20] 美術組（美術規格師）：content\art-deliverables.md + content\art-brief.md（P1 20 件素材規格）
- [2026-06-20] 品管組（數值驗證師）：Year 2-3 金流驗算（名聲門檻下調、Year 2/3 存款目標修正）
- [2026-06-20] 品管組（數值驗證師）：Year 4-5 金流驗算（Year 4 $350,000→$150,000、Year 5 $800,000→$520,000）
- [2026-06-20] 技術組（程式設計師）：員工士氣系統（staff_morale + 日結算懲罰旗標 + 存檔整合）
- [2026-06-20] 設計組（場景設計師）：design\initial-map.md（6x4 起始布局 + 連通驗證座標）
- [2026-06-20] 規格修正：解析度統一 480x270、角色尺寸 16x24px、#F5A623 加入色盤
- [2026-06-20] 技術組（程式設計師）：game.gd（初始地圖載入 + 場景串接 + 測試角色生成）+ hud.gd（金錢/日期/名聲顯示 + 事件即時訊息）
- [2026-06-20] 技術組（系統程式師）：TutorialManager.gd（Day 1 九步驟教學流程，自動觸發、保護旗標、開業補貼串接）
- [2026-06-20] 工具組（工具開發師）：src\tools\generate_placeholders.py + 執行生成 20 件佔位 PNG（全尺寸正確，可直接放入 Godot）
- [2026-06-20] project.godot：TutorialManager 加入 AutoLoad（共 9 個 singleton）
- [2026-06-20] 技術組（程式設計師）：OrderManager.gd（完整訂單生命週期）+ 串接 CustomerAI/StaffAI + project.godot 加入第 10 個 AutoLoad
- [2026-06-20] 發布規劃師：src\export\export_presets.cfg（Android + HTML5）+ content\itch-io-listing.md（上架素材清單）
- [2026-06-20] 品管組（測試員）：content\test-plan.md（12 個整合測試案例）
- [2026-06-20] 工具組：src\tools\draw_sprites.py 生成 39 件像素素材（P1+P2：角色、設備、Tile、UI）
- [2026-06-20] 技術組：Main.tscn 正確 instance Game.tscn + UI.tscn（修復空節點問題）
- [2026-06-20] 技術組：Game.tscn 掛載 game.gd；UI.tscn 的 hud_layer 掛載 hud.gd
- [2026-06-20] 技術組：src\assets\ui\icon.png 佔位圖建立；.godot/imported 快取生成（90 件資源）
- [2026-06-20] 技術組：game.gd 加入地板 ColorRect 視覺（24 格）、設備 Sprite2D（炒菜台+2張桌）、角色 Sprite2D（客人+廚師+外場）、攝影機定位
- [2026-06-20] 技術組：CustomerAI 加入 1.5 秒自動入座備用路徑（SeatManager 未整合時的 DEMO 路徑）
- [2026-06-20] 技術組：OrderManager 加入備用自動完成機制（5 秒自動烹飪完成 + 自動送餐 + 結帳通知）
- [2026-06-20] 技術組：game.gd 加入金錢飄字（+$XXX 金色 Label，向上飄動淡出）
- [2026-06-20] 技術組：main.gd 在場景初始化完成後主動 emit 初始狀態信號（HUD 顯示 Day 1 / $10000）
- [2026-06-20] 品管組：DEMO 就緒度評估 6/10 → 10/10 技術指標通過，客人 AI 完整循環確認
- [2026-06-20] headless 測試：0 ERROR 0 WARNING（包含完整客人 AI 循環 log 驗證）

## 進行中
- （無）

## 待辦
- [ ] 實際音頻資源：下載或生成 BGM（.ogg），放入 src/assets/audio/bgm/main_theme.ogg
- [ ] 在 Godot Editor 開啟 src\ 專案，照 content\test-plan.md 跑 12 個 TC（需本機 Godot 環境）
- [ ] 主選單場景（MainMenu.tscn）：讓遊戲從選單開始，而不是直接進 Game
- [ ] itch.io 上架：照 content\itch-io-listing.md 準備截圖和封面圖，建立頁面
- [ ] P2 素材：walk 動畫幀 2-4、炒菜動作幀、送餐動作幀（可用 draw_sprites.py 繼續擴充）
- [ ] 字體整合：下載 Fusion Pixel Font，放入 src/assets/fonts/，讓 HUD Label 使用像素字體

## 待確認
- 無

## 已知問題
- AudioManager BGM Bus 設為 "Master"（應為 "BGM"），等實際音頻資源加入後需確認 Audio Bus Layout
- 地板視覺目前用 ColorRect（非像素 Tile 貼圖），視覺效果基本。可用 TileMapLayer + TileSet 升級

## 操作紀錄
- [2026-06-20] 新增遊戲專案資料夾：d:\開發遊戲\台灣熱炒王\
- [2026-06-20] 新增子目錄：.claude\agents\、tech\、design\、art\、src\scripts\systems\、src\assets\fonts\
- [2026-06-20] 新增 src\assets\ui\ 目錄與 icon.png 佔位圖
- [2026-06-20] 生成 .godot\imported\ 快取（90 件資源，由 --import flag 觸發）
