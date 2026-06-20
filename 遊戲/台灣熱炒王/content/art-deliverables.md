# 台灣熱炒王 — 美術素材交付清單 v1.0

**整理日期：** 2026-06-20
**整理人：** 美術組長（美術規格師）
**需求來源：** art/art-spec.md、art/animation-spec.md、design/map-design.md、art/ui-spec.md

## 說明

本清單整理第一批需手工繪製的像素圖素材，依優先級分組。
P1 = 遊戲能跑必須有 / P2 = 體驗好 / P3 = 錦上添花

基礎規格提醒（所有素材共用）：
- 格子單位：16x16 px
- 縮放方式：Nearest Neighbor 整數倍，禁止抗鋸齒
- 輪廓規則：可點擊物件須 1px 深色輪廓（#1A1A2E）
- 透明度：只允許完全透明（alpha 0）或完全不透明（alpha 255）

---

## P1 — 最低可運行素材

### 角色

| 素材名稱 | 尺寸 (px) | 幀數 | 備註 | 規格來源 |
|---------|-----------|------|------|--------|
| char_boss_idle | 16x24 | 2 幀 x 4 方向（共 8 幀） | 老闆娘待機，輕微上下呼吸感；主色 #E74C3C 紅色圍裙 + 白圍裙；零錢包（#FFD700） | animation-spec.md 第 22-28 行；art-spec.md 第 411-418 行 |
| char_boss_walk | 16x24 | 4 幀 x 4 方向（共 16 幀） | 老闆娘行走四方向，每幀 150ms | animation-spec.md 第 22-28 行；art-spec.md 第 411-418 行 |
| char_chef_idle | 16x24 | 2 幀 x 4 方向（共 8 幀） | 廚師阿龍待機（背面對灶）；白廚師高帽 + 白袍 + 油漬灰圍裙（#6B6B6B） | animation-spec.md 第 48-56 行；art-spec.md 第 424-430 行 |
| char_chef_walk | 16x24 | 4 幀 x 4 方向（共 16 幀） | 廚師阿龍行走四方向，每幀 150ms | animation-spec.md 第 48-56 行；art-spec.md 第 424-430 行 |
| char_customer_a_idle | 16x24 | 2 幀 x 1（坐姿正面） | 上班族坐著等；白襯衫 + 紅/藍領帶 + 眼鏡 + 手機 | animation-spec.md 第 110-118 行；art-spec.md 第 454-460 行 |
| char_customer_a_walk | 16x24 | 4 幀 x 4 方向（共 16 幀） | 上班族走路進入場景 | animation-spec.md 第 110-118 行；art-spec.md 第 454-460 行 |

### 設備 / 道具

| 素材名稱 | 尺寸 (px) | 幀數 | 備註 | 規格來源 |
|---------|-----------|------|------|--------|
| equip_wok_static | 32x32 | 1 幀 | 快炒爐靜態版（未使用中）；俯視角大鐵鍋，鍋身 #5A5A5A，鍋緣高光 #888888，鑄鐵爐台黑色底 | art-spec.md 第 208-220 行 |
| equip_wok_active | 32x32 | 6 幀 | 快炒爐使用中：火焰 3 幀橙黃跳動 + 鍋中食材翻動 2 幀（循環）；炒火 #C87941 | art-spec.md 第 208-220 行 |
| table_2p | 32x16 | 1 幀 | 2 人折疊桌靜態；白色 #E8E0D0 桌面 + 兩張紅色塑膠椅 #CC1111；桌上醬油瓶 + 牙籤筒 | art-spec.md 第 272-285 行 |
| table_4p | 32x32 | 1 幀 | 4 人折疊桌靜態；同材質，四方向椅背 | art-spec.md 第 287-299 行 |

### Tileset（地板 / 牆 / 路）

