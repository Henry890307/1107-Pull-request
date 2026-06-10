# Church Design 工作流說明

對應工作流檔案：`Church_Design.json`

---

## 1. 用途

本工作流以 **FLUX Kontext Dev + ControlNet Union Pro 2** 為核心，專為教會視覺設計需求打造。低強度 ControlNet（strength 0.4）保留原始活動照片的構圖框架，同時讓 FLUX 自由生成符合活動主題的視覺風格。

主要應用場景：
- **青年聚會**海報（充滿活力的幾何圖形、霓虹燈、鮮豔配色）
- **夏令營**宣傳圖（戶外冒險感、自然元素、青春活潑）
- **聯合崇拜**視覺（莊重神聖、光芒感、大氣背景）
- **夢想市集**活動海報（溫馨市集感、手工藝質感、社群活動氛圍）

硬體基準：i5-13500 / RTX 4080 特規 32GB VRAM / RAM 96GB / Windows 11

---

## 2. 流程圖

```
活動參考照 (LoadImage)
    │
    ├──► VAEEncode ──────────────────────────────────────► FLUX Kontext Dev
    │    (flux_ae.safetensors)                              Context 參考輸入
    │    (將參考照編碼為 latent，維持構圖結構)
    │
    ├──► HED SoftEdge 預處理器（可選：換 Canny 或 Depth）
    │    (AuxPreprocessor: HEDPreprocessor)
    │         │
    │         ▼
    │    ControlNet 預處理輸出圖
    │         │
    │         ▼
    │    FLUX ControlNet Apply
    │    (flux_controlnet_union_pro_2.safetensors)
    │    (mode: SoftEdge, strength: 0.4)
    │         │
    │         ▼
    ├──► CLIPTextEncode 正向 prompt ─────────────────────► FLUX Kontext Dev
    │    (t5xxl_fp16.safetensors + clip_l.safetensors)      文字條件輸入
    │
    ├──► CLIPTextEncode 負向 prompt
    │
    ▼
EmptySD3LatentImage
(設定輸出尺寸，依格式切換 width/height，見第 6 節)
    │
    ▼
FLUX Kontext Dev KSampler
(flux1-kontext-dev.safetensors)
(cfg: 3.5, steps: 24, euler/simple)
    │
    ▼
VAEDecode
(flux_ae.safetensors)
    │
    ▼
輸出圖像 (SaveImage / PreviewImage)
```

---

## 3. 各節點用途

| 節點名稱 | 功能說明 |
|---|---|
| LoadImage | 載入活動參考照（可以是場地照、上屆活動截圖、手繪草稿或任何構圖參考） |
| VAEEncode | 將參考照編碼為 latent，提供給 FLUX Kontext 作為 context 輸入，讓生成結果保持構圖方向感 |
| HEDPreprocessor | 提取 SoftEdge 邊緣圖，以低 strength 0.4 保留大致構圖框架，不鎖死細節，讓 FLUX 自由重繪風格 |
| FluxControlNetApply | 套用 ControlNet 條件，strength 0.4 為低強度設定，只保留大致構圖位置，允許自由創作 |
| CLIPTextEncode（正向）| 描述活動主題、氛圍、視覺風格的提示詞，搭配 T5+CLIP-L 雙編碼器 |
| CLIPTextEncode（負向）| 排除不想要的元素（如文字扭曲、模糊、不搭調的元素） |
| EmptySD3LatentImage | 設定輸出 latent 尺寸，不同格式切換 width/height（見第 6 節尺寸對照表） |
| FLUX Kontext Dev KSampler | 核心生成節點，context 參考 + ControlNet + 文字三重條件共同引導創作 |
| VAEDecode | 將 latent 解碼為最終像素圖像 |

