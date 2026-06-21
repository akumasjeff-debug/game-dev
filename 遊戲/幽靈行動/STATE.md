# 幽靈行動 狀態

## 已完成
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

## 進行中
- 專案監控師：Demo 發布前全局健康檢查完成（見 docs/HEALTH_REPORT.md）

## 待辦

### P0 ✅ 完成
### P1 ✅ 完成（2026-06-21）
- 大招實際效果：盾兵護盾/突擊手攻擊buff/狙擊手秒殺標記/醫療兵回血/爆破手AOE
- 岔路決策點：左路/右路/未知，選擇後即時切換 waypoint 路徑
- Lv.3 條件解鎖：盾兵 Lv.3 自動在房間決策加入「舉盾突入」選項
- headless 測試通過 exit 0 ✓

### P2 ✅ 完成（2026-06-21）
- 基地場景：任務板 UI + 6 職業按鈕 + 4 格陣容選擇 + 出發按鈕
- 離線金幣計算系統（24 小時上限，100 金幣/小時，60 秒門檻）
- 本機存檔（Godot ConfigFile：coins / squad / levels / timestamp）
- AudioManager（15 個 WAV，crossfade BGM 架構）
- TutorialManager（8 步驟新手教學，CanvasLayer layer=20）
- enemy.gd（普通兵/精英/Boss 三種類型，自動攻擊/前線優先/致盲檢查）
- room.gd、base.gd、save_manager.gd、audio_manager.gd、tutorial_manager.gd

### Demo 閉環修正（阻擋 Demo 發布 — 必須完成）
1. 補偵察手 characters.json 資料（防止選偵察手後 crash）
2. HUD 改為 4 人動態初始化（跟隨 selected_squad，解除視覺矛盾）
3. 修 BUG-01：突擊手大招攻擊倍率接入 decision_panel "charge" 傷害計算（5 行）
4. 實作 Boss 決策點（1 個 Boss 房事件 + 任務勝利觸發）
5. 任務結算後金幣自動入帳（結算信號 → SaveManager.add_coins）

### 數值平衡修正（影響可玩性評分）
6. 狙擊手 Lv.1 大招 CD：50 秒 → 35 秒
7. 狙擊手大招觸發條件：改為「目標 HP < 25%」
8. 偵察手 Lv.1 被動：改為「未知房間揭露敵人數量」
9. 明確限制「每職業只能帶一名」規則加入 base.gd 驗證

### Demo 後（不阻擋發布）
- 職業顏色規範統一（解決 base.gd 橙色盾兵 vs ROADMAP 藍色盾兵衝突）
- BGM 音效製作（AUDIO_SPEC 定義的 BGM 清單）
- HTML5 匯出 + Playwright 截圖驗證
- itch.io 頁面上傳（ITCH_PAGE.md + DEMO_DESCRIPTION_EN.md 已就緒）
- BUG-04 清理：`_connect_restart()` 空殼函數整理（不影響執行）

## 待確認
- 偵察手大招語意定案：A「煙霧封鎖（攻擊失效，可移動）」vs B「電磁脈衝（完整眩暈）」？（影響代碼實作方向和 CD 數值）
- Demo 美術路線：「方塊先發，正式版換圖」還是「現在製作精靈圖（+3-5 天）」？

## 已知問題
- character.gd 在 --script 模式下無法獨立載入（autoload GameManager 不存在），在完整場景模式下正常（非問題）
- characters.json 缺偵察手資料（6 職業中只有 5 個）→ Demo 閉環修正 #1
- BUG-01：突擊手大招攻擊倍率（x1.6）未接入 decision_panel "charge" 傷害計算，大招等同無效 → Demo 閉環修正 #3
- BUG-02：狙擊手大招實作為「全隊無傷」語意，與 GDD「目標低血秒殺」不符 → 數值平衡修正 #7
- BUG-03：已修正（base.gd 出發時寫入 `GameManager.current_mission_id`）
- BUG-04：`main.gd _connect_restart()` 為空殼，邏輯在 `_connect_hud()` 完成，不影響執行但影響維護 → Demo 後清理
- 偵察手大招定義衝突：GDD 說「煙霧封鎖（攻擊失效）」，BALANCE_SHEET 說「電磁脈衝（眩暈）」→ 待使用者確認
- HUD 固定 5 人卡，與 6 選 4 陣容系統視覺矛盾 → Demo 閉環修正 #2
- 任務結算後金幣未自動入帳，Meta 閉環斷裂 → Demo 閉環修正 #5
- Boss 決策點未實作，任務無終點高潮 → Demo 閉環修正 #4
- character.gd `fire_shot()` 無計時器驅動，`attack_power` 為裝飾性數值（完整戰鬥系統 Demo 後）

## 已完成（補充，2026-06-21 同日）
- P2 完整實作：enemy.gd（三類敵人）、room.gd、base.gd（完整基地場景）
- AudioManager：15 個 WAV 全部生成，crossfade BGM 架構完成
- TutorialManager：8 步驟新手教學，CanvasLayer layer=20
- BUG-03 修正：selected_mission_id 已通過 GameManager.current_mission_id 傳入戰場
- docs/HEALTH_REPORT.md 完成（專案監控師，Demo 發布前全局健康報告）

## 操作紀錄
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
