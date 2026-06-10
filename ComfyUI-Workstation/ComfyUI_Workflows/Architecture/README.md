# Architecture_Pro 工作流說明

對應工作流檔案：`Architecture_Pro.json`

---

## 1. 工作流用途

本工作流專為建築設計從業者設計，能將 AutoCAD、Revit、SketchUp 等工具匯出的平面圖、立面圖、線稿截圖，透過 FLUX ControlNet（Union Pro 2）與 FLUX Kontext dev 轉化為高品質建築渲染圖。支援多種場景切換：

- **日景** — 自然採光、藍天白雲、清晰陰影
- **夜景** — 室外燈光、幕牆反光、城市氛圍
- **雨景** — 地面反射、濕潤質感、霧氣瀰漫
- **住宅** — 低層住宅、庭園景觀、溫暖材質
- **商辦** — 高層幕牆、企業形象、現代感
- **鳥瞰** — 俯視角度、基地配置、周邊環境
- **街景** — 行人視角、人車互動、都市脈絡

所有場景只需更換 Positive Prompt 即可切換，無需調整 ControlNet 參數。

---

## 2. 節點流程圖

```
[載入 CAD 截圖]
      │
      ▼
[LineArt Preprocessor]
      │  輸出線稿控制圖
      ▼
[FLUX ControlNet Apply (Union Pro 2)]
      │  flux_controlnet_union_pro_2.safetensors
      ▼
[FLUX Kontext dev 取樣器]
      │  flux1-kontext-dev.safetensors
      │  T5 + CLIP-L 雙 Text Encoder
      ▼
[VAE Decode]
      │  flux_ae.safetensors
      ▼
[Ultimate SD Upscale x2]
      │  RealVisXL_V5.0_fp16.safetensors
      │  4x-UltraSharp.pth
      ▼
[儲存/預覽輸出圖]
```

---

## 3. 各節點用途說明

| 節點名稱 | 功能說明 |
|---|---|
| **Load Image** | 載入 CAD 截圖或線稿圖，建議先轉為白底黑線或黑底白線格式 |
| **LineArt Preprocessor** | 使用 ControlNet Auxiliary Preprocessors 套件中的 LineArt Realistic 模式，將截圖精煉成乾淨線稿，濾除多餘雜訊 |
| **FLUX ControlNet Apply (Union Pro 2)** | 套用 `flux_controlnet_union_pro_2.safetensors`，指定 control type 為 `lineart`，strength 建議 0.60–0.75；此節點讓 FLUX 在生成時嚴格遵守建築線稿的幾何結構 |
| **DualCLIPLoader** | 載入 `t5xxl_fp16.safetensors`（T5-XXL 文字編碼器）與 `clip_l.safetensors`（CLIP-L 編碼器），FLUX 需要兩者共同運作才能正確解析長文字 prompt |
| **UNETLoader** | 載入 `flux1-kontext-dev.safetensors` 作為主擴散模型，fp16 格式可在 32GB VRAM 下完整運行無需量化 |
| **VAELoader** | 載入 `flux_ae.safetensors`，FLUX 專屬 VAE，負責將潛空間解碼為最終像素圖像 |
| **KSampler / SamplerCustomAdvanced** | 執行 FLUX 去噪取樣，參數見第 6 段，採用 Euler + Simple Scheduler 組合 |
| **VAEDecode** | 將取樣後的潛空間張量解碼為完整 RGB 圖像 |
| **Ultimate SD Upscale** | 分塊放大，使用 RealVisXL V5 作為放大底模（denoise 0.18），搭配 4x-UltraSharp 上採樣核心，輸出解析度 x2 |
| **Save Image** | 儲存最終輸出，建議儲存路徑含時間戳記與 prompt 前綴方便管理 |

---

## 4. 用到的模型與用途

| 模型檔案 | 存放路徑 | 用途 |
|---|---|---|
| `flux_controlnet_union_pro_2.safetensors` | `models/controlnet/` | FLUX 專用 Union ControlNet，支援 lineart/depth/canny 等多種控制類型 |
| `flux1-kontext-dev.safetensors` | `models/diffusion_models/` | FLUX Kontext dev 本地開源版主力擴散模型，支援圖文交叉注意力 |
| `t5xxl_fp16.safetensors` | `models/clip/` | T5-XXL 文字編碼器，FLUX 長文字理解核心 |
| `clip_l.safetensors` | `models/clip/` | CLIP-L 文字編碼器，與 T5 搭配使用 |
| `flux_ae.safetensors` | `models/vae/` | FLUX 專屬 VAE 解碼器 |
| `RealVisXL_V5.0_fp16.safetensors` | `models/checkpoints/` | Upscale 階段底模，SDXL 架構，細節還原能力強 |
| `4x-UltraSharp.pth` | `models/upscale_models/` | 超解析度放大核心，適合建築線條與材質紋理 |

