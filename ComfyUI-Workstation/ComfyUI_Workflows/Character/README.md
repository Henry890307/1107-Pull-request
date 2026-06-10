# Character_Consistency 工作流說明

對應工作流檔案：`Character_Consistency.json`

---

## 1. 工作流用途

本工作流專為需要「人物一致性」的商業應用場景設計，能在更換服裝、更換背景、更換姿勢的情況下，始終保持同一張臉的五官、膚色、面部特徵高度一致。

核心應用場景：
- **電商服裝試穿**：同一個人模特換多套服裝，保持臉部一致
- **品牌廣告素材**：不同場景、不同構圖的一系列廣告圖，同一張臉
- **角色設計定稿**：將概念角色圖轉換為不同姿勢/角度的一致參考圖
- **社群媒體內容**：快速批量生產同一 KOL 虛擬形象的多場景內容圖

技術實現原理：
- **IPAdapter PLUS FACE**（`ip-adapter-plus-face_sd15.safetensors`）：從參考照片中提取臉部特徵嵌入，注入 SDXL 生成流程，強制生成圖包含相同的臉型與五官佈局
- **FaceDetailer**（Impact Pack 套件）：在生成完成後，對臉部區域進行二次精修，補充細節並修正任何輕微的五官偏移

搭配 OpenPose ControlNet 控制姿勢，可在保持臉部不變的前提下，完整指定人物的肢體動作與鏡頭構圖。

---

## 2. 節點流程圖

```
[LoadImage — 人物參考照（正臉/3/4側臉）]
                |
                v
[IPAdapterPlusFace — ip-adapter-plus-face_sd15.safetensors]
  CLIP Vision: CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors
  weight: 0.85 | weight_type: linear
                |
[LoadImage — 姿勢參考照]
                |
                v
[OpenposePreprocessor]
  detect_hand: true | detect_body: true | detect_face: false
  resolution: 1024
                |
                v
[Apply ControlNet — ControlNet Union SDXL Promax]
  controlnet_union_sdxl_promax.safetensors
  control_type: openpose | strength: 0.70
                |
                |
[CheckpointLoaderSimple — RealVisXL_V5.0_fp16.safetensors]
[CLIPTextEncode — Positive Prompt]
[CLIPTextEncode — Negative Prompt]
                |
         +------+------+
         |      |      |
  [IPAdapter] [ControlNet] [Text Prompt]
         |      |      |
         +------+------+
                |
                v
        [KSampler]
  steps 30 | cfg 6.0 | dpmpp_2m_sde | karras | denoise 1.0
                |
                v
        [VAEDecode]
                |
                v
        [FaceDetailer]
  (Impact Pack — bbox detector: face_yolov8m.pt)
  denoise: 0.45 | steps: 20 | cfg: 6.0
  guide_size: 384 | max_size: 512
                |
                v
        [SaveImage — 輸出]
```

---

## 3. 各節點用途說明

### LoadImage（人物參考照）
載入人物臉部參考照。最佳輸入條件：
- **臉部正面或 3/4 側面照**（IPAdapter 從正面擷取特徵效果最佳）
- 解析度建議 512x512 以上，臉部占畫面 1/3 以上
- 光線均勻，避免強烈陰影遮擋五官
- 單一人物，避免多人照

### IPAdapterPlusFace
本工作流最核心的節點，負責臉部一致性的實現。
- 使用 `ip-adapter-plus-face_sd15.safetensors`（專為臉部設計的 IPAdapter 變體）
- 需要 `CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors` 作為圖像視覺編碼器
- **weight：0.85**（高強度臉部特徵注入，確保生成臉與參考照高度相似）
- `weight_type: linear`（線性混合，臉部特徵在整個去噪過程中持續作用）

**為何 IPAdapter 能維持臉部一致：**
IPAdapter 從參考圖提取 CLIP image embedding（圖像語意向量），並將其作為附加條件注入 U-Net 的 cross-attention 層。這些臉部向量包含了五官比例、膚色、輪廓特徵等資訊，在每一個去噪步驟中持續引導模型生成符合參考臉的結果，效果優於單純用 prompt 描述臉部特徵。

### LoadImage（姿勢參考照）
載入姿勢參考照，可以是真人照片、3D 模型截圖、或手繪火柴人草圖。OpenPose 預處理器會從中提取骨架關鍵點，不需要與最終生成結果的人物外貌相似。

