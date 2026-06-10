# Video 工作流說明（動物影片 & 人物影片）

對應工作流檔案：`Animal_Video.json`、`Human_Video.json`

---

## 1. 用途

本目錄包含兩套以 **Wan 2.2 14B I2V（Image-to-Video）** 為核心的影片生成工作流，皆採用官方推薦的 **high-noise + low-noise 雙階段取樣架構**。

### Animal_Video.json
- 輸入寵物或動物靜態照片，生成帶有自然動作的短影片
- 適用場景：鸚鵡唱歌跳舞、貓咪伸懶腰追玩具、狗狗跑步互動
- 社群媒體 Reels / TikTok / YouTube Shorts 素材製作

### Human_Video.json
- 輸入人物靜態照片或肖像，生成人物動作影片
- 適用場景：走路、講話口型、舞蹈、廣告情境展示
- 可選接 FaceDetailer 對逐幀臉部進行後製修復（詳見第 13 節）

硬體基準：i5-13500 / RTX 4080 特規 32GB VRAM / RAM 96GB / Windows 11

---

## 2. 流程圖

### Animal_Video.json 與 Human_Video.json（流程相同）

```
主體照片 (LoadImage)
    │
    ├──► CLIPVisionEncode ──────────────────────────────────┐
    │    (圖像特徵提取，作為 I2V 起始幀條件)               │
    │                                                       │
    ├──► VAEEncode ─────────────────────────────────────────┤
    │    (wan_2.1_vae.safetensors，將圖編為 latent)         │
    │                                                       ▼
    │              WanImageToVideo 條件準備節點
    │              (image + clip_vision + 文字 prompt)
    │
    ├──► UMT5 Text Encode (正向 prompt)
    │    (umt5_xxl_fp16.safetensors)
    │
    ├──► UMT5 Text Encode (負向 prompt)
    │
    ▼
EmptyHunyuanLatentVideo / WanVideoLatent
(設定尺寸 720×1280 或 480×832，frames=81，fps=16)
    │
    ▼
【第一階段：高噪聲取樣】
KSampler #1
(wan2.2_i2v_high_noise_14B_fp16.safetensors)
(steps=20, start_step=0, end_step=10, euler/simple, cfg=3.5)
    │
    ▼
【第二階段：低噪聲取樣】
KSampler #2
(wan2.2_i2v_low_noise_14B_fp16.safetensors)
(steps=20, start_step=10, end_step=20, euler/simple, cfg=3.5)
    │
    ▼
VAEDecode (wan_2.1_vae.safetensors)
    │
    ▼
VHS_VideoCombine
(format=mp4, fps=16, ping_pong=False)
    │
    ▼
輸出：5秒影片 (81 frames @ 16fps)
```

---

## 3. 各節點用途

| 節點名稱 | 功能說明 |
|---|---|
| LoadImage | 載入主體靜態照片（JPG/PNG，建議人臉或動物主體清晰，背景單純） |
| CLIPVisionEncode | 使用 CLIP Vision 模型提取圖像特徵，作為 I2V 的視覺起始條件，維持主體外觀一致性 |
| VAEEncode | 將輸入圖編碼為 Wan latent，作為第一幀的 latent 條件 |
| UMT5TextEncode | Wan 2.2 專用文字編碼器，理解動作描述與場景提示詞（正向/負向各一） |
| WanVideoLatent | 建立影片 latent 空間，設定解析度、幀數與 FPS |
| KSampler #1（高噪） | 第一階段取樣，使用 high_noise 模型處理前半段步數（0-10步），負責建立整體動態結構 |
| KSampler #2（低噪） | 第二階段取樣，使用 low_noise 模型接續後半段步數（10-20步），負責細節精修與時間一致性 |
| VAEDecode | 將影片 latent 解碼為 RGB 幀序列 |
| VHS_VideoCombine | 將幀序列合成 mp4 影片，設定 fps=16，支援輸出預覽與下載 |

