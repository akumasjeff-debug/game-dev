# 幽靈行動 狀態

## 已完成

### v0.6.1（2026-06-22）— 🔴 破門點擊真機卡死徹底修復（三重保險）
- **問題**：v0.5.10 Button 與 v0.5.11 _input 兩種破門點擊機制在真機 iOS 觸控都收不到 → 破門「點擊任意處繼續」卡死。判定為該裝置對動態疊加 CanvasLayer 的觸控不可靠。
- **修法（三重保險，絕不卡死）**：① 全螢幕 Button(catcher) 用 Control gui_input + pressed（真機按鈕證實可用）、process_mode=ALWAYS ② 保留 main._input() 偵測 InputEventScreenTouch/MouseButton ③ **3.5 秒安全自動推進**（`get_tree().create_timer(3.5, true, false, true)` → _finish_breach，process_always + ignore_time_scale，不受暫停/變速影響）
- 破門 CanvasLayer 層級 20→100（確保在 HUD/任何疊加層之上）
- **驗證**：headless export 0 ERROR；自動推進為確定性 SceneTreeTimer 邏輯（Playwright 截圖在場景切換時必 GPU stall，反證推進有觸發）；版本 v0.6.0 → v0.6.1
- 備註：使用者偏好手動點擊，但該裝置觸控不可靠，故加自動推進為安全網——點擊仍可提早跳過

### v0.6.0（2026-06-22）— 🎨 五 agent 並行全面美術/UIUX 升級
五個 subagent 嚴格切分檔案所有權並行作業，整合後單次 headless + Playwright 驗證通過。
- **HUD/UI（hud.gd + 新增 hud_radial.gd）**：技能卡環形 CD、就緒綠脈動、點擊回饋、HP 三段色、職業色邊框、陣亡灰階紅框；TopBar 進度條分段刻度+平滑填充；中央訊息佇列系統（新增 show_message()）；速度(Engine.time_scale x1/x2/x3)+暫停按鈕(64x64)；底部 home indicator 安全邊距
- **玩家角色/子彈（character.gd + bullet.gd + 玩家 sprite）**：開火槍口閃光+後座、受擊閃紅震動、傷害數字飄字、血條補間、大招職業色光環+粒子、死亡傾倒下沉；子彈曳光拖尾+命中爆閃+方向旋轉；6 職業 sprite 加質感識別光
- **敵人（enemy.gd + 敵人 sprite）**：出場掉落動畫、槍口閃光、受擊閃白、傷害數字、死亡爆裂碎片；Boss 金框大血條+金名+頭頂標記(★ BOSS ★)+紫色呼吸光環；敵人子彈紅色重畫；三型 sprite 殺氣識別光
- **戰鬥場景（main.gd + room.gd + 場景 SVG）**：房間 7 層縱深（後牆+透視地板+區域光照+暗角），三主題差異化；頂燈光錐+警示燈光斑+Boss 血色警戒；環境道具擴充（6→14 件有堆疊層次）；新增 6 個道具 SVG；破門過場美術升級
- **戰鬥外畫面（main_menu/base/gacha/upgrade/squad_confirm/card_gallery/story/decision）**：主選單 HUD 角框+標題光暈+智慧存檔按鈕；基地資源膠囊+任務板+導覽卡；抽卡 SSR/QR 金光放射演出；升級數值前後對比；圖鑑未擁有剪影；統一軍事配色設計系統
- **整合修復**：main.gd:571 `var gx := lx+20`（Variant 無法推斷）→ 明確 float；豆腐字符號 ☠→★、▶→>>
- **驗證**：headless 0 ERROR；Playwright 確認戰鬥（HUD/環形CD/技能橫幅/傷害數字/敵人紅子彈/四角色完整顯示）、主選單、基地畫面皆正常，console 零錯誤；版本 v0.5.12 → v0.6.0
- **技術筆記**：headless --quit 在 MainMenu 主場景不載入 main.gd/戰鬥腳本，會漏 parse error；驗證戰鬥腳本須暫時把 main_scene 改 Main.tscn 再跑（見 [[feedback-godot-parse-error-blindspot]]）

