# FocusGirl（扉扉大冒險）狀態

## 已完成

- 14 款迷你遊戲全部可玩（StarCatcher、Schulte、Memory、Simon、OddOneOut、Maze、Bubble、Rhythm、Puzzle、Connect、MissingPiece、GoNoGo、MathSprint、Stroop）
- 三難度選擇（DifficultyScene + DIFFICULTY_PRESETS）
- 角色選擇（女孩 girl.png / 貓咪 cat.png，含 emoji 退回）
- 角色命名（預設扉扉，支援自訂、重置、快選澄澄）
- 注音指令文字（所有遊戲標題說明）
- 靜音開關（localStorage 記憶）
- 音效合成（Web Audio API beep）
- 觸控優先 UI
- **[2026-06-20] 五個遊戲補「再玩一次」按鈕**（Bubble、OddOneOut、Maze、MissingPiece、Memory）
- **[2026-06-20] Connect 改為點按模式**（移除 pointerup 重置邏輯，改成點第一個、再點下一個）
- **[2026-06-20] Stroop 簡單難度熱身版**（timeLimit >= 4000ms 時字色一致，幼童可靠顏色判斷）
- **[2026-06-20] 進度記錄系統（localStorage）**（getRecord/setRecord，涵蓋 Bubble、OddOneOut、MissingPiece、GoNoGo、MathSprint、Stroop、Rhythm、Schulte、Memory、Puzzle）
- **[2026-06-20] 主選單最佳記錄顯示**（各遊戲格下方顯示最佳分/最快時/最少次）
- **[2026-06-20] 主選單遊戲分類標籤**（右上角粉底小標籤，14 款遊戲各有反應/掃描/記憶等標籤）
- **[2026-06-20] 7 款新迷你遊戲**（數數看、影子配對、記住順序、顏色混色、找相同、認識時鐘、左右手），game.js 從 1576 行增至 2561 行，同步至 D:\子安的武器庫\遊戲\FocusGirl\game.js

## 進行中

-

## 待辦

### 優先 0：7 款新遊戲完成（2026-06-20）
- SubitizingScene（數數看）：完成，行 1593
- ShadowMatchScene（影子配對）：完成，行 1775
- SequenceMemoryScene（記住順序）：完成，行 1892
- ColorMixScene（顏色混色）：完成，行 2037
- FindSameScene（找相同）：完成，行 2146
- ClockReadScene（認識時鐘）：完成，行 2259
- DualTaskScene（左右手）：完成，行 2417

### 優先 1：成就牆（尚未實作）
- 增加一個「成就牆」場景（打星星，3 顆為完整通關）
- 根據最佳紀錄換算星等

### 優先 2：遊戲結束鼓勵話語
- 加入隨機一句鼓勵話語（不只是「太棒了」）
- Stroop / GoNoGo / MathSprint 結束時顯示正確率百分比

### 優先 3：主選單「今日推薦」
- 每天隨機 3 款高亮，降低幼童選擇困難

### 優先 4：StarCatcher 結束畫面補「再玩一次」
- StarCatcher、Simon（已有）、Schulte、Rhythm、Puzzle、GoNoGo、MathSprint、Stroop 等遊戲的結束畫面可統一加「再玩一次」

## 待確認

-

## 已知問題

-

## 操作紀錄

- 2026-06-20：從 D:\子安的武器庫\遊戲\FocusGirl 複製至此繼續開發
- 2026-06-20：7 款新遊戲加入，game.js 2561 行，同步至 D:\子安的武器庫\遊戲\FocusGirl\game.js
- 2026-06-20：製作人進行全局評估，更新待辦清單與已知問題
- 2026-06-20：五項優化完成實作，game.js 從 1514 行增至 1576 行
  - 新增 getRecord/setRecord 工具函式（第 1-8 行）
  - 新增 GAME_TAGS 常數（第 201 行附近）
  - OddOneOutScene.init() 加 this.initTime
  - MissingPieceScene.init() 加 this.initTime
  - ConnectScene 移除 pointerup/pointermove，改為 pointerdown 點按
  - StroopScene.init() 加 this.isEasy flag
  - MenuScene.makeSquare() 加 sceneKey 參數、最佳記錄顯示、分類標籤