| 素材名稱 | 尺寸 (px) | 幀數 | 備註 | 規格來源 |
|---------|-----------|------|------|--------|
| tile_road | 16x16 | 1 幀 | 柏油路面；馬路邊界 4 周皆使用；夜市路面藍灰 #243B55 為主色 | design/map-design.md 第 12-13 行；art-spec.md 第 63-70 行 |
| tile_floor_kitchen | 16x16 | 1 幀 | 廚房區底板（灶腳區）；橘紅色標示（編輯模式）；施工模式可見，一般模式不可見網格 | design/map-design.md 第 18-27 行 |
| tile_floor_dining | 16x16 | 1 幀 | 外場區底板（桌椅區）；米黃色 #E8D5A3 地板磚 | design/map-design.md 第 18-27 行；art-spec.md 第 86-96 行 |
| tile_floor_corridor | 16x16 | 1 幀 | 走道區底板；灰白色水泥地 #6B6B6B | design/map-design.md 第 18-27 行；art-spec.md 第 86-96 行 |
| tile_wall_brick | 16x16 | 1 幀 | 未解鎖區域磚牆封閉邊界；需搭配解鎖後拆除動畫 | design/map-design.md 第 177 行 |

### UI 圖示

| 素材名稱 | 尺寸 (px) | 幀數 | 備註 | 規格來源 |
|---------|-----------|------|------|--------|
| hud_icon_coin | 8x8 | 1 幀 | 錢袋/金幣圖示；高對比 #FFD700 在深色 HUD 背景上 | art-spec.md 第 515-518 行；ui-spec.md 第 37-38 行 |
| hud_icon_star | 8x8 | 2 幀（亮/暗） | 名聲星星；亮星 #F5A623，暗星 #555566 | art-spec.md 第 515-518 行；ui-spec.md 第 39 行 |
| hud_bg_top | 480x28 | 1 幀 | 頂部 HUD 背景；#1A1A2E 半透明底，下邊緣 1px #FF2D55 霓虹描邊 | ui-spec.md 第 26-41 行 |
| hud_bg_bottom | 480x28 | 1 幀 | 底部 HUD 背景；同頂部規格，邊框在上緣 | ui-spec.md 第 43-51 行 |
| btn_build | 20x20 | 2 幀（選中/未選中） | 工具列「建造」快捷鈕；錘子圖示；選中底色 #FF2D55，未選中 #2A2A4A | ui-spec.md 第 43-51 行；art-spec.md 第 521-528 行 |
| btn_table | 20x20 | 2 幀（選中/未選中） | 工具列「擺桌」快捷鈕；桌椅剪影圖示 | ui-spec.md 第 43-51 行 |
| btn_staff | 20x20 | 2 幀（選中/未選中） | 工具列「雇員」快捷鈕；人形圖示 | ui-spec.md 第 43-51 行；art-spec.md 第 523 行 |
| btn_menu | 20x20 | 2 幀（選中/未選中） | 工具列「菜單」快捷鈕；菜單圖示 | ui-spec.md 第 43-51 行；art-spec.md 第 522 行 |
| icon_status_happy | 8x8 | 1 幀 | 滿意度開心臉；笑臉 #FFD700 | ui-spec.md 第 219-229 行 |
| icon_status_angry | 8x8 | 1 幀 | 滿意度憤怒臉；怒臉 #FF2D55 | ui-spec.md 第 219-229 行 |

---

## P2 — 體驗提升素材

### 角色