> **雙模型設計說明（重要）**：Wan 2.2 14B 的 high-noise 與 low-noise 是官方設計的**兩個獨立擴散模型**，並非同一模型的不同設定。high-noise 負責大尺度動態佈局，low-noise 負責細節還原。兩者必須搭配使用，缺一不可，順序不可顛倒。

---

## 4. 模型與用途

| 模型檔案 | 路徑 | 用途 |
|---|---|---|
| wan2.2_i2v_high_noise_14B_fp16.safetensors | models/diffusion_models/ | I2V 第一階段：高噪聲擴散，建立動態結構（約 28GB） |
| wan2.2_i2v_low_noise_14B_fp16.safetensors | models/diffusion_models/ | I2V 第二階段：低噪聲精修，完善細節與時間連貫性（約 28GB） |
| umt5_xxl_fp16.safetensors | models/clip/ | UMT5 文字編碼器，Wan 2.2 專用，理解動作與場景描述 |
| wan_2.1_vae.safetensors | models/vae/ | Wan 專用 VAE，負責影片 latent 編解碼，不可用 FLUX VAE 替換 |

> **注意**：本工作流不使用 FLUX 模型。Wan 2.2 有獨立的 VAE 與文字編碼器，請勿混用。

---

## 5. 模型下載位置（對應 03 下載腳本選單）

使用工作站安裝目錄下的 `install/03_download_models.ps1` 腳本：

| 選單編號 | 模型 | 說明 |
|---|---|---|
| 選項 6 | wan2.2_i2v_high_noise_14B_fp16.safetensors | Wan 2.2 I2V 高噪模型 |
| 選項 6 | wan2.2_i2v_low_noise_14B_fp16.safetensors | Wan 2.2 I2V 低噪模型 |
| 選項 6 | umt5_xxl_fp16.safetensors | UMT5 文字編碼器（Wan 共用） |
| 選項 6 | wan_2.1_vae.safetensors | Wan VAE（Wan 全系列共用） |

> 選項 6 包含 Wan 2.2 全套（I2V + T2V, 14B fp16），總計約 **110 GB**。
> 若磁碟空間不足，可改下載 fp8_scaled 版本（約一半大小），在腳本中修改檔名中 `fp16` → `fp8_scaled`。

---

## 6. 推薦參數

### 輸出解析度建議

| 用途 | Width | Height | Frames | FPS | 輸出長度 |
|---|---|---|---|---|---|
| 720p 豎版（IG Reels / TikTok）| 720 | 1280 | 81 | 16 | 約 5 秒 |
| 720p 橫版（YouTube Shorts）| 1280 | 720 | 81 | 16 | 約 5 秒 |
| 480p 豎版（低 VRAM 安全選項）| 480 | 832 | 81 | 16 | 約 5 秒 |
| 480p 橫版（快速預覽）| 832 | 480 | 65 | 16 | 約 4 秒 |

### 關鍵參數
- **CFG**：3.5（見第 7 節）
- **Steps**：雙 KSampler 各 20 步，高噪 0→10，低噪 10→20
- **Denoise**：1.0（影片生成不需要 img2img 局部降噪）
- **Frames**：81（對應 ~5 秒 @ 16fps），最大不建議超過 97（約 6 秒）

---

## 7. CFG（Guidance）

**推薦值：3.5**

Wan 2.2 使用與 FLUX 類似的 flow-matching 架構，guidance scale 意義：
- `2.5`：動作最流暢自然，但可能偏離 prompt 描述
- `3.5`：**推薦**，動作自然且符合文字描述，主體一致性佳
- `5.0`：嚴格遵從 prompt，但可能出現幀間閃爍或過度誇張動作
- `7.0+`：不建議，容易導致畫面不穩定、主體變形

---

## 8. Steps（取樣步數）

**推薦：雙 KSampler 各 20 步，共 40 步**

