# 常見問題排除總表

> 適用：ComfyUI 工作站 / RTX 4080 32GB VRAM / Windows 11

---

## 目錄

1. [CUDA Out of Memory（OOM）](#1-cuda-out-of-memory-oom)
2. [PyTorch 非 CUDA 版本問題](#2-pytorch-非-cuda-版本問題)
3. [xFormers 版本衝突](#3-xformers-版本衝突)
4. [自訂節點紅框（Import 失敗）](#4-自訂節點紅框import-失敗)
5. [模型下拉選單紅框（找不到模型）](#5-模型下拉選單紅框找不到模型)
6. [ControlNet 找不到模型](#6-controlnet-找不到模型)
7. [IPAdapter 找不到模型](#7-ipadapter-找不到模型)
8. [insightface 安裝失敗（ReActor / FaceID）](#8-insightface-安裝失敗reactor--faceid)
9. [Wan 2.2 OOM 與影片問題](#9-wan-22-oom-與影片問題)
10. [節點版本衝突](#10-節點版本衝突)
11. [ComfyUI-Manager 修復方法](#11-comfyui-manager-修復方法)
12. [如何查看 Console Log](#12-如何查看-console-log)
13. [快速診斷流程圖](#13-快速診斷流程圖)

---

## 1. CUDA Out of Memory（OOM）

### 分級解法（依嚴重程度排序）

| 等級 | 現象 | 解法 | 預期節省 VRAM |
|---|---|---|---|
| 1（最輕）| 偶發 OOM | 重啟 ComfyUI，清除 VRAM 殘留 | - |
| 2 | 特定工作流 OOM | 加 `--highvram` 啟動參數，讓 ComfyUI 更積極管理 | - |
| 3 | 中等 OOM | 模型換用 fp8 版本（UNETLoader: fp8_e4m3fn）| ~12 GB |
| 4 | 解析度造成 OOM | 降低生成解析度（如 1024→768，或 832x480→480x480）| ~30% |
| 5 | batch 造成 OOM | 降低 batch_size 至 1 | 線性比例 |
| 6（影片）| Wan 影片 OOM | 降低 frames（81→65→49）| 每降 16f 約 4 GB |
| 7（最強）| 完全 OOM | 加 `--lowvram` 啟動（使用系統 RAM，速度大幅下降）| 幾乎無限 |

### 分階段解法詳解

**步驟 1：確認問題**
```powershell
# 查看目前 VRAM 使用狀況
nvidia-smi

# 查看是否有其他程式佔用 VRAM
nvidia-smi --query-compute-apps=pid,used_memory --format=csv
```

**步驟 2：釋放 VRAM**
```
ComfyUI 介面 → 右鍵選單 → Free Memory
或重啟 ComfyUI
```

**步驟 3：切換精度**
```
UNETLoader 節點:
  weight_dtype: fp8_e4m3fn（從 default/fp16 改為 fp8）
```

**步驟 4：降低解析度**

| 原始解析度 | 降載後 | VRAM 節省 |
|---|---|---|
| 1024x1024 | 768x768 | ~44% |
| 832x480（Wan）| 640x480 | ~15% |
| 1360x768 | 1024x576 | ~30% |

**步驟 5：加啟動參數**
```bat
REM 可攜版 run_nvidia_gpu.bat 內修改：
python_embeded\python.exe -s ComfyUI\main.py --windows-standalone-build --lowvram
```

---

## 2. PyTorch 非 CUDA 版本問題

### 症狀診斷

| 症狀 | 診斷指令 | 問題確認 |
|---|---|---|
| 生成速度極慢（CPU 速度）| `python -c "import torch; print(torch.cuda.is_available())"` | 輸出 `False` = CPU 版 |
| Console 顯示 CPU 模式 | 看啟動 log | 出現 `cpu` 而非 `cuda` |
| 版本顯示 `+cpu` | `python -c "import torch; print(torch.__version__)"` | 版本含 `+cpu` |

### 解法

```powershell
# 啟動虛擬環境（git 版）
cd D:\ComfyUI
.\venv\Scripts\activate

# 卸載現有版本
pip uninstall torch torchvision torchaudio -y

# 重裝 cu124 版本
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# 確認
python -c "import torch; print(torch.__version__, torch.cuda.is_available())"
# 預期：2.x.x+cu124 True
```

**可攜版：**
```bat
.\python_embeded\python.exe -m pip uninstall torch torchvision torchaudio -y
.\python_embeded\python.exe -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
```

### CUDA 版本選擇對照表

| NVIDIA 驅動版本 | 推薦 PyTorch CUDA 版本 |
|---|---|
| >= 555.xx | cu124（CUDA 12.4）|
| >= 528.xx | cu121（CUDA 12.1）|
| >= 517.xx | cu118（CUDA 11.8）|

> 本工作站驅動 >= 555.xx，使用 **cu124**。

---

## 3. xFormers 版本衝突

### 症狀

| 錯誤訊息 | 說明 |
|---|---|
| `ImportError: cannot import name 'xxx' from 'xformers'` | xFormers 版本與 PyTorch 不符 |
| `AttributeError: module 'xformers' has no attribute 'ops'` | 同上 |
| `RuntimeError: xFormers' memory efficient attention is not supported` | 不相容組合 |

### 解法

```powershell
# 卸載 xFormers
pip uninstall xformers -y

# 確認 PyTorch 版本
python -c "import torch; print(torch.__version__)"

# 對應 cu124 重裝 xFormers
pip install xformers --index-url https://download.pytorch.org/whl/cu124
```

### PyTorch 與 xFormers 對應版本

| PyTorch 版本 | xFormers 版本 | 安裝指令索引 |
|---|---|---|
| 2.4.x+cu124 | 0.0.28.post1 | `--index-url .../cu124` |
| 2.3.x+cu121 | 0.0.26.post1 | `--index-url .../cu121` |
| 2.1.x+cu118 | 0.0.23 | `--index-url .../cu118` |

### 暫時停用 xFormers（偵錯用）

```bat
python main.py --disable-xformers
```

---

## 4. 自訂節點紅框（Import 失敗）

### 症狀

ComfyUI 啟動後，工作流中的節點顯示為紅色框（Red Node），無法連接或執行。

### 診斷步驟

**步驟 1：查看 Console Log（見第 12 節）找出錯誤訊息**

常見的 import 失敗訊息類型：

| 錯誤類型 | 範例訊息 | 意義 |
|---|---|---|
| ModuleNotFoundError | `No module named 'xxx'` | 缺少 Python 套件 |
| ImportError | `cannot import name 'yyy'` | 套件版本不符 |
| SyntaxError | `invalid syntax at line N` | Python 版本不相容 |
| FileNotFoundError | `No such file: 'model.safetensors'` | 模型檔案缺失 |

**步驟 2：使用 Manager 修復**

```
ComfyUI Manager → Install Missing Custom Nodes
或
ComfyUI Manager → Fix Node Dependencies
```

**步驟 3：手動安裝缺失套件**

```powershell
# 查看哪個套件缺失（從 log 中找到 "No module named 'xxx'"）
pip install xxx

# 常見缺失套件
pip install opencv-python
pip install scikit-image
pip install fairscale
pip install einops
pip install timm
pip install accelerate
```

**步驟 4：更新或重裝特定節點**

```powershell
cd D:\ComfyUI\custom_nodes\[節點目錄]
git pull
pip install -r requirements.txt
```

**步驟 5：完整重裝節點**

```powershell
cd D:\ComfyUI\custom_nodes
# 備份配置（如有）後刪除重裝
rmdir /s /q [節點目錄]
git clone [節點 GitHub URL]
```

---

## 5. 模型下拉選單紅框（找不到模型）

### 症狀

節點（如 CheckpointLoaderSimple、UNETLoader 等）的下拉選單中，模型名稱顯示紅色或出現 `[NOT FOUND]` 標記。

### 常見原因與解法

| 原因 | 解法 |
|---|---|
| 模型放在錯誤的子目錄 | 依下表確認正確路徑 |
| 檔案名稱有誤（大小寫/空格）| 確認檔名與工作流中一致 |
| 磁碟空間不足，下載不完整 | 刪除並重新下載 |
| 模型資料夾路徑配置錯誤 | 確認 ComfyUI 的 `extra_model_paths.yaml` |

### 各模型類型的正確放置路徑

| 節點名稱 | 模型類型 | 正確路徑 |
|---|---|---|
| CheckpointLoaderSimple | SD1.5 / SDXL checkpoint | `models/checkpoints/` |
| UNETLoader | FLUX diffusion | `models/diffusion_models/` |
| DualCLIPLoader | FLUX CLIP / T5 | `models/clip/` |
| VAELoader | VAE | `models/vae/` |
| ControlNetLoader | ControlNet | `models/controlnet/` |
| IPAdapterUnifiedLoader | IPAdapter | `models/ipadapter/` |
| CLIPVisionLoader | CLIP Vision | `models/clip_vision/` |
| UpscaleModelLoader | 放大模型 | `models/upscale_models/` |
| LoraLoader | LoRA | `models/loras/` |
| WanModelLoader | Wan 模型 | `models/diffusion_models/` |

### 重新掃描模型

重啟 ComfyUI 會自動重新掃描，或：
```
ComfyUI Manager → Refresh ComfyUI
```

---

## 6. ControlNet 找不到模型

### 症狀

`ControlNetLoader` 節點下拉選單為空，或載入後顯示紅框。

### 解法步驟

1. **確認放置路徑**：模型應放在 `ComfyUI/models/controlnet/`

2. **確認模型基底架構匹配**：

   | 基礎模型 | 使用的 ControlNet | 錯誤組合 |
   |---|---|---|
   | SD1.5 checkpoint | SD1.5 ControlNet（v11p 系列）| 不可使用 SDXL ControlNet |
   | SDXL checkpoint | SDXL ControlNet（union-sdxl）| 不可使用 SD1.5 ControlNet |
   | FLUX.1-dev（UNETLoader）| FLUX ControlNet Union Pro | 不可使用 SD ControlNet |

3. **確認節點連接**：
   - ControlNet 需連接 conditioning（而非直接連 model）
   - `ControlNetApplyAdvanced` 的輸入需要 positive conditioning

4. **預處理器模型自動下載**：
   - `comfyui_controlnet_aux` 預處理器（如 MiDaS、OpenPose）首次使用會自動下載至快取
   - 若下載失敗，手動下載至 `custom_nodes/comfyui_controlnet_aux/ckpts/`

---

## 7. IPAdapter 找不到模型

### CLIP Vision 找不到

**錯誤訊息**：`clip_vision model not found` 或 `CLIPVisionLoader failed`

| 檢查項目 | 正確設定 |
|---|---|
| 放置路徑 | `ComfyUI/models/clip_vision/` |
| 模型與 Preset 對應 | PLUS 系列需 ViT-H；bigG 系列需 ViT-bigG |
| 節點版本 | IPAdapter_plus 最新版，確認無 import 錯誤 |

**常用 CLIP Vision 模型**：
```
clip_vision/
├── clip-vit-h-14-laion2B-s32B-b79K.safetensors  ← PLUS 系列使用
└── clip-vit-large-patch14.safetensors             ← 基礎版使用
```

### Preset 對應模型缺失

**現象**：選擇 Preset 後生成沒有 IPAdapter 效果，或顯示警告

| Preset | 需要的 ipadapter 模型 | 需要的 clip_vision 模型 |
|---|---|---|
| PLUS (SDXL) | `ip-adapter-plus_sdxl_vit-h.safetensors` | ViT-H |
| PLUS FACE (SDXL) | `ip-adapter-plus-face_sdxl_vit-h.safetensors` | ViT-H |
| FaceID Plus v2 (SDXL) | `ip-adapter-faceid-plusv2_sdxl.bin` | ViT-H |
| PLUS (SD1.5) | `ip-adapter-plus_sd15.safetensors` | ViT-H |

下載缺失模型：
```powershell
.\install\03_download_models.ps1
# 選擇選項 9（IPAdapter）或 10（FaceID）
```

---

## 8. insightface 安裝失敗（ReActor / FaceID）

### 症狀

```
ModuleNotFoundError: No module named 'insightface'
ImportError: DLL load failed while importing insightface
```

### Windows 安裝流程（最完整版）

**步驟 1：安裝 Visual C++ Build Tools**

前往 https://visualstudio.microsoft.com/visual-cpp-build-tools/ 下載安裝，勾選：
- Desktop development with C++
- Windows 10/11 SDK

**步驟 2：重啟終端機後安裝**

```powershell
# 啟動虛擬環境
.\venv\Scripts\activate

# 安裝 cmake（insightface 編譯需要）
pip install cmake

# 安裝 insightface
pip install insightface

# 若仍失敗，嘗試指定版本
pip install insightface==0.7.3
```

**步驟 3：若仍失敗，使用預編譯 Wheel**

前往 Gourieff 的預編譯資源：
https://github.com/Gourieff/Assets/tree/main/Insightface

下載對應版本的 `.whl` 檔（注意 Python 版本：cp311=Python3.11，cp312=Python3.12）：

```powershell
# 範例（Python 3.11, Win64）
pip install insightface-0.7.3-cp311-cp311-win_amd64.whl
```

**步驟 4：可攜版安裝**

```bat
.\python_embeded\python.exe -m pip install insightface
REM 或使用 wheel 檔
.\python_embeded\python.exe -m pip install insightface-0.7.3-cp311-cp311-win_amd64.whl
```

### 驗證安裝

```powershell
python -c "import insightface; print(insightface.__version__)"
```

---

## 9. Wan 2.2 OOM 與影片問題

### OOM 分級處理

| 嚴重度 | 情境 | 解法 |
|---|---|---|
| 輕度 | 偶發 OOM | 重啟 ComfyUI，或降 1 個解析度等級 |
| 中度 | 81f 穩定 OOM | 切換 fp8；或降至 65f |
| 重度 | 65f 也 OOM | fp8 + 降至 480x480 解析度 |
| 極重 | 任何設定都 OOM | `--lowvram` 啟動（使用系統 RAM）|

### 影片閃爍排除

| 症狀 | 可能原因 | 解法 |
|---|---|---|
| 全片閃爍 | CFG 過高 | 降至 3.0~3.5 |
| 特定幀異常 | 取樣步數不足 | 增加至 20+20 步 |
| 色彩閃爍 | VAE 問題 | 確認使用 wan_2.1_vae |
| 解析度不符導致閃爍 | 訓練外解析度 | 改用標準 480p 系列解析度 |

### 動作不足排除

| 症狀 | 解法 |
|---|---|
| 影片幾乎靜止 | 提示詞加入動作詞（flowing, walking, moving camera）|
| 輕微晃動 | 降低 CFG 至 2.5~3.0 |
| I2V 動作被鎖死 | 降低起始幀 condition strength（從 1.0 改 0.85）|

---

## 10. 節點版本衝突

### 症狀

工作流突然無法執行，出現以下類型錯誤：
```
AttributeError: 'dict' object has no attribute 'xxx'
TypeError: forward() got an unexpected keyword argument 'yyy'
KeyError: 'zzz'
```

### 診斷

```
ComfyUI Manager → Nodes Info → 查看各節點版本與更新狀態
```

### 解法步驟

**步驟 1：更新所有自訂節點**

```
ComfyUI Manager → Update All Custom Nodes
```

**步驟 2：更新 ComfyUI 本體**

```powershell
cd D:\ComfyUI
git pull
pip install -r requirements.txt
```

**步驟 3：若更新後問題更嚴重（新版不相容），回滾特定節點**

```powershell
cd D:\ComfyUI\custom_nodes\[節點目錄]
git log --oneline -10  # 查看版本記錄
git checkout [舊版 commit hash]  # 回滾至舊版
```

**步驟 4：報告問題**

前往節點的 GitHub Issue 頁面回報，提供：
- ComfyUI 版本
- 節點版本
- 錯誤訊息截圖
- 作業系統與 Python 版本

---

## 11. ComfyUI-Manager 修復方法

ComfyUI-Manager 是主要的修復入口，提供以下工具：

### 常用修復功能

| 功能 | 用途 | 位置 |
|---|---|---|
| Install Missing Custom Nodes | 安裝工作流缺少的節點 | Manager 主選單 |
| Fix Node Dependencies | 修復節點依賴問題 | Manager 主選單 |
| Update All Custom Nodes | 更新所有自訂節點 | Manager 主選單 |
| Update ComfyUI | 更新 ComfyUI 本體 | Manager 主選單 |
| Install via Git URL | 手動安裝節點 | Manager → Custom Nodes |
| Snapshot | 建立環境快照（版本備份）| Manager → Snapshot |
| Restore Snapshot | 回滾至特定版本組合 | Manager → Snapshot |

### Manager 無法啟動時的手動修復

若 ComfyUI-Manager 本身出問題：

```powershell
# 更新 Manager
cd D:\ComfyUI\custom_nodes\ComfyUI-Manager
git pull

# 安裝 Manager 依賴
pip install -r requirements.txt

# 若完全無法修復，重裝 Manager
cd D:\ComfyUI\custom_nodes
rmdir /s /q ComfyUI-Manager
git clone https://github.com/ltdrdata/ComfyUI-Manager.git
```

---

## 12. 如何查看 Console Log

Console Log 是排除問題最重要的工具，包含所有錯誤訊息。

### 查看方式

**可攜版 / Git 版（bat 啟動）**：
- 啟動 ComfyUI 的 CMD 視窗就是 Console，錯誤訊息直接顯示在此

**桌面版（Desktop App）**：
- 右鍵工作列圖示 → 「Open Console」
- 或在 ComfyUI 網頁介面按 F12（開發者工具）→ Console 頁籤

### 重要 Log 位置

```
D:\ComfyUI\comfyui.log           ← 主要 log 檔（若啟用）
D:\ComfyUI\custom_nodes\[節點]\  ← 各節點的 log
```

啟用 log 輸出至檔案：
```bat
python main.py 2>&1 | tee D:\ComfyUI\comfyui.log
```

### 常見 Log 訊息解讀

| Log 訊息 | 意義 |
|---|---|
| `Total VRAM 32510 MB` | GPU 正確偵測 |
| `Using xformers cross attention` | xFormers 正常運作 |
| `Requested to load...` | 模型載入中 |
| `[ERROR] Failed to import ...` | 節點 import 失敗（看後面的模組名稱）|
| `RuntimeError: CUDA out of memory` | OOM，需降載 |
| `torch.cuda.is_available() = False` | PyTorch 未正確連結 CUDA |
| `No module named 'xxx'` | 缺少 Python 套件，`pip install xxx` |
| `HTTPError 403` | HuggingFace 未授權或未登入 |

### 篩選錯誤訊息

在 Console 中搜尋關鍵字（Windows CMD 右鍵 → Find）：
- `ERROR` → 找出所有錯誤
- `WARN` → 找出所有警告
- `import` → 找出 import 相關錯誤
- `CUDA` → 找出 CUDA 相關問題

---

## 13. 快速診斷流程圖

```
生成失敗或節點報錯？
  │
  ├─ 節點顯示紅框
  │     ↓
  │   Console 有 "No module named" 訊息？
  │     ├─ 是 → pip install [模組名]
  │     └─ 否 → Manager → Fix Node Dependencies
  │
  ├─ CUDA Out of Memory
  │     ↓
  │   降載順序：
  │   1. 切換 fp8 → 2. 降解析度 → 3. 降 frame 數 → 4. --lowvram
  │
  ├─ 模型找不到（紅框下拉）
  │     ↓
  │   確認放置路徑是否正確（見第 5 節對照表）
  │
  ├─ 生成結果全黑
  │     ↓
  │   FLUX？→ 確認 VAE 是 flux_ae.safetensors
  │   其他？→ 確認 VAE 版本與 checkpoint 相符
  │
  ├─ 生成速度極慢（CPU 模式）
  │     ↓
  │   pip uninstall torch && pip install torch --index-url .../cu124
  │
  └─ 工作流突然無法執行
        ↓
      Manager → Update All Custom Nodes → 重啟 ComfyUI
```

---

## 附錄：常用排除指令速查

```powershell
# 確認 GPU 狀態
nvidia-smi

# 確認 PyTorch CUDA
python -c "import torch; print(torch.__version__, torch.cuda.is_available())"

# 重裝 cu124 PyTorch
pip uninstall torch torchvision torchaudio -y
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# 重裝 xFormers
pip uninstall xformers -y
pip install xformers --index-url https://download.pytorch.org/whl/cu124

# 確認 HuggingFace 登入狀態
huggingface-cli whoami

# 更新 ComfyUI
cd D:\ComfyUI && git pull && pip install -r requirements.txt

# 更新特定節點
cd D:\ComfyUI\custom_nodes\[節點] && git pull && pip install -r requirements.txt
```

---

> 若以上方法均無法解決問題，請提供完整的 Console Log 並至 ComfyUI GitHub Issues 或對應節點 Issues 頁面回報。
