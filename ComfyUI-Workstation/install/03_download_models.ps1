<#
================================================================
 03_download_models.ps1
 ComfyUI 工作站 - 第三階段：模型下載
================================================================
 特性：
   - 使用 huggingface-cli（斷點續傳、穩定）下載，curl 為備援
   - 分類選單：可只下載你需要的類別（全部約 200-300GB）
   - 自動放到 ComfyUI 正確子資料夾
   - 針對特規 RTX 4080 32GB：FLUX/Wan 預設抓 fp16 完整版（VRAM 夠）
     若想省空間/更快，腳本內也標註了 fp8 版檔名

 用法：
   powershell -ExecutionPolicy Bypass -File 03_download_models.ps1 -ComfyUIPath "D:\ComfyUI"

 注意（重要）：
   FLUX.1-dev 與 FLUX.1-Kontext-dev 是「gated（需同意授權）」模型。
   下載前請先：
     1) 到 https://huggingface.co/black-forest-labs/FLUX.1-dev 按 Agree
     2) 到 https://huggingface.co/black-forest-labs/FLUX.1-Kontext-dev 按 Agree
     3) huggingface-cli login   （貼上你的 HF token）
   「FLUX Kontext Pro」沒有開源權重 → 它是 BFL 官方 API 模型，
     只能用 ComfyUI 的 API 節點呼叫（見 docs/04_flux.md），本腳本不下載它。
#>

param(
    [string]$ComfyUIPath = "."
)
$ErrorActionPreference = "Stop"

# ---------- 找到 models 根目錄與 python ----------
$ComfyUIPath = (Resolve-Path $ComfyUIPath).Path
$Models = Join-Path $ComfyUIPath "models"
if (-not (Test-Path $Models)){ throw "找不到 $Models，請用 -ComfyUIPath 指定 ComfyUI 安裝目錄" }

$python = $null
foreach($c in @("..\python_embeded\python.exe","python_embeded\python.exe",".venv\Scripts\python.exe","venv\Scripts\python.exe")){
    $p = Join-Path $ComfyUIPath $c
    if (Test-Path $p){ $python = (Resolve-Path $p).Path; break }
}
if (-not $python){ $python = "python" }

# 確保 huggingface_hub[cli] 可用
Write-Host "檢查 huggingface-cli..." -ForegroundColor Cyan
& $python -m pip install -q -U "huggingface_hub[cli]" 2>$null

function HF($repo, $file, $destSub, [string]$rename=$null){
    $dest = Join-Path $Models $destSub
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Write-Host "↓ [$repo] $file → models\$destSub" -ForegroundColor Green
    & $python -m huggingface_hub.commands.huggingface_cli download $repo $file --local-dir $dest --local-dir-use-symlinks False
    if ($rename){
        $src = Join-Path $dest $file
        $dst = Join-Path $dest $rename
        if ((Test-Path $src) -and ($src -ne $dst)){ Move-Item -Force $src $dst }
    }
}

function DirectDL($url, $destSub, $name){
    $dest = Join-Path $Models $destSub
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    $out = Join-Path $dest $name
    Write-Host "↓ (curl) $name → models\$destSub" -ForegroundColor Green
    curl.exe -L -C - -o $out $url
}

# ================================================================
#  各類別下載函式
# ================================================================

function Get-ControlNet-SD15 {
    Write-Host "`n### ControlNet SD1.5 (fp16 safetensors) ###" -ForegroundColor Magenta
    $repo = "comfyanonymous/ControlNet-v1-1_fp16_safetensors"
    HF $repo "control_v11p_sd15_canny_fp16.safetensors"    "controlnet"
    HF $repo "control_v11f1p_sd15_depth_fp16.safetensors"  "controlnet"
    HF $repo "control_v11p_sd15_openpose_fp16.safetensors" "controlnet"
    HF $repo "control_v11p_sd15_lineart_fp16.safetensors"  "controlnet"
    HF $repo "control_v11p_sd15_softedge_fp16.safetensors" "controlnet"
    HF $repo "control_v11p_sd15_seg_fp16.safetensors"      "controlnet"
}