| 配置 | 高噪步數 | 低噪步數 | 總計 | 品質 | 速度 |
|---|---|---|---|---|---|
| 快速預覽 | 0→8 (8步) | 8→15 (7步) | 15步 | 中等 | 約 90 秒 |
| 標準 | 0→10 (10步) | 10→20 (10步) | 20步 | 良好 | 約 3-4 分鐘 |
| **推薦** | **0→20 (20步)** | **20→40 (20步)** | **40步** | **最佳** | **約 5-6 分鐘** |
| 精細 | 0→25 (25步) | 25→50 (25步) | 50步 | 細膩 | 約 8 分鐘 |

> **注意**：KSampler #1 的 `end_step` 等於 KSampler #2 的 `start_step`，兩者步數區間必須銜接，不可重疊或留空。

---

## 9. Sampler（取樣器）

**推薦：`euler`**

| Sampler | 特性 | 適用場景 |
|---|---|---|
| euler | 穩定、幀間一致性佳、動作流暢 | **動物/人物影片首選** |
| euler_ancestral | 細節更豐富，但幀間可能稍有抖動 | 強調紋理的靜物影片 |
| dpmpp_2m | 細節佳，但 Wan 相容性稍差 | 備用選項 |

---

## 10. Scheduler（排程器）

**推薦：`simple`**

- `simple`：Wan 2.2 官方推薦，與 euler 搭配最穩定，幀間過渡自然
- `linear`：部分使用者用於動作較激烈場景，效果因 prompt 而異
- `beta`：不推薦用於影片生成，容易導致開頭幀異常

---

## 11. VRAM 用量（32GB 估計）

### Animal_Video / Human_Video（I2V 14B fp16，720×1280，81 frames）

| 階段 | VRAM 佔用 |
|---|---|
| I2V high_noise 模型載入 | ~28 GB |
| I2V low_noise 模型載入（交換後）| ~28 GB |
| UMT5 文字編碼器 | ~5 GB |
| Wan VAE 編解碼 | ~2-3 GB |
| 影片 latent（720×1280×81f）| ~4-6 GB |
| **取樣高峰（兩模型不同時在 VRAM）** | **~22-28 GB** |

> **重要**：由於單一 fp16 14B 模型約佔 28GB，系統會自動在兩個 KSampler 之間**卸載第一個模型再載入第二個**（model offloading）。這是正常行為，不是錯誤。切換時會有約 10-15 秒的載入停頓。

### 降 VRAM 方案

| 方案 | VRAM 節省 | 代價 |
|---|---|---|
| 改用 fp8_scaled 版本 | 節省約 14GB（28→14GB/模型） | 細節稍微損失，整體可接受 |
| 降低解析度 480×832 | 節省約 3-4GB latent | 畫質降低，適合快速測試 |
| 減少 frames 至 49 | 節省約 2-3GB latent | 影片縮短至約 3 秒 |
| 組合（fp8 + 480p）| 節省約 16-18GB | 適合 16-24GB VRAM 顯卡 |

---

## 12. RTX 4080 32GB 最佳設定

```
# ComfyUI 啟動參數（fp16 14B I2V，無需額外降低記憶體）
python main.py --port 8188

# 若出現 OOM 或 CUDA 錯誤，可嘗試：
python main.py --port 8188 --lowvram
# 或
python main.py --port 8188 --gpu-only --disable-smart-memory
```

### 最佳化建議
1. **不要同時在 VRAM 保留兩個 14B 模型**：32GB 不夠同時容納兩個 fp16 14B 模型，ComfyUI 的 smart memory 管理會自動處理切換
2. **關閉其他佔用 GPU 的程式**：確保 VRAM 完全給 ComfyUI 使用（關閉瀏覽器 GPU 加速、遊戲等）
3. **fp8 替代方案**：若頻繁 OOM，改用 fp8_scaled 版本，檔名格式：`wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors`
4. **批次大小固定為 1**：影片生成 batch_size 必須為 1，增加 batch 會成倍增加 VRAM
5. **先低解析度測試**：新 prompt 先用 480×832 確認動作效果，滿意後再換 720×1280 生成

