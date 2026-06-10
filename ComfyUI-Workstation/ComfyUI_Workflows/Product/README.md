# Product Advertising 工作流說明

對應工作流檔案：`Product_Advertising.json`

---

## 1. 用途

本工作流專為電商產品攝影後製、品牌廣告視覺、情境擺拍合成及商業海報設計而設計。
主要應用場景：
- 電商平台主圖（白底換背景、情境感植入）
- 品牌廣告圖（節慶主題、季節限定）
- 產品情境圖（咖啡館、戶外、居家氛圍）
- 行銷海報（活動促銷、新品上市）

硬體基準：i5-13500 / RTX 4080 特規 32GB VRAM / RAM 96GB / Windows 11

---

## 2. 流程圖

```
產品照片 (LoadImage)
    │
    ├──► VAEEncode ──────────────────────────► FLUX Kontext Dev 條件輸入
    │         (將參考圖編碼為 latent)             (context image reference)
    │
    ├──► HED SoftEdge 預處理器
    │         (AuxPreprocessor: HEDPreprocessor)
    │              │
    │              ▼
    │         ControlNet Preprocessor 輸出圖
    │              │
    │              ▼
    │    FLUX ControlNet Apply
    │    (flux_controlnet_union_pro_2.safetensors)
    │    (type: SoftEdge, strength: 0.65)
    │              │
    │              ▼
    ▼    FLUX Kontext Dev KSampler
    └──► (flux1-kontext-dev.safetensors)
         (denoise: 0.85, cfg: 3.0, steps: 22)
              │
              ▼
         VAEDecode
         (flux_ae.safetensors)
              │
              ▼
         ImageUpscaleWithModel
         (4x_foolhardy_Remacri.pth)
              │
              ▼
         輸出圖像 (SaveImage / PreviewImage)
```

---

## 3. 各節點用途

| 節點名稱 | 功能說明 |
|---|---|
| LoadImage | 載入產品原始照片，支援 JPG/PNG/WEBP |
| VAEEncode | 將輸入圖像編碼為 latent space，作為 Kontext 的 context 參考圖，維持產品外觀一致性 |
| HEDPreprocessor | 提取 SoftEdge 邊緣圖，保留產品輪廓與結構線條，防止產品形變 |
| FluxControlNetApply | 套用 ControlNet 條件，以 SoftEdge 引導生成，strength 0.65 保留輪廓但允許背景自由發揮 |
| FLUX Kontext Dev KSampler | 核心生成節點，結合 context 參考與 ControlNet 條件生成新圖像；denoise 0.85 允許充分重繪背景同時保留產品 |
| VAEDecode | 將 latent 解碼為像素圖像 |
| ImageUpscaleWithModel | 使用 Remacri 模型放大 4 倍，適合產品攝影的細節保留，優於 ESRGAN 通用模型 |
| CLIPTextEncode (×2) | 正向/負向提示詞編碼，搭配 t5xxl_fp16 + clip_l 雙編碼器 |
| EmptySD3LatentImage | 設定輸出 latent 尺寸（詳見第 6 節推薦尺寸） |

---

## 4. 模型與用途

| 模型檔案 | 路徑 | 用途 |
|---|---|---|
| flux1-kontext-dev.safetensors | models/diffusion_models/ | 主生成模型，支援 context image 輸入保持產品一致性 |
| t5xxl_fp16.safetensors | models/clip/ | T5 文字編碼器，理解長描述與複雜場景提示詞 |
| clip_l.safetensors | models/clip/ | CLIP-L 編碼器，搭配 T5 使用（雙編碼器架構） |
| flux_ae.safetensors | models/vae/ | FLUX 專用 VAE，負責 latent 編解碼，不可替換 |
| flux_controlnet_union_pro_2.safetensors | models/controlnet/ | Union Pro 2 支援多種 ControlNet 模式，本流程使用 SoftEdge 模式 |
| 4x_foolhardy_Remacri.pth | models/upscale_models/ | 真實感放大模型，保留材質細節，適合產品攝影 |

