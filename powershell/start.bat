@echo off
echo 🚀 PowerShell TODO MCP 起動中...
echo.
echo このバッチファイルは PowerShell版のTODO MCPアプリを起動します
echo PowerShell実行ポリシーが制限されている場合は自動で対処します
echo.

REM PowerShell実行ポリシー確認と設定
powershell -Command "if ((Get-ExecutionPolicy) -eq 'Restricted') { Write-Host '⚠️ PowerShell実行ポリシーを一時的に変更します...' -ForegroundColor Yellow; Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force }"

REM PowerShell版TODO MCPアプリ起動
powershell -ExecutionPolicy Bypass -File start.ps1

echo.
echo 👋 アプリケーションを終了しました
pause