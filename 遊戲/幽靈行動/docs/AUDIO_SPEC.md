# 幽靈行動 — 音效規格文件（AUDIO_SPEC）
版本：1.0｜建立日期：2026-06-21

---

## 設計原則

本遊戲為**手機優先的戰術指揮 + Idle 類型**，玩家大多數時間在「觀看」自動推進，只在決策點主動介入。音效系統必須配合這個節奏：

- **背景持續感**：自動戰鬥的槍聲和環境音要能長時間聆聽而不疲勞，作為「進行中」的聽覺背景
- **決策點必須有清晰的聽覺中斷信號**：讓玩家即使在分心情況下也能立刻注意到
- **大招施放要有明確的「爽感」回饋**，但不能壓過環境音太久
- **BGM 要能在手機長時間遊玩中不讓人關掉**（低刺激、有層次、不重複感）
- 音效與 BGM 分開控制（各自獨立的音量 slider）
- 靜音模式：BGM 靜音後，UI 音效與戰場音效仍可保留

---

## 一、BGM 清單

### 1-A 基地主題（Base Theme）

| 屬性 | 內容 |
|------|------|
| 觸發時機 | 進入基地畫面（任務選擇、角色管理、抽卡） |
| 情緒目標 | 沉穩、待命感，讓玩家感覺「我是指揮官，掌控全局」 |
| 節拍 BPM | 72–80 bpm |
| 樂器組合 | 低頻電子底鼓（悶）、琥珀鋼琴線條、環境 pad 音牆、偶有無線電雜音點綴 |
| 風格關鍵字 | Cinematic Military Ambient、Dark Tactical、Tom Clancy 風格 |
| 循環方式 | Seamless loop，建議 2 分鐘以上才接回開頭，用漸入漸出橋接 |
| 建議時長 | 2:30–3:00 |
| 免費資源來源 | freesound.org 搜尋 "military ambient loop"；Pixabay Music 搜尋 "tactical"；OpenGameArt.org 搜尋 "strategy base theme" |

---

### 1-B 任務推進 — 一般（Mission Advance）

| 屬性 | 內容 |
|------|------|
| 觸發時機 | 小隊自動推進中（無 Boss 的一般房間段） |
| 情緒目標 | 緊張感背景、輕度壓力、讓玩家感覺「行動中」但不焦慮，維持觀看節奏 |
| 節拍 BPM | 90–100 bpm |
| 樂器組合 | 電子打擊律動（帶切分音）、低音合成器線條、高頻電子金屬音偶發、短促弦樂鋸齒波 |
| 風格關鍵字 | Tactical Action Electronic、Industrial Military Beat |
| 循環方式 | Seamless loop，主段 1:30，自然迴圈不能有明顯接縫 |
| 建議時長 | 1:30–2:00 |
| 免費資源來源 | freesound.org 搜尋 "action tactical loop"；Pixabay Music 搜尋 "military action"；Kevin MacLeod "Interloper" 或 "Dark Times" 風格 |

---

### 1-C 任務推進 — 緊張段（High Alert）

| 屬性 | 內容 |
|------|------|
| 觸發時機 | 小隊整體 HP 低於 40%，或任務最後三個房間 |
| 情緒目標 | 壓力升高，讓玩家感覺岌岌可危，催促大招決策 |
| 節拍 BPM | 110–120 bpm |
| 樂器組合 | 電子底鼓加快、厚重低音合成器、細密高頻弦律、急促切分節奏 |
| 風格關鍵字 | Intense Military Action、Urgent Tactical |
| 循環方式 | Seamless loop，比 1-B 更短（1:00–1:15），感覺更緊湊 |
| 建議時長 | 1:00–1:30 |
| 切換方式 | 從 1-B 以 2 秒淡入切換到 1-C；不要硬切 |
| 免費資源來源 | freesound.org 搜尋 "intense action loop"；Pixabay Music 搜尋 "tense battle" |

---

### 1-D Boss 戰（Boss Encounter）

