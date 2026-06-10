# Interior_Design_Pro 工作流說明

對應工作流檔案：`Interior_Design_Pro.json`

---

## 1. 工作流用途

本工作流專為室內設計師設計，能將 SketchUp、3ds Max 或其他建模軟體的截圖（未渲染的線框圖或草稿圖），透過雙 ControlNet（Depth + Canny）與 FLUX Kontext dev 本地模型，轉換為具備高真實感的室內渲染圖。

核心設計理念：
- **Depth ControlNet（depth_fp16）**：保留空間比例與深度關係，確保家具位置、天花板高度、透視鏡頭角度與 SketchUp 原稿一致
- **Canny ControlNet（canny_fp16）**：保留硬邊輪廓線，確保牆面轉角、家具邊界、門窗框線維持原始幾何精度

兩組 ControlNet 協同工作，各自負責不同維度的結構約束，使渲染結果在空間感與線條精度上均能忠實還原設計意圖。

支援室內設計風格（透過 Positive Prompt 切換）：
- 現代簡約（Modern Minimalist）
- 北歐風格（Scandinavian）
- 工業風格（Industrial Loft）
- 日式侘寂（Wabi-sabi / Japandi）
- 奢華古典（Luxury Classical）
- 現代奢華（Modern Luxury / Contemporary）

輸出解析度：`1536x1024`（主力）、`1024x1024`、`1024x768`

---

## 2. 節點流程圖

```
[LoadImage — SketchUp 截圖 / 3D 草稿圖]
                 |
        +--------+--------+
        |                 |
        v                 v
[Depth Preprocessor]  [Canny Preprocessor]
  (MiDaS / Zoe)        (CannyEdgePreprocessor)
  resolution: 1024      low_threshold: 100
        |                 |  high_threshold: 200
        v                 v
[Apply ControlNet — Depth]    [Apply ControlNet — Canny]
  control_v11f1p_sd15_depth_fp16   control_v11p_sd15_canny_fp16
  (透過 FLUX Union ControlNet 橋接)
  strength: 0.55                    strength: 0.45
        |                 |
        +---------+-------+
                  |
                  v
[DualCLIPLoader]                    [CLIPTextEncode — Positive Prompt]
(t5xxl_fp16 + clip_l)               [CLIPTextEncode — Negative Prompt]
                  |                            |
                  +----------+----------------+
                             |
                             v
            [UNETLoader — flux1-kontext-dev.safetensors]
            [ModelSamplingFlux — max_shift 1.15, base_shift 0.5]
            [SamplerCustomAdvanced]
             steps 24 | guidance 3.5 | euler | simple | denoise 1.0
                             |
                             v
            [VAELoader — flux_ae.safetensors]
            [VAEDecode]
                             |
                             v
                    [SaveImage — 輸出]
```

---

## 3. 各節點用途說明

### LoadImage
載入 SketchUp 截圖、3ds Max 視口截圖或其他 3D 建模軟體的預覽圖。建議使用 PNG 格式以保留最佳邊緣資訊供 Canny 預處理器使用。輸入圖應包含完整的室內空間透視構圖，不建議裁切後只剩局部畫面。

### Depth Preprocessor（MiDaS / ZoeDepth）
屬於 `comfyui_controlnet_aux` 套件節點。從輸入截圖中估算深度資訊，輸出灰階深度圖（近白遠黑）。此深度圖傳入 Depth ControlNet，讓 FLUX 在生成時保持空間的三維比例關係，包含透視縮短、家具前後層次、天花板高度感。

建議使用 `ZoeDepthMapPreprocessor`（深度估算精度高於 MiDaS），設定：
- `resolution`：1024

### Canny Preprocessor（CannyEdgePreprocessor）
從輸入截圖中提取硬邊緣特徵。輸出二值化邊緣圖，傳入 Canny ControlNet，確保牆面轉角、門窗框線、家具輪廓保持與原稿幾何完全吻合。

建議設定：
- `low_threshold`：100
- `high_threshold`：200
- `resolution`：1024

若 SketchUp 截圖為線框模式，Canny 提取到的邊緣會非常清晰，ControlNet strength 可適當降低至 0.35。若截圖為彩色上色模式，建議維持 0.45 或稍高。

### Apply ControlNet — Depth（strength 0.55）
套用 `control_v11f1p_sd15_depth_fp16.safetensors`，將深度特徵圖注入 FLUX 生成流程。**Depth 強度設為 0.55**，高於 Canny 的 0.45，原因是空間比例的整體感比局部線條更難從 prompt 文字中還原，因此給予深度更高的優先權。

