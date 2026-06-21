# 幽靈行動 程式碼品質報告
日期：2026-06-21
掃描範圍：16 個 GDScript 檔案（game_manager / character / squad_controller / decision_trigger / decision_panel / hud / main / base / save_manager / audio_manager / tutorial_manager / enemy / room / gacha_manager / gacha_panel / upgrade_panel）
Headless 測試：通過（無 crash，無 GDScript 錯誤）

---

## 嚴重問題（確定會 crash）

無。

---

## 中等問題（可能在特定條件下 crash 或行為異常）

### M1 — upgrade_panel.gd 第 161 行：RARITY_COLORS 陣列越界風險
- **位置**：`_build_char_card()` → `RARITY_COLORS[rarity]`
- **觸發條件**：若未來 `character_rarity` 存入 >= 3 的值（資料損壞或未來擴充），索引越界 crash
- **目前風險**：低（SaveManager 限制最大 rarity = 2），但缺乏保護
- **建議修復**：`RARITY_COLORS[min(rarity, RARITY_COLORS.size() - 1)]`

### M2 — gacha_panel.gd 第 201 行：RARITY_NAMES_DISP 陣列越界風險
- **位置**：`_update_fragment_display()` → `RARITY_NAMES_DISP[r]`
- **觸發條件**：同 M1，rarity >= 3 時 crash
- **建議修復**：`RARITY_NAMES_DISP[min(r, RARITY_NAMES_DISP.size() - 1)]`

### M3 — main.gd：BossDecision 觸發點與 Boss 房觸發點位置重疊
- **位置**：`_create_boss_decision_trigger(Vector2(540, 230))` 和 `_create_boss_room_trigger(Vector2(540, 210))`
- **距離差僅 20px，碰撞半徑各 80px**，小隊同時進入兩個 Area2D
- **問題**：小隊進入 Boss 決策點的同時可能觸發 Boss 房戰鬥，使得「選擇進入方式」的決策面板出現時，Boss 已開始戰鬥
- **建議**：Boss 房觸發改由 Boss 決策選擇回調後手動觸發，或拉開距離到 >= 170px

### M4 — decision_panel.gd：option_selected 信號在 main.gd 重複連接的潛在問題
- **位置**：`main.gd` 第 279 行每次進入房間都重新 connect `option_selected`，使用 `CONNECT_ONE_SHOT` 保護
- **風險**：若 `CONNECT_ONE_SHOT` 的 lambda 在 room 節點已被 queue_free 後回呼，`room.start_battle()` 對已釋放節點呼叫，但有 `is_instance_valid(room)` 保護（第 288 行），實際已安全
- **結論**：已有保護，降級為輕微問題（見下方 L3）

---

## 輕微問題（不影響執行，但值得改善）

### L1 — decision_trigger.gd：未使用的靜態變數 _events_cache / _events_loaded
- **位置**：第 19-20 行
- `static var _events_cache: Dictionary = {}` 和 `static var _events_loaded: bool = false` 宣告後整個腳本中從未讀寫
- **推測**：events.json 動態讀取功能的遺留骨架（尚未實作）
- **建議**：暫時保留（若有計劃實作 JSON 載入），否則移除

### L2 — base.gd：mission_buttons Array 及 _on_mission_selected 函數為遺留代碼
- **位置**：第 11 行 `mission_buttons: Array = []`，第 476 行 `_on_mission_selected()`
- Demo 階段改為單一固定任務顯示卡，`mission_buttons` 永遠為空陣列，`_on_mission_selected` 永遠不被呼叫
- **建議**：多任務功能上線前可暫保留，避免重工