| 屬性 | 內容 |
|------|------|
| 觸發時機 | 進入 Boss 房間，持續至 Boss 倒下 |
| 情緒目標 | 重量感、史詩感、「這傢伙不好打」的敬畏 |
| 節拍 BPM | 95–105 bpm |
| 樂器組合 | 大編制合成弦樂、電子打擊（重低頻鼓）、管風琴式 pad、短促電吉他 stab |
| 風格關鍵字 | Epic Military Boss、Cinematic Action |
| 循環方式 | Seamless loop，有明顯的爬升段（第一圈有引入感，之後穩定循環） |
| 建議時長 | 2:00–2:30 |
| 免費資源來源 | freesound.org 搜尋 "boss battle loop"；Incompetech / Kevin MacLeod 搜尋 "epic heavy"；Pixabay Music 搜尋 "boss theme" |

---

### 1-E 任務勝利（Mission Success）

| 屬性 | 內容 |
|------|------|
| 觸發時機 | 到達關卡終點、勝利結算畫面 |
| 情緒目標 | 解脫感 + 成就感，短暫的「爽了」 |
| 節拍 BPM | 85–95 bpm（比任務中輕鬆） |
| 樂器組合 | 軍號式上升主旋律、電子打擊下行收尾、大鼓三連擊 |
| 風格關鍵字 | Military Victory Fanfare、Tactical Triumph |
| 循環方式 | 不循環，單次播放後淡出回到基地主題 |
| 建議時長 | 0:15–0:30（短段勝利主題） |
| 免費資源來源 | freesound.org 搜尋 "victory fanfare military"；OpenGameArt.org 搜尋 "mission complete" |

---

### 1-F 任務失敗（Mission Failed）

| 屬性 | 內容 |
|------|------|
| 觸發時機 | 全員倒下、失敗結算畫面 |
| 情緒目標 | 低沉、略有遺憾感，但不要讓玩家感覺沮喪（遊戲設計上失敗不懲罰，音效不應製造強烈負面感） |
| 節拍 BPM | 慢板，不強調拍子 |
| 樂器組合 | 低頻弦樂下行、鋼琴低鍵單音、空靈環境殘響 |
| 風格關鍵字 | Somber Military、Quiet Defeat |
| 循環方式 | 不循環，單次播放 8–12 秒後靜音 |
| 建議時長 | 0:08–0:12 |
| 免費資源來源 | freesound.org 搜尋 "failure stinger military"；合成：低沉鋼琴音加 reverb 即可 |

---

## 二、戰場音效清單

### 2-A 武器射擊音

| 音效 ID | 觸發時機 | 情緒目標 | 音色描述 | 建議時長 | 取得方式 |
|---------|---------|---------|---------|---------|---------|
| SFX_WEAPON_ASSAULT | 突擊手自動射擊（高頻率連射） | 火力感、壓制感 | 中頻突擊步槍聲，帶短尾殘響，節奏密集；不要過於尖銳傷耳 | 0.15–0.25 秒 / 發 | freesound.org 搜尋 "assault rifle single shot" |
| SFX_WEAPON_SNIPER | 狙擊手自動攻擊（低頻率單發） | 精準、震撼感 | 低沉長尾狙擊槍聲，有明顯的「咚」感，殘響 0.5 秒 | 0.8–1.2 秒 | freesound.org 搜尋 "sniper rifle shot" |
| SFX_WEAPON_PISTOL | 盾兵副武器（低頻率補射） | 穩定、厚實 | 手槍單發，中低頻，緊湊不拖泥帶水 | 0.2–0.3 秒 | freesound.org 搜尋 "pistol shot" |
| SFX_WEAPON_EXPLOSIVE | 爆破手自動攻擊炸藥桶 | 震撼、清房感 | 中低頻爆炸聲，帶 bass drop，尾音約 1 秒 | 1.0–1.5 秒 | freesound.org 搜尋 "grenade explosion small" |

---

### 2-B 敵人受傷 / 倒下音