> **ControlNet strength 0.4 的意義**：
> - 0.0-0.3：幾乎不參考原始構圖，FLUX 完全自由發揮
> - **0.4（推薦）**：保留大致位置與構圖方向感，但細節完全重繪
> - 0.6-0.7：明顯保留原始輪廓（適合需要精確保留建築物或特定元素時）
> - 0.8+：嚴格複製構圖，適合結構精準的平面設計

---

## 4. 模型與用途

| 模型檔案 | 路徑 | 用途 |
|---|---|---|
| flux1-kontext-dev.safetensors | models/diffusion_models/ | 主生成模型，context 圖輸入保持構圖，文字引導風格重繪（約 24GB） |
| t5xxl_fp16.safetensors | models/clip/ | T5 文字編碼器，理解長篇場景描述與風格關鍵詞 |
| clip_l.safetensors | models/clip/ | CLIP-L 編碼器，搭配 T5 組成雙編碼器架構 |
| flux_ae.safetensors | models/vae/ | FLUX 專用 VAE，負責 latent 編解碼，不可替換 |
| flux_controlnet_union_pro_2.safetensors | models/controlnet/ | Union Pro 2 多模式 ControlNet，本流程使用 SoftEdge 模式（亦支援 Canny、Depth、OpenPose 等） |

