# 本地生成「1080p · 60fps · 6×20 秒接續」影片 — ComfyUI 工作流

**目標規格**：6 段、每段 20 秒、彼此接續的影片，最終輸出 **1920×1080 @ 60fps**。
**目標硬體**：Windows + NVIDIA 獨顯 + **24GB VRAM**（如 RTX 3090 / 4090 等級）。

---

## 0. 工程現實（先讀，避免誤會）

- 本地文生影片模型一次原生只生 **約 5 秒** → 每段「20 秒」= **4 個 5 秒小片段**接成；6 段 = **24 個 5 秒小片段**。
- 模型原生多為 **24fps** → 用 **RIFE 插幀** 補到 **60fps**（24→60 約 2.5×）。
- 「接續」靠 **image-to-video**：把前一段的**最後一格**當作下一段的**起始圖**，畫面就連得起來。
- 1080p 在 24GB 屬上限：策略是 **720p 生成 → 放大到 1080p**，比直接生 1080p 穩、快、省顯存。

---

## 1. 安裝（PowerShell，依序貼上執行）

### 1-1 ComfyUI（可攜版，最省事）
到 <https://github.com/comfyanonymous/ComfyUI/releases> 下載 **ComfyUI Windows Portable**，解壓到例如 `D:\ComfyUI_windows_portable`。

### 1-2 ComfyUI-Manager（用來一鍵裝缺的節點）
```powershell
cd D:\ComfyUI_windows_portable\ComfyUI\custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git
```

### 1-3 本工作流需要的自訂節點
```powershell
# 影片輸出（VideoCombine、LoadVideo、抽最後一格等）
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
# 插幀（RIFE）→ 24fps 補到 60fps
git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git
# 放大（720p → 1080p）
git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git
```
> 裝完重啟 ComfyUI。若啟動時提示缺套件，開 ComfyUI-Manager → **Install Missing Custom Nodes** 補齊。

### 1-4 模型下載（放到對應資料夾）
建議用 **Wan 2.2 TI2V-5B**：單一模型、原生 720p、24GB 跑起來輕鬆又快，且同時支援文生影片(T2V)與圖生影片(I2V)。

| 檔案 | 放到資料夾 | 來源 |
|------|-----------|------|
| `wan2.2_ti2v_5B_fp16.safetensors`（或 fp8 量化版更省） | `models/diffusion_models/` | Comfy-Org / Wan-AI 官方 repo（HuggingFace） |
| `wan2.2_vae.safetensors` | `models/vae/` | 同上 |
| `umt5_xxl_fp8_e4m3fn_scaled.safetensors` | `models/text_encoders/` | 同上 |
| `rife49.pth`（RIFE 權重，首次用會自動下載） | 自動 | Frame-Interpolation 節點自帶 |

HuggingFace 搜尋：`Comfy-Org/Wan_2.2_ComfyUI_Repackaged`（已打包好對應 ComfyUI 的檔名）。

---

## 2. 取得「保證能載入」的基底工作流

不要手貼來路不明的 JSON。打開 ComfyUI 後：

**頂部選單 → Workflow → Browse Templates → Video → 選「Wan 2.2 5B / TI2V」**

這會載入官方、與你版本相符、**保證能跑**的基底圖（含 UNETLoader / CLIPLoader / VAELoader / CLIPTextEncode×2 / 取樣器 / VAEDecode）。我們在它後面接 3 個節點即可。

---

## 3. 在基底範本後面加這 3 個節點（核心工作流）

基底範本的輸出是 `VAEDecode → IMAGE`。把它接成下面這條鏈：

```
[基底範本]
   └─ VAEDecode (IMAGE)
        │
        ├─►  ① Upscale Image (by model 或 Lanczos)   → 1920×1080
        │         width=1920  height=1080
        │
        └─►  ② RIFE VFI  (ComfyUI-Frame-Interpolation)
                  ckpt_name = rife49.pth
                  multiplier = 2 或 3   （24fps×2.5≈60；先 ×2=48 或 ×3=72 再於③設 60）
                  │
                  └─►  ③ Video Combine (VideoHelperSuite)
                            frame_rate = 60
                            format = video/h264-mp4
                            pix_fmt = yuv420p
                            crf = 18  （越小畫質越好、檔越大）
                            save_output = true
```

