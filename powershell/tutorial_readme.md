# 🌱 最小限スタート型 PowerShell+JavaScript プラットフォーム

**教材・教科書・例題として作られた学習用リポジトリ**

## 🎯 学習目標

このリポジトリで学習者は以下を習得できます：

1. **PowerShell美学**: 関数分割 + 短縮命名 + グローバル変数
2. **責任分担設計**: PowerShell(バックエンド) ⟷ JavaScript(フロントエンド)
3. **CORS対応**: ブラウザとサーバー間の正しい通信方法
4. **成長型開発**: 最小限から段階的に機能拡張

## 📐 アーキテクチャ (教材的説明)

```
ユーザー入力
    ↓
┌─────────────────┐    HTTP    ┌─────────────────┐
│   JavaScript    │ ⟷ CORS ⟷ │   PowerShell    │
│   (フロント)      │            │   (バック)       │
├─────────────────┤            ├─────────────────┤
│ ✅ GUI操作       │            │ ✅ LLM処理       │
│ ✅ データUI      │            │ ✅ CORS設定      │
│ ✅ ローカル保存   │            │ ✅ HTTP サーバー  │
│ ❌ 外部API      │            │ ❌ DOM操作       │
└─────────────────┘            └─────────────────┘
```

## 🎓 学習ステップ

### STEP 1: 基本動作確認 (30分)
```powershell
# proxy.ps1 を実行
.\proxy.ps1

# ブラウザで http://localhost:3000/todo-app.html を開く
# 「洗濯、買い物、読書もしたい」と入力してテスト
```

### STEP 2: PowerShell美学を理解 (30分)

#### 🏗️ 関数分割美学
```powershell
# ❌ 悪い例: 全部1つの関数
function DO-EVERYTHING { /* 200行の処理 */ }

# ✅ 良い例: 責任で分割
function INIT-TODO { /* 初期化のみ */ }
function SET-CORS { /* CORS設定のみ */ }
function SEND-JSON { /* JSON送信のみ */ }
function HANDLE-CHAT { /* チャット処理のみ */ }
function RUN-SERVER { /* サーバー実行のみ */ }
```

#### 🔤 短縮命名美学
```powershell
# ❌ 冗長な命名
$httpListenerInstance = [System.Net.HttpListener]::new()
$httpRequest = $httpContext.Request
$httpResponse = $httpContext.Response

# ✅ 簡潔な命名
$global:ls = [System.Net.HttpListener]::new()
$rq = $ct.Request  
$rs = $ct.Response
```

#### 🌐 グローバル変数美学
```powershell
# ✅ 共有リソースはグローバル管理
$global:ls = [System.Net.HttpListener]::new()

# 他の関数から直接アクセス可能
function RUN-SERVER {
    while ($global:ls.IsListening) { }
}
```

### STEP 3: 責任分担を理解 (30分)

#### PowerShell側責任
```powershell
# ✅ PowerShellが担当
- LLM処理 ([LLM]::Parse)
- HTTP サーバー (HttpListener)
- CORS設定 (SET-CORS)
- JSON レスポンス (SEND-JSON)

# ❌ PowerShellは関与しない  
- DOM操作
- ローカルストレージ
- UI イベント処理
```

#### JavaScript側責任
```javascript
// ✅ JavaScriptが担当
- GUI操作 (addMessage, showTodos)
- データ表示 (DOM manipulation)
- ローカルストレージ (localStorage)
- ユーザーイベント (onclick, onkeypress)

// ❌ JavaScriptは関与しない
- 外部API直接アクセス (CORS制限)
- サーバーサイド処理
```

### STEP 4: カスタマイズ実習 (60分)

#### 実習1: 新しいパターン追加
```powershell
# LLMクラスに新パターン追加
else if (message.Contains("仕事") || message.Contains("会議")) 
{
    if (message.Contains("会議")) items.Add("会議資料を準備する");
    if (message.Contains("仕事")) items.Add("仕事タスクを確認する");
    
    content = "仕事関連のタスクを整理しました：\n";
    // 以下同様
}
```

#### 実習2: UI改善
```javascript
// CSS追加でデザイン改善
.todo { 
    background: linear-gradient(45deg, #667eea, #764ba2);
    color: white;
    border-radius: 10px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}
```

#### 実習3: 機能拡張
```javascript
// TODO編集機能追加
function editTodo(index) {
    const newText = prompt('新しいタスク内容:');
    if (newText) {
        todos[index].items[0] = newText;
        localStorage.setItem('todos', JSON.stringify(todos));
        showTodos();
    }
}
```

## 📚 学習教材

### 📖 教科書コード
- `proxy.ps1` - PowerShell美学の完全実装
- `todo-app.html` - JavaScript責任分担の模範例

### 🧪 例題アプリ
- TODO管理システム - 実用的な機能を持つ完全動作例

### 📝 課題
1. **初級**: メッセージパターンを3つ追加
2. **中級**: カテゴリ別TODO表示機能追加  
3. **上級**: 外部API(天気予報)との連携

## 🎨 コード美学の価値

### PowerShell美学の効果
- **可読性向上**: 関数分割により処理が明確
- **保守性向上**: 短縮命名により修正箇所が特定しやすい
- **拡張性向上**: グローバル変数により機能追加が容易

### 実際の美学比較

#### 😰 美学なしコード (悪い例)
```powershell
# 長大な1つの関数、冗長な変数名、スコープ混乱
function StartTodoManagementApplicationServerWithHttpListenerAndCorsSupport {
    $httpListenerInstanceForTodoApplication = [System.Net.HttpListener]::new()
    # 200行の処理...
}
```

#### 😍 美学ありコード (良い例)  
```powershell
# 分割された責任、簡潔な命名、明確なスコープ
function INIT-TODO { $global:ls = [System.Net.HttpListener]::new() }
function SET-CORS($rs) { $rs.AddHeader("Access-Control-Allow-Origin", "*") }
function RUN-SERVER { while ($global:ls.IsListening) { HANDLE-REQUEST $ct } }
```

## 🚀 次のステップ

1. **基本習得**: この教材で基礎を完全理解
2. **応用展開**: 他のアプリケーション（チャット、ゲーム等）に応用
3. **プラットフォーム化**: 共通フレームワークとして発展

## 🏆 学習成果

この教材を完了すると：
- **PowerShell美学**: 読みやすく保守しやすいコードが書ける
- **アーキテクチャ設計**: 責任分担の明確な設計ができる
- **実用アプリ開発**: 実際に使えるアプリケーションが作れる
- **成長型思考**: 最小限から段階的に発展させる考え方を習得

---

**🌱 美しいコードとともに成長する学習プラットフォーム**