| 音效 ID | 觸發時機 | 情緒目標 | 音色描述 | 建議時長 | 取得方式 |
|---------|---------|---------|---------|---------|---------|
| SFX_ENEMY_HIT | 敵人被擊中（一般傷害） | 命中回饋 | 短促中高頻衝擊聲，不讓玩家感到血腥，類似「重擊但乾淨」 | 0.1–0.2 秒 | freesound.org 搜尋 "hit impact medium" |
| SFX_ENEMY_DOWN | 敵人倒下 | 清除滿足感 | 低頻重擊 + 短促布料滑落聲，帶點沉重感 | 0.3–0.5 秒 | freesound.org 搜尋 "body fall thud" |
| SFX_ENEMY_HEAVY_DOWN | Boss 或精英敵人倒下 | 大型目標消滅的爽感 | 低頻重擊 + 金屬碎裂 + 爆破短殘響 | 0.8–1.2 秒 | freesound.org 搜尋 "heavy impact metal fall" |

---

### 2-C 我方角色受傷 / 倒下音

| 音效 ID | 觸發時機 | 情緒目標 | 音色描述 | 建議時長 | 取得方式 |
|---------|---------|---------|---------|---------|---------|
| SFX_ALLY_HIT | 我方角色被擊中 | 警覺感（但不過度悲劇） | 護甲吸收衝擊聲 + 短促喘氣，讓玩家感覺「有人受傷了」 | 0.2–0.3 秒 | freesound.org 搜尋 "armor impact hit"；喘氣聲可與 hit 疊加 |
| SFX_ALLY_CRITICAL | 我方角色 HP 低於 20% 時 | 緊急警告 | 護甲喘氣 + 高頻警告 tone，比 ALLY_HIT 明顯 | 0.3–0.5 秒 | 合成：將 ALLY_HIT 加上 800Hz 警告音 |
| SFX_ALLY_DOWN | 我方角色倒下 | 沉重感，但不過度負面 | 低頻重落地 + 護甲金屬滑動，不加痛苦呻吟（手機遊戲適宜） | 0.5–0.8 秒 | freesound.org 搜尋 "soldier fall armor" |

---

### 2-D 腳步聲

| 音效 ID | 觸發時機 | 音色描述 | 建議時長 | 取得方式 |
|---------|---------|---------|---------|---------|
| SFX_FOOTSTEP_CONCRETE | 混凝土 / 一般室內地板 | 中頻靴子踩踏，稍有迴響 | 0.1–0.15 秒 | freesound.org 搜尋 "military boots concrete footstep" |
| SFX_FOOTSTEP_METAL | 金屬地板 / 工廠走道 | 清脆金屬迴響，「鏗」感明顯 | 0.1–0.15 秒 | freesound.org 搜尋 "footstep metal floor" |
| SFX_FOOTSTEP_WATER | 積水地板 / 雨夜室外 | 水濺聲 + 靴子沉悶踩踏 | 0.15–0.2 秒 | freesound.org 搜尋 "boots splashing puddle" |
| SFX_FOOTSTEP_GRAVEL | 碎石 / 室外廢墟 | 碎石摩擦聲，沙沙帶滾 | 0.1–0.15 秒 | freesound.org 搜尋 "gravel footstep military" |

腳步聲設計備注：Isometric 視角下，腳步聲要比真實音量壓低 40–50%，作為推進感的底層聲音，不能搶過武器音效。每次踩踏隨機從 3–4 個樣本中選取，避免機械重複感。

---

### 2-E 門打開音效

