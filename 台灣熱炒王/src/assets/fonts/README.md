# 字體素材說明

本目錄存放「台灣熱炒王」專案使用的字體檔案。
所有字體均為免費商用授權（OFL-1.1），可安全用於商業發行版本。

---

## 字體清單

### 1. Fusion Pixel Font（主要遊戲字體）

| 項目 | 內容 |
|------|------|
| 用途 | 遊戲內所有中文文字（菜單、對話框、HUD 數字） |
| 開發者 | TakWolf |
| 授權 | OFL-1.1（免費商用，需保留授權聲明） |
| 放置路徑 | `src/assets/fonts/fusion_pixel_8.ttf` |

**下載步驟：**

1. 前往 GitHub Releases 頁面：
   https://github.com/TakWolf/fusion-pixel-font/releases
2. 找到最新版本，下載以下任一檔案（擇一）：
   - `fusion-pixel-8px-monospaced-zh_tr.zip`（等寬版，推薦用於數字對齊）
   - `fusion-pixel-8px-proportional-zh_tr.zip`（比例版，推薦用於對話文字）
3. 解壓縮後取出 `.ttf` 檔
4. 重命名為 `fusion_pixel_8.ttf`
5. 放入本目錄（`src/assets/fonts/`）

---

### 2. Press Start 2P（標題 / 英文數字字體）

| 項目 | 內容 |
|------|------|
| 用途 | 遊戲標題、英文 UI 元素、計分顯示 |
| 授權 | OFL-1.1（免費商用，需保留授權聲明） |
| 來源 | Google Fonts |
| 放置路徑 | `src/assets/fonts/press_start_2p.ttf` |

**下載步驟：**

1. 前往 Google Fonts 頁面：
   https://fonts.google.com/specimen/Press+Start+2P
2. 點擊右上角「Download family」按鈕
3. 解壓縮下載的 ZIP 檔
4. 取出 `PressStart2P-Regular.ttf`
5. 重命名為 `press_start_2p.ttf`
6. 放入本目錄（`src/assets/fonts/`）

---

## 目錄結構（放置完成後）

```
src/assets/fonts/
├── README.md              <- 本檔案
├── fusion_pixel_8.ttf     <- 主要中文像素字體（手動下載）
└── press_start_2p.ttf     <- 英文標題字體（手動下載）
```

---

## Godot 4 設定備忘

### 匯入方式

1. 將 `.ttf` 檔放入 `res://assets/fonts/`（即本目錄）
2. Godot 編輯器會自動辨識並建立對應的 `.import` 檔
3. 在 Inspector 中建立 `FontFile` 資源，指向對應的 `.ttf`

### 像素字體必要設定

在 Godot 4 的字體匯入設定中，**必須關閉以下選項**，否則像素字體會模糊：

| 設定項目 | 值 |
|----------|----|
| Antialiasing | Disabled |
| Subpixel Positioning | Disabled |

### 建議字體大小

| 用途 | font_size 建議值 | 說明 |
|------|-----------------|------|
| 一般 UI 文字 | 16 | 8px 字體 x2 縮放，手機螢幕清晰 |
| 對話框文字 | 16 | 同上 |
| HUD 數字 | 16 | 同上 |
| 遊戲標題（Press Start 2P） | 16 或 32 | 依版面調整 |

### 程式碼範例（GDScript）

```gdscript
# 在程式碼中套用字體（選用）
var font = preload("res://assets/fonts/fusion_pixel_8.ttf")
$Label.add_theme_font_override("font", font)
$Label.add_theme_font_size_override("font_size", 16)
```

---

## 授權聲明範本

發行遊戲時，請在遊戲內或隨附的 CREDITS 文件中加入以下聲明：

```
Fusion Pixel Font by TakWolf
Licensed under SIL Open Font License 1.1
https://github.com/TakWolf/fusion-pixel-font

Press Start 2P by CodeMan38
Licensed under SIL Open Font License 1.1
https://fonts.google.com/specimen/Press+Start+2P
```