### OpenposePreprocessor
屬於 `comfyui_controlnet_aux` 套件節點。從姿勢參考照中偵測並輸出 OpenPose 骨架圖（含身體關鍵點、手部關鍵點）。
- `detect_hand: true`（偵測手部關鍵點，手部動作更自然）
- `detect_body: true`（偵測全身骨架）
- `detect_face: false`（不偵測臉部關鍵點，讓 IPAdapter 負責臉部，避免衝突）
- `resolution: 1024`

### Apply ControlNet（controlnet_union_sdxl_promax，openpose）
套用 `controlnet_union_sdxl_promax.safetensors`，將 OpenPose 骨架圖注入 SDXL 生成流程，確保生成人物的姿勢、肢體動作與參考照吻合。
- `control_type: openpose`
- `strength: 0.70`（適中強度，姿勢準確但肢體細節保留自然變化）
- `start_percent: 0.0`
- `end_percent: 0.85`

### CheckpointLoaderSimple（RealVisXL_V5.0_fp16）
載入 SDXL 架構的 `RealVisXL_V5.0_fp16.safetensors` 作為主底模。RealVisXL V5 專為真人攝影風格最佳化，在膚色細節、頭髮表現、服裝材質等人物渲染關鍵元素上效果優異，與 IPAdapter 的相容性也最佳。

> 本工作流使用 **SDXL + RealVisXL** 而非 FLUX，原因是 IPAdapter PLUS FACE（`ip-adapter-plus-face_sd15.safetensors`）目前僅有 SD1.5 版本，尚無 SDXL 或 FLUX 原生版本。透過 `IPAdapterUnifiedLoader` 的 SDXL 兼容模式，搭配 `ip-adapter-plus_sdxl_vit-h.safetensors`，可在 SDXL 架構下獲得接近的人臉一致性效果。

### CLIPTextEncode（Positive / Negative）
Positive Prompt 描述目標場景、服裝、背景，**不需要**描述臉部特徵（由 IPAdapter 負責）。詳見第 6 段範例。

### KSampler
執行主要取樣，SDXL 推薦使用 `dpmpp_2m_sde` + `karras`，steps 30，cfg 6.0，denoise 1.0。

### VAEDecode
將潛空間張量解碼為 RGB 圖像，作為 FaceDetailer 的輸入。

### FaceDetailer（Impact Pack）
本工作流第二個核心節點，負責臉部精修。

**為何 FaceDetailer 能進一步強化臉部一致性：**
KSampler 生成的完整圖像中，臉部區域佔整體畫面比例較小，解析度有限，細節不足。FaceDetailer 會：
1. 使用 `face_yolov8m.pt` bbox 偵測器定位臉部區域（bbox 偵測方式比分割遮罩更快且穩定）
2. 將臉部裁切放大至 384–512px 後進行獨立的二次去噪（denoise 0.45）
3. 二次去噪同樣注入 IPAdapter 特徵，進一步對齊參考臉特徵
4. 將精修後的臉部貼回完整圖像，並進行邊緣羽化融合

denoise 0.45 的設定確保只做細節補充，不會大幅改變整體臉型（denoise 過高會破壞 IPAdapter 建立的一致性）。

**關於 `face_yolov8m.pt` 的取得方式：**
安裝 `ComfyUI-Impact-Pack` 後，可透過以下方式取得：
1. 在 ComfyUI Manager 中搜尋並安裝 `ComfyUI-Impact-Pack`
2. 安裝完成後，在 ComfyUI 中任意執行含 FaceDetailer 的工作流時，節點會提示自動下載 bbox 模型；點選同意即可
3. 也可在 Impact Pack 設定頁面手動觸發下載
4. 模型下載後存放於 `ComfyUI/models/ultralytics/bbox/face_yolov8m.pt`

---

## 4. 用到的模型與用途

