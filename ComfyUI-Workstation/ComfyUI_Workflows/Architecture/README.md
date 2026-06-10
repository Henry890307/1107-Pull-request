# Architecture_Pro 工作流說明

對應工作流檔案：`Architecture_Pro.json`

---

## 1. 工作流用途

本工作流專為建築設計師與城市規劃師設計，能將 AutoCAD、Revit 匯出的平面圖、立面圖、剖面圖或其他 CAD 截圖，透過 FLUX ControlNet（Union Pro 2）與 FLUX Kontext dev 本地模型，快速轉換為具備高度真實感的建築渲染圖。

支援以下場景類型（透過更換 Positive Prompt 切換，無需調整節點參數）：

| 場景類型 | Prompt 關鍵詞範例 |
|---------|------------------|
| 日景 | `daytime, bright sunlight, clear blue sky, warm golden hour light, sharp shadows` |
| 夜景 | `nighttime, city lights, illuminated facade, dramatic artificial lighting, reflective glass` |
| 雨景 | `rainy day, wet pavement reflections, overcast sky, misty atmosphere, glistening surfaces` |
| 住宅 | `residential building, cozy neighborhood, green landscaping, suburban setting` |
| 商辦 | `commercial office tower, glass curtain wall, corporate architecture, urban skyline` |
| 鳥瞰 | `aerial view, bird's eye perspective, 45 degree angle, urban masterplan, top-down` |
| 街景 | `street level view, pedestrian perspective, sidewalk, city streetscape` |

支援輸出解析度：`1024x1024`、`1536x1024`、`1920x1080`

---

## 2. 節點流程圖

```
[LoadImage — CAD 截圖 / 線稿圖]
              |
              v
[AnyLineArtPreprocessor — LineArt 預處理]
    (comfyui_controlnet_aux 套件)
              |
              v
[Apply ControlNet — flux_controlnet_union_pro_2.safetensors]
    control_type: lineart  |  strength: 0.75
              |
              v
[DualCLIPLoader]                        [CLIPTextEncode — Positive Prompt]
(t5xxl_fp16 + clip_l)                   [CLIPTextEncode — Negative Prompt]
              |                                      |
              +--------------------+----------------+
                                   |
                                   v
                  [UNETLoader — flux1-kontext-dev.safetensors]
                  [ModelSamplingFlux — max_shift 1.15, base_shift 0.5]
                  [SamplerCustomAdvanced / KSampler]
                   steps 24 | guidance 3.5 | euler | simple | denoise 1.0
                                   |
                                   v
                  [VAELoader — flux_ae.safetensors]
                  [VAEDecode]
                                   |
                                   v
                  [Ultimate SD Upscale x2]
                  (RealVisXL_V5.0_fp16.safetensors 底模)
                  (4x-UltraSharp.pth 放大核心)
                  dpmpp_2m | karras | denoise 0.18 | tile 512
                                   |
                                   v
                          [SaveImage — 輸出]
```

---

## 3. 各節點用途說明

### LoadImage
載入 AutoCAD 截圖或 CAD 線稿圖。建議格式：PNG（避免 JPEG 壓縮造成線條模糊）。輸入圖建議預先裁切為目標長寬比（16:9 或 3:2），以確保 ControlNet 比例正確對應。

### AnyLineArtPreprocessor（LineArt 預處理器）
屬於 `comfyui_controlnet_aux` 套件節點。將 CAD 截圖轉換為標準化 LineArt 特徵圖，有效保留建築輪廓線、窗框、結構邊界，同時濾除背景雜訊。建議設定：`resolution: 1024`、`coarse: false`（保留細線）。此預處理是結構控制的關鍵，直接決定 ControlNet 能否正確辨識建築幾何。

