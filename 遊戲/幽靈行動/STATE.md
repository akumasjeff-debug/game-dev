# 幽靈行動 狀態

## 已完成
- GDD v0.1 完成（docs/GDD.md）
- 專案資料夾建立
- Godot 4 專案結構建立（headless 測試 exit code 0，無錯誤）
- 核心操控原型：玩家移動（WASD）+ 槍線朝向滑鼠 + 靜止自動瞄準
- 自動射擊機制：PhysicsRayQuery 掃描 120° 扇形最近敵人，安全模式切換（F 鍵）
- 視野錐形（120°, 300px）跟隨槍線方向（本地 +X，無雙重旋轉）
- 敵人 AI 狀態機（巡邏 → 警覺 → 追擊 → 射擊）
- 辦公室地圖原型（ColorRect 牆壁 + StaticBody2D 碰撞 + NavigationRegion2D）
- 基礎 HUD（HP 條 + 彈藥條 + 換彈提示 + 安全模式指示燈）
- 相機跟隨玩家（Camera2D 移至 Player.tscn 子節點）
- 死亡旗標防重複觸發（player.gd）
- hud.gd 快取 player + 換彈文字殘留修復
- SafeIndicator 改為 anchor 右側定位（任意解析度正確）
- 受傷閃紅效果（modulate，0.15 秒）
- 死亡面板（「任務失敗」+ 按 Enter 重新開始）
- 手動換彈（R 鍵，彈匣未滿且未換彈時有效）
- 自動瞄準 UI 提示（靜止時 HUD 顯示「自動瞄準中」藍色文字）
- 安全模式按鍵提示（「[F] 切換」靜態標籤）
- cop_sprite.gd top_level=true 修正（移除每幀 global_rotation 覆蓋 hack）
- enemy.gd 狀態感知動畫（SHOOT 播 shoot 動畫、移動播 walk、靜止播 idle）
- Main.tscn 5 個敵人設定有意義的矩形巡邏路線（main.gd 統一設定）
- 霧戰三層系統重新實作（ImageTexture 方案，96x54 格，牆壁遮擋正確）
- 任務目標系統（殲滅）：敵人全滅 → 顯示 VictoryPanel
- Demo 測試協議三組審查通過（無霧戰版本）
- **[2026-06-21] 音效系統**：槍聲（200Hz/0.06s）、換彈聲（800→400Hz/0.4s）、敵人死亡聲（150Hz/0.2s）— Python wave 生成，FileAccess 直讀繞過 import 系統（headless exit 0）
- **[2026-06-21] 敵人死亡音效防截斷**：`_die()` 前移 AudioStreamPlayer 至場景根節點再播放，播完自動 queue_free
- **[2026-06-21] BGM 系統**：bgm_battle.wav（8 秒循環，Python wave 合成，60Hz 底音+150Hz 鼓擊+200Hz 金屬泛音），FileAccess 直讀，-12dB，勝利時停止，全 5 關共用
- **[2026-06-21] 地板磚塊**：main.gd 含 _create_floor_tiles()（tilesheet 存在時自動鋪設），tilesheet 目前缺失但有防護不 crash
- **[2026-06-21] 關卡 2（Level2.tscn）**：倉庫廠房，暗殺 BossEnemy，7 雜兵 + 1 Boss，level2_main.gd
- **[2026-06-21] 關卡 3（Level3.tscn）**：廢棄醫院，救援人質，8 雜兵，Hostage.tscn + ExitZone.tscn，level3_main.gd
- **[2026-06-21] 關卡 4（Level4.tscn）**：軍事指揮中心，限時防守 90 秒，10 雜兵從四面逼近，HUD 倒數計時，level4_main.gd
- **[2026-06-21] 關卡 5（Level5.tscn）**：廢棄造船廠最終關，殲滅，12 個精銳，勝利後 1.5s 延遲顯示，level5_main.gd
- **[2026-06-21] 人質系統**：Hostage.tscn + hostage.gd（狀態機：IDLE/FOLLOWING/STOPPED，NavigationAgent2D），ExitZone.tscn
- **[2026-06-21] hud.gd 擴充**：set_mission_text、start_countdown、update_countdown（倒數 Label 上方正中）、_go_to_next_level 關卡串接（Main→L2→L3→L4→L5）
- **[2026-06-21] enemy.gd SPEED/VISION_RANGE 改為 var**：支援 BossEnemy 外部屬性差異化
- **[2026-06-21] 基地場景（HQ）**：Base.tscn + base_main.gd，深色 #1a1a2e 主題，Header/MainContent（三欄面板）/BottomBar（出發＋設定），TransitionOverlay 漸入 0.5s 切 Main.tscn；project.godot 主場景改為 Base.tscn；hud.gd Level5 勝利後改為回 Base.tscn（headless exit 0）

