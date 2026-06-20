專案類型: 遊戲

# FocusGirl（扉扉大冒險）— 專案規則

## 專案簡介

給兒童（小學以下）的注意力訓練小遊戲集合。玩家選擇角色（女孩/貓咪）後，從主選單挑選 14 款迷你遊戲，每款各有簡單/普通/困難三個難度。

**主角命名**：預設「扉扉」，可改成「澄澄」或自訂（最多 6 字），存在 localStorage。

## 技術架構

- **引擎**：Phaser 3.80.1（CDN 載入，不需 build）
- **檔案**：單一 `game.js` + `index.html`，零相依工具鏈
- **資產**：`assets/girl.png`、`assets/cat.png`（找不到圖自動退回 emoji）
- **音效**：Web Audio API `beep()` 合成，有靜音開關存 localStorage

## 14 款迷你遊戲

| 場景名 | 中文名 | 類型 |
|--------|--------|------|
| StarCatcher | 接星星 | 反應 |
| Schulte | 數字方格 | 注意力掃描 |
| Memory | 記憶翻牌 | 工作記憶 |
| Simon | 顏色複誦 | 序列記憶 |
| OddOneOut | 找不同 | 視覺辨別 |
| Maze | 走迷宮 | 手眼協調 |
| Bubble | 數泡泡 | 反應抑制 |
| Rhythm | 節奏拍拍 | 時間判斷 |
| Puzzle | 拼圖還原 | 空間推理 |
| Connect | 連連看 | 數字追蹤 |
| MissingPiece | 找缺角 | 視覺完形 |
| GoNoGo | 停停停 | 抑制控制 |
| MathSprint | 心算閃卡 | 數學流暢 |
| Stroop | Stroop測試 | 認知干擾 |

## 共用元件（game.js 最前面）

- `COLORS`：4 色系（紅/黃/綠/紫）
- `beep() / sfxCorrect / sfxWrong / sfxComplete`：音效
- `pressEffect(scene, target, onClick)`：按鈕彈跳動畫
- `popupText(scene, x, y, str, color)`：飄字效果
- `addBackButton / addSoundToggle / addHeader`：通用 Header
- `makeHearts / bobTween / addCharacter`：共用 UI 元件
- `annotatedInstruction`：注音標記指令文字
- `DIFFICULTY_PRESETS`：所有遊戲的三難度設定

## 場景流程

```
Boot → CharSelect → Menu → Difficulty → [遊戲場景] → Menu
```

## 注意事項

- 指令文字全部有注音（ㄅㄆㄇ），供幼兒閱讀
- 全觸控優先設計，`touch-action:none`
- 畫布寬度上限 480px，高度上限 854px，FIT 模式
- 不要加 build 工具、模組系統、型別系統——保持零工具鏈
