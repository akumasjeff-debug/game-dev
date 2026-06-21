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
- [2026-06-20] 菜單加強：新增 menu_ui.gd（380x200 Panel，ScrollContainer 列表，ON/OFF 切換，點外部關閉）；MenuManager.gd 補 get_all_dishes()；hud.gd「菜單」按鈕接線，懶建立 MenuUI
- [2026-06-20] 故事加強：新增 opening_story.md（16 頁開場對話 + 8 個步驟過渡台詞 + Day1 收攤台詞）；dialog_ui.gd 監聽 TutorialManager.step_changed 在遊戲中顯示對話框；main_menu.gd 首次開始遊戲時播放開場故事（看過後存 user://opening_seen.flag 跳過）；UI.tscn 掛 dialog_ui.gd 腳本
- [2026-06-20] headless 驗證：0 ERROR 0 WARNING

- [2026-06-20] **[故事性大幅加強]** 內容組：content\events.md 追加 E020-E040（21個新事件，員工/常客/社區/食物/季節五大類，共增加約 4,200 字故事內容）
- [2026-06-20] **[故事性大幅加強]** 內容組：新建 content\year-endings.md（五年結局故事，每年 650-700 字，合計約 3,300 字，第二人稱台灣口語）
- [2026-06-20] **[故事性大幅加強]** 內容組：新建 content\staff-stories.md（阿龍師傅/老闆娘/阿弟三人三段式故事弧，含觸發台詞 45 條，約 2,000 字）
- [2026-06-20] **[故事性大幅加強]** 技術組：新建 src\scripts\systems\YearEndingManager.gd（年份結局顯示系統，AutoLoad，監聽 year_ended 信號，全螢幕對話框，打字機效果，淡入淡出）
- [2026-06-20] **[故事性大幅加強]** 技術組：EventManager.gd 新增 daily_quote_ready 信號 + 25 句每日語錄（四類：阿龍語錄/今日推薦/天氣吐槽/客人觀察）+ emit_daily_quote() 方法
- [2026-06-20] **[故事性大幅加強]** 技術組：hud.gd 加入語錄 Label，監聽 EventManager.daily_quote_ready，淡入 0.5s 停留 4s 淡出 1s
- [2026-06-20] **[故事性大幅加強]** 技術組：project.godot 加入 YearEndingManager AutoLoad
- [2026-06-20] **[故事性大幅加強]** 設計組：core-design.md 新增第七章「隨機事件情感節奏設計」（事件比例 40%危機/35%溫情/25%幽默、7天 Mood Arc、三層敘事架構、情感債機制、員工台詞觸發時機）
- [2026-06-20] **[故事性大幅加強]** 資料組：events.json 追加 event_020 到 event_040，現共 40 個事件
- [2026-06-20] headless 最終驗證：0 ERROR 0 WARNING，EventManager 載入 40 個事件，YearEndingManager 正常連接信號

## 進行中
- （無）

- [2026-06-20] itch.io 素材生成：content\itch_cover.png（630x500）+ content\screenshot_01.png（480x270）

## 視覺修整（2026-06-20）
- [2026-06-20] **[問題1修復]** UI Panel 中文字體：hud.gd 底部工具列四按鈕、_show_shop_panel 所有 Label/Button、_show_info_panel 所有 Label/Button、game.gd 金錢飄字 Label — 全部補上 Fusion Pixel 12px 繁中字體覆寫
- [2026-06-20] **[問題2修復]** 餐廳地圖縮小問題：game.gd _setup_camera() 加入 zoom=Vector2(3.5, 3.5)，Camera 對準地圖中心 Vector2(64, 48)，地圖從 96×64px 放大至約 336×224px 填滿 480×270 畫面
- [2026-06-20] headless 驗證：0 ERROR

