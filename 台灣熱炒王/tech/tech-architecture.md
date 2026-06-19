# 台灣熱炒王 — 技術架構初稿

**文件版本：** v0.1  
**建立日期：** 2026-06-20  
**負責人：** 技術組長（程式設計師）  
**狀態：** 引擎選型待使用者決定，其餘架構已可推進

---

## 一、引擎選型評估（重大決策，請使用者決定）

### 選項 A：Godot 4（GDScript / C#）

**優點**
- 2D 像素原生支援優秀：CanvasItem 渲染管線天生為 2D 優化，像素過濾設定簡單（Filter = Nearest）
- TileMap 節點直接對應格子建造系統，官方內建格子碰撞、A* 路徑尋找（AStar2D）
- StateMachine 可透過 AnimationTree 或自定義 Node 輕鬆實作，客人/員工 AI 開發友善
- 行動端打包：iOS / Android 均官方支援，Export Template 直接輸出
- 完全免費，MIT 授權，無任何版稅或席位費
- GDScript 學習門檻低，社群文件完整；C# 模式也支援（需 .NET 6+）
- 社群生態 2024 年後快速成長，像素遊戲範例豐富

**缺點**
- 相比 Unity 商業插件市場較小
- C# 版本在行動端 AOT 編譯偶有坑（GDScript 反而穩定）
- Godot 4.0 初期有些 bug，建議使用 4.2 以上穩定版

**技術適配度：** 高  
**一句話總結：** 最適合本專案的引擎，2D 像素 + 格子系統原生支援，完全免費。

---

### 選項 B：Unity（C#）

**優點**
- 行動端生態最成熟：iOS / Android 測試工具鏈、效能 profiler 完整
- Asset Store 生態龐大，Tilemap 套件、A* 路徑套件（A* Pathfinding Project）成熟
- 2D 功能完整，URP 2D Renderer 支援像素藝術燈光效果
- 大量熱炒類型遊戲前例（開羅風格）有 Unity 實作範例可參考
- C# 語言強型別，大型 codebase 維護性高

**缺點**
- **授權費用問題（重要）：** Unity 2022.3+ 改為 Unity Personal（免費版）上限：年收入 < 100,000 USD，超過需 Unity Pro（$2,040/年/席位）
- Unity 2023 年的「Runtime Fee」政策（後來撤回）留下信任危機，授權條款隨時可能改變
- 像素遊戲需要額外設定（Pixel Perfect Camera、Compression 設定），不如 Godot 直觀
- 二進位場景格式不利 Git 版本控制（需要 Smart Merge 或 YAML 場景格式）
- 啟動與編譯時間比 Godot 慢

**技術適配度：** 中高  
**一句話總結：** 技術能力夠強，但授權政策不穩定是長期風險，個人/小團隊專案要計算成本。

---

### 選項 C：Phaser.js（TypeScript，Web-based）

**優點**
- 純 Web 技術：部署到任何靜態主機即可，零安裝門檻
- TypeScript 開發體驗好，VSCode 整合完整
- 像素渲染簡單（Canvas / WebGL 均支援，Nearest 過濾一行設定）
- 可透過 Capacitor / Cordova 包成 App，成本低

**缺點**
- **行動端效能瓶頸明顯：** WebView 包裝的 App 在低階安卓裝置上幀率常不穩定，AI 密集計算（多客人同時尋路）有 JS 單執行緒瓶頸
- 發布到 App Store 需走 Capacitor 等中間層，審核體驗不如原生
- **沒有格子系統原生支援**，Tilemap 需自行實作或依賴 Tiled 外部工具整合
- 路徑尋找需引入 pathfinding.js 等第三方套件，維護性要評估
- 無法雙端（桌面安裝版）輕鬆發布，如需 Steam 需要再套 Electron
- 程式碼架構需自行搭建（無 Scene/Node 系統）

**技術適配度：** 中  
**一句話總結：** Web 部署方便但行動端效能和 AI 計算量是顯著疑慮，格子系統需全自建。

---

### 選項 D：其他引擎補充評估

#### Defold（Lua）
- 腰公司（King）背後支持，免費
- 2D 原生，行動端效能優秀（C++ 核心）
- **缺點：** Lua 語言社群較小，格子系統和 AI 工具需自建，學習曲線偏高

#### GameMaker（GML / GameScript）
- 開羅風格遊戲大量前例（Stardew Valley 等）
- **缺點：** 授權費用（$99/年，行動端需 $199/年），GML 語言職業市場小，技術彈性有限