| 音效 ID | 觸發時機 | 音色描述 | 建議時長 | 取得方式 |
|---------|---------|---------|---------|---------|
| SFX_DOOR_SILENT | 靜悄悄進入（偵察手/標準選項） | 門把輕轉、金屬絞鏈微聲，幾乎無聲 | 0.4–0.6 秒 | freesound.org 搜尋 "door open silent creak" |
| SFX_DOOR_BREACH | 強行破門（突擊入室） | 木材劈裂 + 鉸鏈撞擊 + 短促爆破殘響 | 0.5–0.8 秒 | freesound.org 搜尋 "door breach kick" |
| SFX_DOOR_EXPLOSIVE | 炸彈爆破門（爆破手選項） | 爆炸聲 + 碎片飛散（高頻金屬碎片聲） | 0.8–1.2 秒 | freesound.org 搜尋 "door explosion breach" |
| SFX_DOOR_SHIELD | 盾撞破門（盾兵 Lv.9 選項） | 金屬盾牌撞擊聲 + 木材破裂，低頻為主 | 0.5–0.7 秒 | freesound.org 搜尋 "shield bash metal wood" |

---

## 三、大招音效

> 大招音效設計原則：施放瞬間需要有**清晰的觸發前奏**（0.1–0.2 秒預備音），然後主要效果音，讓玩家感覺到「我的主動操作產生了影響」。音效整體不超過 2 秒，避免在自動推進過程中佔用過多聽覺空間。

### 3-A 盾兵大招 — 防禦護盾

| 屬性 | 內容 |
|------|------|
| 情緒目標 | 「全隊有保護了」的安心感 + 金屬屏障質感 |
| 觸發前奏 | 0.1 秒金屬嗡鳴（低頻） |
| 主效果音 | 厚重金屬盾牌展開聲 + 能量屏障展開的電子感嗡聲（上升音調） |
| 持續音 | 盾持續期間有極低音量的電磁嗡鳴底音（5 秒） |
| 解除音 | 盾破碎 / 過期：金屬破碎短促聲 |
| 總時長 | 觸發 0.8–1.0 秒 + 持續低音 + 解除 0.3 秒 |
| 取得方式 | freesound.org 搜尋 "shield activate energy"；持續音可用合成 sine wave 200Hz 加 reverb |

---

### 3-B 醫療兵大招 — 緊急治療

| 屬性 | 內容 |
|------|------|
| 情緒目標 | 「回血了」的溫暖感 + 急救的緊迫感 |
| 觸發前奏 | 0.15 秒急救包打開拉鍊聲 |
| 主效果音 | 注射器聲 + 上升音調合成音（類似治療光芒展開） |
| 結尾 | 短促清脆的「叮」，確認治療完成 |
| 總時長 | 1.0–1.2 秒 |
| 取得方式 | freesound.org 搜尋 "medical inject heal"；上升音可用 Python 合成 400Hz→800Hz 掃頻音 |

---

### 3-C 突擊手大招 — 火力全開

| 屬性 | 內容 |
|------|------|
| 情緒目標 | 「全力輸出、清場」的爽快感，聽覺上最刺激 |
| 觸發前奏 | 0.1 秒槍械上膛聲（金屬拉栓） |
| 主效果音 | 密集連射聲爆發（0.5 秒高密度射擊音，比一般射擊音更密）+ 低頻爆發底音 |
| 持續音 | 整個火力全開期間（8 秒）射擊聲頻率提升，玩家可聽到明顯差異 |
| 結尾 | 換彈夾聲（金屬撞擊 + 彈夾插入） |
| 總時長 | 觸發 0.8 秒 + 持續段（依遊戲狀態） + 結尾 0.3 秒 |
| 取得方式 | freesound.org 搜尋 "assault rifle burst full auto" |

---

### 3-D 狙擊手大招 — 精準鎖定

| 屬性 | 內容 |
|------|------|
| 情緒目標 | 「精準、屏氣凝神」的張力感，然後一擊必殺的爽快 |
| 觸發前奏 | 0.3 秒瞄準鏡調焦聲（機械細聲） |
| 主效果音 | 極低頻呼吸聲 0.2 秒 → 狙擊槍重擊發射聲（低頻、帶長尾殘響 1.5 秒） |
| 目標消滅音 | 遠距離命中「砰」聲（比一般距離更悶） |
| 總時長 | 2.0–2.5 秒 |
| 取得方式 | freesound.org 搜尋 "sniper rifle shot long range"；呼吸聲搜尋 "breath hold quiet" |