## 核心體驗修整（2026-06-20）
- [2026-06-20] **[P0 修復]** 客人可見色塊：game.gd 改用 setup_visuals() 建立藍色身體 ColorRect（16x24）+ 皮膚色頭部 ColorRect（12x8），不再依賴可能缺失的外部貼圖
- [2026-06-20] **[P0 修復]** 客人生成位置修正：測試客人 Vector2(60,80) → Vector2(48,64)；SPAWN_POSITIONS 改為右側邊緣 [Vector2(80,64), Vector2(80,48), Vector2(80,72)]
- [2026-06-20] **[P1 修復]** 對話泡泡系統：customer_ai.gd 新增 setup_visuals() + _update_bubble()，依 FSM 狀態顯示 ？/ .../ ！/ ♥ / ╳
- [2026-06-20] **[P1 修復]** 烹飪進度條：staff_ai.gd 廚師 cook 任務中在炒菜台上方顯示橘色進度條（CanvasLayer layer=3，0%→100%）
- [2026-06-20] **[P1 修復]** 底部四按鈕全部接線：建造（設備選購 Panel）、擺桌（桌椅 Panel）、雇員（員工資訊 Panel）、菜單（MenuUI，修復 Node.new→script.new 型別問題）
- [2026-06-20] **[P2 修復]** 金錢飄字字型放大至 14px，位置改 Vector2(200,180) 避免被工具列遮住
- [2026-06-20] headless 驗證：0 ERROR 0 WARNING

## 全面品質提升三輪盤點（2026-06-20）
- [2026-06-20] **[P0 修復]** MenuManager 欄位映射：dishes.json 的 name_zh/base_price 映射為 name/price，unlocked 欄位依 unlock_year <= 1 自動初始化，解決菜單 UI 顯示「未知菜色 $0 全OFF」的問題
- [2026-06-20] **[P0 修復]** 客人點餐從 MenuManager 讀取，備用改為正確 ID（stir_fry_water_spinach/century_egg_tofu/three_cup_chicken）
- [2026-06-20] **[P1 修復]** SeatManager 整合：game.gd 放置設備後登記 4 個初始座位格；customer_ai.gd 進入 ENTERING 狀態時呼叫 _try_reserve_seat() 取得並預留座位，處理競爭條件（最多嘗試 8 次）
- [2026-06-20] **[P1 修復]** 客人 4 色區分：setup_visuals() 隨機從藍/粉紅/橘/黃 4 色選擇身體顏色
- [2026-06-20] **[P1 修復]** 對話泡泡改 ASCII：♥→:)、╳→X、！→!、…→...，避免字體不支援
- [2026-06-20] **[P1 修復]** WAITING 狀態每 3 秒重試找位，找到後重回 ENTERING
- [2026-06-20] **[P1 修復]** 教學對話框點擊推進：_advance_tutorial() 讀取當前步驟的 complete_condition，讓每次點擊都能正確推進任意步驟（含 on_door_opened 等非 on_screen_tapped 條件）
- [2026-06-20] **[P1 修復]** 移除 main.gd 的重複存檔（格式不完整且與 GameManager 存檔衝突）
- [2026-06-20] **[P1 修復]** 烹飪進度條位置修正：從 (16,12) 移到畫面中央 (200,38)，寬度 16→80px，加「烹飪中」標籤
- [2026-06-20] **[P1 修復]** HUD 標籤布局重排：金錢 x=6、日期 x=120、時段 x=330、聲望 x=410，避免重疊
- [2026-06-20] **[P1 修復]** 擺桌購買後真正新增座位到 SeatManager（掃描外場區空格子）
- [2026-06-20] **[P2 修復]** 箭頭符號 ▶ → >> 避免字體問題
- [2026-06-20] **[P2 修復]** 聲望顯示加入等級文字（新手/知名/名店/傳奇）
- [2026-06-20] **[P2 修復]** 金錢顯示千位分隔格式（$10,000）
- [2026-06-20] **[P2 修復]** 客人入座時身體色塊淡入閃爍效果（0.3 秒）
- [2026-06-20] **[P2 修復]** 開場立刻觸發每日語錄（不需等待 17:00 day_started 信號）
- [2026-06-20] **[P2 修復]** 結帳金額改讀菜品實際 price/base_price，不再固定 $160
- [2026-06-20] headless 最終驗證：6 輪全部 0 ERROR 0 WARNING

