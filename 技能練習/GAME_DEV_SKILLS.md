# 遊戲開發技能庫

> 整合自 20 個深度研究 agent，涵蓋 GitHub 開源遊戲生態、Phaser 4、PixiJS v8、主流引擎等完整技術棧。
> 目標：讓每次開新遊戲時，能做出有根據的技術決策，而不是憑感覺。

---

## 一、引擎選型決策框架

### 先問三個問題

```
1. 主要分發在哪裡？
   瀏覽器（免費/廣告）→ Phaser 4
   手機 App Store  → Godot 4
   Steam 桌面       → Godot 4 / MonoGame
   多平台同時       → Godot 4

2. 對效能的要求是哪一層？
   一般 2D 遊戲     → Phaser 4 / Godot 4 都行
   百萬粒子/精靈     → PixiJS（純渲染）+ 自組架構
   3D AAA 品質      → O3DE（但殺雞用牛刀）

3. 預計的核心技術複雜度？
   完整遊戲引擎功能（物理/場景/音效/存檔）→ Phaser 4 或 Godot 4
   只需渲染層，自己組架構                   → PixiJS
   深度 C# 技術棧 + Steam 上架              → MonoGame
```

---

### 引擎比較表（你的技術背景適用）

| 引擎/框架 | 語言 | 適合場景 | 授權 | 學習成本 | 現況 |
|----------|------|---------|------|---------|------|
| **Godot 4** | GDScript/C# | 手機+PC+Web 跨平台，2D/3D | MIT | ★★ | ✅ 你已在用 |
| **Phaser 4** | TypeScript | 瀏覽器遊戲，AI 輔助最順 | MIT | ★★ | 值得學 |
| **PixiJS v8** | TypeScript | 純 2D 渲染，最快 WebGL | MIT | ★★★ | 搭配 Phaser 用 |
| **Defold** | Lua | 檔案最小、HTML5/Mobile | 免費商用 | ★★★ | 特定場景考慮 |
| **MonoGame** | C# | Celeste/STD 品質，Steam | MS-PL | ★★★★ | C# 背景才值得 |
| **O3DE** | C++ | AAA 3D，殺雞用牛刀 | Apache 2.0 | ★★★★★ | 不適合現階段 |

---

### 路線 A：瀏覽器遊戲（推薦入口）

```
TypeScript + Phaser 4 + Vite + AssetPack
↓
發布到 itch.io / GitHub Pages（免費）
→ 流量後接 Poki / CrazyGames SDK（廣告收入）
→ 穩定後 Electron 打包上 Steam
```

**Phaser 4 關鍵優勢**
- AI context 檔案（官方為 Claude/Cursor 提供），AI 輔助最流暢
- SpriteGPULayer 單次 draw call 渲染 100 萬精靈
- TilemapGPULayer 4096×4096 地圖固定成本渲染
- 統一 Filter 系統 24 種特效套用任何物件
- 官方支援 YouTube Playables、Discord Activities、Reddit 遊戲

### 路線 B：跨平台原生（現在走的路）

```
Godot 4 + GDScript + LDtk + Aseprite
↓
匯出 PC/Android/iOS/Web（一份代碼）
→ Android 上 Google Play / iOS 上 App Store
→ Web 版掛 itch.io
```

**Godot 4 關鍵事實**
- 39.8k stars，MIT 授權，無抽成
- CharacterBody2D + NavigationAgent2D 是俯視角遊戲標配
- Signal 系統（GodotSignal）是 Event Bus 的最佳實踐
- headless 測試 `--headless --quit` 可驗證腳本邏輯
- HTML5 匯出需要 SharedArrayBuffer（需特定 server header）

---

## 二、核心系統架構技能

### 2.1 有限狀態機（FSM）— 所有遊戲都需要

```gdscript
# Godot 4 FSM 範例
enum State { IDLE, PATROL, ALERT, CHASE, SHOOT }
var state = State.PATROL

func _process(delta):
    match state:
        State.PATROL: _do_patrol(delta)
        State.CHASE:  _do_chase(delta)
```

- 適用：敵人 AI、角色動畫狀態、遊戲流程控制
- 進階：行為樹（Behavior Tree）—比 FSM 更靈活，Godot 有 Beehave 插件

### 2.2 Signal Bus（全局信號匯流排）— 解耦關鍵

```gdscript
# autoload/SignalBus.gd（加到 Project Settings > Autoload）
signal enemy_died(enemy_id: int)
signal player_hurt(damage: int)
signal level_completed

# 任何地方發出
SignalBus.enemy_died.emit(enemy.id)

# 任何地方監聽（不需要直接引用節點）
SignalBus.enemy_died.connect(_on_enemy_died)
```

**為什麼重要**：避免節點間直接引用，降低耦合。HUD 不需要知道 Player 節點在哪，只需要監聽 SignalBus 的信號。

### 2.3 物件池（Object Pool）— 效能必備