| 模型檔案 | 存放路徑 | 用途 |
|---------|---------|------|
| `RealVisXL_V5.0_fp16.safetensors` | `models/checkpoints/` | SDXL 主底模，真人攝影風格最佳化 |
| `ip-adapter-plus-face_sd15.safetensors` | `models/ipadapter/` | IPAdapter 臉部版，負責人臉特徵注入 |
| `CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors` | `models/clip_vision/` | IPAdapter 使用的圖像視覺編碼器 |
| `controlnet_union_sdxl_promax.safetensors` | `models/controlnet/` | SDXL Union ControlNet，控制人物姿勢 |
| `ip-adapter-plus_sdxl_vit-h.safetensors` | `models/ipadapter/` | SDXL 版 IPAdapter（可選，搭配 SDXL 底模使用）|
| `ip-adapter-faceid-plusv2_sdxl.bin` | `models/ipadapter/` | FaceID 強化版 IPAdapter（可選，強化臉部 ID 一致性）|
| `ip-adapter-faceid-plusv2_sdxl_lora.safetensors` | `models/loras/` | FaceID 搭配 LoRA（與 ip-adapter-faceid-plusv2_sdxl 搭配使用）|
| `face_yolov8m.pt` | `models/ultralytics/bbox/` | FaceDetailer bbox 偵測器（由 Impact Pack 自動下載）|

> **模型選擇說明：**
>
> 本工作流的標準配置使用 `ip-adapter-plus-face_sd15.safetensors`（SD1.5 版本）搭配 `RealVisXL_V5.0_fp16`（SDXL 架構）。IPAdapter 的 SD1.5 特徵提取器可以跨架構使用，實際效果良好。
>
> 若需要更強的臉部 ID 一致性（例如商業棚拍等級的人臉精準度），可改用 `ip-adapter-faceid-plusv2_sdxl.bin` + `ip-adapter-faceid-plusv2_sdxl_lora.safetensors` 組合，並在 LoRA 節點中將 lora 強度設為 0.6–0.8。

---

## 5. 模型下載位置（對應 03_download_models.ps1 選單編號）

執行 `scripts/03_download_models.ps1` 並選擇對應編號：

| 選單編號 | 模型名稱 | 下載後存放路徑 |
|---------|---------|--------------|
| C-1 | RealVisXL_V5.0_fp16.safetensors | models/checkpoints/ |
| E-1 | ip-adapter-plus-face_sd15.safetensors | models/ipadapter/ |
| E-2 | ip-adapter-plus_sdxl_vit-h.safetensors | models/ipadapter/ |
| E-3 | ip-adapter-faceid-plusv2_sdxl.bin | models/ipadapter/ |
| F-1 | CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors | models/clip_vision/ |
| B-4 | controlnet_union_sdxl_promax.safetensors | models/controlnet/ |
| G-1 | ip-adapter-faceid-plusv2_sdxl_lora.safetensors | models/loras/ |

`face_yolov8m.pt` 由 Impact Pack 套件自動下載，無需手動選擇。

---

## 6. 推薦參數

### KSampler（主要取樣）

| 參數 | 推薦值 | 說明 |
|------|--------|------|
| 解析度 | 1024x1024 | SDXL 最佳基礎解析度（人物主體）|
| Steps | 30 | 人物細節（頭髮、膚色）需要足夠步數 |
| CFG | 6.0 | SDXL 真人風格推薦值，避免過度遵從造成油畫感 |
| Sampler | dpmpp_2m_sde | SDXL 人物最佳 sampler，細節豐富且穩定 |
| Scheduler | karras | 配合 dpmpp_2m_sde，噪點衰減曲線最佳 |
| Denoise | 1.0 | 完整生成（txt2img 模式）|
| IPAdapter weight | 0.85 | 高強度臉部特徵注入 |
| ControlNet strength | 0.70 | 姿勢控制，保留肢體自然度 |

### FaceDetailer（臉部精修）

| 參數 | 推薦值 | 說明 |
|------|--------|------|
| Denoise | 0.45 | 低重繪率，細節補充不改變臉型 |
| Steps | 20 | 精修階段足夠 |
| CFG | 6.0 | 與主取樣保持一致 |
| Guide size | 384 | 臉部裁切放大尺寸 |
| Max size | 512 | 臉部精修最大尺寸 |
| Bbox detector | face_yolov8m.pt | 臉部定位偵測器 |
| Sampler | dpmpp_2m_sde | 與主取樣保持一致 |
| Scheduler | karras | 與主取樣保持一致 |

### Positive Prompt 範例

**電商服裝（換白色連衣裙，室內棚拍）：**
```
beautiful woman, wearing white elegant dress, studio photography,
white background, soft box lighting, fashion photography,
high-end commercial photography, sharp focus, 8k
```

**戶外場景（換運動服，城市街頭）：**
```
woman in athletic wear, sports outfit, urban street background,
natural daylight, lifestyle photography, candid pose,
photorealistic, high detail, 8k
```

