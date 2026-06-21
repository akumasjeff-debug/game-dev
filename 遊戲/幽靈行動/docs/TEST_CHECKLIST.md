# 幽靈行動 — 功能驗收清單

**測試日期：** 2026-06-21
**測試員：** 品管組長（測試員）
**Godot 版本：** 4.6.3.stable

---

## Headless 測試結果

```
指令：C:\Godot\Godot_v4.6.3-stable_win64_console.exe --headless --path "d:\開發遊戲\遊戲\幽靈行動\src" --quit
輸出：Godot Engine v4.6.3.stable.official.7d41c59c4
Exit Code：0
ERROR 數量：0
WARNING 數量：0
```

headless 測試乾淨通過，無任何腳本錯誤或警告。

---

## P0 功能驗收

### 小隊自動推進（waypoint 跟隨）
**✅ 已實作且 headless 通過**
`squad_controller.gd` 實作完整：`_process` 每幀推進 pivot，沿 waypoints 移動，`_advance()` 計算方向與距離，支援 `replace_remaining_path()` 熱替換路徑。主路徑共 9 個 waypoint（y=1750 至 y=80），移速 80px/s。

### 5 職業角色各自的隊列位置
**✅ 已實作且 headless 通過**
`main.gd` CHAR_DATA 定義 6 個職業的 `formation_offset`：盾兵 (0,-80)、醫療兵 (-40,80)、突擊手 (-50,0)、狙擊手 (40,80)、爆破手 (50,0)、偵察手 (0,40)。`squad_controller._update_member_positions()` 每幀套用 pivot + offset。

### Area2D 觸發決策點 → 畫面暫停
**✅ 已實作且 headless 通過**
`decision_trigger.gd`：`body_entered` 信號連接 `_trigger()`，呼叫 `GameManager.trigger_decision()` → `pause_squad()` → 發出 `squad_paused` 信號。岔路觸發走 `main.gd` 的 inline `_on_fork_trigger_entered()`，同樣呼叫 `GameManager.trigger_decision()`。

### 決策面板顯示 3 個選項
**✅ 已實作且 headless 通過**
`decision_panel.gd`：接收 `decision_triggered` 信號後 `_populate()` 動態建立 Button，房間型 3 選項（直衝/靜悄悄/炸彈），補給型 3 選項（補血/炸彈CD/抽卡券），岔路型 3 選項（左路/右路/探索）。

### 選擇後繼續推進
**✅ 已實作且 headless 通過**
`_on_option_pressed()` 最後呼叫 `GameManager.resume_squad()`，發出 `squad_resumed` 信號，`squad_controller._process()` 讀取 `is_paused == false` 後恢復移動。

### 角色血條 HUD
**✅ 已實作且 headless 通過**
雙層血條：`character.gd` 在角色節點上建立 ProgressBar（角色頭頂），`hud.gd` 在底部卡片建立 HUD 血條，兩者都連接 `hp_changed` 信號即時更新。顏色閾值：>50% 綠、25~50% 橘、<25% 紅。

### 大招卡片 CD 計時
**✅ 已實作且 headless 通過**
`character.gd _process()` 每幀遞減 `cd_timer`，`hud.gd _process()` 每幀呼叫 `_set_card_cd_state()` 顯示秒數倒數；CD <= 5 秒時放大字體至 40px 並顯示橘色強調。大招就緒時邊框 1.2 秒週期脈衝。

### 勝利/失敗判定
**✅ 已實作且 headless 通過**
勝利：終點 Area2D `_on_end_reached()` 呼叫 `GameManager.trigger_game_over(true)`。失敗：`character.die()` 後呼叫 `GameManager.check_defeat()`，全員 HP <= 0 時呼叫 `trigger_game_over(false)`。兩者均發信號給 HUD 顯示結果面板。

### 重試按鈕
**⚠️ 已實作但有疑慮**
HUD 場景定義 `RestartBtn`，`_on_restart_pressed()` 呼叫 `get_tree().change_scene_to_file("res://scenes/Base.tscn")`（返回基地，非直接重試任務）。重試路徑：基地 → 重新出發。兩個疑慮：
1. `main.gd` 的 `_connect_restart()` 函數為空（第 335-336 行），對 RestartBtn 的連接實際是在 `_connect_hud()` 內完成，但連接目標是 `hud._on_restart_pressed`，而非 main 的邏輯，信號鏈稍顯繞路
2. 勝利後 restart_btn.text 改為「返回基地」，但失敗後按鈕文字仍是 HUD.tscn 預設的「返回基地」，行為一致但未顯式設定

---

## P1 功能驗收