### Apply ControlNet（flux_controlnet_union_pro_2）
套用 `flux_controlnet_union_pro_2.safetensors`，將 LineArt 特徵圖注入 FLUX 生成流程，確保生成結果的建築結構與 CAD 原稿高度吻合。
- `strength`：0.75（保留 CAD 結構的同時給予模型足夠的渲染自由度）
- `control_type`：lineart
- `start_percent`：0.0
- `end_percent`：0.85（後段釋放，讓模型補充材質細節）

### DualCLIPLoader
載入 FLUX 專用的雙 CLIP 文字編碼器。`t5xxl_fp16.safetensors` 負責長文本語意理解（最多 512 tokens），`clip_l.safetensors` 負責對齊視覺特徵。兩者必須同時載入，缺一不可。

### CLIPTextEncode（Positive / Negative）
FLUX 支援長文字描述，Positive Prompt 建議包含：場景類型、建築風格、材質描述、光線條件、品質標籤。Negative Prompt 用於排除不需要的視覺元素（詳見第 6 段範例）。

### UNETLoader + ModelSamplingFlux
載入 `flux1-kontext-dev.safetensors` 主模型，並套用 FLUX 專用取樣校正節點（`ModelSamplingFlux`），設定 `max_shift: 1.15`、`base_shift: 0.5`，確保取樣過程穩定。

### SamplerCustomAdvanced / KSampler
執行 FLUX 去噪取樣。FLUX 使用 `guidance` 參數（非傳統 CFG），建議 3.5。採用 euler sampler + simple scheduler 官方推薦組合，steps 24。

### VAELoader + VAEDecode
載入 `flux_ae.safetensors` 並將潛空間張量解碼為 RGB 圖像。FLUX VAE 採用 16 通道架構，解碼品質顯著優於 SD1.5/SDXL 的 4 通道 VAE，色彩準確度與細節還原能力更強。

### Ultimate SD Upscale（放大節點）
使用 RealVisXL_V5.0_fp16 與 4x-UltraSharp 模型對圖像進行 2 倍放大，搭配低 denoise（0.18）重繪以補充放大後的材質細節，同時不破壞整體構圖。此節點將圖像分割為多個 512px tile 分批處理，避免 VRAM 溢出。
- `tile_width / tile_height`：512
- `padding`：32
- `seam_fix_mode`：Band Pass（消除 tile 接縫）
- `seam_fix_denoise`：0.20

---

## 4. 用到的模型與用途

| 模型檔案 | 存放路徑 | 用途 |
|---------|---------|------|
| `flux1-kontext-dev.safetensors` | `models/diffusion_models/` | 主生成模型，FLUX Kontext dev 本地開源版 |
| `flux_controlnet_union_pro_2.safetensors` | `models/controlnet/` | FLUX 專用 Union ControlNet，支援 lineart/depth/canny 等多種控制類型 |
| `t5xxl_fp16.safetensors` | `models/clip/` | FLUX T5-XXL 文字編碼器（長文本語意）|
| `clip_l.safetensors` | `models/clip/` | FLUX CLIP-L 文字編碼器（視覺特徵對齊）|
| `flux_ae.safetensors` | `models/vae/` | FLUX 專用 VAE 解碼器 |
| `RealVisXL_V5.0_fp16.safetensors` | `models/checkpoints/` | Upscale 階段底模，SDXL 架構，建築材質還原能力強 |
| `4x-UltraSharp.pth` | `models/upscale_models/` | 超解析度放大核心，適合建築線條與材質紋理 |

