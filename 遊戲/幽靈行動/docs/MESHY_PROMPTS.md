# 幽靈行動 — Meshy.ai 3D 模型生成 Prompt 清單
版本：1.0｜建立：2026-06-21｜美術組長出品

---

## 免費方案額度分配（每月 8 個）

Meshy.ai 免費方案每月限 8 次 Text-to-3D 生成。建議本月優先生成以下 8 個：

| 順序 | 模型 | 理由 |
|------|------|------|
| 1 | 突擊手 | Demo 主角，最有存在感 |
| 2 | 盾兵 | 視覺最突出，正面壓迫感強 |
| 3 | 普通敵人 | 沒有敵人就沒有遊戲 |
| 4 | 地板 tile | 場景最基礎底層，其他物件都站在上面 |
| 5 | 醫療兵 | Demo 前補完玩家隊伍 |
| 6 | 狙擊手 | Demo 前補完玩家隊伍 |
| 7 | 牆壁 tile | 有地板就需要牆壁 |
| 8 | 補給箱 | 互動道具，關卡節奏關鍵 |

剩餘模型（爆破手、偵察手、精英敵人、Boss）留待 Demo 後用下一個月額度。

---

## GLB 匯入 Godot 4 步驟

1. 將 `.glb` 檔案直接拖入 Godot 4 的 FileSystem 面板，Godot 會自動辨識並匯入。
2. 在 Import 面板選 `Scene`，勾選 `Generate LODs`（角色）或保持預設（Props），點 Reimport。
3. 將匯入後的場景拖入主場景，在 Node 的 `Transform` 設定 `Scale` 為下方各模型指定值。

---

## 第一批（今天就要生成）

---

### 1. 突擊手（Assault）

**識別色：火焰橙 `#E8600A`**

**Meshy.ai Prompt（直接複製）：**
```
Isometric low-poly 3D military assault soldier, standard athletic build, holding assault rifle with orange foregrip marking, tactical chest rig with magazine pouches, combat helmet with goggles up, knee pads, combat boots, orange accent details on gear, aggressive forward-lean posture, hard-edge geometry, matte olive drab primary color, 300-600 triangles, game asset T-pose
```

| 規格項目 | 內容 |
|---------|------|
| 高度/寬度比例 | 高 1.8 unit / 寬 0.6 unit（相對 1 tile = 1 unit） |
| 多邊形目標 | 300–600 tri |
| 貼圖解析度 | 256×256px |
| 存放路徑 | `src/assets/characters/assault/assault_base.glb` |
| Godot 縮放 | `Scale = Vector3(0.9, 0.9, 0.9)`（調整至視覺高度約佔 tile 的 1.8 倍） |

---

### 2. 盾兵（Tank）

**識別色：鋼鐵藍 `#2255BB`**

**Meshy.ai Prompt（直接複製）：**
```
Isometric low-poly 3D military soldier, tank class, heavily armored, holding large ballistic riot shield in left hand with blue stripe marking, short SMG on right side, full-face tactical helmet, bulky shoulder pads, olive green heavy armor, wide muscular build, hard-edge geometry, no smooth subdivision, matte military color palette, 300-600 triangles, game asset T-pose
```

| 規格項目 | 內容 |
|---------|------|
| 高度/寬度比例 | 高 2.0 unit / 寬 0.85 unit（最寬的角色，肩寬是突擊手 1.4 倍） |
| 多邊形目標 | 300–600 tri |
| 貼圖解析度 | 256×256px |
| 存放路徑 | `src/assets/characters/tank/tank_base.glb` |
| Godot 縮放 | `Scale = Vector3(1.0, 1.0, 1.0)`（盾兵是全場最高，作為縮放基準 1.0） |

---

### 3. 普通敵人（Enemy Soldier）

**識別色：泥土灰 `#887766`**

**Meshy.ai Prompt（直接複製）：**
```
Isometric low-poly 3D enemy soldier, standard build slightly shorter than player characters, simple light helmet, basic bulletproof vest dark brown-gray color #554433, AK-pattern assault rifle, no special markings, no bright accent colors, generic nameless military appearance, slightly hunched posture, hard-edge low-poly geometry, 200-300 triangles, game asset T-pose
```