---

### 3-E 爆破手大招 — 引爆炸彈

| 屬性 | 內容 |
|------|------|
| 情緒目標 | 最大爽快感，AOE 清場的震撼 |
| 觸發前奏 | 0.2 秒起爆器按鈕聲（塑料 click） |
| 主效果音 | 0.1 秒靜音預期感 → 大型爆炸聲（低頻強衝擊 bass drop + 碎片飛散高頻聲）+ 爆炸殘響 |
| 震動建議 | 配合手機震動回饋（Haptic），爆炸瞬間觸發短促震動 |
| 總時長 | 1.5–2.0 秒 |
| 取得方式 | freesound.org 搜尋 "large explosion indoor"；OpenGameArt.org 搜尋 "explosion sfx" |

---

### 3-F 偵察手大招 — 煙霧封鎖

| 屬性 | 內容 |
|------|------|
| 情緒目標 | 「戰略控制」的聰明感，聲音帶點神秘感 |
| 觸發前奏 | 0.15 秒煙霧彈取出 / 安全插拔聲 |
| 主效果音 | 煙霧彈投擲弧線聲（高頻風切）→ 著地「叩」→ 煙霧噴發聲（氣體洩出聲） |
| 持續音 | 煙霧散佈期間有細微的氣體嘶嘶底音（5 秒） |
| 結尾 | 煙霧消散：嘶嘶聲漸弱至靜 |
| 總時長 | 觸發 1.0–1.2 秒 + 持續氣聲 |
| 取得方式 | freesound.org 搜尋 "smoke grenade deploy hiss"；氣體聲搜尋 "gas hiss continuous" |

---

## 四、UI 音效清單

| 音效 ID | 觸發時機 | 情緒目標 | 音色描述 | 建議時長 | 取得方式 |
|---------|---------|---------|---------|---------|---------|
| SFX_UI_CLICK | 一般按鈕點擊 | 輕巧的操作確認感 | 短促清脆點擊聲，高頻（700–900Hz），不刺耳 | 0.05–0.08 秒 | freesound.org 搜尋 "button click ui"；或 Python 合成 |
| SFX_UI_DECISION_OPEN | 決策面板彈出（最重要！） | 立刻讓玩家感知「該我了」，清晰的聽覺中斷 | 中頻電子「嗶嗶」雙音（上行兩個音）+ 短促金屬卡入聲；整體乾淨、不拖長 | 0.3–0.5 秒 | freesound.org 搜尋 "notification alert military"；雙音可用合成 440Hz + 550Hz |
| SFX_UI_DECISION_CONFIRM | 決策面板選擇確認 | 「選好了，執行」的篤定感 | 中低頻確認聲，帶一點金屬點擊質感，比 CLICK 更有份量 | 0.15–0.2 秒 | freesound.org 搜尋 "confirm select heavy click" |
| SFX_UI_SKILL_READY | 大招 CD 冷卻完成提示 | 「可以用了！」的通知感，不打擾，但要讓玩家注意到 | 上升兩音合成音（乾淨的電子音），帶短殘響；音量比 DECISION_OPEN 低 20% | 0.2–0.3 秒 | Python 合成：440Hz→659Hz 兩音連續播，各 0.1 秒 |
| SFX_UI_SKILL_CLICK | 點擊角色卡施放大招（觸發前確認感） | 「點到了」，即時反饋 | 輕微金屬 click，比一般 UI 點擊略厚重 | 0.08–0.1 秒 | freesound.org 搜尋 "card select click" |
| SFX_UI_VICTORY | 關卡勝利主結算時（配合 BGM 1-E 播放後） | 最大滿足感 | 軍號式上升三音 fanfare + 低頻大鼓兩擊收尾 | 0.8–1.2 秒 | freesound.org 搜尋 "victory jingle military"；OpenGameArt.org 搜尋 "victory stinger" |
| SFX_UI_FAIL | 關卡失敗主結算時 | 輕度遺憾，不強烈負面 | 低頻下行兩音（悶），帶短殘響；音量壓低，讓玩家感覺「下次再來」而非沮喪 | 0.5–0.8 秒 | freesound.org 搜尋 "failure stinger short" |
| SFX_GACHA_NORMAL | 普通抽卡（一般稀有度） | 期待感 + 普通回饋 | 卡片翻轉聲 + 輕微光芒音 | 0.6–0.8 秒 | freesound.org 搜尋 "card flip reveal" |
| SFX_GACHA_RARE | 稀有抽卡 | 驚喜感提升 | 卡片翻轉 + 明顯電子光芒上升音 + 金屬光輝短殘響 | 1.0–1.5 秒 | freesound.org 搜尋 "rare card reveal sparkle" |
| SFX_GACHA_LEGENDARY | 超稀有抽卡 | 「大獎」的震撼感，要讓玩家感覺特別 | 慢動作展開感 — 低頻預備嗡聲（0.5 秒）→ 爆閃光芒聲（高頻撞擊 + 電子殘響 2 秒）→ 收尾上升音確認感 | 2.5–3.5 秒 | freesound.org 搜尋 "legendary reveal epic"；部分自合成加工 |