## 五輪全面優化（2026-06-20）
- [2026-06-20] **[第一輪]** 客人頭頂等待條：patience 進度條（16x2px，綠/黃/紅三段色），WAITING/EATING 等餐顯示，收到食物後隱藏
- [2026-06-20] **[第一輪]** 金錢不足閃紅：購買失敗時金額 Label 閃紅 Tween（0.1s 紅→0.3s 白）
- [2026-06-20] **[第一輪]** 打烊停止生客：is_open=false 且超過 5 分鐘寬限期後停止生成客人，重置計時器避免開業衝客
- [2026-06-20] **[第二輪]** 每日結算面板：day_ended 信號觸發全屏半透明面板（今日收入 + 繼續按鈕，CanvasLayer layer=8）
- [2026-06-20] **[第二輪]** 時間顯示升級：HUD 時段從「傍晚/晚上」改為「18:00 晚上」格式
- [2026-06-20] **[第二輪]** 聲望等級顏色化：新手白/知名橘/名店金/傳奇紅，動態更新 Label 顏色
- [2026-06-20] **[第三輪]** BGM 合成：Python wave 模組生成五聲音階台灣風旋律（main_theme.wav），game.gd 優先找 .wav
- [2026-06-20] **[第三輪]** 音效生成：coin/customer_enter/customer_happy/customer_angry/cook_done（共 5 個 .wav）
- [2026-06-20] **[第三輪]** 開張台詞：第一筆收款（>=50元）觸發 first_payment_received 信號，HUD 顯示「阿龍說：第一桌，開張了！」5 秒
- [2026-06-20] **[第四輪]** 客人入場淡入動畫：生成時下移 8px 並透明，0.5 秒 Tween 上移還原並淡入
- [2026-06-20] **[第四輪]** 桌上食物視覺：receive_food 後在客人腳部顯示橘色 6x6 圓點，離場後清理
- [2026-06-20] **[第四輪]** 教學對話框修復：_dialog_bg.gui_input 事件連接修復，點擊對話框任意位置可推進
- [2026-06-20] **[第五輪]** 音效串接：客人入座/滿意/憤怒/付款離場 + 廚師炒菜完成，共 5 個事件點播放對應音效
- [2026-06-20] **[第五輪]** 菜單首次提示：第一次開啟菜單顯示「選幾道你有把握的菜，菜色太多會來不及出菜！」提示
- [2026-06-20] **[第五輪]** SeatManager 防呆：座位清單為空時直接回傳 (-1,-1) + warning，防止空迴圈
- [2026-06-20] **[第五輪]** 結帳防重複：OrderManager.complete_payment 已完成訂單重複觸發時 warning + return，不重複加錢
- [2026-06-20] **[五輪]** headless 最終驗證：五輪全部 0 ERROR 0 WARNING

## 再五輪全面優化（2026-06-20）

### 第一輪：時間系統修復 + 畫面下半部
- [2026-06-20] **[時間修復]** game_manager.gd：初始 current_hour 從 8.0 改為 17.0，遊戲啟動即進入營業時段
- [2026-06-20] **[時間修復]** hud.gd：_get_time_period() 加入明確的打烊條件（2<=h<17），原 else 改為防禦性 "未知"
- [2026-06-20] **[外場視覺]** game.gd：新增 _draw_zone_colored_floor()，用 ColorRect 繪製廚房深灰/走道中灰/外場暖棕三區地板
- [2026-06-20] **[外場視覺]** game.gd：新增 _draw_table_visuals()，桌A/桌B 各加 30x20 米色桌面 ColorRect
- [2026-06-20] **[外場視覺]** game.gd：新增 _draw_zone_divider()，走道/外場交界 y=63px 加橘色分隔線（96x2）
- [2026-06-20] **[動畫]** customer_ai.gd：入座從瞬間 teleport 改為 0.8 秒 Tween 平滑移動到座位，移動完才轉 EATING 狀態

### 第二輪：遊戲節奏 + 成長感
- [2026-06-20] **[薪水]** hud.gd：_on_day_started() 加入每日扣薪 $1,400（廚師 $800 + 外場 $600），新增 _show_salary_popup() 顯示紅色飄字
- [2026-06-20] **[薪水防呆]** hud.gd：spend_money 回傳 false（金錢不足）時呼叫 reduce_staff_morale(20) 並顯示「資金不足，員工士氣 -20！」
- [2026-06-20] **[名聲]** customer_ai.gd：滿意離場 add_reputation(1)，生氣離場 reduce_reputation(1)
- [2026-06-20] **[名聲]** hud.gd：_on_reputation_changed() 末尾加 Tween 閃爍效果（0.15s 亮黃→0.3s 回白）
- [2026-06-20] **[解鎖提示]** hud.gd：聲望達到 10 時顯示「解鎖新菜色！」綠色橫幅（3秒淡出，只觸發一次）