#### Love2D（Lua）
- 極輕量，Lua，PC 優先
- **缺點：** 行動端支援差，無法正式發布到 App Store，排除

---

### 引擎選型建議（供使用者決策）

**技術組建議傾向：選項 A（Godot 4）**

理由：
1. **格子系統天生支援**：TileMap + A* 直接對應本遊戲核心需求，省去大量底層搭建時間
2. **完全免費**：無授權風險，個人或小團隊長期開發無後顧之憂
3. **雙平台打包**：手機（iOS/Android）與 PC（Windows/Mac/Linux）同時支援，為目標平台 TBD 保留最大彈性
4. **AI 實作友善**：Node 架構讓狀態機清晰，每個客人/員工是一個獨立 Node，邏輯隔離好維護
5. **像素遊戲社群**：有大量開羅風格的 Godot 開源案例可參考

若目標平台確認為**純 PC（Steam 優先）** 且團隊有 Unity 熟練者，Unity 仍是可考慮的次選。

---

## 二、核心架構設計（引擎中立）

### 2.1 格子系統（Grid System）

#### 資料結構

```
GridMap（二維陣列）
├── width: int           // 地圖格子寬度
├── height: int          // 地圖格子高度
└── cells: Cell[][]      // 二維格子陣列

Cell
├── x: int               // 格子 X 座標
├── y: int               // 格子 Y 座標
├── type: CellType       // EMPTY | FLOOR | WALL | DOOR
├── object_id: string    // 擺放的設備/桌椅 ID（null 表示空）
├── is_walkable: bool    // 是否可通行（影響尋路）
├── is_occupied: bool    // 是否有物件佔用
└── metadata: dict       // 額外屬性（如地板材質 ID）
```

#### 座標系

- 採用**螢幕座標系**：左上角為 (0, 0)，X 向右，Y 向下
- 格子大小（tile_size）：統一常數，建議 16px 或 32px（待美術定案）
- 世界座標 → 格子座標轉換：`cell_x = floor(world_x / tile_size)`

#### 碰撞設計

- 格子層級碰撞：Cell.is_walkable 決定是否可通行，尋路演算法直接查表
- 物件佔多格：大型設備（如廚房台）記錄 anchor_cell（錨點格）+ 佔用格列表
- 碰撞更新觸發：放置/移除物件時更新受影響格子的 is_walkable，重新觸發尋路快取清除

#### 尋路策略

- 採用 A*（A-Star）演算法
- 路徑快取：相同起點/終點重複使用快取路徑，客人/員工移動時才計算
- 動態避讓：當路徑被臨時阻擋（其他角色佔位），原地等待 0.5s 後重算

---

### 2.2 AI 行為系統

#### 客人狀態機（Customer FSM）

```
[進入] → ENTERING
         ↓ 找到空桌?
    YES  ↓        NO ↓
  SEATED        WAITING_QUEUE
         ↓               ↓ 等待超過耐心值
  ORDERING       LEAVING（不滿）
         ↓
  WAITING_FOOD
         ↓ 收到餐點
     DINING
         ↓ 用餐完畢
   PAYING
         ↓
   LEAVING（滿意）
```

**狀態屬性**
```
Customer
├── patience: float          // 耐心值 0.0~1.0，隨時間遞減
├── hunger: float            // 飢餓值，影響點餐數量
├── budget: int              // 消費預算（影響點餐品項）
├── table_id: string         // 入座的桌子 ID
├── order: Order[]           // 點餐清單
├── satisfaction: float      // 滿意度，影響小費與評價
└── customer_type: string    // REGULAR | VIP | TOURIST | DRUNK（台式特色）
```

#### 員工狀態機（Staff FSM）

```
[廚師]
IDLE → COOKING → PLATING → IDLE
        ↑
     收到訂單

[外場]
IDLE → WALKING_TO_KITCHEN → CARRY_FOOD → WALKING_TO_TABLE → SERVING → IDLE
```

**路徑尋找觸發點**
- 廚師：固定在廚房格子附近，不需要頻繁尋路
- 外場：每次接任務時計算最短路徑（廚房 → 目標桌）

#### 決策優先序
1. 客人入場 → 優先分配離門口最近的空桌
2. 外場閒置 → 優先取最早完成的料理
3. 多名外場競爭同一任務 → 選擇距離最近者

---

### 2.3 事件系統

