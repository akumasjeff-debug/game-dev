# 台灣熱炒王 — Godot 4 架構設計

**版本：** v1.0
**日期：** 2026-06-20
**負責人：** 技術組長（程式設計師）
**引擎：** Godot 4.3+（GDScript）
**目標平台：** Android + iOS

---

## A. 場景樹設計

### 完整場景樹

```
Main（Main.tscn）                    ← 根場景，掛 GameManager.gd（AutoLoad）
├── Game（Game.tscn）                ← 遊戲世界主容器
│   ├── TileMapLayer（floor_layer）  ← 地板層：區域底板（廚房/外場/走道等）
│   ├── TileMapLayer（object_layer） ← 設備層：放置的設備、桌椅、裝飾物
│   ├── Node2D（characters）         ← 角色容器：所有客人與員工的父節點
│   └── Node2D（vfx）                ← 特效容器：冒煙、火焰、飄字等粒子效果
└── UI（UI.tscn）                    ← 介面根節點
    ├── CanvasLayer（hud_layer）      ← HUD 層：金錢、名聲、時間、訂單狀態
    ├── CanvasLayer（dialog_layer）   ← 對話框層：事件通知、角色對話、提示訊息
    └── CanvasLayer（build_layer）    ← 建造模式層：格子網格、預覽幽靈、區域底板選擇
```

AutoLoad（全域單例，不屬於任何場景樹節點，在 project.godot 設定）：
- `GameManager`（GameManager.gd）：遊戲狀態總管，協調各子系統
- `AudioManager`（AudioManager.tscn）：全域音效播放，避免場景切換時音樂中斷

---

### 各節點職責

| 節點 | 類型 | 職責 |
|------|------|------|
| Main | Node | 根場景，協調 Game 與 UI 的初始化順序 |
| Game | Node2D | 遊戲世界容器，持有相機 Camera2D |
| TileMapLayer (floor) | TileMapLayer | 繪製區域底板（廚房橘/外場米黃/走道灰/倉庫咖啡/裝飾綠），每格帶 custom_data zone_type |
| TileMapLayer (object) | TileMapLayer | 繪製放置的設備與桌椅圖塊，提供視覺呈現 |
| Node2D (characters) | Node2D | 所有 Customer 與 Staff 的父容器，方便統一查詢 |
| Node2D (vfx) | Node2D | 特效節點（AnimatedSprite2D/GPUParticles2D），完成後自動移除 |
| CanvasLayer (hud) | CanvasLayer | layer=1，始終渲染在遊戲世界上方，顯示即時數值 |
| CanvasLayer (dialog) | CanvasLayer | layer=2，對話框與通知，可遮蓋 HUD |
| CanvasLayer (build) | CanvasLayer | layer=3，建造模式才顯示（visible=false 平時隱藏） |

---

## B. TileMap 格子系統設計

### 對應 design/map-design.md

---

### TileMapLayer 設定

```gdscript
# 兩層 TileMapLayer，共用同一個 TileSet
# floor_layer：z_index = 0，繪製區域底板
# object_layer：z_index = 1，繪製設備與桌椅
# 格子大小：16x16 px（tile_set.tile_size = Vector2i(16, 16)）
# 像素過濾：texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
```

---

### 座標系統

- 類型：`Vector2i`，整數格子座標
- 原點：左上角 `(0, 0)`，X 向右，Y 向下
- 世界座標 ↔ 格子座標：

```gdscript
# 世界座標 → 格子座標
var cell: Vector2i = floor_layer.local_to_map(world_position)

# 格子座標 → 世界座標（格子中心）
var center: Vector2 = floor_layer.map_to_local(cell)
```

---

### Zone 系統實作

每個 floor_layer 格子透過 TileSet CustomData 儲存區域類型：