### 第三輪：UI/UX 精緻化
- [2026-06-20] **[工具列]** hud.gd：_build_toolbar() 四個按鈕各加 6x12 色塊圖示（建造橘/擺桌褐/雇員藍/菜單綠）
- [2026-06-20] **[跳過鍵]** dialog_ui.gd：_build_dialog() 末尾加「跳過」按鈕，點擊呼叫 TutorialManager._on_day1_complete()
- [2026-06-20] **[結算強化]** hud.gd：結算面板加薪水支出行（紅色 -$1,400）+ 今日淨利行（正綠負紅），面板高度 100→130
- [2026-06-20] **[事件UI]** EventManager.gd：新增 show_event_choice(event_data) 函式，建立 layer=6 選擇面板（事件說明+A/B按鈕）
- [2026-06-20] **[事件UI]** hud.gd：_on_event_triggered() 末尾若事件有選項則呼叫 em.show_event_choice()

### 第四輪：穩定性 + 邊緣案例
- [2026-06-20] **[零桌防呆]** hud.gd：_on_menu_btn_pressed() 開頭偵測 SeatManager 空桌，顯示提示並閃爍擺桌按鈕
- [2026-06-20] **[零桌防呆]** hud.gd：保存擺桌按鈕引用 _table_btn，新增 _flash_table_btn() 黃色閃爍 2 次
- [2026-06-20] **[菜色全關]** customer_ai.gd：_place_order() 區分 MM 不存在（備用菜色）vs MM 存在但菜色全鎖（客人立刻 LEAVING）
- [2026-06-20] **[AI超時]** customer_ai.gd：ANGRY/LEAVING 備用計時器啟動時加 log 確認
- [2026-06-20] **[記憶體]** main.gd：場景切換前後加 characters 子節點計數 log 確認無殘留

### 最終驗證
- [2026-06-20] **[五輪整合]** headless 最終驗證：0 ERROR 0 WARNING，30道菜/40個事件/7個AutoLoad全數正常初始化

## 十輪全面優化（2026-06-20）

### 第1輪：修亂碼 + 薪水時機
- [2026-06-20] **[亂碼修復]** staff_ai.gd：_create_cook_bar() 加 ResourceLoader.exists() 字體防禦檢查，無字體時顯示 ASCII "cooking" 避免亂碼
- [2026-06-20] **[薪水時機]** game_manager.gd：_initialize_default_state() 和 apply_save_data() 中 current_hour 從 17.0 改為 17.5，避免首幀觸發 day_started 立即扣薪

### 第2輪：外場桌椅視覺
- [2026-06-20] **[桌椅強化]** game.gd：_draw_table_visuals() 每張桌加深褐色邊框（32x22）+ 上下各一紅色椅子（10x8）
- [2026-06-20] **[食物視覺]** customer_ai.gd：_show_food_on_table() 圓點改為 12x8 橘色小碗（原 6x6），位置 Vector2(-6, 4)

### 第3輪：廚房視覺整理
- [2026-06-20] **[廚師色塊]** game.gd：_spawn_test_staff() 加廚師三層 ColorRect（白色廚師服 14x20 + 膚色頭 10x6 + 白帽 12x4）、外場兩層（深色服 14x20 + 膚色頭）
- [2026-06-20] **[設備視覺]** game.gd：_draw_equipment_visuals() 炒菜台改 ColorRect（深灰底 32x24 + 亮灰鍋 20x14）+ 標籤，出菜台中灰 ColorRect，桌 Sprite2D 加 ResourceLoader 防禦

### 第4輪：客人AI流程視覺化
- [2026-06-20] **[進場方向]** customer_ai.gd：play_entrance_animation() 改從右方 +8px 淡入並向左移動，符合右側入口
- [2026-06-20] **[滿意圓點]** customer_ai.gd：SATISFIED 狀態加 _show_satisfied_dot()，頭頂顯示 8x8 粉紅色點 1.5s 後淡出

### 第5輪：時間系統 + 一天節奏
- [2026-06-20] **[時段訊息]** game_manager.gd：新增 hour_milestone_reached 信號，17:00 發「開門！熱炒王正式營業」、22:00 發「宵夜時段」、打烊發「今天打烊了」
- [2026-06-20] **[HUD監聽]** hud.gd：_on_hour_milestone() 依 17/22/26 顯示橘/藍紫/灰色 3 秒訊息

### 第6輪：菜色系統深化
- [2026-06-20] **[菜色鎖定]** MenuManager.gd：三杯雞（聲望10）/炒蛤蜊（聲望15）/薑絲大腸（聲望20）明確初始鎖定，已解鎖 7 道
- [2026-06-20] **[解鎖信號]** MenuManager.gd：新增 dish_unlocked 信號，unlock_dish() 觸發時發出
- [2026-06-20] **[鎖定顯示]** menu_ui.gd：locked 菜色顯示「[鎖] 菜名 聲望N解鎖」灰色，不可點擊
- [2026-06-20] **[解鎖特效]** hud.gd：_on_dish_unlocked() 全螢幕橘色閃光（layer=9）+ 橫幅通知

