# 台灣熱炒王 — 素材參考清單

**版本：** v1.0
**建立日期：** 2026-06-20
**負責人：** 素材蒐集員
**狀態：** 初稿，供美術組、音效規劃、程式設計師參考

---

## 第一部分：字體資源

---

### 1. Zpix 像素中文字體（商業授權需付費，謹慎評估）

- **來源：** https://github.com/SolidZORO/zpix-pixel-font
- **授權類型：** 個人/教育用途免費；**商業用途需付費**（單一商品 USD $1,000 / RMB ¥7,000）
- **重要說明：** Zpix 過去曾以 MIT 授權釋出，但目前版本（v3.x）已改為商業授權模型。若預算允許，Zpix 的字形質量極高且繁簡日文一次滿足；若預算有限，建議改用下方備選方案。
- **字體規格：**
  - 基礎尺寸：12px（11px 字形 + 1px 留白）
  - 字元數量：21,998 字（英文 + 繁體中文 + 簡體中文 + 日文）
  - 提供格式：`.ttf`（TrueType）、`.bdf`（點陣格式）
- **下載位置：** GitHub Releases 頁面 → https://github.com/SolidZORO/zpix-pixel-font/releases → 下載最新版 `.zip`，解壓後取 `zpix.ttf`
- **Godot 4 使用方式：**
  1. 將 `zpix.ttf` 放入 `assets/fonts/` 目錄
  2. 在 Godot Import 面板中選取該字體檔案
  3. 建立 `FontFile` Resource，設定 `Base Size = 12`（或 12 的倍數）
  4. 在所有使用像素字體的 Label / RichTextLabel 節點，將 `TextureFilter` 設為 `Nearest`（最重要一步，避免模糊）
  5. Project Settings > Rendering > Textures > Default Texture Filter 也建議全域設為 `Nearest`
- **適合用途：** 遊戲內所有中文 HUD、對話框、菜單、數值顯示
- **使用注意：** 使用前務必確認商業授權費用，並保留授權証明文件

---

### 2. Press Start 2P 字體（推薦優先使用 — 英數字標題）

- **來源：** Google Fonts → https://fonts.google.com/specimen/Press+Start+2P
- **授權類型：** SIL Open Font License 1.1（OFL-1.1）— 完全免費商用，可修改，需保留原授權聲明
- **設計師：** Cody "CodeMan38" Boisclair
- **字體規格：**
  - 基礎設計來源：1980 年代 Namco 街機字型
  - 最佳顯示尺寸：8px、16px 及 8 的倍數
  - 字元支援：基礎拉丁字母（A-Z、a-z）、數字（0-9）、常見標點、希臘字母、西里爾字母
  - **不支援中文** — 純英數字體
- **下載方式：**
  1. 前往 Google Fonts 頁面，點擊右上角「Download family」按鈕
  2. 解壓後取 `PressStart2P-Regular.ttf`（只有一個字重）
  3. 亦可從 Zone38 作者頁面直接下載：http://www.zone38.net/font/
- **適合用途：** 遊戲英文標題、積分顯示、純英數 HUD 元素（如 HP、等級數字搭配英文標記）
- **使用注意：**
  - 只有英數字，中文一律不可用此字體
  - 在 Godot 中同樣需設定 `TextureFilter = Nearest`
  - 顯示效果最佳的是 8px 整數倍大小，避免縮放到奇數像素尺寸

---

### 3. 備選中文像素字體（若 Zpix 商業授權費用過高）

#### 3a. Fusion Pixel Font（方舟融合像素字體）— 推薦優先備選

- **來源：** https://github.com/TakWolf/fusion-pixel-font
- **授權類型：** OFL-1.1（字體本身）/ MIT（建置工具）— 完全免費商用，無需付費
- **字體規格：**
  - 提供尺寸：8px、10px、12px（三種大小）
  - 寬度模式：等寬（Monospaced）/ 比例（Proportional）各一套
  - 字元支援：繁體中文（zh_hant）、簡體中文（zh_hans）、日文、韓文、拉丁字母
  - 風格：無襯線像素風格（Sans-serif 像素設計）