---

## 重要限制說明：60/120 秒影片不可直接生成

### 單次生成上限

**單次生成約 5 秒（81 frames @ 16fps）是消費級顯卡的實際上限。**

即使擁有 32GB VRAM，在任何單張消費級 GPU 上直接生成 60 秒或 120 秒影片都**不可行**，原因如下：

| 限制因素 | 說明 |
|---|---|
| VRAM 不足 | 60 秒 = 960 frames，latent 體積約為 81f 的 12 倍，遠超 32GB |
| 時間不切實際 | 以 5 秒需 5-6 分鐘推算，60 秒單次需約 60-70 分鐘，不含模型切換 |
| 時間一致性崩壞 | Wan 2.2 Transformer 注意力機制在極長序列下計算成本呈平方增長，品質急遽下降 |

### 標準流程：分段生成 → 串接

製作長影片的正確方法是**多段生成接續**，以下是完整步驟：

**步驟 1：生成第一段（0-5 秒）**
- 輸入主體照片，設定動作提示詞
- 生成 81 frames @ 16fps → 約 5 秒 mp4

**步驟 2：提取最後一幀（Last Frame）**
- 使用 VHS 節點或 FFmpeg 提取第一段影片的最後一幀
- 此幀作為第二段的「起始圖片」輸入

**步驟 3：生成第二段（5-10 秒）**
- 以上一段最後一幀作為 LoadImage 輸入
- 沿用相同或微調的動作提示詞（可略微改變動作繼續）
- 生成第二段 81 frames

**步驟 4：重複步驟 2-3**
- 每次以前一段最後一幀作為下一段起始
- 製作 60 秒需重複約 12 段，120 秒需約 24 段
- 每段約 5-6 分鐘，60 秒影片總計約 1-1.5 小時

**步驟 5：串接所有片段**
- 方案 A：使用 **ComfyUI VHS 節點**（`VHS_VideoCombine`）的串接功能，在工作流中依序接入多個影片
- 方案 B：使用 **FFmpeg** 命令列串接：
  ```
  # 建立 concat 清單
  # file 'segment_001.mp4'
  # file 'segment_002.mp4'
  # ...
  ffmpeg -f concat -safe 0 -i concat_list.txt -c copy output_final.mp4
  ```
- 方案 C：使用 **DaVinci Resolve（免費版）** 或 **CapCut** 進行影片剪輯串接，並可加入過場效果與音樂

**步驟 6（選用）：轉場優化**
- 若片段銜接處有輕微跳動，可在剪輯軟體加入 2-3 幀的**溶解（Dissolve）轉場**
- 或使用插幀工具（FILM、RIFE）在銜接處補幀使過渡更順暢

---

## 13. 預估速度 & 常見錯誤排除

### 預估生成速度（RTX 4080 32GB，單段 81 frames）

| 解析度 | 總步數（雙階段）| 預估時間 | 包含模型切換 |
|---|---|---|---|
| 480×832（fp16 14B）| 40 步 | 約 3-4 分鐘 | 約 3.5-4.5 分鐘 |
| 720×1280（fp16 14B）| 40 步 | 約 5-6 分鐘 | 約 6-7 分鐘 |
| 480×832（fp8_scaled 14B）| 40 步 | 約 2-3 分鐘 | 約 2.5-3.5 分鐘 |
| 720×1280（fp8_scaled 14B）| 40 步 | 約 3-4 分鐘 | 約 4-5 分鐘 |

### Animal_Video Prompt 範例

**1. 鸚鵡唱歌跳舞**
```
Positive: A colorful parrot bobbing its head and dancing rhythmically, 
feathers ruffling, beak moving as if singing, natural perch background, 
smooth movement, bright colors
Negative: blurry, static, distorted beak, color shift, flickering
```