#### 架構模式：觀察者模式（Observer / Signal-Slot）

```
EventBus（全域單例）
├── emit(event_name, payload)    // 發送事件
├── subscribe(event_name, cb)    // 訂閱事件
└── unsubscribe(event_name, cb)  // 取消訂閱

事件類型
├── GAME_TICK           // 每秒觸發，驅動時間推進
├── CUSTOMER_ARRIVED    // 客人入場
├── ORDER_PLACED        // 訂單成立
├── DISH_READY          // 料理完成
├── CUSTOMER_LEFT       // 客人離開（含滿意度）
├── DAY_START           // 每日開始
├── DAY_END             // 每日結算
├── YEAR_END            // 年末結算
├── FESTIVAL_TRIGGERED  // 節日事件觸發
└── RANDOM_EVENT        // 隨機事件（媽祖繞境、漲價等）
```

#### 節日事件觸發機制

```
FestivalCalendar
├── festivals: Festival[]
└── check(current_date) → Festival | null

Festival
├── id: string           // "mid_autumn", "year_end_banquet"
├── month: int           // 觸發月份
├── day: int             // 觸發日（-1 表示整月）
├── duration_days: int   // 持續天數
├── effects: Effect[]    // 效果列表
└── is_recurring: bool   // 每年重複

Effect（效果）
├── type: string         // CUSTOMER_MULTIPLIER | PRICE_MULTIPLIER | SPECIAL_MENU
├── value: float         // 倍率或數值
└── target: string       // 套用目標（all | dish_id | customer_type）
```

#### 隨機事件機制

- 每日結算後有機率觸發隨機事件
- 事件權重受「名聲值」、「當前年份」影響
- 事件結果影響次日或當週狀態（非永久，避免雪球效應過強）

---

### 2.4 年份推進系統

```
GameClock
├── year: int            // 當前年份（從第1年開始）
├── month: int           // 1~12
├── day: int             // 1~30（簡化月份）
├── hour: float          // 營業時間（如 17.0~23.0）
├── time_scale: float    // 時間流速（可調整）
└── is_open: bool        // 是否在營業時間

tick(delta_time)         // 每幀呼叫，推進時間
```

**時間單位轉換（範例，待數值設計師確認）**
- 1 遊戲日 ≈ 實際 5 分鐘
- 1 遊戲月 ≈ 30 遊戲日
- 1 遊戲年 ≈ 12 遊戲月

**年份解鎖觸發**
- 年末結算：計算名聲、金錢、客戶滿意度是否達標
- 達標 → 播放過年動畫 → 解鎖下一年新設備/菜色/地圖擴張
- 未達標 → 提示目標未達成，繼續當年

---

### 2.5 組合加成系統

```
ComboCalculator
└── evaluate(grid_state, menu_state) → ComboResult[]

ComboRule（JSON 定義）
├── id: string               // "sanpei_master"
├── name: string             // "三杯雞大師"
├── required_dishes: string[] // ["sanpei_chicken"]
├── required_equipment: string[] // ["wok_l2"]  // 可選
├── required_staff_skill: string // 可選
├── bonus_type: string       // INCOME_MULT | FAME | CUSTOMER_ATTRACT
└── bonus_value: float

// 每次放置設備或解鎖菜色時重新計算
// 結果快取，直到格子狀態改變
```

---

## 三、資料表 JSON Schema 初稿

