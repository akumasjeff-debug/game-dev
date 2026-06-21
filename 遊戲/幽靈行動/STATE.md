# 幽靈行動 狀態

## 已完成
- **抽卡系統平衡調整（2026-06-21）**
  - save_manager.gd：稀有度倍率 r×0.3 → r×0.2（SSR 從 1.6 降至 1.4）
  - gacha_manager.gd：金票備份 x2、SSR 溢出補償從「+50 金幣」改為「+1 藍票」，pull() 傳 ticket_type 給 _apply_result
  - gacha_panel.gd：SSR 補償顯示文字更新為「（已達 SSR）+1 藍色票」
  - upgrade_panel.gd：每個職業卡片新增「已解鎖決策：」說明行，有解鎖呈綠色，未解鎖呈灰色
  - decision_panel.gd：加入 _get_squad_rarity / _build_rarity_options，room 決策動態加入 8 種稀有度選項（盾牆壓制/爆發射擊/側翼突破/目標標記/定向炸藥/急救注射/煙幕掩護/舉盾突入），並在 _apply_decision_effect 實作對應效果
  - headless 測試：exit 0，無 ERROR ✓ 2026-06-21
- **抽卡系統全面重構（2026-06-21）**
  - gacha_manager.gd：重寫為 6 職業等機率（各 16.67%），移除 SR/R/N 階層，保底改為「連 6 抽無新角色強制給未解鎖職業」
  - save_manager.gd：移除 character_fragments，新增 character_rarity/character_copies；新增 get_rarity_multiplier/get_level_multiplier/try_upgrade_rarity/try_level_up/copies_needed_for_rarity_up/coins_needed_for_level_up 6 個函數；存讀檔同步更新
  - upgrade_panel.gd + UpgradePanel.tscn：全新升級管理面板，列出 6 職業稀有度/備份數/等級，支援提升稀有度（2 備份）與金幣升等（level×150）
  - gacha_panel.gd：機率說明改為均等文字，抽卡結果改為備份/首解/SSR轉幣三態顯示，底部改為稀有度總覽
  - base.gd：職業按鈕加稀有度後綴（SR/SSR）與對應邊框顏色，新增「升級管理」按鈕
  - main.gd：_spawn_squad() 套用稀有度乘率×等級乘率數值公式
  - headless 測試：exit 0，無 ERROR ✓ 2026-06-21
- **抽卡系統完整實作（2026-06-21，已被上方重構取代）**
  - gacha_manager.gd：SR/R/N 三稀有度、藍/金雙卡池、軟保底(10抽 R+)、硬保底(50抽 SR)、碎片系統
  - gacha_panel.gd + GachaPanel.tscn：招募中心 UI，程序生成，CanvasLayer layer=15
  - save_manager.gd：新增 blue_tickets/gold_tickets/character_fragments/owned_characters 欄位及存讀檔
  - base.gd：頂欄票券顯示、招募中心按鈕、未解鎖角色鎖定顯示
  - decision_panel.gd：補給箱 "card" 分支給予 1 張藍票
  - main.gd：任務完成給票（demo_01 給金票，其他給藍票）
  - project.godot：GachaManager 加入 autoload
  - headless 測試：exit 0，無 ERROR ✓
- GDD v2.1 完成（第 6 職業「偵察手 Recon」設計定案，隊伍選人機制從「5 人固定」調整為「6 選 4」）
- 職業設計定案：6 職業（盾兵/醫療兵/突擊手/狙擊手/爆破手/偵察手），各對應不同大招類型；偵察手為 CC 控制型，大招煙霧封鎖使敵人攻擊失效 5 秒，CD 35 秒
- GDD v2.0 完成（全新設計，重新定案為戰術指揮+Idle+抽卡）
- 職業設計定案（初版）：5 職業（盾兵/醫療兵/突擊手/狙擊手/爆破手），各對應不同大招類型
- 大招系統設計完成：點卡片施放、各自 CD、升級縮 CD+提升效果
- 破門改為盾兵專屬技能（Lv.9），解鎖特定任務隱藏事件，非主軸機制
- GDD 參考對象更新：FTL 取代「破門清房」
- **P0 核心原型建立完成**：Godot 4 專案 src/ 目錄，headless 測試通過（exit 0, 無 ERROR）✓ 2026-06-21
  - 小隊自動推進（5 人隊形 + waypoint 路徑跟隨）
  - 決策點觸發機制（Area2D → 暫停 → 面板 → 繼續）
  - 2 種決策點：房間（直衝/靜悄/炸彈）、補給箱（補血/炸彈/抽卡券）
  - 大招 HUD：5 張角色卡 + CD 倒數 + 點擊施放
  - 勝負判定 + 結算畫面 + 重試按鈕
  - DecisionPanel 修正為 CanvasLayer（layer=10），UI 不受場景縮放影響

