# Auto Facade — SketchUp 建築自動建模外掛（P1）

參數驅動的建築立面自動建模工具。目前範圍 **P1 + P2**：
垂直遮陽鰭片（W-02）+ 樓板（RB-01）+ 帷幕牆系統（CW-01 豎框/橫框 + GL-01 玻璃單元），
支援 **inch / cm 單位切換** 與參數即時驗證。

對應設計文件：
- `../docs/01-需求與架構分析.md`（全局架構與 P0–P6 路線圖）
- `../docs/02-P1鰭片立面細部設計.md`（鰭片立面）
- `../docs/03-P2帷幕牆系統設計.md`（帷幕牆系統）

## 目錄結構

```
sketchup_auto_facade/
├─ auto_facade.rb              # Extension 載入器（註冊 SketchupExtension）
├─ auto_facade/
│  ├─ main.rb                  # 進入點：選單 + 工具列
│  ├─ core/
│  │  ├─ units.rb              # 單位轉換（內部一律 inch）
│  │  └─ parameters.rb         # 參數 normalize / validate
│  ├─ builder/
│  │  ├─ fin_layout.rb         # 鰭片佈局演算法（by_count / by_spacing）
│  │  ├─ curtain_wall.rb       # 帷幕牆（豎框 / 橫框 / 玻璃單元）
│  │  ├─ facade_builder.rb     # 建模主流程（鰭片 / 樓板 / 帷幕牆）
│  │  └─ materials.rb          # 材質（深鐵灰 / 玻璃藍）
│  └─ ui/
│     ├─ dialog.rb             # HtmlDialog + Ruby↔JS 通訊
│     └─ html/                 # index.html / style.css / app.js
├─ test/test_core.rb          # 純 Ruby 單元測試（不需 SketchUp）
└─ build.rb                   # 打包成 .rbz
```

## 安裝

**方法 A：手動**
將 `auto_facade.rb` 與 `auto_facade/` 一併複製到 SketchUp 的 Plugins 目錄：
- Windows：`%AppData%\SketchUp\SketchUp 20XX\SketchUp\Plugins`
- macOS：`~/Library/Application Support/SketchUp 20XX/SketchUp/Plugins`

**方法 B：.rbz**
執行 `ruby build.rb` 產生 `AutoFacade.rbz`，於 SketchUp
「視窗 > 延伸程式管理器 > 安裝延伸程式」選取安裝。

## 使用

1. 選單 `延伸程式 / Plugins > Auto Facade > 開啟設計面板…`
2. 設定單位、立面、鰭片、樓板參數（面板會即時提示支數/間距與「過密」警告）。
3. 按「生成 / 更新模型」。再次調整參數後重按即「就地重建」（單步 Undo 可還原）。

預設參數即為設計表中的「新版（修正）」：立面寬 144"、3 開間、13 支鰭片、
間距 12"、寬 2.5"、深 10"、深鐵灰 `#3a3f44`。

## 測試

```
ruby test/test_core.rb
```
涵蓋 docs/02 §10 的 T1–T5（佈局演算法、單位等價、過密/重疊驗證）。

## 需求版本

SketchUp 2021+（採用 `UI::HtmlDialog`）。