- `start_percent`：0.0
- `end_percent`：0.80（後段釋放，讓模型自由添加材質細節）

### Apply ControlNet — Canny（strength 0.45）
套用 `control_v11p_sd15_canny_fp16.safetensors`，將邊緣特徵圖注入 FLUX 生成流程。**Canny 強度設為 0.45**，確保家具輪廓與牆面邊界清晰，同時保留材質貼圖的自由度。

- `start_percent`：0.0
- `end_percent`：0.90（比 Depth 稍長，確保邊線細節在更後期的步驟中仍維持）

> **雙 ControlNet 協同說明：**
> 兩組 ControlNet 同時注入同一個 FLUX 取樣過程，強度相加約 1.0，這在 FLUX 的 Union ControlNet 架構下是合理且穩定的。若覺得渲染結果過於接近原始截圖色調，可將兩組 strength 分別降低 0.05。

### DualCLIPLoader
載入 `t5xxl_fp16.safetensors` + `clip_l.safetensors`，FLUX 必須同時使用兩個文字編碼器。T5-XXL 負責解析室內設計的長文字風格描述，CLIP-L 負責對齊視覺特徵。

### CLIPTextEncode（Positive / Negative）
室內渲染 Positive Prompt 建議涵蓋：風格名稱、主要材質、光源類型、氛圍描述、品質標籤。詳見第 6 段範例。

### UNETLoader + ModelSamplingFlux
載入 `flux1-kontext-dev.safetensors`，搭配 `ModelSamplingFlux` 節點設定 `max_shift: 1.15`、`base_shift: 0.5`。

### SamplerCustomAdvanced
執行 FLUX 去噪取樣。guidance 3.5，steps 24，euler sampler，simple scheduler，denoise 1.0（完整生成）。

### VAELoader + VAEDecode
載入 `flux_ae.safetensors` 進行解碼。FLUX 的 16 通道 VAE 在材質貼圖、織物紋理、木紋細節等室內渲染關鍵元素上表現尤為出色。

---

## 4. 用到的模型與用途

| 模型檔案 | 存放路徑 | 用途 |
|---------|---------|------|
| `flux1-kontext-dev.safetensors` | `models/diffusion_models/` | 主生成模型，FLUX Kontext dev 本地開源版 |
| `control_v11f1p_sd15_depth_fp16.safetensors` | `models/controlnet/` | Depth ControlNet，保留空間比例與深度感（strength 0.55）|
| `control_v11p_sd15_canny_fp16.safetensors` | `models/controlnet/` | Canny ControlNet，保留邊緣輪廓線（strength 0.45）|
| `t5xxl_fp16.safetensors` | `models/clip/` | FLUX T5-XXL 文字編碼器（長文本語意）|
| `clip_l.safetensors` | `models/clip/` | FLUX CLIP-L 文字編碼器（視覺特徵對齊）|
| `flux_ae.safetensors` | `models/vae/` | FLUX 專用 VAE 解碼器 |

> **重要說明：FLUX Kontext Pro vs Dev（必讀）**
>
> `flux1-kontext-dev.safetensors` 是本工作站的**本地開源版本**，完全離線運行。
>
> **「FLUX Kontext Pro」沒有開源權重**，是 BFL 官方付費 API 服務，無法下載使用。若需要呼叫 Pro 版 API，請參閱 Architecture README 的第 4 段說明，安裝 `ComfyUI_bfl_api` 套件並填入 BFL API Key。

---

## 5. 模型下載位置（對應 03_download_models.ps1 選單編號）

執行 `scripts/03_download_models.ps1` 並選擇對應編號：

| 選單編號 | 模型名稱 | 下載後存放路徑 |
|---------|---------|--------------|
| A-1 | flux1-kontext-dev.safetensors | models/diffusion_models/ |
| A-2 | t5xxl_fp16.safetensors | models/clip/ |
| A-3 | clip_l.safetensors | models/clip/ |
| A-4 | flux_ae.safetensors | models/vae/ |
| B-2 | control_v11f1p_sd15_depth_fp16.safetensors | models/controlnet/ |
| B-3 | control_v11p_sd15_canny_fp16.safetensors | models/controlnet/ |

若腳本未包含特定模型，請從 Hugging Face `lllyasviel/ControlNet-v1-1` 手動下載對應 fp16 版本。

---

## 6. 推薦參數

### FLUX Kontext Dev 取樣階段