```typescript
// Phaser 4 物件池範例
const bullets = this.physics.add.group({
    classType: Bullet,
    maxSize: 30,
    runChildUpdate: true
});

function fireBullet(x: number, y: number) {
    const bullet = bullets.get();
    if (bullet) bullet.fire(x, y);
}
```

- 避免頻繁 new/GC，在射擊/粒子場景是必須的
- Godot：使用 `queue_free()` 的時機要注意（不要在父節點 `_process` 中對子節點直接調用）

### 2.4 場景管理系統 — 遊戲的骨幹

**標準 Scene 流程**
```
Boot → Preloader（進度條）→ MainMenu → Game → GameOver
                                      ↑↓
                                   UI（並行）
```

**Godot 4 場景管理**
```gdscript
# 帶資料的場景切換（比 Autoload 變數更乾淨）
get_tree().change_scene_to_file.call_deferred("res://scenes/game.tscn")
```

**Phaser 4 場景管理**
```typescript
// UI 場景與遊戲場景並行運行
this.scene.launch('UI');    // 啟動 HUD，不停止 Game
this.scene.pause('Game');   // 暫停遊戲（保留 UI）
```

### 2.5 存讀檔系統 — 常被低估的複雜度

```gdscript
# Godot 4 存檔（JSON 方案）
func save_game():
    var data = {
        "player_hp": player.hp,
        "gold": gold,
        "level": current_level,
        "version": SAVE_VERSION
    }
    var file = FileAccess.open("user://save.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(data))

func load_game():
    if not FileAccess.file_exists("user://save.json"):
        return
    var file = FileAccess.open("user://save.json", FileAccess.READ)
    var data = JSON.parse_string(file.get_as_text())
    # 版本相容性檢查
    if data.get("version", 0) < SAVE_VERSION:
        _migrate_save(data)
```

### 2.6 事件驅動架構 vs 直接調用

| 方式 | 優點 | 缺點 | 適用 |
|------|------|------|------|
| 直接調用 `node.method()` | 簡單直覺 | 高耦合 | 父子關係明確時 |
| Signal/Event Bus | 解耦 | 追蹤難 | 跨系統通訊 |
| Data Store（共享狀態） | 集中管理 | 過度設計風險 | 複雜狀態同步 |

---

## 三、Phaser 4 專項技能

### 3.1 官方推薦模板（2026 最新）

```bash
npm create phaser-game@latest
```

| 模板 | 適合場景 |
|------|---------|
| `template-vite-ts` | **新專案首選**，Phaser 4 + Vite + TypeScript |
| `template-react-ts` | 需要 React UI 的遊戲 |
| `template-nextjs` | SEO/SSR 需求 |
| `template-webpack` | 傳統工作流 |

### 3.2 物理引擎選擇

```
平台遊戲、射擊、賽車、RPG 移動 → Arcade Physics（AABB，預設選擇）
憤怒鳥、積木、繩索、複雜地形  → Matter.js
3D 遊戲                        → Ammo.js (via enable3d)
```

### 3.3 Phaser 4 效能技巧

```typescript
// 1. SpriteGPULayer — 大量靜態精靈
const layer = this.add.spriteGPULayer();
layer.add(sprite);  // 單次 draw call 渲染所有

// 2. TilemapGPULayer — 大地圖
const map = this.make.tilemap({ key: 'map' });
const layer = map.createGPULayer('Ground', tileset);  // 固定成本

// 3. Texture Atlas — 減少 draw call
this.load.atlas('sprites', 'sprites.png', 'sprites.json');

// 4. AudioSprite — 一個檔案所有音效
this.load.audioSprite('sfx', 'sfx.json', ['sfx.ogg', 'sfx.mp3']);
```

### 3.4 Filter 系統（Phaser 4 獨有）

```typescript
// 對任意物件加特效
sprite.filters.internal.add('Glow');
sprite.filters.internal.add('Blur');
camera.filters.internal.add('Vignette');

// 24 種內建：Blur、Bokeh、Glow、Shadow、Pixelate、
// ColorMatrix、GradientMap、Barrel、Displacement、
// Wipe、Bloom、Vignette、Key（去背）、Mask、Stencil...
```

### 3.5 重要插件：Rex Rainbow

`rexrainbow/phaser3-rex-notes`（1,300+ stars）——Phaser 最重要的第三方資源

| 插件 | 功能 |
|------|------|
| TextEdit | 輸入框 |
| VirtualJoystick | 虛擬搖桿（手機必備）|
| FSM | 狀態機 |
| A* Pathfinding | 格子尋路 |
| HexagonGrid | 六角形格子 |
| BBCode Text | 富文字（顏色、大小）|
| Drag + Scroll | 拖拽滾動 |

```javascript
// 安裝方式（在 Game config 中）
const config = {
    plugins: {
        global: [{
            key: 'RexVirtualJoystick',
            plugin: VirtualJoystickPlugin,
            start: true
        }]
    }
};
```

### 3.6 多人遊戲：Phaser + Colyseus

