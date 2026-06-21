# 幽靈行動 — Demo 發布前全局健康報告

版本：1.0 | 日期：2026-06-21 | 監控師：專案監控師

---

## 系統完成度

| 系統 | 代碼狀態 | 設計文件 | 備注 |
|------|---------|---------|------|
| 小隊自動推進（waypoint） | 已實作 | 已完成（GDD） | headless 通過，9 個 waypoint，速度 80px/s |
| 決策點觸發（Area2D 暫停） | 已實作 | 已完成（GDD） | headless 通過，信號鏈完整 |
| 決策面板（3 選項） | 已實作 | 已完成（GDD） | 房間/補給箱/岔路三種類型均通過 |
| 岔路路徑切換 | 已實作 | 已完成（GDD） | `replace_remaining_path()` 熱替換正常 |
| 條件解鎖選項（盾兵 Lv.3） | 已實作 | 已完成（GDD） | headless 通過，預設 level=3 可直接驗證 |
| 大招 HUD（5 卡 CD 倒數） | 已實作 | 已完成（HUD_SPEC.md） | 脈衝動畫、顏色閾值均正常 |
| 盾兵大招（全隊減傷 50%） | 已實作 | 已完成 | headless 通過 |
| 突擊手大招（攻擊 +60%） | 已實作（有缺陷） | 已完成 | BUG-01：倍率未接入決策傷害計算，大招等同無效 |
| 狙擊手大招（秒殺標記） | 已實作（語意偏移） | 已完成 | BUG-02：實作為「全隊無傷」而非「目標低血秒殺」，語意與 GDD 不符 |
| 醫療兵大招（回 30% HP） | 已實作 | 已完成 | headless 通過 |
| 爆破手大招（削 70% HP） | 已實作 | 已完成 | headless 通過，pending 路徑邏輯正確 |
| 偵察手大招（致盲控制） | 已實作（未接入） | 設計有衝突 | enemy.gd 的 `enemies_blinded` 檢查存在，但 GDD 與 BALANCE_SHEET 對大招效果定義不一致（煙霧封鎖 vs 電磁脈衝） |
| 勝利/失敗判定 | 已實作 | 已完成 | headless 通過 |
| 重試按鈕（返回基地） | 已實作（有瑕疵） | 已完成 | BUG-04：`_connect_restart()` 為空殼，邏輯散落 `_connect_hud()`，不影響執行但影響維護 |
| 基地場景（任務板 + 陣容） | 已實作 | 已完成（BASE_UI_SPEC.md） | headless 通過，6 職業按鈕、4 槽陣容、離線金幣彈窗均完整 |
| 6 選 4 陣容選擇 | 已實作 | 已完成 | 選擇結果存 SaveManager，出發時傳入 GameManager |
| 基地→戰場流程串接 | 已實作 | 已完成（ROADMAP.md） | `change_scene_to_file` 正常，`current_mission_id` 已傳入 GameManager（BUG-03 已修正） |
| 任務差異化（多關卡） | 未實作 | 未完成 | Demo 固定單一 Main.tscn，ROADMAP 標記為 Demo 後目標 |
| 任務獎勵閉環（金幣入帳） | 未實作 | 未完成 | 結算後返回基地，但金幣/票券尚未在結算時自動入帳 |
| Boss 房事件 | 未實作 | 有設計（ROADMAP.md） | ROADMAP 定義為 Demo 必須，但代碼尚無 Boss 決策點邏輯 |
| HUD 改為 4 人動態 | 未實作 | 已完成（ROADMAP.md） | 目前 HUD 固定 5 卡，與 GDD v2.1「6 選 4」不一致 |
| 實體敵人與自動攻擊系統 | 部分實作 | 設計完成 | `enemy.gd` 已有完整實體敵人邏輯（攻擊/HP/死亡），但 `character.gd` 的 `fire_shot()` 無計時器驅動，`attack_power` 純裝飾 |
| 音效系統 | 已實作 | 已完成（AUDIO_SPEC.md） | 15 個 WAV 均存在，AudioManager crossfade 架構完整；BGM 音效檔未建立（AUDIO_SPEC 要求的 BGM 清單） |
| 新手教學 | 已實作 | 已完成（TUTORIAL_DESIGN.md） | TutorialManager 8 步驟完整，CanvasLayer layer=20，與 base.gd/main.gd 信號連接待驗證 |
| 離線金幣計算 | 已實作 | 已完成 | headless 通過，24 小時上限，60 秒門檻 |
| 本機存檔 | 已實作 | 已完成 | headless 通過，6 職業 level、selected_squad、coins 均持久化 |
| 偵察手（characters.json） | 未完成 | 已完成（GDD v2.1） | characters.json 目前只有 5 職業，偵察手資料缺失 |
| 數值平衡修正（3 個嚴重） | 未實作 | 已完成（BALANCE_REVIEW.md） | 狙擊手 CD 50s、偵察手 Lv.1 被動失效、爆破手+狙擊手無限秒殺均尚未修正 |
| HTML5 匯出 + 截圖驗證 | 未執行 | 已完成（ROADMAP.md） | ROADMAP 標記為 Demo 必須，Playwright 驗證未跑 |
| 職業顏色規範（方塊一致性） | 部分完成 | 已完成（ROADMAP.md） | base.gd 已定義 6 色（盾兵橙/醫療兵白/突擊手紅/狙擊手綠/爆破手黃/偵察手青），與 ROADMAP 建議有出入（盾兵應為藍色），戰場方塊顏色未與 HUD 同步 |
| itch.io 頁面 | 未完成 | 已完成（ITCH_PAGE.md） | ITCH_PAGE.md 和 DEMO_DESCRIPTION_EN.md 已存在，但頁面未上傳 |