| 規格項目 | 內容 |
|---------|------|
| 高度/寬度比例 | 高 1.6 unit / 寬 0.55 unit（比玩家職業矮，強調「可輕鬆擊敗」感） |
| 多邊形目標 | 200–300 tri（比玩家角色細節少） |
| 貼圖解析度 | 256×256px |
| 存放路徑 | `src/assets/characters/enemies/enemy_soldier_base.glb` |
| Godot 縮放 | `Scale = Vector3(0.8, 0.8, 0.8)`（視覺略矮於突擊手） |

---

### 4. 地板 Tile（混凝土地板）

**底色：深灰 `#3A3A3A`**

**Meshy.ai Prompt（直接複製）：**
```
Isometric low-poly 3D floor tile, military base concrete floor, flat diamond-shaped top surface, dark gray color #3A3A3A, subtle crack lines on surface, hard-edge geometry, seamlessly tileable, viewed from isometric 45 degree angle, no walls no raised edges, 50-100 triangles, game environment tile asset
```

| 規格項目 | 內容 |
|---------|------|
| 尺寸比例 | 1 unit × 1 unit 正方形，Isometric 顯示為 64px 寬 × 32px 高菱形 |
| 厚度 | 0.1 unit（極薄，只是地面底層） |
| 多邊形目標 | 50–100 tri |
| 貼圖解析度 | 128×128px |
| 存放路徑 | `src/assets/environment/tiles/floor_concrete.glb` |
| Godot 縮放 | `Scale = Vector3(1.0, 1.0, 1.0)`（tile 基準單位，不縮放） |

---

## 第二批（Demo 前生成）

---

### 5. 醫療兵（Medic）

**識別色：救護白綠 `#22BB88`**

**Meshy.ai Prompt（直接複製）：**
```
Isometric low-poly 3D military medic soldier, medium slim build, white red-cross armband on left arm, large medical backpack with white cross symbol on back, light tactical vest olive green, soft military cap helmet, medical pouches on belt, holding pistol in right hand, no heavy weapon, caring attentive posture, hard-edge low-poly geometry, 300-500 triangles, game asset T-pose
```

| 規格項目 | 內容 |
|---------|------|
| 高度/寬度比例 | 高 1.8 unit / 寬 0.6 unit |
| 多邊形目標 | 300–500 tri |
| 貼圖解析度 | 256×256px |
| 存放路徑 | `src/assets/characters/medic/medic_base.glb` |
| Godot 縮放 | `Scale = Vector3(0.9, 0.9, 0.9)` |

---

### 6. 狙擊手（Sniper）

**識別色：暗紫灰 `#7755AA`**

**Meshy.ai Prompt（直接複製）：**
```
Isometric low-poly 3D military sniper soldier, slender tall build, holding long sniper rifle with prominent barrel extending beyond other soldiers, wearing ghillie cape covering head and back in green-brown camouflage, light tactical vest visible underneath, minimal ammunition pouches, small purple ribbon accent on ghillie hood, upright ready stance, hard-edge low-poly geometry, 300-550 triangles, game asset T-pose
```

| 規格項目 | 內容 |
|---------|------|
| 高度/寬度比例 | 高 1.7 unit / 寬 0.5 unit（最細長的輪廓） |
| 多邊形目標 | 300–550 tri |
| 貼圖解析度 | 256×256px |
| 存放路徑 | `src/assets/characters/sniper/sniper_base.glb` |
| Godot 縮放 | `Scale = Vector3(0.85, 0.85, 0.85)` |

---

### 7. 牆壁 Tile（混凝土牆）

**亮面：`#4A5A4A` / 暗面：`#2A3A2A`**

**Meshy.ai Prompt（直接複製）：**
```
Isometric low-poly 3D wall segment, military concrete wall block, left face lit olive green #4A5A4A, right face shadowed dark green #2A3A2A, horizontal brick joint lines every half unit height, slight wear texture and grime marks, upright rectangular block shape, hard-edge geometry, seamlessly repeatable in a grid, 100-200 triangles, game environment wall tile asset
```

