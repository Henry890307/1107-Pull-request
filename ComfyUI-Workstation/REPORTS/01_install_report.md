# ComfyUI 工作站 — 安裝完成報告

> 版本：v2.0 | 產生日期：2026-06-10 | 適用硬體：Intel i5-13500 / RTX 4080 32GB VRAM / RAM 96GB / Windows 11

---

## 重要聲明：套件性質與誠實說明

**本套件是在雲端 Linux 容器中產生的「完整部署套件」，並未在使用者的實體 Windows 機器上實際執行安裝。**

這意味著：
- 所有腳本、工作流 JSON、文件均已完整備妥於套件目錄中
- **實際安裝尚未發生**——必須由您在自己的 RTX 4080 機器上執行 `install/` 內的腳本
- 本報告的任務是提供清晰的執行指引，讓您能按部就班完成安裝

套件內容包含：
- PowerShell / Batch 安裝腳本（`install/`，共 6 個檔案）
- 7 個針對您用途設計的 ComfyUI 工作流 JSON（`ComfyUI_Workflows/`）
- 完整操作文件（`docs/`，共 6 份）
- 互動式模型下載腳本（8 個分類選單）

---

## 目標硬體規格

| 項目 | 規格 |
|------|------|
| CPU | Intel i5-13500（16 核心） |
| GPU | 特規 RTX 4080 32GB VRAM（Ada Lovelace AD103，sm_89，記憶體加大版） |
| RAM | 96 GB |
| 作業系統 | Windows 11 |
| 主要用途 | 建築渲染、室內設計、人物一致性、商品廣告、AI 影片、教會海報、IG 輪播、AutoCAD/SketchUp 轉效果圖 |

---

## 已備妥內容清單

### 安裝腳本

| 檔案 | 狀態 | 說明 |
|------|------|------|
| `install/01_check_environment.ps1` | ✅ 已備妥 | 環境前置檢查（Python、Git、CUDA、VRAM、磁碟空間） |
| `install/02_install_custom_nodes.bat` | ✅ 已備妥 | 22 個自訂節點批次安裝 |
| `install/03_download_models.ps1` | ✅ 已備妥 | 8 個分類選單互動式模型下載 |
| `install/04_create_folders.bat` | ✅ 已備妥 | 建立 ComfyUI models/ 完整資料夾結構 |
| `install/install_all.bat` | ✅ 已備妥 | 一鍵全流程執行主入口 |
| `install/generate_workflows.py` | ✅ 已備妥 | 產生並寫入 7 個工作流 JSON |

### 工作流

| 工作流 | 狀態 | 用途 |
|--------|------|------|
| `Architecture/Architecture_Pro.json` | ✅ 已備妥 | CAD 轉建築渲染 |
| `Interior/Interior_Design_Pro.json` | ✅ 已備妥 | SketchUp 轉室內設計 |
| `Character/Character_Consistency.json` | ✅ 已備妥 | 人物一致性生成 |
| `Product/Product_Advertising.json` | ✅ 已備妥 | 商品廣告圖 |
| `Video/Animal_Video.json` | ✅ 已備妥 | AI 動物影片 |
| `Video/Human_Video.json` | ✅ 已備妥 | AI 人物影片 |
| `Church/Church_Design.json` | ✅ 已備妥 | 教會海報多尺寸 |

### 文件

| 文件 | 狀態 |
|------|------|
| `docs/01_installation.md` | ✅ 已備妥 |
| `docs/02_controlnet_guide.md` | ✅ 已備妥 |
| `docs/03_ipadapter_guide.md` | ✅ 已備妥 |
| `docs/04_flux_guide.md` | ✅ 已備妥 |
| `docs/05_wan_video_guide.md` | ✅ 已備妥 |
| `docs/06_troubleshooting.md` | ✅ 已備妥 |

---

## 前置需求確認（安裝前請逐一核對）

- [ ] **ComfyUI 主程式** 已安裝（建議路徑：`C:\ComfyUI\`）
  - 下載：https://github.com/comfyanonymous/ComfyUI
- [ ] **Python 3.10 或 3.11**（64-bit）已安裝並在 PATH 中
  - 驗證：開啟 cmd，輸入 `python --version`
- [ ] **Git for Windows** 已安裝
  - 下載：https://git-scm.com/download/win
  - 驗證：`git --version`
- [ ] **NVIDIA 驅動程式 535.x 以上**（支援 CUDA 12）
  - 驗證：`nvidia-smi`，確認顯示 RTX 4080、32GB
- [ ] **PowerShell 執行原則** 已開放（以系統管理員執行一次）
  - 指令：`Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
