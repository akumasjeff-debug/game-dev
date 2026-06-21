# 幽靈行動 itch.io 發布清單

版本：Demo v0.1.0 | 更新：2026-06-21

---

## 必要項目

- [ ] HTML5 build（index.html + index.pck + index.wasm + index.js）
- [ ] 封面圖（630×500px 或 315×250px）
- [ ] 截圖（至少 3 張，1080×1920 或 16:9）
- [ ] 遊戲標題（英文）
- [ ] 遊戲描述（英文）
- [ ] 操作說明（含控制方式）
- [ ] 版本號（Demo v0.1.0）

---

## 已就緒

### HTML5 Build
- [x] `build/web/index.html` — 主頁面
- [x] `build/web/index.pck` — 遊戲資料包
- [x] `build/web/index.wasm` — WebAssembly 執行檔
- [x] `build/web/index.js` — JavaScript 引擎橋接
- [x] `build/web/index.audio.worklet.js` — 音效 WorkerThread
- [x] `build/web/index.icon.png` — 頁籤圖示

### 截圖（1080×1920，已生成）
- [x] `docs/screenshots/screenshot_01_base.png` — 基地畫面（任務板 + 陣容選擇 + 出發按鈕）
- [x] `docs/screenshots/screenshot_02_mission.png` — 任務進行中（地圖路徑 + HUD + 角色卡片）
- [x] `docs/screenshots/screenshot_03_gacha.png` — 招募中心（6 職業卡牌列表 + 升級/招募按鈕）

備用截圖（540×960，較小尺寸）：
- [x] `docs/screenshots/01_base.png`
- [x] `docs/screenshots/02_mission.png`
- [x] `docs/screenshots/03_decision.png` — 決策面板
- [x] `docs/screenshots/04_victory.png` — 勝利結算

### 文案（已完成）
- [x] 遊戲標題：Ghost Squad: Tactical Command
- [x] 短描述（107 字元）：見 `docs/DEMO_DESCRIPTION_EN.md`
- [x] 長描述（英文）：見 `docs/DEMO_DESCRIPTION_EN.md`
- [x] 長描述（繁中）：見 `docs/ITCH_PAGE.md`
- [x] itch.io 標籤 10 個：tactical / idle / strategy / gacha / mobile / top-down / squad / roguelite / singleplayer / demo
- [x] 版本號命名規則：見 `docs/ITCH_PAGE.md` 第八節
- [x] 內容分級說明：12+，輕度風格化暴力，無血腥無粗口

### 平台規格筆記（已整理）
- [x] iOS App Store：標題 30 字元（正好符合）、字幕 27 字元、關鍵字 100 字元已規劃
- [x] Google Play：標題 50 字元內、短描述 < 80 字元版本備存
- [x] Steam（未來）：需 5 張截圖、Capsule 圖 460×215px — 尚未執行

---

## 待補

### 素材（高優先）
- [ ] **封面圖 630×500px**（itch.io 搜尋結果卡片用）— 目前無成品圖，需要手繪或 AI 生成
  - 建議內容：遊戲標題 + 四人小隊側影 + 黑暗軍事場景背景
  - 顏色基調：深軍綠 `#1A2B1A` + 重點橙 `#E8600A`
- [ ] **Banner 圖 960×540px**（頁面頂部橫幅）— 需另行生成
- [ ] **遊戲 Icon 256×256px**（頁籤 / 書籤圖示）— `build/web/index.icon.png` 目前為 Godot 預設圖示

### 技術驗證
- [ ] **SharedArrayBuffer 設定確認** — Godot 4 HTML5 需要特定 HTTP header（`Cross-Origin-Opener-Policy: same-origin`），itch.io 的 「SharedArrayBuffer support」選項需勾選
- [ ] **嵌入視窗尺寸設定** — itch.io 後台建議設定 `1080 × 1920`（直屏）或 `720 × 1280`
- [ ] **遊戲從 itch.io 嵌入播放器正常載入**（本地測試已 OK，itch 環境尚未驗證）
- [ ] **手機瀏覽器版面確認**（itch.io 頁面在 iOS Safari / Android Chrome 上版面正常）

### 文案補充
- [ ] **操作說明文字**（itch.io 頁面應說明觸控 / 滑鼠操作方式）
  - 建議加入：「點擊決策選項 / Click decision options」
  - 建議加入：「點擊角色卡片觸發大招 / Tap character card to use skill」
- [ ] **隱私政策 URL**（iOS App Store 正式提交前必須，itch.io 不強制要求）

### 發布當天確認
- [ ] 封面圖與截圖已上傳並顯示正常
- [ ] 試玩一次確認遊戲從 itch.io 頁面正常啟動
- [ ] 社群媒體發文準備完成（附 itch.io 連結）

---

## 上傳步驟（itch.io）

1. 登入 [itch.io](https://itch.io) → Dashboard → **Create new project**
2. Kind of project：選 **HTML**
3. 將 `build/web/` 目錄下所有檔案打包為 `ghost_squad_demo_v010.zip`：
   ```
   index.html
   index.pck
   index.wasm
   index.js
   index.audio.worklet.js
   index.audio.position.worklet.js
   index.icon.png
   index.apple-touch-icon.png
   ```
4. 上傳 zip，勾選「**This file will be played in the browser**」
5. 設定嵌入視窗尺寸（Embed options）：寬 `1080`、高 `1920`（或 `540 × 960`）
6. 勾選「**SharedArrayBuffer support**」（Godot 4 必須）
7. 上傳封面圖（630×500px）與三張截圖
8. 填寫標題、短描述、長描述、標籤
9. Pricing：Free + Name Your Price
10. Visibility：先設 **Restricted**（私人測試）→ 確認無誤後改為 **Public**
11. Release status：**In development**
12. 開啟 Community（留言功能）
13. 點擊 **Save & view page**，在頁面內確認遊戲可正常啟動

---

## 版本號規則

| 類型 | 格式 | 說明 |
|------|------|------|
| 主版本 | X.0.0 | 完整版發布、重大架構改變 |
| 次版本 | 0.X.0 | 新功能（新職業、新關卡、抽卡系統） |
| 修補版本 | 0.0.X | Bug 修復、數值調整、文字錯誤 |

**本次發布：Demo v0.1.0**

---

*發布規劃師產出 | 2026-06-21*