```
[Phaser 客戶端]          [Colyseus 伺服器 (Node.js)]
    ↓                         ↓
 玩家輸入 →→→→→→→→→ 接收 → 驗證 → 廣播
 渲染畫面 ←←←←←←←←← Schema 差異同步（自動）
```

**關鍵優勢**：Schema 自動計算差異，只傳輸改變的部分，節省頻寬。

---

## 四、PixiJS v8 專項技能

### 4.1 PixiJS vs Phaser 選擇時機

```
需要完整遊戲功能（物理、場景管理、音效）→ Phaser 4
只需要超快速 WebGL 渲染，自己組架構   → PixiJS v8
需要嵌入 React/Vue 的互動遊戲/廣告     → PixiJS v8 + @pixi/react
```

**重要事實**：Phaser 3 的渲染引擎本身就是基於 PixiJS 架構。選 PixiJS 就是選「更底層的控制權」。

### 4.2 v8 基礎用法

```typescript
import { Application, Sprite, Assets } from 'pixi.js';

const app = new Application();
await app.init({ width: 800, height: 600, background: '#1099bb' });
document.body.appendChild(app.canvas);

const texture = await Assets.load('bunny.png');
const bunny = new Sprite(texture);
app.stage.addChild(bunny);

app.ticker.add((ticker) => {
    bunny.rotation += 0.1 * ticker.deltaTime;
});
```

### 4.3 ParticleContainer — 百萬粒子

```typescript
// 可跑 1,000,000 個粒子維持 60fps（MacBook M3）
const particles = new ParticleContainer();
for (let i = 0; i < 1000000; i++) {
    const p = new Particle();
    p.texture = texture;
    p.x = Math.random() * 800;
    p.y = Math.random() * 600;
    particles.addParticle(p);
}
app.stage.addChild(particles);
```

### 4.4 RenderGroup（靜態場景優化）

```typescript
// 把不常變動的子樹變成 RenderGroup
const background = new Container({ isRenderGroup: true });
// 靜止畫面幾乎不消耗 CPU
// 對比 Phaser 3 的重繪每幀全部：提升 17,417%
```

### 4.5 PixiJS Open-Games 最佳實踐提煉

來自 PixiJS 官方示範遊戲（Bubbo Bubbo + Puzzling Potions）：

**Navigation + AppScreen 模式**（可直接抄用）
```typescript
// AppScreen 統一介面
interface AppScreen {
    prepare?(data?: any): void;
    show?(): Promise<void>;
    hide?(): Promise<void>;
    update?(time: Ticker): void;
    resize?(w: number, h: number): void;
}

// Navigation 管理器維護兩層
// screenView（主畫面層）+ overlayView（浮層）
```

**資源分 Bundle 漸進載入**
```typescript
Assets.init({ manifest });
await Assets.loadBundle('preload');   // 啟動必要資源
await Assets.loadBundle('default');  // 通用資源
Assets.backgroundLoadBundle(['game', 'home']); // 背景非同步預載
```

**AsyncQueue 遊戲流程**（解決「動畫完才執行下一步」問題）
```typescript
// 不用 setTimeout，用 AsyncQueue 排列非同步步驟
// Match3Process 的 6 步驟：統計→特效→消除→重力→補充→檢查
```

**GSAP 做所有動畫**（官方做法，不用 Ticker 手寫補間）
```typescript
import gsap from 'gsap';
gsap.to(sprite, { x: 100, y: 200, duration: 0.3, ease: 'bounce.out' });
```

---

## 五、多人遊戲架構技能

### 5.1 架構選擇決策樹

```
需要防作弊？
├── 是 → 客戶端-伺服器（伺服器權威）
│        ├── 即時動作（FPS/BR）→ UDP + 客戶端預測 + 延遲補償
│        ├── 回合制（棋牌）   → WebSocket + 事件驅動
│        └── MMO             → 分片架構 + 多 Zone 伺服器
└── 否（或 P2P 可接受）
         ├── RTS/MOBA → P2P Lockstep（頻寬省，但需決定性）
         └── 格鬥/動作 → P2P Rollback（延遲感知最低）
```

### 5.2 三大同步方法比較

| 方法 | 適用 | 頻寬 | 防作弊 | 延遲感知 |
|------|------|------|--------|---------|
| **Lockstep（鎖步）** | RTS, MOBA | 極低（只傳指令）| 需決定性算法 | 受最慢玩家影響 |
| **Rollback（回滾）** | 格鬥、快速動作 | 低 | 無（P2P）| 最低（本地預測）|
| **Server Reconciliation** | FPS, MMO | 中 | 強（伺服器權威）| 低（客戶端預測）|

### 5.3 決定性的三大陷阱（P2P 必讀）

1. **浮點數**：不同 CPU 可能結果不同 → 改用定點整數（FixedMathSharp）
2. **容器迭代順序**：`unordered_map` 迭代順序不確定 → 改用有序容器
3. **隨機數**：各客戶端必須用相同 seed 序列 → 自訂 seeded RNG

### 5.4 Godot 多人方案

