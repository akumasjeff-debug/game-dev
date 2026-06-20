# 台灣熱炒王 — 整合測試計畫

版本：v1.0
日期：2026-06-20
撰寫：品管組（測試員）

---

## 重要前置說明

**OrderManager 尚未加入 project.godot 的 autoload 設定。**
目前 project.godot 中只列了 9 個 AutoLoad（缺少 OrderManager）。
TC-01 執行前，請先確認 project.godot 的 `[autoload]` 區塊是否已補上：
```
OrderManager="*res://scripts/systems/OrderManager.gd"
```
若未補上，TC-04 訂單流程測試將無法執行。

---

## TC-01：10 個 AutoLoad 全部載入

**測試類別：** AutoLoad
**前置條件：** 已在 Godot 4 編輯器開啟 `d:\開發遊戲\台灣熱炒王\src\` 作為專案根目錄；OrderManager 已加入 autoload 設定
**操作步驟：**
1. 開啟 Godot 4 編輯器，確認專案已載入
2. 按 F5 執行遊戲（或點選頂部「播放」按鈕）
3. 等待遊戲啟動完成（約 3 秒）
4. 開啟底部「Output」面板，滾動至最頂端查看啟動訊息

**預期結果：** Output 面板應依序出現以下訊息（順序與 project.godot autoload 載入順序一致）：
```
[GameManager] 初始化完成，Year 1 Day 1
[EventManager] 載入完成，共 X 個事件
[AudioManager] 初始化完成，BGM bus=BGM SFX bus=SFX
[TutorialManager] 初始化完成，共 9 步驟
[OrderManager] 初始化完成
[Main] 主場景初始化
```
注意：PathfindingManager、SeatManager、MenuManager、BuildManager 的 `_ready()` 無 print 輸出，不在此清單中，但不應出現 `ERROR` 或 `SCRIPT ERROR` 字樣。
MenuManager 的 print 被 `#` 註解掉，為正常現象。

**常見失敗原因：**
- `SCRIPT ERROR: Parse Error` — GDScript 語法錯誤，點選錯誤訊息可跳到對應行
- `ERROR: Failed to instantiate autoload node` — autoload 路徑錯誤（注意大小寫）；Godot 4 路徑區分大小寫，`PathfindingManager.gd` 與 `pathfindingmanager.gd` 不同
- TutorialManager 顯示「共 0 步驟」— `_build_day1_steps()` 執行失敗，確認 `_steps` 陣列賦值正確
- OrderManager 訊息不出現 — 確認 project.godot 已加入 OrderManager autoload

**嚴重程度：** Critical

---

## TC-02：初始地圖 Zone 正確設定

**測試類別：** 場景
**前置條件：** TC-01 通過；遊戲正在執行中
**操作步驟：**
1. 按 F5 執行遊戲
2. 等待 Output 面板出現 `[game.gd] 地圖 Zone 初始化完成`
3. 按 F8 暫停遊戲（或使用「遊戲內偵錯工具」）
4. 在 Godot 編輯器上方選單點選「Debugger」→「Remote」標籤
5. 在 Remote SceneTree 中找到 BuildManager 節點（位於 /root/BuildManager）
6. 點選 BuildManager，在右側 Inspector 查看 `zone_map` 屬性，確認以下格子的 ZoneType 值

依 `game.gd` 的 `_init_map_zones()`，座標系統為 Vector2i(x, y)，從 (0,0) 起算：

**預期結果（對照 design/initial-map.md）：**

廚房區（KITCHEN = 1）：
- Vector2i(1, 1)、(2, 1)、(3, 1)、(4, 1)、(5, 1)、(6, 1)
- Vector2i(1, 2)、(2, 2)、(3, 2)、(4, 2)、(5, 2)、(6, 2)
共 12 格，ZoneType 應為 1（KITCHEN）

走道區（WALKWAY = 3）：
- Vector2i(1, 3)、(2, 3)、(3, 3)、(4, 3)、(5, 3)、(6, 3)
共 6 格，ZoneType 應為 3（WALKWAY）

外場區（SEATING = 2）：
- Vector2i(1, 4)、(2, 4)、(3, 4)、(4, 4)、(5, 4)、(6, 4)
共 6 格，ZoneType 應為 2（SEATING）

