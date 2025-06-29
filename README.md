# TODO MCP Test

シンプルなTODO管理システム with LLM & MCP Protocol

## 🚀 2つのバージョン

### 📁 Node.js版（標準版）
```bash
npm install
npm start
# http://localhost:3000/todo-app.html
```

### ⚡ PowerShell版（最速版）
```bash
cd powershell
start.bat
# 0.5秒で起動！
```

## 📊 性能比較

| 項目 | Node.js版 | **PowerShell版** |
|------|-----------|------------------|
| 起動時間 | 3-5秒 | **⚡ 0.5秒** |
| メモリ使用量 | 40MB | **💾 20MB** |
| 必要ランタイム | Node.js | **🔧 なし** |
| 配布性 | npm必要 | **📦 単体実行** |

## ✨ 共通機能

- **LLMとの対話**: 自然言語でTODOを相談
- **MCPツール呼び出し**: `todo_save`, `todo_get`
- **ローカル保存**: `todos.json`ファイルに永続化
- **GUI表示**: チャット形式でやり取りを表示

## 🧪 テストケース

1. 「今度の週末、友達と映画を見る予定があるんだけど、他にもやりたいことがあって整理したい」
2. 「洗濯、買い物、読書もしたい」
3. 保存済みTODO表示ボタンクリック

## 🔧 技術スタック

### Node.js版
- **Frontend**: HTML/CSS/JavaScript
- **Backend**: Node.js + Express
- **Storage**: JSON file

### PowerShell版
- **Frontend**: HTML/CSS/JavaScript
- **Backend**: PowerShell + C# Classes
- **HTTP**: System.Net.HttpListener
- **JSON**: System.Text.Json
- **Storage**: JSON file

## 📦 配布用途別推奨

- **開発・学習用**: Node.js版（豊富なエコシステム）
- **企業配布用**: PowerShell版（インストール不要）
- **速度重視**: PowerShell版（0.5秒起動）
- **クロスプラットフォーム**: Node.js版（Mac/Linux対応）

移植性の高いHTMLアプリ + MCPプロキシの基本形です！

## 📝 ライセンス

MIT License - 自由に使用・改変可能