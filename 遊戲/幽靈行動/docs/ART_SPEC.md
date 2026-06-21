# 幽靈行動 — 美術規格文件（ART_SPEC）
版本：1.0｜建立：2026-06-21｜美術組長維護

---

## 一、全遊戲視覺風格指南

### 1.1 視覺定位

| 項目 | 規範 |
|------|------|
| 視角 | Isometric 斜角俯視，固定 45° 水平 + 30° 仰角 |
| 幾何風格 | 低多邊形 3D（Low-Poly），硬邊為主，不用平滑細分 |
| 光影風格 | 卡通感硬邊光，不做真實感 PBR |
| 整體氣質 | Clash of Clans 色彩活潑度 × 軍事主題沉穩度 |

### 1.2 主配色盤

| 角色 | 用途 | 色碼 | Godot Color() |
|------|------|------|--------------|
| 主色 A | 場景主體、地板、建築基底 | `#1A2B1A` 深軍綠 | `Color(0.102, 0.169, 0.102)` |
| 主色 B | 牆壁、陰影面、UI 深色背景 | `#2C2C2C` 深灰 | `Color(0.173, 0.173, 0.173)` |
| 重點色 | 大招按鈕、警示邊框、能量條 | `#E8600A` 橙色 | `Color(0.910, 0.376, 0.039)` |
| 輔助光色 | 高光面、文字、圖示輪廓 | `#F0F0F0` 近白 | `Color(0.941, 0.941, 0.941)` |
| 危險色 | 低血量警示、敵人攻擊範圍 | `#CC2222` 紅色 | `Color(0.800, 0.133, 0.133)` |
| 成功色 | 治療特效、補給獲得、關卡完成 | `#44CC44` 亮綠 | `Color(0.267, 0.800, 0.267)` |

### 1.3 像素/模型規範

| 項目 | 規格 |
|------|------|
| 場景基礎格子 | 1 unit = 1m，Isometric tile 呈現為 64px 寬 × 32px 高（菱形） |
| 角色高度 | 標準兵 1.8 unit；盾兵 2.0 unit（視覺更壯）；狙擊手/偵察手 1.7 unit（視覺更細） |
| 輪廓線 | 角色對外輪廓 2px 深色描邊（`#111111`），部件分隔線 1px |
| 多邊形密度 | 角色 300–600 tri；場景物件 100–300 tri；Boss 800–1200 tri |
| 紋理解析度 | 角色貼圖 256×256px；場景 tile 128×128px；UI 圖示 64×64px |

### 1.4 光影規則

| 項目 | 規格 |
|------|------|
| 主光源方向 | 左上方 45°（Isometric 左前上角），模擬正午陽光 |
| 光源色 | `#FFF5E0`（暖白）|
| 陰影色 | 底色乘以 `Color(0.55, 0.55, 0.65)`，帶輕微藍偏 |
| 陰影落地 | 每個角色腳下一個橢圓 Blob Shadow，半透明 40% 黑色 |
| 自發光 | 大招充能時角色識別色發光（Emission，強度 0.4）|

### 1.5 字型規範

| 層級 | 字型 | 大小 | 用途 |
|------|------|------|------|
| 標題 | Rajdhani Bold（開源，軍事感等寬） | 48px | 任務名稱、關卡標題 |
| 副標 | Rajdhani SemiBold | 28px | 職業名稱、決策選項標頭 |
| 內文 | Noto Sans TC Medium | 20px | 決策選項說明、對話文字 |
| 數字 | Rajdhani Bold | 24px | HP 數值、CD 倒數、金幣 |
| 細節 | Noto Sans TC Regular | 16px | 物品說明、輔助提示 |

---

## 二、六大職業視覺規格

### 職業識別色總表

