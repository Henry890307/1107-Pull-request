# ComfyUI 工作站

> 專業 AI 圖像與影片生成部署套件
> 針對建築渲染、室內設計、人物一致性、商品廣告、AI 影片、教會海報設計最佳化

---

## 目錄

1. [硬體規格](#一硬體規格)
2. [套件性質說明（重要）](#二套件性質說明重要)
3. [目錄結構導覽](#三目錄結構導覽)
4. [5 分鐘快速開始](#四5-分鐘快速開始)
5. [完整安裝流程](#五完整安裝流程)
6. [模型說明與用途](#六模型說明與用途)
7. [ControlNet 使用教學](#七controlnet-使用教學)
8. [IPAdapter 使用教學](#八ipadapter-使用教學)
9. [FLUX 模型教學](#九flux-模型教學)
10. [Wan2.2 影片生成教學](#十wan22-影片生成教學)
11. [建築渲染工作流](#十一建築渲染工作流)
12. [室內設計工作流](#十二室內設計工作流)
13. [人物一致性工作流](#十三人物一致性工作流)
14. [動物影片工作流](#十四動物影片工作流)
15. [更新方式](#十五更新方式)
16. [備份方式](#十六備份方式)
17. [常見問題 FAQ](#十七常見問題-faq)

---

## 一、硬體規格

本套件針對以下硬體規格設計與最佳化：

| 元件 | 規格 |
|------|------|
| **CPU** | Intel i5-13500（16 核心） |
| **GPU** | 特規 RTX 4080 32GB VRAM（Ada Lovelace AD103，sm_89，記憶體加大版） |
| **RAM** | 96 GB |
| **作業系統** | Windows 11 |

**這台機器的 AI 生成能力：**
- 以完整 fp16 精度運行 FLUX 14B 模型（無需量化）
- 運行 Wan2.2 14B 影片模型（單張 GPU 完整載入）
- 同時使用 ControlNet + IPAdapter + LoRA 而不 OOM
- 靜態圖像生成：5–60 秒（依模型與解析度）
- 影片生成（81幀/5秒）：8–15 分鐘/段

---

## 二、套件性質說明（重要）

**本套件是在雲端 Linux 容器中產生的「完整部署套件」，並未在您的 Windows 機器上實際執行安裝。**

這是您應該知道的事實：

- 所有腳本、工作流 JSON、說明文件均已**完整備妥**於套件目錄中
- **實際安裝尚未完成**，需由您在 RTX 4080 機器上執行 `install/` 內的腳本
- 7 個工作流已針對您的用途（建築、室內、人物、商品、影片、教會）設計完成
- 請參照[第四節「5 分鐘快速開始」](#四5-分鐘快速開始)或[第五節「完整安裝流程」](#五完整安裝流程)進行實際安裝

---

## 三、目錄結構導覽

```
ComfyUI-Workstation/
├── install/              安裝腳本（從這裡開始）
├── ComfyUI_Workflows/    7 個工作流 JSON
├── docs/                 完整教學文件
├── REPORTS/              安裝報告與清單
└── README.md             本文件
```

| 資料夾 | 內容 | 您什麼時候需要它 |
|--------|------|----------------|
| `install/` | 安裝腳本 | **首次安裝時執行** |
| `ComfyUI_Workflows/` | 工作流 JSON | 載入到 ComfyUI 使用 |
| `docs/` | 詳細教學 | 深入學習各功能時參閱 |
| `REPORTS/` | 模型清單、資料夾結構 | 管理與維護時參閱 |

---

## 四、5 分鐘快速開始

> 假設 ComfyUI 已安裝於 `C:\ComfyUI\`

### 步驟 1：開啟管理員 PowerShell

```powershell
# 右鍵「Windows PowerShell」→「以系統管理員執行」
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 步驟 2：執行一鍵安裝

```bat
cd C:\ComfyUI\ComfyUI-Workstation\install
install_all.bat
```

跟著畫面提示選擇要下載的模型（建議先選 `[4]` SDXL 與 `[8]` 放大模型快速體驗）。

### 步驟 3：啟動 ComfyUI

```bat
cd C:\ComfyUI
python main.py --listen 0.0.0.0 --port 8188
```

### 步驟 4：載入工作流

開啟 `http://127.0.0.1:8188`，將 `ComfyUI_Workflows/Church/Church_Design.json` 拖曳到介面，輸入提示詞，點擊「Queue Prompt」。

---

## 五、完整安裝流程

完整安裝說明請參閱：[docs/01_installation.md](docs/01_installation.md)

安裝完成後的驗證清單請參閱：[REPORTS/01_install_report.md](REPORTS/01_install_report.md)

### 安裝腳本說明

| 腳本 | 功能 | 執行方式 |
|------|------|----------|
| `install_all.bat` | 一鍵執行全流程 | 雙擊或在 cmd 中執行 |
| `01_check_environment.ps1` | 環境前置檢查 | `.\01_check_environment.ps1` |
| `02_install_custom_nodes.bat` | 安裝 22 個自訂節點 | `02_install_custom_nodes.bat` |
| `03_download_models.ps1` | 互動式模型下載（8 選單） | `.\03_download_models.ps1` |
| `04_create_folders.bat` | 建立資料夾結構 | `04_create_folders.bat` |
| `generate_workflows.py` | 產生工作流 JSON | `python generate_workflows.py` |

### 前置需求

- ComfyUI 主程式（https://github.com/comfyanonymous/ComfyUI）
- Python 3.10 或 3.11（64-bit）
- Git for Windows（https://git-scm.com/download/win）
- NVIDIA 驅動程式 535.x+（CUDA 12 支援）
- 磁碟空間：最少 80GB（建議 200GB+）

---

## 六、模型說明與用途

完整模型清單（含大小、路徑、下載選單）請參閱：[REPORTS/02_model_list.md](REPORTS/02_model_list.md)

### 模型架構快速對照

| 架構 | 代表模型 | 適用工作類型 | VRAM 需求 |
|------|---------|------------|-----------|
| SDXL | RealVisXL / Juggernaut | 人物、商品、室內（高彈性）| 8–16 GB |
| FLUX | flux1-dev / kontext-dev | 建築、教會、精準文字理解 | 18–26 GB |
| Wan2.2 | wan2.2_i2v/t2v_14B | AI 影片（圖生影片/文生影片）| 24–30 GB |
| SD1.5 | （搭配 AnimateDiff）| AnimateDiff 動畫序列 | 6–10 GB |

### FLUX vs SDXL 選擇指南

```
選擇 FLUX 當：
  - 提示詞包含複雜空間描述（「左側...右側...前景...背景...」）
  - 需要精確的文字在圖像中顯示
  - 建築/結構圖，需要直線、幾何形狀精確
  - 輸出尺寸 > 1024px 的細節要求高

選擇 SDXL 當：
  - 使用 IPAdapter 做人物或商品一致性
  - 需要大量批次生成（速度比 FLUX 快 2–3x）
  - 搭配大量 LoRA 微調特定風格
  - 預算有限（模型組合更輕量）
```

---

## 七、ControlNet 使用教學

詳細教學：[docs/02_controlnet_guide.md](docs/02_controlnet_guide.md)

### 快速參數指南

| ControlNet 類型 | 強度建議 | 最佳場景 |
|----------------|---------|----------|
| **Canny**（銳利邊緣）| 0.5–0.8 | 傢具輪廓、商品外形、建築窗框 |
| **Depth**（深度圖）| 0.6–0.9 | 室內空間結構、前後景深度關係 |
| **OpenPose**（人體姿勢）| 0.6–0.85 | 人物動作、手部位置、多人排列 |
| **LineArt**（線條藝術）| 0.6–0.85 | CAD 線稿轉渲染、建築平立面 |
| **SoftEdge**（柔和邊緣）| 0.4–0.7 | 商品柔性輪廓、有機形狀保留 |
| **Seg**（語義分割）| 0.5–0.8 | 室內區域色彩規劃、材質分區 |

### FLUX ControlNet Union 說明

`flux_controlnet_union_pro_2.safetensors` 是單一模型支援多種控制模式的統一 ControlNet：
- 在工作流中通過 `control_type` 參數切換（canny/depth/openpose 等）
- 比使用多個獨立 ControlNet 節點更節省 VRAM
- 適合 FLUX 架構（`flux1-dev` / `flux1-kontext-dev`）

---

## 八、IPAdapter 使用教學

詳細教學：[docs/03_ipadapter_guide.md](docs/03_ipadapter_guide.md)

### IPAdapter 模型選擇指南

| 模型 | 搭配架構 | 強度建議 | 適用 |
|------|---------|---------|------|
| `ip-adapter-plus-face_sd15` | SD1.5 | 0.6–0.85 | 人臉特徵鎖定 |
| `ip-adapter-plus_sdxl_vit-h` | SDXL | 0.5–0.75 | 商品外觀、風格參考 |
| `ip-adapter-faceid-plusv2_sdxl` | SDXL | 0.6–0.85 | 人物 ID 最高精度（需搭配 FaceID LoRA）|

### 強度調整原則

```
強度太高（> 0.9）：過度複製參考圖，失去多樣性
強度太低（< 0.4）：特徵保留不足，人物/商品認不出來
建議範圍：0.5–0.8（根據需求微調）

人物一致性（多場景同一人）：0.65–0.80
商品廣告（保留外觀）：0.55–0.75
風格參考（鬆散參考）：0.4–0.6
```

---

## 九、FLUX 模型教學

詳細教學：[docs/04_flux_guide.md](docs/04_flux_guide.md)

### FLUX 關鍵參數

```
推薦設定（FLUX.1-dev）：
  Steps:        20–28（超過 30 步回報遞減）
  Guidance:     2.5–3.5（非 CFG，較低 = 較有創意，較高 = 較遵循提示）
  Sampler:      euler
  Scheduler:    simple 或 beta
  Resolution:   1024×1024 起步

推薦設定（FLUX Kontext Dev，圖像編輯）：
  Steps:        20–25
  Guidance:     2.0–3.0（編輯時建議略低，保留原圖特徵）
  使用場景:     局部修改、風格遷移、材質替換
```

### FLUX 提示詞撰寫技巧

```
FLUX 的文字理解能力遠勝 SDXL，可使用自然語言長句：

建築場景範例：
「A modern residential building with white concrete facade, 
floor-to-ceiling glass windows, surrounded by bamboo garden, 
golden hour lighting from the southwest, photorealistic, 
8K architectural visualization」

室內設計範例：
「Scandinavian minimalist living room, warm oak wood flooring, 
light grey sofa with geometric throw pillows, large window 
overlooking pine forest, natural diffused afternoon light, 
professional interior photography」
```

### FLUX Kontext Pro 注意事項

`flux1-kontext-pro` 為 Black Forest Labs 商業 API 模型，**無公開權重可下載**。
本套件使用 `flux1-kontext-dev`（開源授權版，品質略低於 Pro 版）。
如需 Pro 版，請申請 BFL API Key：https://api.bfl.ml

---

## 十、Wan2.2 影片生成教學

詳細教學：[docs/05_wan_video_guide.md](docs/05_wan_video_guide.md)

### 重要限制（誠實說明）

**Wan2.2 每次最多生成約 81 幀（約 5 秒，24fps）。**

這是模型架構的設計限制，並非本套件的問題。

| 目標影片長度 | 所需段數 | 預估時間（RTX 4080 32GB）|
|------------|---------|------------------------|
| 5 秒（81幀）| 1 段 | 8–15 分鐘 |
| 30 秒 | 6 段 | 50–90 分鐘 |
| 60 秒 | 12 段 | 100–180 分鐘 |
| 120 秒 | 24 段 | 3–6 小時 |

### 長影片製作流程

```
1. 在 ComfyUI 中生成第一段（81幀）
2. 記錄最後一幀作為下一段的起始幀
3. 生成第二段（可調整提示詞實現場景轉換）
4. 重複直到所有段落完成
5. 使用 Frame-Interpolation（RIFE）從 24fps 補幀到 60fps
6. 用 DaVinci Resolve 或 Premiere Pro 串接所有段落
7. 加入音樂、字幕完成最終影片
```

### Wan2.2 推薦參數

```
解析度：1280×720（720p）或 720×480
幀數：81（5 秒，24fps）
Steps：20–30
CFG：5–7
模型：wan2.2_i2v_low_noise_14B_fp16（低雜訊版，細節保留更好）
VAE：wan_2.1_vae
文字編碼器：umt5_xxl_fp16
```

---

## 十一、建築渲染工作流

工作流檔案：`ComfyUI_Workflows/Architecture/Architecture_Pro.json`
詳細說明：`ComfyUI_Workflows/Architecture/README.md`

### 適用場景

- AutoCAD 圖面線稿轉渲染圖
- SketchUp 建築外觀草圖轉專業效果圖
- 建案行銷材料、業主提案展示
- 建築設計不同材質/光線方案快速比較

### 操作步驟

```
1. 開啟 Architecture_Pro.json 工作流
2. 在「LineArt 前處理器」節點載入 AutoCAD 截圖或線稿圖
3. 在「FLUX Kontext」模型載入 flux1-kontext-dev
4. 在「ControlNet」節點選擇 flux_controlnet_union_pro_2
5. 輸入建築風格提示詞（材質/光線/季節/時間）
6. 調整 LineArt ControlNet 強度（建議 0.65–0.80）
7. 執行生成（約 40–60 秒）
8. 若需要 4K 輸出，啟用 UltimateSDUpscale 節點（約 4–7 分鐘）
```

### 建築提示詞範例

```
現代簡約風：
「Modern minimalist architecture, white concrete and glass facade, 
horizontal lines, mature trees, blue sky, late afternoon warm light,
Tadao Ando style, photorealistic, 8K render」

台灣在地風：
「Contemporary Taiwanese residential building, exposed concrete, 
slatted wooden screens, tropical landscape, monsoon season overcast sky,
professional architectural photography」
```

---

## 十二、室內設計工作流

工作流檔案：`ComfyUI_Workflows/Interior/Interior_Design_Pro.json`

### 適用場景

- SketchUp 室內空間草圖轉高品質渲染
- 不同設計風格快速視覺化（現代/北歐/日式/工業風）
- 室內設計師客戶提案
- 材質、顏色、傢具配置方案比較

### 操作步驟

```
1. 開啟 Interior_Design_Pro.json
2. 載入 SketchUp 室內截圖
3. 前處理器會自動執行 Depth 深度圖提取（~3秒）
4. 同時執行 Canny 邊緣提取（保留傢具輪廓）
5. 輸入室內風格提示詞
6. 設定 Depth 強度（0.7–0.9）和 Canny 強度（0.4–0.6）
7. 使用 FLUX Kontext 執行生成

雙 ControlNet 技巧：
  Depth 較高強度 → 保留空間結構（不要變形）
  Canny 較低強度 → 傢具輪廓保留但允許材質改變
```

---

## 十三、人物一致性工作流

工作流檔案：`ComfyUI_Workflows/Character/Character_Consistency.json`

### 適用場景

- 品牌代言人在多個場景保持一致面貌
- 社群媒體人物系列圖（統一角色）
- 故事板/漫畫角色一致性
- AI 模特兒在不同服裝/場景的應用

### 操作步驟

```
1. 開啟 Character_Consistency.json
2. 在 IPAdapter Face 節點載入人物正臉參考照（建議正面、光線均勻）
3. 在 FaceID LoRA 節點確認 ip-adapter-faceid-plusv2_sdxl_lora 已載入
4. 可選：在 OpenPose 節點載入姿勢參考圖
5. 輸入場景描述（背景/服裝/光線）
6. 設定 IPAdapter 強度（0.65–0.80）
7. FaceDetailer 會在生成後自動精修臉部細節

注意：
  - 參考照片越清晰，一致性越好
  - 避免使用強化妝或遮擋的參考照
  - 若生成的人臉變形，嘗試降低 IPAdapter 強度至 0.6
```

---

## 十四、動物影片工作流

工作流檔案：`ComfyUI_Workflows/Video/Animal_Video.json`

### 適用場景

- 社群媒體動物短影音（IG Reels / TikTok）
- 品牌吉祥物動畫
- 動物紀錄片風格短片
- 寵物紀念影片

### 操作步驟

```
1. 開啟 Animal_Video.json
2. 載入動物靜態圖像（建議 1280×720 以上解析度）
3. 選擇 wan2.2_i2v_low_noise_14B_fp16 模型
4. 確認 wan_2.1_vae 和 umt5_xxl_fp16 已載入
5. 輸入動作描述提示詞（英文效果較好）
6. 設定幀數（81 = 約 5 秒，24fps）
7. 執行（約 8–15 分鐘）
8. 輸出為 MP4 或幀序列

動物影片提示詞範例：
「A majestic lion walking slowly through golden savanna grass, 
cinematic motion, gentle breeze, warm sunset lighting」

「A fluffy cat sitting on window sill, looking outside, 
tail swaying gently, soft natural light, realistic movement」

影片延長技巧：
  記錄最後一幀，作為下一段生成的參考圖，
  保持相同場景/光線的提示詞，實現流暢連續的長影片
```

---

## 十五、更新方式

### 更新自訂節點（建議每週）

```
方法 A（推薦）：
  1. 開啟 ComfyUI
  2. 點擊右上角 Manager 圖示
  3. 選擇「Update All」
  4. 等待完成後重啟 ComfyUI

方法 B（手動）：
  在 PowerShell 中：
  cd C:\ComfyUI\custom_nodes\[節點名稱]
  git pull
  pip install -r requirements.txt
```

### 更新 ComfyUI 主程式（建議每月）

```powershell
cd C:\ComfyUI
git pull
pip install -r requirements.txt
```

### 更新模型

重新執行模型下載腳本，選擇要更新的選單：

```powershell
cd C:\ComfyUI\ComfyUI-Workstation\install
.\03_download_models.ps1
```

---

## 十六、備份方式

### 必要備份項目

| 項目 | 重要度 | 備份頻率 | 方式 |
|------|--------|---------|------|
| `ComfyUI/user/` | 極高 | 每週 | 複製到外部磁碟或 NAS |
| `ComfyUI-Workstation/` 套件 | 高 | 安裝後一次 | 壓縮備份到雲端 |
| 重要生成圖像 | 依需求 | 即時 | 移到 NAS 或 Google Drive |
| 自訂 LoRA 模型 | 高 | 下載後 | 備份到外部磁碟 |

### 快速備份腳本

```powershell
# 建議儲存為 backup_comfyui.ps1，加入 Windows 工作排程器每週自動執行
$Date = Get-Date -Format "yyyyMMdd"
$Source = "C:\ComfyUI\user"
$Dest = "D:\Backup\ComfyUI_$Date"
Copy-Item -Recurse -Force $Source $Dest
Write-Host "備份完成：$Dest"
```

### 不需要備份（可重新生成/下載）

- `ComfyUI/models/` — 太大，保留下載腳本重新下載即可
- `ComfyUI/output/` — 暫存輸出，重要圖像請手動移出
- `ComfyUI/__pycache__/` — Python 快取，自動重建

---

## 十七、常見問題 FAQ

### Q1：安裝腳本執行時被 Windows Defender 阻擋怎麼辦？

```
解決方式：
1. 在 Windows Defender 設定中，將 ComfyUI-Workstation/install/ 資料夾加入排除清單
2. 或右鍵腳本檔案 → 內容 → 取消封鎖
3. 確認已以系統管理員執行 PowerShell
```

### Q2：ComfyUI 啟動後，介面上有紅色（Missing）節點？

```
原因：對應的自訂節點未安裝完成
解決方式：
1. 點擊右上角 Manager
2. 找到顯示「Not Installed」的節點
3. 點擊「Install」手動安裝
4. 重啟 ComfyUI
或：重新執行 02_install_custom_nodes.bat
```

### Q3：FLUX 模型下載失敗，顯示 401 或 403 錯誤？

```
原因：FLUX 模型為 gated，需要授權
解決方式：
1. 登入 HuggingFace：https://huggingface.co
2. 至 https://huggingface.co/black-forest-labs/FLUX.1-dev
3. 點擊「Request access」，填寫表單，等待審核（通常幾分鐘內自動審批）
4. 取得 HuggingFace Token：https://huggingface.co/settings/tokens
5. 在 PowerShell 設定：$env:HF_TOKEN = "hf_xxxxxxxxxxxxxxxx"
6. 重新執行 03_download_models.ps1 選擇選單 5
```

### Q4：執行 Wan2.2 工作流時顯示 CUDA out of memory？

```
RTX 4080 32GB 通常足以運行 Wan2.2 14B fp16（需約 28GB VRAM）
可能原因：
- 其他 GPU 程式佔用 VRAM（Chrome 開太多分頁、遊戲等）
- 同時載入了多個大型模型

解決方式：
1. 關閉其他使用 GPU 的程式
2. 重啟 ComfyUI（清空 GPU 記憶體）
3. 確認只載入必要的模型
4. 或改用 fp8 量化版 Wan2.2（約 14GB VRAM）
```

### Q5：FaceDetailer 節點找不到怎麼辦？

```
FaceDetailer 是 Impact Pack 的內建節點（不是獨立節點）
解決方式：
1. 確認 ComfyUI-Impact-Pack 已安裝
2. Impact Pack 需同時安裝 Impact-Subpack（依賴套件）
3. 在 Manager 搜尋 Impact Pack，確認版本為最新
4. 重啟 ComfyUI 後再搜尋「FaceDetailer」
```

### Q6：影片生成太慢，有什麼加速方法？

```
方法 1（最有效）：安裝 CausVid LoRA
  - 可將 Wan2.2 從 30 步降至 4–8 步，速度提升 5–8 倍
  - 下載：https://huggingface.co/jbilcke-hf/causalvideo-lora-wan

方法 2：安裝 SageAttention
  - FLUX 和 DiT 架構加速 30–50%
  - pip install sageattention

方法 3：降低解析度
  - 使用 720×480 代替 1280×720，速度快約 3–4 倍
  - 生成後用 RealESRGAN_x4plus 放大

方法 4：使用 fp8 量化版本
  - 約一半 VRAM 需求，品質損失約 5–8%
```

### Q7：如何製作 60 秒以上的 AI 影片？

```
Wan2.2 每次最多約 81 幀（5 秒，24fps），這是模型限制。

60 秒影片製作方式：
1. 分 12 段在 ComfyUI 中生成（每段 81 幀）
2. 用 Frame-Interpolation（RIFE）從 24fps 補幀到 60fps（每段 202 幀）
3. 在 DaVinci Resolve 或 Premiere Pro 中串接 12 段影片
4. 加入音樂、轉場、字幕完成最終影片

技巧：
  - 每段的結尾幀作為下一段的起始幀，確保場景連續
  - 使用相似的提示詞維持整體風格一致性
  - 適當加入轉場效果可遮蓋段落接縫
```

### Q8：為什麼建議使用 `low_noise` 版本的 Wan2.2 模型？

```
Wan2.2 提供 high_noise 和 low_noise 兩個版本：

low_noise（推薦）：
  - 輸入圖像的細節保留較好
  - 運動較為平滑自然
  - 適合寫實動物/人物影片

high_noise：
  - 動感較強、創意度較高
  - 場景變化更大
  - 適合需要較大動態幅度的影片

若不確定，從 low_noise 開始。
```

### Q9：ControlNet 強度設太高會怎樣？

```
強度過高的問題：
  - Canny/LineArt 過高（> 0.9）：圖像會完全貼合線稿，失去 AI 生成的自然感
  - Depth 過高（> 0.95）：空間感過強但細節缺失
  - OpenPose 過高（> 0.95）：姿勢正確但人物表情/外觀失真

建議做法：
  - 從 0.65 開始，預覽結果後微調
  - 使用 Advanced-ControlNet 節點可設定「起始步驟」和「結束步驟」
    （例如：前 30% 步驟不套用 ControlNet，讓初始構圖更自然）
```

### Q10：工作流讀取失敗或節點版本不符？

```
可能原因：
  - 工作流使用的節點版本比已安裝的新或舊
  - 節點 API 有所變更

解決方式：
1. Manager → Update All（更新所有節點到最新版）
2. 重啟 ComfyUI
3. 重新載入工作流

若仍有問題：
  - 在 ComfyUI Manager 中搜尋報錯的節點，確認已安裝最新版本
  - 或手動編輯工作流 JSON 修改節點 class_type 為新版本名稱
```

---

## 後續升級建議

詳細升級建議請參閱：[REPORTS/05_upgrade_recommendations.md](REPORTS/05_upgrade_recommendations.md)

重點建議摘要：
- 安裝 **SageAttention** 加速 FLUX 推理 30–50%
- 下載 **CausVid LoRA** 加速影片生成 5–8 倍
- 將 `models/` 放在 **NVMe PCIe 4.0 SSD** 縮短模型載入時間
- 關注 **FLUX Kontext v2** 和 **Wan3.0** 的發布

---

## 完整文件索引

| 文件 | 內容 |
|------|------|
| [docs/01_installation.md](docs/01_installation.md) | 詳細安裝教學 |
| [docs/02_controlnet_guide.md](docs/02_controlnet_guide.md) | ControlNet 進階教學 |
| [docs/03_ipadapter_guide.md](docs/03_ipadapter_guide.md) | IPAdapter 進階教學 |
| [docs/04_flux_guide.md](docs/04_flux_guide.md) | FLUX 模型進階教學 |
| [docs/05_wan_video_guide.md](docs/05_wan_video_guide.md) | Wan2.2 影片生成進階教學 |
| [docs/06_troubleshooting.md](docs/06_troubleshooting.md) | 完整排錯指南 |
| [REPORTS/01_install_report.md](REPORTS/01_install_report.md) | 安裝報告與驗證清單 |
| [REPORTS/02_model_list.md](REPORTS/02_model_list.md) | 完整模型清單 |
| [REPORTS/03_workflow_list.md](REPORTS/03_workflow_list.md) | 工作流清單與參數 |
| [REPORTS/04_folder_structure.md](REPORTS/04_folder_structure.md) | 資料夾結構說明 |
| [REPORTS/05_upgrade_recommendations.md](REPORTS/05_upgrade_recommendations.md) | 後續升級建議 |

---

*ComfyUI 工作站 v2.0 | 產生於 2026-06-10 | 適用硬體：RTX 4080 32GB / i5-13500 / 96GB RAM / Windows 11*