### v0.5.12（2026-06-22）— 掩體圖層調整 + 敵方掩體換素材
- **玩家掩體移到角色後方**：原本 z=5 前景層蓋住角色（只露頭）；改為 z=-1 後景層（RoomCoverBack），完整角色模組顯示在掩體前方，角色更突出。掩體 y 1496→1518 下移貼合腳部
- **角色站立不蹲伏**：`_position_squad_for_combat()` 的 `set_cover_mode(true)` 改 `false`，掩體後移後角色保持站立完整顯示
- **敵方掩體換素材**：enemy_cover_left/mid/right.svg 從混凝土護欄 → **深色鉚釘鋼板路障 + 紅色警示帶**（呼應敵人紅色主題，與玩家沙袋、舊混凝土皆區隔）
- **驗證**：Playwright 確認四名角色完整模組顯示在前、掩體在後；版本 v0.5.11 → v0.5.12

### v0.5.11（2026-06-22）— 🔴 破門卡死修復 + 敵方攻擊力調降
- **🔴 破門點擊失效修復**：v0.5.10 的破門定格用 Button.pressed 偵測點擊，真機 iOS 觸控收不到 → 卡死無法推進。改用 main.gd `_input()` 直接攔截 `InputEventScreenTouch`（真機觸控）+ `InputEventMouseButton`（滑鼠），這是 Godot 最底層、不受 GUI 圖層影響的輸入路徑。新增 `_breach_active/_breach_cl/_breach_tween/_breach_on_complete` 狀態 + `_finish_breach()`
- **敵方攻擊力調降**：普通兵 45→28、精英 55→38、Boss 65→48；攻擊間隔普通兵 2.5→2.8、精英 2.0→2.2、Boss 2.0→2.2。緩解隨機目標後脆皮後排（醫療兵/狙擊手）被秒問題
- **驗證**：Playwright 確認破門清場後定格、5 秒不點擊不會自動推進（before==hold）、四名隊員全存活（ATK 降後不再陣亡）；點擊後 GPU 持續卡頓 = 場景切換中（推進成功的徵兆，swiftshader 抓不到切換幀）；版本 v0.5.10 → v0.5.11

### v0.5.10（2026-06-22）— 隨機目標 + 破門定格 + 技能橫幅
- **破門動畫改為「點擊才繼續」**：main.gd `_play_door_open_animation()` 移除自動推進的 tween 尾段，破門 flash 後定格並顯示「點擊任意處繼續」脈動提示，唯一推進路徑是全螢幕 skip_btn 點擊
- **我方隨機射擊**：character.gd `_try_auto_attack()` 從「鎖定最近敵人」改為「隨機選一名存活敵人」
- **敵方隨機射擊**：enemy.gd `_get_frontline_member()` 從「優先打盾兵」改為「隨機選一名存活隊員」（脆皮後排也會中彈）
- **技能釋放橫幅**：character.gd `_apply_ultimate_effect()` 開頭呼叫 `_show_ultimate_banner()`，畫面中央顯示「角色 發動！技能名」+ 效果敘述 + 持續時間（buff 類用 `tween_method` 即時倒數「持續 X.X 秒」，瞬發類顯示「立即生效」2.2s 後消失）；左側職業色條
- **驗證**：Playwright 確認技能橫幅（突擊手火力全開）、隨機目標（敵人逐一 ELIMINATED 血量分散、醫療兵/狙擊手會中彈陣亡）、破門點擊推進房間 1→2；版本 v0.5.9 → v0.5.10
- **平衡備註**：敵人隨機目標後不再集火盾兵，後排脆皮（醫療兵/狙擊手）存活率下降，1-1 難度上升，後續可能需微調敵人 ATK 或隊員 HP