```gdscript
# TileSet CustomData 設定（在編輯器中建立）
# 欄位名稱："zone_type"
# 欄位類型：int

# Zone 對應常數（ZoneType.gd）
enum ZoneType {
    NONE      = 0,   # 未指定（初始狀態）
    KITCHEN   = 1,   # 廚房區（灶腳區）— 橘紅 #D4380D
    DINING    = 2,   # 外場區（桌椅區）— 米黃 #D4B896
    WALKWAY   = 3,   # 走道區（通道）— 灰白 #C0C0C0
    STORAGE   = 4,   # 倉庫區（儲藏區）— 咖啡 #7A5C3A
    DECOR     = 5,   # 裝飾區（門面區）— 草綠 #52A06A
}

# 讀取格子 zone_type
func get_zone(cell: Vector2i) -> ZoneType:
    var tile_data: TileData = floor_layer.get_cell_tile_data(cell)
    if tile_data == null:
        return ZoneType.NONE
    return tile_data.get_custom_data("zone_type") as ZoneType

# 設定格子 zone_type（鋪設底板）
func set_zone(cell: Vector2i, zone: ZoneType) -> void:
    # 先確認格子上沒有設備才允許更改
    if occupied_cells.has(cell):
        return
    floor_layer.set_cell(cell, SOURCE_ID, zone_to_atlas_coord[zone])
```

---

### 地圖尺寸規格

| 階段 | 總尺寸（含邊界） | 可建造範圍 | 解鎖條件 |
|------|----------------|-----------|---------|
| 初始 | 8x6 | (1,1)～(6,4) | 遊戲開始 |
| 第一擴張 | 12x8 | (1,1)～(10,6) | Year 2 + NT$120,000 |
| 第二擴張 | 16x10 | (1,1)～(14,8) | Year 4 + NT$300,000 |
| 第三擴張 | 18x12 | (1,1)～(16,10) | Year 7 + NT$600,000 |

有效建造區域公式：`(1, 1)` 到 `(map_width - 2, map_height - 2)`（四周各保留 1 格邊界）

---

### 設備佔用格子管理

```gdscript
# 全域佔用表（GridManager.gd）
# key: Vector2i 格子座標
# value: Dictionary { "equipment_id": String, "instance_id": String, "anchor": Vector2i }
var occupied_cells: Dictionary = {}

# 嘗試擺放設備（含碰撞檢查）
func try_place_equipment(anchor: Vector2i, equip_data: EquipmentData, rotated: bool) -> bool:
    var cells_needed: Array[Vector2i] = get_equipment_cells(anchor, equip_data.size, rotated)

    # 邊界檢查
    for cell in cells_needed:
        if not is_within_buildable_area(cell):
            return false

    # 佔用衝突檢查
    for cell in cells_needed:
        if occupied_cells.has(cell):
            return false

    # Zone 合規檢查
    var required_zone: ZoneType = equip_data.required_zone
    for cell in cells_needed:
        if get_zone(cell) != required_zone:
            return false

    # 通過所有檢查，登記佔用
    var instance_id: String = "%s_%d" % [equip_data.id, Time.get_ticks_msec()]
    for cell in cells_needed:
        occupied_cells[cell] = {
            "equipment_id": equip_data.id,
            "instance_id": instance_id,
            "anchor": anchor
        }

    # 更新 TileMap 視覺
    _update_object_tilemap(anchor, equip_data, rotated)

    # 重建路徑尋路圖
    _rebuild_astar()

    return true

# 取得設備所有佔用格（考慮旋轉）
func get_equipment_cells(anchor: Vector2i, size: Vector2i, rotated: bool) -> Array[Vector2i]:
    var cells: Array[Vector2i] = []
    var w: int = size.x if not rotated else size.y
    var h: int = size.y if not rotated else size.x
    for dy in range(h):
        for dx in range(w):
            cells.append(anchor + Vector2i(dx, dy))
    return cells
```

---

### 路徑尋路（AStar2D）