| 素材名稱 | 尺寸 (px) | 幀數 | 備註 | 規格來源 |
|---------|-----------|------|------|--------|
| char_boss_work_order | 16x24 | 4 幀 x 4 方向 | 老闆娘點餐動作（拿筆記錄）；每幀 120ms | animation-spec.md 第 25 行 |
| char_boss_attract | 16x24 | 6 幀（單方向） | 老闆娘吸客（揮手招攬）；6 幀循環，第 4 幀時長加倍 260ms | animation-spec.md 第 26 行；art-spec.md 第 411-418 行 |
| char_chef_work | 16x24 | 6 幀（單方向） | 廚師炒菜基本動作（鍋左右翻炒）；每幀 100ms 循環 | animation-spec.md 第 52 行 |
| char_chef_work_big | 16x24 | 4 幀（單方向） | 廚師大動作炒菜（火大時觸發）；每幀 80ms | animation-spec.md 第 53 行 |
| char_waiter_idle | 16x24 | 2 幀 x 4 方向（共 8 幀） | 外場小弟待機；深藍制服 #2C3E50 + 深藍棒球帽 + 托盤 | animation-spec.md 第 76-83 行；art-spec.md 第 433-440 行 |
| char_waiter_walk_empty | 16x24 | 4 幀 x 4 方向（共 16 幀） | 外場小弟空手行走 | animation-spec.md 第 77 行 |
| char_waiter_walk_tray | 16x24 | 4 幀 x 4 方向（共 16 幀） | 外場小弟端餐盤行走；托盤高舉穩定感 | animation-spec.md 第 78-89 行 |
| char_parttime_idle | 16x24 | 2 幀 x 4 方向（共 8 幀） | 打工仔待機；黃T #F39C12 + 短圍裙 #2C3E50 + 耳機 | animation-spec.md 第 95-104 行；art-spec.md 第 444-451 行 |
| char_parttime_walk | 16x24 | 4 幀 x 4 方向（共 16 幀） | 打工仔行走 | animation-spec.md 第 95-104 行 |
| char_parttime_chop | 16x24 | 4 幀（單方向） | 打工仔切菜動作；刀高舉→快速落下循環，每幀 110ms | animation-spec.md 第 100-102 行 |
| char_parttime_wash | 16x24 | 4 幀（單方向） | 打工仔洗碗動作；雙手在水槽前搓洗，每幀 130ms | animation-spec.md 第 103-104 行 |
| char_customer_b_idle | 16x24 | 2 幀 x 1 | 阿公阿嬤坐著等；溫暖米色系 #DEB887；阿公格子衫 + 保溫杯，阿嬤花上衣 + 菜籃 | animation-spec.md 第 110-118 行；art-spec.md 第 464-470 行 |
| char_customer_b_walk | 16x24 | 4 幀 x 4 方向（共 16 幀） | 阿公阿嬤走路進入 | animation-spec.md 第 115 行 |
| char_customer_c_idle | 16x24 | 2 幀 x 1 | 夜貓族坐著等；黑暗酷感 + 紫色 #9B59B6；珍奶杯 | animation-spec.md 第 110-118 行；art-spec.md 第 473-480 行 |
| char_customer_c_walk | 16x24 | 4 幀 x 4 方向（共 16 幀） | 夜貓族走路進入 | animation-spec.md 第 115 行 |
| char_customer_d_idle | 16x24 | 2 幀 x 1 | 外國觀光客坐著等；花夏威夷衫 + 相機 + 地圖 | animation-spec.md 第 110-118 行；art-spec.md 第 483-491 行 |
| char_customer_d_walk | 16x24 | 4 幀 x 4 方向（共 16 幀） | 外國觀光客走路進入 | animation-spec.md 第 115 行 |
| char_customer_angry | 16x24 | 4 幀（通用） | 客人急躁坐著抖腳；每幀 120ms 循環 | animation-spec.md 第 113 行 |
| char_customer_eating | 16x24 | 4 幀（通用） | 客人滿意吃飯；每幀 180ms 循環 | animation-spec.md 第 114 行 |
| char_customer_leave | 16x24 | 6 幀（通用，正面） | 客人離開動作，播完消失 | animation-spec.md 第 116 行 |

### 設備 / 道具

