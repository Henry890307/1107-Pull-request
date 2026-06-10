# IPAdapter Plus 使用教學

> 適用：ComfyUI 工作站 / RTX 4080 32GB VRAM / ComfyUI_IPAdapter_plus（cubiq）

---

## 目錄

1. [IPAdapter 概念](#1-ipadapter-概念)
2. [安裝 IPAdapter Plus 節點](#2-安裝-ipadapter-plus-節點)
3. [模型檔案放置位置](#3-模型檔案放置位置)
4. [IPAdapterUnifiedLoader 的 Preset 設定](#4-ipadapterunifiedloader-的-preset-設定)
5. [核心參數說明](#5-核心參數說明)
6. [人物換臉一致性技巧](#6-人物換臉一致性技巧)
7. [FaceID 用法與所需 LoRA](#7-faceid-用法與所需-lora)
8. [與 ControlNet 搭配使用](#8-與-controlnet-搭配使用)
9. [常見錯誤與排除](#9-常見錯誤與排除)

---

## 1. IPAdapter 概念

IPAdapter（Image Prompt Adapter）是一種影像提示注入技術，允許你將一張參考圖片的視覺風格、人物外觀或物件特徵注入到生成過程中，而無需修改模型權重。

### 核心能力

- **風格遷移**：將參考圖的整體風格套用到新生成的圖像
- **人物一致性**：保持角色外觀（臉部、服裝、髮型）在不同姿勢/場景中的一致性
- **FaceID**：專注於臉部特徵的精確保留（需要額外 insightface 支援）
- **構圖引導**：以圖像而非文字描述引導構圖

### 與 ControlNet 的差異

| 比較項目 | ControlNet | IPAdapter |
|---|---|---|
| 控制來源 | 結構條件圖（邊緣/深度/姿勢）| 參考圖像的視覺特徵 |
| 控制維度 | 空間結構（2D 條件）| 語意特徵（風格/外觀）|
| 常見用途 | 保留空間布局 | 保留人物外觀/風格 |
| 可疊加 | 是 | 是，且可與 ControlNet 同時使用 |

---

## 2. 安裝 IPAdapter Plus 節點

### 方式一：透過 ComfyUI-Manager 安裝（推薦）

1. 啟動 ComfyUI，開啟 Manager（右鍵選單或側欄）
2. 點擊「**Install Custom Nodes**」
3. 搜尋「`IPAdapter`」→ 選擇 `ComfyUI_IPAdapter_plus`（作者：cubiq）
4. 點擊 Install，重啟 ComfyUI

### 方式二：Git Clone

```powershell
cd D:\ComfyUI\custom_nodes
git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus.git
```

### 安裝 insightface（FaceID 必要依賴）

FaceID 功能需要 insightface：

```powershell
# 先安裝 Visual C++ Build Tools（Windows 必要）
# 下載：https://visualstudio.microsoft.com/visual-cpp-build-tools/

# 安裝 insightface
pip install insightface

# 若安裝失敗，嘗試預編譯版
pip install insightface --extra-index-url https://download.pytorch.org/whl/cu124
```

> insightface 在 Windows 安裝常見問題請見第 9 節排除指南。

---

## 3. 模型檔案放置位置

### IPAdapter 模型

放置路徑：`ComfyUI/models/ipadapter/`

| 模型檔案名稱 | 用途 | 大小 |
|---|---|---|
| `ip-adapter-plus_sdxl_vit-h.safetensors` | SDXL 通用 IPAdapter PLUS | ~1.1 GB |
| `ip-adapter-plus-face_sdxl_vit-h.safetensors` | SDXL 人臉專用 PLUS | ~1.1 GB |
| `ip-adapter-faceid-plusv2_sdxl.bin` | SDXL FaceID Plus v2 | ~0.9 GB |
| `ip-adapter_sdxl_vit-h.safetensors` | SDXL 基礎版（輕量）| ~0.9 GB |
| `ip-adapter-plus_sd15.safetensors` | SD1.5 PLUS | ~0.9 GB |
| `ip-adapter-plus-face_sd15.safetensors` | SD1.5 臉部 PLUS | ~0.9 GB |
| `ip-adapter-faceid-plusv2_sd15.bin` | SD1.5 FaceID Plus v2 | ~0.8 GB |
| `ip-adapter-faceid_sdxl_lora.safetensors` | SDXL FaceID LoRA（搭配 bin 使用）| ~0.5 GB |
| `ip-adapter-faceid_sd15_lora.safetensors` | SD1.5 FaceID LoRA（搭配 bin 使用）| ~0.3 GB |

> FaceID 的 `.bin` 模型需搭配對應 LoRA（見第 7 節）。

### CLIP Vision 模型

放置路徑：`ComfyUI/models/clip_vision/`

| 模型檔案名稱 | 用途 | 搭配的 IPAdapter |
|---|---|---|
| `clip-vit-h-14-laion2B-s32B-b79K.safetensors` | ViT-H（高精度）| PLUS 系列 |
| `clip-vit-large-patch14.safetensors` | ViT-L（輕量）| 基礎版 |
| `CLIP-ViT-bigG-14-laion2B-39B-b160k.safetensors` | ViT-bigG（最高精度）| bigG 系列 |

> **重要**：CLIP Vision 模型與 IPAdapter 模型需正確對應（ViT-H 配 PLUS，bigG 配 bigG），否則會出現特徵不匹配錯誤。

---

## 4. IPAdapterUnifiedLoader 的 Preset 設定

`IPAdapterUnifiedLoader` 是 cubiq 版的統一載入節點，透過 `preset` 參數自動選擇對應模型。

### 主要 Preset 列表

| Preset 名稱 | 對應模型 | 用途 | VRAM 消耗 |
|---|---|---|---|
| `LIGHT - SD1.5 only (low strength)` | ip-adapter_sd15 + ViT-L | SD1.5 輕量引導 | ~2 GB |
| `STANDARD (medium strength)` | ip-adapter-plus_sd15 + ViT-H | SD1.5 標準 | ~3 GB |
| `PLUS (high strength)` | ip-adapter-plus_sd15 + ViT-H | SD1.5 強力 | ~3 GB |
| `PLUS FACE (portraits)` | ip-adapter-plus-face_sd15 + ViT-H | SD1.5 人臉強化 | ~3 GB |
| `FULL FACE - SD1.5 only (portraits)` | ip-adapter-full-face_sd15 + ViT-H | SD1.5 全臉控制 | ~3 GB |
| `PLUS (high strength)` | ip-adapter-plus_sdxl_vit-h + ViT-H | SDXL 強力 | ~4 GB |
| `PLUS FACE (portraits)` | ip-adapter-plus-face_sdxl_vit-h + ViT-H | SDXL 臉部 | ~4 GB |
| `FaceID` | ip-adapter-faceid_sdxl/sd15 + ViT-H | FaceID 基礎版 | ~3 GB |
| `FaceID Plus` | ip-adapter-faceid-plus_sdxl/sd15 + ViT-H | FaceID 增強版 | ~3 GB |
| `FaceID Plus v2` | ip-adapter-faceid-plusv2_sdxl/sd15 + ViT-H | FaceID 最新版（推薦）| ~3 GB |
| `FaceID Portrait (style transfer)` | faceid-portrait | 臉部風格遷移 | ~3 GB |

### 如何選擇 Preset

```
需要保持人物整體外觀（非臉部）？
  → PLUS 系列

只需保持臉部特徵？
  → PLUS FACE 或 FaceID Plus v2

需要極高臉部相似度（換姿勢但保持同一人）？
  → FaceID Plus v2

處理 SDXL 生成（1024x1024）？
  → 選 SDXL 對應 Preset

處理 SD1.5 生成（512/768）？
  → 選 SD1.5 對應 Preset
```

---

## 5. 核心參數說明

### weight（影像提示強度）

| 值域 | 效果 |
|---|---|
| 0.0 | 完全忽略參考圖像 |
| 0.3~0.5 | 輕度引導，風格微微相似 |
| 0.7~0.9 | 中強度，外觀明顯相似 |
| 1.0~1.5 | 強力複製，高度相似（可能犧牲多樣性）|

**建議起始值**：0.7~0.8（PLUS 系列），FaceID 可用 0.8~1.0

### weight_type（權重類型）

| 類型 | 說明 | 適用場景 |
|---|---|---|
| `linear` | 線性均勻分配 | 通用，預設建議 |
| `ease in` | 早期低、後期高 | 保留創意開始，後期靠攏參考 |
| `ease out` | 早期高、後期低 | 早期鎖定結構，後期自由 |
| `ease in-out` | 中間高、兩端低 | 均衡過渡 |
| `weak input` | 主圖影響弱 | 輕微風格引導 |
| `strong input` | 主圖影響強 | 嚴格保留參考外觀 |
| `style transfer` | 只遷移風格，不複製內容 | 風格遷移工作流 |
| `composition` | 保留構圖結構 | 構圖引導 |

**人物一致性推薦**：`linear` 或 `strong input`

### start_at 與 end_at（作用時間範圍）

與 ControlNet 的 start_percent / end_percent 概念相同，控制 IPAdapter 在去噪過程的影響時段：

| 設定 | 效果 |
|---|---|
| `start_at=0.0, end_at=1.0` | 全程作用，最強一致性 |
| `start_at=0.0, end_at=0.7` | 早期引導結構，後期自由細節 |
| `start_at=0.2, end_at=0.8` | 跳過初期隨機，在中段引導 |

---

## 6. 人物換臉一致性技巧

### 工作流概覽

```
[參考圖（人物照片）]
        ↓
[IPAdapterUnifiedLoader: PLUS FACE / FaceID Plus v2]
        ↓
[IPAdapter 節點] weight=0.85, weight_type=linear, start=0.0, end=0.9
        ↓
[CLIPTextEncode: 提示詞描述新場景/姿勢/服裝]
        ↓
[KSampler / SamplerCustomAdvanced]
        ↓
[VAEDecode] → 新場景中保持相同人物外觀
```

### 提高人物一致性的技巧

1. **參考圖選擇**：
   - 使用清晰正面照或半側面照作為參考
   - 避免強烈光線或遮擋面部的參考圖
   - 多張參考圖可搭配 `IPAdapterBatch` 節點使用

2. **多張參考圖（IPAdapterBatch）**：
   ```
   [參考圖 1（正面）] ─┐
   [參考圖 2（側面）] ─┤→ [IPAdapterBatch] → 疊加特徵
   [參考圖 3（全身）] ─┘
   ```

3. **weight_type 選擇**：
   - 換場景不換姿勢：`linear`
   - 換姿勢但保持臉部：`strong input`
   - 風格遷移（保留臉部同時轉換風格）：`style transfer`

4. **與 ControlNet 搭配（見第 8 節）**：
   - IPAdapter 控制外觀 + OpenPose 控制姿勢 = 最強人物一致性

5. **解析度建議**：
   - 輸入參考圖建議與生成解析度相近（如都用 512x512 或 1024x1024）
   - 過小的參考圖會導致特徵提取不精確

---

## 7. FaceID 用法與所需 LoRA

FaceID 使用 insightface 的人臉識別技術，提供比 PLUS FACE 更高的臉部相似度。

### 必要依賴

1. **insightface** Python 套件（見第 2 節安裝）
2. **FaceID IPAdapter 模型**（`.bin` 格式）
3. **FaceID LoRA**（`.safetensors` 格式）

### FaceID 模型與 LoRA 對應

| 基礎模型 | IPAdapter 模型 | 搭配 LoRA |
|---|---|---|
| SD1.5 | `ip-adapter-faceid_sd15.bin` | `ip-adapter-faceid_sd15_lora.safetensors` |
| SD1.5 | `ip-adapter-faceid-plusv2_sd15.bin` | `ip-adapter-faceid-plusv2_sd15_lora.safetensors` |
| SDXL | `ip-adapter-faceid_sdxl.bin` | `ip-adapter-faceid_sdxl_lora.safetensors` |
| SDXL | `ip-adapter-faceid-plusv2_sdxl.bin` | `ip-adapter-faceid-plusv2_sdxl_lora.safetensors` |

### FaceID 節點流程

```
[參考圖（人物照片）]
        ↓
[IPAdapterUnifiedLoader: FaceID Plus v2]
   → 自動載入 FaceID 模型 + CLIP Vision
        ↓
[IPAdapterFaceID 節點]
   weight=0.9, weight_type=linear
   start_at=0.0, end_at=0.9
        ↓
[Load LoRA: ip-adapter-faceid-plusv2 LoRA]
   強度建議：0.6~0.8
        ↓
[KSampler]
```

### FaceID 使用注意事項

1. **insightface 必須正確安裝**：缺少 insightface 時節點會報錯（見第 9 節）
2. **LoRA 必須載入**：FaceID 模型需與對應 LoRA 搭配，否則效果大打折扣
3. **LoRA 強度**：通常設 0.6~0.8，過高會導致臉部過擬合
4. **人臉偵測失敗**：若參考圖無法偵測到人臉，FaceID 節點會靜默失效（無錯誤但無效果），確認參考圖包含清晰可見的人臉

---

## 8. 與 ControlNet 搭配使用

IPAdapter 與 ControlNet 可以同時使用，各司其職：

- **IPAdapter**：控制外觀（人物長什麼樣）
- **ControlNet**：控制結構（人物站在哪、姿勢如何）

### 搭配節點鏈

```
[正面提示詞]
   ↓
[IPAdapterAdvanced]  ← 外觀一致性（參考圖）
   weight=0.8
   ↓
[ControlNetApplyAdvanced: OpenPose]  ← 姿勢控制
   strength=0.85
   ↓
[ControlNetApplyAdvanced: Depth]  ← 場景空間（選用）
   strength=0.7
   ↓
[KSampler / SamplerCustomAdvanced]
```

### 搭配技巧

1. **IPAdapter 先、ControlNet 後**：先讓外觀特徵注入，再以 ControlNet 修正結構
2. **各自強度調低**：兩者都在 0.7~0.85 之間（相互補充而非各自全力）
3. **weight_type 配合**：
   - 需要保留臉部但更換姿勢：IPAdapter 用 `PLUS FACE`，ControlNet 用 OpenPose
   - 需要保留整體風格並保持場景：IPAdapter 用 `PLUS`，ControlNet 用 Depth

### 推薦組合場景

| 場景 | IPAdapter 設定 | ControlNet 設定 |
|---|---|---|
| 人物換背景（保持外觀）| PLUS, weight=0.8 | Depth 0.7（場景空間）|
| 人物換姿勢（保持臉部）| PLUS FACE, weight=0.85 | OpenPose 0.85 |
| 角色一致性（不同場景）| FaceID Plus v2, weight=0.9 | OpenPose 0.8 |
| 風格遷移（保持人物）| PLUS, style transfer mode | Canny 0.7（保結構）|

---

## 9. 常見錯誤與排除

### CLIP Vision 找不到

**錯誤訊息**：`clip_vision model not found` 或模型載入失敗

| 原因 | 解法 |
|---|---|
| 模型未放至 `clip_vision/` 目錄 | 確認路徑：`ComfyUI/models/clip_vision/` |
| 檔案名稱不符 | IPAdapterUnifiedLoader 依檔名配對，確認與預期名稱一致 |
| Preset 與 CLIP Vision 模型不匹配 | PLUS 系列需要 ViT-H，bigG Preset 需要 ViT-bigG |

**快速確認**：在 ComfyUI 的 `LoadCLIPVision` 節點下拉選單中，應該可以看到模型名稱。

### Preset 對應模型缺失

**現象**：選擇 Preset 後節點顯示錯誤或生成結果無 IPAdapter 效果

| 原因 | 解法 |
|---|---|
| ipadapter/ 目錄缺少對應模型 | 執行 `03_download_models.ps1` 選擇對應選項下載 |
| 模型版本不符 | cubiq 節點版本與模型版本需對應，更新節點後重下載 |

### insightface 安裝失敗（FaceID 無法使用）

**錯誤訊息**：`ModuleNotFoundError: No module named 'insightface'`

| 解法 | 指令 |
|---|---|
| 方法一：標準安裝 | `pip install insightface` |
| 方法二：安裝 VC++ Build Tools 後重裝 | 下載 Visual C++ Build Tools 後 `pip install insightface` |
| 方法三：使用預編譯 wheel | 前往 https://github.com/Gourieff/Assets 下載對應 wheel |
| 可攜版 | `.\python_embeded\python.exe -m pip install insightface` |

> 安裝 insightface 後需重啟 ComfyUI。

### FaceID LoRA 未載入

**現象**：FaceID 有效果但人臉相似度低

**解法**：確認工作流包含 `Load LoRA` 節點，載入對應 FaceID LoRA 檔案（`ip-adapter-faceid-plusv2_sdxl_lora.safetensors`），強度設 0.6~0.8。

### IPAdapter 效果過強或過弱

| 現象 | 解法 |
|---|---|
| 生成圖幾乎複製參考圖 | 降低 weight（從 0.8 降至 0.5~0.6）|
| 提示詞描述的內容完全消失 | weight 過高，降至 0.5 以下 |
| 人物外觀與參考圖完全不像 | 提高 weight，確認 CLIP Vision 模型正確載入 |
| 僅有顏色相似但外觀不同 | 改用 `strong input` 或 `FaceID` Preset |

### 節點版本不相容

若升級 ComfyUI_IPAdapter_plus 後舊工作流出錯：

1. 開啟 Manager → Update Custom Nodes
2. 若問題持續，嘗試重裝：`cd custom_nodes && rm -rf ComfyUI_IPAdapter_plus && git clone ...`

---

> 下一步：閱讀 [04_flux.md](./04_flux.md) 學習 FLUX 模型使用方式。