- **最新版本：** 2026.05.07（積極維護中）
- **下載位置：** GitHub Releases → https://github.com/TakWolf/fusion-pixel-font/releases
- **適合用途：** 可完全取代 Zpix 的免費開源替代方案，支援繁體中文，適合遊戲內所有中文顯示
- **使用注意：** 依照 OFL-1.1 規定，字體名稱不可修改後以相同名稱再發布；單純用於遊戲無此限制

#### 3b. Vonwaon Bitmap Font（萬物點陣字體）— CC0 最乾淨授權

- **來源：** https://timothyqiu.itch.io/vonwaon-bitmap
- **授權類型：** CC0 1.0 Universal（公共領域，完全免費商用，不需標示作者）
- **字體規格：**
  - 提供尺寸：12px、16px（分別對應 9pt、12pt）
  - 字元數量：7,543 字形（含 6,763 個中文字、日文假名、希臘文、俄文、注音符號、拼音）
  - 包含繁體中文常用字
- **下載方式：** itch.io 頁面「Download Now」→「名自定價」（輸入 $0 即可免費下載）
- **適合用途：** 授權最乾淨的選項（CC0），適合不想處理任何授權文件的情況
- **使用注意：**
  - 有評論指出其字形資料源自早期 DOS 時代字體，建議確認在當地的法律適用性
  - 字元涵蓋範圍比 Zpix 少，較偏僻的漢字可能缺字

---

## 第二部分：像素素材參考（視覺風格參考，不直接使用）

---

### 開羅（Kairosoft）風格遊戲視覺參考

以下為台灣熱炒王開發時的視覺風格參考，用於理解目標畫面語言。這些截圖和連結僅供參考，不可直接擷取素材使用。

---

#### 參考遊戲一：Game Dev Story（ゲーム発展途上国）

- **開發商：** Kairosoft（日本）
- **視覺特色：**
  - 俯視角 2D 像素，輕微斜等角透視感（辦公室格子排列）
  - 人物比例：約 16x24px 左右的小人，頭身比約 1:1.5（大頭小身）
  - 色盤：鮮豔飽和，以橘黃色系為主，高對比度
  - 每個員工有工作動畫（坐在桌前打字、移動等）
  - UI 風格：圓角白底視窗，細邊框，日式小方格設計
- **公開截圖來源：**
  - Steam 頁面：https://store.steampowered.com/app/1846780/Game_Dev_Story/
  - Kairosoft Wiki：https://kairosoft.wiki.gg/wiki/Game_Dev_Story
- **台灣熱炒王可借鑒：** 員工動畫風格、俯視角格子系統、UI 視窗設計語言

---

#### 參考遊戲二：Hot Springs Story 2（温泉むすめの宿2）

- **開發商：** Kairosoft（日本）
- **視覺特色：**
  - 俯視角 2D 像素，建設模式下有明確的格子系統
  - 畫面顯示解析度（Steam 截圖格式）：1920x1080（為展示用放大版本）
  - 實際遊戲以輕量像素風呈現，250MB 以內的小遊戲
  - 賽季變化（春夏秋冬）有對應的環境色調轉換
  - 客人類型多樣，有不同服裝的小人精靈
  - 「可愛」(Cute) 風格定位，顏色明亮溫暖
- **公開截圖來源：**
  - Steam 頁面：https://store.steampowered.com/app/2089450/Hot_Springs_Story_2/
- **台灣熱炒王可借鑒：** 季節色調系統、客人多樣性設計、建設格子視覺語言

---

#### 參考遊戲三：Recettear: An Item Shop's Tale（Recettear ～アイテム屋さんのつくり方～）

