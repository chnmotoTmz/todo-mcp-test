#!/bin/bash

echo "🚀 TODO MCP Test アプリケーションを起動します..."

# Node.jsの確認
if ! command -v node &> /dev/null; then
    echo "❌ Node.jsがインストールされていません"
    echo "https://nodejs.org/ からNode.jsをインストールしてください"
    exit 1
fi

echo "✅ Node.js version: $(node --version)"

# 依存関係のインストール
if [ ! -d "node_modules" ]; then
    echo "📦 依存関係をインストールしています..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ npm install failed"
        exit 1
    fi
else
    echo "✅ 依存関係は既にインストール済みです"
fi

# サーバー起動
echo "🖥️  プロキシサーバーを起動しています..."
echo "📝 ブラウザで http://localhost:3000/todo-app.html を開いてください"
echo "🛑 停止するには Ctrl+C を押してください"
echo ""

npm start