> **重要說明 — FLUX Kontext Pro vs Dev：**
> 「FLUX Kontext Pro」並無開源權重，是 Black Forest Labs（BFL）官方 API 服務，需要付費申請 BFL API Key 並保持網路連線才能使用。本工作站本地版使用的主力是 `flux1-kontext-dev.safetensors`（開源 dev 版）。
>
> 若需要使用 Kontext **Pro** 版，請在 ComfyUI 中使用官方 API 節點：
> 1. 安裝 `ComfyUI-FluxKontext` 或 `ComfyUI_bfl_api` 套件
> 2. 在節點中找到 **BFL API - Flux Kontext Pro** 節點
> 3. 將你的 BFL API Key 填入節點的 `api_key` 欄位（或設定環境變數 `BFL_API_KEY`）
> 4. 此節點會透過 HTTPS 呼叫 BFL 端點，每次生成按張計費，不消耗本地 VRAM

---

## 5. 模型下載位置（對應 03_download_models.ps1 選單編號）

執行 `scripts/03_download_models.ps1` 並選擇以下編號：

| 選單編號 | 模型名稱 |
|---|---|
| **A-1** | flux1-kontext-dev.safetensors |
| **A-2** | t5xxl_fp16.safetensors |
| **A-3** | clip_l.safetensors |
| **A-4** | flux_ae.safetensors |
| **B-1** | flux_controlnet_union_pro_2.safetensors |
| **C-1** | RealVisXL_V5.0_fp16.safetensors |
| **D-1** | 4x-UltraSharp.pth |

若下載腳本未包含特定模型，請依腳本說明手動從 Hugging Face 或 Civitai 下載後放置於對應資料夾。

---

## 6. 推薦參數

### FLUX 取樣階段

| 參數 | 值 | 說明 |
|---|---|---|
| 解析度 | 1024×1024 / 1536×1024 / 1920×1080 | 根據 CAD 截圖比例選擇 |
| Steps | 24 | FLUX 最佳品質/速度平衡點 |
| Guidance（CFG-like） | 3.5 | FLUX 使用 guidance scale 而非傳統 CFG |
| Sampler | euler | FLUX 官方推薦 |
| Scheduler | simple | 搭配 euler 使用 |
| Denoise | 1.0 | 完整重繪（txt2img 模式） |
| ControlNet Strength | 0.60–0.75 | 建築精度要求高時調高至 0.75 |
| ControlNet Type | lineart | Union Pro 2 控制類型指定 |

### Upscale 階段

| 參數 | 值 | 說明 |
|---|---|---|
| 底模 | RealVisXL_V5.0_fp16 | 保持建築細節與材質真實感 |
| Upscale 核心 | 4x-UltraSharp.pth | 線條清晰，適合建築渲染 |
| Sampler | dpmpp_2m | 放大階段穩定性佳 |
| Scheduler | karras | 搭配 dpmpp_2m |
| Denoise | 0.18 | 低 denoise 確保放大時不過度改變構圖 |
| 倍率 | x2 | 1536×1024 → 3072×2048 |
| Tile Size | 512 | 防止 VRAM 溢出 |

---

## 7. CFG

FLUX 架構不使用傳統 Classifier-Free Guidance（CFG），而是使用 **Guidance Scale**（也稱 `guidance`）：

- 推薦值：**3.5**
- 有效範圍：2.0–5.0
- 數值越高 → prompt 遵循度越高，但可能出現過度飽和或細節失真
- 數值越低 → 圖像更自然，但 prompt 忠實度下降
- 建築渲染場景建議維持 3.5，若需要更精確的材質呈現可調高至 4.0

在傳統 CFG 欄位輸入值對 FLUX 無效，請確認使用支援 FLUX 的節點（如 `FluxGuidance` 或 `SamplerCustomAdvanced` 的 guider）。

---

## 8. Steps

- 推薦值：**24 steps**
- 最低可用：18 steps（速度優先，細節略減）
- 最高建議：30 steps（品質提升有限，不建議超過）
- FLUX dev 版對 steps 敏感度低於 SDXL；20–28 steps 區間品質差異不大
- 建築渲染需要較清晰的線條和材質，建議維持 24 steps

---

## 9. Sampler

- 推薦：**euler**
- 替代選項：`euler_ancestral`（略帶隨機性，適合偏寫意的渲染風格）
- 不建議使用 DDIM 或 LMS（與 FLUX 相容性差）
- FLUX 官方訓練時使用 euler，因此此 sampler 最能還原預期輸出

---

## 10. Scheduler

- 推薦：**simple**
- 替代：`sgm_uniform`（步數分佈更均勻，細節略有不同）
- 不建議使用 `karras` 或 `exponential`（為 SDXL 系設計，搭配 FLUX 效果次佳）
- `simple` scheduler 在 FLUX 的流式匹配架構下表現最穩定

