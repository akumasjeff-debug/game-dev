專案類型: 程式

# 排班系統 — 專案規則

## 專案類型
**程式工具**（非遊戲）— 多門市員工排班管理系統

## 技術架構
- 純 HTML / CSS / JavaScript，無框架、無打包工具
- 後端：Firebase Firestore（`roster-fadmart` 專案）
- AI 排班：Google Gemini API（使用者自行提供 API Key，存於 localStorage）
- 日期選擇：flatpickr CDN

## Firebase 集合結構
| 集合 | 用途 |
|------|------|
| `Employees` | 員工資料（姓名、職位、可支援門市、固定公休、許願假、工時區間）|
| `Stores` | 門市資料（名稱、可用班別、每週人力需求、班別優先順序）|
| `ShiftTypes` | 班別定義（代碼、名稱、時間、工時）|
| `Rosters` | 班表資料（依月份存放，key 格式 `YYYY-MM`）|
| `EmployeeRoles` | 職位清單 |

## 各頁面對應功能
- `src/main-scheduler.html` — 主排班（月曆 + AI + 手動）
- `src/employee-manager.html` — 員工管理
- `src/store-manager.html` — 門市管理
- `src/shift-manager.html` — 班別管理
- `src/schedule-view.html` — 代班推薦（未完成）
- `src/ForMamber.html` — 員工視角班表（未完成）
- `src/index.html` — 待改為正式入口頁

## 核心規則（AI 排班邏輯）
- 員工不得連續上班超過 6 天（6休1）
- 每月工時需在 `minHours` ~ `maxHours` 之間（預設 60~80h）
- 固定班門市員工優先排，機動人員遞補
- AI 使用 Gemini API，帶入前 6 天歷史確保跨月正確

## 開發注意事項
- Firebase API Key 已硬編碼在各 HTML 檔案中（`roster-fadmart` 專案）
- Gemini API Key 由使用者在介面輸入，不存在程式碼裡
- 各頁面目前獨立，尚無統一導覽
