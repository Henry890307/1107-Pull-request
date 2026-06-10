@echo off
REM ================================================================
REM  02_install_custom_nodes.bat
REM  ComfyUI 工作站 - 第二階段：安裝必要自訂節點
REM ================================================================
REM  用法：
REM    1) 把此檔放到 ComfyUI 根目錄（含 custom_nodes 資料夾的那層）
REM       或直接執行，輸入 ComfyUI 路徑。
REM    2) 雙擊執行，或 cmd 執行： 02_install_custom_nodes.bat "D:\ComfyUI"
REM
REM  作法：對每個節點 git clone（已存在則 git pull），最後安裝 requirements。
REM  FaceDetailer 屬於 Impact Pack，不需單獨安裝。
REM ================================================================
setlocal EnableDelayedExpansion

set "COMFY=%~1"
if "%COMFY%"=="" set "COMFY=%CD%"
if not exist "%COMFY%\custom_nodes" (
    echo [ERROR] 在 "%COMFY%" 找不到 custom_nodes 資料夾。
    echo 請把此 bat 放到 ComfyUI 根目錄，或執行： 02_install_custom_nodes.bat "你的ComfyUI路徑"
    pause & exit /b 1
)

REM ---- 找出該安裝使用的 python（可攜版優先）----
set "PY="
if exist "%COMFY%\..\python_embeded\python.exe" set "PY=%COMFY%\..\python_embeded\python.exe"
if exist "%COMFY%\python_embeded\python.exe"     set "PY=%COMFY%\python_embeded\python.exe"
if exist "%COMFY%\.venv\Scripts\python.exe"       set "PY=%COMFY%\.venv\Scripts\python.exe"
if exist "%COMFY%\venv\Scripts\python.exe"        set "PY=%COMFY%\venv\Scripts\python.exe"
if "%PY%"=="" set "PY=python"
echo 使用 Python：%PY%
echo ComfyUI： %COMFY%

cd /d "%COMFY%\custom_nodes"

REM ---- 要安裝的節點清單（名稱 + git URL）----
call :clone ComfyUI-Manager                 https://github.com/ltdrdata/ComfyUI-Manager
call :clone ComfyUI-Impact-Pack             https://github.com/ltdrdata/ComfyUI-Impact-Pack
call :clone ComfyUI-Impact-Subpack          https://github.com/ltdrdata/ComfyUI-Impact-Subpack
call :clone ComfyUI_essentials              https://github.com/cubiq/ComfyUI_essentials
call :clone ComfyUI-Inspire-Pack            https://github.com/ltdrdata/ComfyUI-Inspire-Pack
call :clone ComfyUI-Easy-Use                https://github.com/yolain/ComfyUI-Easy-Use
call :clone ComfyUI-Custom-Scripts          https://github.com/pythongosssss/ComfyUI-Custom-Scripts
call :clone ComfyUI-Advanced-ControlNet     https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet
call :clone comfyui_controlnet_aux          https://github.com/Fannovel16/comfyui_controlnet_aux
call :clone ComfyUI_IPAdapter_plus          https://github.com/cubiq/ComfyUI_IPAdapter_plus
call :clone ComfyUI_UltimateSDUpscale       https://github.com/ssitu/ComfyUI_UltimateSDUpscale
call :clone ComfyUI-VideoHelperSuite        https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
call :clone ComfyUI-KJNodes                 https://github.com/kijai/ComfyUI-KJNodes
call :clone ComfyUI-AnimateDiff-Evolved     https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved
call :clone ComfyUI-Crystools               https://github.com/crystian/ComfyUI-Crystools
call :clone efficiency-nodes-comfyui        https://github.com/jags111/efficiency-nodes-comfyui
call :clone ComfyUI_LayerStyle              https://github.com/chflame163/ComfyUI_LayerStyle
call :clone rgthree-comfy                   https://github.com/rgthree/rgthree-comfy
call :clone was-node-suite-comfyui          https://github.com/WASasquatch/was-node-suite-comfyui
call :clone ComfyUI_FizzNodes               https://github.com/FizzleDorf/ComfyUI_FizzNodes
call :clone ComfyUI-ReActor                 https://github.com/Gourieff/ComfyUI-ReActor
REM ---- Wan 2.2 / 影片所需（kijai 包裝器）----
call :clone ComfyUI-WanVideoWrapper         https://github.com/kijai/ComfyUI-WanVideoWrapper
call :clone ComfyUI-Frame-Interpolation     https://github.com/Fannovel16/ComfyUI-Frame-Interpolation

echo.
echo ================================================================
echo  安裝各節點的 requirements.txt
echo ================================================================
for /d %%D in ("%COMFY%\custom_nodes\*") do (
    if exist "%%D\requirements.txt" (
        echo --- pip install: %%~nxD ---
        "%PY%" -m pip install -r "%%D\requirements.txt"
    )
)

REM ReActor 需要 insightface；FaceDetailer/Subpack 需要 ultralytics
echo --- 安裝臉部相關相依：insightface / onnxruntime-gpu / ultralytics ---
"%PY%" -m pip install insightface onnxruntime-gpu ultralytics

echo.
echo ================================================================
echo  完成！請重新啟動 ComfyUI。
echo  之後到 Manager 介面確認所有節點為綠燈（無 import 失敗）。
echo  FaceDetailer = Impact Pack 內建節點，無需另裝。
echo ================================================================
pause
exit /b 0

:clone
REM %1 = 資料夾名稱, %2 = git URL
if exist "%~1" (
    echo [pull] %~1
    git -C "%~1" pull --ff-only
) else (
    echo [clone] %~1
    git clone --depth 1 %~2 "%~1"
)
exit /b 0