| 方案 | 適合場景 |
|------|---------|
| **netfox** | 伺服器授權 + rollback，有 lag compensation |
| **Snopek Rollback Plugin** | P2P rollback，格鬥遊戲，有教學系列 |
| **Colyseus SDK** | 官方 Godot 客戶端，搭配 Colyseus 伺服器 |

---

## 六、各遊戲類型核心技能

### 6.1 俯視角戰術遊戲（幽靈行動類型）

```
必備：
- CharacterBody2D + NavigationAgent2D（Godot）
- 視野錐形（RayCast2D 陣列或 Polygon2D）
- 霧戰（三層：未探索/看過/當前視線）
- 敵人 FSM（巡邏→警覺→追擊→射擊）
- 射線碰撞（PhysicsRayQueryParameters2D）

進階：
- A* 尋路（Godot 內建 AStarGrid2D）
- 行為樹（Beehave 插件）
- 掩體系統（NavObstacle2D）
- 噪音傳播系統
```

### 6.2 Roguelike / Roguelite

```
核心技能：
- 程序地圖生成（BSP 樹、蜂窩自動機、走廊連接）
- 視野系統（Shadow Casting FOV）
- A* 尋路
- 回合制系統（行動點、速度系統、事件佇列）
- 永久成長數據結構（跨局 vs 局內分離）

參考資源：
- rot.js（瀏覽器 Roguelike 工具庫）
- Brogue CE（最清晰的純 C Roguelike 代碼）
- Shattered Pixel Dungeon（Java，完整手機 Roguelike）
```

### 6.3 即時戰略（RTS）

```
核心技能：
- Flow Field Pathfinding（多敵人共享流場）
- 群體移動 Flocking / Formation
- 視野霧（Fog of War）—— 只傳可見實體
- 波次管理系統（Wave System）
- 鎖步同步（Lockstep）—— RTS 的網路方案

參考：
- OpenRA（C# + Lua，最完整的 RTS 引擎重製）
- 0 A.D.（C++ + Python，AoE II 等級）
```

### 6.4 平台跳躍

```
手感核心技術：
- Coyote Time（離開平台後短暫可跳，通常 0.1s）
- Jump Buffer（提前按跳躍自動觸發，通常 0.1s）
- 可變跳躍高度（長按跳更高）

碰撞技術：
- AABB 碰撞（最基礎）
- 斜坡處理（Snap to Floor）
- 單向平台（One-way Platform）

Camera 技術：
- 相機先行（Look Ahead）
- Trauma 震動系統（指數衰減，比直接 offset 自然）
- Cull Padding（視野外多渲染 2 格緩衝）
```

### 6.5 三消 / Match-3

```
核心演算法：
- 棋盤初始化（避免預先三連）
- 匹配掃描 O(n×m)
- 重力模擬（消除後下落）
- BFS 找連通塊

架構模式（來自 Puzzling Potions）：
- 邏輯/視覺分離（grid: number[][] vs pieces: Sprite[]）
- AsyncQueue 非同步消除流程
- 座標橋接函數（getViewPositionByGridPosition）
```

### 6.6 .io 類遊戲（Web 多人）

```
架構：
- WebSocket（TCP）+ Node.js
- 伺服器 30 ticks/秒（刻意低於渲染 60 FPS）
- 100ms 延遲緩衝 + 線性插值（讓 30 tick 看起來是 60 FPS）
- 只傳視野範圍內的實體（空間分割）

參考：
- vzhou842/example-.io-game（451 stars，最完整教學）
- Kaetram-Open（TypeScript MMORPG，µWebSockets 多伺服器）
```

---

## 七、資源管線技能

### 7.1 必學工具清單

| 工具 | 用途 | 優先級 |
|------|------|--------|
| **Aseprite** | 像素美術 + 動畫（匯出 JSON 動畫資料）| ★★★ 必學 |
| **LDtk** | 現代 2D 關卡編輯器（Godot 有官方插件）| ★★★ 推薦 |
| **Tiled** | 老牌地圖編輯器（.tmx 格式，Phaser 原生支援）| ★★ 次選 |
| **free-tex-packer** | Sprite Atlas 打包（免費替代 TexturePacker）| ★★★ 必用 |
| **AssetPack（Pixi）** | 自動生成圖集、manifest、優化音訊 | ★★ Pixi 生態必用 |

### 7.2 Aseprite 工作流

```
Aseprite 製作動畫
    ↓ 匯出 JSON（含幀資料）+ PNG
Phaser: this.load.aseprite('char', 'char.png', 'char.json')
Godot:  AnimatedSprite2D + SpriteFrames（匯入 JSON）
```

### 7.3 Texture Atlas（圖集）的重要性

- 把多張小圖合成一張大圖 → GPU 只綁定一次材質 → 減少 draw call
- **draw call 是 GPU 最大瓶頸**，不用圖集等於放棄效能

```typescript
// Phaser：一次載入所有精靈
this.load.atlas('game', 'game.png', 'game.json');

// PixiJS：AssetPack 自動處理
// 在 raw-assets/ 目錄後綴加 {tps} 就會自動打包
```