| 參數 | 推薦值 | 說明 |
|------|--------|------|
| 解析度 | 1536x1024 | 室內渲染主力解析度，水平構圖 |
| Steps | 24 | FLUX 最佳品質/速度平衡點 |
| Guidance | 3.5 | FLUX guidance scale 推薦值 |
| Sampler | euler | FLUX 官方推薦 |
| Scheduler | simple | FLUX 專用 scheduler |
| Denoise | 1.0 | 完整生成（txt2img 模式） |
| Depth ControlNet strength | 0.55 | 保留空間比例（優先於 Canny）|
| Canny ControlNet strength | 0.45 | 保留邊緣輪廓線 |

### Positive Prompt 範例

**現代簡約客廳（日景）：**
```
modern minimalist living room, afternoon sunlight through floor-to-ceiling windows,
white walls, light oak wood flooring, grey linen sofa, low-profile coffee table,
indoor plants, warm natural lighting, architectural interior photography,
photorealistic, 8k, ultra detailed
```

**北歐風格臥室：**
```
Scandinavian bedroom, neutral tones, white bedding, light wood furniture,
textured linen curtains, soft diffused morning light, hygge atmosphere,
minimalist decor, photorealistic interior rendering, high detail, 8k
```

**工業風格餐廳：**
```
industrial loft dining room, exposed brick wall, concrete ceiling,
pendant Edison bulb lights, dark wood dining table, metal chairs,
warm evening light, moody atmosphere, photorealistic interior photography, 8k
```

**日式侘寂茶室：**
```
Japanese wabi-sabi tea room, tatami floor, shoji paper screen windows,
bamboo accents, asymmetric ceramic vase, dim warm light, zen atmosphere,
minimalist Japanese interior, photorealistic, ultra detailed
```

**奢華古典主臥：**
```
luxury classical master bedroom, high ceiling, ornate crown molding,
crystal chandelier, silk bedding, dark mahogany furniture, marble floor,
dramatic warm lighting, photorealistic luxury interior photography, 8k
```

### Negative Prompt 範例
```
cartoon, illustration, painting, unrealistic, distorted perspective,
wrong proportions, broken geometry, blurry, low quality, watermark,
text overlay, oversaturated, flat lighting, blown-out highlights
```

---

## 7. CFG（Guidance Scale）

FLUX 使用獨立的 **Guidance Scale** 參數，而非傳統 CFG。

- **推薦值：3.5**
- 室內渲染特別注意：室內場景材質豐富（木紋、織物、金屬反光），guidance 過高（> 4.5）容易導致材質過度飽和失真
- `guidance 3.0–3.5`：材質自然、光線柔和，推薦用於住宅室內
- `guidance 3.5–4.0`：細節更清晰，適合商業空間或展示用渲染

---

## 8. Steps

- **推薦值：24 steps**
- 室內渲染對 steps 的需求略高於建築外觀，因為材質細節（織物紋理、地板木紋、牆面粉刷）需要足夠的去噪步數才能精細呈現
- 最低可用：20 steps（快速預覽）
- 最高建議：28 steps（最終輸出品質）
- 不建議超過 30 steps（邊際收益遞減，增加等待時間）

---

## 9. Sampler

- **推薦：euler**（FLUX 官方推薦，生成室內材質細節最穩定）
- 替代：`euler_ancestral`（隨機性略高，有時能產生更豐富的材質變化，適合探索階段）
- `dpmpp_2m` 搭配 `karras`：可用，但在室內渲染細節上略遜於 euler + simple
- 不建議 DDIM（與 FLUX 架構不匹配）

---

## 10. Scheduler

- **推薦：simple**（FLUX 流式匹配架構的最佳搭配）
- 替代：`sgm_uniform`（步數分佈稍更均勻）
- 不建議：`karras`、`exponential`（SDXL 設計，與 FLUX 組合效果次佳）

---

## 11. VRAM 使用量（RTX 4080 32GB 實際估計）

| 階段 | 估計 VRAM 用量 | 備註 |
|------|--------------|------|
| 模型載入（flux1-kontext-dev + T5 + CLIP-L + VAE） | ~16 GB | fp16 完整模型 |
| Depth 預處理（ZoeDepth） | +0.5 GB | 短暫占用，完成後釋放 |
| Canny 預處理 | +0.2 GB | 短暫占用，完成後釋放 |
| FLUX 取樣（1536x1024，含雙 ControlNet） | ~19–23 GB | 雙 ControlNet 額外佔用約 2–3 GB |
| VAEDecode | ~18–20 GB | 取樣後略降 |
| 全流程峰值 VRAM | **約 20–24 GB** | 32GB 卡有充足餘裕 |

無 Upscale 階段（本工作流不含放大），VRAM 需求低於 Architecture 工作流，全流程最高約 24GB。

---

## 12. RTX 4080 32GB 最佳設定