- [ ] **磁碟空間充足**：至少 200GB 可用（完整模型約 150-175GB）
- [ ] **網路連線穩定**：FLUX 模型單檔超過 20GB
- [ ] **HuggingFace 帳號**（若要下載 FLUX gated 模型）
  - 申請 FLUX 存取：https://huggingface.co/black-forest-labs/FLUX.1-dev

---

## 使用者需執行的步驟清單

### 步驟 0：將套件複製到本機

將整個 `ComfyUI-Workstation/` 資料夾複製到您的 Windows 機器，建議放置於：

```
C:\ComfyUI\ComfyUI-Workstation\
```

---

### 步驟 1：執行環境檢查

以**系統管理員**開啟 PowerShell，執行：

```powershell
cd C:\ComfyUI\ComfyUI-Workstation\install
.\01_check_environment.ps1
```

預期輸出（全部顯示 [OK]）：
- `[OK] Python 3.11.x detected`
- `[OK] Git 2.x detected`
- `[OK] CUDA 12.x detected`
- `[OK] GPU: NVIDIA RTX 4080, 32 GB VRAM`
- `[OK] Available disk space: XXX GB (minimum 200 GB required)`

若有任何 `[WARN]` 或 `[FAIL]`，請先解決再繼續。

---

### 步驟 2：建立資料夾結構

```bat
.\04_create_folders.bat
```

此步驟將在 `C:\ComfyUI\models\` 下建立完整子資料夾結構（controlnet/、ipadapter/、checkpoints/ 等）。

---

### 步驟 3：安裝 22 個自訂節點

```bat
.\02_install_custom_nodes.bat
```

**預期時間：10–30 分鐘（視網路速度）**

將逐一 `git clone` 並執行 `pip install` 安裝以下節點：

| # | 節點 | 主要功能 |
|---|------|----------|
| 1 | ComfyUI-Manager | 節點管理中心 |
| 2 | Impact-Pack（含 Impact-Subpack） | **FaceDetailer**、人臉偵測器（FaceDetailer 為內建功能） |
| 3 | essentials | 基礎工具集 |
| 4 | Inspire-Pack | 進階採樣、區域提示 |
| 5 | Easy-Use | 簡化工作流封裝節點 |
| 6 | Custom-Scripts | 自訂腳本與介面擴充 |
| 7 | Advanced-ControlNet | 進階 ControlNet 時序控制 |
| 8 | controlnet_aux | ControlNet 前處理器（Canny/Depth/OpenPose/LineArt/SoftEdge/Seg） |
| 9 | IPAdapter_plus | 圖像提示適配器（人物/商品一致性） |
| 10 | UltimateSDUpscale | 分區高解析度放大（4K 輸出） |
| 11 | VideoHelperSuite | 影片載入/輸出/幀處理 |
| 12 | KJNodes | 實用工具節點（遮罩/圖像/排程） |
| 13 | AnimateDiff-Evolved | SD 模型動畫序列生成 |
| 14 | Crystools | 資源監控（VRAM/RAM/CPU 即時顯示） |
| 15 | efficiency-nodes | 效率節點（合併 KSampler 流程） |
| 16 | LayerStyle | 圖層混合與風格效果 |
| 17 | rgthree-comfy | 工作流組織（群組/便利節點） |
| 18 | was-node-suite | WAS 大型工具節點集 |
| 19 | FizzNodes | 動畫數值排程（Prompt Travel） |
| 20 | ReActor | 人臉替換（換臉） |
| 21 | WanVideoWrapper | Wan2.2 影片生成包裝器 |
| 22 | Frame-Interpolation | 影格插值補幀（RIFE/FILM） |

---

### 步驟 4：下載模型（互動式選單）

```powershell
.\03_download_models.ps1
```

**選單說明（依需求選擇，可多選）：**

| 選單 | 內容 | 估計大小 | 備註 |
|------|------|----------|------|
| `[1]` | ControlNet SD1.5（6 個模型） | ~9 GB | 建築/室內/人物控制 |
| `[2]` | ControlNet Union（SDXL + FLUX） | ~6 GB | 統一 ControlNet |
| `[3]` | IPAdapter + CLIP Vision | ~12 GB | 人物/商品一致性 |
| `[4]` | SDXL Checkpoints（RealVisXL + Juggernaut） | ~14 GB | 高品質靜態圖 |
| `[5]` | FLUX 模型（flux1-dev + Kontext-dev） | ~35 GB | **需 HuggingFace gated 授權** |
| `[6]` | Wan2.2 影片模型 | ~60 GB | AI 影片生成 |
| `[7]` | 其他影片（AnimateDiff / LTX / HunyuanVideo） | ~40 GB | 多元影片模型 |
| `[8]` | 放大模型（3 個） | ~0.3 GB | 超解析度放大 |
| `[A]` | 全部下載 | ~175 GB | 確認磁碟空間 ≥ 200 GB |

> **FLUX gated 模型注意事項：**
> 選單 5 需要 HuggingFace 帳號並已申請 `black-forest-labs` 模型存取權。
> 請先至 https://huggingface.co/black-forest-labs/FLUX.1-dev 接受授權，
> 並設定環境變數：`$env:HF_TOKEN = "your_token_here"`

> **FLUX Kontext Pro 注意事項：**
> `flux1-kontext-pro` 為 Black Forest Labs 的商業 API 模型，**無公開權重可下載**。
> 工作流中的 Kontext 功能使用 `flux1-kontext-dev`（開源版）運行。
> Pro 版需透過 BFL API（https://api.bfl.ml）付費使用。

---

### 步驟 5：啟動 ComfyUI 並驗證

```bat
cd C:\ComfyUI
python main.py --listen 0.0.0.0 --port 8188
```

> 32GB RTX 4080 **不需要** `--lowvram` 參數。
> 可加上 `--fast` 以啟用 PyTorch 編譯最佳化（需要 triton）。

開啟瀏覽器：`http://127.0.0.1:8188`

