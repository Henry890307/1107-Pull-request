# DO Flow

把你自己開發的 **React Native 程式碼「丟」進來，DO Flow 會在裝置外框裡即時轉譯、
執行並渲染成可互動的 app 預覽** —— 概念類似手機版的 Expo Snack / CodeSandbox。

> 跨平台（iOS / Android / Web）以 **Expo + React Native + TypeScript** 打造。

---

## 它能做什麼（MVP）

- **匯入程式碼**：貼上單檔、從裝置選多個檔案、或匯入 `.zip` 專案。
- **即時預覽**：在 iPhone / Android 裝置外框內渲染你的 app，可切換裝置尺寸、旋轉、重跑。
- **多檔專案**：支援跨檔案的相對 `import`（例如 `./components/Button`）。
- **除錯面板**：顯示 `console.log` 與建置 / 渲染錯誤；不支援的套件會給出友善提示。
- **本地保存**：專案以 AsyncStorage 持久化，重開 app 仍在。
- **內建範例**：計數器（單檔）與待辦清單（多檔）可一鍵體驗。

可用套件：`react`、`react-native`、`react-native-safe-area-context`。

---

## 架構

```
app/                      # expo-router 畫面
  _layout.tsx             # Stack 導覽 + SafeAreaProvider
  index.tsx               # 專案列表 / 範例
  import.tsx              # 匯入（貼上 / 選檔 / zip）
  editor.tsx              # 檔案樹 + 程式碼編輯器
  preview.tsx             # 裝置外框即時預覽 + Console
  settings.tsx
src/
  engine/                 # ★ 即時預覽引擎（核心）
    transpile.ts          #   @babel/standalone：JSX/TS → CommonJS（classic runtime）
    moduleSystem.ts       #   受控 require + 模組圖，注入真實 RN 元件後 eval 執行
    hostModules.ts        #   套件白名單（react / react-native / safe-area-context）
    paths.ts              #   相對 import 解析（無 Node path 模組）
    PreviewRuntime.tsx    #   ErrorBoundary + 渲染進入點元件
    types.ts
  store/projectStore.ts   # zustand + AsyncStorage 持久化
  io/importers.ts         # 貼上 / document-picker / JSZip
  ui/                     # DeviceFrame / FileTree / ConsolePanel / Button / theme
  samples/                # 內建範例專案
```

### 引擎運作流程
1. 匯入的檔案存成 `Map<path, source>`，偵測進入點（`App.tsx` 的 default export）。
2. 每個檔案以 Babel 在裝置上轉譯成 CommonJS（快取）。
3. 自製 `require`：相對路徑解析到其他檔案（依相依順序執行並快取）；
   套件 import 回傳白名單內的**真實** host 模組；其他套件丟出友善錯誤。
4. 取進入點 default export（React 元件），包在 ErrorBoundary 內於裝置外框渲染。

---

## 開發 / 執行

```bash
npm install
npm run web        # 在瀏覽器預覽（最快的驗證方式）
npm run ios        # iOS 模擬器 / Expo
npm run android    # Android 模擬器 / Expo
```

### ⚠️ 執行引擎需要 `eval` 支援
即時預覽以 `Function` 建構式執行轉譯後的程式碼：

| 環境 | 是否可用 | 說明 |
| --- | --- | --- |
| Web (react-native-web) | ✅ | 直接可用 |
| 原生自訂 dev build (JSC) | ✅ | 本專案已設定 `app.json` → `jsEngine: "jsc"` |
| Expo Go / Hermes | ❌ | Hermes 預設停用 `eval`，需用 JSC 的自訂建置 |

---

## 已知限制與路線圖

- **沙箱**：eval 與 host 共用 JS context，僅以套件白名單限制能力，非真正隔離 →
  後續評估 QuickJS / 隔離 WebView。
- **Flutter 支援**：Dart 需要 VM，無法在 RN 內直接執行 → 規劃以遠端 Flutter Web
  build 服務 + WebView 呈現。
- **設計檔匯入**（Figma / Sketch / 截圖）：以 AI 解析產生可預覽 UI。
- 更多 RN 生態套件白名單、語法高亮編輯器、雲端同步與分享連結。