```gdscript
# PathfindingManager.gd（scripts/systems/）
var astar: AStar2D = AStar2D.new()

# 地圖變更後重建尋路圖
func _rebuild_astar() -> void:
    astar.clear()
    var map_rect: Rect2i = grid_manager.get_buildable_rect()

    # 加入所有可通行格子（走道區 + 未被佔用格子）
    for y in range(map_rect.position.y, map_rect.end.y + 1):
        for x in range(map_rect.position.x, map_rect.end.x + 1):
            var cell := Vector2i(x, y)
            if _is_walkable(cell):
                var point_id: int = _cell_to_id(cell)
                astar.add_point(point_id, Vector2(x, y))

    # 連接相鄰可通行格子（四方向）
    for y in range(map_rect.position.y, map_rect.end.y + 1):
        for x in range(map_rect.position.x, map_rect.end.x + 1):
            var cell := Vector2i(x, y)
            if not astar.has_point(_cell_to_id(cell)):
                continue
            for neighbor in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
                var ncell := cell + neighbor
                if astar.has_point(_cell_to_id(ncell)):
                    astar.connect_points(_cell_to_id(cell), _cell_to_id(ncell))

func find_path(from_cell: Vector2i, to_cell: Vector2i) -> Array[Vector2i]:
    var id_path: PackedInt64Array = astar.get_id_path(_cell_to_id(from_cell), _cell_to_id(to_cell))
    var result: Array[Vector2i] = []
    for id in id_path:
        result.append(_id_to_cell(id))
    return result

func _is_walkable(cell: Vector2i) -> bool:
    # 走道區一定可通行
    if grid_manager.get_zone(cell) == ZoneType.WALKWAY:
        return true
    # 其他區域若未被設備佔用，角色也可移動（非最佳路徑）
    return not grid_manager.occupied_cells.has(cell)

func _cell_to_id(cell: Vector2i) -> int:
    return cell.y * 100 + cell.x  # 最大地圖 18x12，不超過 1800

func _id_to_cell(id: int) -> Vector2i:
    return Vector2i(id % 100, id / 100)
```

---

## C. 客人 / 員工 FSM 狀態機設計

### 對應 art/animation-spec.md 動畫轉換規則

---

### 設計原則

每個角色是一個獨立 Node2D，內部持有 FSM 實例。
狀態以 GDScript inner class 實作，透過 `enter()` / `update(delta)` / `exit()` 三個方法管理生命週期。

---

### 員工 FSM（StaffFSM.gd）

```gdscript
# scripts/ai/StaffFSM.gd
class_name StaffFSM
extends Node

enum State {
    IDLE,       # 待機，播放 idle 動畫
    WALK,       # 移動中，播放 walk 動畫（方向對應）
    WORKING,    # 工作中（炒菜/送餐/切菜），播放對應工作動畫
    SATISFIED,  # 完成任務，播放滿意動畫（播完自動回 IDLE）
    ANGRY,      # 被玩家忽視/士氣歸零，播放生氣動畫（播完回 IDLE）
}

var current_state: State = State.IDLE
var owner_staff: Node  # 持有此 FSM 的員工節點
var animated_sprite: AnimatedSprite2D

# 狀態轉換入口
func transition_to(new_state: State) -> void:
    if current_state == new_state:
        return
    _exit_state(current_state)
    current_state = new_state
    _enter_state(new_state)

func _enter_state(state: State) -> void:
    match state:
        State.IDLE:
            animated_sprite.play("idle")
        State.WALK:
            animated_sprite.play("walk_%s" % _direction_suffix())
        State.WORKING:
            animated_sprite.play(owner_staff.current_work_animation)
        State.SATISFIED:
            animated_sprite.play("satisfied")
            # 播完後自動回 IDLE（連接 AnimatedSprite2D.animation_finished 信號）
        State.ANGRY:
            animated_sprite.play("angry")

func _exit_state(state: State) -> void:
    pass  # 目前不需要 exit 清理，預留擴充

func update(delta: float) -> void:
    match current_state:
        State.WALK:
            owner_staff.move_along_path(delta)
            if owner_staff.path_complete:
                transition_to(State.WORKING if owner_staff.has_task else State.IDLE)
        State.WORKING:
            owner_staff.process_task(delta)
            if owner_staff.task_done:
                transition_to(State.SATISFIED)

# 動畫方向後綴（依移動向量決定）
func _direction_suffix() -> String:
    var vel: Vector2 = owner_staff.velocity.normalized()
    if abs(vel.x) > abs(vel.y):
        return "right" if vel.x > 0 else "left"
    else:
        return "down" if vel.y > 0 else "up"
```