### 7.4 音效管線

| 工具 | 用途 |
|------|------|
| **Howler.js** | HTML5 音效庫（Phaser 內建，跨瀏覽器）|
| **ZzFX / ZzFXM** | 程序化音效生成（不需音效檔案，用於 js13k）|
| **Python wave 模組** | 簡易正弦波合成（臨時 placeholder）|
| **Audiosprite** | 多音效合併成一個檔案（減少 HTTP 請求）|
| **OpenGameArt.org** | 免費可商用音效/BGM 資源 |

---

## 八、工具鏈技能

### 8.1 HTML5 遊戲工具鏈

**最新推薦（2026）**
```
TypeScript + Phaser 4 + Vite        → phaserjs/template-vite-ts（官方）
TypeScript + React + Phaser 4      → phaserjs/template-react-ts（官方）
```

```bash
# 快速建立
npm create phaser-game@latest
```

### 8.2 Godot 工具鏈

**模板推薦**
- `maaack/Godot-Game-Template`（1,500 stars）— 15 分鐘搞定選單 + 設定 + 存檔
- `crystal-bit/godot-game-template`（922 stars）— 場景轉場 + 多執行緒載入

**必裝插件**
- `Beehave`（行為樹）
- `Phantom Camera`（相機控制）
- `GUT`（單元測試）

### 8.3 CI/CD（自動發布管線）

```yaml
# GitHub Actions 自動 export + 部署到 itch.io
name: Build
on: push
jobs:
  build:
    steps:
      - uses: actions/checkout@v4
      - name: Export Godot
        uses: firebelley/godot-export@v5
      - name: Deploy to itch.io
        uses: josephbmanley/butler-publish-itchio-action@v1
        env:
          BUTLER_CREDENTIALS: ${{ secrets.BUTLER_CREDENTIALS }}
          CHANNEL: html5
```

### 8.4 測試工具

| 工具 | 用途 |
|------|------|
| **Playwright** | HTML5 匯出後截圖驗證（黑畫面偵測）|
| **Godot headless** | `--headless --quit` 驗證腳本邏輯 |
| **GUT** | Godot 單元測試框架 |
| **Vitest** | Phaser/TS 單元測試 |

---

## 九、發布平台策略

### 9.1 平台選擇矩陣

| 平台 | 適合時機 | 收益模式 | 技術要求 |
|------|---------|---------|---------|
| **itch.io** | 第一款遊戲，驗證受眾 | 自定義售價（0% 平台費）| ZIP + index.html |
| **Poki** | 有成熟玩法、想要流量 | 廣告分潤（CPM）| HTML5 + Poki SDK |
| **CrazyGames** | 休閒到中度遊戲 | 廣告分潤 | HTML5 + CG SDK |
| **YouTube Playables** | 已有 Phaser 遊戲 | 廣告分潤 | Phaser 官方支援 |
| **Discord Activities** | 多人遊戲、社群強 | IAP + 訂閱 | Phaser 官方支援 |
| **Steam** | 完成度高、值得 $10+ | 70% 開發者分潤 | Electron 殼包 |
| **Google Play / App Store** | 手機遊戲 | IAP + 廣告 | Godot 原生匯出 |

### 9.2 推薦發布路徑

```
第一步：itch.io（免費上架，獲取早期回饋）
    ↓
第二步：接 Poki 或 CrazyGames SDK（廣告收入）
    ↓
第三步：手機版 Godot → Google Play / App Store
    ↓
第四步（可選）：Electron 打包 → Steam
```

### 9.3 itch.io 技術注意事項

- 最多 1,000 個解壓後的檔案
- 單檔不超過 200MB，總解壓不超過 500MB
- 伺服器**區分大小寫**（Windows 開發者必看：`Assets` ≠ `assets`）
- 所有外部請求必須用 HTTPS
- HTML5 需要 SharedArrayBuffer → 使用 polyfill 或改單執行緒 Wasm build

---

## 十、HTML5 效能優化要點

### 10.1 反模式（絕對要避免）

```javascript
// ❌ 每幀 new 物件 → GC 爆炸
function update() {
    bullets.push(new Bullet(x, y));
}

// ✅ 物件池
const bullet = bulletPool.get();
if (bullet) bullet.fire(x, y);
```

```javascript
// ❌ 每幀清空全部 Canvas 重畫
ctx.clearRect(0, 0, w, h);
tiles.forEach(t => t.draw()); // 10,000 個格子

// ✅ 靜態背景畫到離屏 Canvas
ctx.drawImage(offscreenMap, 0, 0); // 一次 drawImage
dynamicObjects.forEach(o => o.draw()); // 只畫動態物件
```

```javascript
// ❌ O(N²) 暴力碰撞
enemies.forEach(e1 => enemies.forEach(e2 => checkCollision(e1, e2)));

// ✅ QuadTree 空間分割 O(N log N)
const nearby = quadTree.query(enemy.bounds);
nearby.forEach(n => checkCollision(enemy, n));
```

