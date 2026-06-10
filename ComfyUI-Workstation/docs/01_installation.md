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

Studio 驅動針對 AI 生成、創作工作流優化，穩定性更高，推薦用於長時間推理任務。

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

輸出應顯示驅動版本（建議 ≥ 555.xx）及 CUDA 版本（應顯示 12.x）。

---

## 2. 安裝 ComfyUI

有三種安裝方式，依需求選擇：

### 方式 A：可攜版（推薦新手）

1. 前往 [ComfyUI Releases](https://github.com/comfyanonymous/ComfyUI/releases)
2. 下載最新 `ComfyUI_windows_portable_nvidia.7z`
3. 解壓到目標磁碟（建議 SSD，如 `D:\ComfyUI`）
4. 執行 `run_nvidia_gpu.bat` 啟動

> 可攜版內建 Python 環境，無需額外安裝 Python，但升級彈性較低。

### 方式 B：ComfyUI 桌面版（Desktop App）

1. 前往 [ComfyUI Desktop](https://github.com/Comfy-Org/desktop/releases) 下載安裝程式
2. 執行 `.exe` 安裝，遵循精靈設定
3. 桌面版自動管理 Python 環境，適合一般使用者

> 桌面版的自訂節點路徑位於 `%APPDATA%\ComfyUI\`，請確認與本套件腳本路徑一致。

### 方式 C：Git 手動安裝（推薦進階使用者）

```powershell
# 確認已安裝 Git 與 Python 3.11 / 3.12
git --version
python --version

# Clone ComfyUI
git clone https://github.com/comfyanonymous/ComfyUI.git D:\ComfyUI
cd D:\ComfyUI

# 建立虛擬環境（強烈建議）
python -m venv venv
.\venv\Scripts\activate

# 安裝依賴
pip install -r requirements.txt
```

> Python 版本建議 **3.11** 或 **3.12**，避免使用 3.13（部分套件尚未支援）。

---

## 3. 執行環境檢查腳本（01_check_environment.ps1）

此腳本會自動偵測：
- Python 版本與路徑
- pip 版本
- CUDA 版本（透過 nvidia-smi）
- PyTorch 是否正確連結 CUDA
- 虛擬環境狀態
- ComfyUI 目錄是否存在

### 執行方式

```powershell
# 在 install/ 目錄下，以系統管理員執行 PowerShell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
.\install\01_check_environment.ps1
```

### 預期輸出範例

```
[OK] Python 3.11.9 detected
[OK] pip 24.x detected
[OK] NVIDIA Driver 560.xx, CUDA 12.4
[OK] PyTorch 2.x.x+cu124 - CUDA available: True
[OK] ComfyUI directory found at D:\ComfyUI
```

若出現 `[WARN]` 或 `[ERROR]`，依提示修正後再繼續。

---

## 4. 安裝自訂節點（02_install_custom_nodes.bat）

此腳本透過 ComfyUI Manager 或直接 git clone，安裝本套件所需的全部自訂節點：

| 節點名稱 | 用途 |
|---|---|
| ComfyUI-Manager | 節點管理、更新、修復 |
| comfyui_controlnet_aux | ControlNet 預處理器 |
| ComfyUI_IPAdapter_plus | IPAdapter 人物一致性 |
| ComfyUI-VideoHelperSuite (VHS) | 影片輸入輸出 |
| ComfyUI-KJNodes | 工具節點集合 |
| ComfyUI-AnimateDiff-Evolved | AnimateDiff 動畫 |
| was-node-suite-comfyui | WAS 工具節點 |
| ComfyUI_essentials | 常用工具節點 |

### 執行方式

```bat
.\install\02_install_custom_nodes.bat
```

> 腳本執行完畢後，重新啟動 ComfyUI，Manager 會自動偵測並安裝缺失依賴。

---

## 5. HuggingFace 登入與 Gated 模型授權

部分模型（FLUX.1-dev、Kontext-dev）屬於 **Gated Repository**，需要：
1. 擁有 HuggingFace 帳號
2. 至模型頁面同意授權協議
3. 在本機登入 `huggingface-cli`

### 步驟一：同意模型授權

前往以下頁面，登入後點擊「Agree and access repository」：

- FLUX.1-dev：https://huggingface.co/black-forest-labs/FLUX.1-dev
- FLUX.1-Kontext-dev：https://huggingface.co/black-forest-labs/FLUX.1-Kontext-dev

> 授權審核通常即時生效，若仍顯示無法下載，等待幾分鐘後重試。

### 步驟二：取得 Access Token

1. 登入 HuggingFace → 右上角頭像 → Settings → Access Tokens
2. 建立新 Token，類型選 **Read**
3. 複製 Token（只顯示一次）

### 步驟三：在終端機登入

```powershell
# 安裝 huggingface_hub（若尚未安裝）
pip install huggingface_hub

# 登入
huggingface-cli login
# 貼上 Token 後按 Enter
```

### 步驟四：確認登入狀態

```powershell
huggingface-cli whoami
# 應顯示你的 HuggingFace 使用者名稱
```

---

## 6. 下載模型（03_download_models.ps1）

此腳本提供分類選單，可選擇性下載各類模型。

### 執行方式

```powershell
.\install\03_download_models.ps1
```

### 選單說明與磁碟空間估算

| 選單項目 | 模型內容 | 估計大小 |
|---|---|---|
| 1. FLUX 基礎模型 | flux1-dev.safetensors (diffusion_models) | ~24 GB |
| 2. FLUX Kontext-dev | flux1-kontext-dev.safetensors (diffusion_models) | ~24 GB |
| 3. FLUX Text Encoders | t5xxl_fp16.safetensors + clip_l.safetensors (clip) | ~10 GB |
| 4. FLUX VAE | flux_ae.safetensors (vae) | ~335 MB |
| 5. ControlNet SD1.5 | canny/depth/openpose/lineart/softedge/seg | ~14 GB |
| 6. ControlNet SDXL | controlnet-union-sdxl-1.0-promax | ~5 GB |
| 7. ControlNet FLUX | FLUX.1-dev-ControlNet-Union-Pro-2.0 | ~9 GB |
| 8. IPAdapter PLUS | ip-adapter-plus 系列 + clip_vision | ~8 GB |
| 9. IPAdapter FaceID | ip-adapter-faceid 系列 + LoRA | ~6 GB |
| 10. Wan 2.2 T2V | Wan2.2-T2V-14B 完整模型 | ~55 GB |
| 11. Wan 2.2 I2V | Wan2.2-I2V-14B 完整模型 | ~55 GB |
| 12. Upscale 模型 | 4x-UltraSharp / RealESRGAN 等 | ~300 MB |
| 99. 全部下載 | 以上全部 | ~約 240 GB |

> **建議**：模型全放 SSD（NVMe 優先），機械硬碟讀取速度會嚴重拖慢載入時間。

### 模型放置路徑（ComfyUI/models/ 下）

```
models/
├── checkpoints/        ← SD 系列 checkpoint
├── diffusion_models/   ← FLUX diffusion 主檔
├── clip/               ← FLUX text encoders (t5, clip_l)
├── vae/                ← VAE 檔案
├── controlnet/         ← ControlNet 模型
├── ipadapter/          ← IPAdapter 模型
├── clip_vision/        ← CLIP Vision 模型（IPAdapter 用）
├── upscale_models/     ← 放大模型
├── animatediff_models/ ← AnimateDiff 動態模塊
└── loras/              ← LoRA 檔案
```

---

## 7. 建立資料夾結構（04_create_folders.bat）

此腳本建立所有必要的 models 子目錄及輸出目錄。

```bat
.\install\04_create_folders.bat
```

腳本會建立：
- 所有 `models/` 子目錄
- `output/` 及其子目錄（images、videos、upscaled）
- `input/` 目錄（放置參考圖片）

---

## 8. 重啟與載入工作流

1. 完整關閉並重新啟動 ComfyUI
2. 開啟瀏覽器，前往 `http://127.0.0.1:8188`
3. 點擊介面左下角「Load」或直接拖曳 `.json` 工作流檔案至視窗
4. 工作流位於 `ComfyUI_Workflows/` 目錄

### 工作流一覽

| 工作流檔案 | 功能 |
|---|---|
| 01_flux_txt2img.json | FLUX 文字生圖 |
| 02_flux_kontext_edit.json | FLUX Kontext 影像編輯 |
| 03_controlnet_interior.json | ControlNet 室內設計 |
| 04_ipadapter_portrait.json | IPAdapter 人物一致性 |
| 05_wan22_t2v.json | Wan 2.2 文字生影片 |
| 06_wan22_i2v.json | Wan 2.2 圖片生影片 |
| 07_upscale.json | 圖片放大工作流 |

---

## 9. 確認 CUDA / Torch 正確安裝

在 ComfyUI 的 Python 環境中執行：

```python
python -c "
import torch
print('PyTorch 版本:', torch.__version__)
print('CUDA 可用:', torch.cuda.is_available())
print('CUDA 版本:', torch.version.cuda)
print('GPU 名稱:', torch.cuda.get_device_name(0))
print('VRAM:', round(torch.cuda.get_device_properties(0).total_memory / 1024**3, 1), 'GB')
"
```

### 預期輸出（cu124 環境）

```
PyTorch 版本: 2.4.1+cu124
CUDA 可用: True
CUDA 版本: 12.4
GPU 名稱: NVIDIA GeForce RTX 4080
VRAM: 32.0 GB
```

### 常見問題

- `CUDA 可用: False` → 安裝了 CPU 版 PyTorch，需重裝（見下節）
- CUDA 版本顯示 `None` → 同上

---

## 10. 重裝 PyTorch cu124

若 PyTorch 未正確連結 CUDA，執行以下指令重裝：

```powershell
# 先卸載現有版本
pip uninstall torch torchvision torchaudio -y

# 安裝 PyTorch 2.4.x cu124
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# 確認安裝結果
python -c "import torch; print(torch.__version__, torch.cuda.is_available())"
```

### xFormers 安裝（選用）

xFormers 可加速 Attention 運算，建議安裝：

```powershell
pip install xformers --index-url https://download.pytorch.org/whl/cu124
```

> RTX 4080 32GB VRAM 充裕，xFormers 效益相對有限，但對長序列（高解析度、長影片）仍有幫助。

### 一鍵安裝腳本

```powershell
# 執行 install_all.bat 可依序執行所有安裝步驟
.\install\install_all.bat
```

---

## 附錄：常用啟動參數

```bat
# 一般啟動
python main.py

# 低 VRAM 模式（VRAM < 8GB）
python main.py --lowvram

# 中等 VRAM 模式（8~16GB）
python main.py --normalvram

# 強制使用 fp16（節省 VRAM）
python main.py --fp16-vae

# 啟用 xFormers
python main.py --use-pytorch-attention

# 指定 GPU
python main.py --cuda-device 0
```

> 本工作站 RTX 4080 32GB，一般無需特殊啟動參數，預設設定即可充分發揮效能。
