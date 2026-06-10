# ComfyUI 工作站部署套件 — 安裝完成報告

> 版本：1.0.0 | 產生日期：2026-06-10 | 目標主機：Windows 11 / RTX 4080 32GB

---

## 重要聲明：套件性質說明

**本套件是在雲端 Linux 容器中產生的「完整部署套件」，尚未在使用者的 Windows 機器上實際執行安裝。**

套件內容包含：
- 安裝腳本（PowerShell / Batch）
- 工作流 JSON 檔案（7 個）
- 說明文件（6 份）
- 模型下載腳本（含分項選單）

**使用者需依照本報告的步驟，在自己的 RTX 4080 機器上執行 `install/` 內的腳本，才能完成實際安裝。**

---

## 已備妥內容清單

| 項目 | 狀態 | 說明 |
|------|------|------|
| `install/01_check_environment.ps1` | 已備妥 | 環境前置檢查（Python、Git、CUDA、VRAM）|
| `install/02_install_custom_nodes.bat` | 已備妥 | 22 個自訂節點批次安裝 |
| `install/03_download_models.ps1` | 已備妥 | 8 個選單分項下載模型 |
| `install/04_create_folders.bat` | 已備妥 | 建立 ComfyUI models/ 完整資料夾結構 |
| `install/install_all.bat` | 已備妥 | 一鍵全流程執行主入口 |
| `install/generate_workflows.py` | 已備妥 | 產生並寫入 7 個工作流 JSON |
| `ComfyUI_Workflows/` | 已備妥 | 7 個分類工作流 + 各自 README |
| `docs/01_installation.md` | 已備妥 | 完整安裝教學 |
| `docs/02_controlnet_guide.md` | 已備妥 | ControlNet 使用教學 |
| `docs/03_ipadapter_guide.md` | 已備妥 | IPAdapter 使用教學 |
| `docs/04_flux_guide.md` | 已備妥 | FLUX 模型使用教學 |
| `docs/05_wan_video_guide.md` | 已備妥 | Wan2.2 影片生成教學 |
| `docs/06_troubleshooting.md` | 已備妥 | 常見問題排除 |

---

## 目標硬體規格

| 項目 | 規格 |
|------|------|
| CPU | Intel i5-13500 |
| GPU | 特規 RTX 4080 32GB VRAM（Ada Lovelace AD103, sm_89）|
| RAM | 96 GB DDR5 |
| 作業系統 | Windows 11 |
| 主要用途 | 建築渲染、室內設計、人物一致性、商品廣告、AI 影片、教會海報 |

---

## 使用者需執行的步驟清單

### 前置作業（手動確認）

- [ ] **Step 0-A**：確認已安裝 ComfyUI 主程式  
  下載：https://github.com/comfyanonymous/ComfyUI  
  建議路徑：`C:\ComfyUI\`

- [ ] **Step 0-B**：確認已安裝 Python 3.10 或 3.11（64-bit）  
  驗證：`python --version`

- [ ] **Step 0-C**：確認已安裝 Git for Windows  
  下載：https://git-scm.com/download/win

- [ ] **Step 0-D**：確認已安裝 NVIDIA CUDA Toolkit 12.x  
  驗證：`nvcc --version`

- [ ] **Step 0-E**：確認 GPU 驅動版本 ≥ 535.x（支援 CUDA 12）  
  驗證：`nvidia-smi`

---

### 正式安裝步驟

#### 方法 A：一鍵安裝（推薦）

```
1. 以「系統管理員」身份開啟命令提示字元（cmd）
2. 切換到本套件 install/ 資料夾：
   cd C:\path\to\ComfyUI-Workstation\install
3. 執行主安裝腳本：
   install_all.bat