### 10.2 音效自動播放政策

```typescript
// 瀏覽器阻止自動播放，必須等使用者互動
document.addEventListener('pointerdown', () => {
    audioContext.resume();
    bgm.play();
}, { once: true });
```

### 10.3 高 DPI 螢幕處理

```typescript
// Phaser Config
const config = {
    resolution: Math.max(window.devicePixelRatio, 2)
};

// PixiJS
await app.init({ resolution: Math.max(devicePixelRatio, 2) });
```

---

## 十一、幽靈行動（Ghost Squad）技術分析

### 現況

| 面向 | 狀態 |
|------|------|
| 引擎 | Godot 4 ✅ 適合 |
| 進度 | 5 關 + HQ 基地，headless exit 0 |
| 素材 | ColorRect 佔位圖（最大問題）|
| 下一步 | 陣形系統（4 人小隊架構跳躍）|

### 現有架構的優缺點

**優點**
- NavigationAgent2D 已驗證可用
- FSM 敵人 AI（巡邏→追擊→射擊）架構正確
- 三層霧戰（ImageTexture 方案）已通
- headless 測試穩定

**潛在風險**
- 4 人小隊 = 4 個 NavigationAgent2D 同時計算，效能壓力未知
- 霧戰 ImageTexture 方案需要 4 個視野錐合併，手機效能待驗證
- HTML5 匯出的 SharedArrayBuffer 問題（之前踩過坑）

### 優先執行的技術任務

**第一優先：素材替換**
```
下載 Kenney Top-Down Shooter Pack（CC0）
整合 CraftPix 士兵 Sprite（已列在 GDD 素材清單）
讓 4 個角色在視覺上有辨識度
→ 這一步完成後，陣形系統才能真正測試
```

**第二優先：陣形系統架構**
```gdscript
# 建議的陣形架構
class_name Formation
var positions: Array[Vector2]  # 相對主位置的偏移
var primary_slot: int          # 哪個槽是主要位置

# FormationManager（Autoload）
var current_formation: Formation
var squad: Array[Node2D]       # 4 個隊員節點

func switch_formation(formation: Formation):
    # 重新分配各隊員的目標偏移位置
    # NavigationAgent2D.target_position = primary_pos + offset
```

**第三優先：Signal Bus 重構**
```gdscript
# 建立 autoload/SignalBus.gd
signal squad_member_died(member_id: int)
signal enemy_spotted(enemy: Node2D)
signal formation_changed(formation_name: String)
signal mission_objective_updated(type: String, count: int)
```

### 引擎切換評估

**什麼時候值得換 Phaser 4**
- 陣形系統的 NavigationAgent2D 同時計算造成明顯卡頓（手機 < 30 FPS）
- 霧戰 4 個視野錐合併效能無法優化到 30 FPS

**換 Phaser 4 的代價**
- 所有 5 關 + HQ 場景 GDScript → TypeScript 重寫
- NavigationAgent2D 沒有對等物，需要用 Rex Rainbow 的 A* 或自實作
- 估計重寫時間：2-3 週

**結論**：先做陣形系統，遇到效能牆才換。

---

## 十二、開源遊戲值得深讀的 Repo

### 架構學習

| Repo | 語言 | 學習重點 |
|------|------|---------|
| **BrowserQuest** | HTML5/JS | Mozilla 出品 MMO，client/server 架構 |
| **OpenRA** | C# + Lua | YAML Trait 系統、Lua 任務腳本、完整 RTS 引擎 |
| **DevilutionX** | C++ | Diablo 1 逆向，1996 年遊戲架構教材 |
| **Mindustry** | Java + LibGDX | 工廠+塔防，現代熱門獨立遊戲代碼 |
| **Veloren** | Rust | Voxel RPG，ECS + 網路層，有完整文件 |

### 俯視角遊戲參考

| Repo | 引擎 | 特色 |
|------|------|------|
| **Hypersomnia** | C++ 自製 | 競技俯視射擊，決定性網路架構 |
| **Liblast** | Godot 4 | 多人 FPS，驗證 Godot 4 做 FPS 可行性 |
| **Teeworlds** | C++ | 2D 多人平台射擊，網路架構參考 |

### Phaser 完整遊戲範例

| Repo | Stars | 學習重點 |
|------|-------|---------|
| **OpenSC2K** | 5.1k | Phaser 3 重製 SimCity 2000 |
| **PrinceJS** | 993 | 波斯王子 HTML5，動畫狀態機 |
| **channingbreeze/games** | 2.3k | 100+ 小遊戲，每個都是獨立範例 |
| **SkyOffice** | 1.3k | React + Phaser + Colyseus 多人辦公室 |
| **reldens** | 564 | 完整 MMORPG 平台（Node.js + Colyseus）|

---

## 十三、遊戲模板最佳實踐總結

### 一個好的遊戲起手式必備 7 個系統