| 職業 | 識別色名稱 | Hex | Godot Color() | 設計原則 |
|------|----------|-----|--------------|---------|
| 盾兵 | 鋼鐵藍 | `#2255BB` | `Color(0.133, 0.333, 0.733)` | 穩固、防禦感，藍色代表護盾 |
| 醫療兵 | 救護白綠 | `#22BB88` | `Color(0.133, 0.733, 0.533)` | 醫療十字，生命感 |
| 突擊手 | 火焰橙 | `#E8600A` | `Color(0.910, 0.376, 0.039)` | 攻擊性最強，使用遊戲重點色 |
| 狙擊手 | 暗紫灰 | `#7755AA` | `Color(0.467, 0.333, 0.667)` | 隱蔽、精準、神秘感 |
| 爆破手 | 警戒黃 | `#DDAA00` | `Color(0.867, 0.667, 0.000)` | 炸藥警告色，危險感 |
| 偵察手 | 夜視綠 | `#33CC55` | `Color(0.200, 0.800, 0.333)` | 夜視鏡綠光，電子感 |

六色在 Isometric 地圖上彼此對比度均 > 4.5:1（WCAG AA），確保一眼辨識。

---

### 2.1 盾兵（Tank）

**識別色：鋼鐵藍 `#2255BB`**

#### 體型定義

| 屬性 | 規格 |
|------|------|
| 體型 | 最高壯，肩寬是突擊手的 1.4 倍 |
| 高度 | 2.0 unit（全職業最高） |
| 移速視覺 | 步伐沉重，動畫每步稍微向前傾 |

#### 裝備視覺特徵

- 正面持有大型全身防彈盾牌，佔角色正面 60% 面積，盾牌面有輕微金屬刮痕紋理
- 盾牌左邊緣有鋼鐵藍橫條（識別色條紋）
- 頭戴全臉護目鋼盔，無面部露出
- 軍綠色重型胸甲，雙肩護板明顯
- 腳穿重型戰鬥靴，腳踝護甲外露
- 左手持盾，右手握短衝鋒槍貼於盾右側

#### Meshy.ai 3D 模型 Prompt

```
Isometric low-poly 3D military soldier, tank class, heavily armored, 
holding large ballistic riot shield in left hand with blue stripe marking, 
short SMG on right side, full-face tactical helmet, bulky shoulder pads, 
olive green heavy armor, wide muscular build, hard-edge geometry, 
no smooth subdivision, matte military color palette, 300-600 triangles, 
game asset ready, T-pose
```

#### Midjourney 卡牌藝術 Prompt

```
tactical military tank soldier, half-body portrait, holding massive ballistic shield 
with blue stripe, full-face combat helmet with visor, heavy olive drab plate armor, 
thick shoulder pauldrons, gritty military illustration, strong dramatic lighting 
from upper left, sharp graphic novel style, muted military colors with blue accent, 
highly detailed --ar 2:3 --style raw --v 6
```

#### HUD 卡片規格

| 項目 | 規格 |
|------|------|
| 大招卡識別圓圈色 | `#2255BB` 鋼鐵藍 |
| Godot Color() | `Color(0.133, 0.333, 0.733)` |
| 大招卡 CD 遮罩色 | `Color(0.133, 0.333, 0.733, 0.7)` 半透明 |
| 卡片左側職業色條 | 4px 寬，高度佔卡片 100% |

---

### 2.2 醫療兵（Medic）

**識別色：救護白綠 `#22BB88`**

#### 體型定義

| 屬性 | 規格 |
|------|------|
| 體型 | 中等偏細，無重型護甲，輕便感 |
| 高度 | 1.8 unit（標準） |
| 移速視覺 | 動作謹慎，動畫中有低頭觀察隊友的姿態 |

#### 裝備視覺特徵

- 左臂白色臂章，印有綠色十字（最重要的識別標誌）
- 背部背大型急救背包，白色十字標記，包頂有天線
- 輕型防彈背心，軍綠色，無重型板甲
- 頭戴輕型軍帽，無護目鏡（醫療兵不需偽裝）
- 腰帶掛注射器、醫療包等工具，側面輪廓能看到
- 手持輕型手槍（非主要攻擊，代表「有自衛能力但非戰鬥者」）

#### Meshy.ai 3D 模型 Prompt

```
Isometric low-poly 3D military medic soldier, medium slim build, 
white red-cross armband on left arm, large medical backpack with cross symbol, 
light tactical vest olive green, soft cap helmet, medical pouches on belt, 
holding pistol, no heavy weapon, caring posture, hard-edge low-poly geometry, 
300-500 triangles, game asset T-pose
```