### L3 — main.gd：restart_btn / retry_btn 連接有冗餘的 is_connected 防重複檢查
- **位置**：第 421-426 行
- `hud.gd._ready()` 中 `retry_btn` 已連接一次，`main.gd` 加了 `is_connected` 防止重複，本身正確
- `restart_btn` 在 `hud.gd._ready()` 中**未**連接，由 `main.gd` 連接，`is_connected` 第一次永遠 false，防重複條件永遠成立，冗餘但無害
- **建議**：若 `restart_btn` 未來在 `hud.gd._ready()` 補上連接，需移除 `main.gd` 中的重複連接

### L4 — audio_manager.gd：play_bgm 函數的 BGM 路徑邏輯使用 SFX_MAP
- **位置**：第 92-95 行
- `play_bgm` 查詢的是 `SFX_MAP`，而非獨立的 `BGM_MAP`
- 目前 BGM 皆以 `res://` 完整路徑傳入，邏輯上不影響執行，但語意混亂
- **建議**：新增 `BGM_MAP` 字典，或在函數說明中標記此行為為已知設計

### L5 — character.gd fire_shot：直接引用 AudioManager Autoload（非 get_node_or_null）
- **位置**：第 112-115 行
- 使用全域 `AudioManager.play_sfx()`，若 AudioManager 未載入（測試環境或 headless）會靜默失敗
- 全專案均如此使用，屬一致性設計，可接受

### L6 — tutorial_manager.gd：notify_ult_used / notify_ult_ready 的呼叫端不存在
- **位置**：第 131-148 行定義了 `notify_ult_used` 和 `notify_ult_ready` 等公開方法
- **問題**：`hud.gd` 的 `_on_ultimate_pressed` 和 `_on_ultimate_ready` 中**沒有呼叫** `TutorialManager.notify_ult_used` / `notify_ult_ready`
- 教學步驟 4（大招教學）和步驟 5（CD 說明）依賴這兩個回呼，若不呼叫，步驟 4 的計時器由 `_combat_timer` 兜底，但步驟 5 會靠自動隱藏計時器，只是時機不準確
- **嚴重度**：影響教學體驗，但不 crash
- **建議**：在 `hud.gd _on_ultimate_pressed` 後加入 `TutorialManager.notify_ult_used(member.char_id)`；在 `hud.gd _on_ultimate_ready` 中加入 `TutorialManager.notify_ult_ready(member.char_id)`

### L7 — squad_controller.gd：traveled_distance 在 replace_remaining_path 後不重置可能累積超過 total_distance
- **位置**：第 94-106 行 `replace_remaining_path()`
- 切換路徑後 `traveled_distance` 未重置，但 `total_distance` 重新計算，`ratio = traveled_distance / total_distance` 在新路徑下可能超過 1.0（clamp 保護後為 1.0，但不準確）
- **建議**：`replace_remaining_path` 末段加入 `traveled_distance = 0.0`

---

## 一致性驗證結果

### characters.json vs main.gd CHAR_DATA
| 欄位 | 結論 |
|------|------|
| id（6個）| 完全一致：shield / medic / assault / sniper / demo / recon |
| max_hp（Lv.1）| 完全一致：200/130/155/110/135/140 |
| attack（Lv.1）| 完全一致：30/20/60/120/80/35 |
| defense（Lv.1）| shield=25 一致；其餘 main.gd 設 0，但 JSON 中 medic=15、assault=15 等有 def 值 |
| ultimate_cd（Lv.1）| 完全一致：30/40/25/35/45/35 |

**注意（不一致項目）**：
- `main.gd` 中 medic / assault / sniper / demo / recon 的 `defense` 均設為 `0.0`，但 `characters.json` 的 base_stats 中這些角色在 Lv.1 有 def 值（medic=15, assault=15, sniper=10, demo=18, recon=17）
- **影響**：遊戲中上述角色無防禦減傷，與 JSON 規格不符（盾兵正確 = 25）
- **建議**：由技術組對照 JSON 補齊 main.gd 的 defense 欄位，或確認是設計決策

