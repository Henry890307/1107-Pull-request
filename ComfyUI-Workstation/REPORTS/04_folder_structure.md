# ComfyUI 工作站 — 完整資料夾結構

> 版本：v2.0 | 產生日期：2026-06-10

---

## 一、部署套件結構（ComfyUI-Workstation/）

```
ComfyUI-Workstation/
│
├── install/                          # 安裝腳本目錄（核心）
│   ├── 01_check_environment.ps1      # 環境前置檢查（Python/Git/CUDA/VRAM/磁碟）
│   ├── 02_install_custom_nodes.bat   # 22 個自訂節點批次 git clone + pip install
│   ├── 03_download_models.ps1        # 互動式模型下載（8 個分類選單）
│   ├── 04_create_folders.bat         # 建立 ComfyUI models/ 完整子目錄
│   ├── install_all.bat               # 一鍵執行全流程主入口
│   └── generate_workflows.py         # 產生並寫入 7 個工作流 JSON
│
├── ComfyUI_Workflows/                # 工作流 JSON 與說明文件
│   ├── Architecture/
│   │   ├── Architecture_Pro.json     # CAD 轉建築渲染（LineArt+FLUX ControlNet+Kontext+放大）
│   │   └── README.md                 # 建築工作流操作說明
│   ├── Interior/
│   │   ├── Interior_Design_Pro.json  # SketchUp 轉室內渲染（雙 ControlNet+FLUX Kontext）
│   │   └── README.md                 # 室內工作流操作說明
│   ├── Character/
│   │   ├── Character_Consistency.json # 人物一致性（IPAdapter Face+OpenPose+FaceDetailer）
│   │   └── README.md                 # 人物工作流操作說明
│   ├── Product/
│   │   ├── Product_Advertising.json  # 商品廣告（IPAdapter+SoftEdge+FLUX Kontext+放大）
│   │   └── README.md                 # 商品工作流操作說明
│   ├── Video/
│   │   ├── Animal_Video.json         # AI 動物影片（Wan2.2 I2V）
│   │   ├── Human_Video.json          # AI 人物影片（Wan2.2 I2V）
│   │   └── README.md                 # 影片工作流操作說明
│   ├── Church/
│   │   ├── Church_Design.json        # 教會海報（FLUX Kontext+ControlNet，多尺寸）
│   │   └── README.md                 # 教會設計工作流說明
│   └── Templates/
│       └── README.md                 # 自訂工作流模板說明
│
├── docs/                             # 完整操作文件
│   ├── 01_installation.md            # 詳細安裝教學
│   ├── 02_controlnet_guide.md        # ControlNet 使用教學（SD1.5/SDXL/FLUX）
│   ├── 03_ipadapter_guide.md         # IPAdapter 使用教學（人物/商品一致性）
│   ├── 04_flux_guide.md              # FLUX 模型使用教學（dev/Kontext）
│   ├── 05_wan_video_guide.md         # Wan2.2 影片生成教學（分段生成說明）
│   └── 06_troubleshooting.md         # 常見問題排除指南
│
├── REPORTS/                          # 報告文件（本目錄）
│   ├── 01_install_report.md          # 安裝完成報告（套件性質說明+驗證清單）
│   ├── 02_model_list.md              # 完整模型清單（類別/路徑/用途/大小）
│   ├── 03_workflow_list.md           # 工作流清單（參數/VRAM/速度）
│   ├── 04_folder_structure.md        # 本檔案（資料夾結構說明）
│   └── 05_upgrade_recommendations.md # 後續升級建議
│
└── README.md                         # 主說明文件（安裝、用途、快速開始）
```

---

## 二、ComfyUI 主程式結構（C:\ComfyUI\）