function Get-ControlNet-Union {
    Write-Host "`n### ControlNet Union (SDXL + FLUX) ###" -ForegroundColor Magenta
    # SDXL Union ProMax (xinsir) → 用於 RealVisXL / Juggernaut 工作流
    HF "xinsir/controlnet-union-sdxl-1.0" "diffusion_pytorch_model_promax.safetensors" "controlnet" "controlnet_union_sdxl_promax.safetensors"
    # FLUX Union Pro 2.0 (Shakker-Labs) → 用於 FLUX 工作流的 ControlNet
    HF "Shakker-Labs/FLUX.1-dev-ControlNet-Union-Pro-2.0" "diffusion_pytorch_model.safetensors" "controlnet" "flux_controlnet_union_pro_2.safetensors"
}

function Get-IPAdapter {
    Write-Host "`n### IPAdapter + CLIP Vision ###" -ForegroundColor Magenta
    # SD1.5 plus-face
    HF "h94/IP-Adapter" "models/ip-adapter-plus-face_sd15.safetensors" "ipadapter" "ip-adapter-plus-face_sd15.safetensors"
    # SDXL plus
    HF "h94/IP-Adapter" "sdxl_models/ip-adapter-plus_sdxl_vit-h.safetensors" "ipadapter" "ip-adapter-plus_sdxl_vit-h.safetensors"
    # FaceID Plus v2 (SDXL) + 對應 LoRA
    HF "h94/IP-Adapter-FaceID" "ip-adapter-faceid-plusv2_sdxl.bin" "ipadapter"
    HF "h94/IP-Adapter-FaceID" "ip-adapter-faceid-plusv2_sdxl_lora.safetensors" "loras"
    # CLIP Vision encoders
    HF "h94/IP-Adapter" "models/image_encoder/model.safetensors" "clip_vision" "CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"
    HF "h94/IP-Adapter" "sdxl_models/image_encoder/model.safetensors" "clip_vision" "CLIP-ViT-bigG-14-laion2B-39B-b160k.safetensors"
}

function Get-SDXL-Checkpoints {
    Write-Host "`n### SDXL 寫實 Checkpoints ###" -ForegroundColor Magenta
    HF "SG161222/RealVisXL_V5.0" "RealVisXL_V5.0_fp16.safetensors" "checkpoints"
    HF "RunDiffusion/Juggernaut-XL-v9" "Juggernaut-XL_v9_RunDiffusionPhoto_v2.safetensors" "checkpoints"
}

function Get-FLUX {
    Write-Host "`n### FLUX Dev + Kontext (gated，需先 agree + login) ###" -ForegroundColor Magenta
    # 文字編碼器 + VAE（兩者共用）
    HF "comfyanonymous/flux_text_encoders" "t5xxl_fp16.safetensors" "clip"
    HF "comfyanonymous/flux_text_encoders" "clip_l.safetensors"     "clip"
    HF "black-forest-labs/FLUX.1-dev" "ae.safetensors" "vae" "flux_ae.safetensors"
    # FLUX.1-dev 主模型（32GB VRAM → 用 fp16 完整版 ~23GB）
    HF "black-forest-labs/FLUX.1-dev" "flux1-dev.safetensors" "diffusion_models"
    #   省空間替代：comfyanonymous/flux_dev fp8 → flux1-dev-fp8.safetensors（放 checkpoints）
    # FLUX.1-Kontext-dev（影像編輯/風格轉換主力）
    HF "black-forest-labs/FLUX.1-Kontext-dev" "flux1-kontext-dev.safetensors" "diffusion_models"
    #   省空間替代：Comfy-Org/flux1-kontext-dev_ComfyUI → flux1-dev-kontext_fp8_scaled.safetensors
    Write-Host "提醒：FLUX Kontext Pro 為 API 模型，不在此下載，見 docs/04_flux.md" -ForegroundColor Yellow
}

function Get-Wan22 {
    Write-Host "`n### Wan 2.2 影片 (I2V + T2V, 14B) ###" -ForegroundColor Magenta
    $repo = "Comfy-Org/Wan_2.2_ComfyUI_Repackaged"
    # 共用：VAE + 文字編碼器
    HF $repo "split_files/vae/wan_2.1_vae.safetensors" "vae"
    HF $repo "split_files/text_encoders/umt5_xxl_fp16.safetensors" "clip"
    # I2V 14B（high/low noise，32GB 用 fp16）
    HF $repo "split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors" "diffusion_models"
    HF $repo "split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors"  "diffusion_models"
    # T2V 14B
    HF $repo "split_files/diffusion_models/wan2.2_t2v_high_noise_14B_fp16.safetensors" "diffusion_models"
    HF $repo "split_files/diffusion_models/wan2.2_t2v_low_noise_14B_fp16.safetensors"  "diffusion_models"
    Write-Host "省空間替代：上面檔名把 fp16 換成 fp8_scaled 即可（約一半大小）" -ForegroundColor Yellow
}