**換背景（日本街景，和服）：**
```
woman wearing traditional japanese kimono, cherry blossom street,
kyoto traditional architecture background, spring afternoon light,
editorial fashion photography, photorealistic, 8k
```

### Negative Prompt 範例
```
ugly, deformed face, bad anatomy, distorted limbs, extra fingers,
mutation, low quality, blurry, watermark, text, cartoon, anime,
plastic skin, airbrushed, oversaturated, wrong proportions
```

---

## 7. CFG

- **推薦值：6.0**（SDXL 真人寫實風格推薦範圍 5.0–7.0）
- SDXL 的 CFG 與 FLUX 的 guidance 含義相同（Classifier-Free Guidance），但 SDXL 使用傳統 `KSampler` CFG 欄位，直接填入數值即可
- `CFG < 5.0`：prompt 遵循度下降，人物細節模糊，服裝描述不準確
- `CFG 5.0–7.0`：最佳範圍，人物細節清晰，膚色自然
- `CFG > 8.0`：容易產生過飽和的膚色（「塑膠感」）和誇張的光影對比

---

## 8. Steps

- **推薦值：30 steps**
- SDXL 架構對 steps 的需求高於 FLUX，人物渲染（頭髮、膚色、衣物紋理）需要足夠步數
- 最低可用：24 steps（快速預覽用）
- 最高建議：35 steps（品質接近天花板，超過意義不大）
- FaceDetailer 精修階段使用 20 steps（已夠用，過高反而可能改變臉部特徵）

---

## 9. Sampler

- **推薦：dpmpp_2m_sde**（SDXL 人物渲染最佳 sampler）
- `dpmpp_2m_sde` 在人物皮膚細節、頭髮絲流向、衣物褶皺等方面表現最佳
- 替代選項：`dpmpp_3m_sde`（更高細節，略慢）、`euler_ancestral`（創意性更高但細節略軟）
- 不建議 DDIM 或 LMS（與 SDXL 組合人物細節不足）

---

## 10. Scheduler

- **推薦：karras**（搭配 dpmpp_2m_sde 的黃金組合）
- `karras` 的噪點衰減曲線在人物渲染中能有效保留中間調細節（膚色層次、陰影過渡）
- 替代：`sgm_uniform`（步數更均勻，適合細節豐富的背景場景）
- 不建議 `simple`（FLUX 設計，與 SDXL 搭配效果次佳）

---

## 11. VRAM 使用量（RTX 4080 32GB 實際估計）

| 階段 | 估計 VRAM 用量 | 備註 |
|------|--------------|------|
| 模型載入（RealVisXL SDXL + CLIP Vision） | ~8 GB | SDXL fp16 完整載入 |
| IPAdapter 特徵提取（參考照） | +1 GB | 短暫佔用 |
| OpenPose 預處理 | +0.5 GB | 短暫佔用 |
| KSampler 取樣（1024x1024，含 IPAdapter + ControlNet） | ~10–14 GB | 主要 VRAM 消耗 |
| VAEDecode | ~10–12 GB | SDXL VAE |
| FaceDetailer 精修（384–512px 裁切） | +2–4 GB | 二次 KSampler |
| 全流程峰值 VRAM | **約 12–16 GB** | 32GB 卡極為充裕 |

SDXL 架構的 VRAM 需求遠低於 FLUX，32GB 卡在此工作流下有大量餘裕，可考慮同時在批次模式下生成多張。

---

## 12. RTX 4080 32GB 最佳設定

**ComfyUI 啟動參數：**
```batch
python main.py --force-fp16 --gpu-only
```

**節點層級最佳化（SDXL 人物工作流）：**
- `CheckpointLoaderSimple` 使用 fp16 版本（`RealVisXL_V5.0_fp16.safetensors`）
- IPAdapter weight_type 使用 `linear`（比 `ease in-out` 更穩定的臉部一致性）
- 若需要更強臉部一致性，可叠加 `IPAdapterFaceID`（`ip-adapter-faceid-plusv2_sdxl.bin`）作為第二路 IPAdapter，weight 設為 0.5
- FaceDetailer 的 `feather` 設為 30（邊緣羽化，避免臉部貼回時出現生硬邊界）
- 批次生成多張時，固定相同 seed + 不同 subseed 可在保持臉部一致的前提下增加背景/姿勢多樣性