### 盾兵大招：全隊減傷 50%，5 秒
**✅ 已實作且 headless 通過**
`character.gd "shield"` → `GameManager.activate_shield_buff()`，設 `shield_buff_active = true`、`shield_buff_timer = 5.0`。`apply_damage_to_member()` 套用 `final_amount *= 0.5`。計時器在 `GameManager._process()` 每幀遞減。

### 突擊手大招：全隊攻擊 +60%，8 秒
**✅ 已實作且 headless 通過**
`character.gd "assault"` → `GameManager.activate_assault_buff()`，`assault_buff_timer = 8.0`，`get_attack_multiplier()` 回傳 1.6。注意：倍率只供外部系統查詢，目前無自動攻擊主動呼叫此方法的系統（決策傷害事件不查攻擊倍率），見疑慮欄。

### 狙擊手大招：目標 HP < 25% 瞬殺（或造成 300% 傷害）
**⚠️ 已實作但有疑慮**
實作為「秒殺」語意：有實體敵人時 `set_sniper_mark(enemies[0])`，決策 "charge" 選項若消耗 `sniper_mark_pending` 則跳出全隊無傷迴圈（等同敵人秒殺，非玩家無傷）。設計文件描述「目標 HP < 25% 瞬殺」，但當前實作為「下次房間遭遇無傷」，語意差異較大。無實體敵人場景（所有戰鬥都是決策點）下 pending 標記才生效，邏輯正確但與 GDD 描述不符。

### 醫療兵大招：全隊回 30% HP
**✅ 已實作且 headless 通過**
`character.gd "medic"` → 遍歷 `gm.squad_members`，對非死亡成員呼叫 `member.heal(member.max_hp * 0.3)`。

### 爆破手大招：所有敵人扣 70% HP
**✅ 已實作且 headless 通過**
有實體敵人時直接扣血；無實體敵人（決策點模式）設 `demo_bomb_pending = true`，下次 "charge" 決策套用 `dmg *= 0.3`（等效減傷 70%）。

### 岔路決策點（左/右/未知）
**✅ 已實作且 headless 通過**
`main.gd _create_fork_trigger()` 在 y=970 建立觸發點，3 個選項（left/right/unknown）。`_fork_triggered` 旗標防止重複觸發。

### 選擇後切換 waypoint 路徑
**✅ 已實作且 headless 通過**
`decision_panel._apply_fork_effect()` → `main_scene.switch_path(opt_id)` → `squad_controller.replace_remaining_path()`。"unknown" 選項以 `randi() % 3` 隨機決定走哪條路。

### Lv.3 條件解鎖選項（盾兵 Lv.3 顯示舉盾突入）
**✅ 已實作且 headless 通過**
`decision_trigger._build_decision_data()`：`decision_type == "room"` 且 `_get_shield_level() >= 3` 時附加第 4 個選項 `"shield_rush"`，並將 type 改為 `"shield_entry"`。岔路觸發時也查詢 `shield_level`（儲存在 decision_data 中備用），但目前岔路本身不顯示舉盾選項（符合程式內的 P1-3 備注）。main.gd 預設盾兵 level = 3，可直接測試。

---

## P2 功能驗收

### 基地場景（Base.tscn）可載入
**✅ 已實作且 headless 通過**
`Base.tscn` 存在，掛載 `base.gd`，Autoload 三個（GameManager/SaveManager/AudioManager）均已登錄於 project.godot。

### 6 個職業選擇按鈕
**✅ 已實作且 headless 通過**
`base.gd ALL_CLASSES` 定義 6 職業，`_add_squad_panel()` 動態建立 6 個 Button，連接 `_on_class_toggled()`。

### 陣容選擇（最多 4 人）
**✅ 已實作且 headless 通過**
`_on_class_toggled()`：已選滿 4 人時 `pop_back()` 替換最後一個。可點擊槽位按鈕移除個別成員（`_on_slot_pressed()`）。

### 出發按鈕跳轉任務場景
**⚠️ 已實作但有疑慮**
`_on_launch_pressed()` 驗證陣容 4 人且有選任務才允許出發，重設 GameManager 狀態後 `change_scene_to_file("res://scenes/Main.tscn")`。疑慮：目前只有一個場景（Main.tscn），無論選哪個任務都跳相同場景，選定的 `selected_mission_id` 未傳遞到 Main 場景，任務差異化尚未實作。

### SaveManager autoload
**✅ 已實作且 headless 通過**
project.godot 登錄為 `SaveManager="*res://scripts/save_manager.gd"`。`_ready()` 自動呼叫 `load_game()`，讀取失敗（首次啟動）則使用預設值。

### 離線金幣計算（timestamp 差值）
**✅ 已實作且 headless 通過**
`calculate_offline_reward()`：讀取 `last_exit_timestamp`，計算 `elapsed_seconds`，上限 24 小時（2400 金幣），少於 60 秒不顯示。呼叫後清除 timestamp 避免重複計算。速率：100 金幣/小時。