> **關於 FLUX Kontext Pro**：
> FLUX Kontext Pro 是 Black Forest Labs 的 **API 專屬模型**，目前無公開開源權重可下載。
> 若要使用 Pro 版本，需要：
> 1. 在 ComfyUI 安裝 BFL API 節點（如 `ComfyUI-BFLAPI` 或官方 API 節點）
> 2. 前往 [api.bfl.ml](https://api.bfl.ml) 申請 API Key
> 3. 依照用量付費（以 API 呼叫計費）
> 本工作流使用本地 **flux1-kontext-dev**，無需 API，完全離線運行。

---

## 5. 模型下載位置（對應 03 下載腳本選單）

使用工作站安裝目錄下的 `03_download_models.sh` 腳本：

| 選單編號 | 模型 | 說明 |
|---|---|---|
| 選項 1 | flux1-kontext-dev.safetensors | FLUX Kontext Dev 主模型（約 24GB） |
| 選項 2 | t5xxl_fp16.safetensors | T5 文字編碼器 |
| 選項 2 | clip_l.safetensors | CLIP-L 編碼器（與 T5 同選項） |
| 選項 3 | flux_ae.safetensors | FLUX VAE |
| 選項 4 | flux_controlnet_union_pro_2.safetensors | ControlNet Union Pro 2 |
| 選項 7 | 4x_foolhardy_Remacri.pth | Remacri 放大模型 |

---

## 6. 推薦參數

### 輸出尺寸建議

| 用途 | Width | Height | 比例 |
|---|---|---|---|
| 電商主圖（正方形） | 1024 | 1024 | 1:1 |
| IG 貼文 | 1024 | 1280 | 4:5 |
| 橫幅廣告 | 1280 | 768 | 16:9 |
| 豎版海報 | 832 | 1216 | 2:3 |

### 關鍵參數
- **Denoise**：0.85（保留產品特徵，充分重繪背景）
- **ControlNet Strength**：0.65（SoftEdge 保輪廓，不鎖死細節）
- **Upscale 後處理**：放大倍率 ×4，最終輸出約 4096×4096（電商高解析度）

---

## 7. CFG (Guidance)

**推薦值：3.0**

FLUX 模型使用 Guidance 而非傳統 CFG，數值意義不同：
- `2.0`：創意最大，可能偏離 prompt，適合藝術探索
- `3.0`：**推薦**，平衡創意與提示詞遵從，產品背景自然
- `4.0`：較嚴格遵從提示詞，適合需要精確場景描述時
- `5.0+`：過度遵從，容易出現過飽和或不自然感

---

## 8. Steps（取樣步數）

**推薦值：22 步**

- `15 步`：速度最快（約 45 秒），細節稍粗，適合快速預覽
- `20 步`：良好平衡點
- `22 步`：**推薦**，細節完整，電商級品質
- `28 步`：細節最精緻，生成時間增加約 30%，邊際效益遞減

---

## 9. Sampler（取樣器）

**推薦：`euler`**

| Sampler | 特性 | 適用場景 |
|---|---|---|
| euler | 穩定、快速、產品邊緣清晰 | **產品攝影首選** |
| dpmpp_2m | 細節豐富，稍慢 | 藝術感海報 |
| dpmpp_sde | 紋理細膩，適合材質表現 | 皮革/金屬質感產品 |

---

## 10. Scheduler（排程器）

**推薦：`simple`**

- `simple`：FLUX 官方推薦，與 euler 搭配最穩定
- `normal`：傳統 DDPM 排程，效果略遜於 simple
- `beta`：部分使用者回報細節更銳利，但穩定性稍差

---

## 11. VRAM 用量（32GB 估計）

| 階段 | VRAM 佔用 |
|---|---|
| 模型載入（flux1-kontext-dev fp16） | ~16 GB |
| ControlNet 載入（Union Pro 2） | ~2 GB |
| VAE 編解碼 | ~1 GB |
| 取樣推理（1024×1024） | ~18-20 GB |
| Remacri 放大（4096×4096） | ~3-4 GB |
| **取樣高峰估計** | **~20-22 GB** |
| **放大高峰估計** | **~18-22 GB** |

32GB VRAM 有充裕餘裕，不需要 `--lowvram` 或 `--medvram` 模式。

---

## 12. RTX 4080 32GB 最佳設定

```
# ComfyUI 啟動參數（無需額外記憶體優化）
python main.py --port 8188

# 建議在 ComfyUI 設定中啟用：
# - torch.compile: 關閉（產品工作流模型固定，compile 收益不大）
# - fp16 推理: 啟用（預設）
# - 模型保留記憶體: 啟用（連續生成時節省載入時間）
```

### 最佳化建議
1. **批次生成**：電商需要多角度/多背景時，設定 batch_size 2-4，利用剩餘 VRAM 提升效率
2. **模型預載**：首次載入後保留在 VRAM，後續生成無需重新載入（節省 15-20 秒）
3. **Remacri 放大**：32GB 可直接放大至 4096px，無需分塊（tiled upscale）
4. **ControlNet 強度調整**：若產品輪廓過於明顯/失真，調整 strength 至 0.55-0.70

---

## 13. 預估速度 & 常見錯誤排除

### 預估生成速度（RTX 4080 32GB）

| 解析度 | Steps | 預估時間 |
|---|---|---|
| 1024×1024 | 22 步 | 約 50-70 秒 |
| 1024×1280 | 22 步 | 約 60-80 秒 |
| 1280×768 | 22 步 | 約 55-75 秒 |
| 4096×4096（Remacri 放大後） | — | 額外約 20-30 秒 |

### Prompt 範例

**1. 精品咖啡電商（咖啡豆包裝）**
```
Positive: A bag of premium coffee beans on a rustic wooden table, morning sunlight through window, 
cafe atmosphere, warm tones, shallow depth of field, commercial photography, 8k
Negative: blurry, distorted logo, text artifacts, oversaturated
```

**2. 護膚品牌廣告（精華液）**
```
Positive: Luxury serum bottle on white marble surface, fresh green leaves, water droplets, 
clean minimalist aesthetic, studio lighting, high-end cosmetic advertising
Negative: cluttered background, poor lighting, plastic look
```

**3. 科技產品（耳機）**
```
Positive: Wireless headphones floating in abstract neon light environment, 
cyberpunk aesthetic, reflective surface, product hero shot, dramatic lighting
Negative: wires tangled, dirty, scratched
```

**4. 食品飲料（果汁瓶）**
```
Positive: Fresh orange juice bottle surrounded by sliced oranges and ice cubes, 
vibrant colors, summer outdoor picnic setting, natural light, food photography
Negative: artificial colors, wilted fruit, dark shadows
```

### 常見錯誤排除

| 錯誤症狀 | 可能原因 | 解決方法 |
|---|---|---|
| 產品輪廓扭曲/變形 | ControlNet strength 過低 | 提高 strength 至 0.70-0.80 |
| 背景與產品不融合 | Denoise 過低 | 提高 denoise 至 0.88-0.92 |
| 產品顏色偏移 | Kontext context 圖未正確連接 | 確認 VAEEncode 輸出連至 Kontext 條件輸入 |
| 生成結果完全黑圖 | VAE 未選擇或型號錯誤 | 確認選擇 flux_ae.safetensors |
| OOM（記憶體不足） | 解析度過高或批次過大 | 降低解析度至 1024px，batch_size 改為 1 |
| ControlNet 節點報錯 | 未安裝 ComfyUI ControlNet Auxiliary | 安裝 `comfyui_controlnet_aux` 擴充套件 |
| T5 編碼器載入失敗 | clip 路徑錯誤 | 確認 t5xxl_fp16.safetensors 在 models/clip/ 下 |
| Remacri 放大後出現格狀紋路 | 未使用 tiled 模式（超大圖） | 若輸出超過 2048px，啟用 Tiled Upscale 節點 |