| 素材名稱 | 尺寸 (px) | 幀數 | 備註 | 規格來源 |
|---------|-----------|------|------|--------|
| equip_teppan_static | 48x32 | 1 幀 | 鐵板燒台靜態；長方形鐵板 #5A5A5A + 少量 #7B68EE 紫；醬料架 | art-spec.md 第 222-236 行 |
| equip_teppan_active | 48x32 | 6 幀 | 鐵板燒台使用中：白色蒸氣 3 幀冒出 + 油脂光澤 2 幀閃動 | art-spec.md 第 222-236 行 |
| equip_grill_static | 32x32 | 1 幀 | 炭火烤爐靜態；深棕炭灰 #2C2C2C；爐格上 6 串烤肉/海鮮串 | art-spec.md 第 238-252 行 |
| equip_grill_active | 32x32 | 8 幀 | 炭火烤爐使用中：炭火橙紅閃爍 4 幀 + 白煙裊裊 3 幀 | art-spec.md 第 238-252 行 |
| equip_fridge | 16x32 | 2 幀 | 飲料冰箱；玻璃門反光 2 幀循環；台啤瓶 #4A7C59 排列整齊 + 底部白霧 | art-spec.md 第 254-268 行 |
| table_6p | 64x32 | 1 幀 | 6 人長桌；紅白格紋塑膠桌巾 + 大盤子共食配置 | art-spec.md 第 302-315 行 |
| building_stall | 64x48 | 2 幀 | 路邊攤建築；紅色帆篷 #CC3333 + 黃色流蘇 + 木製攤台 + 手寫菜單牌 + 台啤冰桶；帆篷輕微飄動 2 幀 | art-spec.md 第 154-168 行 |

### Tileset（地板 / 牆 / 路）

| 素材名稱 | 尺寸 (px) | 幀數 | 備註 | 規格來源 |
|---------|-----------|------|------|--------|
| tile_floor_storage | 16x16 | 1 幀 | 倉庫區底板（儲藏區）；咖啡色木板感 #8B7355 | design/map-design.md 第 18-27 行；art-spec.md 第 86-96 行 |
| tile_floor_deco | 16x16 | 1 幀 | 裝飾區底板（門面區）；草綠色地面，入口前廣場感 | design/map-design.md 第 18-27 行 |
| tile_grid_overlay | 16x16 | 1 幀 | 施工模式格子虛線網格疊層；白色 1px 虛線，非施工模式隱藏 | design/map-design.md 第 177 行 |

### UI 圖示