```
C:\ComfyUI\                           # ComfyUI 主程式根目錄
│
├── main.py                           # ComfyUI 主程式進入點
├── requirements.txt                  # Python 套件需求
│
├── custom_nodes/                     # 自訂節點安裝目錄（22 個節點）
│   ├── ComfyUI-Manager/              # 節點管理中心
│   ├── ComfyUI-Impact-Pack/          # Impact Pack（含 FaceDetailer/偵測器）
│   │   └── ComfyUI-Impact-Subpack/   # Impact Subpack（內嵌子套件）
│   ├── comfyui_essentials/           # 基礎工具集
│   ├── ComfyUI-Inspire-Pack/         # 進階採樣與區域提示
│   ├── ComfyUI-Easy-Use/             # 簡化工作流節點
│   ├── ComfyUI-Custom-Scripts/       # 自訂腳本支援
│   ├── ComfyUI-Advanced-ControlNet/  # 進階 ControlNet 時序控制
│   ├── comfyui_controlnet_aux/       # ControlNet 前處理器
│   ├── ComfyUI_IPAdapter_plus/       # IPAdapter 圖像提示適配器
│   ├── UltimateSDUpscale/            # 分區高解析度放大
│   ├── ComfyUI-VideoHelperSuite/     # 影片輸入輸出處理
│   ├── ComfyUI-KJNodes/              # 實用工具節點
│   ├── ComfyUI-AnimateDiff-Evolved/  # SD 模型動畫序列生成
│   ├── crystools/                    # 資源監控（VRAM/RAM/CPU）
│   ├── efficiency-nodes-comfyui/     # 效率節點
│   ├── ComfyUI_LayerStyle/           # 圖層風格效果
│   ├── rgthree-comfy/                # 工作流組織工具
│   ├── was-node-suite-comfyui/       # WAS 工具節點集
│   ├── FizzNodes/                    # 動畫數值排程
│   ├── ReActor/                      # 人臉替換節點
│   ├── ComfyUI-WanVideoWrapper/      # Wan2.2 影片生成包裝器
│   └── ComfyUI-Frame-Interpolation/  # 影格插值補幀（RIFE/FILM）
│
├── models/                           # 模型存放根目錄（詳見第三節）
│
├── input/                            # 輸入圖像目錄
│   ├── architecture/                 # 建築線稿/截圖
│   ├── interior/                     # SketchUp 截圖/室內參考圖
│   ├── character/                    # 人物參考照片
│   ├── product/                      # 商品照片（白底/去背）
│   └── video/                        # 影片輸入幀/參考圖
│
├── output/                           # 生成結果輸出目錄
│   ├── architecture/                 # 建築渲染輸出
│   ├── interior/                     # 室內渲染輸出
│   ├── character/                    # 人物生成輸出
│   ├── product/                      # 商品廣告輸出
│   ├── video/                        # 影片輸出（MP4/幀序列）
│   └── church/                       # 教會設計輸出
│
└── user/
    └── default/
        └── workflows/                # 工作流 JSON 儲存目錄
            ├── Architecture_Pro.json
            ├── Interior_Design_Pro.json
            ├── Character_Consistency.json
            ├── Product_Advertising.json
            ├── Animal_Video.json
            ├── Human_Video.json
            └── Church_Design.json
```

---

## 三、ComfyUI 模型目錄結構（C:\ComfyUI\models\）

```
C:\ComfyUI\models\
│
├── checkpoints/                      # 主模型 Checkpoint（SDXL/LTX-Video）
│   ├── RealVisXL_V5.0_fp16.safetensors
│   ├── Juggernaut-XL_v9_RunDiffusionPhoto_v2.safetensors
│   └── ltxv-13b-0.9.7-distilled.safetensors
│
├── diffusion_models/                 # 擴散模型（FLUX/Wan2.2/HunyuanVideo）
│   ├── flux1-dev.safetensors         # FLUX.1-dev 主模型
│   ├── flux1-kontext-dev.safetensors # FLUX Kontext Dev（圖像編輯）
│   ├── wan2.2_i2v_high_noise_14B_fp16.safetensors
│   ├── wan2.2_i2v_low_noise_14B_fp16.safetensors   # 推薦：圖生影片
│   ├── wan2.2_t2v_high_noise_14B_fp16.safetensors
│   ├── wan2.2_t2v_low_noise_14B_fp16.safetensors   # 推薦：文生影片
│   └── hunyuan_video_t2v_720p_bf16.safetensors
│
├── clip/                             # 文字/視覺編碼器
│   ├── t5xxl_fp16.safetensors        # T5-XXL（FLUX 語義理解）
│   ├── clip_l.safetensors            # CLIP-L（FLUX 短提示詞）
│   └── umt5_xxl_fp16.safetensors    # UMT5-XXL（Wan2.2 多語言）
│
├── clip_vision/                      # CLIP 視覺編碼器（IPAdapter 配套）
│   ├── CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors  # SD1.5 IPAdapter 用
│   └── CLIP-ViT-bigG-14-laion2B-39B-b160k.safetensors # SDXL IPAdapter 用
│
├── vae/                              # VAE 模型
│   ├── flux_ae.safetensors           # FLUX 專用 VAE
│   └── wan_2.1_vae.safetensors       # Wan 2.1/2.2 影片 VAE
│
├── controlnet/                       # ControlNet 控制模型
│   ├── control_v11p_sd15_canny_fp16.safetensors
│   ├── control_v11f1p_sd15_depth_fp16.safetensors
│   ├── control_v11p_sd15_openpose_fp16.safetensors
│   ├── control_v11p_sd15_lineart_fp16.safetensors
│   ├── control_v11p_sd15_softedge_fp16.safetensors
│   ├── control_v11p_sd15_seg_fp16.safetensors
│   ├── controlnet_union_sdxl_promax.safetensors     # SDXL 統一 ControlNet
│   └── flux_controlnet_union_pro_2.safetensors      # FLUX 統一 ControlNet
│
├── ipadapter/                        # IPAdapter 模型
│   ├── ip-adapter-plus-face_sd15.safetensors
│   ├── ip-adapter-plus_sdxl_vit-h.safetensors
│   └── ip-adapter-faceid-plusv2_sdxl.bin
│
├── loras/                            # LoRA 微調模型
│   └── ip-adapter-faceid-plusv2_sdxl_lora.safetensors
│
├── upscale_models/                   # 超解析度放大模型
│   ├── 4x-UltraSharp.pth             # 建築/材質細節放大首選
│   ├── 4x_foolhardy_Remacri.pth      # 人像/寫實場景放大
│   └── RealESRGAN_x4plus.pth         # 通用放大（影片幀適用）
│
├── animatediff_models/               # AnimateDiff 動態模組
│   └── mm_sd_v15_v2.ckpt             # AnimateDiff v2 SD1.5 動態模組
│
├── insightface/                      # InsightFace 人臉分析（ReActor/FaceDetailer 用）
│   └── models/
│       └── buffalo_l/                # Buffalo_L 人臉偵測模型（自動下載）
│
└── ultralytics/                      # YOLO 偵測模型（Impact Pack 用）
    └── bbox/                         # 邊界框偵測（FaceDetailer 人臉偵測）
        └── face_yolov8m.pt           # YOLOv8 人臉偵測（自動下載）
```