---

## 技術風險（Demo 前 48 小時內可能爆炸的地方）

### 高風險

**1. 任務獎勵閉環尚未串通**
玩家完成任務後點「返回基地」，目前代碼沒有任何金幣/票券入帳邏輯。玩家會重複跑任務卻看到金幣永遠不增加，直接破壞 Idle/Meta 層的留存動機。這是 Demo 定義中「必須有」的項目，但目前完全缺失。

**2. HUD 固定 5 人卡，與 6 選 4 陣容系統衝突**
玩家在基地選了 4 人，但戰場 HUD 固定顯示 5 張卡（對應預設 5 職業）。如果玩家選了一個不在預設 5 人組合內的陣容（例如不帶突擊手），HUD 仍顯示突擊手卡。這個視覺錯誤會讓玩家對遊戲機制產生困惑，且動到 HUD 初始化邏輯有連帶影響大招觸發的風險。

**3. 突擊手大招 BUG-01 在 Demo 前 5 分鐘就會被玩家發現**
點下突擊手大招，後續「直衝」傷害完全不變——玩家點了等於沒點。在一個戰鬥驗證期只有 5 分鐘的 Demo 裡，這個 bug 會直接降低玩家對整個大招系統的信任感。修正方式僅需在 decision_panel "charge" 分支加一行乘數，風險極低。

### 中風險

**4. TutorialManager 與 main.gd / base.gd 的信號連接未經可視化驗證**
`tutorial_manager.gd` 邏輯完整，但 headless 測試無法驗證 CanvasLayer 渲染是否正確，也無法確認 `notify_squad_moving()` / `notify_combat_started()` 等呼叫是否已接入 main.gd。教學步驟 2（決策點遮罩）如果信號未連就會是黑頻。

**5. 偵察手大招定義不一致，實作方向未鎖定**
GDD 說「煙霧封鎖（攻擊失效）」，BALANCE_SHEET 說「電磁脈衝（眩暈）」，enemy.gd 實作的是 `enemies_blinded`（攻擊失效）。目前三個文件指向不同語意，如果在 Demo 前同時修改多個文件很容易產生新的矛盾。

**6. 音效 WAV 為合成正弦波，沒有 BGM**
音效存在但品質為佔位符。AUDIO_SPEC.md 定義的 BGM 完全缺席。進入 Demo 後玩家聽到的是靜默背景，決策點觸發音（合成音）的辨識度未知。BGM 缺席在手機環境影響沉浸感。

### 低風險

**7. characters.json 缺偵察手**
基地「6 選 4」介面顯示偵察手按鈕，但若選偵察手出發，GameManager 初始化時讀取的職業資料會是空值。補上 JSON 欄位是 0.5 天工作，但若遺忘會在 Demo 前演示時造成直接 crash。

**8. BUG-04 空殼函數影響後續維護**
`_connect_restart()` 為空函數，不影響現有執行，但若後續有人在此函數添加重試邏輯會因為執行不到而靜默失效。Demo 階段不阻擋，但應在里程碑 2 前清理。

---

## Demo 可玩性評分

### 目前狀態：4 / 10

**扣分原因：**
- -2 分：流程未完整閉環——任務獎勵（金幣）尚未在結算後自動入帳，Meta 層的核心動力（累積金幣升等）無法體驗
- -1 分：突擊手大招 BUG-01 讓大招系統信任度崩潰
- -1 分：HUD 顯示 5 人但陣容選 4 人，視覺上互相矛盾
- -1 分：偵察手 characters.json 缺資料，選了可能 crash
- -1 分：Boss 房事件未實作，任務無終點高潮

**加分優勢（維持 4 分的理由）：**
- 小隊推進流暢，決策面板觸發正確
- 5 個大招中 3 個（盾兵/醫療兵/爆破手）效果正確生效
- 基地場景完整，存檔/讀檔/離線金幣全部運作
- 新手教學邏輯完整（8 步驟），音效資源全部到位
- headless 測試 23 項中 19 項通過，零 crash

### 修完 3 個 Bug + 加入 Boss 決策後：預估 6 / 10

