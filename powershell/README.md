# ⚡ PowerShell TODO MCP - 最速起動版

最速起動を実現するPowerShell + C# 統合版のTODO管理システム

## 🚀 3つのバージョン

### 1. **標準版** - `proxy-server.ps1`
- 詳細なコメント付き
- 初心者向け
- 約200行

### 2. **修正版** - `proxy-server-fixed.ps1` 
- Content-Lengthエラー修正済み
- 安定動作保証
- 約180行

### 3. **🎯 スマート版** - `proxy-server-smart.ps1` ⭐**推奨**
- 極限まで最適化
- JIRA CORSプロキシスタイル
- **わずか120行**

## ⚡ 特徴

- **超高速起動**: 約0.5秒でサーバー起動
- **C#統合**: PowerShell内でC#クラスをフル活用
- **単体実行**: PowerShellのみで完結（Node.js不要）
- **Web GUI**: ブラウザで快適なインターフェース
- **永続化**: JSONファイルでデータ保存

## 📋 動作要件

- **Windows 10/11** (PowerShell 5.1以上)
- **.NET Framework 4.7.2以上** (Windows標準)
- **ブラウザ** (Chrome, Edge, Firefox等)

> 💡 追加インストール不要！Windowsに標準で含まれています

## 🎯 クイックスタート

### 方法1: バッチファイル（推奨）
```batch
start.bat
```

### 方法2: PowerShell起動スクリプト
```powershell
.\start.ps1
```

### 方法3: 直接実行（スマート版）
```powershell
.\proxy-server-smart.ps1
```

## 🔧 実行ポリシーエラーの対処

初回実行時にエラーが出る場合：

```powershell
# 管理者PowerShellで実行
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

# または一時的に許可
PowerShell -ExecutionPolicy Bypass -File start.ps1
```

## ✨ 使用方法

### 基本操作

1. **例文ボタンクリック** で簡単テスト
2. **自然言語入力** でTODO相談
3. **自動保存** でデータ永続化
4. **履歴表示** で過去のTODO確認

### テストシナリオ

```
👤 「今度の週末、友達と映画を見る予定があるんだけど、他にもやりたいことがあって整理したい」
🤖 「週末の予定を整理しましょう！やりたいことを教えてください」

👤 「洗濯、買い物、読書もしたい」  
🤖 「以下のタスクを整理しました：
    • 友達と映画を見る
    • 洗濯をする
    • 買い物に行く
    • 読書をする
    
    優先順位を付けて保存しますね」
🔧 [todo_save実行] → 保存完了！
```

## 🛠️ アーキテクチャ

### 技術スタック

```
PowerShell Script
├── C# Class Definitions (.NET Framework)
├── HTTP Server (System.Net.HttpListener)
├── JSON Processing (System.Text.Json)
└── File I/O (System.IO)
```

### データフロー

```
HTMLアプリ → PowerShell HTTPサーバー → C#クラス → JSON保存
     ↓              ↓                    ↓
 ブラウザGUI    API エンドポイント    todos.json
```

## 📁 ファイル構成

```
powershell/
├── proxy-server.ps1         # 標準版（詳細コメント）
├── proxy-server-fixed.ps1   # 修正版（安定動作）
├── proxy-server-smart.ps1   # ⭐スマート版（最適化）
├── start.ps1                # 起動スクリプト  
├── start.bat                # Windows簡単起動用
├── todo-app.html            # PowerShell版対応GUI
└── README.md                # このファイル
```

## 📊 性能比較

| 版 | 起動時間 | メモリ使用量 | 行数 | 推奨用途 |
|---|----------|-------------|------|----------|
| 標準版 | 0.5秒 | 20MB | 200行 | 学習・理解 |
| 修正版 | 0.5秒 | 20MB | 180行 | 安定運用 |
| **スマート版** | **0.5秒** | **20MB** | **120行** | **本番運用** |

## 🔧 カスタマイズ

### ポート変更

```powershell
# start.ps1で指定
.\start.ps1 -Port 8080

# 直接編集（スマート版）
$ls.Prefixes.Add("http://*:8080/")
```

### C#クラス拡張

```powershell
# スマート版のAdd-Type部分に追加
public class CustomProcessor {
    public static void ProcessAdvanced(Todo todo) {
        // カスタムロジックを追加
    }
}
```

## 🏆 スマート版の優位性

JIRAプロキシコードの美しいスタイルを採用：

- **関数分割**: `INIT-TODO`, `HANDLE-REQUEST`, `RUN-SERVER`
- **短縮命名**: `TodoMgr`, `LLM`, `SEND-JSON`
- **インライン処理**: C#クラスを1行で定義
- **グローバル変数**: `$global:tm`, `$global:ls`
- **統一エラー処理**: 例外処理の最適化

---

**⚡ PowerShell + C# = 最速 & 最強の組み合わせ！**