- **開發商：** EasyGameStation（日本）
- **視覺特色：**
  - 俯視角 2D 像素，商店經營模式
  - 角色比例偏向「大頭萌系」，比開羅系列更卡通化
  - 色盤溫暖，以室內木質色調為主
  - UI 有豐富的對話框和道具圖標系統
  - 特色：物品懸浮飄字、顧客互動對話框
- **公開截圖來源：**
  - Steam 頁面：https://store.steampowered.com/app/70400/Recettear_An_Item_Shops_Tale/
- **台灣熱炒王可借鑒：** 商店互動 UI 設計、道具圖標風格、顧客對話框設計

---

#### 參考遊戲四：Stardew Valley（星露谷物語）

- **開發商：** ConcernedApe（美國獨立）
- **畫面解析度：** 基礎 1x 解析度 480x270（4 倍放大到 1920x1080 顯示）
- **視覺特色：**
  - 俯視角 2D 像素，農場/村莊經營
  - 角色 16x16px 精靈（縮放後顯示），頭身比 1:2
  - 色盤：四季分明，春天鮮綠、冬天銀白，整體柔和溫暖
  - 瓦片地圖：16x16 格子系統
  - 特色：室內外場景無縫切換，光影效果豐富
- **公開截圖來源：**
  - Steam 頁面：https://store.steampowered.com/app/413150/Stardew_Valley/
  - 官網：https://www.stardewvalley.net/screenshots/
- **台灣熱炒王可借鑒：** 480x270 基礎解析度確認可行、室內場景設計、瓦片系統規格

---

#### 參考遊戲五：Overcooked！2（胡鬧廚房 2）

- **開發商：** Ghost Town Games（英國）
- **視覺特色：**
  - 俯視角廚房操作，但採用 3D 多邊形（非像素），作為「廚房動感」的視覺語言參考
  - 廚房道具排列方式、工作流動路線設計值得參考
  - 鍋碗瓢盆的視覺辨識度設計（形狀清楚、顏色鮮豔）
- **公開截圖來源：**
  - Steam 頁面：https://store.steampowered.com/app/728880/Overcooked_2/
- **台灣熱炒王可借鑒：** 廚房空間動線設計、食材和道具的 icon 視覺語言（雖非像素但可轉譯）

---

## 第三部分：音效素材來源

> 對應 `content/audio-spec.md` 的 39 個音效需求及 6 首 BGM

---

### 推薦免費音效網站

#### 1. Freesound.org

- **網址：** https://freesound.org
- **授權類型說明：**
  - **CC0**：公共領域，完全免費商用，無需標示，最優先選擇
  - **CC BY 4.0**：免費商用，但必須在遊戲內或說明文件中標示作者姓名和來源
  - **CC BY-NC**：僅非商業用途免費，**商業遊戲不可使用**，搜尋時必須排除