**2. 貓咪跳躍玩耍**
```
Positive: A fluffy cat pouncing playfully at a toy, ears perked up, 
tail swishing, indoor living room setting, smooth natural motion, 
realistic fur movement
Negative: multiple cats, teleportation, jerky motion, warped body
```

**3. 狗狗跑步奔跑**
```
Positive: A golden retriever running joyfully through a green park, 
tongue out, ears flapping, sunlight filtering through trees, 
dynamic movement, realistic fur and motion blur
Negative: static, standing still, background change, color artifacts
```

**4. 動物互動（親密場景）**
```
Positive: A cat and dog nuzzling affectionately, gentle head rubs, 
cozy warm living room, soft natural light, heartwarming interaction
Negative: aggressive behavior, sudden camera cuts, distorted faces
```

### Human_Video Prompt 範例

**1. 人物走路（廣告感）**
```
Positive: A professional woman in business attire walking confidently 
toward camera, city street background, natural stride, hair flowing, 
cinematic motion, sharp focus
Negative: stumbling, distorted limbs, face morph, background flicker
```

**2. 人物講話口型**
```
Positive: A friendly man speaking naturally to camera, 
slight smile, warm expression, studio background, 
natural head movement, realistic lip movement
Negative: frozen expression, mouth not moving, identity change
```

**3. 舞蹈動作**
```
Positive: A dancer performing elegant contemporary dance moves, 
smooth arm movements, expressive body language, stage lighting,
graceful motion, maintaining consistent appearance
Negative: jerky movement, falling, background instability
```

**4. 廣告情境**
```
Positive: A model showcasing product with natural hand gestures,
turning slightly to show product angle, confident smile,
clean studio setting, professional advertising style
Negative: product disappears, hand distortion, face change
```

### FaceDetailer 逐幀臉部修復（Human_Video 選用）

若人物臉部在影片中出現模糊或失真，可選用 FaceDetailer 進行後製：

- **安裝**：需安裝 `ComfyUI-Impact-Pack` 自訂節點
- **流程**：VHS 解幀 → 逐幀跑 FaceDetailer（BBOX Detector + SAM）→ 重新合成影片
- **效率警告**：5 秒（81 幀）全幀跑 FaceDetailer，在 RTX 4080 32GB 上約需 **20-40 分鐘**，僅建議用於最終輸出版本，不適合測試階段
- **建議**：先用低解析度版本確認動作正確，只在最終高解析度版本上執行 FaceDetailer

### 常見錯誤排除

| 錯誤症狀 | 可能原因 | 解決方法 |
|---|---|---|
| CUDA OOM（記憶體不足）| 14B fp16 超出可用 VRAM | 改用 fp8_scaled 版、降低解析度至 480×832、減少 frames |
| 生成全黑影片 | VAE 選錯型號 | 確認使用 wan_2.1_vae.safetensors，不可用 flux_ae |
| 主體動作開始後變形 | CFG 過高或 prompt 動作幅度太大 | 降低 CFG 至 3.0，描述更溫和的動作 |
| 影片幀間閃爍/跳動 | 低噪模型步數不足 | 增加 KSampler #2 步數至少 10 步 |
| 兩段影片銜接跳幀 | 最後一幀提取錯誤 | 確認提取的是第一段最後一幀（不是倒數第二幀） |
| 模型載入卡住 15 秒以上 | 正常，兩模型切換需要時間 | 等待即可，這是 smart memory offloading 正常行為 |
| VHS_VideoCombine 無法使用 | 未安裝 ComfyUI-VideoHelperSuite | 使用 ComfyUI Manager 安裝 `ComfyUI-VideoHelperSuite` |
| UMT5 載入失敗 | 模型路徑錯誤 | 確認 umt5_xxl_fp16.safetensors 在 models/clip/ 下 |
| 影片只有 1 幀 | KSampler frames 設定為 1 | 檢查 WanVideoLatent 節點的 length/frames 參數 |
| FaceDetailer 速度極慢 | 逐幀處理為正常行為 | 只在最終版使用，或限定跑關鍵幀 |