**員工狀態轉換條件（對應 animation-spec.md）：**

| 觸發條件 | 轉換至 |
|---------|--------|
| 無任務指派 | IDLE |
| 收到移動/任務指令 | WALK |
| 抵達工作位置 | WORKING |
| 工作完成（炒好菜/送達餐點） | SATISFIED（播完回 IDLE） |
| 士氣值歸零或長時間未分配任務 | ANGRY（播完回 IDLE） |

---

### 客人 FSM（CustomerFSM.gd）

```gdscript
# scripts/ai/CustomerFSM.gd
class_name CustomerFSM
extends Node

enum State {
    ENTERING,    # 從入口走進來，尋找座位
    WAITING,     # 找不到位子，在入口等待（耐心遞減）
    EATING,      # 已入座，等待/吃飯（分三個子階段由邏輯控制）
    SATISFIED,   # 收到餐點後短暫播放滿意爆出，接回 EATING
    ANGRY,       # 耐心歸零，生氣爆出後離開
    LEAVING,     # 播放離開動畫，播完後移除節點
}

var current_state: State = State.ENTERING
var owner_customer: Node
var animated_sprite: AnimatedSprite2D

func transition_to(new_state: State) -> void:
    if current_state == new_state:
        return
    # 高優先轉換：ANGRY 可打斷任何狀態
    if new_state == State.ANGRY or new_state == State.LEAVING:
        _force_transition(new_state)
        return
    _exit_state(current_state)
    current_state = new_state
    _enter_state(new_state)

func _force_transition(new_state: State) -> void:
    animated_sprite.stop()
    current_state = new_state
    _enter_state(new_state)

func _enter_state(state: State) -> void:
    match state:
        State.ENTERING:
            animated_sprite.play("walk_down")
        State.WAITING:
            animated_sprite.play("idle_normal")
        State.EATING:
            # 等餐時播 idle_normal，收到餐後外部呼叫 transition_to(SATISFIED)
            animated_sprite.play("idle_normal")
        State.SATISFIED:
            animated_sprite.play("satisfied_burst")
            # 播完後切回 EATING（連接 animation_finished 信號）
        State.ANGRY:
            animated_sprite.play("angry_burst")
            # 播完後切 LEAVING（連接 animation_finished 信號）
        State.LEAVING:
            animated_sprite.play("leave")
            # 播完後 queue_free()

func update(delta: float) -> void:
    match current_state:
        State.ENTERING:
            owner_customer.move_to_seat(delta)
            if owner_customer.seated:
                transition_to(State.EATING)
            elif owner_customer.no_seat_available:
                transition_to(State.WAITING)
        State.WAITING:
            owner_customer.patience -= delta * owner_customer.patience_decay_rate
            if owner_customer.patience <= 0.0:
                transition_to(State.ANGRY)
            # 輪詢是否有空位
            if owner_customer.find_available_seat():
                transition_to(State.ENTERING)
        State.EATING:
            # 耐心監控（等餐時也在遞減）
            if owner_customer.patience < 0.3 and not owner_customer.food_received:
                animated_sprite.play("idle_impatient")
            if owner_customer.patience <= 0.0:
                transition_to(State.ANGRY)
            if owner_customer.finished_eating:
                transition_to(State.LEAVING)
```

**客人狀態轉換條件（對應 animation-spec.md）：**

| 觸發條件 | 轉換至 |
|---------|--------|
| 進入場地 | ENTERING（walk 動畫） |
| 找到座位入座 | EATING（idle_normal） |
| 找不到座位 | WAITING（idle_normal，耐心遞減） |
| 耐心條 < 30% | 播放 idle_impatient（急躁抖腳）|
| 收到餐點 | SATISFIED（爆出星星） → 回 EATING |
| 耐心條歸零 | ANGRY（生氣爆出，最高優先，可打斷任何狀態） → LEAVING |
| 吃完離開 | LEAVING（離開動畫播完後 queue_free） |

**動畫名稱對應（AnimatedSprite2D animation 屬性）：**