| 系統 | Godot 做法 | Phaser 做法 |
|------|-----------|------------|
| 場景管理 + 轉場 | SceneManager Autoload + 動畫 | Scene Manager + EventBus |
| 主選單 + 暫停 | 獨立 Scene | 獨立 Scene |
| 設定存讀 | ConfigFile | localStorage 封裝 |
| 音效管理 | AudioBus + Singleton | @pixi/sound 三層 |
| 輸入管理 | InputMap 預設 | ControlManager 抽象層 |
| 存讀檔 | FileAccess JSON | localStorage 命名空間 |
| 除錯工具 | DebugCanvas（release 移除）| Stats.js |

### 資料夾結構（功能導向，非類型導向）

```
assets/           ← 美術/音效/字體
scenes/
  ├── main_menu/
  ├── gameplay/
  └── settings/
scripts/
  ├── autoload/   ← 全局單例（Godot）或 Singletons（Phaser）
  ├── managers/   ← 系統管理器
  ├── components/ ← 可複用元件
  └── utils/      ← 工具函式
```

---

---

## 十四、跨平台引擎深度比較

### 14.1 Godot 4（你正在用的）— 深度解析

**版本**：4.7（2026-06-18），113k stars，MIT

**三種渲染器（選擇決定手機能不能跑）**

| 渲染器 | 後端 | 適用場景 |
|--------|------|---------|
| **Forward+** | Vulkan / DX12 / Metal | PC + 高端主機，SDFGI + 體積霧 |
| **Mobile** | Vulkan（行動優化）| 手機主力，tile-based GPU 優化 |
| **Compatibility** | OpenGL ES 3.0 | HTML5 匯出唯一選擇，舊硬體 |

**Web 匯出必讀**：HTML5 只能用 Compatibility 渲染器，**C# 腳本不支援 Web 匯出**（4.x 全版本）。

**Godot 4.7 最重要的新功能**
- Jolt Physics 正式整合（比原生 GodotPhysics 效能大幅提升）
- 內建 `VirtualJoystick` 節點（手機搖桿免插件）
- Android 獨立建置（GABE，不需 Android Studio）
- Metal 原生後端（Apple M 系列效能提升，告別 MoltenVK 翻譯層）
- Ubershaders（解決首次渲染 shader 編譯卡頓）
- `tween_await()` 函式（等待 Signal 再繼續 Tween）

**架構核心：Server 層可以繞過 Scene**

```gdscript
# 正常用法（99% 的情況）
var sprite = Sprite2D.new()
add_child(sprite)

# 直接操作 RenderingServer（管理 10 萬+ 物件時）
var item = RenderingServer.canvas_item_create()
RenderingServer.canvas_item_add_texture_rect(item, rect, texture)
# 注意：Server 可以自由寫入，禁止讀取（會強制等待造成效能崩塌）
```

**Signal 連接的三種模式**
```gdscript
# 同步（立即執行，預設）
signal.connect(callable)

# 延遲（幀末執行，安全修改 SceneTree）
signal.connect(callable, CONNECT_DEFERRED)

# 一次性（觸發後自動斷開）
signal.connect(callable, CONNECT_ONE_SHOT)
```

**主機發行路線**：不直接提供主機匯出，需透過 W4 Games 或 Lone Wolf Technology 商業服務（Buckshot Roulette 已登 Switch/PS/Xbox）。

---

### 14.2 Defold — 最適合 HTML5 的引擎

**定位**：「做一件事，做到最好」— 輕量、HTML5/手機優先

**為什麼適合 Web 遊戲**
- HTML5 包體 gzip 後 **1.06 MB**（Godot 9 MB，Unity 8 MB）
- Android 包體 **1.97 MB**（Godot 24 MB）
- Poki 官方黃金合作夥伴（全球最大 HTML5 遊戲平台之一）

**根本不同：訊息傳遞系統（非 Signal）**

```lua
-- Defold 用 URL 定址，訊息非同步入佇列
msg.post("enemy#controller", "take_damage", { amount = 10 })

-- 接收端
function on_message(self, message_id, message, sender)
    if message_id == hash("take_damage") then
        self.health = self.health - message.amount
    end
end
```

Godot 的 Signal 是同步調用，Defold 的 `msg.post` 是非同步佇列——永遠不會在 `msg.post` 的同幀執行，是根本性的架構差異。

**Render Script（Lua 控制渲染管線）**

```lua
function update(self)
    -- 你決定渲染順序（不是引擎決定）
    render.draw(self.background_pred)
    render.draw(self.tile_pred)
    render.draw(self.character_pred)
    render.draw(self.ui_pred)
end
```

**圖形 API**：OpenGL / Vulkan / Metal / WebGL 2.0 / **WebGPU**（2025 新增）

**Lua 注意事項**
- 用 LuaJIT（但 iOS 禁止 JIT，HTML5 用標準 Lua 5.1）
- **只用 Lua 5.1 語法**，確保跨平台相容
- 每幀重複 `vector3()` 是記憶體壓力，要重用物件

