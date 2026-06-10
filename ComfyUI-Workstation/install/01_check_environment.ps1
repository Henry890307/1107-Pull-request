<#
================================================================
 01_check_environment.ps1
 ComfyUI 工作站 - 第一階段：環境檢查
================================================================
 檢查項目：
   1. ComfyUI 是否最新版 (git)
   2. Python 版本是否相容 (建議 3.11 / 3.12)
   3. NVIDIA 驅動 / CUDA 是否正常
   4. Torch 是否為 CUDA 版且支援 RTX 4080 SUPER (sm_89)
   5. xFormers 是否安裝且版本相容
   6. GPU VRAM 是否可被完整偵測 (特規 RTX 4080 = 32GB 顯存)

 用法（在 ComfyUI 根目錄，或用 -ComfyUIPath 指定）：
   powershell -ExecutionPolicy Bypass -File 01_check_environment.ps1
   powershell -ExecutionPolicy Bypass -File 01_check_environment.ps1 -ComfyUIPath "D:\ComfyUI"

 說明：
   - 此腳本「只檢查、不亂改」。需要升級的地方會印出建議指令，
     由你確認後再執行（避免自動破壞既有環境）。
   - 適用 ComfyUI 可攜版 (python_embeded) 與一般 venv 兩種安裝。
#>

param(
    [string]$ComfyUIPath = "."
)

$ErrorActionPreference = "Continue"
$ok    = @()
$warn  = @()
$fail  = @()

function Section($t){ Write-Host "`n==================== $t ====================" -ForegroundColor Cyan }
function Pass($m){ Write-Host "  [OK]   $m" -ForegroundColor Green;  $script:ok   += $m }
function Warn($m){ Write-Host "  [WARN] $m" -ForegroundColor Yellow; $script:warn += $m }
function Fail($m){ Write-Host "  [FAIL] $m" -ForegroundColor Red;    $script:fail += $m }

Write-Host "================================================================" -ForegroundColor Magenta
Write-Host " ComfyUI 工作站 - 環境健檢" -ForegroundColor Magenta
Write-Host " 目標硬體：i5-13500 / RTX 4080 特規 32GB / 96GB RAM / Win11" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta

# ---------- 解析 ComfyUI 路徑與 Python ----------
$ComfyUIPath = (Resolve-Path $ComfyUIPath -ErrorAction SilentlyContinue)
if (-not $ComfyUIPath){ $ComfyUIPath = (Get-Location).Path }
Write-Host "`nComfyUI 路徑：$ComfyUIPath"

# 嘗試找出該安裝使用的 python（優先用可攜版內建的 python_embeded）
$python = $null
$candidates = @(
    (Join-Path $ComfyUIPath "..\python_embeded\python.exe"),
    (Join-Path $ComfyUIPath "python_embeded\python.exe"),
    (Join-Path $ComfyUIPath ".venv\Scripts\python.exe"),
    (Join-Path $ComfyUIPath "venv\Scripts\python.exe")
)
foreach($c in $candidates){ if (Test-Path $c){ $python = (Resolve-Path $c).Path; break } }
if (-not $python){ $python = "python" }  # 退回系統 PATH
Write-Host "使用的 Python：$python"

# ---------- 1. NVIDIA 驅動 / nvidia-smi ----------
Section "1. NVIDIA 驅動 / GPU 偵測"
$smi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
if ($smi){
    $gpuLine = (& nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader) 2>$null
    if ($gpuLine){
        Pass "偵測到 GPU：$gpuLine"
        if ($gpuLine -match "4080"){ Pass "確認為 RTX 4080 系列 (Ada Lovelace, sm_89)" }
        $memMatch = [regex]::Match($gpuLine, '(\d+)\s*MiB')
        if ($memMatch.Success){
            $mb = [int]$memMatch.Groups[1].Value
            $gb = [math]::Round($mb/1024,1)
            if ($gb -ge 30){ Pass "VRAM 可完整偵測：約 ${gb} GB（特規 32GB 顯存正常）" }
            elseif ($gb -ge 15){ Warn "VRAM 偵測為 ${gb} GB（特規卡應為 ~32GB；若你確認是 32GB 版，可能驅動未正確讀取顯存）" }
            else { Fail "VRAM 偵測值偏低 (${gb} GB)，請確認沒有其他程式佔用顯卡，並更新驅動" }
        }
    } else { Fail "nvidia-smi 執行失敗，請更新 NVIDIA 驅動" }
} else {
    Fail "找不到 nvidia-smi。請至 https://www.nvidia.com/Download/index.aspx 安裝最新 Game Ready / Studio 驅動"
}

# ---------- 2. Python 版本 ----------
Section "2. Python 版本"
try {
    $pyver = (& $python --version) 2>&1
    Pass "Python：$pyver"
    $vm = [regex]::Match($pyver, '(\d+)\.(\d+)')
    if ($vm.Success){
        $maj=[int]$vm.Groups[1].Value; $min=[int]$vm.Groups[2].Value
        if ($maj -eq 3 -and ($min -eq 11 -or $min -eq 12)){ Pass "版本相容 (建議 3.11 / 3.12)" }
        elseif ($maj -eq 3 -and $min -eq 10){ Warn "3.10 可用，但建議升級到 3.11/3.12 以獲得最佳套件支援" }
        elseif ($maj -eq 3 -and $min -ge 13){ Warn "3.13 過新，部分自訂節點 / xFormers 可能尚未支援，建議用 3.12" }
        else { Fail "Python 版本不相容，請改用 3.11 或 3.12" }
    }
} catch { Fail "無法執行 Python：$python" }