---

## 11. VRAM 使用量（RTX 4080 32GB 實測估計）

| 階段 | 估計 VRAM 用量 |
|---|---|
| 模型載入（FLUX dev + T5 + CLIP-L + VAE） | ~16 GB |
| FLUX 取樣中（1536×1024，fp16） | **18–22 GB** |
| ControlNet Union Pro 2 啟用後額外佔用 | +1–2 GB |
| VAE Decode | ~18–20 GB |
| Upscale 階段（RealVisXL + 4x-UltraSharp，512 tile） | **+4–6 GB（峰值 ~24 GB）** |
| 全流程峰值 VRAM | **約 24–26 GB** |

32GB VRAM 有充足餘裕，全程無需啟用 `--lowvram` 或 CPU offload。

---

## 12. RTX 4080 32GB 最佳設定

**ComfyUI 啟動參數（`run_comfyui.bat`）：**
```
python main.py --force-fp16 --gpu-only
```

- `--force-fp16`：強制全程使用 fp16 精度，32GB VRAM 足夠，速度比 fp32 快約 40%
- `--gpu-only`：禁止 CPU offload，避免 RAM↔VRAM 資料搬移造成瓶頸
- 不需要 `--lowvram` 或 `--medvram`

**節點層級最佳化：**
- UNETLoader 精度選 `fp16`（非 `default`）
- VAELoader 精度選 `fp16`
- ControlNet 節點中 `strength` 不超過 0.8（超過會降低 FLUX 創意空間且增加 VRAM 佔用）
- Ultimate SD Upscale 的 `tile_size` 設為 512，`tile_overlap` 設為 64

**Windows 11 系統設定：**
- 關閉 Hardware-accelerated GPU Scheduling（HAGS）可提升 VRAM 穩定性
- Page file 建議設為 32GB 以上（備用 swap）
- 生成期間關閉 Chrome 等高 VRAM 佔用應用

---

## 13. 預估生成速度 + 常見錯誤排除

### 預估速度（RTX 4080 32GB，fp16，GPU-only）

| 解析度 | Steps | 估計時間 |
|---|---|---|
| 1024×1024 | 24 | ~20–28 秒 |
| 1536×1024 | 24 | **~30–50 秒** |
| 1920×1080 | 24 | ~45–70 秒 |
| 1536×1024 + Upscale x2 | 24+放大 | ~60–90 秒（含放大） |

### 常見錯誤排除

**錯誤：`CUDA out of memory`**
- 原因：Upscale tile size 過大，或同時開啟其他 GPU 應用
- 解法：將 Ultimate SD Upscale 的 `tile_size` 從 1024 調降至 512；關閉瀏覽器、遊戲等

**錯誤：`LineArt Preprocessor not found`**
- 原因：未安裝 `comfyui_controlnet_aux` 套件
- 解法：透過 ComfyUI Manager 搜尋並安裝 `comfyui_controlnet_aux`，重啟 ComfyUI

**錯誤：`ControlNet model type mismatch`**
- 原因：誤用了 SD1.5 或 SDXL 的 ControlNet 模型
- 解法：確認使用 `flux_controlnet_union_pro_2.safetensors`，並確認節點為 FLUX ControlNet Apply

**錯誤：建築線條在渲染圖中消失或扭曲**
- 原因：ControlNet strength 過低（< 0.5）
- 解法：調高至 0.65–0.75；確認 control type 設為 `lineart`

**錯誤：渲染圖風格不符預期**
- 原因：T5 prompt 太短或描述不精確
- 解法：FLUX T5 編碼器支援長文字（最多 512 tokens），請提供完整的材質、光線、時段、視角描述

---

## 範例 Prompt

### 日景住宅
```
A modern two-story residential house, white stucco facade, floor-to-ceiling windows,
wooden deck, green lawn, mature trees, blue sky with scattered clouds,
warm afternoon sunlight, sharp shadows, photorealistic architectural rendering,
8k, ultra detailed
```

### 夜景商辦
```
A contemporary office tower, glass curtain wall facade, illuminated interior lights,
reflective glass panels, urban street scene, nighttime, city lights in background,
dramatic uplighting, photorealistic, high-end architectural visualization
```

### 鳥瞰住宅社區
```
Aerial view of a residential complex, bird's eye perspective, 45 degree angle,
multiple villa buildings, swimming pool, parking lot, landscaped gardens,
daytime, clear weather, photorealistic satellite-style render, 8k
```

### 雨景街景
```
Street level view of a mixed-use commercial building, rainy day, wet pavement
reflections, pedestrians with umbrellas, motion blur on vehicles, grey overcast sky,
moody atmosphere, photorealistic urban architectural photography
```
