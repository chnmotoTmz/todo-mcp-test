# TODO MCP Test

シンプルなTODO管理システム with LLM & MCP Protocol

## 🚀 クイックスタート

```bash
# リポジトリをクローン
git clone https://github.com/chnmotoTmz/todo-mcp-test.git
cd todo-mcp-test

# 依存関係をインストール
npm install

# サーバー起動
npm start

# ブラウザでアクセス
open http://localhost:3000/todo-app.html
```

## 📁 ファイル構成

- `proxy-server.js` - Node.jsプロキシサーバー（MCP風ツール実装）
- `todo-app.html` - ブラウザで動くGUIアプリ
- `package.json` - 依存関係定義
- `start.sh` - 起動スクリプト

## ✨ 機能

- **LLMとの対話**: 自然言語でTODOを相談
- **MCPツール呼び出し**: `todo_save`, `todo_get`
- **ローカル保存**: `todos.json`ファイルに永続化
- **GUI表示**: チャット形式でやり取りを表示

## 🧪 テストケース

1. 「今度の週末、友達と映画を見る予定があるんだけど、他にもやりたいことがあって整理したい」
2. 「洗濯、買い物、読書もしたい」
3. 保存済みTODO表示ボタンクリック

## 🔧 技術スタック

- **Frontend**: HTML/CSS/JavaScript
- **Backend**: Node.js + Express
- **Storage**: JSON file
- **Protocol**: MCP風のツール呼び出し

移植性の高いHTMLアプリ + MCPプロキシの基本形です！