**Windows 11 系統調校：**
- SDXL 工作流 VRAM 需求較低，可在 Chrome 開著的情況下生成（但建議關閉大量分頁）
- 若要批次生成（一次生成 4–8 張），32GB VRAM 足夠，只需設定 `batch_size: 1`（逐張生成，確保 FaceDetailer 對每張獨立精修）

---

## 13. 預估生成速度 + 常見錯誤排除

### 預估生成速度（RTX 4080 32GB，fp16，gpu-only）

| 操作 | 解析度 | 預估時間 |
|------|--------|---------|
| OpenPose 預處理 | 1024x1024 | 約 2–3 秒 |
| IPAdapter 特徵提取 | 參考照 | 約 1 秒 |
| KSampler（30 steps，SDXL） | 1024x1024 | 約 25–40 秒 |
| VAEDecode | 1024x1024 | 約 2–3 秒 |
| FaceDetailer 精修（20 steps） | 384px 臉部 | 約 5–10 秒 |
| 全流程 | 1024x1024 | **約 35–60 秒** |

### 常見錯誤排除

**錯誤：生成的臉與參考照相似度低（五官位置或比例不對）**
- 原因 1：IPAdapter weight 過低
- 解法：將 IPAdapter weight 提高至 0.85–0.95
- 原因 2：參考照臉部過小或角度過側
- 解法：改用正面或 3/4 側面的參考照，確保臉部占畫面 1/3 以上
- 原因 3：ControlNet OpenPose strength 過高，姿勢約束干擾了 IPAdapter 的臉部特徵注入
- 解法：將 ControlNet strength 降至 0.60，或縮短 `end_percent` 至 0.75

**錯誤：人物姿勢與參考照不符（手臂位置錯誤等）**
- 原因：ControlNet strength 過低，或 OpenPose 預處理器未偵測到完整骨架
- 解法：將 ControlNet strength 提高至 0.75–0.80；確認 OpenPose 預處理器輸出圖中骨架關鍵點完整（可在 ComfyUI 預覽節點輸出確認）

**錯誤：`face_yolov8m.pt` 找不到 / FaceDetailer 無法執行**
- 原因：Impact Pack 未安裝，或 bbox 模型未下載
- 解法：
  1. 透過 ComfyUI Manager 安裝 `ComfyUI-Impact-Pack`
  2. 重啟 ComfyUI 後，第一次執行工作流時節點會提示下載 bbox 模型，點選同意
  3. 若自動下載失敗，手動從 `https://huggingface.co/Ultralytics/assets` 下載 `yolov8m.pt` 並放至 `models/ultralytics/bbox/face_yolov8m.pt`

**錯誤：FaceDetailer 精修後臉部出現生硬邊界**
- 原因：feather 設定過低，臉部貼回時邊緣未平滑過渡
- 解法：將 FaceDetailer 的 `feather` 值提高至 30–50

**錯誤：FaceDetailer 精修後臉部表情或五官大幅改變（不再像參考照）**
- 原因：FaceDetailer 的 denoise 過高，二次去噪偏離了 IPAdapter 的約束
- 解法：將 denoise 降至 0.35–0.40；確認 FaceDetailer 也有連結 IPAdapter 節點（若工作流設計允許）

**錯誤：`IPAdapter model not found` 或無法載入 `ip-adapter-plus-face_sd15`**
- 原因：檔案放置路徑錯誤，或未安裝 IPAdapter 套件
- 解法：
  1. 確認 `ip-adapter-plus-face_sd15.safetensors` 位於 `ComfyUI/models/ipadapter/` 目錄
  2. 透過 ComfyUI Manager 安裝 `ComfyUI-IPAdapter-plus` 套件

**錯誤：`CLIP-ViT-H-14` 視覺編碼器載入失敗**
- 原因：檔案放置路徑錯誤
- 解法：確認 `CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors` 位於 `ComfyUI/models/clip_vision/` 目錄

**錯誤：OpenPose 預處理器偵測不到人物骨架**
- 原因：姿勢參考照人物過小、被遮擋或角度過特殊
- 解法：改用人物清晰可見的全身照，確保主要關節點（肩、肘、腕、髖、膝、踝）都在畫面內

**錯誤：`CUDA out of memory`**
- 原因：SDXL 工作流本身 VRAM 需求不高，若發生通常是 FaceDetailer 的 `max_size` 設定過大
- 解法：將 `max_size` 從 1024 降至 512；或確認 ComfyUI 以 `--force-fp16` 啟動