**ComfyUI 啟動參數：**
```batch
python main.py --force-fp16 --gpu-only
```

| 啟動參數 | 說明 |
|---------|------|
| `--force-fp16` | 強制 fp16 精度，速度最大化 |
| `--gpu-only` | 禁止 CPU offload，維持速度 |

**節點層級最佳化：**
- `ZoeDepthMapPreprocessor` 優先於 `MiDaS`（深度估算精度更高，對室內家具位置還原更準確）
- 雙 ControlNet 若需進一步調整平衡，建議 Depth 維持 >= 0.50，Canny 維持 >= 0.35
- 可在 VAEDecode 前加入 `ImageSharpening` 節點（strength 0.3）增強材質細節清晰度
- 若輸出解析度為 1024x768，可在 SaveImage 後選擇性接 `ImageScaleToTotalPixels` 調整最終尺寸

**Windows 11 系統調校：**
- 雙 ControlNet 同時運行時 VRAM 峰值較高，建議關閉其他 GPU 應用
- 深度預處理器（ZoeDepth）首次執行會下載額外模型（約 300MB），需要網路連線

---

## 13. 預估生成速度 + 常見錯誤排除

### 預估生成速度（RTX 4080 32GB，fp16，gpu-only）

| 操作 | 解析度 | 預估時間 |
|------|--------|---------|
| Depth + Canny 預處理 | 1536x1024 | 約 3–5 秒（含）|
| FLUX 取樣（24 steps，雙 ControlNet） | 1536x1024 | 約 35–55 秒 |
| VAEDecode | 1536x1024 | 約 3–5 秒 |
| 全流程 | 1536x1024 | **約 40–65 秒** |

### 常見錯誤排除

**錯誤：渲染結果空間比例嚴重失真（家具大小比例錯誤）**
- 原因：Depth ControlNet strength 過低，或深度預處理器輸出品質差
- 解法：將 Depth strength 提高至 0.60–0.65；改用 `ZoeDepthMapPreprocessor` 替代 `MiDaS`；確認輸入截圖有清晰的前後景深差異

**錯誤：牆面轉角或家具邊界模糊不清**
- 原因：Canny ControlNet strength 過低，或 Canny 閾值設定不當導致邊緣偵測不足
- 解法：將 Canny strength 提高至 0.50；降低 `low_threshold` 至 80 以偵測更多細線；確認輸入截圖為高對比度線條

**錯誤：`CUDA out of memory`（雙 ControlNet 場景）**
- 原因：雙 ControlNet 同時啟用，VRAM 需求顯著增加
- 解法：確認 ComfyUI 以 `--force-fp16` 啟動；關閉瀏覽器等高 VRAM 應用；若持續發生可嘗試將解析度降至 1024x768

**錯誤：`ZoeDepthMapPreprocessor` 無法使用**
- 原因：`comfyui_controlnet_aux` 未安裝或版本過舊
- 解法：透過 ComfyUI Manager 更新 `comfyui_controlnet_aux` 至最新版；或改用 `MiDaS-DepthMapPreprocessor` 作為替代

**錯誤：生成圖材質風格與 Prompt 不符（如 prompt 要北歐風但生成工業風）**
- 原因：Canny ControlNet 保留了太多 SketchUp 暗色線框，影響風格判斷
- 解法：將 Canny strength 降至 0.35；或在預處理前對 SketchUp 截圖進行亮度提升（Brightness +20）

**錯誤：`t5xxl_fp16` 或 `clip_l` 載入失敗**
- 原因：檔案不在正確路徑
- 解法：確認 `t5xxl_fp16.safetensors` 和 `clip_l.safetensors` 均位於 `ComfyUI/models/clip/` 目錄下

**錯誤：控制類型 `depth` / `canny` 在 FLUX 中不生效**
- 原因：SD1.5 ControlNet 模型（`control_v11...`）無法直接用於 FLUX 架構
- 解法：確認工作流使用的是 FLUX Union ControlNet 橋接方式（透過 `flux_controlnet_union_pro_2` 的 union 架構來支援多種控制類型），或改用 FLUX 原生 ControlNet 模型

> **補充說明：本工作流使用 `control_v11f1p_sd15_depth_fp16` 及 `control_v11p_sd15_canny_fp16` 的原因**
>
> 在 FLUX Union ControlNet（`flux_controlnet_union_pro_2`）的框架下，可以橋接多種傳統 ControlNet 特徵圖輸入。實際運作時，預處理器輸出的 Depth 與 Canny 特徵圖被送入 FLUX ControlNet 的 union 節點，由 FLUX 統一處理，不會直接載入 SD1.5 的模型權重。