> **重要說明：FLUX Kontext Pro vs Dev（必讀）**
>
> `flux1-kontext-dev.safetensors` 是本工作站的**本地開源版本**，可完全離線運行，無需 API Key。
>
> **「FLUX Kontext Pro」沒有開源權重**，是 Black Forest Labs（BFL）官方 API 服務，只能透過網路呼叫，需付費取得 BFL API Key。無論在 Hugging Face、Civitai 或其他管道都找不到可下載的 Pro 版模型檔案。
>
> 若要在 ComfyUI 中使用 Kontext **Pro** 版 API，步驟如下：
> 1. 前往 [https://api.bfl.ml](https://api.bfl.ml) 申請 BFL API Key（付費服務，依生成張數計費）
> 2. 透過 ComfyUI Manager 安裝 `ComfyUI-FluxKontext` 或 `ComfyUI_bfl_api` 套件
> 3. 在工作流中以 **BFL API Flux Kontext Pro** 節點取代 `UNETLoader` + `KSampler`
> 4. 在節點的 `api_key` 欄位填入你的 BFL API Key（或設定環境變數 `BFL_API_KEY`）
> 5. 每次執行節點時，ComfyUI 透過 HTTPS 傳送請求至 BFL 端點，結果回傳後在本地解碼；不消耗本地 VRAM，但需要穩定的網路連線

---

## 5. 模型下載位置（對應 03_download_models.ps1 選單編號）

執行 `scripts/03_download_models.ps1` 並選擇對應編號：

| 選單編號 | 模型名稱 | 下載後存放路徑 |
|---------|---------|--------------|
| A-1 | flux1-kontext-dev.safetensors | models/diffusion_models/ |
| A-2 | t5xxl_fp16.safetensors | models/clip/ |
| A-3 | clip_l.safetensors | models/clip/ |
| A-4 | flux_ae.safetensors | models/vae/ |
| B-1 | flux_controlnet_union_pro_2.safetensors | models/controlnet/ |
| C-1 | RealVisXL_V5.0_fp16.safetensors | models/checkpoints/ |
| D-1 | 4x-UltraSharp.pth | models/upscale_models/ |

若下載腳本未包含特定模型，請依腳本說明手動從 Hugging Face 或 Civitai 下載並放置於對應目錄。

---

## 6. 推薦參數

### FLUX Kontext Dev 取樣階段

| 參數 | 推薦值 | 說明 |
|------|--------|------|
| 解析度 | 1536x1024 | 建議主力解析度，符合 16:9 建築渲染標準 |
| Steps | 24 | FLUX 最佳品質/速度平衡點 |
| Guidance（CFG） | 3.5 | FLUX 使用 guidance 而非傳統 CFG，3.5 為最佳範圍 |
| Sampler | euler | FLUX 官方推薦 sampler |
| Scheduler | simple | FLUX 專用 scheduler，與 euler 搭配最穩定 |
| Denoise | 1.0 | 完整生成（txt2img 模式） |
| ControlNet strength | 0.75 | 建築精度要求高；可依需求調整 0.6-0.85 |
| ControlNet type | lineart | Union Pro 2 控制類型指定 |

### Upscale 放大階段（Ultimate SD Upscale）

| 參數 | 推薦值 | 說明 |
|------|--------|------|
| 底模 | RealVisXL_V5.0_fp16 | 保持建築細節與材質真實感 |
| 放大核心 | 4x-UltraSharp.pth | 線條清晰，適合建築渲染 |
| Sampler | dpmpp_2m | 放大階段穩定性佳 |
| Scheduler | karras | 配合 dpmpp_2m 效果最佳 |
| Denoise | 0.18 | 低重繪率，補充細節但不改變結構 |
| 放大倍率 | x2 | 1536x1024 → 3072x2048 |
| Tile Size | 512 | 分塊處理，防止 VRAM 溢出 |
| Tile Padding | 32 | 相鄰 tile 重疊，避免接縫 |

### Positive Prompt 範例

**日景住宅：**
```
daytime, modern two-story residential house, white stucco facade,
floor-to-ceiling windows, wooden deck, green lawn, mature trees,
clear blue sky, warm afternoon sunlight, sharp shadows,
photorealistic architectural rendering, 8k, ultra detailed
```

**夜景商辦：**
```
nighttime, contemporary office tower, glass curtain wall, illuminated facade,
urban skyline, city lights, dramatic uplighting, reflective glass panels,
photorealistic architectural visualization, high detail, 8k
```

**鳥瞰住宅社區：**
```
aerial view, bird's eye perspective, 45 degree angle, residential complex,
multiple villa buildings, swimming pool, landscaped gardens, parking lot,
daytime, clear weather, photorealistic masterplan render, 8k
```

### Negative Prompt 範例
```
blurry, cartoon, sketch, painting, unrealistic proportions, distorted geometry,
low quality, watermark, text overlay, oversaturated, lens flare,
fish-eye distortion, impossible architecture
```

---

## 7. CFG（Guidance Scale）

FLUX 架構不使用傳統 Classifier-Free Guidance（CFG），而是使用獨立的 **Guidance Scale** 參數（在 `FluxGuidance` 節點或 `SamplerCustomAdvanced` 的 guider 中設定）。

- **推薦值：3.5**
- 有效範圍：2.0–5.0
- `guidance < 2.5`：生成結果過於自由，可能忽略 prompt 與 ControlNet 約束，建築線條失真
- `guidance 3.0–4.0`：最佳範圍，prompt 遵循度與創意自由度平衡
- `guidance > 5.0`：過度飽和，色調失真，建築材質卡通化

> 注意：在傳統 `KSampler` 的 CFG 欄位輸入值對 FLUX **無效**，請確認使用支援 FLUX 的 `SamplerCustomAdvanced` 或 `FluxGuidance` 節點。

---

## 8. Steps

- **推薦值：24 steps**
- 最低可用：18 steps（速度優先，細節略減，適合快速預覽）
- 最高建議：28 steps（品質提升有限，時間成本不划算）
- FLUX dev 版對 steps 敏感度低於 SDXL；20–26 steps 區間品質差異不大
- 建築渲染需要清晰的線條和材質細節，建議維持 24 steps

---

## 9. Sampler

- **推薦：euler**（FLUX 官方訓練所用 sampler）
- 替代選項：`euler_ancestral`（略帶隨機性，適合偏寫意渲染風格，但建築線條略軟）
- `dpmpp_2m`：可用但需搭配 karras scheduler，品質略遜於 euler + simple
- `heun`：品質略高但速度慢一倍，僅適合最終高品質輸出
- 不建議使用 DDIM、LMS（與 FLUX 相容性差，可能產生偽影）

---

## 10. Scheduler

- **推薦：simple**（FLUX 專用 noise schedule）
- 替代：`sgm_uniform`（步數分佈更均勻，細節略有差異）
- 不建議使用 `karras` 或 `exponential`（為 SDXL 系設計，搭配 FLUX 效果次佳）
- `simple` scheduler 在 FLUX 的流式匹配（flow matching）架構下表現最穩定，是官方推薦組合

---

## 11. VRAM 使用量（RTX 4080 32GB 實際估計）

| 階段 | 估計 VRAM 用量 | 備註 |
|------|--------------|------|
| 模型載入（flux1-kontext-dev + T5 + CLIP-L + VAE） | ~16 GB | fp16 完整模型 |
| FLUX 取樣（1024x1024，24 steps） | ~18 GB | 含 ControlNet |
| FLUX 取樣（1536x1024，24 steps） | ~18–22 GB | 主力解析度 |
| FLUX 取樣（1920x1080，24 steps） | ~20–24 GB | 高解析度 |
| VAEDecode | +2 GB 額外 | FLUX 16 通道 VAE |
| Ultimate SD Upscale（RealVisXL，512 tile） | +6–8 GB 額外 | 峰值約 24–28 GB |
| 全流程峰值 VRAM | **約 24–28 GB** | 32GB 卡完整執行 |

32GB VRAM 充足，全程無需啟用 `--lowvram` 或 CPU offload，所有模型均使用 fp16 精度。

---

## 12. RTX 4080 32GB 最佳設定

**ComfyUI 啟動參數（`run_comfyui.bat` 或 PowerShell 腳本）：**
```batch
python main.py --force-fp16 --gpu-only
```

| 啟動參數 | 說明 |
|---------|------|
| `--force-fp16` | 強制全流程使用 fp16 精度，速度比 fp32 快約 40%，32GB 足夠 |
| `--gpu-only` | 禁止 CPU offload，避免 RAM↔VRAM 資料搬移造成速度瓶頸 |

不需要加的參數（32GB 無需）：
- ~~`--lowvram`~~
- ~~`--medvram`~~
- ~~`--cpu`~~（僅偵錯用途）

**節點層級最佳化：**
- `UNETLoader` 精度選 `fp16`（非 `default`）
- `VAELoader` 精度選 `fp16`
- `ControlNet strength` 不超過 0.85（超過會明顯降低 FLUX 創意空間）
- `Ultimate SD Upscale` 的 `tile_size` 設為 512，`tile_overlap` 設為 64

**Windows 11 系統調校：**
- 建議關閉 Hardware-accelerated GPU Scheduling（HAGS），可提升 VRAM 分配穩定性
- Page file 設為 32GB 以上（備用 swap，避免 OOM crash）
- 生成期間關閉瀏覽器、串流軟體等高 VRAM 占用應用程式

---

## 13. 預估生成速度 + 常見錯誤排除

### 預估生成速度（RTX 4080 32GB，fp16，gpu-only）

| 操作 | 解析度 | 預估時間 |
|------|--------|---------|
| FLUX 取樣（24 steps） | 1024x1024 | 約 20–28 秒 |
| FLUX 取樣（24 steps） | 1536x1024 | **約 30–50 秒** |
| FLUX 取樣（24 steps） | 1920x1080 | 約 45–70 秒 |
| Ultimate SD Upscale x2 | 1536→3072 | 約 40–60 秒 |
| 全流程（1536 + Upscale） | — | **約 70–110 秒** |

### 常見錯誤排除

**錯誤：`CUDA out of memory`**
- 原因：Upscale tile size 過大，或生成期間同時開啟高 VRAM 應用
- 解法：將 `Ultimate SD Upscale` 的 `tile_size` 從 1024 調降至 512；生成前關閉瀏覽器

**錯誤：`AnyLineArtPreprocessor not found` / `LineArt Preprocessor not found`**
- 原因：未安裝 `comfyui_controlnet_aux` 套件
- 解法：透過 ComfyUI Manager 搜尋並安裝 `comfyui_controlnet_aux`，完成後重啟 ComfyUI

**錯誤：`ControlNet model type mismatch`**
- 原因：誤用了 SD1.5 或 SDXL 的 ControlNet 模型
- 解法：確認 ControlNet 節點載入的是 `flux_controlnet_union_pro_2.safetensors`，且使用 FLUX Apply ControlNet 節點（非 SD1.5 版）

**錯誤：建築線條在渲染圖中消失或結構扭曲**
- 原因：ControlNet strength 過低（< 0.5）或 LineArt 預處理 resolution 不足
- 解法：strength 調高至 0.65–0.75；AnyLineArtPreprocessor 的 `resolution` 設為與輸入圖相同寬度（最低 768）

**錯誤：`VAEDecode` 後圖像顏色偏紫/偏青**
- 原因：使用了錯誤的 VAE（SD1.5 或 SDXL 的 VAE）
- 解法：確認 `VAELoader` 載入的是 `flux_ae.safetensors`，而非其他 VAE

**錯誤：`t5xxl` 或 `clip_l` 模型載入失敗**
- 原因：模型放置路徑錯誤或檔案名稱不符
- 解法：確認 `t5xxl_fp16.safetensors` 和 `clip_l.safetensors` 均位於 `ComfyUI/models/clip/` 目錄下

**錯誤：Ultimate SD Upscale 放大後 tile 接縫明顯**
- 原因：`seam_fix_mode` 未啟用或設定不當
- 解法：將 `seam_fix_mode` 設為 `Band Pass`，`seam_fix_denoise` 設為 0.15–0.25，`seam_fix_width` 設為 64