### 第7輪：音效/BGM整合
- [2026-06-20] **[音量設定]** audio_manager.gd：BGM 音量 0.6，音效音量 0.8；新增 fade_bgm(target, duration) 函式
- [2026-06-20] **[開門音效]** game_manager.gd：_on_day_started() 播放 customer_enter.wav
- [2026-06-20] **[打烊淡出]** game_manager.gd：_on_day_ended() 呼叫 fade_bgm(0.2, 2.0)

### 第8輪：事件系統真正觸發
- [2026-06-20] **[自動觸發]** EventManager.gd：_on_day_ended() 呼叫 _auto_trigger_daily_event()，每日打烊後延遲 1 秒觸發符合條件的隨機事件
- [2026-06-20] **[選擇回饋]** EventManager.gd：apply_option() 後組建回饋字串（金錢/名聲/custom），透過 HUD 群組顯示 4 秒
- [2026-06-20] **[7天冷卻]** EventManager.gd：_event_last_triggered_day 字典記錄觸發天數，同一事件 7 天內不重複
- [2026-06-20] **[HUD群組]** hud.gd：_ready() 加入 add_to_group("hud")

### 第9輪：HUD資訊架構優化
- [2026-06-20] **[時段位置]** hud.gd：_time_label.position.x 從 330 改為 310，確保不與聲望欄重疊
- [2026-06-20] **[金錢動畫]** hud.gd：_on_money_changed() 加 meta 追蹤前值，增加金色閃光/減少紅色閃光（0.5s Tween）
- [2026-06-20] **[聲望進度條]** hud.gd：聲望 Label 下方加 30x3px 進度條，顯示到下一級的進度
- [2026-06-20] **[訊息佇列]** hud.gd：_show_message() 改為佇列機制，多訊息排隊不重疊

### 第10輪：整體 Polish
- [2026-06-20] **[開場暫停]** main_menu.gd：開場故事期間 GameManager.pause_time()，結束後 resume_time()
- [2026-06-20] **[場景淡入]** main.gd：新增 _fade_in_scene()，進入 Main.tscn 時 0.5 秒黑色淡入（layer=10）
- [2026-06-20] **[客人上限]** game.gd：MAX_CUSTOMERS 4 → 6
- [2026-06-20] **[Tutorial清理]** dialog_ui.gd：_on_tutorial_complete() 加 _dialog_bg.queue_free()，確保對話框節點完整移除
- [2026-06-20] **[版本號]** main_menu.gd：v0.1 DEMO → v0.7 DEMO

### 最終驗證
- [2026-06-20] **[十輪整合]** headless 最終驗證：0 ERROR 0 WARNING，30道菜（已解鎖7道）/40個事件/7個AutoLoad全數正常初始化

## 再十輪全面優化（2026-06-20，v0.7.0 Playwright 截圖問題修復）

### 第1輪：Camera zoom 修正
- [2026-06-20] **[視野修復]** game.gd：Camera zoom 從 3.5 改為 2.2，position 從 (64,48) 改為 (56,44)，讓廚房+外場整體入鏡，客人不再佔螢幕 1/3 高度

### 第2輪：外場燈泡裝飾
- [2026-06-20] **[視覺強化]** game.gd：新增 _draw_dining_area_lights()，在分隔線上方繪製 7 個暖白色燈泡（4x4px，間隔 12px），模擬外場吊燈氛圍

### 第3輪：薪水時機徹底修復
- [2026-06-20] **[薪水修復]** hud.gd：_on_day_started() 加入 Year 1 Day 1 免扣薪邏輯，開業第一天不扣薪水，確保初始 $10,000 完整
- [2026-06-20] **[薪水修復]** game_manager.gd：apply_save_data() 強制 current_hour=17.5，防止讀存檔後下一幀觸發 day_started 立即扣薪

### 第4輪：教學對話框推進修復
- [2026-06-20] **[教學修復]** dialog_ui.gd：_advance_tutorial() 移除 on_screen_tapped 限制，所有步驟條件都允許玩家點擊對話框手動推進，教學不再卡住

### 第5輪：烹飪進度條位置調整
- [2026-06-20] **[UI修復]** staff_ai.gd：_create_cook_bar() 的 BAR_X 從 200 改為 120（靠廚房左側），BAR_Y 從 38 改為 32，視覺更合理