設備應在 `equipment_map` 中：
- Vector2i(1, 1) → "stove_wok_lv1"
- Vector2i(3, 2) → "counter_serving"
- Vector2i(2, 4) → "table_4p_a"
- Vector2i(5, 4) → "table_4p_b"

Output 面板確認：
```
[game.gd] 地圖 Zone 初始化完成
[game.gd] 初始設備放置完成
```

**常見失敗原因：**
- zone_map 為空 Dictionary — game.gd 的 `_init_map_zones()` 未被呼叫；確認 Game.tscn 根節點有掛 game.gd 腳本
- ZoneType 數值錯誤 — BuildManager.ZoneType enum 定義順序：EMPTY=0, KITCHEN=1, SEATING=2, WALKWAY=3, STORAGE=4, DECORATION=5
- 設備 ID 不在 equipment_map — `place_equipment()` 呼叫失敗，確認格子座標未超出 MAP_WIDTH(16)、MAP_HEIGHT(10) 範圍

**嚴重程度：** Critical

---

## TC-03：客人生成正常

**測試類別：** AI
**前置條件：** TC-01 通過；game.gd 的 `_spawn_test_customer()` 已啟用
**操作步驟：**
1. 按 F5 執行遊戲
2. 觀察 Output 面板，等待出現以下訊息：
   ```
   [game.gd] 測試客人已生成，位置: (60, 80)
   [CustomerAI] 客人生成，初始狀態 ENTERING
   ```
3. 按 F8 暫停遊戲
4. 在 Godot 編輯器的 Remote SceneTree 中展開 `/root/Main/Game/characters`（若找不到，確認場景結構是否有 characters 節點）
5. 確認 SceneTree 中出現一個 CustomerAI 節點
6. 點選該節點，在 Inspector 確認：
   - `_current_state` = 0（對應 State.ENTERING）
   - `patience` = 1.0
   - `seated` = false

**預期結果：** SceneTree 中可見一個 CustomerAI 節點；`_current_state` 為 ENTERING（0）；Output 面板無任何 `ERROR` 字樣；CustomerAI 節點已自動加入 "customers" group（可在 Remote SceneTree 的節點屬性中確認）

**常見失敗原因：**
- 找不到 characters 節點 — Game.tscn 中未建立 characters 子節點，game.gd 會 fallback 直接 add_child 到 Game 根節點，不影響功能但 Scene Tree 路徑不同
- CustomerAI 節點未在 group "customers" — customer_ai.gd 的 `_ready()` 中應呼叫 `add_to_group("customers")`，確認此行存在
- `[CustomerAI] 客人生成` 訊息出現但節點不可見 — 確認 Game.tscn 在場景中有被正確載入（Main.tscn 應有引用 Game.tscn）

**嚴重程度：** High

---

## TC-04：訂單完整循環

**測試類別：** 訂單流程
**前置條件：** TC-01 通過（OrderManager 已載入）；TC-03 通過（客人節點存在）；員工節點已生成（TC-03 中 StaffAI 也已生成）
**操作步驟：**

> 此測試透過 Godot 4 的 GDScript REPL（Debugger → DebugConsole）手動驅動訂單流程。

1. 按 F5 執行遊戲，等待遊戲完全初始化
2. 按 F8 暫停遊戲
3. 開啟 Godot 編輯器「Debugger」面板，切換至「Locals」或「Errors」，確認無 SCRIPT ERROR
4. 在 Remote SceneTree 找到 StaffAI 節點，記錄其 node.name（例："StaffAI"）
5. 恢復遊戲（F8 再按一次），在 Output 面板確認 CustomerAI 已生成，記錄其節點 name（例："CustomerAI"）
6. 使用 Remote SceneTree，選取 OrderManager 節點，在 Inspector 手動驗證以下流程：

   **步驟 4a：place_order**
   - 在 Godot Debugger 的遠端呼叫或透過臨時測試腳本執行：
     ```gdscript
     OrderManager.place_order("CustomerAI", "chicken_3cup", Vector2i(2, 4))
     ```
   - Output 預期：`[OrderManager] 訂單 order_001 建立：chicken_3cup（客人 CustomerAI）`

   **步驟 4b：assign_to_chef**
   - 執行：
     ```gdscript
     OrderManager.assign_to_chef("order_001", "StaffAI")
     ```
   - Output 預期：`[OrderManager] 訂單 order_001 指派給廚師 StaffAI`
   - 同時應出現：`[StaffAI] 開始執行任務：order_001`

   **步驟 4c：complete_cooking**
   - 執行：
     ```gdscript
     OrderManager.complete_cooking("order_001")
     ```
   - Output 預期：`[OrderManager] 訂單 order_001 完成烹飪，等待外場取餐`

   **步驟 4d：deliver_to_table**（若有閒置外場員工，complete_cooking 會自動觸發）
   - 若未自動觸發，手動執行：
     ```gdscript
     OrderManager.deliver_to_table("order_001", "StaffAI")
     ```
   - Output 預期：`[OrderManager] 訂單 order_001 由 StaffAI 送達`

   **步驟 4e：complete_payment**（deliver_to_table 會自動呼叫）
   - Output 預期：`[OrderManager] 客人 CustomerAI 結帳 $150.0`
   - 同時 GameManager 的 money 應從 10000 增加到 10150