4. 依照畫面提示選擇要下載的模型選單（可多選）
5. 等待所有下載與安裝完成
```

#### 方法 B：分步執行（遇到問題時使用）

- [ ] **Step 1**：執行環境檢查
  ```powershell
  # 以系統管理員開啟 PowerShell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  cd C:\path\to\ComfyUI-Workstation\install
  .\01_check_environment.ps1
  ```
  預期結果：所有項目顯示 [OK] 或 [PASS]

- [ ] **Step 2**：安裝自訂節點（22 個）
  ```
  .\02_install_custom_nodes.bat
  ```
  預期結果：每個節點 git clone + pip install 成功，最後顯示「22/22 nodes installed」

- [ ] **Step 3**：建立資料夾結構
  ```
  .\04_create_folders.bat
  ```
  預期結果：`ComfyUI/models/` 下建立 controlnet/, ipadapter/, checkpoints/ 等資料夾

- [ ] **Step 4**：下載模型（依需求選擇）
  ```powershell
  .\03_download_models.ps1
  ```
  選單說明：
  - `[1]` ControlNet SD1.5（6 個，約 9 GB）
  - `[2]` ControlNet Union SDXL + FLUX（約 6 GB）
  - `[3]` IPAdapter + CLIP Vision（約 12 GB）
  - `[4]` SDXL Checkpoints（RealVisXL + Juggernaut，約 14 GB）
  - `[5]` FLUX 模型（需 HuggingFace token，約 35 GB）
  - `[6]` Wan2.2 影片模型（約 60 GB）
  - `[7]` 其他影片模型（AnimateDiff / LTX-Video / HunyuanVideo，約 40 GB）
  - `[8]` 放大模型（約 0.3 GB）
  - `[A]` 全部下載（約 175 GB，確認磁碟空間足夠）

  > **FLUX Gated 模型注意事項**：選單 5 需要 HuggingFace 帳號並申請存取權限。  
  > 請先至 https://huggingface.co/black-forest-labs/FLUX.1-dev 點選「Request access」。

- [ ] **Step 5**：產生工作流 JSON
  ```
  python generate_workflows.py
  ```
  預期結果：7 個工作流 JSON 寫入 `ComfyUI/user/default/workflows/` 或 `ComfyUI_Workflows/`

---

### 啟動 ComfyUI

```batch
cd C:\ComfyUI
python main.py --listen 0.0.0.0 --port 8188
```

> 建議加上 `--lowvram` 只在 VRAM < 8GB 的機器。32GB RTX 4080 不需要。  
> 可加上 `--fast` 啟用 PyTorch 最佳化。  
> 開啟瀏覽器：http://127.0.0.1:8188

---

## 執行後驗證檢查表

完成安裝後，請逐一確認以下項目：

### 環境層級

- [ ] `01_check_environment.ps1` 執行後，所有項目顯示綠色 [OK]
- [ ] `nvidia-smi` 顯示 GPU：NVIDIA RTX 4080，記憶體 32 GB
- [ ] `nvcc --version` 顯示 CUDA 12.x
- [ ] ComfyUI 啟動後，終端機無 CUDA 錯誤

### 自訂節點層級

- [ ] 開啟 ComfyUI → 右上角 Manager 圖示可正常開啟
- [ ] Manager → 「Custom Nodes Manager」頁面中，以下節點全部顯示為已安裝（綠色）：
  - ComfyUI-Manager
  - Impact-Pack（含 Impact-Subpack）
  - essentials
  - Inspire-Pack
  - Easy-Use
  - Custom-Scripts
  - Advanced-ControlNet
  - controlnet_aux
  - IPAdapter_plus
  - UltimateSDUpscale
  - VideoHelperSuite
  - KJNodes
  - AnimateDiff-Evolved
  - Crystools
  - efficiency-nodes
  - LayerStyle
  - rgthree-comfy
  - was-node-suite
  - FizzNodes
  - ReActor
  - WanVideoWrapper
  - Frame-Interpolation

### 模型層級

- [ ] `ComfyUI/models/checkpoints/` 下存在至少一個 .safetensors 檔案
- [ ] `ComfyUI/models/controlnet/` 下存在至少一個 controlnet 模型
- [ ] ComfyUI 啟動後，右鍵 → Add Node → Load Checkpoint，下拉選單中可見模型名稱

### 工作流層級

- [ ] 載入 `Architecture/Architecture_Pro.json`，工作流節點全部正常連線（無紅色錯誤節點）
- [ ] 點選 Queue Prompt，成功執行完整推理並輸出圖片
- [ ] 輸出圖片顯示於 ComfyUI 右側面板
- [ ] 終端機無 OOM（Out of Memory）錯誤

### 效能基準

完成後可記錄以下基準數值，作為日後比較依據：

| 工作流 | 預期步驟數 | 預期時間 | 實際時間 |
|--------|-----------|---------|---------|
| Architecture_Pro（FLUX 20步）| 20 | ~45 秒 | ___ |
| Interior_Design_Pro（SDXL 30步）| 30 | ~25 秒 | ___ |
| Character_Consistency（SDXL 30步）| 30 | ~30 秒 | ___ |

---

## 預期常見問題與排除

| 問題現象 | 可能原因 | 排除方向 |
|---------|---------|---------|
| 節點安裝失敗（git error）| 網路不穩 / Git 版本過舊 | 手動 `git clone` 個別節點 |
| FLUX 模型下載 401 錯誤 | 未設定 HF token / 未申請 gated | 至 HuggingFace 申請並設定 `HF_TOKEN` 環境變數 |
| ComfyUI 啟動後紅色節點 | 對應自訂節點未安裝 | Manager → 搜尋節點名稱手動安裝 |
| CUDA out of memory | 多個模型同時載入 | 關閉其他 GPU 程式，重啟 ComfyUI |
| Wan2.2 影片黑畫面 | VAE 未正確載入 | 確認 `wan_2.1_vae` 存在於 `models/vae/` |
| FaceDetailer 節點找不到 | Impact-Subpack 未安裝 | Manager 重新安裝 Impact-Pack（含 Subpack）|

詳細排除步驟請參閱：[docs/06_troubleshooting.md](../docs/06_troubleshooting.md)

---

## 安裝套件版本資訊

| 元件 | 版本/說明 |
|------|---------|
| 套件產生日期 | 2026-06-10 |
| 目標 ComfyUI 版本 | 最新穩定版（建議 commit ≥ 2025-01）|
| Python 目標版本 | 3.10 / 3.11 |
| PyTorch 目標版本 | 2.4.x（CUDA 12.1）|
| 自訂節點數量 | 22 個 |
| 工作流數量 | 7 個 |
| 文件數量 | 6 份 |

---

*本報告由 ComfyUI 工作站部署套件自動產生。如有問題請聯絡套件維護者或參閱 docs/ 資料夾內的詳細文件。*