| 規格項目 | 內容 |
|---------|------|
| 尺寸比例 | 1 unit 寬 × 2.5 unit 高 × 0.2 unit 厚 |
| 多邊形目標 | 100–200 tri |
| 貼圖解析度 | 128×128px |
| 存放路徑 | `src/assets/environment/tiles/wall_concrete.glb` |
| Godot 縮放 | `Scale = Vector3(1.0, 1.0, 1.0)`（牆壁基準不縮放） |

備註：Isometric 中牆壁分左右兩面，Meshy 生成後若只有一面，在 Godot 複製並鏡射 X 軸即可產生右牆面。

---

### 8. 補給箱（Supply Crate）

**主色：深軍綠 `#2A4A2A`，識別白色十字**

**Meshy.ai Prompt（直接複製）：**
```
Isometric low-poly 3D military supply crate, metal ammo box style, deep olive green color #2A4A2A, white medical cross symbol centered on front panel, metal clasps and carry handle on top lid, rectangular box shape slightly wider than tall, closed lid position, subtle green emission glow on edges, hard-edge low-poly geometry, 100-200 triangles, game prop asset
```

| 規格項目 | 內容 |
|---------|------|
| 尺寸比例 | 高 0.5 unit / 寬 0.6 unit / 深 0.6 unit |
| 多邊形目標 | 100–200 tri |
| 貼圖解析度 | 128×128px |
| 存放路徑 | `src/assets/environment/props/supply_crate.glb` |
| Godot 縮放 | `Scale = Vector3(0.6, 0.6, 0.6)`（比角色小，放在地上作為 Props） |

---

## 第三批（Demo 後）

---

### 9. 爆破手（Demolitions）

**識別色：警戒黃 `#DDAA00`**

**Meshy.ai Prompt（直接複製）：**
```
Isometric low-poly 3D military demolitions soldier, stocky medium build, massive explosive backpack with yellow-black hazard stripes on back, yellow-tinted blast goggles on face, thick work gloves, fireproof arm guards on forearms, multiple cylindrical explosive charges clipped on belt, short-barrel shotgun in hands, tactical vest, hard-edge low-poly geometry, warning yellow accent color, 350-600 triangles, game asset T-pose
```

| 規格項目 | 內容 |
|---------|------|
| 高度/寬度比例 | 高 1.85 unit / 寬 0.75 unit（因爆炸背包視覺最寬） |
| 多邊形目標 | 350–600 tri |
| 貼圖解析度 | 256×256px |
| 存放路徑 | `src/assets/characters/demo/demo_base.glb` |
| Godot 縮放 | `Scale = Vector3(0.92, 0.92, 0.92)` |

---

### 10. 偵察手（Recon）

**識別色：夜視綠 `#33CC55`**

**Meshy.ai Prompt（直接複製）：**
```
Isometric low-poly 3D military recon soldier, slender light build, NVG night vision goggles with green-tinted lenses mounted on helmet projecting forward, monocular scope clipped on right shoulder strap, compact light tactical vest with minimal pouches, small backpack, pistol holstered on hip, smoke grenades on belt, no primary rifle, agile upright ready stance, green glowing accent on NVG lenses, hard-edge low-poly geometry, 250-450 triangles, game asset T-pose
```

| 規格項目 | 內容 |
|---------|------|
| 高度/寬度比例 | 高 1.7 unit / 寬 0.5 unit（與狙擊手同高但更纖細） |
| 多邊形目標 | 250–450 tri |
| 貼圖解析度 | 256×256px |
| 存放路徑 | `src/assets/characters/recon/recon_base.glb` |
| Godot 縮放 | `Scale = Vector3(0.85, 0.85, 0.85)` |

---

### 11. 精英敵人（Elite Enemy Soldier）

**識別色：深紅 `#AA1111`**