### 3.1 菜色表（dish.json）

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Dish",
  "type": "object",
  "required": ["id", "name_zh", "category", "base_price", "cook_time", "required_equipment"],
  "properties": {
    "id": {
      "type": "string",
      "description": "唯一識別碼",
      "example": "sanpei_chicken"
    },
    "name_zh": {
      "type": "string",
      "description": "繁體中文名稱",
      "example": "三杯雞"
    },
    "name_en": {
      "type": "string",
      "description": "英文名稱（在地化用）"
    },
    "category": {
      "type": "string",
      "enum": ["hot_stir_fry", "grill", "cold_dish", "soup", "drink", "snack"],
      "description": "熱炒|烤物|冷盤|湯品|飲料|小食"
    },
    "base_price": {
      "type": "integer",
      "description": "基礎售價（新台幣，遊戲幣）",
      "minimum": 1
    },
    "cost": {
      "type": "integer",
      "description": "食材成本"
    },
    "cook_time": {
      "type": "number",
      "description": "烹飪時間（秒，遊戲內時間）"
    },
    "required_equipment": {
      "type": "array",
      "items": { "type": "string" },
      "description": "所需設備 ID 列表",
      "example": ["wok"]
    },
    "unlock_year": {
      "type": "integer",
      "description": "解鎖年份（1 = 初始可用）",
      "default": 1
    },
    "unlock_condition": {
      "type": "string",
      "description": "解鎖條件描述（可選，空=預設解鎖）"
    },
    "fame_bonus": {
      "type": "integer",
      "description": "每次售出增加名聲值",
      "default": 0
    },
    "customer_type_attract": {
      "type": "array",
      "items": { "type": "string" },
      "description": "特別吸引的客群類型",
      "example": ["regular", "foodie"]
    },
    "tags": {
      "type": "array",
      "items": { "type": "string" },
      "description": "標籤，用於組合加成判斷",
      "example": ["chicken", "taiwanese_classic", "alcohol_pair"]
    },
    "description_zh": {
      "type": "string",
      "description": "遊戲內顯示的菜色描述文字"
    },
    "icon_id": {
      "type": "string",
      "description": "對應圖示素材 ID"
    }
  }
}
```

**範例資料**
```json
[
  {
    "id": "sanpei_chicken",
    "name_zh": "三杯雞",
    "name_en": "Three-Cup Chicken",
    "category": "hot_stir_fry",
    "base_price": 280,
    "cost": 80,
    "cook_time": 45,
    "required_equipment": ["wok"],
    "unlock_year": 1,
    "fame_bonus": 2,
    "customer_type_attract": ["regular", "family"],
    "tags": ["chicken", "taiwanese_classic", "alcohol_pair"],
    "description_zh": "台灣熱炒靈魂，一鍋端上桌，台啤必備良伴。"
  },
  {
    "id": "taiwan_beer",
    "name_zh": "台灣啤酒",
    "category": "drink",
    "base_price": 60,
    "cost": 25,
    "cook_time": 3,
    "required_equipment": ["fridge"],
    "unlock_year": 1,
    "tags": ["alcohol", "beer"],
    "description_zh": "台啤，熱炒店永遠的靈魂伴侶。"
  }
]
```

---

### 3.2 設備表（equipment.json）

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Equipment",
  "type": "object",
  "required": ["id", "name_zh", "category", "size", "cost", "unlock_year"],
  "properties": {
    "id": {
      "type": "string",
      "example": "wok"
    },
    "name_zh": {
      "type": "string",
      "example": "大炒鍋"
    },
    "category": {
      "type": "string",
      "enum": ["cooking", "storage", "seating", "decor", "service", "utility"],
      "description": "烹飪設備|儲存|座位|裝飾|服務|工具"
    },
    "size": {
      "type": "object",
      "description": "佔用格子大小",
      "properties": {
        "width": { "type": "integer" },
        "height": { "type": "integer" }
      },
      "required": ["width", "height"],
      "example": { "width": 1, "height": 1 }
    },
    "cost": {
      "type": "integer",
      "description": "購買費用"
    },
    "unlock_year": {
      "type": "integer",
      "default": 1
    },
    "upgrade_levels": {
      "type": "array",
      "description": "升級等級列表（index 0 = Lv1）",
      "items": {
        "type": "object",
        "properties": {
          "level": { "type": "integer" },
          "upgrade_cost": { "type": "integer" },
          "speed_bonus": { "type": "number", "description": "速度加成倍率" },
          "quality_bonus": { "type": "number", "description": "品質加成倍率" },
          "capacity": { "type": "integer", "description": "同時可處理訂單數" }
        }
      }
    },
    "enabled_dishes": {
      "type": "array",
      "items": { "type": "string" },
      "description": "此設備可製作的菜色 ID"
    },
    "placement_rules": {
      "type": "object",
      "properties": {
        "needs_wall": { "type": "boolean", "default": false },
        "needs_floor": { "type": "boolean", "default": true },
        "adjacent_required": { "type": "array", "items": { "type": "string" } }
      }
    },
    "fame_contribution": {
      "type": "integer",
      "description": "擺放後持續提供的名聲值加成",
      "default": 0
    },
    "sprite_id": { "type": "string" },
    "description_zh": { "type": "string" }
  }
}
```