7. 在 Remote SceneTree 確認 GameManager 的 `money` 屬性為 10150.0

**預期結果：** 全部 5 個階段的 print 訊息依序出現；`_orders["order_001"]["status"]` 最終為 "done"；`GameManager.money` 為 10150.0

**常見失敗原因：**
- `assign_to_chef` 找不到員工節點 — StaffAI 節點的 `name` 必須完全符合傳入的 staff_id；確認節點名稱拼寫
- `deliver_to_table` 找不到客人節點 — CustomerAI 節點的 `name` 必須完全符合 customer_id；確認 `receive_food()` 方法存在於 customer_ai.gd
- 訂單狀態卡在 "cooking" — `_find_node_by_name_in_group` 找不到員工，檢查員工是否已加入 "staff" group

**嚴重程度：** Critical

---

## TC-05：TutorialManager Day 1 步驟序列

**測試類別：** 訂單流程 / 場景
**前置條件：** TC-01 通過；全新遊戲（無存檔）；GameManager.current_year=1、current_day=1
**操作步驟：**
1. 確認無存檔（刪除 `user://saves/save_01.json`，Windows 路徑通常為 `%AppData%\Godot\app_userdata\台灣熱炒王\saves\`）
2. 按 F5 執行遊戲
3. 等待 `[TutorialManager] 初始化完成，共 9 步驟` 出現
4. 等待 GameManager 時間推進到 17:00（約需等待現實時間 30 秒 × 9 小時差距 = 4.5 分鐘，或暫時修改 `SECONDS_PER_GAME_HOUR` 為 1.0 加速測試）
5. 觀察 Output 面板，應出現 `[GameManager] Day 1 Year 1 開始營業`，緊接著：
   ```
   [TutorialManager] 教學開始，第 1 步：on_game_start
   ```
6. 在 Debugger 中呼叫各步驟的完成條件，逐步推進：
   - 步驟 1 完成：`TutorialManager.complete_current_step("on_screen_tapped")`
   - 預期：`[TutorialManager] 步驟 1 完成，條件：on_screen_tapped`
   - 預期：`[TutorialManager] 進入步驟 2：on_step1_complete`
7. 繼續對每個步驟呼叫對應的 condition_id，確認步驟依序推進直到步驟 9
8. 步驟 9 完成後，呼叫 `TutorialManager.complete_current_step("on_day_settlement_confirmed")`
9. 觀察 Output 面板

**預期結果：**
- `[TutorialManager] Day 1 教學完成，解除教學保護，觸發開業補貼事件。`
- `TutorialManager.is_tutorial_active` 變為 false
- `TutorialManager.tutorial_protection_active` 變為 false
- EventManager 觸發 "event_subsidy" 事件（Output 應出現 `[EventManager] 觸發事件：event_subsidy`）
- 傳送錯誤的 condition_id 不應推進步驟（例：在步驟 2 時呼叫 "on_cooking_done" 應被忽略，無訊息輸出）

**常見失敗原因：**
- 教學未自動啟動 — `TutorialManager._on_game_day_started` 未收到信號；確認 `GameManager.day_started` 信號連接成功
- `complete_current_step` 呼叫後無任何 print — `is_tutorial_active` 為 false，表示教學未正確啟動
- event_subsidy 未觸發 — EventManager.has_method("trigger_event") 回傳 false，或 events.json 中無 "event_subsidy" 事件

**嚴重程度：** High

---

## TC-06：存檔 / 讀檔

**測試類別：** 存讀檔
**前置條件：** TC-01 通過；遊戲執行中
**操作步驟：**
1. 按 F5 執行遊戲，等待初始化完成
2. 透過 Debugger 手動修改 GameManager 數值：
   ```gdscript
   GameManager.add_money(5000.0)         # money 應為 15000
   GameManager.add_reputation(50)         # reputation 應為 50
   ```
3. 執行存檔：
   ```gdscript
   var data = GameManager.export_save_data()
   SaveManager.save_game(data)
   ```
4. 確認 Output 無錯誤，且以下路徑存在存檔檔案：
   Windows：`%AppData%\Godot\app_userdata\台灣熱炒王\saves\save_01.json`
5. 用文字編輯器開啟 save_01.json，確認內容結構：
   ```json
   {
     "version": 1,
     "save_date": "...",
     "game_data": {
       "year": 1,
       "day": 1,
       "money": 15000.0,
       "reputation": 50,
       "staff_morale": 100.0
     }
   }
   ```
6. 按 F8 暫停遊戲，使用 Debugger 將 money 改回 10000：
   ```gdscript
   GameManager.money = 10000.0
   ```
7. 執行讀檔：
   ```gdscript
   var loaded = SaveManager.load_game()
   GameManager.apply_save_data(loaded["game_data"])
   ```
8. 確認 GameManager.money 回到 15000.0、reputation 回到 50

**預期結果：**
- 存檔後 `user://saves/save_01.json` 存在且格式正確
- 讀檔後 GameManager 數值與存檔一致（money=15000、reputation=50）
- Output 應出現 `save_completed` 信號觸發（若有 UI 連接信號）
- Output 無任何 `push_error` 輸出