---

## 四、資料夾說明索引

| 資料夾 | 用途 | 放什麼 |
|--------|------|--------|
| `install/` | 部署套件腳本 | PS1/BAT/PY 安裝腳本 |
| `ComfyUI_Workflows/` | 工作流定義 | JSON 工作流 + README |
| `docs/` | 操作文件 | Markdown 教學文件 |
| `REPORTS/` | 報告文件 | 安裝報告、清單、建議 |
| `custom_nodes/` | 擴充節點 | 22 個自訂節點目錄 |
| `models/checkpoints/` | 傳統主模型 | SDXL .safetensors |
| `models/diffusion_models/` | 新架構模型 | FLUX/Wan2.2/HunyuanVideo |
| `models/clip/` | 文字編碼器 | T5-XXL/CLIP/UMT5 |
| `models/clip_vision/` | 視覺編碼器 | CLIP-ViT（IPAdapter 配套） |
| `models/vae/` | 圖像編解碼 | 各架構專用 VAE |
| `models/controlnet/` | 結構控制模型 | SD1.5/SDXL/FLUX ControlNet |
| `models/ipadapter/` | 圖像適配器 | IPAdapter 模型 |
| `models/loras/` | 微調模型 | FaceID LoRA、風格 LoRA |
| `models/upscale_models/` | 放大模型 | .pth 超解析度模型 |
| `models/animatediff_models/` | AnimateDiff | SD1.5 動態模組 |
| `models/insightface/` | 人臉分析 | ReActor/FaceDetailer 依賴 |
| `models/ultralytics/` | 物件偵測 | Impact Pack YOLO 偵測器 |
| `input/` | 使用者輸入圖 | 參考圖/線稿/商品照 |
| `output/` | 生成結果 | 輸出圖像/影片（依類別） |
| `user/default/workflows/` | ComfyUI 工作流 | 工作流 JSON（ComfyUI 讀取） |

---

## 五、磁碟空間規劃建議

| 目錄 | 預估大小 | 建議磁碟 |
|------|----------|----------|
| `ComfyUI/` 主程式 + custom_nodes | ~5–10 GB | 任何磁碟 |
| `models/` 最小建議集合 | ~80–120 GB | **建議 NVMe SSD**（讀取速度影響載入時間） |
| `models/` 完整配置（含 Wan2.2 全套） | ~200–285 GB | 建議 1TB+ NVMe |
| `output/` 生成結果累積 | 視使用量 | 可放較慢的 HDD |

> **強烈建議**將 `models/` 放在 NVMe SSD（讀取速度 > 3000 MB/s），FLUX 14B 以上模型載入時間從 HDD 的 3–5 分鐘縮短為 NVMe 的 30–60 秒。

---

*本文件由 ComfyUI 工作站部署套件產生。資料夾結構在 `04_create_folders.bat` 執行後自動建立。*