### SaveManager.DEFAULT_LEVELS vs GachaManager.ALL_CHARS
| 項目 | DEFAULT_LEVELS | ALL_CHARS |
|------|----------------|-----------|
| 包含 key | shield/medic/assault/sniper/demo/recon（6個）| 同上（6個）|
| 結論 | 完全一致 |

### SaveManager.owned_characters 初始值 vs base.gd ALL_CLASSES
- `owned_characters` 初始 = `["shield", "assault", "medic"]`（3 個）
- `ALL_CLASSES` 有 6 個職業
- 初始解鎖 3 個，其餘鎖定顯示為 `[鎖定]`，行為符合設計預期

---

## 已確認正常的項目

- **Null 安全**：所有 `get_node()` 呼叫均使用 `get_node_or_null()`（共 14 處），未發現裸 `get_node()` 後直接存取屬性
- **is_instance_valid 保護**：squad_members 遍歷、enemies 遍歷均有 `is_instance_valid()` 雙重保護
- **Array 越界**：`squad_members` 迴圈均用 `for member in`（無索引存取），`waypoints[i+1]` 在 `i < size-1` 條件保護下存取，`_sfx_pool[0]` 在 pool_size=8 固定大小下安全
- **Signal 定義完整**：game_manager 的 5 個 signal、character 的 4 個 signal、room 的 1 個 signal 均已在檔案頂部 `signal` 宣告，emit 呼叫對應正確
- **場景路徑**：`change_scene_to_file` 使用路徑 `res://scenes/Main.tscn` 和 `res://scenes/Base.tscn`（均合理）；`load("res://scenes/GachaPanel.tscn")` 和 `load("res://scenes/UpgradePanel.tscn")`（均合理）
- **GachaManager.ALL_CHARS 保底邏輯**：`_no_new_streak` 計數正確遞增/重置，`unowned` 過濾邏輯正確
- **SaveManager 讀寫一致性**：save/load 欄位對稱，version migration 不需要（首次讀不到 key 有預設值保護）
- **GameManager Buff 計時器**：3 個 buff 倒計時（shield/assault/recon）均在 `_process` 中正確處理，不會負數
- **character.gd get_cd_ratio**：`ultimate_cd <= 0` 有保護，不除以零
- **enemy.gd `die()` 延遲移除**：使用 `create_timer(0.3).timeout.connect(queue_free)`，room.gd 在 `_on_enemy_died` 中延遲 0.4 秒確認，時間差正確（0.4 > 0.3）

---

## 建議改善（優先度低）

1. **統一大招音效呼叫**：`hud.gd` 呼叫 `AudioManager.play_ult(member.char_id)`，使用英文 char_id；`ULT_MAP` 同時收錄中文與英文 key，雙份設定日後維護成本高 — 建議統一只用英文 char_id
2. **decision_trigger.gd 的 BASE_DECISION_DATA 與 main.gd 的 inline decision_data 重複**：main.gd 自行建立房間決策資料（第 261-270 行），與 decision_trigger.gd 中的 BASE_DECISION_DATA["room"] 重複，建議抽成共用常數
3. **enemy.gd Phase 2 未實作**：characters.json enemies 中 boss_manager 定義了 `phase2_threshold` 和 `phase2_atk_interval`，但 enemy.gd 沒有 Phase 2 邏輯，Boss 數值設計無法完整體現

---

## Headless 測試結果

```
指令：C:\Godot\Godot_v4.6.3-stable_win64_console.exe --headless --path d:\開發遊戲\遊戲\幽靈行動\src --quit
結果：通過（無錯誤輸出）
```

**注意 headless 測試盲點**：本次測試僅能驗證腳本語法與 Autoload 初始化。以下問題 headless 無法偵測：
- `@onready` 節點路徑是否正確（hud.gd 的 Panel/VBox/TitleLabel 等路徑）
- 場景節點結構（DecisionPanel/Root 的實際子節點是否存在）
- Boss 決策點與 Boss 房觸發點重疊（M3）的運行時行為