**常見失敗原因：**
- 存檔目錄建立失敗 — `user://saves/` 目錄沒有寫入權限（極少見）；`DirAccess.open("user://")` 回傳 null
- JSON 解析失敗 — save_01.json 被其他程式佔用或格式損毀
- `apply_save_data` 後數值未更新 — 確認 `GameManager.apply_save_data()` 中有正確發出 `money_changed` 等信號

**嚴重程度：** Critical

---

## TC-07：HUD 顯示正確

**測試類別：** HUD
**前置條件：** TC-01 通過；UI.tscn 已正確載入（Main.tscn 包含 UI.tscn）
**操作步驟：**
1. 按 F5 執行遊戲
2. 等待 Output 出現：
   ```
   [hud.gd] GameManager 信號連接完成（AutoLoad）
   [hud.gd] EventManager 信號連接完成（AutoLoad）
   ```
3. 觀察遊戲畫面左上角，確認 HUD Label 已顯示初始值：
   - 金錢：`$10000`（位置 x=8, y=4）
   - 日期：`Year 1 - Day 1`（位置 x=180, y=4）
   - 聲望：`聲望: 0`（位置 x=380, y=4）
4. 透過 Debugger 觸發數值變動：
   ```gdscript
   GameManager.add_money(1000.0)
   GameManager.add_reputation(25)
   ```
5. 觀察 HUD 畫面，確認即時更新：
   - 金錢 Label 更新為 `$11000`
   - 聲望 Label 更新為 `聲望: 25`
6. 等待 GameManager 時間推進到 17:00 觸發 day_started 信號，確認日期 Label 更新

**預期結果：**
- HUD Label 在遊戲畫面可見（白色文字）
- 數值變動後 Label 即時更新，不需要手動刷新
- 日期 Label 在 day_started 信號觸發後格式為 `Year X - Day X`
- 若 Output 出現 `[hud.gd] 找不到 GameManager，跳過信號連接` — 這是失敗訊號

**常見失敗原因：**
- HUD 不顯示 — UI.tscn 根節點未掛 hud.gd 腳本；或 UI.tscn 未被 Main.tscn 引用
- 數值不更新 — 信號連接失敗（hud.gd 使用雙重機制：先嘗試 `Engine.has_singleton`，再嘗試 `get_node_or_null`）；確認 `/root/GameManager` 路徑可找到節點
- Label 位置重疊或超出螢幕 — 確認視窗解析度設定（project.godot 設定為 480x270）

**嚴重程度：** High

---

## TC-08：佔位 PNG 載入正常