#### Midjourney 卡牌藝術 Prompt

```
military field medic, half-body portrait, white armband with green cross prominent, 
large medical pack on back, light olive tactical vest, soft military cap, 
medical supplies on belt, holding pistol, warm determined expression, 
medical emergency lighting, clean graphic illustration style, 
teal-green accent color, detailed character art --ar 2:3 --style raw --v 6
```

#### HUD 卡片規格

| 項目 | 規格 |
|------|------|
| 大招卡識別圓圈色 | `#22BB88` 救護白綠 |
| Godot Color() | `Color(0.133, 0.733, 0.533)` |
| 大招卡 CD 遮罩色 | `Color(0.133, 0.733, 0.533, 0.7)` |
| 卡片左側職業色條 | 4px 寬，高度佔卡片 100% |

---

### 2.3 突擊手（Assault）

**識別色：火焰橙 `#E8600A`（=遊戲重點色）**

#### 體型定義

| 屬性 | 規格 |
|------|------|
| 體型 | 標準軍人體型，肌肉感但靈活 |
| 高度 | 1.8 unit（標準） |
| 移速視覺 | 動畫有前傾衝刺感，步伐最輕快 |

#### 裝備視覺特徵

- 手持全尺寸突擊步槍（AK/M4 混合輪廓），槍身有橙色護木（識別色元素）
- 標準戰術背心，軍綠 + 多口袋，彈匣袋明顯
- 頭戴戰術頭盔 + 護目鏡抬起（非偽裝用途）
- 腰帶掛額外彈匣，視覺上「彈藥充足」
- 無盾無特殊大型裝備，強調機動性
- 膝蓋護具，戰術褲有口袋

#### Meshy.ai 3D 模型 Prompt

```
Isometric low-poly 3D military assault soldier, standard athletic build, 
holding assault rifle with orange foregrip marking, tactical chest rig 
with magazine pouches, combat helmet with goggles up, knee pads, 
combat boots, orange accent details on gear, aggressive forward-lean posture, 
hard-edge geometry, matte olive drab primary color, 300-600 triangles, game asset T-pose
```

#### Midjourney 卡牌藝術 Prompt

```
elite military assault trooper, half-body portrait, gripping assault rifle ready to fire, 
tactical plate carrier with orange accent stripe, combat helmet goggles raised, 
multiple magazine pouches, intense focused expression, dynamic shooting stance, 
dramatic orange-tinted action lighting, gritty military comic art style, 
high contrast orange highlight on weapon --ar 2:3 --style raw --v 6
```

#### HUD 卡片規格

| 項目 | 規格 |
|------|------|
| 大招卡識別圓圈色 | `#E8600A` 火焰橙 |
| Godot Color() | `Color(0.910, 0.376, 0.039)` |
| 大招卡 CD 遮罩色 | `Color(0.910, 0.376, 0.039, 0.7)` |
| 卡片左側職業色條 | 4px 寬，高度佔卡片 100% |

---

### 2.4 狙擊手（Sniper）

**識別色：暗紫灰 `#7755AA`**

#### 體型定義

| 屬性 | 規格 |
|------|------|
| 體型 | 最纖細，無重型護甲，修長輪廓 |
| 高度 | 1.7 unit（視覺最細長） |
| 移速視覺 | 動畫緩慢謹慎，有俯臥/跪姿狀態 |

#### 裝備視覺特徵

- 手持長槍（狙擊步槍輪廓，槍管明顯超過其他職業槍管長度 1.5 倍）
- 身穿偽裝披風（Ghillie 毛髮型），覆蓋頭部與背部，草綠色混深色
- 披風內可見輕型戰術背心
- 頭部偽裝覆蓋，只露出瞄準鏡面部特寫時才看到眼睛
- 腰部掛著少量彈藥，強調精準不強調火力
- 披風帽簷有紫色識別色絲帶（細節識別）

#### Meshy.ai 3D 模型 Prompt