**範例資料**
```json
[
  {
    "id": "wok",
    "name_zh": "大炒鍋",
    "category": "cooking",
    "size": { "width": 1, "height": 1 },
    "cost": 500,
    "unlock_year": 1,
    "upgrade_levels": [
      { "level": 1, "upgrade_cost": 0, "speed_bonus": 1.0, "capacity": 1 },
      { "level": 2, "upgrade_cost": 1500, "speed_bonus": 1.3, "capacity": 2 },
      { "level": 3, "upgrade_cost": 4000, "speed_bonus": 1.7, "capacity": 3 }
    ],
    "enabled_dishes": ["sanpei_chicken", "clam_stir_fry", "water_spinach"],
    "description_zh": "熱炒店的靈魂，沒有炒鍋就沒有熱炒。"
  },
  {
    "id": "plastic_table_4",
    "name_zh": "折疊桌（4人）",
    "category": "seating",
    "size": { "width": 2, "height": 2 },
    "cost": 200,
    "unlock_year": 1,
    "upgrade_levels": [
      { "level": 1, "upgrade_cost": 0, "capacity": 4 },
      { "level": 2, "upgrade_cost": 800, "capacity": 6 }
    ],
    "description_zh": "紅色塑膠折疊桌，台灣熱炒的標配。"
  }
]
```

---