## 已完成（分鏡全畫面升級，2026-06-21）
- **體力值系統**：save_manager.gd 加 stamina/max_stamina（初始 10/10），spend_stamina()，存讀檔完整
- **基地體力 HUD**：base.gd 頂欄新增「體力：N/10」綠色顯示，出發前先扣體力
- **陣容確認面板**：新增 SquadConfirmPanel.tscn（CanvasLayer layer=8）+ squad_confirm_panel.gd
  - 4 槽位橫排，大角色頭像、名稱+稀有度+等級、HP/ATK/DEF 數值、大招說明
  - 龍躐式（▲▼上下滑動）切換角色
  - 「確認出發」→ 2 秒開場動廊（暗幕 + 任務標題）→ 進戰場
  - Bug 修正：SquadConfirmPanel 加到 root 後需在 _launch_mission() 呼叫 queue_free() 才會隨場景切換消失
- **戰鬥結算電影感**：hud.gd 升級
  - 勝利：1.5 秒金幣 count-up 動畫（0→200），Tween.tween_method
  - 失敗：0.5 秒電影感延遲，給 30 安慰金幣，「重試任務」按鈕
- **決策面板橫向按鈕**：DecisionPanel.tscn 面板寬度從 680 升至 1000px，ButtonsContainer 從 VBoxContainer 改為 HBoxContainer，按鈕 280×120，均分空間，加得失評估提示
- **GACHA 翻牌動畫**：gacha_panel.gd 加 Tween 翻牌（scale.x: 1→0→1），卡背「？？？」→ 角色揭示，SSR 金色閃爍，重複角色顯示「備份 +1（已 X 張）」
- **升級管理強化**：upgrade_panel.gd 加 BASE_STATS + POTENTIAL_UNLOCK 常數，每角色卡顯示實際數值（HP/ATK/DEF）、每升幅說明「各項數值 +2%」、Lv.10 潛能解鎖（灰色/金色雙態）
- **Playwright 全流程驗證**：基地→陣容確認→開場動廊→戰場完整顯示，TCG 卡片 4 張全部綠框就緒 ✓ 2026-06-21

## 進行中
- 無

## 待辦

### P0 ✅ 完成
### P1 ✅ 完成（2026-06-21）
### 抽卡系統 ✅ 完成（2026-06-21）
### P2 ✅ 完成（2026-06-21）

### Demo 閉環修正 ✅ 全部完成（2026-06-21）
1. ✅ 偵察手 characters.json 資料 — 已存在，無需修正
2. ✅ HUD 4 人動態初始化 — 已確認 setup_cards() 按 squad.size() 動態建立，無需修正
3. ✅ 突擊手大招攻擊倍率接入 charge 傷害 — 修正邏輯：atk_mult 讓進場傷害降低（反比），而非讓玩家受傷加重
4. ✅ Boss 決策點 — 實作 _create_boss_decision_trigger + 3 個選項（直衝/側翼/引誘），觸發 trigger_game_over(true)
5. ✅ 任務結算金幣入帳 — hud.gd _on_game_won 整合給幣+給票，main.gd 終點觸發改為純粹 trigger_game_over

### 數值平衡修正 ✅ 全部完成（2026-06-21）
6. ✅ 狙擊手 CD：main.gd CHAR_DATA 從 50.0 改為 35.0
7. ✅ 狙擊手大招：character.gd 改為「目標 HP < 25% 瞬殺，否則 300% ATK 傷害」邏輯
8. ✅ 偵察手情報：decision_panel.gd _populate() 在 room 決策顯示「偵察手情報：X 名敵人」
9. ✅ 每職業限一名：base.gd _on_class_toggled 已有 char_id in selected 防護，無需額外修改

