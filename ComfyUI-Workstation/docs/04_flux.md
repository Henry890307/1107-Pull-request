# FLUX 模型使用教學

> 適用：ComfyUI 工作站 / RTX 4080 32GB VRAM / FLUX.1-dev + Kontext-dev

---

## 目錄

1. [FLUX 模型版本差異](#1-flux-模型版本差異)
2. [模型載入節點鏈](#2-模型載入節點鏈)
3. [FluxGuidance 參數](#3-fluxguidance-參數)
4. [標準取樣鏈](#4-標準取樣鏈)
5. [EmptySD3LatentImage 解析度設定](#5-emptysd3latentimage-解析度設定)
6. [fp16 vs fp8 取捨（32GB VRAM）](#6-fp16-vs-fp8-取捨32gb-vram)
7. [FLUX Kontext 影像編輯與風格轉換](#7-flux-kontext-影像編輯與風格轉換)
8. [接 BFL API 使用 Kontext Pro](#8-接-bfl-api-使用-kontext-pro)
9. [Gated 模型下載與授權](#9-gated-模型下載與授權)
10. [常見錯誤與排除](#10-常見錯誤與排除)

---

## 1. FLUX 模型版本差異

| 版本 | 類型 | 用途 | 取得方式 |
|---|---|---|---|
| FLUX.1-dev | 本地模型 | 高品質文字生圖 | HuggingFace 下載（Gated）|
| FLUX.1-Kontext-dev | 本地模型 | 影像編輯、風格轉換 | HuggingFace 下載（Gated）|
| FLUX.1-Kontext Pro | API 服務 | 商業級影像編輯（無本地權重）| BFL API 金鑰 |
| FLUX.1-schnell | 本地模型 | 快速生成（低品質）| Apache 2.0，可自由下載 |

### 關鍵說明

**FLUX Kontext Pro 沒有公開權重**。它是 Black Forest Labs 的商業 API 服務，你無法下載其模型檔案在本地執行。在本地機器上進行影像編輯，請使用 **FLUX.1-Kontext-dev**（`flux1-kontext-dev.safetensors`）。

**FLUX.1-dev 與 Kontext-dev 都是 Gated Repository**，需要到 HuggingFace 同意授權後才能下載（見第 9 節）。

### 架構特點

FLUX 採用 **Transformer（DiT）架構**，與 SD1.5/SDXL 的 UNet 架構根本不同：

- 使用 **雙 CLIP**（T5 XXL + CLIP-L）作為文字編碼器
- 使用獨立的 **FLUX VAE**（flux_ae.safetensors）
- 不使用傳統的 CFG（Classifier-Free Guidance），改用 FluxGuidance 節點
- 取樣採用 **flow matching** 方法，建議使用 `euler` 取樣器

---

## 2. 模型載入節點鏈

FLUX 的載入方式與 SD1.5/SDXL 不同，使用三個獨立載入節點：

### 完整載入節點結構

```
[UNETLoader]
  unet_name: flux1-dev.safetensors
  weight_dtype: default（fp16）或 fp8
        ↓ (MODEL)

[DualCLIPLoader]
  clip_name1: t5xxl_fp16.safetensors  ← T5 XXL 文字編碼器
  clip_name2: clip_l.safetensors       ← CLIP-L
  type: flux                           ← 必須選 flux
        ↓ (CLIP)

[VAELoader]
  vae_name: flux_ae.safetensors        ← FLUX 專用 VAE
        ↓ (VAE)
```

### 重要注意事項

1. **DualCLIPLoader 的 type 必須設為 `flux`**：若設為 `sd3` 或其他選項，文字編碼會出錯
2. **T5 模型需要大量 VRAM**：`t5xxl_fp16.safetensors` 在 fp16 下佔用約 9.5 GB VRAM；32GB 可輕鬆容納
3. **VAE 不可混用**：FLUX 必須使用 `flux_ae.safetensors`，使用 SD VAE 會產生黑圖或噪點圖

### 節點路徑示意

```
UNETLoader ──────────────────────────────────────→ MODEL ─┐
DualCLIPLoader → CLIPTextEncode(正面提示) → COND ─────────┤
              → CLIPTextEncode(負面提示) → COND ─────────┤→ SamplerCustomAdvanced
VAELoader ───────────────────────────────────────→ VAE ──┤
EmptySD3LatentImage ─────────────────────────────→ LATENT ┘
```

---

## 3. FluxGuidance 參數

FLUX 不使用傳統的 CFG，而是透過 `FluxGuidance` 節點設定引導強度。

### FluxGuidance 節點

```
[CLIPTextEncode 正面提示詞]
        ↓
[FluxGuidance]
  guidance: 3.5  ← 引導強度
        ↓
[conditioning 輸出]
```

### guidance 參數建議值

| guidance 值 | 效果 |
|---|---|
| 1.0~2.0 | 低引導，提示詞影響弱，圖像更隨機多樣 |
| 2.5~3.5 | 標準引導，平衡品質與多樣性（**推薦**）|
| 3.5~4.5 | 高引導，提示詞影響強，圖像更符合描述 |
| > 5.0 | 過高引導，容易產生對比過強、不自然的圖像 |

**建議起始值**：`3.5`，根據實際效果微調。

> 注意：FLUX 的 guidance 不是 SD 的 CFG，兩者數值含義不同。SD 的 CFG 7.0 ≈ FLUX guidance 3.5，但具體效果因提示詞內容而異。

---

## 4. 標準取樣鏈

FLUX 使用 ComfyUI 的進階取樣節點（Custom Advanced Sampler），與 SD 的 KSampler 不同。

### 標準 FLUX 取樣節點鏈

```
[RandomNoise]
  noise_seed: 隨機或固定種子
        ↓
[KSamplerSelect]
  sampler_name: euler（FLUX 標準取樣器）
        ↓
[BasicScheduler]
  scheduler: simple（FLUX 推薦）
  steps: 20（快速）~ 28（高品質）
  denoise: 1.0（文字生圖）或 0.6~0.85（img2img）
        ↓
[BasicGuider]
  model: (來自 UNETLoader)
  conditioning: (來自 FluxGuidance)
        ↓
[SamplerCustomAdvanced]
  noise: (來自 RandomNoise)
  guider: (來自 BasicGuider)
  sampler: (來自 KSamplerSelect)
  sigmas: (來自 BasicScheduler)
  latent_image: (來自 EmptySD3LatentImage)
        ↓
[VAEDecode]
  samples: (來自 SamplerCustomAdvanced 的 output)
  vae: (來自 VAELoader)
        ↓
[SaveImage / PreviewImage]
```

### 取樣器選擇

| 取樣器 | 適用場景 | 備註 |
|---|---|---|
| `euler` | FLUX 文字生圖（推薦）| 官方建議 |
| `euler_ancestral` | 更多變化，創意生成 | 可能有些不穩定 |
| `dpmpp_2m` | 高品質，步數較多 | 不是 FLUX 最佳選擇 |
| `ipndm` | 實驗性 | 部分工作流使用 |

**建議**：FLUX 穩定使用 `euler` + `simple` 排程器。

### 步數建議

| 步數 | 速度 | 品質 | 適用 |
|---|---|---|---|
| 15~20 | 快（約 30~50s）| 良好 | 快速預覽 |
| 20~25 | 中（約 50~90s）| 優良 | 日常生成 |
| 25~30 | 慢（約 90~150s）| 最佳 | 最終輸出 |

> RTX 4080 32GB：FLUX fp16 約 50~100 秒 / 張（1024x1024，25 步）

---

## 5. EmptySD3LatentImage 解析度設定

FLUX 使用 `EmptySD3LatentImage` 節點（而非 SD 的 `EmptyLatentImage`）。

### 節點設定

```
[EmptySD3LatentImage]
  width: 1024
  height: 1024
  batch_size: 1
```

### 建議解析度

| 比例 | 寬 x 高 | 適用場景 |
|---|---|---|
| 1:1 | 1024 x 1024 | 人物、產品圖 |
| 3:4 | 768 x 1024 | 人物直幅 |
| 4:3 | 1024 x 768 | 風景橫幅 |
| 16:9 | 1360 x 768 | 寬幅場景 |
| 9:16 | 768 x 1360 | 手機直幅 |
| 2:3 | 832 x 1216 | 人像標準 |

### 解析度對 VRAM 與速度的影響

| 解析度 | VRAM 消耗（fp16）| 25 步生成時間（約）|
|---|---|---|
| 512 x 512 | ~18 GB | ~20s |
| 1024 x 1024 | ~24 GB | ~60s |
| 1360 x 768 | ~26 GB | ~75s |
| 1536 x 1024 | ~28 GB | ~100s |
| 2048 x 2048 | >32 GB（OOM）| - |

> 32GB VRAM 可穩定跑 1024x1024；更高解析度建議先生成 1024 再用 Upscale 工作流放大。

---

## 6. fp16 vs fp8 取捨（32GB VRAM）

### fp16（半精度浮點）

- **VRAM 佔用**：FLUX 主模型約 24 GB，加 T5 約 9 GB，合計約 33 GB（略超，ComfyUI 會自動換出）
- **品質**：最佳，無精度損失
- **建議**：32GB VRAM 的本工作站可使用 fp16，ComfyUI 會自動管理換出
- **設定方式**：`UNETLoader` → `weight_dtype: default`

### fp8（8-bit 浮點量化）

- **VRAM 佔用**：主模型約 12 GB，可大幅節省 VRAM
- **品質**：輕微品質損失，但在多數場景肉眼難以分辨
- **建議**：當同時使用 ControlNet + IPAdapter + FLUX 時（總需求接近或超過 32GB），考慮使用 fp8
- **設定方式**：`UNETLoader` → `weight_dtype: fp8_e4m3fn`

### 本工作站建議策略

| 使用情境 | 建議精度 |
|---|---|
| 單純 FLUX 文字生圖 | fp16（`default`）|
| FLUX + ControlNet | fp16（32GB 可容納）|
| FLUX + ControlNet + IPAdapter | fp8（避免 OOM）|
| FLUX + ControlNet + IPAdapter + 高解析度 | fp8 + 降低解析度至 768x1024 |

### T5 XXL 的記憶體考量

T5 XXL fp16 佔用約 9.5 GB。如果 VRAM 壓力大，可改用 T5 fp8 版本：

- `t5xxl_fp8_e4m3fn.safetensors`（~4.7 GB）
- 品質差異極小，但節省約 4.8 GB VRAM

---

## 7. FLUX Kontext 影像編輯與風格轉換

FLUX.1-Kontext-dev 是專為影像編輯設計的模型，支援：
- 精確的局部區域修改
- 風格轉換（保留內容改變畫風）
- 物件替換
- 文字插入（英文）

### Kontext 工作流節點鏈

```
[Load Image: 參考圖（要編輯的圖）]
        ↓
[VAEEncode]  ← 將參考圖編碼為 latent
  vae: flux_ae.safetensors
        ↓ (latent)

[UNETLoader: flux1-kontext-dev.safetensors]
        ↓ (MODEL)

[DualCLIPLoader]
  clip1: t5xxl_fp16.safetensors
  clip2: clip_l.safetensors
  type: flux
        ↓ (CLIP)

[CLIPTextEncode]
  正面提示詞：描述修改後的目標
        ↓

[FluxGuidance] guidance: 2.5~3.5
        ↓

[BasicScheduler]
  steps: 20~28
  denoise: 0.55~0.75  ← Kontext 影像編輯的關鍵！
        ↓

[SamplerCustomAdvanced]
  latent_image: (來自 VAEEncode，非 EmptySD3LatentImage)
        ↓

[VAEDecode] → 輸出編輯後的圖像
```

### Kontext 的關鍵：denoise 設定

Kontext 影像編輯的核心在於控制 denoise（去噪強度）：

| denoise 值 | 效果 |
|---|---|
| 0.3~0.5 | 輕微修改，保留大部分原圖 |
| 0.5~0.7 | 中度修改，平衡保留與改變（**推薦**）|
| 0.7~0.85 | 較大修改，改變明顯但保留場景結構 |
| 0.9~1.0 | 幾乎完全重新生成（類似 txt2img）|

### 實用編輯提示詞技巧

**物件替換**：
```
Replace the [原物件] with [新物件], keep everything else the same
```

**風格轉換**：
```
Transform the image into [目標風格] style, maintain the composition and layout
```

**局部修改**：
```
Change the color of [物件] to [顏色], preserve all other elements
```

**文字插入**：
```
Add the text "[文字內容]" on [位置], [字型風格]
```

---

## 8. 接 BFL API 使用 Kontext Pro

FLUX.1-Kontext **Pro** 是 API 服務，無法在本地執行，需要透過 BFL（Black Forest Labs）API 金鑰呼叫。

### 前置準備

1. 前往 [https://api.bfl.ml/](https://api.bfl.ml/) 申請 API 金鑰
2. 購買 API 額度（按張收費）
3. 安裝 ComfyUI 的 BFL API 節點（如 `ComfyUI-BFLApiNode` 等社群節點）

### API 節點使用方式

```
[BFL API 節點]
  api_key: (貼上你的 BFL API 金鑰)
  model: flux-kontext-pro
  prompt: (你的提示詞)
  image: (參考圖，Base64 或 URL)
  aspect_ratio: 1:1（或其他比例）
  guidance: 3.5
  output_format: jpeg
        ↓
[Load Image from URL / Decode Response]
        ↓
[SaveImage]
```

> **注意**：使用 API 需要穩定的網路連線，且每次生成都會消耗 API 額度。本地 Kontext-dev 完全免費，API 版 Pro 品質略高但有額度成本。

### BFL API 優缺點對比

| 比較項目 | 本地 Kontext-dev | BFL API Kontext Pro |
|---|---|---|
| 成本 | 一次性（電費）| 按次計費 |
| 速度 | 60~120 秒/張 | 10~30 秒/張（雲端 GPU）|
| 隱私 | 完全本地 | 圖片上傳至雲端 |
| 品質 | 優良 | 商業最佳 |
| 網路依賴 | 僅下載模型 | 每次生成需連線 |

---

## 9. Gated 模型下載與授權

FLUX.1-dev 與 FLUX.1-Kontext-dev 屬於 Gated Repository，需要以下步驟才能下載：

### 步驟總覽

1. **建立 HuggingFace 帳號**：https://huggingface.co/join
2. **同意 FLUX.1-dev 授權**：https://huggingface.co/black-forest-labs/FLUX.1-dev → 點擊「Agree and access repository」
3. **同意 FLUX.1-Kontext-dev 授權**：https://huggingface.co/black-forest-labs/FLUX.1-Kontext-dev → 同上
4. **取得 Access Token**：Settings → Access Tokens → 建立 Read Token
5. **登入 CLI**：

```powershell
huggingface-cli login
# 輸入 Token（格式：hf_xxxxxxxxxxxxxxxxxx）
```

6. **驗證登入**：

```powershell
huggingface-cli whoami
```

7. **執行下載腳本**：

```powershell
.\install\03_download_models.ps1
# 選擇選項 1（FLUX.1-dev）和/或 選項 2（Kontext-dev）
```

### 手動下載方式

```powershell
# 使用 huggingface-cli 手動下載
huggingface-cli download black-forest-labs/FLUX.1-dev flux1-dev.safetensors --local-dir D:\ComfyUI\models\diffusion_models

huggingface-cli download black-forest-labs/FLUX.1-Kontext-dev flux1-kontext-dev.safetensors --local-dir D:\ComfyUI\models\diffusion_models
```

---

## 10. 常見錯誤與排除

### T5 記憶體錯誤

**錯誤訊息**：`RuntimeError: CUDA out of memory` 在載入 T5 模型時出現

| 解法 | 說明 |
|---|---|
| 使用 t5xxl_fp8 版本 | 節省約 4.8 GB VRAM |
| 關閉其他佔用 VRAM 的程式 | 遊戲、其他 AI 工具等 |
| 使用 fp8 主模型 | `UNETLoader` weight_dtype 改為 fp8 |
| 啟動加 `--highvram` 參數 | 讓 ComfyUI 更積極保留模型在 VRAM |

### 黑圖（生成結果全黑）

**原因與解法**：

| 原因 | 解法 |
|---|---|
| VAE 不符（使用了 SD VAE）| 確認 VAELoader 載入 `flux_ae.safetensors` |
| fp8 VAE 解碼精度問題 | 在 VAEDecode 前加 `ModelSamplingFlux` 節點 |
| guidance 設為 0 | FluxGuidance 設 >= 2.5 |
| denoise 設為 0 | BasicScheduler denoise 設 >= 0.5（img2img）|

### VAE 不符

**現象**：生成圖像有藍色或異常色偏、噪點、或彩虹色干擾

**解法**：
- 確認 `VAELoader` 節點載入的是 `flux_ae.safetensors`
- 不可將 SD1.5 VAE（如 `vae-ft-mse-840000.safetensors`）用於 FLUX

### DualCLIPLoader type 錯誤

**現象**：生成圖像無法理解提示詞，或提示詞完全無效

**解法**：確認 `DualCLIPLoader` 的 `type` 參數設為 `flux`（而非 `sd3`、`stable_cascade` 等）

### 模型下載 403 Forbidden

**原因**：未完成 HuggingFace Gated 授權

**解法**：
1. 確認已同意對應模型的授權協議（在 HuggingFace 網頁操作）
2. 確認 `huggingface-cli whoami` 顯示正確帳號
3. 若授權剛完成，等待 2~5 分鐘再重試

### Kontext 編輯效果不明顯

| 原因 | 解法 |
|---|---|
| denoise 太低（< 0.4）| 提高至 0.6~0.75 |
| 提示詞描述不夠精確 | 加入更具體的修改描述 |
| 使用了 dev 模型代替 kontext-dev | 確認 UNETLoader 載入 `flux1-kontext-dev.safetensors` |

### 取樣節點顯示紅框（SamplerCustomAdvanced）

**原因**：ComfyUI 版本過舊，不支援 FLUX 的進階取樣節點

**解法**：更新 ComfyUI 至最新版本：
```powershell
cd D:\ComfyUI
git pull
```

---

> 下一步：閱讀 [05_wan22.md](./05_wan22.md) 學習 Wan 2.2 影片生成。
