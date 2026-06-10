# ComfyUI 工作站 — 完整模型清單

> 版本：v2.0 | 產生日期：2026-06-10
> 模型路徑以 `ComfyUI/models/` 為根目錄

---

## 說明

- **Gated**：需 HuggingFace 帳號並申請授權才可下載
- **API Only**：無公開權重，僅能透過付費 API 使用
- **大小估計**：為磁碟佔用近似值，實際依精度格式而定
- **下載選單**：對應 `install/03_download_models.ps1` 的互動選單編號

---

## 選單 1：ControlNet SD1.5 模型

> 放置資料夾：`models/controlnet/`

| 檔名 | 放置資料夾 | 用途 | 大小估計 | 下載選單 | Gated |
|------|-----------|------|----------|----------|-------|
| `control_v11p_sd15_canny_fp16.safetensors` | `controlnet/` | Canny 邊緣偵測控制（建築線稿、輪廓） | ~760 MB | 選單 1 | 否 |
| `control_v11f1p_sd15_depth_fp16.safetensors` | `controlnet/` | 深度圖控制（室內空間結構、前後景） | ~760 MB | 選單 1 | 否 |
| `control_v11p_sd15_openpose_fp16.safetensors` | `controlnet/` | 人體姿勢控制（人物動作、肢體一致性） | ~760 MB | 選單 1 | 否 |
| `control_v11p_sd15_lineart_fp16.safetensors` | `controlnet/` | 線條藝術控制（CAD 線稿轉渲染） | ~760 MB | 選單 1 | 否 |
| `control_v11p_sd15_softedge_fp16.safetensors` | `controlnet/` | 柔和邊緣控制（商品輪廓保留） | ~760 MB | 選單 1 | 否 |
| `control_v11p_sd15_seg_fp16.safetensors` | `controlnet/` | 語義分割控制（室內區域色彩佈局） | ~760 MB | 選單 1 | 否 |

**選單 1 小計：約 4.5 GB（fp16 版本）**

---

## 選單 2：ControlNet Union 模型

> 適用 SDXL 與 FLUX 架構的統一 ControlNet

| 檔名 | 放置資料夾 | 用途 | 大小估計 | 下載選單 | Gated |
|------|-----------|------|----------|----------|-------|
| `controlnet_union_sdxl_promax.safetensors` | `controlnet/` | SDXL 統一 ControlNet（支援 Canny/Depth/OpenPose/LineArt/SoftEdge/Seg 多模式） | ~2.5 GB | 選單 2 | 否 |
| `flux_controlnet_union_pro_2.safetensors` | `controlnet/` | FLUX 專用統一 ControlNet（支援多種控制模式，建築/室內 FLUX 工作流核心） | ~2.5 GB | 選單 2 | 否 |

**選單 2 小計：約 5 GB**

---

## 選單 3：IPAdapter 模型

> 圖像提示適配器，實現人物/商品圖像一致性

| 檔名 | 放置資料夾 | 用途 | 大小估計 | 下載選單 | Gated |
|------|-----------|------|----------|----------|-------|
| `ip-adapter-plus-face_sd15.safetensors` | `ipadapter/` | SD1.5 人臉 IPAdapter（人物一致性，高精度臉部特徵保留） | ~570 MB | 選單 3 | 否 |
| `ip-adapter-plus_sdxl_vit-h.safetensors` | `ipadapter/` | SDXL 通用 IPAdapter（商品/風格圖像參考） | ~1.1 GB | 選單 3 | 否 |
| `ip-adapter-faceid-plusv2_sdxl.bin` | `ipadapter/` | SDXL FaceID Plus v2（人物臉部 ID 一致性，搭配 FaceID LoRA） | ~570 MB | 選單 3 | 否 |
| `ip-adapter-faceid-plusv2_sdxl_lora.safetensors` | `loras/` | SDXL FaceID Plus v2 配套 LoRA（需與 FaceID bin 搭配使用） | ~280 MB | 選單 3 | 否 |
| `CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors` | `clip_vision/` | CLIP ViT-H 視覺編碼器（SD1.5 IPAdapter 配套） | ~2.4 GB | 選單 3 | 否 |
| `CLIP-ViT-bigG-14-laion2B-39B-b160k.safetensors` | `clip_vision/` | CLIP ViT-bigG 視覺編碼器（SDXL IPAdapter 配套） | ~3.7 GB | 選單 3 | 否 |