### 第6輪：低錢警告
- [2026-06-20] **[UX強化]** hud.gd：_on_money_changed() 加入低錢警告，金錢 < $3,000 時 HUD 金錢文字持續顯示紅色

### 第7輪：結算面板加食材成本
- [2026-06-20] **[結算強化]** hud.gd：_show_day_summary_panel() 新增「食材成本」行（收入 * 30%），淨利計算扣除薪水+食材，面板高度 130→150

### 第8輪：霓虹感 Polish
- [2026-06-20] **[視覺polish]** game.gd：新增 _draw_neon_sign()，在廚房上方繪製「阿嬤熱炒」橘紅色招牌（64x12 深色背景）
- [2026-06-20] **[視覺polish]** hud.gd：工具列四個按鈕加 font_hover_color 橘色 hover 效果

### 第9輪：速度控制 + 暫停
- [2026-06-20] **[新功能]** hud.gd：右上角新增速度按鈕（>> x1/x2/x3 循環）+ 暫停按鈕（|| / >|），控制 GameManager.time_scale
- [2026-06-20] **[新功能]** hud.gd：暫停時中央顯示「已暫停」overlay（CanvasLayer layer=10），Esc 鍵 toggle 暫停
- [2026-06-20] **[調整]** hud.gd：聲望 Label 從 x=410 左移至 x=382，騰出右上角空間給速度控制按鈕

### 第10輪：存檔系統啟用
- [2026-06-20] **[存檔]** main_menu.gd：存檔存在時顯示綠色「繼續遊戲」按鈕，點擊直接跳轉 Main.tscn

### 最終驗證
- [2026-06-20] **[再十輪整合]** headless 最終驗證：0 ERROR 0 WARNING

## 再十輪視覺強化（2026-06-20，v0.9 DEMO）

### 第1輪：Camera + 視野優化
- [2026-06-20] **[視野]** game.gd：Camera zoom 2.2→2.5，position (56,44)→(60,50)，建築整體可視，人物比例合理

### 第2輪：廚師視覺重做
- [2026-06-20] **[廚師]** game.gd：廚師身體 14×20 白色→10×18 深藍廚師服 Color(0.1,0.22,0.42)；廚師帽 12×4→8×4 灰白（帽寬 8 ≤ 頭寬 10）；廚師頭膚色加深；新增左右手臂 3×6px；外場員工身體縮為 10×18px

### 第3輪：廚房視覺強化
- [2026-06-20] **[廚房]** game.gd：廚房後壁基線深灰橫條；炒菜台改深棕台面+亮灰鍋+橘色火焰 2 個；收銀台改木棕+收銀機螢幕深藍綠；炒菜台標籤上移

### 第4輪：外場視覺重做
- [2026-06-20] **[外場]** game.gd：外場地板加亮至 Color(0.35,0.26,0.16)；廚房地板加深至 Color(0.16,0.14,0.18)；新增磁磚縫線 6 條；桌子擴增為 3 張（tile 2,4 / 4,4 / 6,4）；桌面改亮米色、椅子改台灣紅

### 第5輪：客人視覺精緻化
- [2026-06-20] **[客人]** customer_ai.gd：身體 16×24→10×14px；頭部 12×8→8×7px；新增頭髮 ColorRect 8×3px（4種：黑/褐/灰白/深棕）；耐心條位置調整貼近頭頂

### 第6輪：霓虹夜市氛圍
- [2026-06-20] **[霓虹]** game.gd：招牌加紅色外框+深紫背景；外場燈泡改為 5 顆 5×5px 均勻分布，每顆加光暈；橘色地面反光條

### 第7輪：動態效果加強
- [2026-06-20] **[動態]** game.gd：招牌 sin 波閃爍（0.85±0.15，頻率 2.1Hz）；hud.gd：聲望增加觸發白色 CanvasLayer layer=5 閃光 0.3s 淡出

### 第8輪：UI 精緻化
- [2026-06-20] **[UI]** hud.gd：HUD 頂部背景改深紫藍 Color(0.07,0.03,0.15)；霓虹線改亮橘；工具列背景改深紫藍；按鈕加 StyleBoxFlat hover 橘色底；結算面板改深夜藍+橘色邊框

### 第9輪：佈局優化
- [2026-06-20] **[佈局]** game.gd：走道分隔線上下各加 2px 深色陰影；廚師站位改 Vector2(20,36)、外場員工改 Vector2(56,72)

