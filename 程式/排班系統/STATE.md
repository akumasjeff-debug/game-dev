# 排班系統 狀態

## 已完成
- Firebase Firestore 資料架構（Employees、Stores、ShiftTypes、Rosters、EmployeeRoles）
- 員工管理：CRUD、許願休假、固定公休、可支援門市
- 門市管理：人力需求設定（每週各天人數）、班別優先順序（Must/Prio）
- 班別管理：班次代碼、時間、工時定義
- 主排班月曆：手動拖填、補位、機動新增
- AI 自動排班：接 Gemini API，遵守 6休1 規則、工時上下限
- 員工工時統計表
- 2026-06-20 統一導覽入口頁（index.html 改為正式選單，藍色 card 風格，連結全部功能頁）
- 2026-06-20 schedule-view.html 完成（代班推薦：選日期查排班，「找代班」按鈕純邏輯計算，考慮 6休1 + 固定公休 + 可支援門市）
- 2026-06-20 ForMamber.html 完成（員工矩陣月班表 + 工時統計卡片，含門市日曆、切月份）
- 2026-06-20 main-scheduler.html 加入 6休1 前端強制驗證（pick() 函數，連續 7 天時 alert 並拒絕排入）
- 2026-06-20 全部功能頁加入「返回首頁」連結
- 2026-06-20 全組健康審查完成（設計/技術/UI/品管/數值，共 5 組）
- **2026-06-20 app.html 統一整合版完成，整合所有功能於單一 HTML 檔案（含側欄導覽 + 手機 Tab Bar + 手機週視圖）**
- **2026-06-20 [P0-1] 跨月 6休1 歷史修復**：新增 `sch_prevRoster` 全域變數，`sch_load()` 同時載入上個月班表，新增 `hasShiftOnDate()` 輔助函數，`sch_render()`/`sch_pick()`/`history` 計算全改用跨月查詢
- **2026-06-20 [P0-2] AI 失敗保護**：`candidates?.length` 空時 throw、所有模型失敗時 throw 錯誤訊息
- **2026-06-20 [P1-1] Firebase try/catch**：`sch_load()`、`emp_init()`、`store_init()`、`member_fetchData()` 全部加入 try/catch 並 alert 錯誤
- **2026-06-20 [P1-2] 月初連班 UI 修正**：已由 P0-1 的 `hasShiftOnDate()` 一併解決
- **2026-06-20 [P1-3] 初始月份改 `new Date()`**：`sch_currDate` 與 `member_currDate` 改為動態當月
- **2026-06-20 [P1-4] 工時預設依職位拆分**：正職/全職/Full → 160~176h，其餘 → 60~80h，已有資料則保留
- **2026-06-20 [P1-5] 例假日/排休日分開**：員工表單新增「🚫 例假日」+「💤 排休日」兩區塊，Firebase 新增 `restDays` 欄位，代班推薦標注「⚠️ 今日排休，加班出勤」，AI Prompt 加入排休日軟性規則
- **2026-06-20 [P2-1] Modal 點背景關閉**：所有 `.modal` 加 click 監聽，點背景自身就關閉
- **2026-06-20 [P2-2] AI 排班 Modal 加月份確認**：`sch_openAiModal()` 動態更新標題顯示當前月份
- **2026-06-20 部署版複製完成**：`apps/roster/index.html` 已同步更新（2262 行）

## 進行中
-

## 待辦

### P2 — 中優先（體驗改善，部分已完成）

- **[P2-3] 機動新增按鈕點擊區太小（padding 只有 5px）**
  - 位置：`app.html` `.add-extra-btn`
  - 修法：padding 改為 `10px 5px`，高度達 44px 手機標準

- **[P2-4] 員工班表無資料時全顯示「-」，無友善提示**
  - 修法：`member_buildTable()` 加入無資料時的提示文字

- **[P2-5] 員工班表橫向捲動無視覺提示**
  - 修法：`.member-table-wrapper` 右側加漸層遮罩（`::after` 偽元素）

- **[P2-6] 代班推薦候選人卡片缺少本月工時資訊與班別相容性**
  - 問題：候選人卡片只顯示連班天數，不顯示工時狀況
  - 修法：卡片加「本月已 Xh（上限 Yh）」顯示

### P3 — 低優先（錦上添花）

- **[P3-1] AI 排班改分批執行（7 天或 14 天一批）**
- **[P3-2] 許願假加天數上限保護（建議上限 8 天）**
- **[P3-3] 三個主頁加統一底部 Tab Bar**（app.html 已有手機 tab bar，此項指桌面版）
- **[P3-4] 員工班表加個人班表快速篩選**
- **[P3-5] 匯出功能（PDF 或 Excel 班表）**
- **[P3-6] Firebase Security Rules**

## 待確認
- 是否需要登入機制（Firebase Auth）

## 已知問題
- ai-test.html 是開發測試頁，可保留或移除
- `sch_validateAndFix()` 裡的 6休1 驗證仍用 `sch_prevDateKey()`（舊函數），未換成 `hasShiftOnDate()`，但因為 aiRoster 內部查詢不需要跨月（AI 排的是當月範圍），影響有限

## 操作紀錄
- 2026-06-20 從桌面新增資料夾移入 d:\開發遊戲\程式\排班系統\src\
- 原始班表參考資料：玥勝原始班表.xlsx
- 2026-06-20 index.html 全面改寫為導覽入口頁
- 2026-06-20 schedule-view.html 全面改寫（舊版為 AI 一鍵排班，新版為日期選擇 + Firebase 查詢 + 純邏輯代班推薦）
- 2026-06-20 ForMamber.html 補充「返回首頁」連結與底部工時統計卡片
- 2026-06-20 main-scheduler.html 補充返回首頁連結與 pick() 6休1 驗證邏輯
- 2026-06-20 employee-manager、store-manager、shift-manager 補充返回首頁連結
- 2026-06-20 五組全局健康審查完成，待辦清單已依 P0/P1/P2/P3 優先順序重整
- 2026-06-20 app.html 整合版建立，src/app.html 為主開發檔案，apps/roster/index.html 為部署版
- 2026-06-20 P0+P1+P2 修復完成（共 8 項），app.html 同步至 apps/roster/index.html（2262 行）