```
Isometric low-poly 3D military sniper soldier, slender tall build, 
holding long sniper rifle with prominent barrel, wearing ghillie cape 
covering head and back in green-brown camouflage, light tactical vest underneath, 
minimal pouches, purple ribbon accent on hood, crouching ready stance, 
hard-edge low-poly geometry, 300-550 triangles, game asset T-pose
```

#### Midjourney 卡牌藝術 Prompt

```
military sniper operator, half-body portrait, long sniper rifle held at ready, 
full ghillie suit draped over shoulders and head, camouflage face paint, 
piercing eyes visible through ghillie hood, light vest underneath, 
cool purple-gray color palette, dramatic shadow from upper left, 
patient deadly expression, sharp military illustration style, 
purple accent in equipment detail --ar 2:3 --style raw --v 6
```

#### HUD 卡片規格

| 項目 | 規格 |
|------|------|
| 大招卡識別圓圈色 | `#7755AA` 暗紫灰 |
| Godot Color() | `Color(0.467, 0.333, 0.667)` |
| 大招卡 CD 遮罩色 | `Color(0.467, 0.333, 0.667, 0.7)` |
| 卡片左側職業色條 | 4px 寬，高度佔卡片 100% |

---

### 2.5 爆破手（Demolitions）

**識別色：警戒黃 `#DDAA00`**

#### 體型定義

| 屬性 | 規格 |
|------|------|
| 體型 | 中壯，背部因炸藥背包而視覺最寬 |
| 高度 | 1.85 unit（略高於標準） |
| 移速視覺 | 步伐穩重，背包讓重心偏後 |

#### 裝備視覺特徵

- 背部超大炸藥背包，有黃黑警告條紋（識別色 + 安全標誌）
- 頭戴護目鏡（最重要識別：護目鏡正面鏡片為黃色反光）
- 戴厚重工作手套，手臂有防火護臂
- 腰帶掛多個炸藥包（黑色圓柱形，帶引線）
- 標準戰術背心，比醫療兵更厚
- 短管霰彈槍（強調近距離爆發）

#### Meshy.ai 3D 模型 Prompt

```
Isometric low-poly 3D military demolitions soldier, stocky medium build, 
massive explosive backpack with yellow-black hazard stripes, 
yellow-tinted blast goggles on face, thick work gloves, 
fireproof arm guards, multiple explosive charges on belt, 
short-barrel shotgun, tactical vest, hard-edge low-poly geometry, 
warning yellow accent color, 350-600 triangles, game asset T-pose
```

#### Midjourney 卡牌藝術 Prompt

```
military demolitions expert, half-body portrait, massive explosive backpack 
with hazard stripes visible, yellow blast goggles prominent on face, 
thick armored gloves, explosive charges clipped to belt, shotgun in hand, 
intense explosive expert expression, yellow warning color palette accent, 
dramatic industrial lighting, gritty military comic illustration style, 
high contrast yellow and dark military colors --ar 2:3 --style raw --v 6
```

#### HUD 卡片規格

| 項目 | 規格 |
|------|------|
| 大招卡識別圓圈色 | `#DDAA00` 警戒黃 |
| Godot Color() | `Color(0.867, 0.667, 0.000)` |
| 大招卡 CD 遮罩色 | `Color(0.867, 0.667, 0.000, 0.7)` |
| 卡片左側職業色條 | 4px 寬，高度佔卡片 100% |

---

### 2.6 偵察手（Recon）

**識別色：夜視綠 `#33CC55`**

#### 體型定義

| 屬性 | 規格 |
|------|------|
| 體型 | 最輕裝，最纖細，視覺上最「小」 |
| 高度 | 1.7 unit（與狙擊手同高，但更纖細） |
| 移速視覺 | 動畫輕盈靈巧，有貓步感 |

#### 裝備視覺特徵

- 頭戴夜視鏡頭盔（最重要識別：鏡頭向前突出，閒置時鏡頭折起呈 T 字形）
- 肩部掛偵察鏡/單眼望遠鏡（右肩）
- 輕型戰術背心，口袋比其他職業少
- 小型精實背包，比爆破手背包小 3 倍
- 緊身戰術褲，方便移動
- 腰掛手槍 + 煙霧彈（圓形物件），無長槍
- 夜視鏡頭的鏡片有綠色自發光效果（識別色來源）