### 節點連法摘要
| 來源節點 / 輸出 | 目標節點 / 輸入 |
|----------------|----------------|
| `VAEDecode` IMAGE | `Upscale Image` image |
| `Upscale Image` IMAGE | `RIFE VFI` frames |
| `RIFE VFI` IMAGE | `Video Combine` images |

> 順序很重要：**先放大、再插幀、最後合成**。插幀放在放大之後，動態最順。

---

## 4. 每段 20 秒 / 接續的設定（重點）

### 4-1 一次生 5 秒
在基底範本的「latent 長度 / length」設成 **81 格**（= 24fps × ~3.4s 的常見值）或模型支援的 **121 格 ≈ 5 秒**。
- `length = 121`（5 秒 @24fps），`width=1280`、`height=704`（16:9，720p 檔位）。

### 4-2 「接續」做法（手動鏈接，最可靠）
這是讓 6 段連起來的關鍵。用 **image-to-video**：

1. **第 1 個 5 秒片段**：在基底範本用 `LoadImage` 放你的「起始畫面圖」（或純文生不放圖）。生成 → 用 VideoHelperSuite 的 **「Split / Select Last Image」**（或 `VHS_VideoCombine` 旁的取格節點）抽出**最後一格**存成 PNG。
2. **第 2 個 5 秒片段**：把上一步的**最後一格 PNG** 放進 `LoadImage` 當起始圖，改 prompt 為下一個鏡頭內容 → 生成 → 再抽最後一格。
3. 重複到第 24 個片段。

> 每段 20 秒 = 連做 4 次（4×5s），每 4 個片段就是「一段」。6 段共 24 次。每次只換兩樣東西：**起始圖（上一段最後一格）** 和 **prompt**。

### 4-3 最後把 6 段接起來
全部 24 個 5 秒片段（已各自插幀到 60fps）丟進剪輯軟體（剪映 / DaVinci Resolve 免費版）依序拼接，或用 `ffmpeg`：
```powershell
# 先把每個片段路徑寫進 list.txt：每行 file 'D:/clips/clip01.mp4'
ffmpeg -f concat -safe 0 -i list.txt -c copy final_1080p60.mp4
```

---

## 5. 24GB 的建議參數

| 參數 | 建議值 | 說明 |
|------|--------|------|
| 生成解析度 | 1280×704 (720p) | 再放大到 1080p，省顯存最穩 |
| length（每片段） | 121 格 ≈ 5 秒 | |
| KSampler steps | 20–30 | TI2V-5B 20 步已不錯 |
| cfg | 5–6 | |
| sampler / scheduler | `uni_pc` 或 `dpmpp_2m` / `simple` | |
| 權重精度 | fp8（省顯存）或 fp16（畫質略好） | 24GB fp16 也跑得動 |
| RIFE multiplier | 3（72fps）→ Video Combine 設 60 | 也可 ×2 設 48 換 60 |

**速度概念**：720p 5 秒約數十秒~數分鐘/片段（依步數）。24 個片段＋插幀，整支 2 分鐘成品預估 **1~3 小時** 算圖時間。

---

## 6. （可選）做成「數字人口播」

若這支是要有人講話的數字人：
1. 先用上面流程或一張人像照產出「底片 / 人像」。
2. 安裝 **MuseTalk**（高品質對嘴，24GB 飛快）或 ComfyUI 的對嘴節點。
3. 餵入「底片 + 你的語音音檔」→ 產生對嘴影片（長度由音訊決定，**不受 5 秒限制**）。
4. 一樣用 RIFE 插幀到 60fps、輸出 1080p。

口播路線比純文生動畫單純很多，且本地品質可逼近商業產品。

---

## 7. 和 Higgsfield / Gemini Omni 的差距

- **數字人口播**：本地（你的 24GB）可做到**幾乎一樣好**。
- **電影級文生動畫**：本地很不錯，但他們在「超穩定運鏡＋一鍵 4K」略勝（用 80GB 企業卡叢集）。你的差距主要在**解析度上限與算圖速度**，不是畫質本身。

---

### 一句話總結
**官方 Wan 2.2 範本（保證可載入）＋ 放大→RIFE→VideoCombine 三節點 ＝ 1080p60 工作流；用 image-to-video 把每段最後一格餵下一段，就能做出 6×20 秒的接續影片。**