- **搜尋技巧：** 進入網站後，在搜尋結果頁面左側勾選「Licenses」→ 只勾選 CC0 或 CC BY（排除 CC BY-NC 和 CC BY-ND）
- **推薦搜尋關鍵字（對應 audio-spec.md 需求）：**

  | 音效類別 | 搜尋關鍵字 |
  |---------|-----------|
  | 鍋氣/炒菜聲（SFX_COOK_WOK_GAS） | `wok sizzle`、`stir fry sizzle`、`hot oil sizzle` |
  | 大鑊氣（SFX_COOK_WOK_BURST） | `flame burst kitchen`、`gas flame burst` |
  | 碰盤聲（SFX_COOK_PLATE_CLANK） | `plate clank`、`ceramic bowl hit` |
  | 剁菜聲（SFX_COOK_CHOP） | `chopping board`、`knife chop wood` |
  | 水流聲（SFX_COOK_WASH_FLOW） | `running water sink`、`water tap` |
  | 沸騰聲（SFX_COOK_BOIL） | `water boiling`、`pot boiling loop` |
  | 炒拌聲（SFX_COOK_STIR） | `wooden spoon stirring`、`spatula pan` |
  | 開火聲（SFX_COOK_FIRE_ON） | `gas stove ignite`、`lighter click fire` |
  | 椅子聲（SFX_SERVICE_SEAT） | `chair scrape floor`、`chair drag` |
  | 結帳聲（SFX_SERVICE_BILL） | `cash register ding`、`coins money` |
  | 門鈴聲（SFX_ENV_DOOR_BELL） | `door bell chime`、`shop door bell` |
  | 炭火聲（SFX_ENV_CHARCOAL） | `charcoal fire crackle`、`campfire loop` |
  | 夜市環境（SFX_ENV_NIGHT_MARKET） | `night market ambient`、`street food crowd`、`asian street ambient` |
  | 鞭炮聲（SFX_FESTIVAL_FIRECRACKER） | `firecracker short`、`firecrackers burst` |
  | 鑼鼓聲（SFX_FESTIVAL_DRUM） | `chinese drum`、`gong drum percussion`、`temple drum` |
  | 烤肉聲（SFX_FESTIVAL_BBQ） | `meat grill sizzle`、`barbecue sizzle fat drip` |
  | UI 點擊（SFX_UI_CLICK） | `button click short`、`ui click light` |
  | 升級音效（SFX_UI_LEVELUP） | `level up chime`、`success jingle short` |
  | 金幣聲（SFX_UI_MONEY_FLY） | `coin pickup`、`coin ding` |

---

#### 2. OpenGameArt.org

- **網址：** https://opengameart.org
- **授權說明：** 平台上大多數素材為 CC0 或 CC BY，部分有 GPL。搜尋後注意看每個素材頁面頂端的授權標示。
- **推薦授權過濾：** 在搜尋頁面選擇「Field License」→ 選 CC0 或 CC-BY 3.0/4.0，確保可商用
- **適合搜尋的內容：**

  | 類型 | 搜尋關鍵字 |
  |-----|-----------|
  | 8-bit BGM 音樂包 | `8-bit bgm loop`、`chiptune game music`、`retro loop` |
  | 輕快風格 BGM | `upbeat casual music`、`shop theme loop`、`management game bgm` |
  | 8-bit 音效包 | `8-bit sfx pack`、`retro sound effects`、`chiptune sfx` |
  | UI 音效 | `pixel level up`、`retro coin`、`chiptune button click` |
  | 亞洲/東方風 BGM | `oriental music loop`、`asian themed bgm` |

- **特別說明：** OpenGameArt 上的素材通常已是 `.ogg` 格式，可直接用於 Godot 4，無需格式轉換

---

#### 3. itch.io（免費音效包）

- **網址：** https://itch.io/game-assets/free/tag-audio
- **搜尋方式：** 使用標籤篩選，例如「8-bit」「pixel」「chiptune」「sfx-pack」
- **授權注意：** itch.io 上每個素材包的授權各自不同，下載前必須點入頁面確認授權聲明（通常在頁面下方或 README 內）
- **推薦尋找的素材包類型：**
  - 8-bit UI 音效包（含按鈕、確認、取消、升級、通知等基礎 UI 音效）
  - Chiptune 廚房/餐廳主題 BGM 包（關鍵字：`chiptune loop pack`、`8-bit restaurant`）
  - 環境音效包（關鍵字：`ambient sound pack`、`crowd noise`、`restaurant ambient`）
  - 像素遊戲節慶音效包（關鍵字：`celebration sfx`、`pixel party sounds`）
- **注意：** 搜尋到感興趣的包後，在頁面確認授權是否含「Commercial Use OK」或明確標示 CC0 / MIT

---

#### 4. Pixabay Music（已在 audio-spec.md 中列出，補充說明）

- **網址：** https://pixabay.com/music/
- **授權類型：** CC0（完全免費商用，無需標示）— 授權最乾淨
- **特別說明：** 收錄大量亞洲風格 BGM，包含五聲音階旋律和現代化東方樂器編曲，與台灣熱炒王的音樂方向高度吻合
- **推薦亞洲風 BGM 搜尋詞：** `asian background`、`oriental upbeat`、`chinese festival`、`taiwan`、`night market`