#### Meshy.ai 3D 模型 Prompt

```
Isometric low-poly 3D military recon soldier, slender light build, 
NVG night vision goggles mounted on helmet with green-tinted lenses, 
monocular scope on right shoulder, compact light tactical vest, 
small backpack, pistol on hip, smoke grenades on belt, 
no heavy weapon, agile crouching ready stance, 
green glowing accent on NVG lenses, hard-edge low-poly geometry, 
250-450 triangles, game asset T-pose
```

#### Midjourney 卡牌藝術 Prompt

```
military recon operator, half-body portrait, night vision goggles with green glow 
on helmet, monocular scope clipped to shoulder, minimal lightweight tactical vest, 
compact small backpack, pistol and smoke grenades on belt, 
no primary weapon, agile alert expression, dark environment with green NVG glow, 
stealth night operation atmosphere, cool military illustration style, 
neon green accent on NVG lenses against dark background --ar 2:3 --style raw --v 6
```

#### HUD 卡片規格

| 項目 | 規格 |
|------|------|
| 大招卡識別圓圈色 | `#33CC55` 夜視綠 |
| Godot Color() | `Color(0.200, 0.800, 0.333)` |
| 大招卡 CD 遮罩色 | `Color(0.200, 0.800, 0.333, 0.7)` |
| 卡片左側職業色條 | 4px 寬，高度佔卡片 100% |

---

## 三、敵人視覺規格

### 3.1 敵人識別層級系統

敵人不使用職業識別色，改用**等級階層色**：

| 等級 | 識別色 | Hex | 視覺差異 |
|------|--------|-----|---------|
| 普通兵 | 泥土灰 | `#88776655` | 最基礎輪廓，無特殊裝備 |
| 精英兵 | 深紅 | `#AA1111` | 頭盔紅色標記、護甲更厚 |
| Boss | 黑金 | `#110000` 底色 + `#FFBB00` 描邊 | 體型最大，金色發光輪廓 |

血條顏色同步：
- 普通兵血條：`#DD4444` 紅色
- 精英兵血條：`#AA1111` 深紅
- Boss 血條：`#FFBB00` 金色，位於畫面上方獨立大血條

### 3.2 普通兵視覺規格

| 屬性 | 規格 |
|------|------|
| 體型 | 標準，比玩家職業稍矮（1.6 unit），強調可被輕鬆擊敗的感覺 |
| 裝備 | 輕型頭盔、基礎背心、AK 輪廓步槍 |
| 顏色 | 深灰棕配色（`#554433`），無識別特徵 |
| 多邊形 | 200–300 tri，比玩家職業細節少 |

#### Meshy.ai Prompt（普通兵）

```
Isometric low-poly 3D enemy soldier, standard build slightly shorter than player, 
simple light helmet, basic bulletproof vest dark brown-gray color, 
AK-pattern assault rifle, no special markings, generic military appearance, 
hard-edge low-poly geometry, 200-300 triangles, game asset T-pose
```

### 3.3 精英兵視覺規格

| 屬性 | 規格 |
|------|------|
| 體型 | 略高壯（1.8 unit），護甲明顯更厚 |
| 裝備 | 全臉頭盔（頭盔有紅色識別標記）、重型胸甲、重型武器（機槍輪廓） |
| 顏色 | 黑色護甲為主（`#1A1A1A`），頭盔紅色斑紋（`#AA1111`） |
| 多邊形 | 400–550 tri |

#### Meshy.ai Prompt（精英兵）

```
Isometric low-poly 3D elite enemy soldier, bulkier taller build, 
full-face black combat helmet with red stripe marking, heavy black plate armor, 
light machine gun or heavy rifle, reinforced shoulder guards, 
intimidating stance, dark black primary with red accent, 
hard-edge geometry, 400-550 triangles, game asset T-pose
```

### 3.4 Boss 視覺規格

