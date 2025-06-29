const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

// 静的ファイル配信（HTMLファイル用）
app.use(express.static('.'));

// TODOファイルのパス
const TODO_FILE = 'todos.json';

// MCPツール定義
const tools = [
  {
    name: 'todo_save',
    description: 'Save todo items with priority',
    input_schema: {
      type: 'object',
      properties: {
        items: { 
          type: 'array', 
          items: { type: 'string' },
          description: 'List of todo items'
        },
        category: { 
          type: 'string', 
          description: 'Category (weekend, work, personal, etc.)'
        },
        priority: { 
          type: 'string', 
          enum: ['high', 'medium', 'low'],
          description: 'Priority level'
        }
      },
      required: ['items']
    }
  },
  {
    name: 'todo_get',
    description: 'Get all saved todo items',
    input_schema: {
      type: 'object',
      properties: {
        category: {
          type: 'string',
          description: 'Filter by category (optional)'
        }
      }
    }
  }
];

// TODOファイルの初期化
function initTodoFile() {
  if (!fs.existsSync(TODO_FILE)) {
    fs.writeFileSync(TODO_FILE, JSON.stringify([], null, 2));
  }
}

// TODOデータの読み込み
function loadTodos() {
  try {
    const data = fs.readFileSync(TODO_FILE, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    return [];
  }
}

// TODOデータの保存
function saveTodos(todos) {
  fs.writeFileSync(TODO_FILE, JSON.stringify(todos, null, 2));
}

// 簡単なLLM応答シミュレーション（テスト用）
app.post('/api/chat', async (req, res) => {
  try {
    const { messages } = req.body;
    const lastMessage = messages[messages.length - 1]?.content || '';
    
    // 簡単なパターンマッチング（実際のAnthropicAPI呼び出しの代替）
    let response = {
      role: 'assistant',
      content: ''
    };

    if (lastMessage.includes('週末') || lastMessage.includes('予定')) {
      response.content = '週末の予定を整理しましょう！やりたいことを教えてください。整理して保存しますよ。';
    } else if (lastMessage.includes('洗濯') || lastMessage.includes('買い物') || lastMessage.includes('映画')) {
      // ツール呼び出しをシミュレート
      const items = [];
      if (lastMessage.includes('映画')) items.push('友達と映画を見る');
      if (lastMessage.includes('洗濯')) items.push('洗濯をする');
      if (lastMessage.includes('買い物')) items.push('買い物に行く');
      if (lastMessage.includes('読書')) items.push('読書をする');
      
      response.content = `以下のタスクを整理しました：\n${items.map(item => `• ${item}`).join('\n')}\n\n優先順位を付けて保存しますね。`;
      response.tool_calls = [
        {
          type: 'function',
          function: {
            name: 'todo_save',
            arguments: JSON.stringify({
              items: items,
              category: 'weekend',
              priority: 'medium'
            })
          }
        }
      ];
    } else {
      response.content = 'どのようなことを整理したいですか？具体的に教えてください。';
    }

    res.json({
      type: 'message',
      role: 'assistant',
      content: [{ type: 'text', text: response.content }],
      tool_calls: response.tool_calls || []
    });

  } catch (error) {
    console.error('Chat error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ツール実行エンドポイント
app.post('/api/tool/:toolName', (req, res) => {
  const { toolName } = req.params;
  const { params } = req.body;
  
  console.log(`Tool called: ${toolName}`, params);

  try {
    switch(toolName) {
      case 'todo_save':
        const todos = loadTodos();
        const newTodo = {
          id: Date.now(),
          timestamp: new Date().toISOString(),
          items: params.items || [],
          category: params.category || 'general',
          priority: params.priority || 'medium'
        };
        todos.push(newTodo);
        saveTodos(todos);
        
        res.json({ 
          success: true, 
          message: `${params.items?.length || 0}個のタスクを保存しました！`,
          data: newTodo
        });
        break;

      case 'todo_get':
        const allTodos = loadTodos();
        const filteredTodos = params.category 
          ? allTodos.filter(todo => todo.category === params.category)
          : allTodos;
        
        res.json({
          success: true,
          data: filteredTodos,
          count: filteredTodos.length
        });
        break;

      default:
        res.status(404).json({ error: `Tool ${toolName} not found` });
    }
  } catch (error) {
    console.error(`Tool ${toolName} error:`, error);
    res.status(500).json({ error: error.message });
  }
});

// ツールリスト取得
app.get('/api/tools', (req, res) => {
  res.json({ tools });
});

// サーバー起動
const PORT = process.env.PORT || 3000;

initTodoFile();

app.listen(PORT, () => {
  console.log(`🚀 Proxy server running on http://localhost:${PORT}`);
  console.log(`📝 Open http://localhost:${PORT}/todo-app.html to start`);
  console.log(`💾 TODOs will be saved to: ${path.resolve(TODO_FILE)}`);
});