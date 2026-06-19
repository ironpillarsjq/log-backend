@echo off
chcp 64000 >nul

echo ====================================================
echo            Starting Fluent Bit (Windows)...
echo ====================================================

:: 1. 仅仅作为“执行引擎”的绝对路径
set "FB_BIN=D:\Major\fluent-bit\bin\fluent-bit.exe"

:: 2. 核心修复：牢牢钉住当前脚本所在的【项目根目录】
set "CURRENT_PROJECT_DIR=%~dp0"

:: 3. 同级目录下进行环境配置文件覆盖（因为你的 env 文件夹和 start.bat 同级）
echo [INFO] 正在刷新环境配置文件...
copy /Y "%CURRENT_PROJECT_DIR%env\env_windows.conf" "%CURRENT_PROJECT_DIR%env\env.conf" >nul

echo [INFO] 正在清理本地旧缓冲区与残留进程...
taskkill /f /im fluent-bit.exe >nul 2>&1
:: 缓冲区依然放在编译运行的地方清理
if exist "D:\Major\fluent-bit\buffer" rd /s /q "D:\Major\fluent-bit\buffer"

echo [SUCCESS] 准备工作就绪，正在调起 Fluent Bit 引擎...
echo ----------------------------------------------------

:: 4. 终极启动命令：用绝对路径的引擎，加载你当前 Git 项目目录下的配置文件
"%FB_BIN%" -c "%CURRENT_PROJECT_DIR%conf\fluent-bit.conf"

pause