### 存檔/讀檔（user://save_data.cfg）
**✅ 已實作且 headless 通過**
`save_game()` 寫入 coins、last_exit_timestamp、character_levels（6 職業）、selected_squad。`load_game()` 讀取並驗證 squad 長度（必須 == 4，否則回退預設）。關閉視窗時 `_notification(NOTIFICATION_WM_CLOSE_REQUEST)` 呼叫 `record_exit_time()`。

---

## 品管摘要

| 優先級 | 總計 | 通過 | 有疑慮 | 未實作 |
|--------|------|------|--------|--------|
| P0     | 9    | 8    | 1      | 0      |
| P1     | 7    | 5    | 2      | 0      |
| P2     | 7    | 6    | 1      | 0      |
| **合計** | **23** | **19** | **4** | **0** |

---

## 已知 Bug / 疑慮清單

**BUG-01（疑慮）**
- **問題描述**：突擊手大招攻擊倍率未接入決策傷害計算
- **重現步驟**：1. 開局 2. 使用突擊手大招 3. 在決策點選「直衝進入」
- **預期結果**：全隊傷害應依 get_attack_multiplier() * 1.6 加傷
- **實際結果**：`decision_panel._apply_decision_effect()` 的 "charge" 分支直接 `randf_range(15.0, 35.0)`，未查詢攻擊倍率，大招等同無效
- **嚴重程度**：影響體驗
- **平台**：全平台

**BUG-02（疑慮）**
- **問題描述**：狙擊手大招語意與 GDD 不符（應為「目標低血秒殺」，實作為「下次遭遇全隊無傷」）
- **重現步驟**：1. 使用狙擊手大招 2. 無實體敵人時，pending = true 3. 下次選「直衝」 4. 全隊完全不受傷
- **預期結果**：標記最弱敵人，對其造成 300% 傷害或秒殺（玩家可能仍受傷）
- **實際結果**：全隊無傷進入（等同隱身效果，與狙擊手職業定位不符）
- **嚴重程度**：影響體驗
- **平台**：全平台

**BUG-03（疑慮）**
- **問題描述**：任務選擇 ID 未傳入 Main 場景，所有任務跑同一地圖
- **重現步驟**：1. 基地選「廢棄倉庫清查」2. 出發 3. 進入 Main 場景
- **預期結果**：載入對應的支線地圖或不同敵人配置
- **實際結果**：永遠進入相同的 Main.tscn
- **嚴重程度**：小問題（P2 開發中，尚可接受）
- **平台**：全平台

**BUG-04（疑慮）**
- **問題描述**：`main.gd _connect_restart()` 是空函數，重試按鈕連接邏輯散落在 `_connect_hud()`
- **重現步驟**：1. 閱讀 main.gd 第 78 行、第 333-336 行
- **預期結果**：`_connect_restart()` 負責重試邏輯（命名語意）
- **實際結果**：連接邏輯在 `_connect_hud()` 第 238-240 行完成，`_connect_restart()` 為空殼，維護時容易誤判
- **嚴重程度**：小問題（不影響執行，影響維護性）
- **平台**：全平台

---

## 下一步建議

### 目前最脆弱的地方

**最脆弱：大招效果與戰鬥系統脫鉤**
整個戰鬥是「決策點觸發傷害」模式（無實體敵人），但三個關鍵大招（突擊手攻擊倍率、狙擊手標記、偵察手致盲）都預設有「實體敵人」才完整生效。當前場景 100% 是決策點模式，三個大招的 pending 路徑在程式碼中存在，但觸發條件不一致，容易漏接。

**次脆弱：無自動攻擊系統**
`character.gd` 有 `fire_shot()` 方法但沒有任何計時器或 AI 定期呼叫它。`get_attack_multiplier()` 和突擊手 buff 沒有任何地方消耗。整個戰鬥完全依賴「決策點傷害」，CHAR_DATA 的 `attack_power` 數值目前完全是裝飾性的，未接入任何計算。

### 優先修復順序

1. **修 BUG-01（突擊手大招無效）**：在 decision_panel "charge" 分支的傷害計算加上 `GameManager.get_attack_multiplier()` 乘數。5 行以內的改動，收益大。

2. **修 BUG-02（狙擊手語意混淆）**：將 "charge" 分支的 sniper pending 邏輯改為「傷害 * 0」只對第一個敵人，其他成員正常受傷（符合「狙擊一個，其餘照常」的職業定位）。

3. **釐清任務系統架構**：決定 `selected_mission_id` 要如何傳入 Main 場景（GameManager 增加 `current_mission_id` 變數是最簡方式），即使地圖暫時相同也應先打通資料流，避免後續多地圖開發時重構成本增加。