**Collection Proxy（獨特的多世界架構）**：每個 Proxy 有獨立物理世界，物理碰撞不跨世界。關卡切換靠 Proxy 載入/卸載實現，時間縮放可以各世界獨立控制。

**什麼時候選 Defold**
- 目標是 Poki/CrazyGames 等 HTML5 平台
- 已有 Lua 背景（Roblox 開發者）
- 對包體大小有極致要求（廣告互動遊戲、品牌遊戲）

**什麼時候不選**
- 需要 3D（Defold 的 3D 支援有限）
- 需要大量社群插件
- 需要 C# 或 Python（Lua 思維差距大）

---

### 14.3 MonoGame — C# 的底層掌控

**定位**：「框架（Framework）而非引擎（Engine）」—— XNA 的開源繼承者

**關鍵事實**
- 14k stars，Celeste、Stardew Valley、Streets of Rage 4、TMNT Shredder's Revenge 都用它
- Re-Logic（Terraria）和 ConcernedApe（Stardew Valley）是 Premier Sponsors
- 無版稅、無授權費、MS-PL 授權

**MonoGame 不提供（要自己做）**
- 場景編輯器（純 code）
- 物理引擎（需整合 Farseer/Jitter）
- ECS 架構（需自己設計或用 Nez）
- 動畫狀態機
- 粒子系統
- UI 系統

**但這是優點**：完全控制，代碼 = 架構，無引擎開銷。這也是 Celeste 能做出精確手感的關鍵。

**Content Pipeline（最重要的概念）**

```
原始資源（PNG/WAV/FBX/HLSL）
    ↓ 編譯期預處理
.xnb 二進位格式（GPU 直讀，DXT/PVRTC 壓縮）
    ↓ 執行期
ContentManager.Load<Texture2D>("player")
```

Texture2D 記憶體壓縮對比：
- 直接載入 PNG：262KB → 4MB+（RGBA 展開）
- Content Pipeline：262KB → 32KB（GPU 壓縮格式）

**近期重大發展（3.8.5 preview）**
- DirectX 12 後端（preview）
- Vulkan 後端修復
- GPU Instancing 在 DX12 後端啟用

**適合誰**：有 C# 背景、不喜歡引擎限制、想做 Steam 桌面遊戲或主機移植的開發者。

**不適合**：沒有程式背景的創作者、需要快速原型。

---

### 14.4 O3DE — AAA 引擎架構的學習標本

**定位**：Amazon Lumberyard 捐給 Linux Foundation，Apache 2.0，AAA 級 3D

**不適合現在用的原因**
- 9.4k stars（Godot 113k，差距 12x）
- 3,400 個未解決 Issue（積壓嚴重）
- 學習曲線 = Godot 的 5-10 倍
- 建置環境需要 1-2 天才能跑起來
- 2D 支援遠不如 Godot

**但值得學習的架構思想**

**EBus（Event Bus 的終極版）**
```cpp
// 宣告 Bus
class MyBus : public AZ::EBusTraits {
public:
    virtual void OnEvent(int value) = 0;
};
using MyBusBroadcast = AZ::EBus<MyBus>;

// 廣播（比 Godot Signal 更系統化）
MyBusBroadcast::Broadcast(&MyBus::OnEvent, 42);
```

這個設計可以遷移思維到 Godot 的 SignalBus Autoload 上。

**Gem 模組化系統**：「引擎級 npm package」— 只打包用到的功能，和 Godot 插件（Plugin）概念相似但更嚴格。資料驅動配置（JSON）而非 code 配置。

**Atom Renderer 架構（技術上很先進）**
```
Feature Gems（陰影、GI、PostFX）
    ↓
RPI（Render Pipeline Interface）
    ↓
RHI（Render Hardware Interface）
    ↓
DX12 / Vulkan / Metal（各後端）
```

Pass 系統完全資料驅動，渲染管線用 JSON 配置，不改 C++ 就能調整渲染流程。

**唯一不可替代的優勢**：**ROS2 整合**（機器人操作系統）— 工業模擬、倉儲自動化、自動駕駛測試環境的唯一開源選擇。

**結論**：O3DE 是用來「讀」的，理解 AAA 引擎架構極限長什麼樣，而不是現在就切換過去。

---

### 14.5 四引擎選型速查

```
做瀏覽器遊戲（Poki/itch.io/YouTube Playables）
    → 輕量/精簡：Defold（最小包體）
    → 功能完整/AI輔助：Phaser 4

做手機 App（App Store/Google Play）
    → 唯一答案：Godot 4

做 Steam 桌面遊戲（C# 偏好）
    → MonoGame（完全控制）或 Godot 4

做 AAA 3D 開放世界
    → Unreal Engine（現實考量）
    → O3DE（學術/工業/Apache 2.0 商業需求）

做你現在的幽靈行動
    → 繼續 Godot 4（已有 5 關 + HQ 基地）
```

---

*最後更新：2026-06-21 | 來源：20 個深度研究 agent 全部完成*