---

### 8-bit BGM 自製工具

若找不到合適的免費 BGM，以下工具可用於自製 8-bit 台灣風格音樂：

#### BeepBox（beepbox.co）

- **網址：** https://beepbox.co
- **授權：** 免費，開源（MIT），無需安裝，純瀏覽器使用
- **功能：** 瀏覽器內直接作曲，支援方波、三角波、鋸齒波、FM 合成器和噪音頻道，作品可匯出為 `.wav`（免費版）或透過擴充版匯出 `.ogg`
- **適合用途：** 快速製作 BGM Demo 草稿、UI 音效短句、測試旋律想法
- **特色：** 曲目自動儲存在 URL 中，分享超方便，無賬號需求；入門學習曲線極低
- **限制：** 音色選擇較少，適合輕量 8-bit 風格，較難做出複雜編曲

#### FamiStudio（免費）

- **網址：** https://famistudio.org
- **授權：** 完全免費，開源（MIT）
- **平台：** Windows / Mac / Linux
- **功能：** 精確模擬 NES（FC/紅白機）的 2A03 音效晶片，支援 5 個頻道（2 個方波、1 個三角波、1 個噪音、1 個 DPCM 取樣），支援顫音、滑音、琶音等技巧；可匯出 NSF（真實 NES 可播放格式）和 `.wav`
- **適合用途：** 製作高品質的 NES 風格 BGM，最終正式版音樂製作（而非 Demo）
- **特色：** 匯出品質穩定，可在真實 NES 硬體播放，音色具有正統 8-bit 質感
- **學習資源：** 有官方教學視頻，YouTube 上教學豐富

#### PICO-8（付費，需特別標注）

- **網址：** https://www.lexaloffle.com/pico-8.php
- **授權：** 付費軟體（個人授權約 USD $14.99，含終身更新）
- **功能：** 虛構的幻想遊戲機（Fantasy Console），內建像素編輯器、地圖編輯器、音效編輯器、音樂編輯器，可獨立用於製作 8-bit 音效和 BGM
- **音樂功能：** 支援 4 頻道 chiptune 作曲，音效/BGM 可匯出供外部使用（`.wav`）
- **適合用途：** 對 8-bit 創作環境感興趣的開發者，PICO-8 是完整的一站式像素遊戲開發環境，音樂功能只是其中一部分
- **注意：** 有免費線上版（https://www.pico-8.com，功能受限）可先試用再決定是否購買

---

## 第四部分：Godot 4 像素遊戲設定備忘

---

### 步驟 1：解析度設定

**路徑：** Project > Project Settings > Display > Window

| 設定項目 | 設定值 | 說明 |
|---------|-------|------|
| Viewport Width | `480` | 遊戲基礎寬度 |
| Viewport Height | `270` | 遊戲基礎高度（16:9 比例） |
| Window Width Override | `1920`（選填） | 桌面測試用視窗大小，不影響遊戲解析度 |
| Window Height Override | `1080`（選填） | 桌面測試用視窗大小 |

> 480x270 以 4 倍縮放正好達到 1920x1080，是像素遊戲的理想基礎解析度。

---

### 步驟 2：Stretch（縮放）模式設定

**路徑：** Project > Project Settings > Display > Window > Stretch

| 設定項目 | 設定值 | 說明 |
|---------|-------|------|
| Stretch Mode | `canvas_items` | 整個畫面在原始解析度渲染，縮放時保持清晰 |
| Stretch Aspect | `keep` | 維持 16:9 比例，不拉伸變形 |
| Scale Mode | `integer`（Godot 4.3+） | 只允許整數倍縮放（2x、3x、4x），確保像素正方 |