**選單 3 小計：約 8.6 GB**

---

## 選單 4：SDXL Checkpoints

> 高品質靜態圖像生成主模型

| 檔名 | 放置資料夾 | 用途 | 大小估計 | 下載選單 | Gated |
|------|-----------|------|----------|----------|-------|
| `RealVisXL_V5.0_fp16.safetensors` | `checkpoints/` | 超寫實風格 SDXL（建築渲染、室內、人物、商品，fp16 版本） | ~6.9 GB | 選單 4 | 否 |
| `Juggernaut-XL_v9_RunDiffusionPhoto_v2.safetensors` | `checkpoints/` | 人像攝影風格 SDXL（人物一致性、商品廣告，v9 版本） | ~6.9 GB | 選單 4 | 否 |

**選單 4 小計：約 13.8 GB**

---

## 選單 5：FLUX 模型（需 HuggingFace Gated 授權）

> 最高品質文字理解與結構生成，需申請存取授權

| 檔名 | 放置資料夾 | 用途 | 大小估計 | 下載選單 | Gated |
|------|-----------|------|----------|----------|-------|
| `flux1-dev.safetensors` | `diffusion_models/` | FLUX.1-dev 主模型（高品質圖像生成主幹） | ~23.8 GB | 選單 5 | **是** |
| `flux1-kontext-dev.safetensors` | `diffusion_models/` | FLUX Kontext Dev（圖像編輯、局部修改、風格遷移） | ~23.8 GB | 選單 5 | **是** |
| `t5xxl_fp16.safetensors` | `clip/` | T5-XXL 文字編碼器 fp16（FLUX 的語義理解核心） | ~9.2 GB | 選單 5 | **是** |
| `clip_l.safetensors` | `clip/` | CLIP-L 文字編碼器（FLUX 配套，負責短提示詞） | ~246 MB | 選單 5 | **是** |
| `flux_ae.safetensors` | `vae/` | FLUX 專用 VAE（圖像編碼/解碼） | ~335 MB | 選單 5 | **是** |
| `flux1-kontext-pro` | N/A | **API Only — 無公開權重**，需透過 BFL API 付費使用 | N/A | 無 | API |

> **注意：** 選單 5 全部模型均為 gated。下載前請：
> 1. 至 https://huggingface.co/black-forest-labs 接受各模型授權
> 2. 設定 HuggingFace Token：`$env:HF_TOKEN = "hf_xxxxxxxxxxxxxxxx"`

**選單 5 小計：約 57 GB（不含 kontext-pro）**

---

## 選單 6：Wan2.2 影片模型

> 目前最強開源 AI 影片生成模型

| 檔名 | 放置資料夾 | 用途 | 大小估計 | 下載選單 | Gated |
|------|-----------|------|----------|----------|-------|
| `wan2.2_i2v_high_noise_14B_fp16.safetensors` | `diffusion_models/` | Wan2.2 圖生影片（高雜訊版，動感較強） | ~28 GB | 選單 6 | 否 |
| `wan2.2_i2v_low_noise_14B_fp16.safetensors` | `diffusion_models/` | Wan2.2 圖生影片（低雜訊版，細節保留較佳，建議首選） | ~28 GB | 選單 6 | 否 |
| `wan2.2_t2v_high_noise_14B_fp16.safetensors` | `diffusion_models/` | Wan2.2 文生影片（高雜訊版） | ~28 GB | 選單 6 | 否 |
| `wan2.2_t2v_low_noise_14B_fp16.safetensors` | `diffusion_models/` | Wan2.2 文生影片（低雜訊版，建議首選） | ~28 GB | 選單 6 | 否 |
| `umt5_xxl_fp16.safetensors` | `clip/` | UMT5-XXL 多語言文字編碼器（Wan2.2 配套） | ~9.2 GB | 選單 6 | 否 |
| `wan_2.1_vae.safetensors` | `vae/` | Wan 2.1 VAE（Wan2.2 影片 VAE，向後相容） | ~430 MB | 選單 6 | 否 |

