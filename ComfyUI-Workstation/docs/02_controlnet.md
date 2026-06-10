# ControlNet 使用教學

> 適用：ComfyUI 工作站 / RTX 4080 32GB VRAM / comfyui_controlnet_aux 節點

---

## 目錄

1. [ControlNet 概念](#1-controlnet-概念)
2. [SD1.5 六種 ControlNet](#2-sd15-六種-controlnet)
3. [SDXL ControlNet Union ProMax](#3-sdxl-controlnet-union-promax)
4. [FLUX ControlNet Union Pro 2.0](#4-flux-controlnet-union-pro-20)
5. [預處理器選擇（comfyui_controlnet_aux）](#5-預處理器選擇comfyui_controlnet_aux)
6. [核心參數調整](#6-核心參數調整)
7. [雙 ControlNet 疊加技巧](#7-雙-controlnet-疊加技巧)
8. [室內設計工作流實戰](#8-室內設計工作流實戰)
9. [常見錯誤與排除](#9-常見錯誤與排除)

---

## 1. ControlNet 概念

ControlNet 是一種條件控制擴充網路，讓你在生圖時提供「結構性條件」——例如邊緣、深度、姿勢——讓模型在保持這些條件的同時進行創意生成。

### 工作原理

```
原始圖片 → 預處理器 → 條件圖（control image）
                                    ↓
提示詞 → Diffusion Model ← ControlNet 注入條件
                                    ↓
                              生成圖像
```

ControlNet 不改變主模型的權重，而是透過額外的編碼器將條件特徵注入到 Diffusion Model 的各層之中。這表示：

- 一個基礎模型可搭配多種 ControlNet
- 多個 ControlNet 可同時疊加使用
- 調整 `strength`、`start_percent`、`end_percent` 可精細控制影響範圍

### ComfyUI 中的節點結構

```
[Load Image] → [預處理器節點] → [Control Image]
                                         ↓
[Load ControlNet Model] ──────→ [Apply ControlNet]
                                         ↓
                              [條件（Conditioning）] → [KSampler]
```

---

## 2. SD1.5 六種 ControlNet

SD1.5 ControlNet 模型放置於 `ComfyUI/models/controlnet/`。以下為六種常用類型：

### 2.1 Canny（邊緣偵測）

- **模型**：`control_v11p_sd15_canny.safetensors`
- **預處理器**：`CannyEdgePreprocessor`
- **原理**：偵測圖像中的高對比邊緣，生成黑白線稿
- **用途與適用場景**：
  - 保留建築物的銳利輪廓
  - 室內線稿再生（保留家具位置與形狀）
  - 產品設計稿轉渲染圖
  - 漫畫線稿上色
- **調整建議**：預處理器低閾值 100、高閾值 200（預設），邊緣過多可提高至 150/250

### 2.2 Depth（深度估計）

- **模型**：`control_v11f1p_sd15_depth.safetensors`
- **預處理器**：`MiDaSDepthMapPreprocessor`、`DepthAnythingV2Preprocessor`（推薦）
- **原理**：估計圖像的深度資訊，生成灰階深度圖（近白遠黑）
- **用途與適用場景**：
  - 保留場景的空間感與立體結構
  - 室內設計換風格（保留空間比例）
  - 人物構圖重繪（保留前後景關係）
  - 自然風景重繪
- **調整建議**：DepthAnythingV2 品質優於 MiDaS，建議優先使用

### 2.3 OpenPose（人體姿勢）

- **模型**：`control_v11p_sd15_openpose.safetensors`
- **預處理器**：`OpenposePreprocessor`（可選 body/hand/face）
- **原理**：偵測人體關節點，生成骨架圖
- **用途與適用場景**：
  - 固定人物姿勢重繪（換衣、換臉、換風格）
  - 舞蹈動作參考生成
  - 多人構圖控制
  - 體育動作視覺化
- **調整建議**：若需手部精度，啟用 `detect_hand=True`；臉部表情控制啟用 `detect_face=True`

### 2.4 Lineart（線稿）

- **模型**：`control_v11p_sd15_lineart.safetensors`
- **預處理器**：`LineartPreprocessor`（真實系）、`LineartAnimePreprocessor`（動漫系）
- **原理**：提取圖像的線條結構，比 Canny 更乾淨、更接近手繪線稿
- **用途與適用場景**：
  - 手繪線稿上色
  - 動漫插畫風格轉換
  - 建築立面線稿生成
  - 真實照片轉線稿再重繪
- **調整建議**：動漫素材用 `LineartAnimePreprocessor`；真實照片用 `LineartPreprocessor`

### 2.5 SoftEdge（柔和邊緣）

- **模型**：`control_v11p_sd15_softedge.safetensors`
- **預處理器**：`HEDPreprocessor`、`PiDiNetPreprocessor`
- **原理**：偵測柔和邊緣，比 Canny 更具容忍度，不會產生過多細碎邊緣
- **用途與適用場景**：
  - 保留整體構圖但允許細節變化
  - 寫實風格圖像重繪（避免 Canny 過度束縛）
  - 自然物體（花卉、毛髮、雲朵）的形狀引導
  - img2img 的輕度構圖鎖定
- **調整建議**：`strength` 建議 0.6~0.8（比 Canny 低），以保留創意空間

### 2.6 Seg（語意分割）

- **模型**：`control_v11p_sd15_seg.safetensors`
- **預處理器**：`UniformerSegPreprocessor`
- **原理**：將圖像分割為不同語意區域（天空、牆壁、地板、植物等），以色塊表示
- **用途與適用場景**：
  - 室內設計布局控制（明確指定每個區域的材質）
  - 建築外觀改造（保留建築結構，改變材質）
  - 景觀設計視覺化
  - 都市場景風格轉換
- **調整建議**：Seg 圖對生成影響較強，`strength` 建議 0.7~0.9

---

## 3. SDXL ControlNet Union ProMax

### 模型資訊

- **模型名稱**：`controlnet-union-sdxl-1.0-promax.safetensors`
- **放置路徑**：`models/controlnet/`
- **特點**：單一模型支援多種控制類型，透過 `control_type` 參數切換

### 支援的控制類型

| control_type 值 | 對應功能 |
|---|---|
| 0 | OpenPose |
| 1 | Depth |
| 2 | Hed/Pidi/Scribble/Ted |
| 3 | Canny/Lineart/Anime Lineart/Mlsd |
| 4 | Normal |
| 5 | Segment |
| 6 | Tile/Blur |
| 7 | Repaint |

### ComfyUI 使用方式

```
[SetUnionControlNetType] → control_type 設定
        ↓
[ControlNetApplyAdvanced] → conditioning
```

在 ComfyUI 中使用 `SetUnionControlNetType` 節點設定 `control_type`，再接至 `ControlNetApplyAdvanced`。

### SDXL Union ProMax vs SD1.5 個別模型的差異

| 比較項目 | SD1.5 個別模型 | SDXL Union ProMax |
|---|---|---|
| 基礎模型 | SD 1.5 | SDXL |
| 模型數量 | 每種功能各一個模型 | 單一模型含全部功能 |
| 磁碟空間 | ~14 GB（6 種）| ~5 GB |
| 切換方式 | 載入不同模型 | 修改 control_type 參數 |
| 圖像品質 | 穩定成熟 | 更高解析度（1024x1024）|

---

## 4. FLUX ControlNet Union Pro 2.0

### 模型資訊

- **模型名稱**：`FLUX.1-dev-ControlNet-Union-Pro-2.0.safetensors`
- **放置路徑**：`models/controlnet/`
- **對應基礎模型**：FLUX.1-dev

### FLUX ControlNet 與 SD ControlNet 的核心差異

| 比較項目 | SD1.5/SDXL ControlNet | FLUX ControlNet Union Pro 2 |
|---|---|---|
| 架構 | UNet 條件注入 | Transformer（DiT）條件注入 |
| 節點 | `ControlNetApplyAdvanced` | `ControlNetApplyAdvanced`（相同節點，不同模型）|
| 品質 | 成熟穩定 | 更高細節保真度 |
| 支援類型 | 視模型而定 | Canny, Depth, HED, Pose 等多種 |
| 所需 VRAM | ~4~8 GB 額外 | ~8~12 GB 額外（FLUX 本體已佔較多）|

### FLUX ControlNet 工作流節點鏈

```
[UNETLoader: flux1-dev] → FLUX 模型
[LoadControlNet: FLUX.1-dev-ControlNet-Union-Pro-2.0]
[預處理器] → control image
[ControlNetApplyAdvanced] → conditioning
[KSamplerSelect] → [SamplerCustomAdvanced]
```

> 使用 FLUX ControlNet 時，strength 建議從 0.6 開始測試；FLUX 的生成品質對 ControlNet 強度較敏感，過高會造成結構扭曲。

---

## 5. 預處理器選擇（comfyui_controlnet_aux）

`comfyui_controlnet_aux` 節點提供多種預處理器，安裝後在節點選單中可找到。

### 各 ControlNet 類型建議預處理器

| ControlNet 類型 | 推薦預處理器 | 備選預處理器 | 說明 |
|---|---|---|---|
| Canny | `CannyEdgePreprocessor` | - | 調整低/高閾值 |
| Depth | `DepthAnythingV2Preprocessor` | `MiDaSDepthMapPreprocessor` | V2 品質更佳 |
| OpenPose | `OpenposePreprocessor` | `DWPosePreprocessor`（更精確）| 選擇是否偵測手/臉 |
| Lineart | `LineartPreprocessor` | `LineartAnimePreprocessor` | 依素材風格選擇 |
| SoftEdge | `HEDPreprocessor` | `PiDiNetPreprocessor` | HED 通用性較好 |
| Seg | `UniformerSegPreprocessor` | `OneFormerCOCOSegPreprocessor` | OneFormer 更精確 |
| Normal | `BAENormalPreprocessor` | `MiDaSNormalMapPreprocessor` | 用於表面法線 |

### 預處理器輸出解析度設定

建議輸出解析度與目標生成解析度一致：
- SD1.5 生成 512x512 → 預處理器解析度設 512
- SDXL 生成 1024x1024 → 預處理器解析度設 1024
- 解析度過低會導致控制圖模糊，影響生成品質

---

## 6. 核心參數調整

### strength（控制強度）

| 值域 | 效果 |
|---|---|
| 0.0 | 完全不受控制（等同不使用 ControlNet）|
| 0.3~0.5 | 輕度引導，允許較多創意發揮 |
| 0.7~0.9 | 中強度，結構基本符合控制圖 |
| 1.0 | 最強控制，緊密跟隨控制圖結構 |

**建議值**：
- Canny/Lineart（需保留精確線條）：0.8~1.0
- Depth/Pose（保留空間/姿勢）：0.7~0.9
- SoftEdge（輕度構圖引導）：0.5~0.8
- Seg（區域布局控制）：0.7~0.9

### start_percent 與 end_percent（作用時間範圍）

ControlNet 在去噪過程的哪個階段介入，以 0.0（開始）到 1.0（結束）表示：

| 參數 | 說明 | 常見設定 |
|---|---|---|
| start_percent | ControlNet 從哪個去噪步驟開始生效 | 0.0（從頭開始）|
| end_percent | ControlNet 在哪個去噪步驟停止生效 | 1.0（直到結束）|

**進階調參技巧**：

- `start_percent=0.0, end_percent=0.6`：只影響早期大結構，後期自由發揮細節
- `start_percent=0.0, end_percent=1.0`：全程控制，最緊密跟隨控制圖
- `start_percent=0.3, end_percent=0.8`：跳過初始噪點階段，減少過度控制

對於室內設計工作流（雙 ControlNet），常見設定：
- Depth（空間感）：`start=0.0, end=0.7`
- Canny（結構線條）：`start=0.0, end=0.9`

---

## 7. 雙 ControlNet 疊加技巧

在 ComfyUI 中，多個 ControlNet 可以串聯，每個都接收前一個輸出的 conditioning：

### 節點鏈結構

```
[Positive Conditioning（提示詞）]
        ↓
[ControlNetApplyAdvanced: Depth]
   strength=0.75, start=0.0, end=0.7
        ↓
[ControlNetApplyAdvanced: Canny]
   strength=0.85, start=0.0, end=0.9
        ↓
[KSampler / SamplerCustomAdvanced]
```

### 雙 ControlNet 黃金組合

| 組合 | 適用場景 | 建議強度 |
|---|---|---|
| Depth + Canny | 室內設計（保留空間感 + 精確邊緣）| Depth:0.7, Canny:0.8 |
| Depth + OpenPose | 人物場景（空間 + 姿勢）| Depth:0.6, Pose:0.8 |
| Canny + OpenPose | 動漫角色（線稿 + 姿勢）| Canny:0.7, Pose:0.85 |
| SoftEdge + Depth | 自然場景重繪 | SoftEdge:0.6, Depth:0.7 |

### 疊加注意事項

1. **總強度不宜過高**：兩個 ControlNet 各設 1.0 會導致過度約束，生成圖像呆板
2. **順序影響**：先疊加的 ControlNet 影響較強，建議將主要結構控制放第一個
3. **VRAM 考量**：每增加一個 ControlNet 額外消耗約 2~4 GB VRAM，32GB 可穩定使用雙 ControlNet

---

## 8. 室內設計工作流實戰

本套件的 `03_controlnet_interior.json` 工作流採用雙 ControlNet 設計。

### 工作流概覽

```
輸入圖片（現有室內照片）
  ├─→ [DepthAnythingV2Preprocessor] → Depth Map
  └─→ [CannyEdgePreprocessor] → Canny Map
         ↓
[UNETLoader: FLUX.1-dev] 或 [CheckpointLoaderSimple: SD1.5]
[CLIPTextEncode: 正面提示詞] ← 描述目標風格
[CLIPTextEncode: 負面提示詞]
         ↓
[ControlNetApply: Depth, strength=0.75]
         ↓
[ControlNetApply: Canny, strength=0.8]
         ↓
[KSampler / SamplerCustomAdvanced]
         ↓
[VAEDecode] → 輸出圖
```

### 正面提示詞範例（室內設計）

```
a modern minimalist living room, white walls, wooden floor,
large windows, natural light, scandinavian style furniture,
high quality interior photography, 8k, photorealistic
```

### 參數建議

| 參數 | 建議值 | 說明 |
|---|---|---|
| Steps | 20~28 | FLUX 用 20；SD1.5 用 25~30 |
| CFG | 7.0（SD1.5）/ 3.5（FLUX）| FLUX 使用 FluxGuidance |
| Denoise | 0.85~0.95 | 保留原始空間布局，降低可減少變化 |
| 解析度 | 768x1024 | 室內照片常見比例 |

---

## 9. 常見錯誤與排除

| 錯誤訊息 / 現象 | 原因 | 解法 |
|---|---|---|
| `ControlNet model not found` | 模型未放至 controlnet/ 目錄 | 確認模型在 `models/controlnet/` 下 |
| 節點顯示紅框 | comfyui_controlnet_aux 未正確安裝 | Manager → Install Missing Nodes |
| 預處理器模型下載失敗 | 第一次使用會自動下載，網路問題 | 確認網路連線，或手動下載至快取目錄 |
| 控制圖有效但生成圖忽略結構 | strength 太低 | 提高至 0.8~1.0 |
| 生成圖完全複製控制圖，缺乏創意 | strength 過高或 start/end 設定不當 | 降低 strength 或縮短 end_percent |
| SDXL Union ProMax control_type 無效 | 未使用 SetUnionControlNetType 節點 | 在 ControlNet 前加入 SetUnionControlNetType |
| Depth 圖顯示全黑或全白 | 預處理器解析度設定問題 | 確認 resolution 與圖片尺寸一致 |
| FLUX ControlNet 生成扭曲 | FLUX 對 strength 較敏感 | 將 strength 降至 0.5~0.7 測試 |
| 雙 ControlNet 後 VRAM OOM | 總 VRAM 不足 | 降低解析度或使用 fp8 模型 |
| OpenPose 偵測不到手部 | 預設未啟用手部偵測 | `detect_hand=True` |

---

> 下一步：閱讀 [03_ipadapter.md](./03_ipadapter.md) 學習 IPAdapter 人物一致性技術。