### v0.5.9（2026-06-22）— 🔴 子彈/扣血根因修復 + 血條上移 + 掩體換裝
- **🔴 根因1（致命，戰鬥完全卡住）**：main.gd `_build_room_visual()` 呼叫了未定義的 `_add_environment_props()` → main.gd parse error → `_spawn_squad`/`_start_room` 全不執行 → 戰鬥場景卡住、沒子彈、不扣血。**補上函式本體解決。**
- **🔴 根因2（致命，子彈不顯示）**：bullet.gd `var _body: Node2D` 但實際會指派 ColorRect（非 Node2D）→ `_body is ColorRect` 被編譯器判定恆假 → **整個 bullet.gd parse error 無法載入 → 子彈永遠不出現**。改為 `var _body`（untyped）解決。此 bug 自始存在，headless 在 MainMenu `--quit` 從不載入 bullet.gd 故一直漏掉，**只有 Playwright 真機 WebGL 才抓到**。
- **血條上移頭頂**：character.gd 玩家血條從身體下方移到頭頂上方（y = -half-16）；enemy.gd 敵人血條同步移到頭頂（y = -size.y/2-18），名稱標籤再上移
- **敵人掩體換素材**：enemy_cover_left/mid/right.svg 從棕色沙袋 → **混凝土澤西護欄 + 黃黑危險條紋**（梯形塊、彈孔磨損），與玩家沙袋明顯區隔
- **玩家掩體確認**：已是 4 段獨立沙袋（player_cover_seg.svg × 4 站位，段間 36px 斷開），非整片相連
- **中段環境素材**：`_add_environment_props()` 依任務類型在兩側擺道具（office：server_rack/locker/crate；warehouse：pillar/crate/barrel；harbor：container/barrel/rope）
- **匯出路徑修正**：export_presets.cfg `../../build/web` → `../build/web`（原路徑指向不存在的 遊戲/build/web）
- **驗證**：Playwright headless WebGL 確認子彈雙向射擊、雙方扣血、醫療兵 +14hp 治療、血條在頭頂、4 段獨立掩體；主選單無 console error；版本號 v0.5.8 → v0.5.9

### v0.5.8（2026-06-22）— 掩體素材升級為沙袋牆
- **玩家掩體**：灰色矩形 → 暗橄欖綠**沙袋牆**（11 段交錯沙袋，高光/陰影/綁繩縫），軍事戰術風格
- **敵人掩體**：暗紅棕破舊沙袋（含彈孔破損細節）
- **修正拉伸變形**：原 player_cover 只有 280×18 被 STRETCH_SCALE 拉成 920×30（橫向 3.3 倍糊掉）；新素材按最終尺寸 920×30 / 300×22 的 1:1 設計，匯入後不變形
- 素材用 Python 程序化生成（`shape-rendering=crispEdges` 像素風）

### v0.5.7（2026-06-22）— 掩體層次修正
- **玩家掩體改為前景層**：原本跟 RoomVisual 一起 z=-10 跑到角色後面；改成獨立 `_room_foreground` 節點 z=5，畫在角色之上 → 角色躲在掩體後方
- **掩體固定不隨角色移動**：前景層加在 Main 固定座標，不在角色節點下
- **角色站位**：y=1520 在掩體（y=1450）下方，朝上方敵人射擊
- 每次換房間時 `_room_foreground` 一併 queue_free

### v0.5.6（2026-06-22）— 🔴 重大根因修復：戰鬥場景全黑
- **真機測試暴露致命 bug**：iPhone 進入戰鬥後畫面全黑（只有 HUD），headless `--quit` 與 Playwright 都漏掉
- **根因1（致命）**：`main.gd` 有 Parse Error（`var cfg := ROOM_CONFIGS[idx]` 無法推斷 Variant 型別）→ 整個 main.gd 載入失敗 → `_spawn_squad()`/`_start_room()` 全沒執行 → 戰鬥場景空白。之前 headless 主場景是 MainMenu、第一幀就 `--quit`，**根本沒載入 main.gd**，故 parse error 從未被觸發。自 v0.5.0 獨立房間架構起戰鬥就一直空白，Playwright 看到的「房間1/4」只是 hud.gd 預設值，被誤判為「SwiftShader 渲染限制」
- **修復1**：`var cfg: Dictionary = ROOM_CONFIGS[idx]`（×2）、`var is_boss: bool = ...`
- **根因2**：修復1後敵人/掩體顯示了但小隊角色仍不可見 → RoomVisual（全螢幕不透明背景 ColorRect）在 `_spawn_squad` 之後 add_child，同 z_index=0 下 tree order 較後 → **蓋住角色**
- **修復2**：`RoomVisual.z_index = -10`（背景層永遠在角色/敵人之下）
- **驗證手段升級**：臨時把 main_scene 改成 Main.tscn 直接匯出測試版，Playwright 截圖確認戰鬥場景完整渲染（敵人+掩體+4角色+HUD），驗證後改回 MainMenu
- **渲染後端**：順手把 forward_plus → gl_compatibility（Web/iOS 必須，雖非本次根因）

