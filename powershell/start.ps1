# PowerShell TODO MCP App 起動スクリプト
# 最速起動 & 自動ブラウザ起動

param(
    [switch]$NoBrowser = $false,
    [string]$Port = "3000"
)

Write-Host @"
⚡ PowerShell TODO MCP アプリケーション
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 最速起動版 with C# integration
📝 ローカル TODO 管理システム
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"@ -ForegroundColor Cyan

# ファイル存在確認
$requiredFiles = @("proxy-server.ps1", "todo-app.html")
$missingFiles = @()

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "❌ 必要なファイルが見つかりません:" -ForegroundColor Red
    foreach ($file in $missingFiles) {
        Write-Host "   - $file" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "📥 GitHubからダウンロードしてください:" -ForegroundColor Yellow
    Write-Host "   https://github.com/chnmotoTmz/todo-mcp-test" -ForegroundColor Blue
    Read-Host "Enterキーで終了"
    exit 1
}

Write-Host "✅ 必要なファイルを確認しました" -ForegroundColor Green

# PowerShell実行ポリシー確認
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -eq "Restricted") {
    Write-Host "⚠️ PowerShell実行ポリシーが制限されています" -ForegroundColor Yellow
    Write-Host "以下のコマンドを管理者権限で実行してください:" -ForegroundColor Yellow
    Write-Host "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned" -ForegroundColor Cyan
    Read-Host "Enterキーで終了"
    exit 1
}

# ポート使用確認
$portInUse = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Host "⚠️ ポート $Port は既に使用されています" -ForegroundColor Yellow
    Write-Host "他のアプリケーションを終了するか、別のポートを指定してください" -ForegroundColor Yellow
    $newPort = Read-Host "新しいポート番号を入力 (Enterでスキップ)"
    if ($newPort) {
        $Port = $newPort
    }
}

# サーバー起動
Write-Host "🔧 サーバーを起動しています..." -ForegroundColor Yellow

# バックグラウンドジョブでサーバー起動
$serverJob = Start-Job -ScriptBlock {
    param($serverScript)
    & $serverScript
} -ArgumentList (Resolve-Path "proxy-server.ps1")

# 起動待機
Start-Sleep -Seconds 2

# サーバー起動確認
$maxRetries = 10
$retryCount = 0
$serverReady = $false

Write-Host "⏳ サーバー起動確認中..." -ForegroundColor Yellow

while ($retryCount -lt $maxRetries -and -not $serverReady) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$Port/todo-app.html" -Method HEAD -TimeoutSec 2 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $serverReady = $true
        }
    } catch {
        $retryCount++
        Start-Sleep -Seconds 1
        Write-Host "." -NoNewline -ForegroundColor Gray
    }
}

Write-Host ""

if ($serverReady) {
    Write-Host "✅ サーバー起動成功!" -ForegroundColor Green
    Write-Host "🌐 URL: http://localhost:$Port/todo-app.html" -ForegroundColor Cyan
    
    # ブラウザ自動起動
    if (-not $NoBrowser) {
        Write-Host "🚀 ブラウザを起動しています..." -ForegroundColor Green
        Start-Process "http://localhost:$Port/todo-app.html"
    }
    
    Write-Host ""
    Write-Host "💡 使用方法:" -ForegroundColor Yellow
    Write-Host "   1. ブラウザでTODOアプリが開きます" -ForegroundColor White
    Write-Host "   2. 例文ボタンをクリックして試してください" -ForegroundColor White
    Write-Host "   3. 自然言語でTODOを相談できます" -ForegroundColor White
    Write-Host ""
    Write-Host "🛑 停止方法:" -ForegroundColor Red
    Write-Host "   このウィンドウで Ctrl+C を押すか、このウィンドウを閉じてください" -ForegroundColor White
    Write-Host ""
    
    # ジョブ状態監視
    try {
        Write-Host "⚡ サーバー実行中... (Ctrl+C で停止)" -ForegroundColor Green
        
        # ジョブ完了まで待機
        Wait-Job $serverJob | Out-Null
        
        # ジョブ結果取得
        $result = Receive-Job $serverJob
        if ($result) {
            Write-Host "📝 サーバーログ:" -ForegroundColor Cyan
            $result | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
        }
    } catch {
        Write-Host "⚠️ サーバーが停止しました" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ サーバー起動に失敗しました" -ForegroundColor Red
    
    # ジョブエラー確認
    $jobErrors = Receive-Job $serverJob -ErrorAction SilentlyContinue
    if ($jobErrors) {
        Write-Host "エラー詳細:" -ForegroundColor Red
        $jobErrors | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
    }
}

# クリーンアップ
if ($serverJob) {
    Stop-Job $serverJob -ErrorAction SilentlyContinue
    Remove-Job $serverJob -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "👋 TODO MCP アプリを終了します" -ForegroundColor Cyan
Read-Host "Enterキーで終了"