**測試類別：** 美術資源
**前置條件：** Python 工具 `src/tools/generate_placeholders.py` 已執行完成（佔位 PNG 存在）
**操作步驟：**
1. 確認以下目錄中的 PNG 檔案存在（共 20 個）：
   - `src/assets/sprites/characters/`：char_boss_idle.png、char_boss_walk.png、char_chef_idle.png、char_chef_walk.png、char_customer_a_idle.png、char_customer_a_walk.png（6 個）
   - `src/assets/sprites/equipment/`：equip_wok_active.png、equip_wok_static.png、table_2p.png、table_4p.png（4 個）
   - `src/assets/sprites/tiles/`：tile_floor_kitchen.png、tile_road.png、tile_floor_corridor.png、tile_floor_dining.png、tile_wall_brick.png（5 個）
   - `src/assets/sprites/ui/`：hud_icon_coin.png、hud_icon_star.png、hud_bg_top.png、hud_bg_bottom.png、btn_build.png（5 個）
2. 在 Godot 編輯器的 FileSystem 面板確認上述路徑可見且有 `.import` 對應檔
3. 在 Debugger 中執行資源載入測試：
   ```gdscript
   var test_paths = [
     "res://assets/sprites/characters/char_boss_idle.png",
     "res://assets/sprites/equipment/table_4p.png",
     "res://assets/sprites/tiles/tile_floor_kitchen.png",
     "res://assets/sprites/ui/hud_icon_coin.png"
   ]
   for p in test_paths:
     var tex = ResourceLoader.load(p)
     if tex == null:
       print("FAIL: ", p)
     else:
       print("OK: ", p)
   ```
4. 確認全部 4 個（代表性樣本）回傳 OK

**預期結果：**
- 全部 20 個 PNG 在 Godot FileSystem 面板可見
- ResourceLoader.load() 對所有測試路徑回傳非 null 的 Texture2D 資源
- Output 面板不出現 `ERROR: Failed to load resource`
- Godot 編輯器啟動時不出現大量「缺少 .import 檔」警告

**常見失敗原因：**
- `.import` 檔不存在 — 第一次在 Godot 中開啟此專案時，需等待 Godot 完成初始 import 掃描（底部進度條）
- 路徑大小寫錯誤 — Godot 在 Windows 上路徑不區分大小寫，但在 Android/Linux 上區分；統一使用小寫確保跨平台相容
- PNG 檔案損毀 — 重新執行 `generate_placeholders.py` 重新生成

**嚴重程度：** Medium

---

## TC-09：音效系統基礎播放

**測試類別：** AutoLoad / 音效
**前置條件：** TC-01 通過；AudioManager 初始化訊息已出現
**操作步驟：**
1. 按 F5 執行遊戲，確認 Output 出現：
   ```
   [AudioManager] 初始化完成，BGM bus=BGM SFX bus=SFX
   ```
2. 在 Remote SceneTree 找到 `/root/AudioManager` 節點，展開確認有兩個子節點：`BGMPlayer` 和 `SFXPlayer`
3. 在 Godot Debugger 中執行音量調整測試：
   ```gdscript
   AudioManager.bgm_volume = 0.5
   AudioManager.sfx_volume = 0.8
   print("BGM vol: ", AudioManager.bgm_volume)   # 應印 0.5
   print("SFX vol: ", AudioManager.sfx_volume)   # 應印 0.8
   ```
4. 確認音量值在 0.0~1.0 範圍內被正確 clamp（嘗試設 1.5，應被限制為 1.0）：
   ```gdscript
   AudioManager.bgm_volume = 1.5
   print("Clamped: ", AudioManager.bgm_volume)   # 應印 1.0
   ```
5. 確認 AudioBus 設定正確：在 Godot 編輯器下方「Audio」面板，確認存在名為 BGM 和 SFX 的 Bus

**預期結果：**
- AudioManager 節點下存在 BGMPlayer 和 SFXPlayer 子節點
- 音量屬性 setter 正確執行 clamp（0.0~1.0）
- AudioBus "BGM" 和 "SFX" 存在於 Godot Audio 設定（若不存在，播放音效時會出現 bus 不存在的警告）

**常見失敗原因：**
- BGMPlayer 的 bus 找不到 — Godot 專案需手動在 Audio > Bus Layout 中建立 BGM 和 SFX 兩個 Bus；若未建立，AudioStreamPlayer 會 fallback 到 Master，但不 crash
- AudioManager 節點未出現在 SceneTree — autoload 路徑設定錯誤；確認 project.godot 中路徑大小寫與實際檔案一致（`audio_manager.gd`）