---

## 五、環境音效清單

### 5-A 基地場景環境音

| 音效 ID | 情緒目標 | 音色描述 | 建議時長（循環） | 取得方式 |
|---------|---------|---------|----------------|---------|
| AMB_BASE_INTERIOR | 沉穩、待命感，有人類活動痕跡但不吵雜 | 遠處低頻空調聲、偶發的鍵盤聲、極遠的金屬撞擊 / 工具聲、低頻電子設備嗡嗡聲 | 1:30–2:00 seamless loop | freesound.org 搜尋 "military base indoor ambient"；"control room ambience" |
| AMB_BASE_RADIO | 點綴層，不一定持續播 | 偶發的無線電靜電聲 + 短促語音片段（建議 0.5 秒靜電 + 模糊人聲，不要有具體台詞） | 單次 2–4 秒，隨機觸發 | freesound.org 搜尋 "radio static military" |

---

### 5-B 任務場景環境音 — 室內建築

| 音效 ID | 情緒目標 | 音色描述 | 建議時長（循環） | 取得方式 |
|---------|---------|---------|----------------|---------|
| AMB_MISSION_INDOOR | 緊張、未知、壓抑 | 低頻空氣聲、遠處金屬滴水聲（不規則）、偶發的遠處爆炸悶聲（極低音量，像遠方的戰鬥） | 1:00–1:30 seamless loop | freesound.org 搜尋 "abandoned building interior ambient" |
| AMB_MISSION_INDOOR_ALERT | 高警戒室內（敵人密集房間進入前） | 低頻嗡嗡電流聲 + 偶發的金屬敲擊 | 0:45–1:00 seamless loop | freesound.org 搜尋 "industrial alarm hum" |

---

### 5-C 任務場景環境音 — 工業區

| 音效 ID | 情緒目標 | 音色描述 | 建議時長（循環） | 取得方式 |
|---------|---------|---------|----------------|---------|
| AMB_MISSION_INDUSTRIAL | 機械感、壓抑、危險感 | 工廠機械運轉低頻聲、蒸汽洩出聲、金屬傳送帶聲、偶發的電焊閃光聲（短促） | 1:30–2:00 seamless loop | freesound.org 搜尋 "factory industrial ambient loop" |

---

### 5-D 任務場景環境音 — 雨夜室外

| 音效 ID | 情緒目標 | 音色描述 | 建議時長（循環） | 取得方式 |
|---------|---------|---------|----------------|---------|
| AMB_MISSION_RAIN_NIGHT | 孤立感、緊張感，暗示高難度任務 | 穩定雨聲（中密度，非暴雨）+ 遠雷偶發 + 水滴打金屬板聲 | 2:00 seamless loop | freesound.org 搜尋 "rain night urban ambient loop"；"rainy night street" |
| AMB_MISSION_RAIN_THUNDER | 點綴層，隨機觸發 | 雷聲（帶距離感，不要太近）| 單次 2–5 秒 | freesound.org 搜尋 "distant thunder rumble" |

