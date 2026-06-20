# 台灣熱炒王 — 開發者開啟指南

## 環境需求

- Godot 4.3 以上（建議使用最新穩定版 Godot 4.3.x）
- 下載位址：https://godotengine.org/download/

---

## 開啟專案步驟

1. 啟動 Godot 編輯器，進入 Project Manager
2. 點擊右上角 Import
3. 選擇此目錄下的 `project.godot` 檔案（路徑：`src/project.godot`）
4. 點擊 Import & Edit，等待引擎匯入資源
5. 按 F5 或點擊右上角播放鍵執行遊戲

---

## Android 匯出設定

1. 在 Godot 編輯器選單：Editor > Export Templates > Download and Install
2. 選擇對應版本的 Export Templates 並安裝
3. 安裝 Android Studio 與 Android SDK（API Level 21 以上）
4. 設定環境變數：
   - `ANDROID_HOME`：指向 Android SDK 目錄
   - `JAVA_HOME`：指向 JDK 目錄（建議 JDK 17）
5. 在 Godot：Project > Export > Add > Android
6. 填入 Package Name（如 `com.yourname.taiwanhot`）
7. 連接裝置後點擊 Export Project 或 One Click Deploy

---

## iOS 匯出設定

1. 需要 macOS + Xcode（最新穩定版）
2. 需要 Apple Developer Program 帳號（USD $99/年）
3. 在 Godot：Project > Export > Add > iOS
4. 填入 Bundle Identifier（如 `com.yourname.taiwanhot`）
5. 設定 Team ID（來自 Apple Developer 帳號）
6. 點擊 Export Project 產生 Xcode 專案
7. 用 Xcode 開啟產生的 `.xcodeproj`，選擇目標裝置後 Build & Run

---

## 目錄結構說明

```
src/
├── project.godot          — Godot 專案設定檔（從這裡 Import）
├── scenes/
│   ├── main/              — 根場景 Main.tscn
│   ├── game/              — 遊戲世界場景 Game.tscn（TileMap、角色容器）
│   └── ui/                — UI 場景 UI.tscn + AudioManager.tscn
├── scripts/
│   ├── core/              — 核心系統：GameManager、GridManager、GameClock
│   ├── ai/                — AI 狀態機：CustomerFSM、StaffFSM
│   ├── systems/           — 子系統：SaveManager、PathfindingManager、OrderManager
│   └── utils/             — 工具函數：常數定義、型別轉換、輔助函數
├── resources/
│   ├── data/              — 靜態遊戲資料：dishes.json、equipment.json、staff.json
│   └── themes/            — Godot Theme 資源：UI 主題樣式
├── assets/
│   ├── sprites/
│   │   ├── characters/    — 角色精靈表（老闆娘、廚師、外場、客人）
│   │   └── buildings/     — 設備與建築圖塊（TileSet 素材）
│   ├── audio/
│   │   ├── bgm/           — 背景音樂（.ogg 格式）
│   │   └── sfx/           — 音效素材（.ogg 或 .wav）
│   ├── fonts/             — 中文字型（.ttf，建議使用 OFL 授權字體）
│   └── ui/                — UI 圖片素材（按鈕、面板、圖示）
├── addons/                — Godot 外掛（若有使用第三方 plugin）
└── export/
    ├── android/           — Android 匯出設定與 keystore
    └── ios/               — iOS 匯出設定
```

---

## 技術架構文件

詳細架構設計請參閱：`../tech/godot-architecture.md`

包含：場景樹設計、TileMap 格子系統、FSM 狀態機、存檔系統、觸控輸入設計。
