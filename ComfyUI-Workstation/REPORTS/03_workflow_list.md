# ComfyUI 工作站 — 工作流清單

> 版本：v2.0 | 產生日期：2026-06-10
> 所有工作流均針對 RTX 4080 32GB VRAM / 96GB RAM 最佳化

---

## 重要說明

- **VRAM 估計**：基於 RTX 4080 32GB，實際用量受圖像解析度與批次大小影響
- **速度估計**：基於 RTX 4080 32GB，啟用 fp16 精度、無 LoRA 疊加的單張生成時間
- **影片分段限制**：Wan2.2 每次最多生成約 81 幀（5 秒/24fps），長影片需分段後串接

---

## 工作流總覽表

| # | 名稱 | 檔案路徑 | 用途 | 輸出類型 |
|---|------|---------|------|----------|
| 1 | Architecture_Pro | `Architecture/Architecture_Pro.json` | CAD 線稿/截圖轉建築渲染 | 靜態圖像 |
| 2 | Interior_Design_Pro | `Interior/Interior_Design_Pro.json` | SketchUp 模型轉室內設計渲染 | 靜態圖像 |
| 3 | Character_Consistency | `Character/Character_Consistency.json` | 多場景人物一致性生成 | 靜態圖像 |
| 4 | Product_Advertising | `Product/Product_Advertising.json` | 商品廣告圖與情境合成 | 靜態圖像 |
| 5 | Animal_Video | `Video/Animal_Video.json` | AI 動物影片生成（圖生影片） | 影片 |
| 6 | Human_Video | `Video/Human_Video.json` | AI 人物影片生成（圖生影片） | 影片 |
| 7 | Church_Design | `Church/Church_Design.json` | 教會海報與多尺寸宣傳設計 | 靜態圖像（多尺寸） |

---

## 工作流詳細說明

### 1. Architecture_Pro — CAD 轉建築渲染

| 項目 | 詳細資訊 |
|------|----------|
| **檔案路徑** | `ComfyUI_Workflows/Architecture/Architecture_Pro.json` |
| **用途** | 將 AutoCAD 線稿截圖或 SketchUp 外觀圖轉換為專業建築渲染圖 |
| **核心技術** | LineArt ControlNet（線稿保留）+ FLUX ControlNet Union（結構控制）+ FLUX Kontext（風格融合）+ UltimateSDUpscale（4K 輸出） |
| **主要模型** | `flux1-kontext-dev` + `flux_controlnet_union_pro_2` + `control_v11p_sd15_lineart_fp16` + `flux_ae` + `t5xxl_fp16` + `4x-UltraSharp` |
| **輸入要求** | 建築線稿圖（PNG/JPG）+ 文字提示詞（材質/光線/風格描述） |
| **輸出類型** | 靜態圖像（PNG） |
| **推薦輸出尺寸** | 1024×1024（基礎）→ 4096×4096（UltimateSDUpscale 放大後） |
| **推薦 Steps** | 20–28（FLUX 模型 20 步即可達到高品質） |
| **推薦 CFG** | 1.0（FLUX 使用 Guidance Scale 而非 CFG，建議 2.5–3.5） |
| **推薦 Sampler** | `euler` |
| **推薦 Scheduler** | `simple` 或 `beta` |
| **ControlNet 強度** | LineArt: 0.6–0.8，ControlNet Union: 0.5–0.7 |
| **VRAM 估計** | 18–26 GB（FLUX fp16）；放大階段峰值可達 28 GB |
| **速度估計** | 基礎生成 40–60 秒；含 UltimateSDUpscale 放大 3–6 分鐘 |
| **適用場景** | 建築師提案展示、AutoCAD 圖面可視化、建案行銷材料 |

---

### 2. Interior_Design_Pro — SketchUp 轉室內設計渲染