| 屬性 | 規格 |
|------|------|
| 體型 | 最大（2.2 unit），佔 2×2 格子，存在感強 |
| 裝備 | 重型外骨骼護甲輪廓、雙持武器、背部有指揮天線 |
| 顏色 | 全黑護甲（`#111111`）+ 金色自發光邊框（`#FFBB00`） |
| 特效 | 每 10 秒閃一次金色脈衝 Emission |
| 多邊形 | 800–1200 tri |

#### Meshy.ai Prompt（Boss）

```
Isometric low-poly 3D enemy boss commander, massive imposing build 2x height of normal soldier, 
heavy exo-armor black plates, dual-wielding heavy weapons, command antenna on back, 
gold glowing edge trim on all armor panels, ominous dark black primary color 
with bright gold accent emission, dramatic commanding stance, 
hard-edge geometry, 800-1200 triangles, game asset
```

---

## 四、環境物件視覺規格

### 4.1 互動物件識別色規範

互動物件用**外框發光色**區別類型（玩家接近時顯示）：

| 物件類型 | 靜態顏色 | 接近高光色 | Hex |
|---------|---------|----------|-----|
| 普通門（木） | 棕色 `#7A5C3A` | 白色 `#FFFFFF` | 高光 `#FFFFFF` |
| 加固門（鐵） | 深灰 `#4A4A4A` | 橙色 `#E8600A` | 高光 `#E8600A` |
| 普通箱子 | 軍綠 `#3A5A3A` | 白色 `#FFFFFF` | 高光 `#FFFFFF` |
| 補給箱 | 深橄欖綠 + 白十字 | 綠色 `#44CC44` | 高光 `#44CC44` |
| 炸藥桶 | 紅色 `#AA2222` + 黃色警告條 | 紅色脈衝 `#FF4444` | 高光 `#FF4444` |
| 掩體（木牆） | 原木色 `#8B6543` | 白色 `#FFFFFF` | 高光 `#FFFFFF` |

### 4.2 門（普通木門）

| 規格項目 | 內容 |
|---------|------|
| 尺寸 | 1×1 unit，Isometric 顯示為菱形 + 垂直門板 |
| 材質感 | 粗糙木頭，有木紋線條（2–3 條橫線代表木板縫） |
| 顏色 | 主體 `#7A5C3A` 棕，邊框 `#4A3020` 深棕 |
| 狀態 | 關閉（默認）/ 打開（旋轉 90°，淡出 0.3 秒） |

#### Meshy.ai Prompt

```
Isometric low-poly 3D wooden door, military base interior style, 
rough wood planks with metal hinges, dark brown color, 
closed upright position, hard-edge geometry, 100-200 triangles, 
game prop asset
```

### 4.3 門（加固鐵門）

| 規格項目 | 內容 |
|---------|------|
| 尺寸 | 1×1 unit，比木門厚 2 倍 |
| 材質感 | 金屬板，有鉚釘細節（4 角各一個圓點） |
| 顏色 | 主體 `#4A4A4A` 深灰，鉚釘 `#888888` 亮灰 |
| 狀態 | 需要炸藥/盾撞才能打開 |
| 視覺提示 | 門上有橙色警告標誌（三角形驚嘆號），提示特殊條件 |

#### Meshy.ai Prompt

```
Isometric low-poly 3D reinforced metal blast door, military bunker style, 
thick steel plates with rivets at corners, dark gray color, 
orange warning triangle decal on surface, heavy industrial look, 
hard-edge low-poly geometry, 150-250 triangles, game prop asset
```

### 4.4 普通箱子（木箱）

| 規格項目 | 內容 |
|---------|------|
| 尺寸 | 0.5×0.5×0.5 unit |
| 材質感 | 木板箱，4 角有金屬角扣 |
| 顏色 | `#7A6040` 深棕木色，角扣 `#888888` |
| 用途 | 場景點綴 + 提供掩體 |

### 4.5 補給箱（軍用綠箱）