## 進行中
- 無

## 待辦（確認執行）
- 陣形系統：最多 4 陣形、一鍵切換（Q/E/Z/X）、主要位置概念、鏡頭跟隨主要位置
- 其餘 7 種職業：狙擊手 / 盾兵 / 重裝 / 醫療兵 / 散彈兵 / 偵察手 / 爆破手（各有專屬武器、HP、移速）
- 基地系統：任務板（主線/支線選擇）、武器購買 / 升級（機率制 1–10 級）、隊員管理
- Roguelite 跨局成長：金錢保留、職業解鎖、武器等級永久、隊員格數擴展（最多 4 格）
- 素材替換：ColorRect 臨時素材 → 正式像素圖（角色、地圖磚塊、武器、UI）

## 後續選擇項目（未確認，保留設計文件為參考）
- 匿蹤系統：噪音等級、警戒消退時間、屍體觸發全區搜索
- 六大素質成長：體力 / 敏捷 / 感知 / 力量 / 技術 / 意志
- 倒地與救援機制：10 秒倒數、隊友施救、醫療兵加速
- 故事情報系統：任務前情報文字、任務後解鎖劇情段落
- 後期怪物關卡：生化實驗體（聽覺偵測）、軍事機械（視覺+雷達）

## 待確認
- 無

## 已知問題
- 巡邏/追擊敵人顏色（深紅/正紅）對比不夠明顯（低優先）
- cop_sprite 縮放 SCALE_FACTOR=0.25 可能偏小，待視覺驗證後調整
- headless 模式下音效警告（非 bug，headless 不支援音頻驅動，實際遊戲正常）
- main.gd 的 _create_floor_tiles() 需要 tilesheet_complete.png，目前缺失，push_warning 但不 crash（低優先）
- BossEnemy（關卡 2）視野/速度差異化：SPEED 已為 var，level2_main.gd 有賦值程式碼，但需實際執行確認

## 操作紀錄
- 2026-06-20：建立專案，完成 GDD v0.1 設計討論
- 2026-06-20：第一輪，建立 Godot 4 完整原型（所有場景、腳本），headless exit 0
- 2026-06-20：第二輪，修復相機跟隨、霧戰 _draw() 重寫、NavigationRegion2D
- 2026-06-20：Demo 測試協議：測試員、數值驗證師、UI/UX 設計師三組平行審查
- 2026-06-20：第三輪，修復所有審查問題（7 項修復 + 敵人數值調整）
- 2026-06-20：第四輪，UI 提示、換彈系統；fog_of_war 改為 stub（暫停功能）
- 2026-06-21：第五輪，cop_sprite top_level 修正、enemy SHOOT 動畫修正、敵人巡邏路線設定、新建 main.gd
- 2026-06-21：第六輪，霧戰三層系統重新實作（ImageTexture + 牆壁遮擋）、任務目標系統（殲滅）完成
- 2026-06-21：第七輪，音效系統（槍聲/換彈/死亡三個 WAV）、敵人死亡音效防截斷機制、headless exit 0
- 2026-06-21：第十輪，關卡 2-5 全部完成（暗殺/救援/限時防守/最終殲滅），BGM，人質系統，HUD 串接，全 5 關關卡序列，headless exit 0
- 2026-06-21：第十一輪，HQ 基地場景（Base.tscn + base_main.gd），主場景改為 Base，Level5 勝利後回 Base，headless exit 0

## 關卡一覽（全 5 關）
| 關卡 | 場景 | 主題 | 任務類型 | 敵人數 |
|------|------|------|---------|-------|
| 1 | Main.tscn | 辦公室 | 殲滅 | 5 |
| 2 | Level2.tscn | 倉庫廠房 | 暗殺（BossEnemy） | 7+1 |
| 3 | Level3.tscn | 廢棄醫院 | 救援人質 | 8 |
| 4 | Level4.tscn | 軍事指揮中心 | 限時防守 90s | 10 |
| 5 | Level5.tscn | 廢棄造船廠 | 殲滅（最終關） | 12 |

## 突擊手最終數值（Demo 版）
| 項目 | 數值 |
|------|------|
| HP | 100 |
| 移速 | 150 px/s |
| 傷害 | 25 |
| 射速 | 0.1 s/發（600 RPM）|
| 彈匣 | 30 發，換彈 2 秒 |
| 射程 | 500 px |

## 雜兵最終數值（Demo 版）
| 項目 | 數值 |
|------|------|
| HP | 75 |
| 傷害 | 20 |
| 射速 | 0.5 s/發 |
| 移速 | 120 px/s |
| 視野距離 | 350 px |
| 追擊放棄距離 | 525 px |