> 使用 `viewport` 模式會在低解析度下渲染整個場景（更道地的 lo-fi 感），但補間動畫和粒子效果會顯得鋸齒明顯。`canvas_items` 模式較適合有複雜 UI 動畫的作品。

---

### 步驟 3：Texture Filter（紋理濾波）全域設定

**路徑：** Project > Project Settings > Rendering > Textures

| 設定項目 | 設定值 | 說明 |
|---------|-------|------|
| Default Texture Filter | `Nearest` | 最近鄰濾波，保持像素銳利不模糊（最重要！） |

> 這是最容易遺忘的設定。若設為預設的 `Linear`，所有像素圖片縮放時會模糊，失去像素風格。

**個別節點設定（若需要覆蓋）：**

對於單個 `Sprite2D`、`TextureRect`、`AnimatedSprite2D` 節點，可在 Inspector 中找到 `CanvasItem > Texture > Filter`，設為 `Nearest`。

---

### 步驟 4：像素貼齊（Pixel Snap）設定

**路徑：** Project > Project Settings > Rendering > 2D

| 設定項目 | 設定值 | 說明 |
|---------|-------|------|
| Snap 2D Transforms to Pixel | `On` | 強制所有 2D 變換貼齊像素格，避免精靈在亞像素位置抖動 |
| Snap 2D Vertices to Pixel | `On`（建議） | 確保頂點也貼齊像素 |

> 不啟用此設定時，移動中的精靈可能會在某些位置看起來「不夠清晰」，因為它停在 0.5 像素的位置。

---

### 步驟 5：Camera2D 像素貼齊設定

在使用 `Camera2D` 時，若相機有平滑跟隨效果，需要額外確認：

```gdscript
# Camera2D Inspector 設定
# Position Smoothing > Enabled = false（關閉位置平滑，避免相機在亞像素位置）
# 若需要平滑效果，使用 Tween 自行實作並在 _physics_process 中以 floor() 貼齊
```

或在相機腳本中強制像素貼齊：

```gdscript
func _process(delta: float) -> void:
    # 將相機位置貼齊到最近的整數像素
    position = position.floor()
```

---

### 步驟 6：字體設定（補充）

在 Godot 4 中使用像素字體時：

1. 匯入 `.ttf` 後，在 Import 面板設定 `Antialiasing = None`、`Hinting = None`
2. 在 `FontFile` Resource 的 `Rendering > Multichannel Signed Distance Field` 設為 **Off**
3. Label 節點的 `Theme Overrides > Font Size` 應設為字體基礎尺寸的整數倍（Zpix 使用 12 的倍數，Press Start 2P 使用 8 的倍數）

---

## 推薦優先使用

| 類別 | 推薦選項 | 理由 |
|-----|---------|------|
| 中文像素字體 | **Fusion Pixel Font**（3a） | OFL 免費商用，繁體中文完整，積極維護，12px 規格與設計吻合 |
| 英文標題字體 | **Press Start 2P** | OFL 免費商用，最標準的 8-bit 像素字體，社群支援豐富 |
| 廚房音效 | **Freesound.org**（篩 CC0） | 廚房錄音最豐富，廚師音效細節（鍋氣、切菜、炒拌）種類最多 |
| BGM 及 8-bit 音效包 | **OpenGameArt.org** | 專為遊戲設計，多為 OGG 格式，可直接導入 Godot |
| 亞洲風 BGM 搜尋 | **Pixabay Music** | CC0 最乾淨，亞洲風 BGM 收錄比其他平台多 |
| BGM 自製工具 | **FamiStudio**（長期）/ **BeepBox**（草稿） | FamiStudio 品質最高，BeepBox 最快上手 |

---

*文件結束 — 素材蒐集員 v1.0*
*下一步：程式設計師確認 Godot 4 像素設定、音效規劃師開始在 Freesound / OpenGameArt 搜尋對應音源、美術規格師確認字體選用方向（Fusion Pixel Font 或等待 Zpix 授權評估結果）。*