### 第10輪：Polish + 版本號
- [2026-06-20] **[Polish]** 確認無 debug ColorRect；廚師帽 8×4 符合規格（≤頭寬 10px）；stretch mode canvas_items 確認；main_menu.gd 版本號 v0.7→v0.9 DEMO

### 最終驗證
- [2026-06-20] **[十輪整合]** headless 最終驗證：0 ERROR 0 WARNING，30道菜/40個事件/7個AutoLoad正常

## 再十輪視覺優化（v0.9.1 → v1.0，2026-06-21）

### 第1輪：廚師 sprite 修正
- [2026-06-21] **[廚師 sprite]** game.gd：char_chef_idle.png Sprite2D 加 z_index=2（確保在 ColorRect 之上）、scale=1.5（放大 1.5x）、position.y 從 -12 改為 -5（腳部對齊節點原點）

### 第2輪：Kenney 客人 sprite 一致性
- [2026-06-21] **[客人 sprite]** customer_ai.gd：加入靜態快取 `_kenney_tex_cache`，改用 `CustomerAI._get_kenney_texture()` 只載入一次；Sprite2D 加 z_index=2、scale=1.5；PIL 確認 x=408 y=0/17/34/51 均有 136-141 非透明像素，座標正確

### 第3輪：客人出現區域
- [2026-06-21] **[外場限制]** game.gd：SPAWN_POSITIONS 中 y=48（走道區）改為 y=68（外場內），三個進入點全部在 y=64~72 的外場範圍

### 第4輪：「烹飪中」位置修正
- [2026-06-21] **[進度條]** staff_ai.gd：BAR_X 從 120 改為 100、BAR_Y 從 32 改為 80（根據廚師世界座標換算螢幕位置）；「烹飪中」Label 改為進度條正上方 12px（垂直排列替代原本左側排列）

### 第5輪：招牌左側藍色方塊修正
- [2026-06-21] **[招牌]** game.gd：sign_border 從 x=15 改為 x=16，確保左側不截斷；sign_label 改為明確設定 size=(70,14) 並 horizontal_alignment=CENTER；加 StyleBoxEmpty 移除 Label 預設背景，消除藍色視覺噪音

### 第6輪：外場亮度提升
- [2026-06-21] **[外場]** game.gd：外場地板顏色從 Color(0.35,0.26,0.16) 改為 Color(0.42,0.30,0.18)（更明亮的暖棕）；_draw_dining_area_lights() 新增 3 個地面燈光（8×8 暖黃燈泡 + 20×30 透明光暈），均勻分布在外場

### 第7-9輪：動畫確認
- [2026-06-21] **[動畫確認]** PIL 確認 char_chef_idle.png (16x24, 148非透明px)；chef_cook_f1-f6 均為 16x24px 有效（150-158 非透明px）；動畫幀切換邏輯在 staff_ai.gd _tick_animation() 已正確實作（WORKING→cook 6幀 8FPS）；Kenney tilemap 人物座標 x=408 y=0/17/34/51 確認正確，無需更新

### 第10輪：清理 + 版本號
- [2026-06-21] **[清理]** customer_ai.gd：移除 13 個 debug print；staff_ai.gd：移除 3 個 debug print；game.gd：移除 20 個 debug print（push_warning 保留）
- [2026-06-21] **[版本號]** main_menu.gd：v0.9 DEMO → v1.0 DEMO
- [2026-06-21] **[驗證]** 所有 Sprite2D 確認有 TEXTURE_FILTER_NEAREST；headless 最終驗證 0 ERROR 0 WARNING

## 二十輪全面優化（2026-06-21，v1.0 → v1.1 DEMO）

### 輪1：Sprite 顯示修復
- customer_ai.gd _tick_animation() 加 ResourceLoader.exists() 防呆，只在幀號變更時 load
- staff_ai.gd _tick_animation() 全部 load 呼叫加防呆

### 輪2：客人行為循環
- customer_ai.gd _process_leaving() 加入向右移動視覺
- _place_order() 改為點 1-3 道菜，總價存 meta
- _on_leaving_complete() 結帳改從 meta 取總價

### 輪3：員工 AI
- staff_ai.gd 廚師佇列上限 2 個任務
- _complete_current_task() cook 分支加 _show_deliver_popup() 飄字

### 輪4：數值平衡
- dishes.json 6 道菜調漲定價
- 客人生成間隔 8→6 秒，上限 4→8 人

