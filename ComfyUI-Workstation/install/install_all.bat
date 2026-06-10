@echo off
REM ================================================================
REM  install_all.bat  -  ComfyUI 工作站一鍵總控
REM ================================================================
REM  依序執行：環境檢查 -> 安裝節點 -> 建立資料夾 -> 下載模型
REM  用法： install_all.bat "D:\ComfyUI"   （指向你的 ComfyUI 根目錄）
REM ================================================================
setlocal
set "COMFY=%~1"
if "%COMFY%"=="" (
    set /p COMFY="請輸入你的 ComfyUI 根目錄 (例 D:\ComfyUI)： "
)
set "HERE=%~dp0"

echo.
echo ############################################################
echo #  ComfyUI 工作站部署  (目標：RTX 4080 特規 32GB / 96GB RAM)
echo #  ComfyUI 路徑： %COMFY%
echo ############################################################
echo.

echo === 第一階段：環境檢查 ===
powershell -ExecutionPolicy Bypass -File "%HERE%01_check_environment.ps1" -ComfyUIPath "%COMFY%"
echo.
choice /M "環境檢查完成。是否繼續安裝自訂節點"
if errorlevel 2 goto :end

echo === 第二階段：安裝自訂節點 ===
call "%HERE%02_install_custom_nodes.bat" "%COMFY%"

echo === 第四階段：建立工作流資料夾 ===
call "%HERE%04_create_folders.bat" "%COMFY%"

echo === 第三階段：下載模型（選單）===
powershell -ExecutionPolicy Bypass -File "%HERE%03_download_models.ps1" -ComfyUIPath "%COMFY%"

:end
echo.
echo 全部步驟結束。請重新啟動 ComfyUI 並開始使用工作流。
pause