| 規格項目 | 內容 |
|---------|------|
| 尺寸 | 0.6×0.6×0.5 unit（比普通箱稍大） |
| 材質感 | 金屬軍用彈藥箱質感，頂部有扣環 |
| 顏色 | 主體 `#2A4A2A` 深軍綠，正面白色醫療十字 |
| 視覺提示 | 靜態時頂部有微弱綠光（Emission 0.2），表示可互動 |
| 打開狀態 | 箱蓋翻起 90°，內部有金光粒子效果 |

#### Meshy.ai Prompt

```
Isometric low-poly 3D military supply crate, metal ammo box style, 
deep olive green color, white medical cross on front panel, 
metal clasps and handle on top, slight green emission glow, 
hard-edge low-poly geometry, 100-200 triangles, closed lid, game prop asset
```

### 4.6 炸藥桶

| 規格項目 | 內容 |
|---------|------|
| 尺寸 | 0.4×0.4×0.8 unit（圓柱形） |
| 材質感 | 金屬油桶，有橫向焊接線 |
| 顏色 | 主體 `#AA2222` 紅色，黃黑警告條紋環繞中段 |
| 視覺提示 | 有紅色脈衝 Emission（每 2 秒一次，提醒危險） |
| 爆炸觸發 | 爆破手靠近時橘色高光，引爆後爆炸特效 |

---

## 五、地板與牆壁 Isometric Tile 規格

### 5.1 Tile 系統基礎

| 規格項目 | 內容 |
|---------|------|
| 基礎 Tile 形狀 | Isometric 菱形：64px 寬 × 32px 高 |
| 世界座標 | 1 tile = 1m × 1m |
| 牆壁高度 | 2.5 unit（3 tile 高） |
| Tile 貼圖解析度 | 128×128px（縮放至 64×32 顯示） |

### 5.2 地板 Tile 種類

| Tile 名稱 | 用途 | 顏色 | 視覺特徵 |
|----------|------|------|---------|
| 混凝土地板 | 室內標準地板 | `#3A3A3A` 深灰 | 有輕微龜裂紋，均勻分布 |
| 金屬格板 | 特殊區域、Boss 房 | `#2A2A2A` 深黑 + `#555555` 格線 | 金屬格子圖案，有光澤感 |
| 泥土地面 | 室外地圖 | `#5A4A30` 泥棕 | 有腳印紋路，不均勻邊緣 |
| 草地 | 室外自然區 | `#2A5A2A` 深草綠 | 有隨機草葉散點 |

#### 混凝土地板 Tile Prompt（Meshy.ai/Midjourney）

```
Isometric tile texture, concrete floor military base, dark gray #3A3A3A, 
subtle crack pattern, low-poly flat tile, 64x32 pixel isometric diamond shape, 
top-down view, seamless tiling
```

### 5.3 牆壁 Tile 種類

牆壁由「垂直面」組成，Isometric 中分為**左牆面**與**右牆面**兩種，光影不同：

| 牆面 | 光影規則 | 顏色 |
|------|---------|------|
| 左牆面（受光面） | 主光源照射，較亮 | `#4A5A4A` 偏亮軍綠 |
| 右牆面（陰影面） | 背光面，較暗 | `#2A3A2A` 偏暗軍綠 |
| 牆頂面（頂部） | 不顯示（上面是天花板） | N/A |

#### 牆壁視覺特徵

- 混凝土牆：有水平磚縫線（每 0.5 unit 一條），輕微汙漬
- 金屬牆（Boss 房）：鋼板拼接感，有鉚釘
- 破損牆：局部缺角，露出內部深色，配合爆破手技能效果

#### Meshy.ai 牆壁 Prompt

```
Isometric low-poly 3D wall segment, military concrete wall, 
left face lit olive green #4A5A4A, right face shadowed dark green #2A3A2A, 
horizontal brick joint lines every 0.5 unit, slight wear and grime, 
hard-edge geometry, seamlessly repeatable wall tile, game environment asset
```

### 5.4 Tile 擺放規範

| 規範項目 | 內容 |
|---------|------|
| 房間最小尺寸 | 4×4 tiles |
| 走廊寬度 | 2 tiles（確保 4 角色隊伍可以並排） |
| 牆壁厚度 | 1 tile（單層） |
| 房間高度（天花板） | 統一 3 tiles 高 |
| 地板/牆壁接縫 | 牆壁 Tile 下邊與地板 Tile 上邊對齊，無縫隙 |