| 項目 | 詳細資訊 |
|------|----------|
| **檔案路徑** | `ComfyUI_Workflows/Interior/Interior_Design_Pro.json` |
| **用途** | 將 SketchUp 室內空間模型轉換為高品質室內設計渲染圖 |
| **核心技術** | Depth ControlNet（空間結構）+ Canny ControlNet（傢具輪廓）雙重控制 + FLUX Kontext（材質/風格生成） |
| **主要模型** | `flux1-kontext-dev` + `control_v11f1p_sd15_depth_fp16` + `control_v11p_sd15_canny_fp16` + `flux_controlnet_union_pro_2` + `flux_ae` |
| **輸入要求** | SketchUp 截圖（含深度通道或截圖）+ 設計風格提示詞 |
| **輸出類型** | 靜態圖像（PNG） |
| **推薦輸出尺寸** | 1024×768（室內橫幅）或 1024×1024 |
| **推薦 Steps** | 20–25 |
| **推薦 CFG / Guidance** | FLUX Guidance: 2.5–3.5 |
| **推薦 Sampler** | `euler` 或 `dpmpp_2m` |
| **推薦 Scheduler** | `simple` |
| **ControlNet 強度** | Depth: 0.7–0.9（空間結構優先），Canny: 0.4–0.6（輪廓輔助） |
| **VRAM 估計** | 18–24 GB |
| **速度估計** | 20–40 秒（單圖）；雙 ControlNet 前處理額外 3–5 秒 |
| **適用場景** | 室內設計師方案展示、業主溝通提案、SketchUp 模型可視化 |

---

### 3. Character_Consistency — 人物一致性

| 項目 | 詳細資訊 |
|------|----------|
| **檔案路徑** | `ComfyUI_Workflows/Character/Character_Consistency.json` |
| **用途** | 維持同一人物特徵在不同場景、服裝、角度下的一致性 |
| **核心技術** | IPAdapter Face（人臉 ID 鎖定）+ OpenPose ControlNet（姿勢控制）+ FaceDetailer（人臉精修） |
| **主要模型** | `Juggernaut-XL_v9` 或 `RealVisXL_V5.0_fp16` + `ip-adapter-faceid-plusv2_sdxl` + `control_v11p_sd15_openpose_fp16` + `CLIP-ViT-bigG-14` |
| **輸入要求** | 人物參考照片（清晰正臉）+ 姿勢參考圖（可選）+ 場景描述 |
| **輸出類型** | 靜態圖像（PNG） |
| **推薦輸出尺寸** | 832×1216（人像直幅）或 1024×1024 |
| **推薦 Steps** | 30–35 |
| **推薦 CFG** | 5–7 |
| **推薦 Sampler** | `dpmpp_2m_sde` 或 `euler_ancestral` |
| **推薦 Scheduler** | `karras` |
| **IPAdapter 強度** | Face: 0.6–0.85（太高會失去多樣性，太低會失去一致性） |
| **FaceDetailer** | 建議啟用，detect_size: 512，步驟數與主流程一致 |
| **VRAM 估計** | 10–16 GB（SDXL + IPAdapter）；FaceDetailer 額外 2–3 GB |
| **速度估計** | 25–40 秒（含 FaceDetailer 後處理） |
| **適用場景** | 社群媒體人物系列圖、品牌代言人形象、漫畫/故事角色一致性 |

---

### 4. Product_Advertising — 商品廣告

| 項目 | 詳細資訊 |
|------|----------|
| **檔案路徑** | `ComfyUI_Workflows/Product/Product_Advertising.json` |
| **用途** | 商品圖合成廣告情境，保留商品外觀並生成專業廣告背景 |
| **核心技術** | IPAdapter（商品外觀鎖定）+ SoftEdge ControlNet（輪廓保留）+ FLUX Kontext（情境融合）+ 放大輸出 |
| **主要模型** | `flux1-kontext-dev` + `ip-adapter-plus_sdxl_vit-h` + `control_v11p_sd15_softedge_fp16` + `4x_foolhardy_Remacri` + `CLIP-ViT-bigG-14` |
| **輸入要求** | 商品白底照片或去背圖（PNG）+ 廣告情境描述（場景/光線/品牌風格） |
| **輸出類型** | 靜態圖像（PNG） |
| **推薦輸出尺寸** | 1024×1024（正方形）或 1200×628（廣告橫幅）|
| **推薦 Steps** | 20–25（FLUX）|
| **推薦 CFG / Guidance** | FLUX Guidance: 2.5–4.0 |
| **推薦 Sampler** | `euler` |
| **推薦 Scheduler** | `simple` |
| **IPAdapter 強度** | 0.5–0.75（保留商品特徵，允許光線自然融合） |
| **SoftEdge 強度** | 0.5–0.7 |
| **VRAM 估計** | 16–24 GB |
| **速度估計** | 30–50 秒（含放大） |
| **適用場景** | 電商商品廣告、品牌 IG 貼文、商品型錄、平面廣告 |