> **磁碟空間警告：** 若下載全部 4 個 Wan2.2 主模型需約 112 GB。
> 建議初期只下載 `i2v_low_noise` 與 `t2v_low_noise` 兩個（約 56 GB）。

**選單 6 小計（全選）：約 121 GB / 建議最小集合：約 61 GB**

---

## 選單 7：其他影片模型

| 檔名 | 放置資料夾 | 用途 | 大小估計 | 下載選單 | Gated |
|------|-----------|------|----------|----------|-------|
| `mm_sd_v15_v2.ckpt` | `animatediff_models/` | AnimateDiff v2 動態模組（SD1.5 動畫序列） | ~1.7 GB | 選單 7 | 否 |
| `ltxv-13b-0.9.7-distilled.safetensors` | `checkpoints/` | LTX-Video 13B（快速影片生成，低 VRAM 需求，適合快速預覽） | ~26 GB | 選單 7 | 否 |
| `hunyuan_video_t2v_720p_bf16.safetensors` | `diffusion_models/` | HunyuanVideo 720p（騰訊高品質文生影片） | ~38 GB | 選單 7 | 否 |
| HunyuanVideo VAE | `vae/` | HunyuanVideo 專用 VAE | ~1.5 GB | 選單 7 | 否 |
| HunyuanVideo Text Encoders | `clip/` | HunyuanVideo 文字編碼器（CLIP + LLaVA） | ~8 GB | 選單 7 | 否 |

**選單 7 小計：約 75 GB**

---

## 選單 8：放大模型

> 超解析度放大，將 512/1024px 輸出放大至 2K/4K

| 檔名 | 放置資料夾 | 用途 | 大小估計 | 下載選單 | Gated |
|------|-----------|------|----------|----------|-------|
| `4x-UltraSharp.pth` | `upscale_models/` | 4x 超銳利化放大（建築細節、材質紋理最佳選擇） | ~67 MB | 選單 8 | 否 |
| `4x_foolhardy_Remacri.pth` | `upscale_models/` | 4x 真實感放大（人像、風景、室內寫實場景） | ~67 MB | 選單 8 | 否 |
| `RealESRGAN_x4plus.pth` | `upscale_models/` | 4x RealESRGAN（通用放大，影片幀放大首選） | ~67 MB | 選單 8 | 否 |

**選單 8 小計：約 200 MB**

---

## 模型空間需求彙總

| 選單 | 類別 | 最小必要 | 完整下載 |
|------|------|----------|----------|
| 選單 1 | ControlNet SD1.5 | ~4.5 GB | ~4.5 GB |
| 選單 2 | ControlNet Union | ~5 GB | ~5 GB |
| 選單 3 | IPAdapter | ~8.6 GB | ~8.6 GB |
| 選單 4 | SDXL Checkpoints | ~7 GB（擇一） | ~14 GB |
| 選單 5 | FLUX（gated） | ~34 GB（dev + encoders） | ~57 GB |
| 選單 6 | Wan2.2 | ~61 GB（low_noise 兩個） | ~121 GB |
| 選單 7 | 其他影片 | ~1.7 GB（只 AnimateDiff） | ~75 GB |
| 選單 8 | 放大模型 | ~0.2 GB | ~0.2 GB |
| **合計** | | **~122 GB（最小建議）** | **~285 GB** |

> **建議最低配置**（滿足所有工作流）：選單 1+2+3+4+5+8 ≈ 80 GB
> **建議完整配置**（含影片功能）：選單 1+2+3+4+5+6+8 ≈ 200 GB

---

*本清單由 ComfyUI 工作站部署套件產生。模型大小為估算值，實際請以下載後的磁碟用量為準。*
