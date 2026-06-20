專案類型: 遊戲

# 國語小練習 — 專案規則

## 專案簡介
國小國語練習網頁，純 HTML + vanilla JS，無框架無打包工具。
目標對象：小學 1-3 年級，仿考卷 8 種題型，手機優先設計。

## 技術架構
- `index.html`：樣式 + HTML 骨架
- `app.js`：題目生成邏輯、題型渲染、狀態管理、localStorage
- `data.js`：字典資料（CHAR_DB）+ 課本題庫（TEXTBOOK_*）

## 題型列表
1. `zhuyin`：給字，選注音
2. `char_fill`：給注音+句子，選正確字（同音字辨別）
3. `classifier`：量詞
4. `redup`：疊字詞
5. `fill_blank`：填空（選詞）
6. `wrong_char`：改錯字
7. `radical`：部首部件（選出不同部件的字）
8. `true_false`：○× 判斷

## 資料擴充方式
- 增加注音字：在 `data.js` 的 `CHAR_DB` 新增 `{ z:'注音', b:'部首', g:年級 }`
- 增加填空題：在 `TEXTBOOK_FILL_Q` 新增 `{ sent, answer, options:[4個] }`
- 增加看注音選字：在 `TEXTBOOK_CHAR_Q` 新增 `{ before, zhuyin, answer, options:[4個] }`
- 增加 ○× 題：在 `TEXTBOOK_TF_Q` 新增 `{ text, answer:true/false }`
- 增加量詞：在 `app.js` 的 `CLASSIFIERS` 新增 `{ word, answer, options:[4個] }`
- 增加部首群組：在 `app.js` 的 `RADICAL_GROUPS` 新增 `{ radical, label, chars:[至少4個] }`