### Demo 後（不阻擋發布）
- 職業顏色規範統一（解決 base.gd 橙色盾兵 vs ROADMAP 藍色盾兵衝突）
- BGM 音效製作（AUDIO_SPEC 定義的 BGM 清單）
- HTML5 匯出 + Playwright 截圖驗證
- itch.io 頁面上傳（ITCH_PAGE.md + DEMO_DESCRIPTION_EN.md 已就緒）
- BUG-04 清理：`_connect_restart()` 空殼函數整理（不影響執行）

## 待確認
- 無

## 已知問題
- character.gd 在 --script 模式下無法獨立載入（autoload GameManager 不存在），在完整場景模式下正常（非問題）
- BUG-04：`main.gd _connect_restart()` 為空殼，邏輯在 `_connect_hud()` 完成，不影響執行但影響維護 → Demo 後清理
- character.gd `fire_shot()` 無計時器驅動，`attack_power` 為裝飾性數值（完整戰鬥系統 Demo 後）
- Boss 決策觸發點位於 y=280，Boss 房 room_trigger 位於 y=210（間距 70px），已修正（之前 20px 重疊問題）
- **HTML5 中文字型破碎**：Godot 預設字體未 embed 至 WebExport，文字顯示為方格（已知，Demo 可接受）
- **itch.io 發布素材缺失**：cover 630×500、banner 960×540、icon 256×256 尚未製作

## 已完成（像素方塊 SVG 美術 + Demo 驗證，2026-06-21）
- **12 個 SVG 檔完成**：6 個戰場 sprite（64×64 像素方塊風格）+ 6 個 HUD 頭像（portrait）
  - 每個職業有獨特剪影：盾兵（大盾）、醫療兵（背包+十字架）、突擊手（雙臂前伸步槍）、狙擊手（超長槍管貫穿+鬼影斗篷）、爆破手（黃黑警告條紋背包）、偵察手（T形夜視鏡+綠色發光）
- **character.gd 重構**：_body 從 ColorRect 改為 Node（Sprite2D/ColorRect 二擇），die() 從 `.color` 改為 `.modulate`
- **hud.gd 更新**：角色卡頭像優先載入 SVG portrait，有無 SVG 皆可正常顯示
- **save_manager.gd 修正**：owned_characters 預設補上 "demo"（與 DEFAULT_SQUAD 一致，修正「要 4 人但只有 3 個可選」的出發卡關 bug）
- **main.gd 修正**：CHAR_DATA 5 個角色 defense 從 0.0 改為正確數值；Boss 觸發點從 y=230 移至 y=280
- **HTML5 匯出 + Playwright 驗證**：`--import` 先跑讓 SVG 被索引，`--export-release` 成功，Playwright 確認基地→戰場轉場正常，像素 sprite 在戰場上正確渲染（爆破手顯示黃色，來自 SVG 而非 ColorRect 紅色，確認 SVG 載入成功）
- **6 個 BGM WAV 生成**：base_bgm / mission_bgm / high_alert_bgm / boss_bgm / victory_bgm / defeat_bgm

## 已完成（補充，2026-06-21 同日）
- P2 完整實作：enemy.gd（三類敵人）、room.gd、base.gd（完整基地場景）
- AudioManager：15 個 WAV 全部生成，crossfade BGM 架構完成
- TutorialManager：8 步驟新手教學，CanvasLayer layer=20
- BUG-03 修正：selected_mission_id 已通過 GameManager.current_mission_id 傳入戰場
- docs/HEALTH_REPORT.md 完成（專案監控師，Demo 發布前全局健康報告）

## Demo 後（不阻擋發布）
- 職業顏色規範統一（解決 base.gd 橙色盾兵 vs ROADMAP 藍色盾兵衝突）
- BGM 音效製作（AUDIO_SPEC 定義的 BGM 清單）
- HTML5 匯出 + Playwright 截圖驗證
- itch.io 頁面上傳（ITCH_PAGE.md + DEMO_DESCRIPTION_EN.md 已就緒）
- BUG-04 清理：`_connect_restart()` 空殼函數整理
- Boss 決策點與 Boss 房觸發區重疊調整（y=230 vs y=210，考慮分離至 y=280）
- 偵察手大招 UI 定案（電磁脈衝已實作於 character.gd，GDD 煙霧封鎖待使用者確認）