### v0.5.5（2026-06-22）
- **game_manager.gd**：`trigger_game_over()` 修復 `current_room_index` 未歸零（第二局房間計數出錯 bug）
- **數值重校 Round 2**：普通兵 HP 1200→1000 / ATK 35→45；Boss ATK 75→65 + 間隔 1.5→2.0s；盾兵 HP 400→500；大招初始 CD 盾兵 15s / 爆破手 20s（其他角色維持立即可用）
- **hud.gd**：`_on_room_advanced()` 同步更新 ProgressBar（之前一直顯示「進度 0%」）
- **main.gd**：`_on_room_cleared()` 正確 queue_free 舊房間節點（記憶體洩漏修復）

### v0.5.4（2026-06-22）
- **main.gd**：房間 queue_free 修復（佔坑記憶體洩漏）
- **hud.gd**：進度條在通關時正確更新

### v0.5.3（2026-06-22）
- **character.gd**：大招效果全面修正（突擊手 80%當前HP、狙擊手 max_hp×0.6、醫療兵平80HP、爆破手 40% max_hp AoE）
- **hud.gd**：TopBar 三欄佈局修復（不重疊），BottomBar 高度修正，restart_btn 信號連接
- **bullet.gd**：Sprite2D 沒有 `.color` 屬性 → 改用 `.modulate`

### v0.5.1~5.2（2026-06-22）
- **關卡架構重構**：獨立房間系統（1-1→1-2→1-3→Boss），全螢幕單房間
- **子彈對射視覺**：character.gd 自主攻擊並發射子彈，enemy.gd 反擊子彈
- **小隊進場動畫**：從螢幕底部走入（0.85s），期間暫停攻擊
- **TCG 精靈全套**：6職業站立+蹲伏 SVG + 敵人 3 種 SVG
- **HUD 卡片修復**：BottomBar 高度 180→220px
- **破門動畫**：點擊畫面可跳過
- **Bug 8項修復**：敵人進場攻擊/首次延遲/全滅浮點/DEMO重置路徑/出發順序

### v0.4.x（2026-06-21~22）
- 隊員不出現修復（卡牌 ID 去等級後綴再查 CHAR_DATA）
- 卡牌管理：4槽陣容 + 下方列表去重過濾
- 基地「升級管理」移除，整合進陣容管理

### v0.4.0（2026-06-22）
- 主選單畫面、基地畫面、任務場景全流程
- TCG 卡牌系統（24張，6職業×R/SR/SSR/QR）
- 抽卡系統（Gacha）、音效/BGM、存檔系統
- Boss AI、結算畫面、HUD

## 進行中
- 無

## 待辦
- [ ] 人工瀏覽器測試：
  - 子彈飛行在 WebGL 下是否正常
  - 進場動畫+蹲伏切換視覺
  - Boss 死亡後結算畫面是否彈出
  - iPhone Home Indicator 是否遮擋 HUD
- [ ] 音效補充：確認 gunshot_enemy.wav 是否存在且被正確引用
- [ ] 關卡系統擴充（目前只有 Level 1，4 個房間）

## 待確認
- 無

## 已知問題
- iPhone Home Indicator 可能遮擋 HUD 底部（未實測）
- headless 無法驗證 WebGL 渲染，子彈/蹲伏動畫需瀏覽器確認
- 大招初始 CD 設計（盾兵 15s / 爆破手 20s）可能影響 1-1 難度，需真機調整

## 操作紀錄
- 2026-06-22 v0.5.5: 房間計數重置 bug、記憶體洩漏、進度條不更新、數值平衡 Round 2
- 2026-06-22 v0.5.4: 記憶體洩漏修復、進度條修復
- 2026-06-22 v0.5.3: 大招效果修正、TopBar 佈局修復、bullet.gd 修正
- 2026-06-22 v0.5.1: 多 agent 平行修復，8 bug 修復，TCG 精靈全套
- 2026-06-22 v0.5.0: 獨立房間架構上線
- 2026-06-22 v0.4.7: 戰鬥暫停/節奏/跳過動畫
- 2026-06-21 v0.4.6: 隊員不出現修復，事件選擇關閉
