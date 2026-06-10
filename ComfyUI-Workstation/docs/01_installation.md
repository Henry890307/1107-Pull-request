# ComfyUI 工作站完整安裝流程

> 硬體規格：Intel i5-13500 / RTX 4080 32GB VRAM（特規）/ 96GB RAM / Windows 11

---

## 目錄

1. [安裝 NVIDIA Studio 驅動](#1-安裝-nvidia-studio-驅動)
2. [安裝 ComfyUI](#2-安裝-comfyui)
3. [執行環境檢查腳本](#3-執行環境檢查腳本-01_check_environmentps1)
4. [安裝自訂節點](#4-安裝自訂節點-02_install_custom_nodesbat)
5. [HuggingFace 登入與 Gated 模型授權](#5-huggingface-登入與-gated-模型授權)
6. [下載模型](#6-下載模型-03_download_modelsps1)
7. [建立資料夾結構](#7-建立資料夾結構-04_create_foldersbat)
8. [重啟與載入工作流](#8-重啟與載入工作流)
9. [確認 CUDA / Torch 正確安裝](#9-確認-cuda--torch-正確安裝)
10. [重裝 PyTorch cu124](#10-重裝-pytorch-cu124)

---

## 1. 安裝 NVIDIA Studio 驅動

### 為何選 Studio 驅動而非 Game Ready？

Studio 驅動針對 AI 生成、創作工作流優化，穩定性更高，推薦用於長時間推理任務。Game Ready 驅動以遊戲效能為優先，更新頻率高但較易出現相容性問題。

### 安裝步驟

1. 前往 [NVIDIA 驅動下載頁面](https://www.nvidia.com/Download/index.aspx)
2. 產品類型選 **GeForce**，產品系列選 **GeForce RTX 40 Series**，型號選 **GeForce RTX 4080**
3. 作業系統選 **Windows 11 64-bit**，下載類型選 **Studio Driver (SD)**
4. 下載並執行安裝程式，選擇「自訂安裝」→「全新安裝」以清除舊驅動殘留
5. 安裝完畢後重新開機

### 確認驅動版本

```powershell
nvidia-smi
```

輸出應顯示驅動版本（建議 >= 555.xx）及 CUDA 版本（應顯示 12.x）。範例：

```
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 560.94   Driver Version: 560.94   CUDA Version: 12.6            |
+-----------------------------------------------------------------------------+
| GPU 0: NVIDIA GeForce RTX 4080  ... | 32510 MiB |
+-----------------------------------------------------------------------------+
```

> **注意**：nvidia-smi 顯示的 CUDA 版本是驅動支援的最高版本，不代表已安裝的 CUDA Toolkit 版本。PyTorch 的 CUDA 版本（cu124）是獨立打包的。

---

## 2. 安裝 ComfyUI

有三種安裝方式，依需求選擇：

### 方式 A：可攜版（推薦新手）

1. 前往 [ComfyUI Releases](https://github.com/comfyanonymous/ComfyUI/releases)
2. 下載最新 `ComfyUI_windows_portable_nvidia.7z`（約 1.5 GB）
3. 解壓到目標磁碟（建議 SSD，如 `D:\ComfyUI`）；路徑不可包含中文或空格
4. 執行 `run_nvidia_gpu.bat` 啟動

> 可攜版內建 Python 3.11 環境與 cu124 PyTorch，無需額外安裝 Python，適合快速上手。但升級彈性較低，遇到複雜環境問題時較難排查。

### 方式 B：ComfyUI 桌面版（Desktop App）

1. 前往 [ComfyUI Desktop Releases](https://github.com/Comfy-Org/desktop/releases) 下載最新 `.exe`
2. 執行安裝程式，依精靈完成設定
3. 桌面版自動管理 Python 環境，適合一般使用者
4. 自訂節點路徑位於 `%APPDATA%\ComfyUI\custom_nodes\`

> 桌面版無法直接指定啟動參數（如 `--lowvram`），若需精細控制建議改用 Git 版。

### 方式 C：Git 手動安裝（推薦進階使用者）

```powershell
# 先確認已安裝 Git（https://git-scm.com/）與 Python 3.11 或 3.12
git --version
python --version

# Clone ComfyUI 至 SSD
git clone https://github.com/comfyanonymous/ComfyUI.git D:\ComfyUI
cd D:\ComfyUI

# 建立虛擬環境（強烈建議，避免污染系統 Python）
python -m venv venv
.\venv\Scripts\activate

# 安裝依賴（requirements.txt 的 PyTorch 版本可能不含 cu124，需後續重裝）
pip install -r requirements.txt
```

> Python 版本建議 **3.11** 或 **3.12**，避免使用 3.13（部分套件如 insightface 尚未支援）。

---

## 3. 執行環境檢查腳本（01_check_environment.ps1）

此腳本會自動偵測並回報環境狀態，協助在正式安裝前發現潛在問題。

### 執行方式

```powershell
# 以系統管理員身分開啟 PowerShell（右鍵 → 以系統管理員執行）
# 首次執行需解除執行原則限制
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# 切換至 install 目錄
cd C:\path\to\ComfyUI-Workstation\install
.\01_check_environment.ps1
```

### 腳本檢查項目

| 檢查項目 | 正常顯示 |
|---|---|
| Python 版本 | `[OK] Python 3.11.x` 或 `3.12.x` |
| pip 版本 | `[OK] pip 24.x` |
| NVIDIA 驅動 | `[OK] Driver 5xx.xx` |
| CUDA 版本（nvidia-smi）| `[OK] CUDA 12.x` |
| PyTorch 安裝 | `[OK] PyTorch 2.x.x+cu124` |
| PyTorch CUDA 可用 | `[OK] torch.cuda.is_available() = True` |
| GPU 偵測 | `[OK] NVIDIA GeForce RTX 4080` |
| VRAM 容量 | `[OK] 32.x GB` |
| ComfyUI 目錄 | `[OK] Found at D:\ComfyUI` |
| 虛擬環境 | `[OK] venv activated` |

若出現 `[WARN]` 或 `[ERROR]` 標記，依提示修正後再繼續下一步。

---

## 4. 安裝自訂節點（02_install_custom_nodes.bat）

此腳本透過 ComfyUI-Manager 或直接 `git clone`，安裝本套件所需的全部自訂節點。

### 執行方式

```bat
REM 切換至 install 目錄後執行
cd C:\path\to\ComfyUI-Workstation\install
02_install_custom_nodes.bat
```

### 安裝節點清單

| 節點名稱 | 功能 | 對應教學 |
|---|---|---|
| ComfyUI-Manager | 節點管理、更新、修復入口 | 全部 |
| comfyui_controlnet_aux | ControlNet 預處理器（Canny、Depth、OpenPose 等）| 02_controlnet.md |
| ComfyUI_IPAdapter_plus | IPAdapter 人物一致性與 FaceID | 03_ipadapter.md |
| ComfyUI-VideoHelperSuite (VHS) | 影片載入、分幀、輸出 | 05_wan22.md |
| ComfyUI-WanVideoWrapper | Wan 2.2 影片生成節點 | 05_wan22.md |
| ComfyUI-KJNodes | 各種實用工具節點 | 全部 |
| rgthree-comfy | Power Lora Loader 等高效工具 | 全部 |
| ComfyUI_essentials | 基礎實用節點補強 | 全部 |
| was-node-suite-comfyui | WAS 文字、影像工具節點集 | 全部 |
| ComfyUI-GGUF | GGUF 量化模型載入支援 | 04_flux.md |

> 安裝完畢後，重新啟動 ComfyUI。若有節點顯示紅框（import 失敗），請參閱 [06_troubleshooting.md](./06_troubleshooting.md)。

---

## 5. HuggingFace 登入與 Gated 模型授權

部分模型屬於 **Gated Repository**（需授權才能下載），包括：

- **FLUX.1-dev**（black-forest-labs/FLUX.1-dev）
- **FLUX.1-Kontext-dev**（black-forest-labs/FLUX.1-Kontext-dev）

> **重要說明**：FLUX Kontext **Pro** 是 API 服務，沒有公開權重；本地使用請以 **flux1-kontext-dev.safetensors** 為主。

### 步驟一：同意模型授權協議

分別前往以下頁面，登入 HuggingFace 後點擊「**Agree and access repository**」：

- FLUX.1-dev：https://huggingface.co/black-forest-labs/FLUX.1-dev
- FLUX.1-Kontext-dev：https://huggingface.co/black-forest-labs/FLUX.1-Kontext-dev

授權審核通常即時生效；若仍出現 403 錯誤，等待幾分鐘後重試。

### 步驟二：取得 HuggingFace Access Token

1. 登入 HuggingFace，右上角頭像 → **Settings** → **Access Tokens**
2. 點擊 **New token**，類型選 **Read**，輸入名稱（如 `comfyui-workstation`）
3. 建立後複製 Token（格式為 `hf_xxxxxxxxxxxxxxxxxx`，僅顯示一次）

### 步驟三：在終端機登入 huggingface-cli

```powershell
# 啟動虛擬環境（Git 版）
.\venv\Scripts\activate

# 安裝 huggingface_hub（若尚未安裝）
pip install huggingface_hub

# 登入，輸入 Token 後按 Enter
huggingface-cli login

# 確認登入狀態
huggingface-cli whoami
# 應顯示你的 HuggingFace 使用者名稱
```

### 可攜版登入方式

```bat
.\python_embeded\python.exe -m pip install huggingface_hub
.\python_embeded\python.exe -m huggingface_hub login
```

---

## 6. 下載模型（03_download_models.ps1）

此腳本提供互動式分類選單，可按需求選擇性下載各類模型。

### 執行方式

```powershell
cd C:\path\to\ComfyUI-Workstation\install
.\03_download_models.ps1
```

### 選單說明與磁碟空間估算

| 選單編號 | 模型內容 | 放置路徑 | 估計大小 |
|---|---|---|---|
| 1 | FLUX.1-dev（flux1-dev.safetensors）| diffusion_models/ | ~24 GB |
| 2 | FLUX.1-Kontext-dev（flux1-kontext-dev.safetensors）| diffusion_models/ | ~24 GB |
| 3 | FLUX T5 Encoder（t5xxl_fp16.safetensors）| clip/ | ~9.3 GB |
| 4 | FLUX CLIP-L（clip_l.safetensors）| clip/ | ~246 MB |
| 5 | FLUX VAE（flux_ae.safetensors）| vae/ | ~335 MB |
| 6 | ControlNet SD1.5 全套（6 種）| controlnet/ | ~14 GB |
| 7 | ControlNet SDXL Union ProMax | controlnet/ | ~5 GB |
| 8 | ControlNet FLUX Union Pro 2.0 | controlnet/ | ~9 GB |
| 9 | IPAdapter Plus（SDXL 系列）| ipadapter/ | ~5 GB |
| 10 | IPAdapter FaceID（含 LoRA）| ipadapter/ + loras/ | ~6 GB |
| 11 | CLIP Vision（IPAdapter 必要）| clip_vision/ | ~1.7 GB |
| 12 | Wan 2.2 T2V 14B（高/低噪音雙模）| diffusion_models/ | ~55 GB |
| 13 | Wan 2.2 I2V 14B（高/低噪音雙模）| diffusion_models/ | ~55 GB |
| 14 | Wan 2.2 VAE + UMT5 Encoder | vae/ + clip/ | ~12 GB |
| 15 | 放大模型（4x-UltraSharp 等）| upscale_models/ | ~300 MB |
| 99 | 全部下載 | 各對應路徑 | **~約 240 GB** |

### 磁碟空間規劃建議

- **全套約 240 GB**，強烈建議放置於 **NVMe SSD**（機械硬碟讀取速度過慢，模型載入會耗費數分鐘）
- 建議配置：512 GB SSD 專用於模型，另備 256 GB 供 ComfyUI 程式與輸出使用
- 若預算有限，優先下載：選項 1~5（FLUX 基礎）+ 選項 6（ControlNet SD1.5）= 約 70 GB

### 模型正規路徑結構

```
ComfyUI/models/
├── checkpoints/           ← SD1.5 / SDXL checkpoint（.safetensors）
├── diffusion_models/      ← FLUX 主擴散模型（flux1-dev, kontext-dev）
├── clip/                  ← Text Encoder（t5xxl_fp16, clip_l）
├── vae/                   ← VAE（flux_ae, sdxl_vae 等）
├── controlnet/            ← ControlNet 模型
├── ipadapter/             ← IPAdapter 模型
├── clip_vision/           ← CLIP Vision（IPAdapter 所需）
├── upscale_models/        ← 放大模型
├── animatediff_models/    ← AnimateDiff 動態模塊
└── loras/                 ← LoRA 模型
```

---

## 7. 建立資料夾結構（04_create_folders.bat）

此腳本建立所有必要的目錄結構，確保 ComfyUI 能正確掃描模型，並為輸出檔案提供整齊的存放位置。

```bat
cd C:\path\to\ComfyUI-Workstation\install
04_create_folders.bat
```

腳本建立內容：
- 完整的 `ComfyUI/models/` 子目錄樹
- `ComfyUI/output/images/`、`output/videos/`、`output/upscaled/`
- `ComfyUI/input/`（放置輸入參考圖片用）

---

## 8. 重啟與載入工作流

### 啟動 ComfyUI

**可攜版：**
```bat
D:\ComfyUI\run_nvidia_gpu.bat
```

**Git 版：**
```powershell
cd D:\ComfyUI
.\venv\Scripts\activate
python main.py --listen 0.0.0.0 --port 8188
```

**桌面版：** 直接點擊桌面圖示。

啟動後開啟瀏覽器前往 [http://127.0.0.1:8188](http://127.0.0.1:8188)

### 確認節點全部載入

啟動時觀察 console 輸出，若出現類似以下訊息表示正常：
```
Total VRAM 32510 MB, total RAM 98304 MB
xformers version: 0.0.28
```

若看到紅色節點，開啟 ComfyUI Manager → **Install Missing Custom Nodes** 後重啟。

### 載入工作流

1. 在 ComfyUI 介面左側點擊「**Load**」按鈕
2. 導向 `ComfyUI_Workflows/` 目錄
3. 選擇對應工作流的 `.json` 檔案

| 工作流檔案 | 功能 | 對應教學 |
|---|---|---|
| 01_flux_txt2img.json | FLUX 文字生圖 | 04_flux.md |
| 02_flux_kontext_edit.json | FLUX Kontext 影像編輯 | 04_flux.md |
| 03_controlnet_interior.json | ControlNet 室內設計（雙 ControlNet）| 02_controlnet.md |
| 04_ipadapter_portrait.json | IPAdapter 人物一致性 | 03_ipadapter.md |
| 05_wan22_t2v.json | Wan 2.2 文字生影片 | 05_wan22.md |
| 06_wan22_i2v.json | Wan 2.2 圖片生影片 | 05_wan22.md |
| 07_upscale.json | 4x 圖片放大 | - |

---

## 9. 確認 CUDA / Torch 正確安裝

在 ComfyUI 的 Python 環境中執行以下指令：

```powershell
# Git 版（啟動虛擬環境後執行）
python -c "
import torch
print('PyTorch 版本:', torch.__version__)
print('CUDA 可用:', torch.cuda.is_available())
print('CUDA 版本:', torch.version.cuda)
print('GPU 數量:', torch.cuda.device_count())
print('GPU 名稱:', torch.cuda.get_device_name(0))
vram = torch.cuda.get_device_properties(0).total_memory / 1024**3
print(f'VRAM: {vram:.1f} GB')
"
```

### 預期輸出（cu124 正常環境）

```
PyTorch 版本: 2.4.1+cu124
CUDA 可用: True
CUDA 版本: 12.4
GPU 數量: 1
GPU 名稱: NVIDIA GeForce RTX 4080
VRAM: 32.0 GB
```

### 在 ComfyUI console 中快速確認

ComfyUI 啟動時 console 會輸出：
```
Total VRAM 32510 MB, total RAM 98304 MB
PyTorch version: 2.4.1+cu124
```

若 `CUDA 可用: False` 或版本不含 `+cu124`，請執行下一節的重裝步驟。

---

## 10. 重裝 PyTorch cu124

若 PyTorch 安裝為 CPU 版本（`+cpu`）或 CUDA 版本不符（非 cu124），依以下步驟重裝：

### Git 版重裝

```powershell
# 啟動虛擬環境
cd D:\ComfyUI
.\venv\Scripts\activate

# 卸載現有 PyTorch
pip uninstall torch torchvision torchaudio -y

# 安裝 cu124 版本（CUDA 12.4 對應 PyTorch 2.4/2.5）
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# 確認結果
python -c "import torch; print(torch.__version__, torch.cuda.is_available())"
# 預期：2.4.1+cu124 True
```

### 可攜版重裝

```bat
REM 在 ComfyUI 可攜版根目錄執行
.\python_embeded\python.exe -m pip uninstall torch torchvision torchaudio -y
.\python_embeded\python.exe -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
```

### xFormers 安裝（選用）

xFormers 加速 Attention 計算，建議安裝（需與 PyTorch 版本對應）：

```powershell
pip install xformers --index-url https://download.pytorch.org/whl/cu124
```

安裝後在 ComfyUI 啟動時可見：
```
xformers version: 0.0.28
```

> 本工作站 RTX 4080 32GB VRAM 充裕，xFormers 在 SD1.5/SDXL 上效益明顯；FLUX 因使用 FlashAttention2 架構，效益相對有限但仍可安裝。

### xFormers 版本衝突排除

若安裝後出現衝突錯誤，可指定版本：
```powershell
pip install xformers==0.0.28.post1 --index-url https://download.pytorch.org/whl/cu124
```

詳細版本衝突排除請見 [06_troubleshooting.md](./06_troubleshooting.md)。

---

## 附錄 A：一鍵安裝腳本

若不想分步執行，可直接使用：

```bat
cd C:\path\to\ComfyUI-Workstation\install
install_all.bat
```

腳本依序執行：
1. 環境檢查（01）
2. 安裝自訂節點（02）
3. 建立資料夾（04）
4. 提示 HuggingFace 登入
5. 顯示模型下載選單（03）

---

## 附錄 B：常用啟動參數

| 參數 | 說明 | 適用情境 |
|---|---|---|
| `--lowvram` | 積極卸載模型至 RAM | VRAM < 8GB |
| `--normalvram` | 預設行為 | VRAM 8~16GB |
| `--highvram` | 盡量保留模型在 VRAM | VRAM >= 24GB |
| `--fp16-vae` | VAE 使用 fp16 | 減少 VRAM 佔用 |
| `--disable-xformers` | 停用 xFormers | 偵錯時使用 |
| `--listen 0.0.0.0` | 允許區域網路存取 | 多機存取 |
| `--port 8188` | 指定埠號 | 多實例並行 |
| `--cuda-device 0` | 指定 GPU | 多 GPU 系統 |

> 本工作站 RTX 4080 32GB VRAM 充裕，預設啟動即可；需要長影片生成時建議加 `--highvram`。

---

## 附錄 C：安裝常見問題速查

| 問題現象 | 原因 | 解法 |
|---|---|---|
| pip 下載極慢 | 預設伺服器距離遠 | 使用 VPN 或換鏡像站 |
| git clone 失敗 | 網路限制 | 手動下載 zip 或使用 VPN |
| 403 Forbidden（HF）| 未登入或未授權 | 執行 `huggingface-cli login` |
| CUDA not available | CPU 版 PyTorch | 執行第 10 節重裝 |
| 模型下拉選單空白 | 路徑錯誤或資料夾不存在 | 確認放至正確子目錄 |
| 節點出現紅框 | 自訂節點 import 失敗 | 見 06_troubleshooting.md |
| PowerShell 拒絕執行 | 執行原則限制 | 執行 `Set-ExecutionPolicy RemoteSigned` |

---

> 下一步：閱讀 [02_controlnet.md](./02_controlnet.md) 學習 ControlNet 使用方式。