| 素材名稱 | 尺寸 (px) | 幀數 | 備註 | 規格來源 |
|---------|-----------|------|------|--------|
| char_boss_portrait | 16x16 | 1 幀 | 老闆娘管理面板頭像；臉部特寫，與完整角色色調一致 | art-spec.md 第 575 行 |
| char_chef_portrait | 16x16 | 1 幀 | 廚師阿龍管理面板頭像 | art-spec.md 第 575 行 |
| char_waiter_portrait | 16x16 | 1 幀 | 外場小弟管理面板頭像 | art-spec.md 第 575 行 |
| char_parttime_portrait | 16x16 | 1 幀 | 打工仔管理面板頭像 | art-spec.md 第 575 行 |
| icon_equip_wok | 12x12 | 2 幀（選中/未選中） | 工具列廚具大炒鍋圖示；簡化剪影，#FFD700 在深色底 | art-spec.md 第 573 行；ui-spec.md 第 108-112 行 |
| icon_equip_teppan | 12x12 | 2 幀 | 工具列廚具鐵板燒台圖示 | art-spec.md 第 573 行 |
| icon_equip_grill | 12x12 | 2 幀 | 工具列廚具炭火烤爐圖示 | art-spec.md 第 573 行 |
| icon_equip_fridge | 12x12 | 2 幀 | 工具列廚具飲料冰箱圖示 | art-spec.md 第 573 行 |
| icon_table_2p | 12x12 | 2 幀 | 工具列桌椅 2 人桌圖示 | art-spec.md 第 573 行 |
| icon_table_4p | 12x12 | 2 幀 | 工具列桌椅 4 人桌圖示 | art-spec.md 第 573 行 |
| icon_status_normal | 8x8 | 1 幀 | 滿意度普通平臉；#AAAAAA | ui-spec.md 第 221 行 |
| icon_status_unhappy | 8x8 | 1 幀 | 滿意度不滿苦臉；#FF6B35 | ui-spec.md 第 222 行 |
| icon_hourglass | 8x8 | 2 幀 | 等待時間沙漏；黃→紅隨時間變色，沙量減少形狀動畫 | ui-spec.md 第 224-229 行 |
| icon_staff_working | 8x8 | 1 幀 | 員工狀態（工作中）；綠點 #00D26A | ui-spec.md 第 225 行 |
| icon_staff_rest | 8x8 | 1 幀 | 員工狀態（休息中）；灰點 #777788 | ui-spec.md 第 226 行 |
| icon_staff_overwork | 8x8 | 2 幀（閃爍） | 員工狀態（過勞警示）；閃爍紅點 #FF2D55 | ui-spec.md 第 227 行 |
| btn_confirm | 80x22 | 3 幀（正常/懸停/點擊） | 確認按鈕；底色 #00D26A，1px #009A4E 邊框，白字 | ui-spec.md 第 169-175 行 |
| btn_cancel | 80x22 | 3 幀 | 取消按鈕；底色 #2A2A4A，1px #555566 邊框，#CCCCCC 字 | ui-spec.md 第 170 行 |
| dialog_corner_deco | 3x3 | 1 幀 | 對話框四角紅色花紋角飾（類傳統祥雲紋，像素簡化）；4 組 | art-spec.md 第 543 行 |
| fx_smoke | 8x16 | 6 幀 | 炒菜冒煙；白煙 #F5F5F5 → 灰 #C8C8C8 向上飄散，6 幀循環 | art-spec.md 第 583-589 行 |
| fx_rating_positive | 32x8 | 12 幀 | 滿意飄字「+滿意！」；綠色 #27AE60，Y 軸向上 8px | art-spec.md 第 591-598 行 |
| fx_rating_negative | 32x8 | 12 幀 | 不滿飄字「-不滿」；紅色 #E74C3C，Y 軸緩升 6px + X 輕微搖晃 | art-spec.md 第 591-598 行 |
| fx_money | 32x8 | 10 幀 | 金錢飄字「+$NNN」；金色 #FFD700，右上方 45 度飄出 | art-spec.md 第 600-607 行 |
| fx_wait_exclaim | 6x8 | 4 幀 | 客人等待感嘆號；紅色 #FF2D55，4 幀交替亮暗閃爍 | art-spec.md 第 648-653 行 |
| fx_done_bell | 16x12 | 10 幀 | 料理完成鈴鐺；銀色 8x8px 搖鈴圖示 + 「叮！」白字，上飄 6px 後消失 | art-spec.md 第 655-663 行 |

---

## P3 — 錦上添花素材

### 角色

| 素材名稱 | 尺寸 (px) | 幀數 | 備註 | 規格來源 |
|---------|-----------|------|------|--------|
| char_boss_celebrate | 16x24 | 6 幀（一次性） | 老闆娘雙手叉腰點頭；200ms/幀，播完回 Idle | animation-spec.md 第 27 行；art-spec.md 第 401 行 |
| char_boss_angry | 16x24 | 4 幀（一次性） | 老闆娘跺腳生氣；100ms/幀，播完回 Idle | animation-spec.md 第 28 行 |
| char_chef_scoop | 16x24 | 5 幀（一次性） | 廚師起鍋盛盤；130ms/幀，完成後回 Idle | animation-spec.md 第 54 行 |
| char_customer_react_happy | 16x24 | 3 幀（一次性） | 客人滿意爆出（星星/愛心）；接回 Idle 滿意 | animation-spec.md 第 117 行 |
| char_customer_react_angry | 16x24 | 3 幀（一次性） | 客人生氣爆出（黑線/汗滴）；接回 Idle 急躁 | animation-spec.md 第 118 行 |

### 設備 / 道具

