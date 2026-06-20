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

## 進行中
-

## 待辦
- 匯出功能（PDF 或 Excel 班表）
- Firebase Security Rules（目前無身份驗證，任何人可讀寫）

## 待確認
- 是否需要登入機制（Firebase Auth）
- 是否要整合成單一 HTML 檔案（離線版），或維持多頁 Firebase 版

## 已知問題
- ai-test.html 是開發測試頁，可保留或移除

## 操作紀錄
- 2026-06-20 從桌面新增資料夾移入 d:\開發遊戲\程式\排班系統\src\
- 原始班表參考資料：玥勝原始班表.xlsx
- 2026-06-20 index.html 全面改寫為導覽入口頁
- 2026-06-20 schedule-view.html 全面改寫（舊版為 AI 一鍵排班，新版為日期選擇 + Firebase 查詢 + 純邏輯代班推薦）
- 2026-06-20 ForMamber.html 補充「返回首頁」連結與底部工時統計卡片
- 2026-06-20 main-scheduler.html 補充返回首頁連結與 pick() 6休1 驗證邏輯
- 2026-06-20 employee-manager、store-manager、shift-manager 補充返回首頁連結