---

## 六、HUD 卡片視覺規格總覽

### 6.1 大招卡尺寸與佈局

底部 HUD 顯示 4 張選出的角色大招卡（從 6 個職業選 4 人）。

| 規格項目 | 內容 |
|---------|------|
| 卡片尺寸 | 120×80px（手機橫屏） |
| 職業色條 | 卡片左側 4px 寬色條，高度 100% |
| 識別圓圈 | 卡片右上角，直徑 24px 實心圓，填充職業識別色 |
| 角色名縮寫 | 卡片中間上方，白色 Rajdhani Bold 16px |
| HP 百分比 | 縮寫下方，數字 + 細長血條（寬度 80px，高 6px） |
| CD 遮罩 | 大招冷卻中時，卡片上方覆蓋半透明職業色遮罩（Alpha 0.7）|
| 可點擊狀態 | 遮罩消失，職業色邊框脈衝閃爍（0.5 秒一次） |

### 6.2 六職業識別色快速參考

| 職業 | 識別色 | Hex | Godot Color() |
|------|--------|-----|--------------|
| 盾兵 | 鋼鐵藍 | `#2255BB` | `Color(0.133, 0.333, 0.733)` |
| 醫療兵 | 救護白綠 | `#22BB88` | `Color(0.133, 0.733, 0.533)` |
| 突擊手 | 火焰橙 | `#E8600A` | `Color(0.910, 0.376, 0.039)` |
| 狙擊手 | 暗紫灰 | `#7755AA` | `Color(0.467, 0.333, 0.667)` |
| 爆破手 | 警戒黃 | `#DDAA00` | `Color(0.867, 0.667, 0.000)` |
| 偵察手 | 夜視綠 | `#33CC55` | `Color(0.200, 0.800, 0.333)` |

---

## 七、素材生成工作流程

### 7.1 3D 角色（Meshy.ai）

1. 使用本文各職業的 Meshy.ai Prompt 生成基礎 Mesh
2. 匯出 `.glb` 格式
3. 在 Godot 4 以 `AnimationPlayer` 設定以下動畫狀態：
   - `idle`：靜止呼吸循環（12 幀）
   - `walk`：行走循環（8 幀）
   - `attack`：攻擊動作（6 幀）
   - `skill`：大招施放（10 幀，帶識別色發光 Emission 效果）
   - `hurt`：受傷後仰（4 幀）
   - `die`：倒下（8 幀，最終靜止在地）
4. 各角色在 `skill` 動畫期間施放識別色粒子效果（對應 Emission 色）

### 7.2 卡牌插畫（Midjourney）

1. 使用本文各職業的 Midjourney Prompt 生成
2. 目標尺寸：512×768px（2:3 比例）
3. 裁切為卡牌 art 區域（上 80%），下 20% 為 HUD 資訊區
4. 套用統一 UI 框架（深色背景 + 識別色邊框）

### 7.3 優先生成順序

| 優先度 | 素材 | 理由 |
|--------|------|------|
| P0 | 突擊手 3D 模型 | MVP 起始職業 |
| P0 | 盾兵 3D 模型 | MVP 起始職業 |
| P0 | 普通兵 3D 模型 | MVP 需要敵人 |
| P0 | 混凝土地板/牆壁 Tile | MVP 場景 |
| P1 | 醫療兵 / 狙擊手 3D 模型 | MVP 次要職業 |
| P1 | 補給箱 / 木門 物件 | MVP 互動物件 |
| P1 | 爆破手 / 偵察手 3D 模型 | 完整版職業 |
| P2 | 全職業卡牌插畫（Midjourney） | 抽卡系統上線前 |
| P2 | 加固門 / 炸藥桶 / Boss 模型 | 進階關卡 |

---

*ART_SPEC v1.0 — 美術組長審核完成*
*下次更新：MVP 視覺驗收後，根據實際生成結果修訂 Prompt*