function Get-OtherVideo {
    Write-Host "`n### AnimateDiff + LTX-Video + Hunyuan Video ###" -ForegroundColor Magenta
    # AnimateDiff（SD1.5 motion module v3）
    HF "guoyww/animatediff" "mm_sd_v15_v2.ckpt" "animatediff_models"
    # LTX-Video 0.9.7（13B distilled，快速影片）
    HF "Lightricks/LTX-Video" "ltxv-13b-0.9.7-distilled.safetensors" "checkpoints"
    # Hunyuan Video (t2v 720p)
    $hv = "Comfy-Org/HunyuanVideo_repackaged"
    HF $hv "split_files/diffusion_models/hunyuan_video_t2v_720p_bf16.safetensors" "diffusion_models"
    HF $hv "split_files/vae/hunyuan_video_vae_bf16.safetensors" "vae"
    HF $hv "split_files/text_encoders/llava_llama3_fp16.safetensors" "clip"
    HF $hv "split_files/text_encoders/clip_l.safetensors" "clip" "hunyuan_clip_l.safetensors"
}

function Get-Upscalers {
    Write-Host "`n### 放大模型 ###" -ForegroundColor Magenta
    HF "Kim2091/UltraSharp" "4x-UltraSharp.pth" "upscale_models"
    DirectDL "https://huggingface.co/FacehugmanIII/4x_foolhardy_Remacri/resolve/main/4x_foolhardy_Remacri.pth" "upscale_models" "4x_foolhardy_Remacri.pth"
    DirectDL "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth" "upscale_models" "RealESRGAN_x4plus.pth"
}

# ================================================================
#  選單
# ================================================================
$menu = @"

=================== ComfyUI 模型下載選單 ===================
 ComfyUI： $ComfyUIPath
 模型目錄：$Models

  1) ControlNet SD1.5 (6 個)          ~4 GB
  2) ControlNet Union (SDXL + FLUX)   ~5 GB
  3) IPAdapter + CLIP Vision          ~5 GB
  4) SDXL Checkpoints (RealVisXL/Juggernaut) ~14 GB
  5) FLUX Dev + Kontext (gated!)      ~55 GB
  6) Wan 2.2 影片 (I2V+T2V 14B)       ~110 GB
  7) AnimateDiff + LTX + Hunyuan      ~45 GB
  8) 放大模型 (4x UltraSharp/Remacri/ESRGAN) ~0.3 GB
  9) 圖像類全套 (1+2+3+4+5+8)         ~83 GB
 10) 影片類全套 (6+7)                 ~155 GB
  A) 全部下載 (約 240 GB，需很多時間/空間)
  Q) 離開
============================================================
請輸入選項（可用逗號多選，如 1,2,3）：
"@

Write-Host $menu -ForegroundColor Cyan
$choice = Read-Host
$picks = $choice.Split(",") | ForEach-Object { $_.Trim().ToUpper() }

foreach($p in $picks){
    switch($p){
        "1"  { Get-ControlNet-SD15 }
        "2"  { Get-ControlNet-Union }
        "3"  { Get-IPAdapter }
        "4"  { Get-SDXL-Checkpoints }
        "5"  { Get-FLUX }
        "6"  { Get-Wan22 }
        "7"  { Get-OtherVideo }
        "8"  { Get-Upscalers }
        "9"  { Get-ControlNet-SD15; Get-ControlNet-Union; Get-IPAdapter; Get-SDXL-Checkpoints; Get-FLUX; Get-Upscalers }
        "10" { Get-Wan22; Get-OtherVideo }
        "A"  { Get-ControlNet-SD15; Get-ControlNet-Union; Get-IPAdapter; Get-SDXL-Checkpoints; Get-FLUX; Get-Wan22; Get-OtherVideo; Get-Upscalers }
        "Q"  { Write-Host "離開。" }
        default { Write-Host "略過未知選項：$p" -ForegroundColor Yellow }
    }
}

Write-Host "`n模型下載流程結束。請用 ComfyUI Manager → Model Manager 確認檔案是否就位。" -ForegroundColor Cyan