## 操作紀錄
- 2026-06-21：Demo 閉環修正 + 數值平衡（9 項）
  - 修改 src/scripts/main.gd：sniper ult_cd 50.0→35.0，加 _create_boss_decision_trigger / _create_boss_room_trigger，移除 _on_end_reached 中票券給予（改由 hud.gd 統一）
  - 修改 src/scripts/decision_panel.gd：加 _is_char_in_squad，_populate 加偵察手情報顯示，charge 傷害邏輯修正（atk_mult 反比降低進場傷害），加 boss 決策三選項效果
  - 修改 src/scripts/character.gd：狙擊手大招改為「HP < 25% 瞬殺 / 否則 300% ATK」邏輯
  - 修改 src/scripts/hud.gd：_on_game_won 整合 add_coins(200) + 票券獎勵，result_desc 顯示獎勵明細
  - 三輪 headless 測試：exit 0，無 ERROR ✓ 2026-06-21
- 2026-06-21：抽卡系統平衡調整
  - 修改 src/scripts/save_manager.gd（稀有度倍率 0.3→0.2）
  - 修改 src/scripts/gacha_manager.gd（金票 x2 備份、SSR 補償改藍票）
  - 修改 src/scripts/gacha_panel.gd（SSR 補償顯示文字）
  - 修改 src/scripts/upgrade_panel.gd（加決策解鎖說明、卡片高度 140→180）
  - 修改 src/scripts/decision_panel.gd（_get_squad_rarity、_build_rarity_options、8 種稀有度選項效果）
- 2026-06-21：抽卡系統全面重構（備份/稀有度新設計）
  - 重寫 src/scripts/gacha_manager.gd（等機率 6 職業，移除 SR/R/N）
  - 修改 src/scripts/save_manager.gd（移除 fragments，加 rarity/copies/6 函數）
  - 新增 src/scripts/upgrade_panel.gd（角色升級管理面板）
  - 新增 src/scenes/UpgradePanel.tscn（CanvasLayer layer=16）
  - 修改 src/scripts/gacha_panel.gd（均等機率說明，稀有度總覽）
  - 修改 src/scripts/base.gd（稀有度邊框，升級管理按鈕）
  - 修改 src/scripts/main.gd（數值公式套用 rarity_mult×level_mult）
- 2026-06-21：抽卡系統完整實作
  - 新增 src/scripts/gacha_manager.gd（抽卡邏輯 autoload）
  - 新增 src/scripts/gacha_panel.gd（招募中心 UI）
  - 新增 src/scenes/GachaPanel.tscn（CanvasLayer 場景）
  - 修改 save_manager.gd（新增 4 個抽卡相關欄位）
  - 修改 base.gd（票券顯示、招募中心按鈕、角色鎖定邏輯）
  - 修改 decision_panel.gd（card 分支補上藍票獎勵）
  - 修改 main.gd（任務完成給票）
  - 修改 project.godot（GachaManager autoload）
- 2026-06-21：設計討論完成，重新定案為戰術指揮+Idle+抽卡遊戲
- 2026-06-21：舊版開發檔案移至 黑歷史/ 資料夾
- 2026-06-21：GDD v2.0 撰寫完成，STATE.md 建立
- 2026-06-21：P0 核心原型建立
  - 新增 src/ 目錄結構（scenes/, scripts/, resources/）
  - 建立 project.godot（1080x1920，GameManager autoload）
  - 建立 6 個 GDScript：game_manager.gd, character.gd, squad_controller.gd, decision_trigger.gd, decision_panel.gd, hud.gd, main.gd
  - 建立 3 個場景：Main.tscn, HUD.tscn, DecisionPanel.tscn
  - 建立 resources/characters.json（5 職業數值）
  - Headless 測試通過：exit 0，無 SCRIPT ERROR，無 ERROR
- 2026-06-21：DecisionPanel.tscn 改為 CanvasLayer 根節點（修正 UI 縮放問題）
- 2026-06-21：建立 icon.svg（避免啟動警告）
- 2026-06-21：P2 系統完成：enemy.gd / room.gd / base.gd / audio_manager.gd / save_manager.gd / tutorial_manager.gd
- 2026-06-21：生成 15 個 WAV 音效（UI 6 個 + 大招 6 個 + 戰鬥 3 個）
- 2026-06-21：專案監控師健康報告完成 → docs/HEALTH_REPORT.md
- 2026-06-21：STATE.md 更新，P2 標記完成，待辦改為 Demo 閉環修正清單