---

### 5. Animal_Video — AI 動物影片

| 項目 | 詳細資訊 |
|------|----------|
| **檔案路徑** | `ComfyUI_Workflows/Video/Animal_Video.json` |
| **用途** | 將靜態動物圖像生成流暢的 AI 動畫影片（圖生影片） |
| **核心技術** | Wan2.2 I2V（Image-to-Video，圖生影片）+ WanVideoWrapper + VideoHelperSuite |
| **主要模型** | `wan2.2_i2v_low_noise_14B_fp16` + `wan_2.1_vae` + `umt5_xxl_fp16` |
| **輸入要求** | 動物參考圖（PNG/JPG，建議 720p 以上）+ 動作描述提示詞 |
| **輸出類型** | 影片（MP4，建議 24fps） |
| **推薦輸出解析度** | 720×480 或 1280×720（720p）|
| **推薦幀數** | 81 幀（約 5 秒，24fps）— **單次最大限制** |
| **推薦 Steps** | 20–30 |
| **推薦 CFG** | 5–7 |
| **推薦 Sampler** | `euler` 或 `dpmpp_2m` |
| **推薦 Scheduler** | `linear` 或 `beta` |
| **VRAM 估計** | 24–30 GB（Wan2.2 14B fp16） |
| **速度估計** | 720p 81幀：8–15 分鐘/段 |
| **長影片說明** | 60 秒需分 12 段生成（每段 81 幀），再用 DaVinci Resolve 或 Premiere 串接；Frame-Interpolation 可補幀至更高流暢度 |
| **適用場景** | 社群媒體動物短影音、品牌吉祥物動畫、IG Reels 動物內容 |

---

### 6. Human_Video — AI 人物影片

| 項目 | 詳細資訊 |
|------|----------|
| **檔案路徑** | `ComfyUI_Workflows/Video/Human_Video.json` |
| **用途** | 將人物靜態圖像生成自然動態的 AI 影片（圖生影片） |
| **核心技術** | Wan2.2 I2V（人物動作生成）+ WanVideoWrapper + VideoHelperSuite + Frame-Interpolation（可選補幀） |
| **主要模型** | `wan2.2_i2v_low_noise_14B_fp16` + `wan_2.1_vae` + `umt5_xxl_fp16` |
| **輸入要求** | 人物照片（PNG/JPG，建議半身/全身清晰圖）+ 動作提示詞（如：walking, talking, dancing） |
| **輸出類型** | 影片（MP4，建議 24fps） |
| **推薦輸出解析度** | 720×480 或 1280×720（720p）|
| **推薦幀數** | 81 幀（約 5 秒，24fps）— **單次最大限制** |
| **推薦 Steps** | 20–30 |
| **推薦 CFG** | 5–8（人物動作建議略高以保持一致性） |
| **推薦 Sampler** | `dpmpp_2m` |
| **推薦 Scheduler** | `linear` |
| **VRAM 估計** | 24–30 GB |
| **速度估計** | 720p 81幀：8–15 分鐘/段 |
| **長影片說明** | 60 秒需分 12 段生成，建議每段結尾與下一段開頭保留 2–3 幀重疊以利串接；Frame-Interpolation（RIFE）可從 24fps 補至 60fps |
| **適用場景** | AI 人物短影音、品牌人物動畫、虛擬主播素材、社群媒體影片 |