| FSM 狀態 | animation 名稱 |
|---------|----------------|
| ENTERING | `walk_down` / `walk_left` / `walk_right` / `walk_up` |
| WAITING | `idle_normal` |
| EATING（等餐） | `idle_normal` |
| EATING（急躁） | `idle_impatient` |
| EATING（吃飯） | `idle_eating` |
| SATISFIED | `satisfied_burst` |
| ANGRY | `angry_burst` |
| LEAVING | `leave` |

---

## D. 存檔系統設計

### 格式與路徑

- **格式：** JSON（人類可讀，方便除錯與版本 migration）
- **存檔路徑：** `user://saves/save_01.json`
- **自動存檔：** `user://saves/auto_save.json`（每日結算後觸發）
- **手機平台確認：** `OS.get_user_data_dir()` 回傳實際沙盒路徑
  - Android：`/data/data/<package>/files/`
  - iOS：`<app_sandbox>/Documents/`

---

### 存檔根節點結構

```json
{
    "version": 1,
    "save_date": "2026-06-20T15:30:00",
    "game_data": {
        "year": 2,
        "day": 45,
        "money": 28500.0,
        "reputation": 340,
        "map": { ... },
        "unlocked_items": ["sanpei_chicken", "taiwan_beer"],
        "staff": [ ... ]
    }
}
```

**根節點欄位：**

| 欄位 | 型別 | 說明 |
|------|------|------|
| version | int | 存檔格式版本號，從 1 開始遞增 |
| save_date | String | ISO 8601 格式時間字串 |
| game_data | Object | 遊戲狀態主體（見下表） |

**game_data 欄位：**

| 欄位 | 型別 | 說明 |
|------|------|------|
| year | int | 當前遊戲年份（1 起） |
| day | int | 當前遊戲日（1 起，不跨年重置，累積天數） |
| money | float | 當前資金（新台幣，遊戲幣） |
| reputation | int | 聲望值（0~1000） |
| map | Object | 地圖狀態（見下方） |
| unlocked_items | Array[String] | 已解鎖菜色 + 設備 ID 列表 |
| staff | Array[Object] | 已雇用員工狀態列表 |

**map 結構：**

```json
"map": {
    "width": 12,
    "height": 8,
    "expansion_stage": 1,
    "cells": [
        { "x": 3, "y": 2, "zone": 1, "equipment_id": "wok", "level": 2 },
        { "x": 5, "y": 4, "zone": 2, "equipment_id": "plastic_table_4", "level": 1 }
    ]
}
```

**staff 陣列元素：**

```json
{
    "staff_id": "chef_a_long",
    "unlocked_skills": ["fast_wok"],
    "experience": 450
}
```

---

### 版本升級策略（SaveMigration.gd）

```gdscript
# scripts/systems/SaveMigration.gd
class_name SaveMigration
extends RefCounted

static func migrate(data: Dictionary) -> Dictionary:
    var version: int = data.get("version", 0)

    if version < 1:
        data = _migrate_v0_to_v1(data)

    # 未來版本在此繼續 if version < 2: ...
    return data

static func _migrate_v0_to_v1(data: Dictionary) -> Dictionary:
    # v0（開發期）→ v1：新增 reputation 欄位
    if not data["game_data"].has("reputation"):
        data["game_data"]["reputation"] = 0
    data["version"] = 1
    return data
```

---

### 讀寫實作（SaveManager.gd）

```gdscript
# scripts/systems/SaveManager.gd
class_name SaveManager
extends Node

const SAVE_DIR: String = "user://saves/"
const SAVE_FILE: String = "user://saves/save_01.json"
const CURRENT_VERSION: int = 1

func save_game(game_data: Dictionary) -> bool:
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)
    var payload: Dictionary = {
        "version": CURRENT_VERSION,
        "save_date": Time.get_datetime_string_from_system(),
        "game_data": game_data
    }
    var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    if file == null:
        push_error("SaveManager: 無法開啟存檔檔案 %s" % SAVE_FILE)
        return false
    file.store_string(JSON.stringify(payload, "\t"))
    file.close()
    return true

func load_game() -> Dictionary:
    if not FileAccess.file_exists(SAVE_FILE):
        return {}
    var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
    if file == null:
        return {}
    var raw: String = file.get_as_text()
    file.close()
    var result: Variant = JSON.parse_string(raw)
    if result == null or not result is Dictionary:
        push_error("SaveManager: 存檔 JSON 格式錯誤")
        return {}
    # 執行版本 migration
    return SaveMigration.migrate(result)
```