> **關於 FLUX Kontext Pro**：
> FLUX Kontext Pro 是 Black Forest Labs 的 **API 專屬模型**，目前無公開開源權重。
> 若要使用 Pro 版本（品質更高、細節更精準），需要：
> 1. 安裝 ComfyUI BFL API 節點（`ComfyUI-BFLAPI` 或官方 API 節點）
> 2. 前往 [api.bfl.ml](https://api.bfl.ml) 申請 API Key
> 3. 依 API 使用量付費
> 本工作流使用本地 **flux1-kontext-dev**，無需 API，完全離線運行。

---

## 5. 模型下載位置（對應 03 下載腳本選單）

使用工作站安裝目錄下的 `install/03_download_models.ps1` 腳本：

| 選單編號 | 模型 | 說明 |
|---|---|---|
| 選項 5 | flux1-kontext-dev.safetensors | FLUX Kontext Dev 主模型（約 24GB，需先 HF 同意授權） |
| 選項 5 | t5xxl_fp16.safetensors | T5 文字編碼器（與 FLUX 同選項） |
| 選項 5 | clip_l.safetensors | CLIP-L 編碼器（與 FLUX 同選項） |
| 選項 5 | flux_ae.safetensors | FLUX VAE（與 FLUX 同選項） |
| 選項 2 | flux_controlnet_union_pro_2.safetensors | ControlNet Union Pro 2（FLUX 版） |

> **重要**：選項 5（FLUX）下載前需先到 HuggingFace 同意 FLUX Kontext Dev 的授權協議，並執行 `huggingface-cli login` 輸入 HF Token。

---

## 6. 推薦參數

### 各格式尺寸設定（EmptySD3LatentImage 參數）

| 輸出格式 | Width | Height | 比例 | 說明 |
|---|---|---|---|---|
| **IG 貼文（4:5）** | 1024 | 1280 | 4:5 | 直接於 EmptySD3LatentImage 設定 1024×1280 |
| **IG 限時動態（9:16）** | 896 | 1152 | 接近 9:16 | Latent 設 896×1152，生成後再用 Remacri 放大至 1080×1350 或更大 |
| **A4 海報（直立）** | 832 | 1216 | 接近 A4 | 生成後放大至 2480×3508（300dpi A4）供印刷使用 |
| **16:9 投影（橫版）** | 1280 | 720 | 16:9 | 直接設定，無需放大即可投影使用 |
| **16:9 高解析度** | 1920 | 1080 | 16:9 | 若 VRAM 允許可直接生成，或由 1280×720 Remacri 放大 |

### 尺寸切換方法

在 ComfyUI 工作流中，找到 `EmptySD3LatentImage` 節點，直接修改兩個數值：
```
IG 貼文：    width = 1024,  height = 1280
IG 限動：    width = 896,   height = 1152
A4 海報：    width = 832,   height = 1216
16:9 投影：  width = 1280,  height = 720
```

> **注意**：FLUX 對解析度比例較敏感。建議使用 64 的倍數作為 width/height 值，避免解析度不整除造成的邊緣異常。

### 關鍵參數設定
- **Denoise**：1.0（從頭生成，非 img2img）
- **ControlNet Strength**：0.4（低強度，保構圖不鎖細節）
- **Guidance（CFG）**：3.5（見第 7 節）

---

## 7. CFG（Guidance）

**推薦值：3.5**

FLUX 使用 Guidance scale（非傳統 CFG），數值說明：
- `2.5`：FLUX 極度自由發揮，可能偏離 prompt，畫面獨特但難以控制
- `3.0`：略偏創意，適合藝術感海報，允許一定偏差
- `3.5`：**推薦**，prompt 遵從度與視覺創意的最佳平衡點
- `4.5`：嚴格遵從 prompt，適合需要精確場景描述的聯合崇拜或正式活動海報
- `6.0+`：過度遵從，容易出現過飽和色彩或不自然感，不建議

---

## 8. Steps（取樣步數）

**推薦值：24 步**

| 步數 | 品質 | 速度 | 建議用途 |
|---|---|---|---|
| 16 步 | 中等 | 約 40 秒 | 快速構圖測試，驗證 prompt 方向 |
| 20 步 | 良好 | 約 55 秒 | 多版本快速比較 |
| **24 步** | **優秀** | **約 65-80 秒** | **正式輸出推薦** |
| 30 步 | 細膩 | 約 90 秒 | 最終精修版，邊際效益小 |
| 35 步+ | 幾乎無提升 | 約 110 秒+ | 不建議，浪費時間 |

---

## 9. Sampler（取樣器）

**推薦：`euler`**

| Sampler | 特性 | 適用場景 |
|---|---|---|
| euler | 穩定、色彩均衡、邊緣清晰 | **教會海報首選**，一致輸出品質 |
| dpmpp_2m | 細節豐富，需多走幾步 | 需要極致細節時（人物面孔、建築細節）|
| dpmpp_sde | 隨機性較高，每次結果略有不同 | 需要多樣化版本時快速探索 |

---

## 10. Scheduler（排程器）

**推薦：`simple`**

- `simple`：FLUX 官方推薦排程，搭配 euler 最穩定，色彩還原最準確
- `normal`：傳統 DDPM 排程，效果略遜
- `sgm_uniform`：對 FLUX 的初期去噪有較好的均勻分布，部分使用者偏好用於光影複雜場景

---

## 11. VRAM 用量（32GB 估計）

| 階段 | VRAM 佔用 |
|---|---|
| 模型載入（flux1-kontext-dev fp16）| ~16 GB |
| ControlNet Union Pro 2 載入 | ~2 GB |
| T5 + CLIP-L 文字編碼器 | ~5 GB |
| VAE 編解碼 | ~1 GB |
| 取樣推理（1024×1280）| ~18-20 GB |
| 取樣推理（1280×720）| ~17-19 GB |
| **總高峰估計（含所有組件）** | **~20-22 GB** |

32GB VRAM 有充裕餘裕（約 8-10GB 空餘），不需要任何降低記憶體的啟動參數。

---

## 12. RTX 4080 32GB 最佳設定

```
# ComfyUI 啟動參數（無需額外優化）
python main.py --port 8188

# 若同時跑多個工作流需要更多 VRAM 時：
python main.py --port 8188 --reserve-vram 2
```

### 最佳化建議
1. **批次多版本比較**：設定 `batch_size 2-3`，同時生成多個版本供選擇，利用剩餘 VRAM 提升效率
2. **ControlNet 強度快速測試**：先用 `steps=16, strength=0.3/0.4/0.5` 三個版本快速比較構圖感，確定後再改回 `steps=24` 輸出正式版
3. **模型預載**：首次生成後保留模型在 VRAM，連續生成多個活動海報時節省 15-20 秒載入時間
4. **不同格式快速切換**：只需修改 `EmptySD3LatentImage` 的 width/height，其他參數保持不變即可切換格式
5. **高解析度輸出**：若需要印刷級解析度，可加入 `4x_foolhardy_Remacri` 放大節點，在 32GB 上可直接放大至 4096px

---

## Prompt 範例（4 種活動）

以下所有範例可直接複製貼入 CLIPTextEncode 節點的文字欄位。

### 1. 青年聚會海報

**活動特色**：充滿活力、年輕感、現代設計

```
Positive: A vibrant youth church gathering poster, 
energetic neon geometric shapes, colorful confetti and light rays, 
young people silhouettes raising hands in worship, 
modern urban design, electric blue and orange accent colors,
dynamic diagonal composition, glowing bokeh lights background,
high energy spiritual atmosphere, professional church event poster design

Negative: old-fashioned design, dark gloomy atmosphere, 
pixelated text, cluttered layout, too many elements, watermark
```

**ControlNet Strength**：0.4（若有活動照參考構圖）
**Guidance**：3.5 | **Steps**：24 | **推薦格式**：IG 貼文 1024×1280

---

### 2. 夏令營宣傳圖

**活動特色**：戶外冒險、自然、大自然中的信仰體驗

```
Positive: Summer church camp promotional poster, 
lush green forest mountains backdrop, adventure and nature elements,
campfire warmth glow, wooden cross silhouette against sunset sky,
young campers in nature setting, warm amber and forest green palette,
adventurous outdoor spirit, hope and joy, cinematic landscape
community bonding, faith in nature, professional event poster

Negative: indoor setting, urban environment, dark stormy weather,
overcrowded design, corporate cold feel
```

**ControlNet Strength**：0.35（若只有室內參考照，降低強度讓 FLUX 更自由轉換場景）
**Guidance**：3.5 | **Steps**：24 | **推薦格式**：IG 貼文 1024×1280 或 A4 832×1216

---

### 3. 聯合崇拜視覺

**活動特色**：莊重、神聖、感動人心的大型崇拜氛圍

```
Positive: United worship service visual design,
majestic cathedral rays of divine light, golden and white color palette,
congregation silhouettes in reverent worship, 
heavenly atmosphere with soft cloud formations,
cross motif bathed in golden light, hope and transcendence,
grand cinematic scale, moving worship experience,
professional church event visual, peaceful and powerful

Negative: cartoon style, childish design, dark or chaotic,
commercial advertisement look, secular imagery
```

**ControlNet Strength**：0.45（若有場地或台前構圖參考）
**Guidance**：4.0（需要較精確的場景呈現）| **Steps**：28 | **推薦格式**：16:9 投影 1280×720

---

### 4. 夢想市集活動海報

**活動特色**：溫馨、手工藝感、社群互動、創意市集

```
Positive: Church dream marketplace event poster,
cozy artisan market atmosphere, handmade crafts and creative stalls,
warm fairy lights string decoration, pastel color palette,
community gathering joyful vibe, watercolor texture elements,
flat lay design style, vintage market aesthetic,
flowers and natural materials, welcoming community spirit,
charming and creative visual identity

Negative: formal corporate design, dark background, 
industrial look, digital cold aesthetic
```

**ControlNet Strength**：0.3（若無合適參考圖，低強度讓 FLUX 自由創作）
**Guidance**：3.0（允許更多創意發揮）| **Steps**：24 | **推薦格式**：IG 限動 896×1152 或 IG 貼文 1024×1280

---

## 海報文字處理說明（重要）

### FLUX 對中文字/海報文字的限制

FLUX Kontext Dev 對英文字母有一定的渲染能力，但對以下情況有明顯限制：
- **繁體中文字**：FLUX 幾乎無法正確生成繁體中文，會產生錯誤字形或亂碼
- **精確排版**：字體大小、位置、字距無法通過 prompt 精確控制
- **特定字體風格**：無法指定特定字型（黑體、圓體、明體）

### 建議工作流程：AI 生圖 + 後期疊字

```
FLUX 生成純視覺背景/底圖
    ↓
輸出高解析度圖片（1024×1280 或更高）
    ↓
匯入 Canva / Photoshop / Affinity Publisher
    ↓
疊加活動文字（活動名稱、日期、地點、QR Code）
    ↓
輸出最終海報
```

**推薦免費工具**：
- **Canva（免費版）**：線上操作，有大量教會海報模板，直接拖入 FLUX 生成圖作為背景
- **Adobe Express（免費版）**：與 Canva 類似，提供更多字體選項
- **Affinity Publisher 2（買斷制）**：適合需要精準印刷版面的 A4/A3 海報
- **GIMP（免費開源）**：功能完整但學習曲線較高

### Prompt 技巧：為文字保留空白區域

在 prompt 中加入以下描述，讓 FLUX 在圖像中留出空白給文字使用：
```
...clean empty space at the top for title text overlay,
bottom third reserved for event details text,
uncluttered center composition...
```

---

## 13. 預估速度 & 常見錯誤排除

### 預估生成速度（RTX 4080 32GB）

| 解析度 | Steps | 預估時間 |
|---|---|---|
| 1024×1024 | 24 步 | 約 55-70 秒 |
| 1024×1280（IG 貼文）| 24 步 | 約 65-80 秒 |
| 896×1152（IG 限動）| 24 步 | 約 60-75 秒 |
| 832×1216（A4 海報）| 24 步 | 約 60-75 秒 |
| 1280×720（16:9 投影）| 24 步 | 約 55-70 秒 |
| + Remacri 放大（4x）| — | 額外 20-35 秒 |

### 常見錯誤排除

| 錯誤症狀 | 可能原因 | 解決方法 |
|---|---|---|
| 生成結果與參考照構圖無關 | ControlNet strength 太低或 VAEEncode 未正確連接 | 確認 VAEEncode 輸出已連至 Kontext context 輸入；嘗試提高 strength 至 0.5 |
| 畫面太拘束、背景與原照太相似 | ControlNet strength 過高 | 降低 strength 至 0.3-0.35 |
| 生成全黑圖或 NaN 錯誤 | VAE 型號錯誤 | 確認使用 flux_ae.safetensors（不可用 Wan VAE） |
| 人物臉部模糊或扭曲 | FLUX 在低解析度時人臉細節較差 | 生成後用 FaceDetailer 或 Remacri 放大並加強細節 |
| OOM（記憶體不足） | 解析度超出範圍或批次過大 | 降低解析度至 1024px 以內，batch_size 改為 1 |
| ControlNet 預處理圖全白或全黑 | HEDPreprocessor 未安裝 | 安裝 `comfyui_controlnet_aux` 套件 |
| T5 文字編碼器載入失敗 | 路徑錯誤 | 確認 t5xxl_fp16.safetensors 在 models/clip/ 下 |
| 輸出圖有明顯格狀噪點（GAN 噪聲）| FLUX VAE 解碼異常 | 重新確認 flux_ae.safetensors，不要使用第三方 VAE |
| 海報感不夠，太像一般風景照 | Prompt 缺乏設計感關鍵詞 | 在 prompt 加入 `poster design, event promotional material, graphic design, professional layout` |
| 中文字出現亂碼或錯誤字形 | FLUX 本身限制 | 不要在 prompt 要求生成中文字；改用 Canva/PS 後期疊字 |
| ControlNet Union Pro 2 節點顯示模式選項不對 | 舊版 ControlNet 節點 | 更新 ComfyUI 與 ComfyUI Manager，確認使用支援 Union Pro 的節點版本 |