---

### 步驟 6：複製工作流（選擇性）

工作流 JSON 已在 `ComfyUI_Workflows/` 目錄中，可手動拖曳到 ComfyUI 介面載入，
或複製到 ComfyUI 的 workflows 目錄：

```powershell
Copy-Item -Recurse "C:\ComfyUI\ComfyUI-Workstation\ComfyUI_Workflows\*" `
          "C:\ComfyUI\user\default\workflows\" -Force
```

---

## 執行後驗證檢查表

### 環境層級

- [ ] `01_check_environment.ps1` 全部項目顯示 **[OK]**（綠色）
- [ ] `nvidia-smi` 顯示 GPU：NVIDIA RTX 4080，VRAM 約 32 GB
- [ ] ComfyUI 啟動後，終端機最後一行顯示 `Starting server`，無 CUDA 錯誤
- [ ] 瀏覽器可正常開啟 `http://127.0.0.1:8188`
- [ ] Crystools 節點（若已安裝）顯示 GPU 型號與 VRAM 用量

### 自訂節點層級

- [ ] ComfyUI Manager 圖示可正常開啟（右上角或選單中）
- [ ] Manager → Custom Nodes Manager，以下 22 個節點全部顯示 **綠色（已安裝）**：
  - ComfyUI-Manager、Impact-Pack（含 Impact-Subpack）、essentials、Inspire-Pack
  - Easy-Use、Custom-Scripts、Advanced-ControlNet、controlnet_aux
  - IPAdapter_plus、UltimateSDUpscale、VideoHelperSuite、KJNodes
  - AnimateDiff-Evolved、Crystools、efficiency-nodes、LayerStyle
  - rgthree-comfy、was-node-suite、FizzNodes、ReActor、WanVideoWrapper、Frame-Interpolation
- [ ] 右鍵搜尋節點可找到 `FaceDetailer`（屬 Impact Pack 內建）
- [ ] 右鍵搜尋節點可找到 `IPAdapterAdvanced`
- [ ] 右鍵搜尋節點可找到 `WanVideoSampler` 或相關 Wan 節點

### 模型層級

- [ ] `ComfyUI/models/checkpoints/` 下有 `.safetensors` 檔案
- [ ] `ComfyUI/models/controlnet/` 下有 ControlNet 模型
- [ ] `ComfyUI/models/ipadapter/` 下有 ip-adapter 相關檔案
- [ ] `ComfyUI/models/upscale_models/` 下有放大模型 `.pth` 檔案
- [ ] 工作流的 Checkpoint Loader 下拉選單可看到模型名稱（非空白）