**具體修正內容：**
1. BUG-01 突擊手大招接入傷害計算（5 行）
2. HUD 改為 4 人動態（跟隨 selected_squad）
3. 結算後金幣自動入帳（任務完成信號觸發 SaveManager）
4. Boss 決策點邏輯（1 個特殊決策節點 + 勝利觸發）
5. 補齊偵察手 characters.json

修完後玩家能體驗完整一局閉環（基地 → 選陣容 → 任務 → Boss → 結算 → 金幣入帳 → 回基地）。要到 7-8 分還需要：數值平衡修正 3 項嚴重問題 + BGM + 職業顏色規範。

---

## 需要使用者決定的事項

**問題 1：偵察手大招語意最終定案（設計分歧）**
目前 GDD 和 BALANCE_SHEET 對偵察手大招有兩種不同定義：
- 選項 A（GDD 版）：「煙霧封鎖」——敵人攻擊失效但可移動（`enemies_blinded`，enemy.gd 已按此實作）
- 選項 B（BALANCE_SHEET 版）：「電磁脈衝」——完整眩暈（敵人完全無法行動）

選項 B 的強度更高，在 Lv.10 配合突擊手有 54.8% 無敵窗口，BALANCE_REVIEW 建議若選 B 需要把 CD 從 15.5 秒拉到 20 秒。請確認使用哪個版本，後續代碼實作和數值才能收斂。

**問題 2：Demo 是否現在就要換掉方塊美術？**
ROADMAP 建議 Demo 可以用彩色方塊發布，只要職業顏色規範一致。目前 base.gd 的顏色定義與 ROADMAP 建議不完全一致（盾兵用橙色 vs ROADMAP 建議藍色）。若要換成正式精靈圖，估時 3-5 天並需要召喚美術組製作。請確認 Demo 目標：「方塊先發，正式版換圖」還是「現在做精靈圖」。

---

## 最後建議（按優先順序）

**建議 1（立即執行，阻擋 Demo）：補全 5 個閉環缺口**
按以下順序執行，估計 2-3 天：
1. 補偵察手 characters.json（0.5 天，防止 crash）
2. HUD 改為 4 人動態初始化（1 天，解除視覺矛盾）
3. 修 BUG-01 突擊手大招接入傷害計算（0.5 天，恢復大招信任感）
4. 實作 Boss 決策點（1 天，提供任務終點高潮）
5. 任務結算後金幣自動入帳（0.5 天，接通 Meta 閉環）

**建議 2（Demo 前必做，影響可玩性評分）：套用 BALANCE_REVIEW 三個嚴重修正**
套用後估計評分從 6 分提升到 7 分：
- 狙擊手 Lv.1 大招 CD：50 秒 → 35 秒
- 狙擊手大招觸發條件：改為「目標 HP < 25%」
- 偵察手 Lv.1 被動：改為「未知房間揭露敵人數量」
以上修改集中在 characters.json 和 decision_trigger.gd，估時 0.5 天。

**建議 3（Demo 後，但應趁早確定方向）：鎖定美術路線**
ROADMAP 指出 Isometric 3D 場景是正式版目標，Demo 用方塊。建議現在就確認職業顏色最終版本（解決 base.gd 橙色盾兵 vs ROADMAP 藍色盾兵的衝突），讓美術組製作對應的顏色規範文件，避免 Demo 發布後需要大幅改色。

---

## 附：文件覆蓋度摘要

| 文件 | 用途 | 狀態 |
|------|------|------|
| GDD.md | 核心設計規格（v2.1） | 完整 |
| BALANCE_SHEET.md | 原始數值表 | 完整 |
| BALANCE_REVIEW.md | 數值問題診斷 | 完整，8 個問題已識別 |
| ROADMAP.md | Demo 發布路線圖 | 完整，含時程估算 |
| TEST_CHECKLIST.md | 功能驗收清單 | 完整，23 項 / 19 通過 |
| HUD_SPEC.md | HUD 設計規格 | 完整 |
| AUDIO_SPEC.md | 音效規格 | 完整，WAV 均已生成 |
| TUTORIAL_DESIGN.md | 新手教學設計 | 完整 |
| MAP_DESIGN.md | 地圖設計 | 存在，待確認與代碼的對應 |
| MISSION_PROGRESSION.md | 任務進度設計 | 存在 |
| EVENTS_CONTENT.md | 事件文案 | 存在 |
| ART_SPEC.md | 美術規格 | 存在 |
| BASE_UI_SPEC.md | 基地 UI 規格 | 存在 |
| ITCH_PAGE.md | itch.io 頁面素材 | 存在，未上傳 |
| DEMO_DESCRIPTION_EN.md | 英文 Demo 說明 | 存在 |

**文件覆蓋評估：設計文件已齊全，核心風險在代碼實作而非設計缺失。**

---

*本報告依據：STATE.md（2026-06-21）、TEST_CHECKLIST.md v1.0、BALANCE_REVIEW.md v1.0、ROADMAP.md v1.0、所有 src/scripts/ GDScript 源碼直接審閱*