**嚴重程度：** Medium

---

## TC-10：建造模式 Zone 驗證

**測試類別：** 場景
**前置條件：** TC-02 通過（zone_map 已正確初始化）
**操作步驟：**
1. 按 F5 執行遊戲，等待初始化完成
2. 在 Debugger 中執行設備放置驗證：

   **驗證合法放置（廚房格）：**
   ```gdscript
   var can_place = BuildManager.check_placement(
     Vector2i(2, 1), Vector2i(1, 1), BuildManager.ZoneType.KITCHEN
   )
   print("廚房空格放置：", can_place)   # 應為 true
   ```

   **驗證非法放置（在外場格放廚房設備）：**
   ```gdscript
   var illegal = BuildManager.check_placement(
     Vector2i(1, 4), Vector2i(1, 1), BuildManager.ZoneType.KITCHEN
   )
   print("外場放廚房設備：", illegal)   # 應為 false
   ```

   **驗證重疊放置（已有設備的格子）：**
   ```gdscript
   var overlap = BuildManager.check_placement(
     Vector2i(1, 1), Vector2i(1, 1), BuildManager.ZoneType.KITCHEN
   )
   print("已有爐台的格子：", overlap)   # 應為 false（stove_wok_lv1 已佔用）
   ```

   **驗證超界放置：**
   ```gdscript
   var out_of_bounds = BuildManager.check_placement(
     Vector2i(15, 9), Vector2i(2, 2), BuildManager.ZoneType.KITCHEN
   )
   print("超出地圖邊界：", out_of_bounds)   # 應為 false
   ```

3. 測試設備移除與再放置：
   ```gdscript
   BuildManager.remove_equipment(Vector2i(1, 1))
   var after_remove = BuildManager.check_placement(
     Vector2i(1, 1), Vector2i(1, 1), BuildManager.ZoneType.KITCHEN
   )
   print("移除後可再放置：", after_remove)   # 應為 true
   ```

**預期結果：** 全部 5 個驗證回傳預期的 true/false；`equipment_removed` 信號在 remove_equipment 後發出

**常見失敗原因：**
- 全部 check_placement 回傳 false — zone_map 為空，代表 TC-02 的前置條件未滿足
- 移除後無法重新放置 — `_equipment_origin` 字典未正確清除，`equipment_map` 仍有殘留項目

**嚴重程度：** High

---

## TC-11：隨機事件觸發

**測試類別：** 場景
**前置條件：** TC-01 通過；`src/resources/data/events.json` 存在且格式正確
**操作步驟：**
1. 按 F5 執行遊戲
2. 確認 Output 出現 `[EventManager] 載入完成，共 X 個事件`（X 應大於 0）
3. 使用 Debugger 手動觸發一個事件：
   ```gdscript
   EventManager.trigger_event("event_subsidy")
   ```
4. 觀察 Output 面板，應出現：
   ```
   [EventManager] 觸發事件：event_subsidy（...）
   ```
5. 確認 HUD 的 `_message_label` 出現事件名稱文字（位於畫面 x=8, y=258）
6. 等待 3 秒，確認訊息自動消失（由 hud.gd 的 `create_timer(3.0)` 控制）
7. 測試防止重複觸發：在同一天內連續呼叫兩次同一事件，確認第二次不重複觸發
   ```gdscript
   EventManager.trigger_event("event_subsidy")
   EventManager.trigger_event("event_subsidy")
   # Output 應只出現一次觸發訊息
   ```

**預期結果：**
- `trigger_event` 呼叫後 Output 出現觸發訊息
- HUD 顯示事件名稱 3 秒後消失
- 同一天同一事件不重複觸發（`_triggered_today` 防護機制生效）

**常見失敗原因：**
- `[EventManager] 載入完成，共 0 個事件` — events.json 為空陣列或 JSON 格式錯誤；開啟 `src/resources/data/events.json` 確認結構
- 事件觸發後 HUD 無顯示 — hud.gd 的 EventManager 信號連接失敗；確認 Output 有 `[hud.gd] EventManager 信號連接完成`
- 找不到 trigger_event 方法 — EventManager.gd 中確認 `trigger_event(event_id: String)` 方法存在

**嚴重程度：** High

---