### 輪5：升級系統
- game_manager.gd 加入 upgrade_points（每 $1000 得 1 點）
- hud.gd 工具列第 5 個按鈕「升級」，含升級面板

### 輪6：事件完整化
- EventManager.gd apply_option 後呼叫 _resume_game_if_idle()
- _flush_queue() pause_time 改 null 安全

### 輪7：年度目標
- YearEndingManager.gd 加入年度目標面板 + confetti 動畫

### 輪8：音效整合
- 生成 order.wav、level_up.wav
- customer_ai.gd 下單時播放 order.wav

### 輪9：主選單強化
- main_menu.gd 加窗戶燈光、霓虹招牌、路人動畫（2個 Tween 路人）

### 輪10：Tutorial 修復
- dialog_ui.gd 步驟1自動 3 秒推進
- 所有步驟點擊均可推進

### 輪11：外場視覺
- game.gd _draw_dining_extra_decor()：菜單白板、電風扇、牆壁邊框

### 輪12：廚房視覺
- game.gd _draw_kitchen_extra_decor()：證書、調料架、磁磚縫、排煙管

### 輪13：客人多樣化
- customer_ai.gd 4種客人不同耐心值（20/30/60/90秒）和消費倍率
- 聲望依滿意度：+1（正常）/ +2（快速）/ -1（憤怒離場）

### 輪14：存檔完整化
- main_menu.gd 繼續遊戲前驗證存檔，損壞自動重置

### 輪15：效能優化
- game.gd 客人計數改 get_nodes_in_group
- customer_ai.gd 耐心條只在值變化 >0.1px 時更新

### 輪16：內容擴充
- events.json 加入 3 個節日事件（中秋/尾牙/農曆新年），共 43 個事件

### 輪17：UI 打磨
- hud.gd 速度/暫停按鈕加大（touch 區域更大）：速度 42x16→48x18，暫停 20x16→24x18

### 輪18：錯誤處理
- hud.gd 加入 log_game_error() 方法（錯誤計數，3次觸發 HUD 警告）
- OrderManager place_order 加入空值防呆（customer_id/dish_id 為空時 warning+return）

### 輪19：視覺特效
- staff_ai.gd 廚師烹飪時每 0.5s 生成冒煙粒子（白色 4x4 ColorRect，向上飄移 20px/0.8s 淡出）
- customer_ai.gd 進場光暈效果（淡黃色 20x20 ColorRect，alpha 0.3→0 / 0.3s）
- game.gd 金錢飄字改為 40px/1.5s（原 30px/1.0s，更顯眼）

### 輪20：版本號
- main_menu.gd v1.0 DEMO → v1.1 DEMO
- [2026-06-21] 最終 headless 驗證：0 ERROR 0 WARNING

## 待辦（需使用者操作）
- [ ] 字體：下載 Fusion Pixel Font .ttf 放入 src/assets/fonts/（https://github.com/TakWolf/fusion-pixel-font/releases）
- [ ] itch.io：封面圖和截圖已備妥（content\），照 content\itch-io-listing.md 建立頁面並上傳

## 待確認
- 無

## 已知問題（v1.1）
- 字體缺失：src/assets/fonts/ 只有 README.md，HUD 目前 fallback 系統字，需使用者下載 Fusion Pixel Font
- BGM/音效為 Python 合成正弦波，可玩性 OK 但音質簡單；可後續替換為真實音源
- 地板視覺目前用像素 Sprite2D（不是 TileMapLayer + TileSet），擴張地圖時需重構（技術債）
- 炒菜台座標硬編碼 Vector2(16,16)（技術債）
- Tutorial 步驟 2-9 的自動推進依賴遊戲事件信號，部分信號尚未與 TutorialManager 完整連接（步驟目前需手動點擊推進）

## 操作紀錄
- [2026-06-20] 新增遊戲專案資料夾：d:\開發遊戲\台灣熱炒王\
- [2026-06-20] 新增 src\assets\ui\ 目錄與 icon.png 佔位圖
- [2026-06-20] 新增 src\scenes\main_menu\ 目錄
- [2026-06-20] 生成 .godot\imported\ 快取（90 件資源）
- [2026-06-20] project.godot 主場景改為 MainMenu.tscn；視窗 scale=3.0
- [2026-06-20] 新增 src\assets\audio\bgm\main_theme.wav（Python 合成台灣五聲音階旋律）
- [2026-06-20] 新增 src\assets\audio\sfx\ 目錄，5 個音效：coin/customer_enter/customer_happy/customer_angry/cook_done