### 3.3 員工表（staff.json）

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Staff",
  "type": "object",
  "required": ["id", "name_zh", "role", "hire_cost", "salary_per_day"],
  "properties": {
    "id": {
      "type": "string",
      "example": "chef_a_long"
    },
    "name_zh": {
      "type": "string",
      "example": "廚師阿龍"
    },
    "role": {
      "type": "string",
      "enum": ["chef", "waiter", "manager", "part_timer"],
      "description": "廚師|外場|老闆娘/管理|打工仔"
    },
    "hire_cost": {
      "type": "integer",
      "description": "雇用費用"
    },
    "salary_per_day": {
      "type": "integer",
      "description": "每日薪資"
    },
    "unlock_year": {
      "type": "integer",
      "default": 1
    },
    "base_stats": {
      "type": "object",
      "description": "基礎數值",
      "properties": {
        "speed": { "type": "number", "description": "工作速度 1.0 為基準" },
        "quality": { "type": "number", "description": "料理/服務品質" },
        "morale": { "type": "number", "description": "士氣，影響工作效率" },
        "capacity": { "type": "integer", "description": "同時處理任務數" }
      }
    },
    "skill_tree": {
      "type": "array",
      "description": "技能樹（可解鎖的被動加成）",
      "items": {
        "type": "object",
        "properties": {
          "skill_id": { "type": "string" },
          "name_zh": { "type": "string" },
          "unlock_cost": { "type": "integer" },
          "effect_type": { "type": "string" },
          "effect_value": { "type": "number" },
          "prerequisite_skill": { "type": "string", "description": "前置技能 ID" }
        }
      }
    },
    "specialty_dishes": {
      "type": "array",
      "items": { "type": "string" },
      "description": "擅長菜色 ID（烹飪速度額外加成）"
    },
    "personality": {
      "type": "string",
      "description": "個性標籤，影響特殊事件觸發",
      "example": "hardworking"
    },
    "sprite_id": { "type": "string" },
    "description_zh": { "type": "string" }
  }
}
```

**範例資料**
```json
[
  {
    "id": "chef_a_long",
    "name_zh": "廚師阿龍",
    "role": "chef",
    "hire_cost": 3000,
    "salary_per_day": 200,
    "unlock_year": 1,
    "base_stats": {
      "speed": 1.2,
      "quality": 1.0,
      "morale": 1.0,
      "capacity": 2
    },
    "skill_tree": [
      {
        "skill_id": "fast_wok",
        "name_zh": "快手翻炒",
        "unlock_cost": 500,
        "effect_type": "cook_speed",
        "effect_value": 0.15
      },
      {
        "skill_id": "signature_dish",
        "name_zh": "招牌料理",
        "unlock_cost": 1500,
        "effect_type": "fame_bonus",
        "effect_value": 0.20,
        "prerequisite_skill": "fast_wok"
      }
    ],
    "specialty_dishes": ["sanpei_chicken", "clam_stir_fry"],
    "personality": "passionate",
    "description_zh": "從小攤做起的老廚師，三杯雞是他的拿手絕活。"
  }
]
```

---

## 四、存檔系統設計

### 存檔策略

- **格式：** JSON（人類可讀，方便除錯）
- **存檔時機：** 每日結算後自動存檔 + 玩家手動存檔
- **版本號：** 存檔內嵌 `save_version`，升級遊戲版本時做 migration
- **備份：** 保留最近 3 份自動存檔（save_auto_1, save_auto_2, save_auto_3 輪替）

### 存檔結構

```json
{
  "save_version": "1.0.0",
  "game_id": "台灣熱炒王",
  "created_at": "2026-06-20T10:00:00",
  "last_saved": "2026-06-20T15:30:00",
  "playtime_seconds": 3600,

  "game_state": {
    "year": 2,
    "month": 8,
    "day": 15,
    "hour": 20.5,
    "money": 28500,
    "fame": 340,
    "total_customers_served": 1250
  },

  "grid_data": {
    "width": 16,
    "height": 12,
    "cells": [
      {
        "x": 3, "y": 4,
        "object_id": "wok",
        "object_level": 2,
        "object_instance_id": "wok_001"
      }
    ]
  },

  "staff_roster": [
    {
      "staff_id": "chef_a_long",
      "instance_id": "staff_001",
      "current_level": 3,
      "unlocked_skills": ["fast_wok"],
      "experience": 450
    }
  ],

  "menu_unlocked": ["sanpei_chicken", "clam_stir_fry", "taiwan_beer"],

  "combo_unlocked": ["sanpei_master"],

  "yearly_stats": [
    {
      "year": 1,
      "total_revenue": 45000,
      "total_customers": 820,
      "avg_satisfaction": 0.78,
      "goal_achieved": true
    }
  ],

  "settings": {
    "bgm_volume": 0.8,
    "sfx_volume": 1.0,
    "time_scale": 1.0,
    "language": "zh-TW"
  }
}
```

---

## 五、建議專案目錄結構

（引擎中立的邏輯分層，選定引擎後再對應實際檔案格式）

```
src\
├── core\                    # 核心遊戲邏輯（無 UI 依賴）
│   ├── game_clock.gd        # 時間推進系統
│   ├── grid_map.gd          # 格子系統
│   ├── combo_calculator.gd  # 組合加成計算
│   └── event_bus.gd         # 全域事件系統
│
├── entities\                # 遊戲實體
│   ├── customer\
│   │   ├── customer.gd      # 客人基類
│   │   ├── customer_fsm.gd  # 客人狀態機
│   │   └── customer_types\  # 各類型客人（觀光客、酒客等）
│   ├── staff\
│   │   ├── staff.gd         # 員工基類
│   │   ├── chef.gd          # 廚師
│   │   └── waiter.gd        # 外場
│   └── objects\
│       ├── equipment.gd     # 設備
│       └── table.gd         # 桌椅
│
├── systems\                 # 子系統
│   ├── pathfinding.gd       # 路徑尋找（A*）
│   ├── order_manager.gd     # 訂單管理
│   ├── economy.gd           # 金錢/收支計算
│   ├── fame_system.gd       # 名聲系統
│   ├── festival_calendar.gd # 節日行事曆
│   └── save_manager.gd      # 存讀檔
│
├── ui\                      # 介面層（與核心邏輯分離）
│   ├── hud\                 # 遊戲內 HUD（金錢、時間、名聲）
│   ├── menus\               # 主選單、設定、存檔
│   ├── build_mode\          # 建造模式 UI
│   └── panels\              # 設備詳情、員工管理等面板
│
└── data\                    # 資料讀取層
    ├── data_loader.gd       # 統一讀取 JSON 資料
    └── validators\          # 資料驗證（開發期間用）

data\                        # 靜態資料（JSON）
├── dishes.json
├── equipment.json
├── staff.json
├── combos.json
├── events.json
└── festival_calendar.json

assets\                      # 素材資源
├── sprites\
│   ├── characters\
│   ├── equipment\
│   └── tiles\
├── audio\
│   ├── bgm\
│   └── sfx\
└── ui\
```

---

## 六、待確認事項（回報給製作人）

1. **[重大] 引擎選型**：請使用者從 A/B/C 選項中確認（技術組建議：Godot 4）
2. **[重大] 目標平台**：手機 / PC / 雙平台？影響引擎優先序與解析度設計
3. **[設計組協作] 格子大小**：tile_size 需等美術規格師定案（建議 16 或 32px）
4. **[數值企劃協作] 時間流速**：1 遊戲天 = 實際幾分鐘？影響所有 cook_time 設定
5. **[設計組協作] 初始地圖大小**：格子寬高建議值（本文暫定 16x12）