| 素材名稱 | 尺寸 (px) | 幀數 | 備註 | 規格來源 |
|---------|-----------|------|------|--------|
| deco_neon_sign | 48x16 | 4 幀 | 霓虹招牌；紅底 #FF2D55 白字 + 金色外框 #FFD700；亮→略暗→亮→全亮循環 | art-spec.md 第 320-332 行 |
| deco_menu_board | 16x32 | 1 幀 | 菜單白板；黑框 #1A1A2E 白底，手寫線條紋路；解鎖新菜色時閃爍 | art-spec.md 第 334-348 行 |
| deco_electric_fan | 16x32 | 4 幀 | 大型電扇；扇葉旋轉 4 幀循環 + 頭部左右搖擺 2 幀 | art-spec.md 第 350-363 行 |
| deco_string_lights | 64x8 | 2 幀 | 燈泡串；黑色電線 + 燈泡 #FFD60A，全亮→交錯亮，掛於牆頂 | art-spec.md 第 365-378 行 |
| building_small | 96x64 | 8 幀 | 室內小店建築；霓虹招牌閃爍 4 幀 + 排油煙機抽風扇旋轉 4 幀 | art-spec.md 第 171-186 行 |
| building_large | 128x80 | 8 幀 | 大型店面建築；大型霓虹招牌閃爍 6 幀 + 空調機運轉旋轉 4 幀 | art-spec.md 第 188-203 行 |

### Tileset（地板 / 牆 / 路）

| 素材名稱 | 尺寸 (px) | 幀數 | 備註 | 規格來源 |
|---------|-----------|------|------|--------|
| tile_wall_expand_anim | 16x16 | 4 幀（一次性） | 磚牆解鎖拆除動畫；4 幀碎裂消失效果 | design/map-design.md 第 177 行 |

### UI 圖示

| 素材名稱 | 尺寸 (px) | 幀數 | 備註 | 規格來源 |
|---------|-----------|------|------|--------|
| btn_upgrade | 20x20 | 2 幀（選中/未選中） | 工具列「設備升級」快捷鈕；箭頭向上圖示 | art-spec.md 第 524 行 |
| btn_speed | 20x20 | 3 幀（x1/x2/x4） | 工具列速度控制按鈕；三狀態切換 | art-spec.md 第 525 行 |
| btn_settings | 20x20 | 2 幀 | 工具列設定齒輪按鈕 | art-spec.md 第 526 行 |
| btn_hamburger | 16x16 | 1 幀 | 頂部 HUD 漢堡選單三橫線按鈕 | ui-spec.md 第 41 行 |
| icon_table_6p | 12x12 | 2 幀 | 工具列桌椅 6 人長桌圖示 | art-spec.md 第 573 行 |
| btn_danger | 80x22 | 3 幀 | 危險操作按鈕（如返回主選單）；底色 #FF2D55，1px #CC1133 | ui-spec.md 第 171 行 |
| fx_upgrade_flash | 16x16 | 8 幀（一次性） | 升級閃光；金色星形光芒向外擴散 + 目標物件閃爍；#FFD700 核心 + #FFFFFF 輝光 | art-spec.md 第 612-617 行 |
| fx_reputation | 48x8 | 20 幀（一次性） | 名聲提升；橙紅光芒 + 「名聲提升！等級 X」字幕滑入停留再滑出；#E74C3C + #FFD700 交替 | art-spec.md 第 619-625 行 |
| fx_moon_mid_autumn | 24x24 | 4 幀（常駐循環） | 中秋月亮；橙黃大圓月 16px + 4px 光暈，每 8 幀脈動 | art-spec.md 第 630-635 行 |
| fx_firecracker | 16x16 | 6 幀（每 30 幀觸發） | 過年鞭炮；紅色爆炸像素點向外散射 8 方向，3 幀擴散後 fade out | art-spec.md 第 637-641 行 |
| fx_red_packet | 8x10 | 1 幀（精靈循環移動） | 紅包雨精靈；紅色矩形 + 金色邊框，60 幀場景中從頂部落下 | art-spec.md 第 643-645 行 |

---

## 統計

- P1 素材數：**20 件**
- P2 素材數：**52 件**
- P3 素材數：**24 件**
- 合計：**96 件**

---

*本清單由美術組長根據 art-spec.md、animation-spec.md、design/map-design.md、art/ui-spec.md 四份文件交叉整理，優先級依「主場景能顯示 > 辨識度與流暢 > 裝飾細節」原則裁定。如有新增素材需求，異動須知會美術組長統一更新。*