---

## 六、音效系統架構建議（給程式設計師）

### 音量控制分組

```
MasterVolume（總音量）
├── BGM_Volume（背景音樂，獨立控制）
├── SFX_Volume（音效，包含戰場 + 大招 + UI）
│   ├── Battle_SFX（武器 / 受傷 / 腳步 / 門）
│   ├── Skill_SFX（六職業大招）
│   └── UI_SFX（按鈕 / 通知 / 勝敗）
└── Ambient_Volume（環境音，獨立控制）
```

### 優先順序規則（音效搶道優化）

手機端 AudioStreamPlayer 資源有限，優先順序如下：

| 優先等級 | 音效類型 | 說明 |
|---------|---------|------|
| 最高 | SFX_UI_DECISION_OPEN | 決策點出現，任何情況都必須完整播出 |
| 高 | 大招音效（SFX_SKILL_*） | 玩家主動觸發，需要即時回饋 |
| 中 | SFX_ENEMY_DOWN、SFX_ALLY_DOWN | 重要事件回饋 |
| 低 | 武器射擊音（連射期間可限制同時播放數量，最多 4 個聲道） |
| 最低 | 腳步聲（可在低效能裝置上關閉） |

### BGM 切換規則

| 情境 | 切換行為 |
|------|---------|
| 基地 → 任務開始 | 2 秒淡出基地 BGM，1 秒靜音，淡入任務 BGM |
| 任務 BGM 1-B → 1-C（高警戒） | 2 秒交叉淡入（crossfade） |
| 進入 Boss 房間 | 1 秒淡出 → 立刻切入 Boss BGM（無靜音段，保持緊張感） |
| 勝利 / 失敗 | 0.5 秒硬切，播勝利/失敗音效，之後 3 秒淡出回基地 BGM |

### 合成音效生成參考（Python wave 模組）

無法找到合適免費素材時，以下音效建議用 Python wave 模組合成：

- **SFX_UI_SKILL_READY**：440Hz→659Hz 掃頻，各 0.1 秒，加上 0.05 秒 fade out
- **SFX_UI_CLICK**：700Hz 正弦波，0.06 秒，帶 exponential decay
- **SFX_ALLY_CRITICAL（警告音部分）**：800Hz 正弦波，0.3 秒，帶 0.05 秒 fade out
- **大招持續底音**：對應頻率的 sine wave 加 reverb impulse response

---

## 七、素材蒐集指引（交接給素材蒐集員）

### 免費可商用音效推薦來源

| 來源 | 適合取得內容 | 授權類型 |
|------|------------|---------|
| freesound.org | 武器聲、環境音、UI 音效、爆炸聲 | CC0 / CC BY（注意各音效個別授權） |
| OpenGameArt.org | BGM、遊戲音效包 | CC0 / CC BY / OGA-BY |
| Pixabay Music | BGM 完整音樂 | Pixabay License（可商用）|
| Incompetech（Kevin MacLeod）| BGM 風格音樂 | CC BY |
| Freepd.com | BGM | CC0 |
| Zapsplat.com（免費帳號）| UI / 短音效 | Zapsplat License |

### 優先採購清單（按重要度排序）

1. SFX_UI_DECISION_OPEN — 整個遊戲最重要的單一音效，決策點的聽覺中斷信號
2. BGM 任務推進 1-B — 玩家聽最久的音樂
3. 六職業大招音效（可先做突擊手 + 爆破手）
4. SFX_WEAPON_ASSAULT / SNIPER — 出現頻率最高的武器音
5. BGM 基地主題 1-A
6. 環境音 AMB_MISSION_INDOOR
7. 抽卡三段音效（NORMAL / RARE / LEGENDARY）
8. 其餘 UI 音效（較容易找到或合成）

---

*AUDIO_SPEC 版本 1.0｜音效規劃｜2026-06-21*