### 工作流執行驗證

- [ ] 載入 `Church/Church_Design.json`（需求資源最少，適合首次驗證）
- [ ] 工作流所有節點正常連線（無紅色邊框錯誤節點）
- [ ] 填入測試提示詞，點擊 **Queue Prompt**
- [ ] 執行完成，圖片顯示於右側預覽區域
- [ ] `ComfyUI/output/` 資料夾中有新圖像檔案產生
- [ ] 終端機無 `CUDA out of memory` 或 `RuntimeError` 訊息

### 效能基準記錄

完成後建議記錄以下基準數值，作為日後調校依據：

| 工作流 | 步驟數 | RTX 4080 32GB 預期時間 | 您的實際時間 |
|--------|--------|----------------------|-------------|
| Church_Design（FLUX 20步） | 20 | ~30–45 秒 | ___________ |
| Interior_Design_Pro（SDXL 30步） | 30 | ~20–30 秒 | ___________ |
| Character_Consistency（SDXL+IPAdapter） | 30 | ~25–35 秒 | ___________ |
| Architecture_Pro（FLUX+ControlNet） | 20 | ~40–60 秒 | ___________ |

---

## 重要限制說明

### 影片長度限制

**Wan2.2 每次生成最多約 81 幀（約 5 秒，24fps）。**

60 秒影片需分 12 段生成，120 秒影片需分 24 段生成。
完成後使用 Frame-Interpolation 補幀，再以影片編輯軟體（DaVinci Resolve、Premiere Pro）串接。

這是目前所有主流 AI 影片模型的共同限制，並非本套件問題。

### FLUX Kontext Pro

`flux1-kontext-pro` 為商業 API 模型，本套件工作流使用 `flux1-kontext-dev`（開源授權版）。
若需 Pro 級品質，請另外申請 BFL API Key。

---

## 預期常見問題與排除

| 問題現象 | 可能原因 | 排除方向 |
|---------|---------|---------|
| 節點安裝失敗（git clone error） | 網路不穩 / Git 版本過舊 | 手動 `git clone` 個別節點到 `custom_nodes/` |
| FLUX 下載 401 / 403 錯誤 | 未設定 HF Token 或未申請 gated | 設定 `$env:HF_TOKEN`，至 HF 申請存取 |
| ComfyUI 啟動後出現紅色節點 | 自訂節點未安裝或 Python 套件缺失 | Manager → 重新安裝對應節點 |
| CUDA out of memory | 多模型同時載入、解析度過高 | 關閉其他 GPU 程式，重啟 ComfyUI |
| Wan2.2 影片輸出黑畫面 | VAE 未正確載入或路徑錯誤 | 確認 `wan_2.1_vae.safetensors` 在 `models/vae/` |
| FaceDetailer 節點找不到 | Impact-Subpack 未完整安裝 | Manager 重新安裝 Impact-Pack（確認含 Subpack）|
| PowerShell 執行被拒絕 | 執行原則限制 | 以管理員執行 `Set-ExecutionPolicy RemoteSigned` |
| 下載速度極慢 | 部分模型伺服器限速 | 使用 aria2c 或離峰時段下載 |

詳細排錯步驟請參閱：[docs/06_troubleshooting.md](../docs/06_troubleshooting.md)

---

## 套件版本資訊

| 元件 | 版本/資訊 |
|------|---------|
| 套件產生日期 | 2026-06-10（雲端環境） |
| 目標 ComfyUI 版本 | 最新穩定版（建議 2025-01 以後的 commit） |
| 目標 Python 版本 | 3.10 / 3.11 |
| 目標 PyTorch 版本 | 2.4.x（CUDA 12.1）或 2.5.x |
| 自訂節點數量 | 22 個 |
| 工作流數量 | 7 個 |
| 文件數量 | 6 份 |

---

*本報告由 ComfyUI 工作站部署套件產生於雲端 Linux 容器。*
*實際安裝需由使用者在本機 Windows 11 RTX 4080 機器上執行。*
*如有問題，請參閱 `docs/06_troubleshooting.md` 或聯絡套件維護者。*