**Meshy.ai Prompt（直接複製）：**
```
Isometric low-poly 3D elite enemy soldier, bulkier taller build than standard enemy, full-face black combat helmet with red stripe marking on top, heavy black plate armor on chest and shoulders, reinforced shoulder guards, light machine gun or heavy assault rifle, intimidating wide-stance posture, dark black primary color #1A1A1A with red accent #AA1111 on helmet, hard-edge geometry, 400-550 triangles, game asset T-pose
```

| 規格項目 | 內容 |
|---------|------|
| 高度/寬度比例 | 高 1.8 unit / 寬 0.75 unit（比普通兵高壯） |
| 多邊形目標 | 400–550 tri |
| 貼圖解析度 | 256×256px |
| 存放路徑 | `src/assets/characters/enemies/enemy_elite_base.glb` |
| Godot 縮放 | `Scale = Vector3(0.9, 0.9, 0.9)` |

---

### 12. Boss

**識別色：黑金 `#111111` 底 + `#FFBB00` 描邊**

**Meshy.ai Prompt（直接複製）：**
```
Isometric low-poly 3D enemy boss commander, massive imposing build twice the height of normal soldiers, heavy exoskeleton armor with thick black plates covering entire body, dual-wielding heavy weapons one in each hand, command antenna array on back, gold glowing edge trim on all armor panel borders and joints, ominous full-face visor helmet, wide dominant stance occupying two tile widths, dark black primary color #111111 with bright gold emission accent #FFBB00, hard-edge geometry, 800-1200 triangles, game asset
```

| 規格項目 | 內容 |
|---------|------|
| 高度/寬度比例 | 高 2.2 unit / 寬 1.2 unit（佔 2×2 格子，存在感最強） |
| 多邊形目標 | 800–1200 tri |
| 貼圖解析度 | 256×256px |
| 存放路徑 | `src/assets/characters/enemies/boss_base.glb` |
| Godot 縮放 | `Scale = Vector3(1.1, 1.1, 1.1)`（大於所有角色，視覺震撼感） |
| 特效備註 | Godot 內加 `OmniLight3D`（色 `#FFBB00`，能量 0.4），附在 Boss 節點，每 10 秒觸發 Emission 脈衝 Tween |

---

## 快速對照表

| 批次 | 模型名稱 | 存放路徑 | Godot Scale | Meshy 多邊形目標 |
|------|---------|---------|-------------|----------------|
| 第一批 | 突擊手 | `characters/assault/assault_base.glb` | 0.9 | 300–600 |
| 第一批 | 盾兵 | `characters/tank/tank_base.glb` | 1.0 | 300–600 |
| 第一批 | 普通敵人 | `characters/enemies/enemy_soldier_base.glb` | 0.8 | 200–300 |
| 第一批 | 地板 tile | `environment/tiles/floor_concrete.glb` | 1.0 | 50–100 |
| 第二批 | 醫療兵 | `characters/medic/medic_base.glb` | 0.9 | 300–500 |
| 第二批 | 狙擊手 | `characters/sniper/sniper_base.glb` | 0.85 | 300–550 |
| 第二批 | 牆壁 tile | `environment/tiles/wall_concrete.glb` | 1.0 | 100–200 |
| 第二批 | 補給箱 | `environment/props/supply_crate.glb` | 0.6 | 100–200 |
| 第三批 | 爆破手 | `characters/demo/demo_base.glb` | 0.92 | 350–600 |
| 第三批 | 偵察手 | `characters/recon/recon_base.glb` | 0.85 | 250–450 |
| 第三批 | 精英敵人 | `characters/enemies/enemy_elite_base.glb` | 0.9 | 400–550 |
| 第三批 | Boss | `characters/enemies/boss_base.glb` | 1.1 | 800–1200 |

所有路徑均以 `src/assets/` 為根目錄。

---

*MESHY_PROMPTS v1.0 — 美術組長審核完成*
*Prompt 若生成結果不符預期，微調關鍵詞：`hard-edge`、`low-poly`、`T-pose`、`game asset` 這四個詞必須保留*