---

## E. 手機觸控輸入設計

### 建造模式：點擊格子

```gdscript
# scripts/systems/BuildModeInput.gd
func _input(event: InputEvent) -> void:
    if not build_mode_active:
        return

    if event is InputEventScreenTouch and event.pressed:
        # 螢幕座標 → 世界座標 → 格子座標
        var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
        var cell: Vector2i = floor_layer.local_to_map(world_pos)

        if grid_manager.is_within_buildable_area(cell):
            _on_cell_tapped(cell)
            get_viewport().set_input_as_handled()  # 防止事件穿透到地圖下層
```

---

### 拖放設備

```gdscript
func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _drag_start_pos = event.position
            _drag_start_cell = _screen_to_cell(event.position)
            _show_ghost_preview(_drag_start_cell)
        else:
            # 放開：嘗試擺放
            _hide_ghost_preview()
            var drop_cell: Vector2i = _screen_to_cell(event.position)
            if grid_manager.try_place_equipment(drop_cell, selected_equipment, is_rotated):
                _on_placement_success(drop_cell)
            else:
                _on_placement_fail()
            get_viewport().set_input_as_handled()

    elif event is InputEventScreenDrag:
        # 更新幽靈預覽位置
        var current_cell: Vector2i = _screen_to_cell(event.position)
        _update_ghost_preview(current_cell)
        get_viewport().set_input_as_handled()

func _show_ghost_preview(cell: Vector2i) -> void:
    ghost_sprite.visible = true
    ghost_sprite.modulate = Color(1, 1, 1, 0.5)  # 半透明
    ghost_sprite.position = floor_layer.map_to_local(cell)
```

---

### HUD 按鈕衝突防止

```gdscript
# UI 的 Control 節點
func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        get_viewport().set_input_as_handled()
        # 設定 input_as_handled 後，地圖不會收到此觸控事件
```

Control 節點的 `mouse_filter` 設為 `MOUSE_FILTER_STOP`，確保 HUD 按鈕觸控不穿透至地圖。

---

### 兩指縮放（Camera2D）

```gdscript
# scripts/core/CameraController.gd
extends Camera2D

const ZOOM_MIN: float = 0.8
const ZOOM_MAX: float = 2.0

var _prev_pinch_distance: float = 0.0
var _is_pinching: bool = false

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        # 追蹤觸控點數量，判斷是否為兩指操作
        _update_touch_count(event)

    elif event is InputEventScreenDrag:
        if _is_pinching:
            # 計算兩指距離變化
            var touches: Array = _get_active_touches()
            if touches.size() >= 2:
                var dist: float = touches[0].distance_to(touches[1])
                if _prev_pinch_distance > 0.0:
                    var scale_factor: float = dist / _prev_pinch_distance
                    var new_zoom: float = clampf(zoom.x * scale_factor, ZOOM_MIN, ZOOM_MAX)
                    zoom = Vector2(new_zoom, new_zoom)
                _prev_pinch_distance = dist
            get_viewport().set_input_as_handled()
```

---

### 效能注意事項（60fps 目標）

| 原則 | 說明 |
|------|------|
| 避免 _input 做重計算 | `_input` 只設 flag，計算移至 `_process` |
| 路徑尋路快取 | 相同起點/終點重複使用快取，地圖變更後才重建 AStar2D |
| 角色數量限制 | 同時在場最多 20 名客人 + 10 名員工，超出則排隊等候入場 |
| TileMap 更新頻率 | 僅在放置/移除設備時更新，不在每幀重繪 |
| 幽靈預覽優化 | 拖曳時每格子只更新一次（節流：格子座標變化才觸發） |
| GPU Particles | 煙霧/火焰特效使用 CPUParticles2D（手機更相容） |
