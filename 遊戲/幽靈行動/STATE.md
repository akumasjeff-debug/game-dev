# 幽靈行動 狀態

## 已完成
### TCG 卡牌系統
- TCG 卡牌系統（24 張：6 職業 × R/SR/SSR/QR 四等級）
- 抽卡機率：R 75% / SR 18% / SSR 6% / QR 1%，三層保底（10/50/100抽）
- 卡片數值倍率：R×1.0 / SR×1.6 / SSR×2.8 / QR×5.0
- 新手10連免費抽（含保底 SR）
- save_manager.gd：owned_cards / card_levels / selected_squad / gacha_pity / starter_claimed
- gacha_config.json + cards.json 資料檔

### 視覺素材（新增）
- 4種稀有度 TCG 卡框 SVG（card_frame_r/sr/ssr/qr.svg）
- SWAT 破門場景圖（breach_scene.svg，180個rect，3名特種部隊員）

### 過場動畫
- SWAT 破門過場動畫（取代舊滑門動畫）：黑邊+場景圖+BREACH文字+閃白，總時長 0.84s

### 核心遊戲循環
- 俯視角戰鬥系統（4 房間 + Boss 房）
- 6 職業角色（盾兵/突擊/爆破/醫療/狙擊/偵察），各有大招
- 醫療兵自動回血被動 + Lv.6 戰場復活
- 蹲伏/站立精靈切換（掩體後蹲姿，射擊時站起）
- Boss 房震屏 + 紅閃警告效果
- 敵人死亡動畫（閃白→膨脹→旋轉倒下/縮消失 + 擊殺文字）

### 任務系統
- 3 個任務：辦公大樓(demo_01)、地下停車場(warehouse_01)、港口(harbor_01)
- 任務差異化：不同敵人配置、BGM、房間主題色、地板紋理
- 任務確認面板（難度星級 + 獎勵預覽，取消/出擊）
- 任務完成後故事片段（黑底淡入，3條台詞隨機）
- 任務完成記錄存檔（completed_missions）
- 決策事件任務特化（停車場/港口有專屬描述）
- 6 個新任務專屬事件（停車場3 + 港口3）

### 基地系統
- 放置橫帶（側視角，4隊員自動戰鬥，波次制）
- 任務板（多任務選擇，難度顯示）
- 離線獎勵彈出通知（5分鐘觸發，上限24小時，50金幣/小時）
- 存檔系統（金幣/票券/等級/任務進度）

### 視覺素材
- 全 6 職業俯視角 sprite + 6 蹲伏姿態 + 6 肖像
- 敵人 3 種：普通兵/精英/Boss（俯視角 SVG）
- 側視角 sprite（4 玩家 + 2 敵人 + 掩體木箱）
- 戰場掩體 SVG（玩家大掩體 + 敵人小掩體 ×3）
- 道具：辦公室/停車場/港口三套（18+ SVG）
- 地板紋理：辦公室/停車場/港口（含 35% 透明度疊加）
- 子彈 SVG（玩家黃銅彈頭/敵人深紅彈頭）

### 音效系統
- BGM：任務主題曲 + warehouse_bgm + harbor_bgm
- SFX：gunshot/gunshot_enemy/impact_hit/ult_activate/victory_sting
- 音效串接：玩家射擊/受傷/大招/勝利全部有音效

### HUD & UI
- 戰鬥 HUD：任務名稱 + 房間進度（N/4）
- 結算畫面：動態獎勵（依任務顯示金幣/金票/藍票）
- 中文字型完整支援（chinese_font.ttf 4.7MB）

## 進行中
- 24 張卡片插畫（6 職業 × R/SR/SSR/QR）
- 主選單畫面（main_menu.gd + main_menu_bg.svg）
- 缺少側視角 sprite（side_sniper / side_recon / side_boss）
- 基地背景圖、抽卡面板背景圖

## 待辦
- 角色升級面板技能說明
- HTML5 重新 build + butler push v0.4.0

## 待確認
- 無

## 已知問題
- events.json 新增的 mission_filter 欄位需要 decision_panel.gd 程式端配合讀取才能生效
- 角色蹲伏模式已實作 set_cover_mode()，但 room.gd 尚未在所有入口點完整呼叫
- demo_qr 爆破手 ATK 350 可能過高（爆發型，需測試後調整）
- QR 盾兵 DEF 200 對照敵人傷害上限需確認是否過強

## 操作紀錄
- 新增 src/resources/data/missions.json（3個任務配置）
- 新增 src/resources/data/mission_stories.json（任務故事片段）
- 新增 src/audio/bgm/warehouse_bgm.wav、harbor_bgm.wav
- 新增 src/audio/combat/gunshot_enemy.wav、impact_hit.wav
- 新增 src/audio/ult/ult_activate.wav
- 新增 src/audio/ui/victory_sting.wav
- 新增 src/resources/art/sprites/crouch/ 資料夾（6個蹲伏 SVG）
- 新增 src/resources/art/sprites/side/ 資料夾（7個側視角 SVG）
- 新增 src/resources/art/sprites/bullet_player.svg、bullet_enemy.svg
- 新增 src/resources/art/props/（停車場3 + 港口3 + 地板2 + 掩體4 SVG）
- 新增 src/scripts/story_panel.gd
- 新增 docs/press/（cover/banner/icon SVG）