## TC-12：MenuManager 菜品資料載入

**測試類別：** AutoLoad
**前置條件：** TC-01 通過；`src/resources/data/dishes.json` 存在
**操作步驟：**
1. 按 F5 執行遊戲（注意：MenuManager 的 `_ready()` print 被註解掉，不會有初始化訊息）
2. 在 Debugger 中驗證菜品資料：
   ```gdscript
   var dishes = MenuManager.get_available_dishes()
   print("已解鎖菜品數量：", dishes.size())
   for dish in dishes:
     print("  - ", dish["id"], "：", dish["name"], "（$", dish["price"], "）")
   ```
3. 確認至少有以下初始菜品存在（對照 content/dishes.md 規格）：
   - 三杯雞（chicken_3cup）
   - 炒蛤蜊（clam_stir_fry）
   - 台啤（taiwan_beer）
4. 測試 `get_dish_by_id`：
   ```gdscript
   var chicken = MenuManager.get_dish_by_id("chicken_3cup")
   print("三杯雞資料：", chicken)
   # 預期：{ "id": "chicken_3cup", "name": "三杯雞", "price": ..., ... }
   ```
5. 測試鎖定菜品（未解鎖的菜品不應出現在 get_available_dishes）

**預期結果：**
- `get_available_dishes()` 回傳非空陣列
- 初始解鎖的菜品可正確查詢到資料
- `get_dish_by_id()` 傳入不存在的 ID 應回傳 null 或空 Dictionary（不 crash）

**常見失敗原因：**
- `get_available_dishes()` 回傳空陣列 — dishes.json 中所有菜品的 `"unlocked"` 欄位為 false，或 JSON 格式錯誤
- MenuManager 沒有 print 訊息確認 — 需在 MenuManager.gd 第 61 行移除 `#` 取消 print 的註解暫時確認載入數量

**嚴重程度：** High

---

## 測試環境需求

| 項目 | 規格 |
|------|------|
| Godot 版本 | 4.3 以上（project.godot config/features 指定） |
| 作業系統 | Windows 11（主要開發環境）；macOS 12+ 亦可 |
| 目標平台 | Mobile（project.godot 設定 `config/features=["Mobile"]`） |
| 螢幕解析度 | 480x270 原生；測試視窗預設不可縮放 |
| 執行裝置 | PC 開發機（測試優先）；手機部署測試為次要 |
| 必要工具 | Python 3.8+（執行 generate_placeholders.py） |
| 存檔路徑 | Windows：`%AppData%\Godot\app_userdata\台灣熱炒王\saves\` |

---

## 測試執行順序建議

依相依性排序，Critical 優先執行：

```
第一輪（Critical — 遊戲能否啟動）：
  TC-01 → TC-02 → TC-06

第二輪（High — 核心功能可運作）：
  TC-04 → TC-03 → TC-07 → TC-10 → TC-11 → TC-12

第三輪（Medium — 功能完整性）：
  TC-05 → TC-08 → TC-09
```

**注意：** TC-04 依賴 TC-01 但不強制依賴 TC-03（可手動指定 ID）；TC-05 依賴 TC-01 且建議搭配加速時間（修改 `SECONDS_PER_GAME_HOUR` 為 `1.0`）進行測試。

---

## 快速冒煙測試（Smoke Test）

「60 秒內能驗證基本可玩性」的最快速驗證方法：

**Smoke A — 啟動不當機（10 秒）**
按 F5 執行遊戲，等待 3 秒，確認畫面出現且 Output 面板無 `SCRIPT ERROR` 或紅色錯誤訊息。看到 `[GameManager] 初始化完成` 即為通過。

**Smoke B — HUD 可見（20 秒）**
在 Smoke A 基礎上，觀察遊戲畫面左上角是否有白色文字顯示 `$10000` 和 `Year 1 - Day 1`。若 HUD 可見，代表 GameManager + UI.tscn + hud.gd 三層連動正常。

**Smoke C — 存檔不崩潰（30 秒）**
在 Debugger 中執行：
```gdscript
SaveManager.save_game(GameManager.export_save_data())
```
若 Output 無錯誤，且 `%AppData%\Godot\app_userdata\台灣熱炒王\saves\save_01.json` 存在，代表核心存讀系統正常。

三個 Smoke Test 全部通過，可認定遊戲達到「基本可執行」狀態，再進行完整測試計畫。