---

### 7. Church_Design — 教會海報與多尺寸設計

| 項目 | 詳細資訊 |
|------|----------|
| **檔案路徑** | `ComfyUI_Workflows/Church/Church_Design.json` |
| **用途** | 教會活動海報、主日崇拜視覺、IG 輪播設計（支援多種尺寸輸出） |
| **核心技術** | FLUX Kontext（氛圍/風格生成）+ FLUX ControlNet（構圖控制）+ 多尺寸批次輸出 |
| **主要模型** | `flux1-kontext-dev` 或 `flux1-dev` + `flux_controlnet_union_pro_2`（可選）+ `flux_ae` + `t5xxl_fp16` |
| **輸入要求** | 活動主題文字 + 風格描述（光線/色調/氛圍）+ 可選參考圖 |
| **輸出類型** | 靜態圖像（PNG，多尺寸） |
| **支援輸出尺寸** | 1080×1080（IG 方形）、1080×1350（IG 直幅）、1080×1920（Stories/Reels）、A4 海報（2480×3508 at 300dpi）|
| **推薦 Steps** | 20–25（FLUX 高效率）|
| **推薦 CFG / Guidance** | FLUX Guidance: 2.0–3.5（海報風格建議較低以保留創意自由度） |
| **推薦 Sampler** | `euler` |
| **推薦 Scheduler** | `simple` 或 `beta` |
| **VRAM 估計** | 16–22 GB（FLUX fp16，無 ControlNet）；含 ControlNet 約 20–26 GB |
| **速度估計** | 單尺寸 25–40 秒；批次 4 個尺寸約 2–3 分鐘 |
| **適用場景** | 教會週報封面、主日崇拜投影片背景、佈道會海報、讀經課程宣傳、IG 輪播圖文系列 |

---

## 工作流對應模型快速查找

| 工作流 | 必要 Checkpoint | 必要 ControlNet | 必要 IPAdapter | 必要影片模型 |
|--------|----------------|----------------|---------------|------------|
| Architecture_Pro | flux1-kontext-dev | lineart_sd15 + union_pro_2 | — | — |
| Interior_Design_Pro | flux1-kontext-dev | depth_sd15 + canny_sd15 | — | — |
| Character_Consistency | RealVisXL / Juggernaut-XL | openpose_sd15 | faceid-plusv2_sdxl | — |
| Product_Advertising | flux1-kontext-dev | softedge_sd15 | plus_sdxl_vit-h | — |
| Animal_Video | — | — | — | wan2.2_i2v_low_noise_14B |
| Human_Video | — | — | — | wan2.2_i2v_low_noise_14B |
| Church_Design | flux1-dev | union_pro_2（可選） | — | — |

---

## 效能速查表（RTX 4080 32GB）

| 工作流 | 解析度 | Steps | 預估 VRAM | 預估時間 |
|--------|--------|-------|-----------|---------|
| Architecture_Pro | 1024×1024 | 20 | 20–26 GB | 45–60 秒 |
| Architecture_Pro（含 4K 放大） | 4096×4096 | — | 24–28 GB | 4–7 分鐘 |
| Interior_Design_Pro | 1024×768 | 20 | 18–24 GB | 30–45 秒 |
| Character_Consistency | 832×1216 | 30 | 12–16 GB | 25–40 秒 |
| Product_Advertising | 1024×1024 | 20 | 18–24 GB | 35–50 秒 |
| Animal_Video | 1280×720 / 81幀 | 25 | 26–30 GB | 8–15 分鐘/段 |
| Human_Video | 1280×720 / 81幀 | 25 | 26–30 GB | 8–15 分鐘/段 |
| Church_Design | 1080×1080 | 20 | 16–22 GB | 25–35 秒 |

---

*本清單由 ComfyUI 工作站部署套件產生。速度與 VRAM 估計為參考值，實際因系統狀態、模型載入方式與 PyTorch 版本而有所差異。*