# ---------- 3-6. Torch / CUDA / xFormers / VRAM（用 Python 一次查完）----------
Section "3-6. Torch / CUDA / xFormers / VRAM"
$probe = @'
import json, sys
r = {}
try:
    import torch
    r["torch"] = torch.__version__
    r["cuda_available"] = torch.cuda.is_available()
    r["torch_cuda"] = torch.version.cuda
    if torch.cuda.is_available():
        r["device"] = torch.cuda.get_device_name(0)
        cap = torch.cuda.get_device_capability(0)
        r["capability"] = f"{cap[0]}.{cap[1]}"
        props = torch.cuda.get_device_properties(0)
        r["vram_gb"] = round(props.total_memory/1024**3, 1)
        # 簡單分配測試：嘗試在 GPU 上配置 1GB tensor
        try:
            t = torch.zeros((256,1024,1024), dtype=torch.float32, device="cuda")
            del t; torch.cuda.empty_cache()
            r["alloc_test"] = "ok"
        except Exception as e:
            r["alloc_test"] = f"fail: {e}"
except Exception as e:
    r["torch_error"] = str(e)
try:
    import xformers
    r["xformers"] = xformers.__version__
except Exception as e:
    r["xformers_error"] = str(e)
print("PROBE_JSON:" + json.dumps(r))
'@

$tmp = Join-Path $env:TEMP "comfy_probe.py"
$probe | Out-File -FilePath $tmp -Encoding utf8
$out = (& $python $tmp) 2>&1
Remove-Item $tmp -ErrorAction SilentlyContinue

$jsonLine = ($out | Select-String "PROBE_JSON:").ToString()
if ($jsonLine){
    $r = ($jsonLine -replace "^.*PROBE_JSON:","") | ConvertFrom-Json

    if ($r.torch){ Pass "Torch 版本：$($r.torch)" } else { Fail "Torch 未安裝或匯入失敗：$($r.torch_error)" }
    if ($r.torch_cuda){ Pass "Torch 編譯的 CUDA 版本：$($r.torch_cuda)" }
    if ($r.cuda_available){ Pass "CUDA 可用 (torch.cuda.is_available = True)" }
    else { Fail "CUDA 不可用！多半是裝到 CPU 版 Torch。請重裝 CUDA 版（見下方建議）" }
    if ($r.device){ Pass "Torch 偵測到的裝置：$($r.device)" }
    if ($r.capability){
        if ($r.capability -eq "8.9"){ Pass "運算能力 sm_89 → 完整支援 RTX 4080 SUPER" }
        else { Warn "運算能力為 $($r.capability)（4080 SUPER 應為 8.9）" }
    }
    if ($r.vram_gb){ Pass "Torch 可見 VRAM：$($r.vram_gb) GB" }
    if ($r.alloc_test -eq "ok"){ Pass "VRAM 配置測試通過（成功配置/釋放 1GB）" }
    elseif ($r.alloc_test){ Fail "VRAM 配置測試失敗：$($r.alloc_test)" }

    if ($r.xformers){ Pass "xFormers 版本：$($r.xformers)" }
    else { Warn "xFormers 未安裝（非必要；PyTorch 2.x 內建 SDPA 已足夠，但裝了可省一點 VRAM）。錯誤：$($r.xformers_error)" }
} else {
    Fail "Python 探測腳本沒有輸出 JSON，原始輸出："
    Write-Host $out
}

# ---------- 7. ComfyUI 版本 (git) ----------
Section "7. ComfyUI 版本 (git)"
if (Test-Path (Join-Path $ComfyUIPath ".git")){
    Push-Location $ComfyUIPath
    $localHash  = (git rev-parse --short HEAD) 2>$null
    $branch     = (git rev-parse --abbrev-ref HEAD) 2>$null
    git fetch --quiet 2>$null
    $behind = (git rev-list --count "HEAD..@{u}") 2>$null
    Pop-Location
    Pass "ComfyUI git commit：$localHash (branch: $branch)"
    if ($behind -and [int]$behind -gt 0){ Warn "落後遠端 $behind 個 commit → 建議更新：cd `"$ComfyUIPath`"; git pull" }
    elseif ($behind -eq "0"){ Pass "已是最新版" }
} else {
    Warn "此資料夾不是 git 安裝（可能是可攜版 zip）。請改用 ComfyUI Manager → Update ComfyUI 來更新。"
}

# ---------- 總結 ----------
Section "健檢總結"
Write-Host ("  通過 (OK)   : {0}" -f $ok.Count)   -ForegroundColor Green
Write-Host ("  警告 (WARN) : {0}" -f $warn.Count) -ForegroundColor Yellow
Write-Host ("  失敗 (FAIL) : {0}" -f $fail.Count) -ForegroundColor Red

if ($fail.Count -gt 0){
    Write-Host "`n--- 常見修復建議 ---" -ForegroundColor Magenta
    Write-Host @"
[CUDA / Torch 不可用]  重裝 CUDA 版 PyTorch（cu124，對應 RTX 4080 SUPER）：
  "$python" -m pip uninstall -y torch torchvision torchaudio
  "$python" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

[xFormers 缺少]（選用）：
  "$python" -m pip install -U xformers --index-url https://download.pytorch.org/whl/cu124

[NVIDIA 驅動]  下載 Studio Driver：https://www.nvidia.com/Download/index.aspx
"@
}
Write-Host "`n環境檢查完成。修正所有 [FAIL] 後，再執行 02_install_custom_nodes.bat。" -ForegroundColor Cyan
