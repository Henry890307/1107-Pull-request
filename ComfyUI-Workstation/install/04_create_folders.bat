@echo off
REM ================================================================
REM  04_create_folders.bat
REM  ComfyUI 工作站 - 第四階段：建立工作流資料夾結構
REM ================================================================
REM  在指定根目錄建立 ComfyUI_Workflows 樹狀結構，
REM  並把本套件內附的 workflow.json 複製進對應子資料夾。
REM
REM  用法： 04_create_folders.bat "D:\ComfyUI_Projects"
REM         未指定則建立在目前目錄。
REM ================================================================
setlocal

set "ROOT=%~1"
if "%ROOT%"=="" set "ROOT=%CD%"

set "WF=%ROOT%\ComfyUI_Workflows"
echo 建立資料夾於：%WF%

for %%D in (Architecture Interior Character Product Video Church Templates) do (
    mkdir "%WF%\%%D" 2>nul
    echo   [建立] ComfyUI_Workflows\%%D
)

REM ---- 複製本套件附帶的 workflow.json（此 bat 同層的 ..\ComfyUI_Workflows）----
set "SRC=%~dp0..\ComfyUI_Workflows"
if exist "%SRC%" (
    echo 複製內附工作流 from "%SRC%"
    xcopy "%SRC%\*" "%WF%\" /E /I /Y >nul
    echo   [完成] 已複製所有 workflow.json 與說明
) else (
    echo   [略過] 找不到內附工作流來源，僅建立空資料夾
)

echo.
echo 資料夾結構建立完成：
echo   %WF%\Architecture   建築渲染
echo   %WF%\Interior       室內渲染
echo   %WF%\Character      人物一致性
echo   %WF%\Product        商品廣告
echo   %WF%\Video          人物/動物影片
echo   %WF%\Church         教會海報
echo   %WF%\Templates      範本/共用
echo.
echo 之後在 ComfyUI 介面用 Workflow ^> Open 載入對應的 .json 即可。
pause
